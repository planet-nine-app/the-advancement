# Fedwiki Base Deployment Scripts

Production-ready scripts for deploying federated wiki instances with the wiki-plugin-allyabase on Digital Ocean. Includes automatic SSL, nginx reverse proxy, and firewall configuration.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create your DO API token file:
```bash
cp do-token.json.example do-token.json
# Edit do-token.json and add your Digital Ocean API token
```

3. **Add SSH keys to Digital Ocean** (recommended for security):

The script will automatically fetch and use all SSH keys from your DO account. To add SSH keys:

**Option A: Via Web Interface**
- Go to https://cloud.digitalocean.com/account/security
- Click "Add SSH Key"
- Paste your public key from `~/.ssh/id_rsa.pub`

**Option B: Generate new key pair**
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy public key to clipboard (macOS)
pbcopy < ~/.ssh/id_ed25519.pub

# Or view it to copy manually
cat ~/.ssh/id_ed25519.pub
```

Then add the public key to Digital Ocean via the web interface.

**Without SSH Keys**: If no SSH keys are found, the script will warn you and create the droplet with password authentication. Digital Ocean will email the root password, but this is less secure than SSH key authentication.

## Usage

### Production Deploy (with SSL)

Deploy a new fedwiki base with domain name and SSL:

```bash
node deploy-do.js my-base-name
```

You'll be prompted for:
- **Owner name**: Your wiki owner username
- **Location emoji**: 3 emoji identifier (e.g., `☮️🌙🎸`)
- **Federation emoji**: 1 emoji prefix (e.g., `💚`)
- **Domain name**: Your domain (e.g., `wiki.example.com`) - **optional**

If you provide a domain name, the script will automatically:
1. Configure nginx as a reverse proxy
2. Obtain a Let's Encrypt SSL certificate via certbot
3. Set up automatic certificate renewal
4. Configure HTTPS redirects
5. Enable UFW firewall (only ports 22 and 443)

**Important**: Before deployment, point your domain's A record to the droplet's IP. You can do this after deployment, but certbot will fail until DNS is configured.

### Development Deploy (HTTP only)

Skip the domain prompt to deploy without SSL:

```bash
node deploy-do.js my-base
# Press Enter when prompted for domain name
```

This creates an HTTP-only wiki accessible via the droplet's IP address.

### Options

```bash
# Skip owner configuration (for testing)
node deploy-do.js my-base --skip-config

# Specify region and size
node deploy-do.js my-base --region sfo3 --size s-2vcpu-2gb
```

Available regions: `nyc1`, `nyc3`, `sfo3`, `sgp1`, `lon1`, `fra1`, `tor1`, `blr1`

Available sizes:
- `s-1vcpu-1gb` - $6/month (default)
- `s-2vcpu-2gb` - $12/month
- `s-4vcpu-8gb` - $48/month

## Manual Configuration

If you want to configure the owner.json separately:

```bash
node configure-owner.js
```

This creates `owner.json` with:
- Owner name
- Sessionless cryptographic keys
- Location emoji (3 emoji identifier)
- Federation emoji (1 emoji prefix)

## Files

- `deploy-do.js` - Main deployment orchestrator
- `configure-owner.js` - Interactive owner configuration
- `setup-wiki.sh` - Droplet setup script (runs on the server)
- `custom-style.css` - Custom dark purple theme CSS
- `do-token.json` - Your DO API token (gitignored)
- `owner.json` - Generated owner configuration (gitignored)

## How It Works

### 1. Configuration Phase
- Prompts for wiki owner details
- Generates sessionless keys for authentication
- Creates `owner.json` with federation emoji identifiers
- Optionally collects domain name for SSL setup

### 2. Droplet Creation
- Uses Digital Ocean API to create Ubuntu 22.04 droplet
- Tags: `planet-nine`, `fedwiki`, `allyabase`
- Waits for IP assignment (~30 seconds)

### 3. Security Setup
- Enables UFW firewall with strict rules:
  - Port 22 (SSH) - Open for management
  - Port 443 (HTTPS) - Open for web traffic
  - All other ports - Closed
- Installs nginx, certbot, and dependencies

### 4. Application Setup
- Connects via SSH (~60 seconds wait for SSH availability)
- Uploads `owner.json` and `setup-wiki.sh`
- Runs setup script which:
  - Updates system packages
  - Installs Node.js 20.x LTS
  - Installs wiki globally via npm
  - Installs wiki-plugin-allyabase into wiki's node_modules
  - Creates systemd service for wiki (port 3000)
  - Starts wiki service with auto-restart

### 5. Reverse Proxy & SSL
- Configures nginx to proxy port 443 → localhost:3000
- If domain provided:
  - Obtains Let's Encrypt SSL certificate via certbot
  - Configures automatic HTTPS redirect
  - Enables certbot timer for auto-renewal (runs twice daily)
- If no domain:
  - Configures nginx for HTTP on port 80

### 6. Post-Deployment
- Wiki accessible via HTTPS (with domain) or HTTP (IP only)
- Auto-restarts on failure via systemd
- SSL certificates auto-renew before expiration
- Create an "allyabase" page to activate the plugin
- Use the plugin UI to launch the allyabase ecosystem

## Federation Setup

After deployment, to join the federation:

1. Visit your wiki at `http://<droplet-ip>`
2. Create a page called "allyabase"
3. Add an allyabase plugin item to the page
4. The plugin will load and provide a UI to:
   - Launch the allyabase microservices ecosystem
   - Register your location with other wikis
   - Resolve federated resources

Your wiki's federation identity is:
- Location: Your 3-emoji identifier (e.g., `☮️🌙🎸`)
- Federation: Your 1-emoji prefix (e.g., `💚`)
- Federated shortcode: `💚☮️🌙🎸/resource-path`

## Troubleshooting

### SSH Connection Fails

**Issue**: Cannot connect via SSH after deployment

**Solutions**:

1. **Add SSH keys before deployment**: The script automatically fetches all SSH keys from your DO account. Make sure you've added at least one:
   ```bash
   # Check what keys are in your DO account
   # (requires doctl CLI or check web interface)
   ```

2. **Use password authentication**: If no SSH keys are found, DO will email the root password. Use it to connect:
   ```bash
   ssh root@droplet-ip
   # Enter the password from email
   ```

3. **Add SSH keys after deployment**:
   ```bash
   # Connect with password
   ssh root@droplet-ip

   # Create .ssh directory
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh

   # Add your public key
   echo "your-public-key-here" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

4. **Verify SSH service**:
   ```bash
   ssh root@droplet-ip
   systemctl status sshd
   ```

### SSL Certificate Fails

If certbot fails to obtain a certificate:

1. **Check DNS**: Ensure your domain's A record points to the droplet IP
   ```bash
   dig +short yourdomain.com
   ```

2. **Manually retry**:
   ```bash
   ssh root@your-droplet-ip
   certbot --nginx -d yourdomain.com
   ```

3. **Check nginx logs**:
   ```bash
   tail -f /var/log/nginx/error.log
   ```

### Plugin Not Loading

SSH into the droplet and check:
```bash
# Check wiki service status
systemctl status wiki

# View wiki logs
journalctl -u wiki -f

# Verify plugin installation
ls -la $(npm root -g)/wiki/node_modules/ | grep allyabase
```

### Wiki Not Starting

```bash
# Check if wiki is running
systemctl status wiki

# Check nginx status
systemctl status nginx

# View nginx error logs
tail -f /var/log/nginx/error.log

# Restart services
systemctl restart wiki
systemctl restart nginx
```

### Firewall Blocks Access

Check firewall rules:
```bash
ufw status verbose
```

Ensure ports 22 and 443 are open:
```bash
ufw allow 443/tcp
ufw reload
```

### Certificate Renewal Issues

Check renewal timer:
```bash
systemctl status certbot.timer
systemctl list-timers | grep certbot
```

Test renewal:
```bash
certbot renew --dry-run
```

## Next Steps

After deploying multiple fedwiki bases:

1. **Register Federation Locations**: Use the allyabase plugin on each wiki to register other wikis' locations
2. **Test Cross-Wiki References**: Create pages with federated shortcodes (e.g., `💚☮️🌙🎸/resource`)
3. **Launch Allyabase Services**: Use the plugin UI to launch the full microservices ecosystem
4. **Configure Backups**: Set up automated backups of `/root/.wiki` directory
5. **Monitor Resources**: Use Digital Ocean monitoring or set up custom alerts

## Production Deployment Checklist

✅ **Included in this deployment:**
- UFW firewall (only SSH and HTTPS)
- SSL/TLS with Let's Encrypt
- Automatic certificate renewal
- Nginx reverse proxy
- Systemd service with auto-restart
- Latest Node.js LTS
- SSH key authentication (automatic)
- Password authentication disabled (if SSH keys present)
- Security hardening

📋 **Additional recommendations:**
- Regular system updates: `apt-get update && apt-get upgrade`
- Backup strategy for `/root/.wiki` directory
- Monitor disk usage and logs
- Consider using a non-root user for wiki service
- Set up monitoring/alerting (uptime, resources)
- Configure fail2ban for additional SSH protection
- Rotate SSH keys periodically

## Architecture

```
Internet (Port 443 HTTPS)
         │
         ▼
    [UFW Firewall]
         │
         ▼
     [Nginx Reverse Proxy]
     (SSL Termination)
         │
         ▼
   [Fedwiki on localhost:3000]
   (wiki + wiki-plugin-allyabase)
```

All ports except 22 (SSH) and 443 (HTTPS) are blocked by UFW. The wiki runs on localhost:3000 and is only accessible through nginx, which handles SSL termination and reverse proxying.

## DNS Configuration

The deployment script can automatically create DNS records if your domain is managed by Digital Ocean. Otherwise, you'll need to configure DNS manually.

### Automatic DNS (Digital Ocean Managed Domains)

If your domain (`allyabase.com`) is managed by Digital Ocean:

1. **Enter full domain when prompted**: `foo.allyabase.com`
2. Script automatically creates A record pointing to the droplet IP
3. Wait 5-30 minutes for DNS propagation
4. Verify: `dig +short foo.allyabase.com`

**Domain must be added to Digital Ocean first:**
- Go to https://cloud.digitalocean.com/networking/domains
- Click "Add Domain"
- Enter your root domain (`allyabase.com`)
- Update your domain registrar's nameservers to:
  - `ns1.digitalocean.com`
  - `ns2.digitalocean.com`
  - `ns3.digitalocean.com`

### Manual DNS (Any Registrar)

If your domain is managed elsewhere (Namecheap, GoDaddy, Cloudflare, etc.):

**For subdomain (foo.allyabase.com):**
1. Log into your domain registrar/DNS provider
2. Go to DNS management for `allyabase.com`
3. Add an A record:
   - **Name/Host**: `foo` (just the subdomain part)
   - **Type**: `A`
   - **Value**: `<droplet-ip>` (from deployment output)
   - **TTL**: `3600` (1 hour)

**For root domain (allyabase.com):**
1. Same as above, but:
   - **Name/Host**: `@` or leave blank (depending on registrar)

**Examples for common registrars:**

**Namecheap:**
```
Type: A Record
Host: foo
Value: 192.0.2.1
TTL: Automatic
```

**Cloudflare:**
```
Type: A
Name: foo
IPv4 address: 192.0.2.1
Proxy status: DNS only (grey cloud)
TTL: Auto
```

**GoDaddy:**
```
Type: A
Name: foo
Value: 192.0.2.1
TTL: 1 Hour
```

### Verifying DNS Propagation

After adding the DNS record, wait 5-30 minutes and verify:

```bash
# Check if DNS is resolving
dig +short foo.allyabase.com

# Should return your droplet IP
# If it returns nothing, DNS hasn't propagated yet

# Check propagation globally
# Visit: https://dnschecker.org/#A/foo.allyabase.com
```

### SSL Certificate Setup Timing

**Important**: Certbot needs DNS to be fully propagated before it can issue certificates.

**If you deploy before DNS propagates:**
1. Deployment will complete but certbot will fail
2. Wiki will be accessible via HTTP at the IP address
3. After DNS propagates, manually run:
   ```bash
   ssh root@droplet-ip
   certbot --nginx -d foo.allyabase.com
   ```

**If you deploy after DNS propagates:**
1. Everything works automatically
2. SSL certificate issued during deployment
3. Wiki immediately accessible via HTTPS at domain

**Recommended workflow:**
1. Create DNS record first (manually or via DO)
2. Wait 10-15 minutes
3. Run deployment script with domain name
4. SSL configured automatically

## Custom Styling

The deployment includes a custom dark purple theme with green glowing text. The theme is automatically installed to `/root/.wiki/client/style.css` on the server.

### Default Theme Features:
- Dark purple gradient background (`#1a0033` to `#2d1b4e`)
- Green text with glow effect (`#7fff7f` with text-shadow)
- Glowing links and buttons
- Styled scrollbars
- Dark code blocks
- Custom selection highlighting

### Customizing the Theme:

**Option 1: Edit before deployment**
```bash
# Edit the CSS file locally
nano custom-style.css

# Make your changes
# Then deploy - custom CSS will be uploaded automatically
node deploy-do.js my-base
```

**Option 2: Edit after deployment**
```bash
# SSH into the droplet
ssh root@droplet-ip

# Edit the CSS file
nano /root/.wiki/client/style.css

# Restart wiki to apply changes
systemctl restart wiki
```

**Option 3: Remove custom styling**
```bash
# SSH into droplet
ssh root@droplet-ip

# Remove custom CSS
rm /root/.wiki/client/style.css

# Restart wiki to use default theme
systemctl restart wiki
```

### CSS Customization Tips:

The custom CSS file (`custom-style.css`) uses standard CSS with `!important` flags to override wiki defaults. Key areas you can customize:

**Colors:**
```css
/* Background gradient */
background: linear-gradient(135deg, #1a0033 0%, #2d1b4e 100%);

/* Text color */
color: #7fff7f;

/* Glow effect */
text-shadow: 0 0 10px rgba(127, 255, 127, 0.5);
```

**Glow intensity:**
```css
/* Subtle glow */
text-shadow: 0 0 5px rgba(127, 255, 127, 0.3);

/* Strong glow */
text-shadow: 0 0 15px rgba(127, 255, 127, 0.8);
```

**Other themes:**
- Blue cyberpunk: Change `#1a0033` → `#001a33`, `#7fff7f` → `#00ffff`
- Red matrix: Change `#1a0033` → `#330000`, `#7fff7f` → `#ff0000`
- Orange retro: Change `#1a0033` → `#331a00`, `#7fff7f` → `#ffaa00`

Federated Wiki automatically loads `/root/.wiki/client/style.css` if it exists, so any changes you make will be applied globally to your wiki instance.
