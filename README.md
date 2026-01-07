# CloudflareBackup
Cross-platform scripts to create comprehensive Cloudflare configuration backups using curl and the Cloudflare API.

## Available Scripts

- **Windows**: `Cloudflare_backup.bat` - Batch script for Windows systems
- **macOS/Linux**: `cloudflare_backup.sh` - Bash script for Unix-like systems

## Setup

1. Create a folder for your backups
2. Download the appropriate script for your operating system
3. Configure the script with your credentials and zone information (see Configuration section)

## Running the Scripts

### Windows (Batch Script)
**Via File Explorer:**
1. Browse to the backup folder
2. Double-click `Cloudflare_backup.bat`

**Via Command Prompt:**
1. Open Command Prompt
2. Navigate to the backup folder
3. Execute: `Cloudflare_backup.bat`

### macOS/Linux (Bash Script)
**Via Terminal:**
1. Make the script executable: `chmod +x cloudflare_backup.sh`
2. Run the script: `./cloudflare_backup.sh`

## Configuration

### Windows Script (Cloudflare_backup.bat)
Replace the following placeholders:
- `[REPLACE WITH YOUR API TOKEN]`: API token with read permissions for all zones

Configure domains (zone IDs are auto-discovered):
- `Domain1`, `Domain2`, etc.: Your domain names (e.g., "example.com")
- **Maximum 9 domains by default**

**To support more than 9 domains:**
1. Add more domain variables: `set "Domain10="`, `set "Domain11="`, etc.
2. Update the loop counter: Change `for /L %%i in (1,1,9)` to `for /L %%i in (1,1,N)` where N is your total domain count
3. Update the account ID collection loop similarly

**To use fewer domains:**
- Simply leave unused domain variables empty (e.g., `set "Domain3=""`)

### macOS/Linux Script (cloudflare_backup.sh)
Replace the following placeholders:
- `[REPLACE WITH YOUR API TOKEN]`: API token with read permissions for all zones
- Update the `DOMAINS` array with your domain names (e.g., `DOMAINS=("example.com" "example.org")`)

**No domain count limit** - add as many domains as needed to the array

## What Gets Backed Up

Both scripts create comprehensive backups of the following Cloudflare configurations:

### Zone-Level Data

#### Legacy Endpoints
- **DNS Records** - All DNS entries for the zone
- **WAF Rules** - Web Application Firewall rules (legacy)
- **Custom Pages** - Custom error pages and challenge pages
- **DNSSEC** - DNSSEC configuration and keys
- **IP Access Rules** - IP allowlist/blocklist rules
- **Load Balancers** - Zone-specific load balancer configurations
- **Page Rules** - Page rules for URL-based configurations
- **Page Shield** - Content Security Policy and script monitoring
- **WAF Overrides** - Custom WAF rule overrides
- **General Settings** - All zone settings

#### Modern Rules API
- **Rate Limits** - Rate limiting rules (http_ratelimit phase)
- **URL Normalization** - URL normalization settings
- **Managed Transforms** - Managed header transformations
- **Cache Rules** - Caching behavior rules (http_request_cache_settings phase)
- **Configuration Rules** - Zone configuration overrides (http_config_settings phase)
- **Redirect Rules** - URL redirects (http_request_dynamic_redirect phase)
- **Origin Rules** - Origin server configurations (http_request_origin phase)
- **Custom Error Rules** - Custom error responses (http_custom_errors phase)
- **URL Rewrite Rules** - URL rewrites (http_request_transform phase)
- **Request Header Transform** - Request header modifications (http_request_late_transform phase)
- **Response Header Transform** - Response header modifications (http_response_headers_transform phase)
- **Compression Rules** - Compression settings (http_request_compress phase)

#### CDN and Performance Settings
- **Smart Tiered Cache** - Smart tiered caching configuration
- **Cache Reserve** - Cache reserve settings
- **Argo Smart Routing** - Argo smart routing status
- **Tiered Caching** - Tiered caching configuration

#### Zone Settings
- **Always Online** - Always online mode
- **Development Mode** - Development mode status
- **Early Hints** - Early hints configuration
- **HTTP/2** - HTTP/2 support
- **HTTP/3** - HTTP/3 (QUIC) support
- **IPv6** - IPv6 compatibility
- **WebSockets** - WebSocket support
- **TLS 1.3** - TLS 1.3 configuration
- **Min TLS Version** - Minimum TLS version
- **Zero RTT** - 0-RTT connection resumption
- **Image Resizing** - Image resizing settings
- **Prefetch Preload** - Prefetch and preload settings
- **Proxy Read Timeout** - Proxy read timeout
- **Opportunistic Encryption** - Opportunistic encryption
- **TLS Client Auth** - TLS client authentication
- **Ciphers** - Cipher suite configuration
- **WebP** - WebP image conversion
- **Hotlink Protection** - Hotlink protection
- **Server Side Excludes** - Server-side excludes

#### Security Settings
- **Security Level** - Security level setting
- **Challenge TTL** - Challenge page TTL
- **Browser Check** - Browser integrity check
- **Replace Insecure JS** - Insecure JavaScript replacement
- **WAF Setting** - WAF on/off status

#### Cloudflare for SaaS
- **Fallback Origin** - SaaS custom hostname fallback origin configuration

### Account-Level Data
- **IP Lists** - Account-wide IP lists metadata
- **IP List Items** - Individual items for each list (with kind and name)
- **Bulk Redirect Rules** - Account-level bulk redirect rulesets
- **Load Balancer Pools** - Account-wide load balancer pool configurations

## Output Structure

Backups are organized in the following folder structure:

```
Backup Root/
├── Domain1/
│   └── YYYY-MM-DD HH-MM-SS/
│       ├── DNS.txt
│       ├── WAF.txt
│       ├── Settings.txt
│       ├── Cache-Rules.txt
│       ├── Rate-limits.txt
│       └── [other configuration files]
├── Domain2/
│   └── YYYY-MM-DD HH-MM-SS/
└── account/
    └── YYYY-MM-DD HH-MM-SS/
        ├── IP-Lists.txt
        ├── List-Items-ip-MyIPList.txt
        ├── Bulk-Redirect-Rules.txt
        └── Load-Balancer-Pools.txt
```

Each backup creates timestamped folders containing JSON files with configuration data from the Cloudflare API.

## Authentication Methods

Both scripts use **Bearer token authentication** (`Authorization: Bearer` header) - the modern Cloudflare API standard.

- Create an API token at: https://dash.cloudflare.com/profile/api-tokens
- Required permissions: Read access for all zones and account settings
- Token is more secure than legacy API key + email authentication

## Important Notes

- This creates configuration backups, not a complete account backup
- Account-level settings (billing, team members, etc.) are not included
- Scripts have been tested with Free and Pro zones
- All API responses are saved as JSON files for easy parsing and restoration
- **Windows script limitation**: Maximum 9 domains by default (can be extended manually)
- **macOS/Linux script**: No domain count limit
- Zone IDs and Account IDs are automatically discovered from domain names
- Some endpoints may return errors for features not enabled on your plan (these are skipped in the shell script)

## Requirements

- `curl` command-line tool (included in most modern operating systems)
- `jq` command-line JSON processor (for parsing API responses)
  - Windows: Download from https://jqlang.github.io/jq/download/
  - macOS: `brew install jq`
  - Linux: `apt install jq` or `yum install jq`
- Valid Cloudflare API token with appropriate read permissions
- Network access to Cloudflare API endpoints
