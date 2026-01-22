#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 -s <service_name> -n <namespace> -d <domain> [-v]"
    echo "  -s: Service name (e.g., minio)"
    echo "  -n: Namespace where the service is deployed"
    echo "  -d: Domain (e.g., sandbox.hackmepls.co.uk)"
    echo "  -v: Verbose output (optional)"
    exit 1
}

# Initialize variables
SERVICE=""
NAMESPACE=""
DOMAIN=""
VERBOSE=false

# Parse command line arguments
while getopts "s:n:d:vh" opt; do
    case $opt in
        s) SERVICE="$OPTARG" ;;
        n) NAMESPACE="$OPTARG" ;;
        d) DOMAIN="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) usage ;;
        \?) usage ;;
    esac
done

# Check required arguments
if [ -z "$SERVICE" ] || [ -z "$NAMESPACE" ] || [ -z "$DOMAIN" ]; then
    usage
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

log_section() {
    echo -e "${BLUE}--- $1 ---${NC}"
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

# Function to check DNS resolution
check_dns() {
    local host=$1
    log_section "Checking DNS resolution for $host"
    
    # Try different DNS resolvers
    echo "Using system resolver:"
    dig +short $host
    
    echo -e "\nUsing Cloudflare DNS (1.1.1.1):"
    dig +short @1.1.1.1 $host
}

# Function to check certificate
check_cert() {
    local host=$1
    log_section "Checking TLS certificate for $host"
    
    echo | openssl s_client -showcerts -servername $host -connect $host:443 2>/dev/null | openssl x509 -inform pem -noout -text
}

# Function to check Istio configuration
check_istio_config() {
    local service=$1
    local namespace=$2
    
    log_header "Checking Istio Configuration"
    
    # Check VirtualService
    log_section "VirtualService Details"
    if check_resource "virtualservice" "$service" "$namespace"; then
        log_success "VirtualService $service exists"
        kubectl get virtualservice $service -n $namespace -o yaml
        
        # Extract and check each gateway
        log_section "Gateway References"
        local gateways=$(kubectl get virtualservice $service -n $namespace -o jsonpath='{.spec.gateways}')
        echo "Configured gateways: $gateways"
        
        for gateway in $(echo $gateways | tr -d '[]"' | tr ',' '\n'); do
            IFS='/' read -r gateway_ns gateway_name <<< "$gateway"
            [ -z "$gateway_ns" ] && gateway_ns=$namespace
            
            if check_resource "gateway" "$gateway_name" "$gateway_ns"; then
                log_success "Gateway $gateway_name exists in namespace $gateway_ns"
                kubectl get gateway $gateway_name -n $gateway_ns -o yaml
            else
                log_error "Gateway $gateway_name not found in namespace $gateway_ns"
            fi
        done
    else
        log_error "No VirtualService found for $service"
    fi
}

# Function to check Istio ingress configuration
check_istio_ingress() {
    log_header "Checking Istio Ingress Configuration"
    
    # Check internal ingress gateway
    log_section "Internal Ingress Gateway"
    kubectl get pods -n istio-system -l app=istio-ingressgateway-internal -o wide
    kubectl get service -n istio-system -l app=istio-ingressgateway-internal -o wide
    
    # Get gateway configuration
    log_section "Gateway Configurations in istio-system"
    kubectl get gateway -n istio-system -o yaml
    
    # Check gateway status
    log_section "Gateway Status"
    istioctl proxy-status | grep ingressgateway
    
    # Check ingress gateway routes
    log_section "Ingress Gateway Routes"
    for pod in $(kubectl get pods -n istio-system -l app=istio-ingressgateway-internal -o jsonpath='{.items[*].metadata.name}'); do
        echo "Routes for pod $pod:"
        istioctl proxy-config routes pod/$pod -n istio-system
    done
}

# Function to check Envoy configuration
check_envoy_config() {
    local service=$1
    local namespace=$2
    
    log_header "Checking Envoy Configuration"
    
    # Get service pods
    local pods=$(kubectl get pods -n $namespace -l app=$service -o jsonpath='{.items[*].metadata.name}')
    
    for pod in $pods; do
        log_section "Envoy Config for pod $pod"
        
        # Check listeners
        echo "Listeners:"
        istioctl proxy-config listener $pod -n $namespace
        
        # Check clusters
        echo -e "\nClusters:"
        istioctl proxy-config cluster $pod -n $namespace
        
        # Check routes
        echo -e "\nRoutes:"
        istioctl proxy-config route $pod -n $namespace
    done
}

# Function to test routing
test_routing() {
    local service=$1
    local domain=$2
    
    log_header "Testing Routing"
    
    local service_url="https://$service.$domain"
    local api_url="https://api-internal.$domain"
    
    # Test direct service access
    log_section "Testing direct service access"
    curl -v -k --max-time 5 $service_url
    
    # Test through API gateway
    log_section "Testing through API gateway"
    curl -v -k --max-time 5 -H "Host: $service.$domain" $api_url
    
    # Check for redirects
    log_section "Checking redirects"
    curl -v -k -L --max-time 5 $service_url
}

# Main execution
log_header "Starting Routing Troubleshooting for $SERVICE.$DOMAIN"

# Check DNS
check_dns "$SERVICE.$DOMAIN"
check_dns "api-internal.$DOMAIN"

# Check certificates
check_cert "$SERVICE.$DOMAIN"
check_cert "api-internal.$DOMAIN"

# Check Istio configuration
check_istio_config "$SERVICE" "$NAMESPACE"

# Check Istio ingress
check_istio_ingress

# Check Envoy configuration
check_envoy_config "$SERVICE" "$NAMESPACE"

# Test routing
test_routing "$SERVICE" "$DOMAIN"

# Final summary
log_header "Troubleshooting Summary"
echo "Service: $SERVICE"
echo "Namespace: $NAMESPACE"
echo "Domain: $DOMAIN"
echo "Service URL: https://$SERVICE.$DOMAIN"
echo "API Gateway: https://api-internal.$DOMAIN"

# If verbose, dump additional diagnostic information
if [ "$VERBOSE" = true ]; then
    log_header "Additional Diagnostic Information"
    
    log_section "Istio Operator Status"
    kubectl get istiooperator -A -o yaml
    
    log_section "All VirtualServices"
    kubectl get virtualservices -A -o yaml
    
    log_section "All Gateways"
    kubectl get gateways -A -o yaml
    
    log_section "Istio System Pods"
    kubectl get pods -n istio-system
    
    log_section "Istio System Services"
    kubectl get services -n istio-system
    
    log_section "Istio Ingress Gateway Logs"
    kubectl logs -n istio-system -l app=istio-ingressgateway-internal --tail=100
fi 