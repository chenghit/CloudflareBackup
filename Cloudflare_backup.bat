@echo off
setlocal enabledelayedexpansion

:: Date and time setup
if "%date%A" LSS "A" (set toks=1-3) else (set toks=2-4)
for /f "tokens=2-4 delims=(-)" %%a in ('echo:^|date') do (
    for /f "tokens=%toks% delims=.-/ " %%i in ('date/t') do (
        set '%%a'=%%i
        set '%%b'=%%j
        set '%%c'=%%k))
if %'yy'% LSS 100 set 'yy'=20%'yy'%
set "BatchDate=%'yy'%-%'mm'%-%'dd'%"

for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set "hour=%%a"
    set "minute=%%b"
    set "second=%%c"
)
set "BatchTime=%hour%-%minute%-%second%"

:: Configuration
set "APIToken=[REPLACE WITH YOUR API TOKEN]"

:: Define domains - zone IDs will be auto-discovered
set "Domain1=[REPLACE WITH DOMAIN 1]"
set "Domain2=[REPLACE WITH DOMAIN 2]"
set "Domain3="
set "Domain4="
set "Domain5="
set "Domain6="
set "Domain7="
set "Domain8="
set "Domain9="

echo Starting Cloudflare backup...

:: Collect unique account IDs from zones
set "AccountIDs="
for /L %%i in (1,1,9) do (
    if defined Domain%%i (
        for /f "tokens=*" %%z in ('curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=!Domain%%i!" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" ^| jq -r ".result[0].id // empty"') do (
            if not "%%z"=="" (
                for /f "tokens=*" %%a in ('curl -s -X GET "https://api.cloudflare.com/client/v4/zones/%%z" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" ^| jq -r ".result.account.id // empty"') do (
                    if not "%%a"=="" (
                        echo !AccountIDs! | find "%%a" >nul || set "AccountIDs=!AccountIDs! %%a"
                    )
                )
            )
        )
    )
)

:: Backup account-level resources for each unique account
for %%a in (!AccountIDs!) do (
    set "FolderAccount=account\%BatchDate% %BatchTime%"
    md "!FolderAccount!" 2>nul
    
    echo Backing up account-level resources (Account ID: %%a)
    
    curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/%%a/rules/lists" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FolderAccount!\IP-Lists.txt"
    echo   Backed up rules/lists
    
    for /f "tokens=*" %%i in ('type "!FolderAccount!\IP-Lists.txt" ^| jq -r ".result[]?.id // empty"') do (
        for /f "tokens=1,2 delims=|" %%n in ('type "!FolderAccount!\IP-Lists.txt" ^| jq -r ".result[] | select(.id==\"%%i\") | .kind + \"|\" + .name"') do (
            curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/%%a/rules/lists/%%i/items" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FolderAccount!\List-Items-%%n-%%o.txt"
            echo   Backed up items for %%n list: %%o
        )
    )
    
    curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/%%a/rulesets?phase=http_request_redirect" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FolderAccount!\Bulk-Redirect-Rules.txt"
    echo   Backed up bulk redirect rules
    
    curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/%%a/load_balancers/pools" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FolderAccount!\Load-Balancer-Pools.txt"
    echo   Backed up load_balancers/pools
    
    echo Account backup completed
)

:: Loop through domains
for /L %%i in (1,1,9) do (
    if defined Domain%%i (
        echo Processing !Domain%%i!...
        
        for /f "delims=" %%z in ('curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=!Domain%%i!" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json"') do set "ZoneResponse=%%z"
        for /f "tokens=*" %%z in ('echo !ZoneResponse! ^| jq -r ".result[0].id // empty"') do set "ZoneID=%%z"
        
        if defined ZoneID (
            set "FullFolder=!Domain%%i!\%BatchDate% %BatchTime%"
            echo Backing up !Domain%%i! (Zone ID: !ZoneID!)
            md "!FullFolder!"
            
            :: Legacy endpoints
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/firewall/rules?per_page=100" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\WAF.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/custom_pages" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Custom-Pages.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/dns_records" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\DNS.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/dnssec" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\DNSSEC.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/firewall/access_rules/rules" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\IP-Access-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/load_balancers" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Load-Balancers.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/pagerules" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Page-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/page_shield" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Page_Shield.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Settings.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/firewall/waf/overrides" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\WAF-Overrides.txt"
            
            :: Modern Rules API endpoints
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_ratelimit/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Rate-limits.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/url_normalization" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\URL-Normalization.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/managed_headers" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Managed-Transforms.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_cache_settings/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Cache-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_config_settings/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Configuration-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_dynamic_redirect/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Redirect-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_origin/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Origin-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_custom_errors/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Custom-Error-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_transform/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\URL-Rewrite-Rules.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_late_transform/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Request-Header-Transform.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_response_headers_transform/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Response-Header-Transform.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/rulesets/phases/http_request_compress/entrypoint" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Compression-Rules.txt"
            
            :: CDN and Performance Settings
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/cache/smart_tiered_cache" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Smart-Tiered-Cache.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/cache/cache_reserve" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Cache-Reserve.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/argo/smart_routing" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Argo-Smart-Routing.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/argo/tiered_caching" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Tiered-Cache.txt"
            
            :: Zone Settings
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/always_online" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Always-Online.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/development_mode" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Development-Mode.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/early_hints" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Early-Hints.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/http2" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\HTTP2.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/http3" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\HTTP3.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/ipv6" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\IPv6.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/websockets" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\WebSockets.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/tls_1_3" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\TLS-1-3.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/min_tls_version" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Min-TLS-Version.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/0rtt" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Zero-RTT.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/image_resizing" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Image-Resizing.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/prefetch_preload" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Prefetch-Preload.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/proxy_read_timeout" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Proxy-Read-Timeout.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/opportunistic_encryption" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Opportunistic-Encryption.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/tls_client_auth" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\TLS-Client-Auth.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/ciphers" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Ciphers.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/webp" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\WebP.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/hotlink_protection" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Hotlink-Protection.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/server_side_excludes" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Server-Side-Excludes.txt"
            
            :: Security settings
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/security_level" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Security-Security-level.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/challenge_ttl" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Security-Challenge-TTL.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/browser_check" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Security-Browser-Check.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/replace_insecure_js" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\Security-replace-insecure-s.txt"
            curl -s -X GET "https://api.cloudflare.com/client/v4/zones/!ZoneID!/settings/waf" -H "Authorization: Bearer !APIToken!" -H "Content-Type: application/json" -o "!FullFolder!\WAF-Setting.txt"
            
            echo Backup completed for !Domain%%i!
            echo.
        ) else (
            echo Error: Could not find zone ID for !Domain%%i!
        )
    )
)

echo All backups completed!
pause
endlocal
