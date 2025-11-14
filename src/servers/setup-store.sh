#!/bin/bash

set -e

DOMAIN=$1
STORE_NAME=$2

echo "======================================"
echo "Planet Nine Store Setup"
echo "======================================"
echo "Domain: ${DOMAIN:-none}"
echo "Store Name: $STORE_NAME"
echo ""

# Wait for cloud-init to complete
echo "⏳ Waiting for cloud-init to complete..."
cloud-init status --wait

# Wait for unattended-upgrades to finish
echo "⏳ Waiting for system updates to complete..."
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "  Waiting for dpkg lock..."
  sleep 5
done

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
echo "📦 Installing nginx, certbot, and firewall..."
apt-get install -y nginx certbot python3-certbot-nginx ufw

# Configure firewall
echo "🔒 Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (for Let's Encrypt)
ufw allow 443/tcp   # HTTPS
echo "✅ Firewall configured"

# Install Node.js 20 LTS
echo "📦 Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
echo "✅ Node.js installed: $(node --version)"

# Install Sanora globally
echo "📦 Installing Sanora..."
git clone https://github.com/planet-nine-app/sanora.git /root/sanora
cd /root/sanora/src/server/node
npm install
echo "✅ Sanora installed"

# Create systemd service for Sanora
echo "📝 Creating Sanora systemd service..."
cat > /etc/systemd/system/sanora.service << 'EOF'
[Unit]
Description=Sanora - Planet Nine Feed Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/sanora/src/server/node
ExecStart=/usr/bin/node sanora.js
Restart=always
RestartSec=10
Environment=PORT=7243

[Install]
WantedBy=multi-user.target
EOF

# Copy feeds to Sanora public directory
echo "📚 Setting up feeds..."
mkdir -p /root/sanora/src/server/node/public/feeds
cp /root/feeds/*.json /root/sanora/src/server/node/public/feeds/ 2>/dev/null || true

# Start Sanora service
echo "🚀 Starting Sanora service..."
systemctl daemon-reload
systemctl enable sanora
systemctl start sanora
echo "✅ Sanora service started"

# Configure nginx
if [ -n "$DOMAIN" ]; then
  echo "🌐 Configuring nginx with SSL for domain: $DOMAIN"

  # Basic HTTP config for Let's Encrypt challenge
  cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:7243;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

  # Reload nginx
  nginx -t && systemctl reload nginx

  # Obtain SSL certificate
  echo "🔒 Obtaining SSL certificate from Let's Encrypt..."
  certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
    echo "⚠️  SSL certificate installation failed"
    echo "⚠️  Store is running on HTTP only"
  }

  # Enable certbot auto-renewal
  systemctl enable certbot.timer
  systemctl start certbot.timer
  echo "✅ SSL auto-renewal configured"

else
  echo "🌐 Configuring nginx without SSL (HTTP only)"

  cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://localhost:7243;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

  nginx -t && systemctl reload nginx
fi

echo ""
echo "======================================"
echo "✅ Store Setup Complete!"
echo "======================================"
echo "Sanora is running on port 7243"
echo "Nginx is configured and running"
echo "Feeds are available at /feeds/"
echo ""

# Show service status
systemctl status sanora --no-pager -l
