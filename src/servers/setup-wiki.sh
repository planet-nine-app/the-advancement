#!/bin/bash

# Droplet setup script for fedwiki with wiki-plugin-allyabase
# This script runs on the newly created Digital Ocean droplet

set -e

# Read domain name if provided
DOMAIN_NAME="$1"

echo "=================================="
echo "Fedwiki + Allyabase Setup"
echo "=================================="
echo ""

if [ -n "$DOMAIN_NAME" ]; then
  echo "Domain: $DOMAIN_NAME"
  echo ""
fi

# Wait for cloud-init and unattended-upgrades to finish
echo "⏳ Waiting for cloud-init to complete..."
cloud-init status --wait || true

echo "⏳ Waiting for unattended-upgrades to finish..."
# Wait for apt locks to be released
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
  echo "  Waiting for other package managers to finish..."
  sleep 5
done

# Give it a moment to fully release
sleep 5

# Update system
echo "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Install required packages
echo "📦 Installing required packages..."
apt-get install -y -qq nginx certbot python3-certbot-nginx ufw

# Configure firewall
echo "🔒 Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP for certbot'
ufw allow 443/tcp comment 'HTTPS'
ufw --force reload
echo "✅ Firewall configured (ports 22, 80, and 443 open)"

# Install Node.js (using NodeSource repository for latest LTS)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -qq nodejs

# Verify installation
echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Install wiki globally
echo "📦 Installing wiki..."
npm install -g wiki --silent

# Install wiki-plugin-allyabase and wiki-security-sessionless into wiki's node_modules
echo "📦 Installing wiki-plugin-allyabase..."
WIKI_PATH=$(npm root -g)/wiki/node_modules
mkdir -p "$WIKI_PATH"
# Install using npm in the wiki directory (not in the plugin subdirectory)
cd /root
npm install --prefix "$WIKI_PATH/.." wiki-plugin-allyabase --silent 2>/dev/null || true
echo "📦 Installing wiki-security-sessionless..."
npm install --prefix "$WIKI_PATH/.." wiki-security-sessionless --silent 2>/dev/null || true

# Setup wiki directory
echo "📁 Setting up wiki directory..."
mkdir -p /root/.wiki/status
mkdir -p /root/.wiki/client
mkdir -p /root/.wiki/pages
mkdir -p /root/security

# Copy owner.json (this will be uploaded separately)
if [ -f /tmp/owner.json ]; then
  cp /tmp/owner.json /root/.wiki/status/owner.json
  echo "✅ Owner configuration installed"

  # Extract pubKey from owner.json and create security/owner.json
  OWNER_PUBKEY=$(node -pe "JSON.parse(require('fs').readFileSync('/tmp/owner.json', 'utf8')).pubKey")
  echo "{\"pubKey\": \"$OWNER_PUBKEY\"}" > /root/security/owner.json
  echo "✅ Security owner.json created with pubKey"

  # Generate cookieSecret
  COOKIE_SECRET=$(openssl rand -hex 32)
  echo "$COOKIE_SECRET" > /root/security/cookieSecret
  echo "✅ Cookie secret generated"
else
  echo "⚠️  No owner.json found - wiki will run in public mode"
fi

# Copy custom CSS (this will be uploaded separately)
# Fedwiki serves CSS from the wiki-client package, so we need to put it there
if [ -f /tmp/custom-style.css ]; then
  # Ensure we're in a stable directory
  cd /root

  # Put it in .wiki/client directory (fedwiki serves this as /client/)
  cp /tmp/custom-style.css /root/.wiki/client/custom-style.css

  # Also try to inject it into wiki-client's HTML template
  WIKI_CLIENT_PATH=$(npm root -g 2>/dev/null)/wiki/node_modules/wiki-client

  if [ -d "$WIKI_CLIENT_PATH" ]; then
    # Try different possible HTML template locations
    for html_file in "$WIKI_CLIENT_PATH/default.html" "$WIKI_CLIENT_PATH/views/static.html" "$WIKI_CLIENT_PATH/client/views/static.html"; do
      if [ -f "$html_file" ]; then
        # Backup original
        cp "$html_file" "$html_file.backup"

        # Add our custom CSS link before </head>
        sed -i 's|</head>|  <link rel="stylesheet" href="/client/custom-style.css">\n</head>|' "$html_file"
        echo "✅ Custom dark purple theme injected into $(basename $html_file)"
        break
      fi
    done
  fi

  echo "✅ Custom CSS file placed in .wiki/client/"
else
  echo "ℹ️  No custom CSS found - using default wiki theme"
fi

# Copy Welcome Visitors page (this will be uploaded separately)
if [ -f /tmp/welcome-visitors.json ]; then
  cp /tmp/welcome-visitors.json /root/.wiki/pages/welcome-visitors
  echo "✅ Welcome Visitors page installed"
else
  echo "ℹ️  No Welcome Visitors page found"
fi

# Create systemd service for wiki (running on localhost:4000)
echo "⚙️  Creating systemd service..."

# Determine security arguments based on whether owner.json was provided
if [ -f /root/security/owner.json ]; then
  # Read the cookie secret
  COOKIE_SECRET=$(cat /root/security/cookieSecret)

  cat > /etc/systemd/system/wiki.service <<EOF
[Unit]
Description=Federated Wiki
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/wiki --security_type=sessionless --security=./security --cookieSecret=$COOKIE_SECRET --session_duration=10 --port 4000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  echo "✅ Wiki service configured with sessionless security"
else
  # Fallback to legacy security if no owner.json
  cat > /etc/systemd/system/wiki.service <<'EOF'
[Unit]
Description=Federated Wiki
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/wiki --security_legacy --port 4000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  echo "✅ Wiki service configured with legacy security"
fi

# Enable and start wiki service
systemctl daemon-reload
systemctl enable wiki
systemctl start wiki

if [ -f /root/security/owner.json ]; then
  echo "✅ Wiki service started on localhost:4000 (sessionless security)"
else
  echo "✅ Wiki service started on localhost:4000 (legacy security)"
fi

# Configure nginx (basic HTTP server for certbot challenge)
echo "⚙️  Configuring nginx..."

if [ -n "$DOMAIN_NAME" ]; then
  # Initial config - simple HTTP server for certbot challenge
  cat > /etc/nginx/sites-available/wiki <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Root directory for certbot webroot plugin
    root /var/www/html;
    index index.html;

    location / {
        return 200 'Wiki setup in progress...';
        add_header Content-Type text/plain;
    }
}
EOF
else
  # Development config (HTTP only, no domain) with proxy
  cat > /etc/nginx/sites-available/wiki <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
fi

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default

# Enable wiki site
ln -sf /etc/nginx/sites-available/wiki /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

# Start nginx
systemctl enable nginx
systemctl restart nginx

echo "✅ Nginx configured and started"

# Setup SSL with certbot if domain provided
if [ -n "$DOMAIN_NAME" ]; then
  echo "🔒 Setting up SSL certificate..."

  # Wait a moment for nginx to fully start
  sleep 2

  # Get SSL certificate
  certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --register-unsafely-without-email --redirect

  if [ $? -eq 0 ]; then
    echo "✅ SSL certificate installed successfully"

    # Setup auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    echo "✅ SSL auto-renewal configured"

    # Now update nginx config with proxy to wiki on port 4000
    echo "⚙️  Updating nginx configuration with wiki proxy..."
    cat > /etc/nginx/sites-available/wiki <<EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    # Reload nginx with new proxy config
    nginx -t && systemctl reload nginx
    echo "✅ Nginx proxy configured for wiki on port 4000"
  else
    echo "⚠️  SSL certificate installation failed"
    echo "You can manually run: certbot --nginx -d $DOMAIN_NAME"
  fi
fi

echo ""
echo "=================================="
echo "✅ Setup Complete!"
echo "=================================="
echo ""

if [ -n "$DOMAIN_NAME" ]; then
  echo "Wiki URL: https://$DOMAIN_NAME"
  echo ""
  echo "SSL Certificate: ✅ Configured"
  echo "Auto-renewal: ✅ Enabled"
else
  echo "Wiki URL: http://$(curl -s ifconfig.me)"
  echo ""
  echo "⚠️  Running without SSL (HTTP only)"
  echo "For production, re-run with a domain name"
fi

echo ""
echo "Firewall Status:"
echo "  Port 22 (SSH): ✅ Open"
echo "  Port 80 (HTTP): ✅ Open"
echo "  Port 443 (HTTPS): ✅ Open"
echo "  All other ports: ❌ Closed"
echo ""
echo "Next steps:"
echo "1. Visit your wiki URL"
echo "2. Create an 'allyabase' page to activate the plugin"
echo "3. Use the plugin to launch the allyabase ecosystem"
echo ""
