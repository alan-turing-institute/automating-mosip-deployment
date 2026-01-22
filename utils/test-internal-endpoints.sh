#!/bin/bash
# MOSIP Internal Endpoints Test Script
# Tests all internal MOSIP service endpoints for deployment verification
# Usage: ./test-internal-endpoints.sh [OPTIONS] [MOSIP_DOMAIN]
#
# Options:
#   --skip-internal    Skip internal service-to-service tests (only test via gateways)
#   --external-only    Same as --skip-internal
#   --internal-only    Only test internal service-to-service (skip gateway tests)
#   -h, --help         Show this help message

# Don't exit on error - we handle errors in functions
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default flags
SKIP_INTERNAL=false
SKIP_EXTERNAL=false
MOSIP_DOMAIN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-internal|--external-only)
            SKIP_INTERNAL=true
            shift
            ;;
        --internal-only)
            SKIP_EXTERNAL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [MOSIP_DOMAIN]"
            echo ""
            echo "Options:"
            echo "  --skip-internal, --external-only    Skip internal service-to-service tests (only test via gateways)"
            echo "  --internal-only                      Only test internal service-to-service (skip gateway tests)"
            echo "  -h, --help                          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 warwick-2.turing-mosip.net                    # Test both internal and external"
            echo "  $0 --skip-internal warwick-2.turing-mosip.net    # Only test external (gateway) access"
            echo "  $0 --internal-only warwick-2.turing-mosip.net   # Only test internal service-to-service"
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$MOSIP_DOMAIN" ]; then
                MOSIP_DOMAIN="$1"
            else
                echo -e "${RED}Error: Multiple domains provided${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Get MOSIP domain from parameter or ConfigMap
if [ -z "$MOSIP_DOMAIN" ]; then
    MOSIP_DOMAIN=$(kubectl get configmap global -n default -o jsonpath='{.data.installation-domain}' 2>/dev/null || echo "")
    if [ -z "$MOSIP_DOMAIN" ]; then
        echo -e "${RED}Error: MOSIP domain not provided and not found in ConfigMap${NC}"
        echo "Usage: $0 [OPTIONS] <MOSIP_DOMAIN>"
        echo "Use -h or --help for usage information"
        exit 1
    fi
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}MOSIP Internal Endpoints Test${NC}"
echo -e "${CYAN}Domain: ${MOSIP_DOMAIN}${NC}"
if [ "$SKIP_INTERNAL" = true ]; then
    echo -e "${CYAN}Mode: External Only (Gateway Tests)${NC}"
elif [ "$SKIP_EXTERNAL" = true ]; then
    echo -e "${CYAN}Mode: Internal Only (Service-to-Service)${NC}"
else
    echo -e "${CYAN}Mode: Both Internal and External${NC}"
fi
echo -e "${CYAN}========================================${NC}\n"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results arrays
declare -a PASSED_SERVICES
declare -a FAILED_SERVICES
declare -a SKIPPED_SERVICES

# Function to print status with verbose output for failures/skips
print_status() {
    local status=$1
    local service=$2
    local details=$3
    local verbose_info=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}[✓ PASS]${NC} ${service}${details:+ - $details}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        PASSED_SERVICES+=("$service")
    elif [ $status -eq 2 ]; then
        echo -e "${YELLOW}[⊘ SKIP]${NC} ${service}${details:+ - $details}"
        if [ -n "$verbose_info" ]; then
            echo -e "  ${CYAN}Details:${NC} $verbose_info"
        fi
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        SKIPPED_SERVICES+=("$service")
    else
        echo -e "${RED}[✗ FAIL]${NC} ${service}${details:+ - $details}"
        if [ -n "$verbose_info" ]; then
            echo -e "  ${CYAN}Details:${NC} $verbose_info"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_SERVICES+=("$service")
    fi
}

# Function to check if namespace exists
check_namespace() {
    local ns=$1
    kubectl get namespace "$ns" &>/dev/null
    return $?
}

# Function to check if service exists
check_service() {
    local ns=$1
    local svc=$2
    kubectl get svc -n "$ns" "$svc" &>/dev/null 2>&1
    return $?
}

# Function to find a pod we can exec into for testing
# Prefers pods with curl/busybox, falls back to any running pod
find_test_pod() {
    local preferred_ns=${1:-""}
    
    # Try to find httpbin pod first (has curl)
    local httpbin_pod=$(kubectl get pods -n httpbin -l app=httpbin --field-selector=status.phase=Running --no-headers 2>/dev/null | head -1 | awk '{print $1}' || echo "")
    if [ -n "$httpbin_pod" ]; then
        echo "httpbin/$httpbin_pod"
        return 0
    fi
    
    # Try to find any pod in preferred namespace
    if [ -n "$preferred_ns" ] && check_namespace "$preferred_ns"; then
        local pod=$(kubectl get pods -n "$preferred_ns" --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -v "Completed" | head -1 | awk '{print $1}' || echo "")
        if [ -n "$pod" ]; then
            echo "$preferred_ns/$pod"
            return 0
        fi
    fi
    
    # Fall back to any running pod in any namespace
    local pod=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -v "Completed" | head -1 | awk '{print $1 "/" $2}' || echo "")
    if [ -n "$pod" ]; then
        echo "$pod"
        return 0
    fi
    
    return 1
}

# Function to check if HTTP response code is successful
# Returns 0 for success (2xx, 3xx), 1 for failure (4xx, 5xx), 2 for connection error (000)
check_http_code() {
    local code=$1
    local code_num=$(echo "$code" | sed 's/[^0-9]//g')
    
    # Connection failure
    if [ -z "$code_num" ] || [ "$code_num" = "000" ] || [ "$code_num" = "0" ]; then
        return 2
    fi
    
    # Success: 2xx and 3xx (redirects are OK)
    if [ "$code_num" -ge 200 ] && [ "$code_num" -lt 400 ]; then
        return 0
    fi
    
    # Failure: 4xx and 5xx
    if [ "$code_num" -ge 400 ]; then
        return 1
    fi
    
    # Unknown
    return 1
}

# Function to test TCP connection (for databases, etc.)
test_tcp_service() {
    local ns=$1
    local svc=$2
    local port=$3
    local description=$4
    
    if ! check_namespace "$ns"; then
        print_status 2 "$description" "Namespace not found" "Namespace '$ns' does not exist"
        return 2
    fi
    
    if ! check_service "$ns" "$svc"; then
        local svc_list=$(kubectl get svc -n "$ns" --no-headers 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "none")
        print_status 2 "$description" "Service not found" "Service '$svc' not found in namespace '$ns'. Available services: $svc_list"
        return 2
    fi
    
    # Find a pod to exec into
    local test_pod=$(find_test_pod "$ns")
    if [ -z "$test_pod" ]; then
        print_status 2 "$description" "No test pod available" "Could not find a running pod to exec into for testing"
        return 2
    fi
    
    local test_ns=$(echo "$test_pod" | cut -d'/' -f1)
    local test_pod_name=$(echo "$test_pod" | cut -d'/' -f2)
    local target="${svc}.${ns}.svc.cluster.local:${port}"
    
    # Try nc (netcat) first, fall back to creating a pod
    local result="failed"
    if kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v nc >/dev/null 2>&1" &>/dev/null; then
        result=$(kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "nc -w 5 -zv ${target} 2>&1 || echo 'connection failed'" 2>/dev/null || echo "failed")
    elif kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v timeout >/dev/null 2>&1 && command -v nc >/dev/null 2>&1" &>/dev/null; then
        result=$(kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "timeout 5 nc -zv ${target} 2>&1 || echo 'connection failed'" 2>/dev/null || echo "failed")
    else
        # Fallback to creating a pod if exec doesn't work
        local test_pod_name_new="test-tcp-${svc}-$(date +%s)"
        result=$(kubectl run -it --rm "$test_pod_name_new" \
            --image=busybox:latest \
            --restart=Never \
            --quiet \
            -- sh -c "nc -w 5 -zv ${target} 2>&1 || echo 'connection failed'" 2>/dev/null || echo "failed")
    fi
    
    if echo "$result" | grep -qiE "succeeded|open|connected"; then
        print_status 0 "$description" "TCP connection successful"
        return 0
    else
        print_status 1 "$description" "TCP connection failed" "Tested: $target, Result: $result. Test pod: $test_pod"
        return 1
    fi
}

# Function to test direct service access (HTTP)
test_direct_service() {
    local ns=$1
    local svc=$2
    local port=${3:-80}
    local path=${4:-/}
    local description=$5
    
    if ! check_namespace "$ns"; then
        print_status 2 "$description" "Namespace not found" "Namespace '$ns' does not exist"
        return 2
    fi
    
    if ! check_service "$ns" "$svc"; then
        local svc_list=$(kubectl get svc -n "$ns" --no-headers 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "none")
        print_status 2 "$description" "Service not found" "Service '$svc' not found in namespace '$ns'. Available services: $svc_list"
        return 2
    fi
    
    # Find a pod to exec into
    local test_pod=$(find_test_pod "$ns")
    if [ -z "$test_pod" ]; then
        print_status 2 "$description" "No test pod available" "Could not find a running pod to exec into for testing"
        return 2
    fi
    
    local test_ns=$(echo "$test_pod" | cut -d'/' -f1)
    local test_pod_name=$(echo "$test_pod" | cut -d'/' -f2)
    local url="http://${svc}.${ns}.svc.cluster.local:${port}${path}"
    
    # Build verbose details
    local verbose_details=""
    verbose_details+="Test Pod: $test_pod\n"
    verbose_details+="Target URL: $url\n"
    verbose_details+="Service: $svc.$ns.svc.cluster.local:$port\n"
    
    # Try curl first, fall back to wget, then try creating a pod
    local response="000"
    local tool_used=""
    local error_output=""
    
    # Check what tools are available
    if kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v curl >/dev/null 2>&1" &>/dev/null; then
        tool_used="curl"
        verbose_details+="Tool: curl (found in pod)\n"
        verbose_details+="Command: kubectl exec -n $test_ns $test_pod_name -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 '$url'\n"
        
        # Capture both stdout and stderr
        local curl_output=$(kubectl exec -n "$test_ns" "$test_pod_name" -- curl -v -s -o /dev/null -w "%{http_code}\n%{errormsg}" --max-time 10 "$url" 2>&1 || true)
        response=$(echo "$curl_output" | tail -1 | grep -oE "^[0-9]+" || echo "000")
        error_output=$(echo "$curl_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    elif kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v wget >/dev/null 2>&1" &>/dev/null; then
        tool_used="wget"
        verbose_details+="Tool: wget (found in pod)\n"
        verbose_details+="Command: kubectl exec -n $test_ns $test_pod_name -- wget -q -O- --timeout=10 --spider '$url'\n"
        
        local wget_output=$(kubectl exec -n "$test_ns" "$test_pod_name" -- wget -q -O- --timeout=10 --spider "$url" 2>&1 || true)
        response=$(echo "$wget_output" | grep -oE "HTTP/[0-9.]+ [0-9]+" | awk '{print $2}' || echo "000")
        error_output=$(echo "$wget_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    else
        tool_used="kubectl-run"
        verbose_details+="Tool: kubectl run (curl image, no suitable pod found)\n"
        verbose_details+="Command: kubectl run test-pod --image=curlimages/curl:latest --restart=Never -- curl -s -o /dev/null -w '%{http_code}' --max-time 10 '$url'\n"
        
        local test_pod_name_new="test-${svc}-$(date +%s)"
        local run_output=$(kubectl run -it --rm "$test_pod_name_new" \
            --image=curlimages/curl:latest \
            --restart=Never \
            --quiet \
            -- curl -v -s -o /dev/null -w "%{http_code}\n%{errormsg}" --max-time 10 "$url" 2>&1 || true)
        response=$(echo "$run_output" | tail -1 | grep -oE "^[0-9]+" || echo "000")
        error_output=$(echo "$run_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    fi
    
    verbose_details+="Response code: $response\n"
    
    # Check DNS resolution
    local dns_check=$(kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "nslookup ${svc}.${ns}.svc.cluster.local 2>&1 || getent hosts ${svc}.${ns}.svc.cluster.local 2>&1 || echo 'DNS lookup failed'" 2>/dev/null || echo "DNS check failed")
    verbose_details+="DNS resolution: $(echo "$dns_check" | head -3 | tr '\n' '; ')\n"
    
    # Check if service endpoint exists
    local endpoints=$(kubectl get endpoints -n "$ns" "$svc" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "none")
    verbose_details+="Service endpoints: $endpoints\n"
    
    check_http_code "$response"
    local code_status=$?
    
    if [ $code_status -eq 0 ]; then
        print_status 0 "$description" "HTTP $response"
        return 0
    elif [ $code_status -eq 2 ]; then
        print_status 1 "$description" "Connection failed" "$verbose_details"
        return 1
    else
        print_status 1 "$description" "HTTP $response" "$verbose_details"
        return 1
    fi
}

# Function to test service via Istio gateway
test_gateway_service() {
    local ns=$1
    local host=$2
    local path=${3:-/}
    local gateway=${4:-istio-ingressgateway-internal}
    local description=$5
    
    if ! check_namespace "$ns"; then
        print_status 2 "$description" "Namespace not found" "Namespace '$ns' does not exist"
        return 2
    fi
    
    # Check if gateway exists
    if ! kubectl get svc -n istio-system "$gateway" &>/dev/null; then
        local gw_list=$(kubectl get svc -n istio-system --no-headers 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "none")
        print_status 2 "$description (via gateway)" "Gateway not found" "Gateway '$gateway' not found in istio-system. Available gateways: $gw_list"
        return 2
    fi
    
    # Find a pod to exec into
    local test_pod=$(find_test_pod "$ns")
    if [ -z "$test_pod" ]; then
        print_status 2 "$description (via gateway)" "No test pod available" "Could not find a running pod to exec into for testing"
        return 2
    fi
    
    local test_ns=$(echo "$test_pod" | cut -d'/' -f1)
    local test_pod_name=$(echo "$test_pod" | cut -d'/' -f2)
    local url="http://${gateway}.istio-system:80${path}"
    
    # Build verbose details
    local verbose_details=""
    verbose_details+="Test Pod: $test_pod\n"
    verbose_details+="Target URL: $url\n"
    verbose_details+="Host Header: $host\n"
    verbose_details+="Gateway: $gateway.istio-system:80\n"
    
    # Try curl first, fall back to wget, then try creating a pod
    local response="000"
    local tool_used=""
    local error_output=""
    # Check what tools are available
    if kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v curl >/dev/null 2>&1" &>/dev/null; then
        tool_used="curl"
        verbose_details+="Tool: curl (found in pod)\n"
        verbose_details+="Command: kubectl exec -n $test_ns $test_pod_name -- curl -s -o /dev/null -w '%{http_code}' -H 'Host: $host' --max-time 10 '$url'\n"
        
        # Capture both stdout and stderr
        local curl_output=$(kubectl exec -n "$test_ns" "$test_pod_name" -- curl -v -s -o /dev/null -w "%{http_code}\n%{errormsg}" \
            -H "Host: ${host}" \
            --max-time 10 "$url" 2>&1 || true)
        response=$(echo "$curl_output" | tail -1 | grep -oE "^[0-9]+" || echo "000")
        error_output=$(echo "$curl_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    elif kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v wget >/dev/null 2>&1" &>/dev/null; then
        tool_used="wget"
        verbose_details+="Tool: wget (found in pod)\n"
        verbose_details+="Command: kubectl exec -n $test_ns $test_pod_name -- wget -q -O- --timeout=10 --header='Host: $host' --spider '$url'\n"
        
        local wget_output=$(kubectl exec -n "$test_ns" "$test_pod_name" -- wget -q -O- --timeout=10 --header="Host: ${host}" --spider "$url" 2>&1 || true)
        response=$(echo "$wget_output" | grep -oE "HTTP/[0-9.]+ [0-9]+" | awk '{print $2}' || echo "000")
        error_output=$(echo "$wget_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    else
        tool_used="kubectl-run"
        verbose_details+="Tool: kubectl run (curl image, no suitable pod found)\n"
        verbose_details+="Command: kubectl run test-pod --image=curlimages/curl:latest --restart=Never -- curl -s -o /dev/null -w '%{http_code}' -H 'Host: $host' --max-time 10 '$url'\n"
        
        local test_pod_name_new="test-gw-${ns}-$(date +%s)"
        local run_output=$(kubectl run -it --rm "$test_pod_name_new" \
            --image=curlimages/curl:latest \
            --restart=Never \
            --quiet \
            -- curl -v -s -o /dev/null -w "%{http_code}\n%{errormsg}" \
            -H "Host: ${host}" \
            --max-time 10 "$url" 2>&1 || true)
        response=$(echo "$run_output" | tail -1 | grep -oE "^[0-9]+" || echo "000")
        error_output=$(echo "$run_output" | grep -iE "error|failed|timeout|resolve|connect" || echo "")
        
        if [ -n "$error_output" ]; then
            verbose_details+="Error output: $error_output\n"
        fi
    fi
    
    verbose_details+="Response code: $response\n"
    
    # Check gateway endpoint
    local gw_endpoints=$(kubectl get endpoints -n istio-system "$gateway" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "none")
    verbose_details+="Gateway endpoints: $gw_endpoints\n"
    
    check_http_code "$response"
    local code_status=$?
    
    if [ $code_status -eq 0 ]; then
        print_status 0 "$description (via gateway)" "HTTP $response"
        return 0
    elif [ $code_status -eq 2 ]; then
        print_status 1 "$description (via gateway)" "Connection failed" "$verbose_details"
        return 1
    else
        print_status 1 "$description (via gateway)" "HTTP $response" "$verbose_details"
        return 1
    fi
}

# Function to test health endpoint
test_health_endpoint() {
    local ns=$1
    local svc=$2
    local path=${3:-/actuator/health}
    local description=$4
    
    if ! check_namespace "$ns"; then
        print_status 2 "$description (health)" "Namespace not found" "Namespace '$ns' does not exist"
        return 2
    fi
    
    if ! check_service "$ns" "$svc"; then
        local svc_list=$(kubectl get svc -n "$ns" --no-headers 2>/dev/null | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "none")
        print_status 2 "$description (health)" "Service not found" "Service '$svc' not found in namespace '$ns'. Available services: $svc_list"
        return 2
    fi
    
    # Find a pod to exec into
    local test_pod=$(find_test_pod "$ns")
    if [ -z "$test_pod" ]; then
        print_status 2 "$description (health)" "No test pod available" "Could not find a running pod to exec into for testing"
        return 2
    fi
    
    local test_ns=$(echo "$test_pod" | cut -d'/' -f1)
    local test_pod_name=$(echo "$test_pod" | cut -d'/' -f2)
    local url="http://${svc}.${ns}.svc.cluster.local:8080${path}"
    
    # Try curl first, fall back to wget, then try creating a pod
    local response="000"
    if kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v curl >/dev/null 2>&1" &>/dev/null; then
        response=$(kubectl exec -n "$test_ns" "$test_pod_name" -- curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    elif kubectl exec -n "$test_ns" "$test_pod_name" -- sh -c "command -v wget >/dev/null 2>&1" &>/dev/null; then
        response=$(kubectl exec -n "$test_ns" "$test_pod_name" -- wget -q -O- --timeout=10 --spider "$url" 2>&1 | grep -oE "HTTP/[0-9.]+ [0-9]+" | awk '{print $2}' || echo "000")
    else
        # Fallback to creating a pod if exec doesn't work
        local test_pod_name_new="test-health-${svc}-$(date +%s)"
        response=$(kubectl run -it --rm "$test_pod_name_new" \
            --image=curlimages/curl:latest \
            --restart=Never \
            --quiet \
            -- curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    fi
    
    check_http_code "$response"
    local code_status=$?
    
    if [ $code_status -eq 0 ]; then
        print_status 0 "$description (health)" "HTTP $response"
        return 0
    elif [ $code_status -eq 2 ]; then
        print_status 1 "$description (health)" "Connection failed" "Tested URL: $url, Response: $response (connection timeout). Test pod: $test_pod"
        return 1
    else
        print_status 1 "$description (health)" "HTTP $response" "Tested URL: $url, Response code: $response (4xx/5xx error)"
        return 1
    fi
}

# Function to check pod status (excludes Completed jobs)
check_pod_status() {
    local ns=$1
    local label=${2:-""}
    local description=$3
    
    if ! check_namespace "$ns"; then
        local ns_check=$(kubectl get namespace "$ns" 2>&1)
        print_status 2 "$description (pods)" "Namespace not found" "Namespace '$ns' does not exist. Checked with: kubectl get namespace $ns"
        return 2
    fi
    
    # Get all pods excluding Completed status (one-off jobs)
    local all_pods=$(kubectl get pods -n "$ns" ${label:+-l $label} --no-headers 2>/dev/null | grep -v "Completed" || true)
    local running_pods=$(kubectl get pods -n "$ns" ${label:+-l $label} --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -v "Completed" | wc -l || echo "0")
    local total_pods=$(echo "$all_pods" | wc -l || echo "0")
    
    # Get pod details for verbose output
    local pod_details=$(kubectl get pods -n "$ns" ${label:+-l $label} --no-headers 2>/dev/null | awk '{print $1 " (" $3 ")"}' | head -5 | tr '\n' ',' | sed 's/,$//' || echo "none")
    
    if [ "$total_pods" -eq 0 ] || [ -z "$all_pods" ]; then
        print_status 2 "$description (pods)" "No active pods found" "Namespace: $ns, Label: ${label:-none}, Found pods: $pod_details"
        return 2
    fi
    
    # Check for non-running pods (excluding Completed)
    local non_running=$(echo "$all_pods" | grep -v "Running" | wc -l || echo "0")
    
    if [ "$non_running" -eq 0 ] && [ "$running_pods" -gt 0 ]; then
        print_status 0 "$description (pods)" "$running_pods/$total_pods running"
        return 0
    else
        local failed_pods=$(echo "$all_pods" | grep -v "Running" | awk '{print $1 " (" $3 ")"}' | head -3 | tr '\n' ',' | sed 's/,$//' || echo "none")
        print_status 1 "$description (pods)" "$running_pods/$total_pods running" "Non-running pods: $failed_pods"
        return 1
    fi
}

echo -e "${BLUE}=== Infrastructure Services ===${NC}\n"

# Postgres
check_pod_status "postgres" "app.kubernetes.io/name=postgresql" "Postgres"
if [ "$SKIP_INTERNAL" != true ]; then
    test_tcp_service "postgres" "postgres-postgresql" "5432" "Postgres"
fi

# IAM/Keycloak (check both iam and keycloak namespaces)
if check_namespace "keycloak"; then
    check_pod_status "keycloak" "" "IAM/Keycloak"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_direct_service "keycloak" "keycloak" "8080" "/auth" "IAM/Keycloak"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "keycloak" "iam.${MOSIP_DOMAIN}" "/auth" "istio-ingressgateway-internal" "IAM/Keycloak"
    fi
elif check_namespace "iam"; then
    check_pod_status "iam" "" "IAM/Keycloak"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_direct_service "iam" "keycloak" "8080" "/auth" "IAM/Keycloak"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "iam" "iam.${MOSIP_DOMAIN}" "/auth" "istio-ingressgateway-internal" "IAM/Keycloak"
    fi
else
    check_pod_status "keycloak" "" "IAM/Keycloak"
    if ! check_namespace "keycloak"; then
        check_pod_status "iam" "" "IAM/Keycloak"
    fi
fi

# MinIO
if check_namespace "minio"; then
    check_pod_status "minio" "" "MinIO"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_direct_service "minio" "minio" "9000" "/" "MinIO"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "minio" "minio.${MOSIP_DOMAIN}" "/" "istio-ingressgateway-internal" "MinIO"
    fi
else
    check_pod_status "minio" "" "MinIO"
fi

# ActiveMQ
if check_namespace "activemq"; then
    check_pod_status "activemq" "" "ActiveMQ"
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "activemq" "activemq.${MOSIP_DOMAIN}" "/" "istio-ingressgateway-internal" "ActiveMQ"
    fi
fi

# Kafka
if check_namespace "kafka"; then
    check_pod_status "kafka" "" "Kafka"
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "kafka" "kafka.${MOSIP_DOMAIN}" "/" "istio-ingressgateway-internal" "Kafka"
    fi
fi

# Config Server
if check_namespace "config-server"; then
    check_pod_status "config-server" "" "Config Server"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "config-server" "config-server" "/actuator/health" "Config Server"
    fi
fi

echo -e "\n${BLUE}=== Core Services ===${NC}\n"

# Keymanager
if check_namespace "keymanager"; then
    check_pod_status "keymanager" "" "Keymanager"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "keymanager" "keymanager-service" "/actuator/health" "Keymanager"
    fi
fi

# Websub
if check_namespace "websub"; then
    check_pod_status "websub" "" "Websub"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "websub" "websub-service" "/actuator/health" "Websub"
    fi
fi

# Kernel Services
if check_namespace "kernel"; then
    check_pod_status "kernel" "" "Kernel"
    
    # Test key kernel services
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "kernel" "kernel-masterdata-service" "/actuator/health" "Kernel Masterdata"
        test_health_endpoint "kernel" "kernel-syncdata-service" "/actuator/health" "Kernel Syncdata"
        test_health_endpoint "kernel" "kernel-audit-manager-service" "/actuator/health" "Kernel Audit"
        test_health_endpoint "kernel" "kernel-notification-service" "/actuator/health" "Kernel Notification"
        test_health_endpoint "kernel" "kernel-otp-manager-service" "/actuator/health" "Kernel OTP"
        test_health_endpoint "kernel" "kernel-ridgenerator-service" "/actuator/health" "Kernel RID Generator"
    fi
fi

# Masterdata Loader
if check_namespace "masterdata-loader"; then
    check_pod_status "masterdata-loader" "" "Masterdata Loader"
fi

# BioSDK
if check_namespace "biosdk"; then
    check_pod_status "biosdk" "" "BioSDK"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "biosdk" "biosdk-service" "/actuator/health" "BioSDK"
    fi
fi

echo -e "\n${BLUE}=== Registration Services ===${NC}\n"

# Packet Manager
if check_namespace "packetmanager"; then
    check_pod_status "packetmanager" "" "Packet Manager"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "packetmanager" "packetmanager-service" "/actuator/health" "Packet Manager"
    fi
fi

# Data Share
if check_namespace "datashare"; then
    check_pod_status "datashare" "" "Data Share"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "datashare" "datashare-service" "/actuator/health" "Data Share"
    fi
fi

# Pre-registration
if check_namespace "prereg"; then
    check_pod_status "prereg" "" "Pre-registration"
    if [ "$SKIP_EXTERNAL" != true ]; then
        # Use /preregistration/v1/applications instead of /status as it's in the VirtualService match list
        test_gateway_service "prereg" "prereg.${MOSIP_DOMAIN}" "/preregistration/v1/applications" "istio-ingressgateway" "Pre-registration"
    fi
fi

# Registration Processor
if check_namespace "regproc"; then
    check_pod_status "regproc" "" "Registration Processor"
    # Test key regproc services
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "regproc" "regproc-packet-receiver-service" "/actuator/health" "Regproc Packet Receiver"
        test_health_endpoint "regproc" "regproc-packet-validator-service" "/actuator/health" "Regproc Packet Validator"
    fi
fi

# Registration Client
if check_namespace "regclient"; then
    check_pod_status "regclient" "" "Registration Client"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_direct_service "regclient" "regclient" "80" "/registration-client/" "Registration Client"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "regclient" "regclient.${MOSIP_DOMAIN}" "/registration-client/" "istio-ingressgateway-internal" "Registration Client"
    fi
fi

echo -e "\n${BLUE}=== Identity Services ===${NC}\n"

# ID Repository
if check_namespace "idrepo"; then
    check_pod_status "idrepo" "" "ID Repository"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "idrepo" "idrepo-service" "/actuator/health" "ID Repository"
    fi
fi

# ID Authentication
if check_namespace "ida"; then
    check_pod_status "ida" "" "ID Authentication"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "ida" "ida-service" "/actuator/health" "ID Authentication"
    fi
fi

# Resident Services
if check_namespace "resident"; then
    check_pod_status "resident" "" "Resident Services"
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "resident" "resident.${MOSIP_DOMAIN}" "/resident/v1/status" "istio-ingressgateway" "Resident Services"
    fi
fi

# Partner Management
if check_namespace "pms"; then
    check_pod_status "pms" "" "Partner Management"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "pms" "pms-service" "/actuator/health" "Partner Management"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "pms" "pmp.${MOSIP_DOMAIN}" "/" "istio-ingressgateway-internal" "Partner Management Portal"
    fi
fi

echo -e "\n${BLUE}=== Supporting Services ===${NC}\n"

# Admin Services
if check_namespace "admin"; then
    check_pod_status "admin" "" "Admin Services"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "admin" "admin-service" "/actuator/health" "Admin Services"
    fi
    if [ "$SKIP_EXTERNAL" != true ]; then
        test_gateway_service "admin" "admin.${MOSIP_DOMAIN}" "/admin/v1/status" "istio-ingressgateway-internal" "Admin Services"
    fi
fi

# Print Service
if check_namespace "print"; then
    check_pod_status "print" "" "Print Service"
    if [ "$SKIP_INTERNAL" != true ]; then
        test_health_endpoint "print" "print-service" "/actuator/health" "Print Service"
    fi
fi

# Partner Onboarder
if check_namespace "partner-onboarder"; then
    check_pod_status "partner-onboarder" "" "Partner Onboarder"
fi

# Mock Services
if check_namespace "mock-abis"; then
    check_pod_status "mock-abis" "" "Mock ABIS"
fi

if check_namespace "mock-smtp"; then
    check_pod_status "mock-smtp" "" "Mock SMTP"
fi

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}Test Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo -e "${YELLOW}Skipped: ${SKIPPED_TESTS}${NC}"

if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed Services:${NC}"
    for service in "${FAILED_SERVICES[@]}"; do
        echo -e "  - ${service}"
    done
fi

if [ ${#SKIPPED_SERVICES[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Skipped Services (not deployed):${NC}"
    for service in "${SKIPPED_SERVICES[@]}"; do
        echo -e "  - ${service}"
    done
fi

echo -e "\n${CYAN}========================================${NC}\n"

# Exit with error if any tests failed (but not if only skipped)
# Re-enable exit on error for final exit code
set -e

if [ $FAILED_TESTS -gt 0 ]; then
    exit 1
else
    exit 0
fi

