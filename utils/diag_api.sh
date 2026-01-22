#!/bin/bash

# Check if domain parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 mosip.turing.co.uk"
    exit 1
fi

DOMAIN=$1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $2"
    else
        echo -e "${RED}[FAILED]${NC} $2"
    fi
}

# Function to test HTTP endpoints
test_http_endpoint() {
    local url=$1
    local description=$2
    echo -e "\n${YELLOW}Testing $description${NC}"
    echo "URL: $url"
    
    # Using curl with 10 second timeout
    curl -v -k --max-time 10 "$url" 2>&1 | grep "HTTP/"
    local status=$?
    print_status $status "$description"
    return $status
}

# Function to test TCP endpoints
test_tcp_endpoint() {
    local host=$1
    local port=$2
    local description=$3
    echo -e "\n${YELLOW}Testing $description${NC}"
    echo "Host: $host, Port: $port"
    
    # Using nc (netcat) with 5 second timeout
    timeout 5 nc -zv $host $port 2>&1
    local status=$?
    print_status $status "$description"
    return $status
}

# Main testing sequence
echo -e "${YELLOW}Starting MOSIP Diagnostic Tests${NC}"
echo "----------------------------------------"

# Test Internal API endpoints
test_http_endpoint "https://api-internal.${DOMAIN}/httpbin/get?show_env=true" "Internal API Gateway"

# Test MinIO endpoint
test_http_endpoint "https://minio.${DOMAIN}" "MinIO Service"

# Test Kafka endpoint
test_http_endpoint "https://kafka.${DOMAIN}" "Kafka Service"

# Test Keycloak endpoint
test_http_endpoint "https://iam.${DOMAIN}/auth" "Keycloak Service"

# Test Landing page
test_http_endpoint "https://${DOMAIN}/" "Landing Page"

echo -e "\n${YELLOW}Diagnostic Tests Completed${NC}"
echo "----------------------------------------" 