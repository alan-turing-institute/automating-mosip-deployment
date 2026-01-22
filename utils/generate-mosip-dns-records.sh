#!/bin/bash
# Script to generate MOSIP DNS records
# This script creates A and CNAME records for MOSIP deployment

set -e

echo "================================================"
echo "MOSIP DNS Records Generator"
echo "================================================"
echo ""

# Get MOSIP domain
read -p "Enter your MOSIP domain (e.g., mosip.example.com): " MOSIP_DOMAIN

if [ -z "$MOSIP_DOMAIN" ]; then
    echo "Error: MOSIP domain cannot be empty"
    exit 1
fi

# Get IP addresses
echo ""
echo "Enter IP addresses for A records:"
read -p "  OBS Nginx Private IP (for rancher.${MOSIP_DOMAIN}): " OBS_NGINX_IP
read -p "  MOSIP Nginx Private IP (for api-internal.${MOSIP_DOMAIN}): " MOSIP_NGINX_PRIVATE_IP
read -p "  MOSIP Public IP (for api.${MOSIP_DOMAIN}): " MOSIP_PUBLIC_IP

if [ -z "$OBS_NGINX_IP" ] || [ -z "$MOSIP_NGINX_PRIVATE_IP" ] || [ -z "$MOSIP_PUBLIC_IP" ]; then
    echo "Error: All IP addresses are required"
    exit 1
fi

# Output file
OUTPUT_FILE="mosip-${MOSIP_DOMAIN}-records.txt"

echo ""
echo "Generating DNS records file: ${OUTPUT_FILE}"
echo ""

# Generate DNS records
cat > "$OUTPUT_FILE" << EOF
\$TTL 300
rancher.${MOSIP_DOMAIN}.                IN      A       ${OBS_NGINX_IP}
rancher-keycloak.${MOSIP_DOMAIN}.       IN      A       ${OBS_NGINX_IP}
api-internal.${MOSIP_DOMAIN}.           IN      A       ${MOSIP_NGINX_PRIVATE_IP}
api.${MOSIP_DOMAIN}.                    IN      A       ${MOSIP_PUBLIC_IP}
prereg.${MOSIP_DOMAIN}.                 IN      CNAME   api.${MOSIP_DOMAIN}.
resident.${MOSIP_DOMAIN}.               IN      CNAME   api.${MOSIP_DOMAIN}.
idp.${MOSIP_DOMAIN}.                    IN      CNAME   api.${MOSIP_DOMAIN}.
${MOSIP_DOMAIN}.                        IN      CNAME   api-internal.${MOSIP_DOMAIN}.
activemq.${MOSIP_DOMAIN}.               IN      CNAME   api-internal.${MOSIP_DOMAIN}.
kibana.${MOSIP_DOMAIN}.                 IN      CNAME   api-internal.${MOSIP_DOMAIN}.
regclient.${MOSIP_DOMAIN}.              IN      CNAME   api-internal.${MOSIP_DOMAIN}.
admin.${MOSIP_DOMAIN}.                  IN      CNAME   api-internal.${MOSIP_DOMAIN}.
object-store.${MOSIP_DOMAIN}.           IN      CNAME   api-internal.${MOSIP_DOMAIN}.
minio.${MOSIP_DOMAIN}.                  IN      CNAME   api-internal.${MOSIP_DOMAIN}.
kafka.${MOSIP_DOMAIN}.                  IN      CNAME   api-internal.${MOSIP_DOMAIN}.
iam.${MOSIP_DOMAIN}.                    IN      CNAME   api-internal.${MOSIP_DOMAIN}.
postgres.${MOSIP_DOMAIN}.               IN      CNAME   api-internal.${MOSIP_DOMAIN}.
pmp.${MOSIP_DOMAIN}.                    IN      CNAME   api-internal.${MOSIP_DOMAIN}.
onboarder.${MOSIP_DOMAIN}.              IN      CNAME   api-internal.${MOSIP_DOMAIN}.
smtp.${MOSIP_DOMAIN}.                   IN      CNAME   api-internal.${MOSIP_DOMAIN}.
EOF

echo "✓ DNS records generated successfully: ${OUTPUT_FILE}"
echo ""
echo "Summary:"
echo "--------"
echo "Domain:                    ${MOSIP_DOMAIN}"
echo "OBS Nginx IP:              ${OBS_NGINX_IP}"
echo "MOSIP Nginx Private IP:    ${MOSIP_NGINX_PRIVATE_IP}"
echo "MOSIP Public IP:           ${MOSIP_PUBLIC_IP}"
echo ""
echo "Total records:"
echo "  - 4 A records"
echo "  - 17 CNAME records"
echo ""
echo "Next steps:"
echo "1. Review the generated records file: ${OUTPUT_FILE}"
echo "2. Import to your DNS provider or manually add the records"
echo "3. Wait for DNS propagation (usually 5-60 minutes)"
echo "4. Verify records using: dig ${MOSIP_DOMAIN}"
echo ""
echo "⚠️  Important note:"
echo "    The apex domain (${MOSIP_DOMAIN}) has a CNAME to api-internal.${MOSIP_DOMAIN}"
echo "    Some DNS providers don't support CNAME at apex. If that's the case,"
echo "    replace it with an A record pointing to ${MOSIP_NGINX_PRIVATE_IP}"
echo ""

