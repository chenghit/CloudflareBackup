#!/bin/bash

# Cloudflare Backup Script for macOS
# Based on freitasm/CloudflareBackup

# Generate timestamp
BATCH_DATE=$(date +"%Y-%m-%d")
BATCH_TIME=$(date +"%H-%M-%S")

# API token
API_TOKEN="[REPLACE WITH YOUR API TOKEN]"

# Define zone ID and domain pairs
declare -a ZONE_IDS=("[REPLACE WITH ZONE ID TO BACKUP]" "[REPLACE WITH ZONE ID TO BACKUP]" "[REPLACE WITH ZONE ID TO BACKUP]")
declare -a DOMAINS=("[REPLACE WITH DOMAIN NAME FOR THIS ZONE]" "[REPLACE WITH DOMAIN NAME FOR THIS ZONE]" "[REPLACE WITH DOMAIN NAME FOR THIS ZONE]")

# Loop through zones
for i in "${!ZONE_IDS[@]}"; do
    ZONE_ID="${ZONE_IDS[$i]}"
    DOMAIN="${DOMAINS[$i]}"
    FULL_FOLDER="$DOMAIN/$BATCH_DATE $BATCH_TIME"
    
    echo "ZoneID=$ZONE_ID"
    echo "Domain=$DOMAIN"
    echo "FullFolder=$FULL_FOLDER"
    
    mkdir -p "$FULL_FOLDER"
    
    # Backup zone configurations
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/rules?per_page=100" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/WAF.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/custom_pages" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Custom-Pages.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/DNS.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dnssec" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/DNSSEC.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/access_rules/rules" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/IP-Access-Rules.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/load_balancers" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Load-Balancers.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/page_shield" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Page_Shield.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rate_limits" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Rate-Limits.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_transform/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Transform-Rewrite-URL.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_late_transform/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Transform-Modify-Request-Header.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_response_headers_transform/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Transform-Modify-Response-Headers.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/managed_headers" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Transform-Managed-Transforms.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_cache_settings/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Cache-Rules.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Redirect-Rules.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_request_origin/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Origin-Rules.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/url_normalization" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/URL-Normalisation.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/ua_rules" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/UA-Blocking.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/firewall/waf/overrides" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/WAF-Overrides.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Settings.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets/phases/http_config_settings/entrypoint" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Configuration-Rules.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Security-Security-level.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/challenge_ttl" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Security-Challenge-TTL.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/browser_check" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Security-Browser-Check.txt"
    
    curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/replace_insecure_js" \
        -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
        -o "$FULL_FOLDER/Security-replace-insecure-s.txt"
    
    echo
done

# Uncomment and update these if you have load balancer pools

# Backup account level data
# FOLDER_ACCOUNT="account/$BATCH_DATE $BATCH_TIME"
# mkdir -p "$FOLDER_ACCOUNT"

# curl -X GET "https://api.cloudflare.com/client/v4/user/load_balancers/pools" \
#     -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
#     -o "$FOLDER_ACCOUNT/Load-Balancers-Pools.txt"

# curl -X GET "https://api.cloudflare.com/client/v4/user/load_balancers/pools/[REPLACE WITH LOAD BALANCER POOL ID 1]" \
#     -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
#     -o "$FOLDER_ACCOUNT/Load-Balancers-Pools-Details-1.txt"

# curl -X GET "https://api.cloudflare.com/client/v4/user/load_balancers/pools/[REPLACE WITH LOAD BALANCER POOL ID 2]" \
#     -H "Authorization: Bearer $API_TOKEN" -H "Content-Type: application/json" \
#     -o "$FOLDER_ACCOUNT/Load-Balancers-Pools-Details-2.txt"

echo "Backup completed!"
