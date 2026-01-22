#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 -s <service_name> -n <namespace> [-v]"
    echo "  -s: Service name (e.g., minio, httpbin, keycloak, postgres)"
    echo "  -n: Namespace where the service is deployed"
    echo "  -v: Verbose output (optional)"
    exit 1
}

# Initialize variables
SERVICE=""
NAMESPACE=""
VERBOSE=false

# Create temporary files for storing port mappings
PORT_MAP_FILE=$(mktemp)
PROTOCOL_MAP_FILE=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$PORT_MAP_FILE" "$PROTOCOL_MAP_FILE"
    kubectl delete pod test-curl test-netcat test-grpcurl --ignore-not-found=true -n "$NAMESPACE" 2>/dev/null
}

# Set up trap for cleanup
trap cleanup EXIT

# Store port mapping
store_port_map() {
    local key=$1
    local value=$2
    echo "$key:$value" >> "$PORT_MAP_FILE"
}

# Store protocol
store_protocol() {
    local key=$1
    local value=$2
    echo "$key:$value" >> "$PROTOCOL_MAP_FILE"
}

# Get port mapping
get_port_map() {
    local key=$1
    grep "^$key:" "$PORT_MAP_FILE" | cut -d: -f2-
}

# Get protocol
get_protocol() {
    local key=$1
    grep "^$key:" "$PROTOCOL_MAP_FILE" | cut -d: -f2-
}

# Parse command line arguments
while getopts "s:n:vh" opt; do
    case $opt in
        s) SERVICE="$OPTARG" ;;
        n) NAMESPACE="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) usage ;;
    esac
done

# Check required arguments
if [ -z "$SERVICE" ] || [ -z "$NAMESPACE" ]; then
    usage
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_info() {
    echo -e "ℹ $1"
}

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    if kubectl get $resource_type $resource_name -n $namespace &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to parse service specification
parse_service_spec() {
    local service=$1
    local namespace=$2
    
    log_header "Parsing Service Specification"
    
    # Get service spec in JSON format
    local service_json=$(kubectl get service $service -n $namespace -o json)
    
    # Parse ports using proper JSON path
    echo "$service_json" | jq -r '.spec.ports[] | "\(.name // "unnamed")|\(.port)|\(.targetPort)|\(.protocol)"' | while IFS='|' read -r port_name port_number target_port protocol; do
        store_port_map "$port_name" "$port_number:$target_port"
        store_protocol "$port_name" "${protocol,,}"
        
        log_info "Found port mapping: $port_name -> Port: $port_number, Target: $target_port, Protocol: $protocol"
    done
}

# Function to parse gateway specification
parse_gateway_spec() {
    local service=$1
    local namespace=$2
    
    log_header "Parsing Gateway Specification"
    
    # First check if there's a VirtualService
    if ! check_resource "virtualservice" "$service" "$namespace"; then
        log_error "No VirtualService found for $service"
        return 1
    fi
    
    # Get gateway references
    local vs_json=$(kubectl get virtualservice $service -n $namespace -o json)
    local gateways=$(echo "$vs_json" | jq -r '.spec.gateways[]? // empty')
    
    if [ -z "$gateways" ]; then
        log_error "No gateways found in VirtualService"
        return 1
    fi
    
    # For each gateway
    for gateway in $gateways; do
        IFS='/' read -r gateway_ns gateway_name <<< "$gateway"
        [ -z "$gateway_ns" ] && gateway_ns=$namespace
        [ -z "$gateway_name" ] && continue
        
        if check_resource "gateway" "$gateway_name" "$gateway_ns"; then
            log_success "Found gateway: $gateway_name in namespace $gateway_ns"
            
            # Get gateway spec in JSON format
            local gateway_json=$(kubectl get gateway $gateway_name -n $gateway_ns -o json)
            
            # Check if servers exist
            local has_servers=$(echo "$gateway_json" | jq 'has("spec") and .spec != null and has("servers") and .spec.servers != null and (.spec.servers | length > 0)')
            
            if [ "$has_servers" = "true" ]; then
                # Parse servers using proper JSON path
                echo "$gateway_json" | jq -r '.spec.servers[] | select(.port != null) | select(.port.number != null) | "\(.port.number)|\(.port.name // "unnamed")|\(.port.protocol // "TCP")|\(.hosts[0] // "*")"' | while IFS='|' read -r port_number port_name protocol host; do
                    if [ ! -z "$port_number" ] && [ ! -z "$port_name" ]; then
                        store_port_map "${gateway_name}_${port_name}" "$port_number"
                        store_protocol "${gateway_name}_${port_name}" "${protocol,,}"
                        
                        log_info "Found gateway port: $port_name -> Port: $port_number, Protocol: $protocol"
                        log_info "Host: $host"
                    fi
                done
            else
                log_error "No valid server configurations found in gateway $gateway_name"
            fi
        else
            log_error "Gateway $gateway_name not found in namespace $gateway_ns"
        fi
    done
}

# Function to parse endpoint specification
parse_endpoint_spec() {
    local service=$1
    local namespace=$2
    
    log_header "Parsing Endpoint Specification"
    
    # Get endpoints in JSON format
    local endpoints_json=$(kubectl get endpoints $service -n $namespace -o json)
    
    # Parse subsets using proper JSON path
    echo "$endpoints_json" | jq -r '.subsets[] | .addresses[] as $addr | .ports[] | "\($addr.ip)|\(.name // "unnamed")|\(.port)|\(.protocol)|\($addr.targetRef.name // "")"' | while IFS='|' read -r ip port_name port_number protocol target_ref; do
        store_port_map "${ip}_${port_name}" "$port_number"
        store_protocol "${ip}_${port_name}" "${protocol,,}"
        
        log_info "Found endpoint: $ip:$port_number ($port_name) Protocol: $protocol"
        [ ! -z "$target_ref" ] && log_info "  Pod: $target_ref"
    done
}

# Function to test endpoint connectivity
test_endpoint() {
    local target=$1
    local port=$2
    local protocol=${3:-http}
    local description=$4
    
    log_info "Testing $description: $target:$port ($protocol)"
    
    # Clean up any existing test pods and wait for deletion to complete
    kubectl delete pod test-curl test-netcat test-grpcurl --ignore-not-found=true -n "$NAMESPACE" &>/dev/null
    while kubectl get pod test-curl test-netcat test-grpcurl -n "$NAMESPACE" &>/dev/null; do
        sleep 1
    done
    
    # Create a test pod with appropriate image based on protocol
    case $protocol in
        tcp|tcp-*|udp|udp-*)
            kubectl run -i --rm --restart=Never test-netcat --image=busybox -- nc -zv -w 3 $target $port 2>&1 | head -n 5
            ;;
        http|https)
            kubectl run -i --rm --restart=Never test-curl --image=curlimages/curl -- curl -v -m 5 $protocol://$target:$port 2>&1 | head -n 5
            ;;
        grpc)
            kubectl run -i --rm --restart=Never test-grpcurl --image=fullstorydev/grpcurl -- -plaintext $target:$port list 2>&1 | head -n 5
            ;;
        *)
            log_error "Unsupported protocol: $protocol"
            return 1
            ;;
    esac
}

# Function to run comprehensive tests
run_tests() {
    log_header "Running Comprehensive Tests"
    
    # 1. Test Service Ports
    while IFS=: read -r port_name port_info; do
        [ -z "$port_name" ] && continue
        IFS=':' read -r port target_port <<< "$port_info"
        protocol=$(get_protocol "$port_name")
        
        # Test ClusterIP
        test_endpoint "$CLUSTER_IP" "$port" "$protocol" "Service ClusterIP ($port_name)"
        
        # Test Service DNS
        test_endpoint "$SERVICE.$NAMESPACE.svc.cluster.local" "$port" "$protocol" "Service DNS ($port_name)"
        
        # If target port is different, test that too
        if [ "$port" != "$target_port" ] && [ ! -z "$target_port" ]; then
            test_endpoint "$SERVICE.$NAMESPACE.svc.cluster.local" "$target_port" "$protocol" "Service DNS (target port)"
        fi
    done < "$PORT_MAP_FILE"
}

# Main execution flow
parse_service_spec "$SERVICE" "$NAMESPACE"
parse_gateway_spec "$SERVICE" "$NAMESPACE"
parse_endpoint_spec "$SERVICE" "$NAMESPACE"

# Get cluster IP for service
CLUSTER_IP=$(kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
ENDPOINT_IPS=$(kubectl get endpoints $SERVICE -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}')

# Run all tests
run_tests

# Show test matrix summary
log_header "Test Matrix Summary"
printf "%-20s %-10s %-15s %-10s\n" "NAME" "PORT" "TARGET" "PROTOCOL"
echo "------------------------------------------------"
while IFS=: read -r port_name port_info; do
    [ -z "$port_name" ] && continue
    IFS=':' read -r port target_port <<< "$port_info"
    protocol=$(get_protocol "$port_name")
    printf "%-20s %-10s %-15s %-10s\n" "$port_name" "$port" "${target_port:-N/A}" "$protocol"
done < "$PORT_MAP_FILE"

# Check if namespace exists
log_header "Checking namespace $NAMESPACE"
if ! check_resource "namespace" "$NAMESPACE" "$NAMESPACE"; then
    log_error "Namespace $NAMESPACE does not exist"
    exit 1
fi
log_success "Namespace $NAMESPACE exists"

# Check Istio injection
log_header "Checking Istio injection"
ISTIO_INJECTION=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.istio-injection}')
if [ "$ISTIO_INJECTION" == "enabled" ]; then
    log_success "Istio injection is enabled"
else
    log_error "Istio injection is not enabled"
fi

# Check if service exists
log_header "Checking service $SERVICE"
if ! check_resource "service" "$SERVICE" "$NAMESPACE"; then
    log_error "Service $SERVICE does not exist in namespace $NAMESPACE"
    exit 1
fi
log_success "Service $SERVICE exists"

# Get service details and endpoints
log_header "Service Details and Endpoints"
kubectl get service $SERVICE -n $NAMESPACE -o wide
echo -e "\nService Description:"
kubectl describe service $SERVICE -n $NAMESPACE
echo -e "\nEndpoints:"
kubectl get endpoints $SERVICE -n $NAMESPACE -o wide

# Collect service ports and endpoints
log_header "Collecting Service Ports and Endpoints"
ENDPOINT_IPS=$(kubectl get endpoints $SERVICE -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}')
SERVICE_PORTS=$(kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.spec.ports[*].port}')
TARGET_PORTS=$(kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.spec.ports[*].targetPort}')

# Check VirtualService
log_header "Checking VirtualService configuration"
if check_resource "virtualservice" "$SERVICE" "$NAMESPACE"; then
    log_success "VirtualService $SERVICE exists"
    
    # Check gateway configuration
    GATEWAYS=$(kubectl get virtualservice $SERVICE -n $NAMESPACE -o jsonpath='{.spec.gateways}')
    echo "Configured gateways: $GATEWAYS"
    
    # Verify each gateway exists
    for gateway in $(echo $GATEWAYS | tr -d '[]"' | tr ',' '\n'); do
        IFS='/' read -r gateway_ns gateway_name <<< "$gateway"
        if [ -z "$gateway_ns" ]; then
            gateway_ns=$NAMESPACE
        fi
        if check_resource "gateway" "$gateway_name" "$gateway_ns"; then
            log_success "Gateway $gateway exists"
            
            # Get gateway ports and hosts
            GATEWAY_PORTS=$(kubectl get gateway $gateway_name -n $gateway_ns -o jsonpath='{.spec.servers[*].port.number}')
            GATEWAY_HOSTS=$(kubectl get gateway $gateway_name -n $gateway_ns -o jsonpath='{.spec.servers[*].hosts}')
            
            echo "Gateway Ports: $GATEWAY_PORTS"
            echo "Gateway Hosts: $GATEWAY_HOSTS"
        else
            log_error "Gateway $gateway does not exist"
        fi
    done
    
    # Show VirtualService details
    if [ "$VERBOSE" = true ]; then
        echo ""
        kubectl get virtualservice $SERVICE -n $NAMESPACE -o yaml
    fi
else
    log_error "VirtualService $SERVICE does not exist"
fi

# Check pods
log_header "Checking pods"
kubectl get pods -n $NAMESPACE -l app=$SERVICE -o wide
echo ""
kubectl describe pods -n $NAMESPACE -l app=$SERVICE

# Check pod logs
log_header "Checking pod logs"
PODS=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[*].metadata.name}')
for pod in $PODS; do
    echo -e "\nLogs for pod $pod:"
    kubectl logs -n $NAMESPACE $pod --tail=50
done

# Check Istio proxy logs if injection is enabled
if [ "$ISTIO_INJECTION" == "enabled" ]; then
    log_header "Checking Istio proxy logs"
    for pod in $PODS; do
        echo -e "\nIstio proxy logs for pod $pod:"
        kubectl logs -n $NAMESPACE $pod -c istio-proxy --tail=50
    done
fi

# Check Istio ingress gateway logs
log_header "Checking Istio ingress gateway logs"
echo "Internal gateway logs:"
kubectl logs -n istio-system -l app=istio-ingressgateway-internal -c istio-proxy --tail=50

# Final status
log_header "Troubleshooting Summary"
echo "Service: $SERVICE"
echo "Namespace: $NAMESPACE"
echo "Istio Injection: $ISTIO_INJECTION"
echo "VirtualService: $(check_resource 'virtualservice' "$SERVICE" "$NAMESPACE" && echo "Present" || echo "Missing")"
echo "Pods Running: $(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[*].status.phase}' | grep -c "Running")"
echo "Service Ports: $SERVICE_PORTS"
echo "Target Ports: $TARGET_PORTS"
echo "Endpoint IPs: $ENDPOINT_IPS" 