#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${NC}[INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to check if a resource exists
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    kubectl get $resource_type $resource_name -n $namespace &>/dev/null
}

# Function to backup a resource
backup_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local backup_dir="gateway-config-backup-$(date +%Y%m%d-%H%M%S)"
    
    mkdir -p "$backup_dir"
    kubectl get $resource_type $resource_name -n $namespace -o yaml > "$backup_dir/${resource_type}_${resource_name}_${namespace}.yaml"
    log_info "Backed up $resource_type/$resource_name to $backup_dir"
}

# Function to fix gateway configuration
fix_gateway() {
    local gateway_name=$1
    local namespace=$2
    local selector=$3
    local host=$4
    
    if ! check_resource "gateway" "$gateway_name" "$namespace"; then
        log_error "Gateway $gateway_name not found in namespace $namespace"
        return 1
    fi
    
    # Backup current configuration
    backup_resource "gateway" "$gateway_name" "$namespace"
    
    # Create new gateway configuration
    cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: $gateway_name
  namespace: $namespace
spec:
  selector:
    istio: $selector
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "$host"
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Updated gateway $gateway_name in namespace $namespace"
    else
        log_error "Failed to update gateway $gateway_name in namespace $namespace"
        return 1
    fi
}

# Function to verify VirtualService configuration
verify_virtualservice() {
    local vs_name=$1
    local namespace=$2
    local host=$3
    
    if ! check_resource "virtualservice" "$vs_name" "$namespace"; then
        log_warning "VirtualService $vs_name not found in namespace $namespace"
        return 0
    fi
    
    # Check if VirtualService uses wildcard hosts
    local current_hosts=$(kubectl get virtualservice $vs_name -n $namespace -o jsonpath='{.spec.hosts}')
    if [[ $current_hosts == *"*"* ]]; then
        log_warning "VirtualService $vs_name in namespace $namespace uses wildcard hosts"
        
        # Backup current configuration
        backup_resource "virtualservice" "$vs_name" "$namespace"
        
        # Update VirtualService hosts
        kubectl get virtualservice $vs_name -n $namespace -o json | \
        jq --arg host "$host" '.spec.hosts = [$host]' | \
        kubectl apply -f -
        
        if [ $? -eq 0 ]; then
            log_success "Updated VirtualService $vs_name hosts in namespace $namespace"
        else
            log_error "Failed to update VirtualService $vs_name hosts in namespace $namespace"
        fi
    fi
}

# Main execution
log_info "Starting gateway configuration fix"

# Get domain information from global ConfigMap
PUBLIC_DOMAIN=$(kubectl get cm global -n default -o jsonpath='{.data.mosip-api-host}' 2>/dev/null)
INTERNAL_DOMAIN=$(kubectl get cm global -n default -o jsonpath='{.data.mosip-api-internal-host}' 2>/dev/null)

if [ -z "$PUBLIC_DOMAIN" ] || [ -z "$INTERNAL_DOMAIN" ]; then
    log_error "Failed to get domain information from global ConfigMap"
    exit 1
fi

# Fix public gateway
fix_gateway "public" "istio-system" "ingressgateway" "$PUBLIC_DOMAIN"

# Fix internal gateway
fix_gateway "internal" "istio-system" "ingressgateway-internal" "$INTERNAL_DOMAIN"

# Verify and fix VirtualServices in all namespaces
log_info "Verifying VirtualServices in all namespaces"

# Get all namespaces with VirtualServices
NAMESPACES=$(kubectl get virtualservices --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort -u)

for ns in $NAMESPACES; do
    # Get all VirtualServices in namespace
    VS_NAMES=$(kubectl get virtualservices -n $ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
    
    for vs in $VS_NAMES; do
        # Check gateway references to determine which domain to use
        GATEWAYS=$(kubectl get virtualservice $vs -n $ns -o jsonpath='{.spec.gateways}')
        
        if [[ $GATEWAYS == *"internal"* ]]; then
            verify_virtualservice "$vs" "$ns" "$INTERNAL_DOMAIN"
        elif [[ $GATEWAYS == *"public"* ]]; then
            verify_virtualservice "$vs" "$ns" "$PUBLIC_DOMAIN"
        else
            log_warning "VirtualService $vs in namespace $ns has no gateway reference"
        fi
    done
done

log_info "Gateway configuration fix completed"
log_info "Backup files are stored in gateway-config-backup-* directory"
log_info "Please verify the changes and test the configuration" 