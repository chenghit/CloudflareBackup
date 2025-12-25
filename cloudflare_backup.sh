#!/bin/bash

# Cloudflare Backup Script for macOS
# Optimized version with associative arrays and auto zone discovery

set -euo pipefail

# Configuration
API_TOKEN="[REPLACE WITH YOUR API TOKEN]"
BATCH_DATE=$(date +"%Y-%m-%d")
BATCH_TIME=$(date +"%H-%M-%S")

# Define domains - zone IDs will be auto-discovered
DOMAINS=("[REPLACE WITH DOMAIN 1]" "[REPLACE WITH DOMAIN 2]")

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
        # Legacy endpoints (still useful for reference)
        "WAF.txt:firewall/rules?per_page=100"
        "Custom-Pages.txt:custom_pages"
        "DNS.txt:dns_records"
        "DNSSEC.txt:dnssec"
        "IP-Access-Rules.txt:firewall/access_rules/rules"
        "Load-Balancers.txt:load_balancers"
        "Page-Rules.txt:pagerules"
        "Page_Shield.txt:page_shield"
        "Settings.txt:settings"
        "WAF-Overrides.txt:firewall/waf/overrides"
        
        # Modern Rules API endpoints
        "Rate-limits.txt:rulesets/phases/http_ratelimit/entrypoint"
        "URL-Normalization.txt:url_normalization"
        "Managed-Transforms.txt:managed_headers"
        "Cache-Rules.txt:rulesets/phases/http_request_cache_settings/entrypoint"
        "Configuration-Rules.txt:rulesets/phases/http_config_settings/entrypoint"
        "Redirect-Rules.txt:rulesets/phases/http_request_dynamic_redirect/entrypoint"
        "Origin-Rules.txt:rulesets/phases/http_request_origin/entrypoint"
        "Custom-Error-Rules.txt:rulesets/phases/http_custom_errors/entrypoint"
        "URL-Rewrite-Rules.txt:rulesets/phases/http_request_transform/entrypoint"
        "Request-Header-Transform.txt:rulesets/phases/http_request_late_transform/entrypoint"
        "Response-Header-Transform.txt:rulesets/phases/http_response_headers_transform/entrypoint"
        "Compression-Rules.txt:rulesets/phases/http_request_compress/entrypoint"
        
        # CDN and Performance Settings (not covered by Rules)
        "Smart-Tiered-Cache.txt:cache/smart_tiered_cache"
        "Cache-Reserve.txt:cache/cache_reserve"
        "Argo-Smart-Routing.txt:argo/smart_routing"
        "Tiered-Cache.txt:argo/tiered_caching"
        
        # Zone Settings (only those NOT covered by new Rules to avoid duplicates)
        "Always-Online.txt:settings/always_online"
        "Development-Mode.txt:settings/development_mode"
        "Early-Hints.txt:settings/early_hints"
        "HTTP2.txt:settings/http2"
        "HTTP3.txt:settings/http3"
        "IPv6.txt:settings/ipv6"
        "WebSockets.txt:settings/websockets"
        "TLS-1-3.txt:settings/tls_1_3"
        "Min-TLS-Version.txt:settings/min_tls_version"
        "Zero-RTT.txt:settings/0rtt"
        "Image-Resizing.txt:settings/image_resizing"
        "Prefetch-Preload.txt:settings/prefetch_preload"
        "Proxy-Read-Timeout.txt:settings/proxy_read_timeout"
        "Opportunistic-Encryption.txt:settings/opportunistic_encryption"
        "TLS-Client-Auth.txt:settings/tls_client_auth"
        "Ciphers.txt:settings/ciphers"
        "WebP.txt:settings/webp"
        "Hotlink-Protection.txt:settings/hotlink_protection"
        "Server-Side-Excludes.txt:settings/server_side_excludes"
        
        # Security settings (basic ones not fully covered by Configuration Rules)
        "Security-Security-level.txt:settings/security_level"
        "Security-Challenge-TTL.txt:settings/challenge_ttl"
        "Security-Browser-Check.txt:settings/browser_check"
        "Security-replace-insecure-s.txt:settings/replace_insecure_js"
        "WAF-Setting.txt:settings/waf"
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
