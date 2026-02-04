# CloudflareBackup
Cross-platform scripts to create comprehensive Cloudflare configuration backups using curl and the Cloudflare API.

## Available Scripts

- **Windows**: `cloudflare_backup.bat` - Batch script for Windows systems
- **macOS/Linux**: `cloudflare_backup.sh` - Bash script for Unix-like systems

## Setup

1. Create a folder for your backups
2. Download the appropriate script for your operating system
3. Copy `config.example` to `config`
4. Edit `config` file with your API token and domain names (see Configuration section below)

## Running the Scripts

### Windows (Batch Script)
**Via File Explorer:**
1. Browse to the backup folder
2. Double-click `cloudflare_backup.bat`

**Via Command Prompt:**
1. Open Command Prompt
2. Navigate to the backup folder
3. Execute: `cloudflare_backup.bat`

### macOS/Linux (Bash Script)
**Via Terminal:**
1. Make the script executable: `chmod +x cloudflare_backup.sh`
2. Run the script: `./cloudflare_backup.sh`

## Configuration

Both scripts now use a `config` file for credentials and domain names:

1. **Copy the example config:**
   ```bash
   cp config.example config
   ```

2. **Edit the `config` file:**
   - Set `API_TOKEN` to your Cloudflare API token (create at: https://dash.cloudflare.com/profile/api-tokens)
   - Set `DOMAIN1`, `DOMAIN2`, etc. to your domain names
   - Add more domains as needed (no limit for shell script, 9 domains max for batch script by default)

3. **Security:**
   - The `config` file is in `.gitignore` and will not be committed to version control
   - Never share or commit your `config` file with real credentials
   - Keep your API token secure

**Example config:**
```
API_TOKEN=your_actual_cloudflare_api_token
DOMAIN1=example.com
DOMAIN2=example.org
DOMAIN3=example.net
```

### Windows Script Notes
- **Maximum 9 domains by default**
- To support more domains, edit the batch script to add `DOMAIN10`, `DOMAIN11`, etc. variables and update loop counters

### macOS/Linux Script Notes
- **No domain count limit** - add as many `DOMAIN` entries as needed

## What Gets Backed Up

Both scripts create comprehensive backups of the following Cloudflare configurations:

### Zone-Level Data

#### Modern WAF Rules API
- **WAF Custom Rules** - Custom firewall rules (http_request_firewall_custom phase)
- **WAF Managed Rules** - Managed firewall rulesets (http_request_firewall_managed phase)

#### Modern Rules API
- **Rate Limits** - Rate limiting rules (http_ratelimit phase)
- **Cache Rules** - Caching behavior rules (http_request_cache_settings phase)
- **Configuration Rules** - Zone configuration overrides (http_config_settings phase)
- **Redirect Rules** - URL redirects (http_request_dynamic_redirect phase)
- **Origin Rules** - Origin server configurations (http_request_origin phase)
- **Custom Error Rules** - Custom error responses (http_custom_errors phase)
- **URL Rewrite Rules** - URL rewrites (http_request_transform phase)
- **Request Header Transform** - Request header modifications (http_request_late_transform phase)
- **Response Header Transform** - Response header modifications (http_response_headers_transform phase)
- **Compression Rules** - Compression settings (http_request_compress phase)
- **Cloud Connector Rules** - Cloud storage provider routing rules (Beta)

#### Core Infrastructure
- **DNS Records** - All DNS entries for the zone
- **DNSSEC** - DNSSEC configuration and keys
- **Load Balancers** - Zone-specific load balancer configurations
- **IP Access Rules** - IP allowlist/blocklist rules
- **Page Shield** - Content Security Policy and script monitoring
- **Custom Pages** - Custom error pages and challenge pages

#### CDN and Performance Settings
- **Smart Tiered Cache** - Smart tiered caching configuration
- **Cache Reserve** - Cache reserve settings
- **Argo Smart Routing** - Argo smart routing status
- **Tiered Caching** - Tiered caching configuration
- **URL Normalization** - URL normalization settings
- **Managed Transforms** - Managed header transformations

#### Zone Settings
- **TLS 1.3** - TLS 1.3 configuration
- **Min TLS Version** - Minimum TLS version
- **Ciphers** - Cipher suite configuration
- **HTTP/3** - HTTP/3 (QUIC) support
- **HTTP/2** - HTTP/2 support
- **IPv6** - IPv6 compatibility
- **Zero RTT** - 0-RTT connection resumption
- **WebSockets** - WebSocket support
- **Early Hints** - Early hints configuration
- **Image Resizing** - Image resizing settings
- **WebP** - WebP image conversion
- **Development Mode** - Development mode status
- **Always Online** - Always online mode
- **Hotlink Protection** - Hotlink protection
- **Server Side Excludes** - Server-side excludes
- **Opportunistic Encryption** - Opportunistic encryption
- **TLS Client Auth** - TLS client authentication

#### Security Settings
- **Security Level** - Security level setting
- **Challenge TTL** - Challenge page TTL
- **Browser Check** - Browser integrity check

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
