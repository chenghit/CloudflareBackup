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
- `[REPLACE WITH YOUR CLOUDFLARE LOGIN EMAIL]`: Your Cloudflare login email
- `[REPLACE WITH YOUR API KEY]`: API key with read permissions for all zones

For each zone (up to 9 zones by default):
- `[REPLACE WITH ZONE ID TO BACKUP]`: The Zone ID from Cloudflare dashboard
- `[REPLACE WITH DOMAIN NAME FOR THIS ZONE]`: Domain name for folder organization

To modify zone count:
- Add/remove `ZoneID#` and `Domain#` pairs
- Update the loop counter in `for /L %%i in (1,1,9)` (change 9 to your zone count)

### macOS/Linux Script (cloudflare_backup.sh)
Replace the following placeholders:
- `[REPLACE WITH YOUR API TOKEN]`: Bearer token with read permissions
- Update the `ZONE_IDS` array with your zone IDs
- Update the `DOMAINS` array with corresponding domain names

For load balancer pools (optional):
- Uncomment the account-level backup section
- Replace `[REPLACE WITH LOAD BALANCER POOL ID]` with actual pool IDs

## What Gets Backed Up

Both scripts create comprehensive backups of the following Cloudflare configurations:

### Zone-Level Data
- **DNS Records** - All DNS entries for the zone
- **WAF Rules** - Web Application Firewall rules and configurations
- **Custom Pages** - Custom error pages and challenge pages
- **DNSSEC** - DNSSEC configuration and keys
- **IP Access Rules** - IP allowlist/blocklist rules
- **Load Balancers** - Zone-specific load balancer configurations
- **Page Shield** - Content Security Policy and script monitoring
- **Rate Limits** - Rate limiting rules and thresholds
- **Transform Rules** - URL rewrites, header modifications
- **Cache Rules** - Caching behavior and bypass rules
- **Redirect Rules** - URL redirects and forwarding
- **Origin Rules** - Origin server configurations
- **URL Normalization** - URL normalization settings
- **User Agent Blocking** - UA-based blocking rules
- **WAF Overrides** - Custom WAF rule overrides
- **Security Settings** - Security level, challenge TTL, browser checks
- **Configuration Rules** - Zone-specific configuration overrides

### Account-Level Data (Optional)
- **Load Balancer Pools** - Account-wide load balancer pool configurations
- **Pool Details** - Detailed configuration for specific pools
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
        └── Load-Balancers-Pools.txt
```

Each backup creates timestamped folders containing JSON files with configuration data from the Cloudflare API.

## Authentication Methods

- **Windows Script**: Uses email + API key authentication (`X-Auth-Email` and `X-Auth-Key` headers)
- **macOS/Linux Script**: Uses Bearer token authentication (`Authorization: Bearer` header)

Both methods require read permissions for all zones you want to backup.

## Important Notes

- This creates configuration backups, not a complete account backup
- Account-level settings (billing, team members, etc.) are not included
- Scripts have been tested with Free and Pro zones
- All API responses are saved as JSON files for easy parsing and restoration
- Load balancer pool backups are optional and can be disabled if not needed

## Requirements

- `curl` command-line tool (included in most modern operating systems)
- Valid Cloudflare API credentials with appropriate permissions
- Network access to Cloudflare API endpoints
