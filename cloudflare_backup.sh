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

# Function to get account ID
get_account_id() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" | \
        jq -r '.result[0].id // empty'
}

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
        "WAF.txt:firewall/rules?per_page=100"
        "Custom-Pages.txt:custom_pages"
        "DNS.txt:dns_records"
        "DNSSEC.txt:dnssec"
        "IP-Access-Rules.txt:firewall/access_rules/rules"
        "Load-Balancers.txt:load_balancers"
        "Page-Rules.txt:pagerules"
        "Page_Shield.txt:page_shield"
        "Rate-limits.txt:rulesets/phases/http_ratelimit/entrypoint"
        "Transform-Rewrite-URL.txt:rulesets/phases/http_request_transform/entrypoint"
        "Transform-Modify-Request-Header.txt:rulesets/phases/http_request_late_transform/entrypoint"
        "Transform-Modify-Response-Headers.txt:rulesets/phases/http_response_headers_transform/entrypoint"
        "Transform-Managed-Transforms.txt:managed_headers"
        "Cache-Rules.txt:rulesets/phases/http_request_cache_settings/entrypoint"
        "Redirect-Rules.txt:rulesets/phases/http_request_dynamic_redirect/entrypoint"
        "Origin-Rules.txt:rulesets/phases/http_request_origin/entrypoint"
        "URL-Normalisation.txt:url_normalization"
        "WAF-Overrides.txt:firewall/waf/overrides"
        "Settings.txt:settings"
        "Configuration-Rules.txt:rulesets/phases/http_config_settings/entrypoint"
        "Security-Security-level.txt:settings/security_level"
        "Security-Challenge-TTL.txt:settings/challenge_ttl"
        "Security-Browser-Check.txt:settings/browser_check"
        "Security-replace-insecure-s.txt:settings/replace_insecure_js"
    )
    
    # Backup each endpoint
    for entry in "${endpoints[@]}"; do
        local file="${entry%%:*}"
        local endpoint="${entry#*:}"
        local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/$endpoint" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json")
        
        # Skip if error 10003 (no configuration exists)
        if echo "$response" | grep -q '"code": 10003'; then
            echo "  ⊘ Skipped $endpoint (not configured)"
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
    local list_ids=$(echo "$lists_response" | jq -r '.result[]?.id // empty')
    for list_id in $list_ids; do
        local list_name=$(echo "$lists_response" | jq -r ".result[] | select(.id==\"$list_id\") | .name")
        local items_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists/$list_id/items" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json")
        echo "$items_response" > "$folder/IP-List-Items-$list_name.txt"
        echo "  ✓ Backed up items for list: $list_name"
    done
    
    # Backup Load Balancer Pools
    local response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$account_id/load_balancers/pools" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json")
    
    if echo "$response" | grep -q '"code": 10003'; then
        echo "  ⊘ Skipped load_balancers/pools (not configured)"
    else
        echo "$response" > "$folder/Load-Balancer-Pools.txt"
        echo "  ✓ Backed up load_balancers/pools"
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
