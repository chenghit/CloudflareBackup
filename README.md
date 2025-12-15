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
- **DNS Records** - All DNS entries for the zone
- **WAF Rules** - Web Application Firewall rules and configurations
- **Custom Pages** - Custom error pages and challenge pages
- **DNSSEC** - DNSSEC configuration and keys
- **IP Access Rules** - IP allowlist/blocklist rules
- **Load Balancers** - Zone-specific load balancer configurations
- **Page Rules** - Page rules for URL-based configurations
- **Page Shield** - Content Security Policy and script monitoring
- **Rate Limits** - Rate limiting rules and thresholds (new rulesets API)
- **Transform Rules** - URL rewrites, header modifications (request/response)
- **Managed Transforms** - Managed header transformations
- **Cache Rules** - Caching behavior and bypass rules
- **Redirect Rules** - URL redirects and forwarding
- **Origin Rules** - Origin server configurations
- **URL Normalization** - URL normalization settings
- **WAF Overrides** - Custom WAF rule overrides
- **Configuration Rules** - Zone-specific configuration overrides
- **Security Settings** - Security level, challenge TTL, browser checks, insecure JS replacement
- **General Settings** - All zone settings

### Account-Level Data
- **IP Lists** - Account-wide IP lists metadata
- **IP List Items** - Individual items for each IP list
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
│       └── [other configuration files]
├── Domain2/
│   └── YYYY-MM-DD HH-MM-SS/
└── account/
    └── YYYY-MM-DD HH-MM-SS/
        └── IP-Lists.txt
```

Each backup creates timestamped folders containing JSON files with configuration data from the Cloudflare API.

## Authentication Methods

Both scripts now use **Bearer token authentication** (`Authorization: Bearer` header) - the modern Cloudflare API standard.

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

## Requirements

- `curl` command-line tool (included in most modern operating systems)
- `jq` command-line JSON processor (for parsing API responses)
  - Windows: Download from https://jqlang.github.io/jq/download/
  - macOS: `brew install jq`
  - Linux: `apt install jq` or `yum install jq`
- Valid Cloudflare API token with appropriate read permissions
- Network access to Cloudflare API endpoints
