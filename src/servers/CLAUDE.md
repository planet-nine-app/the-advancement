# Federated Wiki Auto-Deployment System

## Overview

Minimalist deployment scripts for launching privacy-first federated wiki instances with the **allyabase** plugin on Digital Ocean. Single-command deployment with SSL, DNS, custom theming, and production-ready security.

## Quick Start

```bash
# Deploy a new base
node deploy-do.js <base-name> --project allyabase --ssh-key ~/.ssh/id_ed25519_do
```

Example:
```bash
node deploy-do.js test-base-1 --project allyabase --ssh-key ~/.ssh/id_ed25519_do
```

Your wiki will be live at `https://<base-name>.allyabase.com` with:
- ✅ SSL certificate (Let's Encrypt)
- ✅ DNS A record configured
- ✅ Custom dark purple theme with glowing green text
- ✅ Welcome Visitors page explaining allyabase
- ✅ Firewall secured (ports 22, 80, 443 only)
- ✅ Wiki on port 4000 (allyabase uses 3000)

## Files

```
servers/
├── deploy-do.js              # Main deployment orchestration
├── configure-owner.js        # Interactive owner configuration
├── setup-wiki.sh            # Server-side setup script
├── custom-style.css         # Dark purple theme with glowing green text
├── welcome-visitors.json    # Default landing page
├── do-token.json           # API token (gitignored)
├── owner.json              # Generated owner config (gitignored)
└── package.json            # Dependencies
```

## Configuration Files

### do-token.json (gitignored)

```json
{
  "token": "dop_v1_..."
}
```

Get your token at: https://cloud.digitalocean.com/account/api/tokens
- ✅ Select "Full Access" (or check both Read and Write)

### owner.json (gitignored, auto-generated)

```json
{
  "name": "owner-name",
  "locationEmoji": "☮️💚🏴‍☠️",
  "federationEmoji": "💚",
  "friend": {
    "☮️💚🏴‍☠️": "029b39355ae6625181f9e034fb9959848aa61008c3ea13c1199cfdddef8800d1"
  },
  "publicKey": "029b39355ae6625181f9e034fb9959848aa61008c3ea13c1199cfdddef8800d1",
  "privateKey": "...",
  "domain": "base-name.allyabase.com"
}
```

Generated during deployment using Sessionless cryptography.

## Deployment Process

### 1. Owner Configuration
- Prompts for wiki owner name
- Prompts for location emoji (3 emoji identifier)
- Prompts for federation emoji (1 emoji identifier)
- Prompts for optional domain name
- Generates Sessionless keypair
- Saves to `owner.json`

### 2. Droplet Creation
- Creates Ubuntu 22.04 droplet
- Region: `nyc3` (configurable)
- Size: `s-1vcpu-1gb` (configurable)
- Adds all SSH keys from your DO account
- Tags: `planet-nine`, `fedwiki`, `allyabase`
- Assigns to specified project (optional)

### 3. DNS Configuration
- Extracts root domain (e.g., `allyabase.com`)
- Creates A record pointing to droplet IP
- Supports subdomains (e.g., `foo.allyabase.com`)
- Propagation takes 5-30 minutes

### 4. Server Setup (`setup-wiki.sh`)

**System Updates:**
- Waits for cloud-init to complete
- Waits for unattended-upgrades to finish
- Updates system packages
- Installs: nginx, certbot, python3-certbot-nginx, ufw

**Firewall Configuration:**
- Enables UFW
- Allows port 22 (SSH)
- Allows port 80 (HTTP for Let's Encrypt)
- Allows port 443 (HTTPS)
- Denies all other ports

**Node.js & Wiki:**
- Installs Node.js 20 LTS
- Installs wiki globally via npm
- Installs wiki-plugin-allyabase
- Creates systemd service running on port 4000

**Configuration Files:**
- Copies `owner.json` to `/root/.wiki/status/owner.json`
- Copies `custom-style.css` to `/root/.wiki/client/custom-style.css`
- Copies `welcome-visitors.json` to `/root/.wiki/pages/welcome-visitors`
- Injects CSS link into wiki-client HTML template

**SSL Certificate (if domain provided):**
1. Configures nginx with basic HTTP server (for certbot challenge)
2. Runs certbot to obtain Let's Encrypt certificate
3. Updates nginx config with HTTPS + reverse proxy to port 4000
4. Enables certbot auto-renewal timer

**Without domain:**
- Configures nginx reverse proxy on HTTP only
- No SSL certificate

### 5. Verification
- Checks setup script exit code
- Displays wiki URL
- Shows security status
- Provides federation details
- Shows next steps

## Command-Line Options

```bash
node deploy-do.js <base-name> [options]

Options:
  --skip-config     Skip owner configuration (use for testing)
  --region <r>      Digital Ocean region (default: nyc3)
  --size <s>        Droplet size (default: s-1vcpu-1gb)
  --project <p>     Project name or ID to assign droplet to
  --ssh-key <k>     Path to SSH private key (default: auto-detect)
```

### Examples

**Full production deployment:**
```bash
node deploy-do.js production-base --project allyabase
```

**Custom region and size:**
```bash
node deploy-do.js large-base --region sfo3 --size s-2vcpu-4gb --project allyabase
```

**Custom SSH key:**
```bash
node deploy-do.js secure-base --ssh-key /path/to/key --project allyabase
```

**Skip configuration (testing):**
```bash
node deploy-do.js test-base --skip-config
```

## Custom Theme

The custom dark purple theme (`custom-style.css`) features:
- Deep purple gradient background (`#1a0033` to `#2d1b4e`)
- Glowing green text (`#7fff7f`)
- Neon-style links with hover effects
- Dark overlay cards with purple borders
- Custom scrollbar styling
- Allyabase-specific plugin styles

The CSS is injected into the wiki-client HTML template at deployment time, ensuring it loads on every page.

## Welcome Visitors Page

The `welcome-visitors.json` page explains:
- What federated wiki is
- How to launch an allyabase ecosystem
- How to fork pages for decentralized knowledge
- Editing and federation basics
- Privacy and ownership principles
- Links to learn more about Planet Nine

This page appears at the root URL and serves as the landing page for new visitors.

## Architecture

### Port Configuration
- **Port 4000**: Wiki server (avoiding conflict with allyabase on port 3000)
- **Port 80**: HTTP (for Let's Encrypt challenge)
- **Port 443**: HTTPS (nginx reverse proxy to wiki)
- **Port 22**: SSH (for remote management)

### Directory Structure on Droplet
```
/root/
├── .wiki/
│   ├── status/
│   │   └── owner.json          # Wiki owner configuration (full)
│   ├── client/
│   │   └── custom-style.css    # Custom theme (served at /client/)
│   └── pages/
│       └── welcome-visitors     # Landing page (JSON format)
└── security/
    ├── owner.json               # Sessionless owner pubKey only
    └── cookieSecret             # Generated session cookie secret

/usr/lib/node_modules/
└── wiki/
    └── node_modules/
        ├── wiki-plugin-allyabase/
        ├── wiki-security-sessionless/
        └── wiki-client/
            └── default.html     # Modified to include custom CSS
```

### Sessionless Security Setup

The deployment automatically configures wiki-security-sessionless for passwordless authentication:

**Security Directory (`/root/security/`):**
- `owner.json` - Contains only the owner's public key:
  ```json
  {"pubKey": "025bfdbff040e38e48901d6cc26f11ba988cbdfbafc82197ae87012d98fa4c37"}
  ```
- `cookieSecret` - Random 64-character hex string for session cookies

**Wiki Launch Arguments:**
```bash
/usr/bin/wiki \
  --security_type=sessionless \
  --security=./security \
  --cookieSecret=<64-char-hex> \
  --session_duration=10 \
  --port 4000
```

**Authentication Flow:**
1. User visits wiki
2. Wiki challenges with nonce
3. User signs nonce with private key (stored in browser/extension)
4. wiki-security-sessionless verifies signature against owner.json pubKey
5. Session created with 10-day duration

**Benefits:**
- No passwords to remember or leak
- Cryptographic authentication
- Works with Planet Nine browser extensions
- Compatible with Sessionless ecosystem

### SSL Certificate Flow

**With Domain:**
1. Configure nginx with simple HTTP server (no proxy)
2. Run certbot with nginx plugin on port 80
3. Let's Encrypt performs HTTP-01 challenge
4. Certificate obtained and stored in `/etc/letsencrypt/`
5. Update nginx config with HTTPS + proxy to port 4000
6. Enable certbot auto-renewal timer

**Without Domain:**
- Skip SSL setup
- HTTP-only nginx reverse proxy
- Accessible via `http://<droplet-ip>`

## Security Features

### Firewall (UFW)
- Default deny incoming
- Default allow outgoing
- Only ports 22, 80, 443 open
- All other ports blocked

### SSL/TLS
- Let's Encrypt certificates (free, auto-renewing)
- TLS 1.2+ only
- Strong cipher suites via certbot defaults
- HTTP → HTTPS redirect
- Auto-renewal via systemd timer

### SSH Keys
- Uses all SSH keys from Digital Ocean account
- No password authentication
- Key auto-detection (ed25519 or RSA)
- Custom key path support

### Sessionless Authentication
- Owner keypair generated via Sessionless
- No passwords stored
- Cryptographic identity
- Federation via public key

## Troubleshooting

### SSH Connection Timeout
```
Error: SSH connection timeout. The droplet may still be booting.
```
**Solution:** Droplet is still initializing. Wait 2-3 minutes and try connecting manually:
```bash
ssh root@<droplet-ip>
```

### SSL Certificate Failure
```
⚠️  SSL certificate installation failed
```
**Possible causes:**
1. DNS not propagated yet (wait 5-30 minutes)
2. Port 80 blocked (check firewall)
3. Domain not pointing to droplet IP

**Manual fix:**
```bash
ssh root@<droplet-ip>
certbot --nginx -d your-domain.com
```

### DNS Record Already Exists
```
⚠️  Could not create DNS record automatically
Error 422: Record already exists
```
**Solution:** Delete the existing DNS record and redeploy, or manually update the existing record to point to the new droplet IP.

### No SSH Keys Found
```
⚠️  No SSH private key found at ~/.ssh/id_ed25519 or ~/.ssh/id_rsa
```
**Solution:**
- Use `--ssh-key` option to specify custom key path
- Or add your public key to Digital Ocean account

### CSS Not Loading
If the custom CSS isn't showing:
1. Check if file exists: `ls -la /root/.wiki/client/custom-style.css`
2. Check if HTML was modified: `grep custom-style /usr/lib/node_modules/npm/node_modules/wiki-client/default.html`
3. Restart wiki: `systemctl restart wiki`
4. Clear browser cache

## Digital Ocean Requirements

### API Token Permissions
Your API token must have:
- ✅ Read access (to fetch SSH keys, projects)
- ✅ Write access (to create droplets, DNS records)

Create token at: https://cloud.digitalocean.com/account/api/tokens

### SSH Keys
Add your public SSH key to Digital Ocean:
1. Go to: https://cloud.digitalocean.com/account/security
2. Click "Add SSH Key"
3. Paste your public key (`cat ~/.ssh/id_rsa.pub`)
4. Give it a name

### Domain Management
For SSL to work, your domain must be:
1. Added to Digital Ocean DNS
2. Nameservers pointing to Digital Ocean:
   - `ns1.digitalocean.com`
   - `ns2.digitalocean.com`
   - `ns3.digitalocean.com`

## Dependencies

### Node.js Packages
- `dots-wrapper@^3.12.5` - Digital Ocean API client
- `node-ssh@^13.2.0` - SSH automation
- `sessionless` - Cryptographic key generation (used in configure-owner.js)

### System Packages (installed on droplet)
- `nginx` - Web server and reverse proxy
- `certbot` - Let's Encrypt SSL certificate automation
- `python3-certbot-nginx` - Certbot nginx plugin
- `ufw` - Uncomplicated Firewall
- `nodejs` - Node.js runtime (v20 LTS)
- `npm` - Node package manager

### Wiki Packages (installed via npm)
- `wiki` - Federated wiki server
- `wiki-plugin-allyabase` - Planet Nine base launcher plugin
- `wiki-security-sessionless` - Sessionless cryptographic authentication

## Integration with Planet Nine

This deployment system is part of the **Planet Nine** ecosystem:
- **Allyabase Plugin**: Launch full Planet Nine base with Julia, Fount, BDO services
- **Sessionless Auth**: Passwordless cryptographic identity
- **Federated Knowledge**: Decentralized wiki network
- **Privacy-First**: No tracking, local-first data storage

### Launching Allyabase
After deployment:
1. Visit your wiki URL
2. Create a page titled "allyabase"
3. The plugin detects this page and activates
4. Click the plugin button to launch services:
   - Julia (identity and authentication)
   - Fount (MAGIC protocol resolver)
   - BDO (Base Data Objects)
   - And more...

## Development

### Local Testing
```bash
# Install dependencies
npm install

# Test owner configuration
node configure-owner.js

# Test deployment (will create real droplet!)
node deploy-do.js test-base --project allyabase
```

### Modifying the Setup Script
Edit `setup-wiki.sh` and redeploy. The script is uploaded fresh each deployment.

### Customizing the Theme
Edit `custom-style.css` and redeploy. Changes will be reflected immediately.

### Adding Welcome Content
Edit `welcome-visitors.json` and redeploy. This is a standard federated wiki page in JSON format.

## Future Enhancements

Potential improvements:
- [ ] Support for other cloud providers (AWS, Azure, Linode)
- [ ] Automated backups to S3/Spaces
- [ ] Multi-wiki deployment (wiki farm)
- [ ] Custom domain validation before deployment
- [ ] Monitoring and alerting integration
- [ ] Wiki content seeding (import existing pages)
- [ ] Plugin marketplace integration
- [ ] Automated updates and maintenance

## References

- **Federated Wiki**: http://fed.wiki.org
- **Digital Ocean API**: https://docs.digitalocean.com/reference/api/
- **wiki-plugin-allyabase**: (Planet Nine plugin)
- **Sessionless**: https://sessionless.com
- **Let's Encrypt**: https://letsencrypt.org

---

**Status**: Production-ready ✅

**Last Updated**: October 2025

**Maintainer**: Planet Nine Team
