#!/bin/bash

# Cloudflare Backup Script for macOS/Linux
# Optimized version with associative arrays and auto zone discovery

set -euo pipefail

# Check if config file exists
if [[ ! -f "config" ]]; then
    echo "❌ Error: 'config' file not found!"
    echo ""
    echo "Please create a 'config' file:"
    echo "  1. Copy 'config.example' to 'config'"
    echo "  2. Edit 'config' and add your API token and domains"
    echo ""
    exit 1
fi

# Load configuration from config file
source config

# Validate API token
if [[ -z "${API_TOKEN:-}" ]] || [[ "$API_TOKEN" == "your_cloudflare_api_token_here" ]]; then
    echo "❌ Error: API_TOKEN not configured!"
    echo "Please edit the 'config' file and set your Cloudflare API token."
    exit 1
fi

# Build domains array from config
DOMAINS=()
for i in {1..99}; do
    var_name="DOMAIN$i"
    domain="${!var_name:-}"
    if [[ -n "$domain" ]] && [[ "$domain" != "example.com" ]] && [[ "$domain" != "example"* ]]; then
        DOMAINS+=("$domain")
    fi
done

# Check if at least one domain is configured
if [[ ${#DOMAINS[@]} -eq 0 ]]; then
    echo "❌ Error: No domains configured!"
    echo "Please edit the 'config' file and add at least one domain."
    exit 1
fi

BATCH_DATE=$(date +"%Y-%m-%d")
BATCH_TIME=$(date +"%H-%M-%S")

# Function to get zone ID for a domain
get_zone_id() {
    local domain=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | \
        jq -r '.result[0].id // empty'
}

# Function to get account ID from zone
get_account_id_from_zone() {
    local zone_id=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | \
        jq -r '.result.account.id // empty'
}

# Function to backup zone data
backup_zone() {
    local zone_id=$1
    local domain=$2
    local folder="$domain/$BATCH_DATE $BATCH_TIME"
    
    echo "Backing up $domain (Zone ID: $zone_id)"
    mkdir -p "$folder"
    
    # Define backup endpoints (file:endpoint pairs)
    local endpoints=(
        # Modern Rulesets API endpoints
        "WAF-Custom-Rules.txt:rulesets/phases/http_request_firewall_custom/entrypoint"
        "WAF-Managed-Rules.txt:rulesets/phases/http_request_firewall_managed/entrypoint"
        "Rate-limits.txt:rulesets/phases/http_ratelimit/entrypoint"
        "Cache-Rules.txt:rulesets/phases/http_request_cache_settings/entrypoint"
        "Configuration-Rules.txt:rulesets/phases/http_config_settings/entrypoint"
        "Redirect-Rules.txt:rulesets/phases/http_request_dynamic_redirect/entrypoint"
        "Origin-Rules.txt:rulesets/phases/http_request_origin/entrypoint"
        "Compression-Rules.txt:rulesets/phases/http_request_compress/entrypoint"
        "URL-Rewrite-Rules.txt:rulesets/phases/http_request_transform/entrypoint"
        "Request-Header-Transform.txt:rulesets/phases/http_request_late_transform/entrypoint"
        "Response-Header-Transform.txt:rulesets/phases/http_response_headers_transform/entrypoint"        
        "Custom-Error-Rules.txt:rulesets/phases/http_custom_errors/entrypoint"
        "Cloud-Connector-Rules.txt:cloud_connector/rules"

        # Core Infrastructure
        "DNS.txt:dns_records"
        "DNSSEC.txt:dnssec"
        "Load-Balancers.txt:load_balancers"
        "SaaS-Fallback-Origin.txt:custom_hostnames/fallback_origin"
        "IP-Access-Rules.txt:firewall/access_rules/rules"

        # CDN and Performance Settings
        "Smart-Tiered-Cache.txt:cache/smart_tiered_cache"
        "Cache-Reserve.txt:cache/cache_reserve"
        "Argo-Smart-Routing.txt:argo/smart_routing"
        "Tiered-Cache.txt:argo/tiered_caching"
        "URL-Normalization.txt:url_normalization"

        # Zone Settings (only those NOT covered by new Rules to avoid duplicates)
        "TLS-1-3.txt:settings/tls_1_3"
        "Min-TLS-Version.txt:settings/min_tls_version"
        "Ciphers.txt:settings/ciphers"
        "HTTP3.txt:settings/http3"
        "HTTP2.txt:settings/http2"
        "IPv6.txt:settings/ipv6"
        "Zero-RTT.txt:settings/0rtt"
        "WebSockets.txt:settings/websockets"
        "Early-Hints.txt:settings/early_hints"
        "Image-Resizing.txt:settings/image_resizing"
        "WebP.txt:settings/webp"
        "Development-Mode.txt:settings/development_mode"
        "Always-Online.txt:settings/always_online"
        "Hotlink-Protection.txt:settings/hotlink_protection"
        "Server-Side-Excludes.txt:settings/server_side_excludes"
        "Security-level.txt:settings/security_level"
        "Challenge-TTL.txt:settings/challenge_ttl"
        "Browser-Check.txt:settings/browser_check"
        
        # Others
        "Page_Shield.txt:page_shield"
        "Custom-Pages.txt:custom_pages"
        "Managed-Transforms.txt:managed_headers"
        "Opportunistic-Encryption.txt:settings/opportunistic_encryption"
        "TLS-Client-Auth.txt:settings/tls_client_auth"
    )
    
    # Backup each endpoint
    for entry in "${endpoints[@]}"; do
        local file="${entry%%:*}"
        local endpoint="${entry#*:}"
        local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/$endpoint" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json")
        
        # Skip if error 10003 (no configuration exists) or other common errors
        if echo "$response" | grep -q '"code": 10003\|"code": 1001\|"code": 1014'; then
            echo "  ⊘ Skipped $endpoint (not configured or not available)"
            continue
        fi
        
        echo "$response" > "$folder/$file"
        echo "  ✓ Backed up $endpoint"
    done
    
    echo "✓ Backup completed for $domain"
}

# Function to backup account-level data
backup_account() {
    local account_id=$1
    local folder="account/$BATCH_DATE $BATCH_TIME"
    
    echo "Backing up account-level resources (Account ID: $account_id)"
    mkdir -p "$folder"
    
    # Backup IP Lists metadata
    local lists_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$lists_response" > "$folder/IP-Lists.txt"
    echo "  ✓ Backed up rules/lists"
    
    # Backup items for each list
    echo "$lists_response" | jq -r '.result[]?.id // empty' | while read -r list_id; do
        [[ -z "$list_id" ]] && continue
        local list_name=$(echo "$lists_response" | jq -r ".result[] | select(.id==\"$list_id\") | .name")
        local list_kind=$(echo "$lists_response" | jq -r ".result[] | select(.id==\"$list_id\") | .kind")
        local items_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists/$list_id/items" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json")
        echo "$items_response" > "$folder/List-Items-$list_kind-$list_name.txt"
        echo "  ✓ Backed up items for $list_kind list: $list_name"
    done
    
    # Backup Bulk Redirect Rules (account-level rulesets)
    local redirect_rulesets=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/rulesets?phase=http_request_redirect" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    
    if ! echo "$redirect_rulesets" | grep -q '"code": 10003'; then
        echo "$redirect_rulesets" > "$folder/Bulk-Redirect-Rules.txt"
        echo "  ✓ Backed up bulk redirect rules"
    else
        echo "  ⊘ Skipped bulk redirect rules (not configured)"
    fi
    
    # Backup Load Balancer Pools
    local pools_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/load_balancers/pools" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    
    if ! echo "$pools_response" | grep -q '"code": 10003'; then
        echo "$pools_response" > "$folder/Load-Balancer-Pools.txt"
        echo "  ✓ Backed up load_balancers/pools"
    else
        echo "  ⊘ Skipped load_balancers/pools (not configured)"
    fi
    
    echo "✓ Account backup completed"
}

# Main execution
echo "Starting Cloudflare backup..."

# Collect all unique account IDs from zones
account_ids=""
for domain in "${DOMAINS[@]}"; do
    zone_id=$(get_zone_id "$domain")
    if [[ -n "$zone_id" ]]; then
        account_id=$(get_account_id_from_zone "$zone_id")
        if [[ -n "$account_id" ]] && [[ ! " $account_ids " =~ " $account_id " ]]; then
            account_ids="$account_ids $account_id"
        fi
    fi
done

# Backup account-level resources for each unique account
for account_id in $account_ids; do
    backup_account "$account_id"
done

# Backup zones
for domain in "${DOMAINS[@]}"; do
    echo "Processing $domain..."
    
    zone_id=$(get_zone_id "$domain")
    
    if [[ -z "$zone_id" ]]; then
        echo "❌ Error: Could not find zone ID for $domain"
        continue
    fi
    
    backup_zone "$zone_id" "$domain"
done

echo "All backups completed!"
