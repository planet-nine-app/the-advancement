# LinkHub Docker Deployment

LinkHub can be deployed in three ways:

## Option 0: Local Testing (Recommended for Development)

Deploy LinkHub using local files for quick testing and development.

### Prerequisites
- Docker and Docker Compose installed
- LinkHub code checked out locally

### Deploy

```bash
cd linkhub

# Build and start LinkHub using local files
docker-compose -f docker-compose.standalone.yml up -d --build

# Check logs
docker logs -f planet-nine-linkhub

# Stop
docker-compose -f docker-compose.standalone.yml down
```

### Access
- **LinkHub**: http://localhost:3010
- **Demo Mode**: http://localhost:3010 (shows demo links)
- **Authenticated**: http://localhost:3010?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE

### Benefits
- Uses local code (no need to push to GitHub first)
- Faster iteration during development
- Runs in demo mode (works without Fount connection)
- Ideal for testing before pushing to production

## Option 1: Standalone Container (Recommended for Production)

Deploy LinkHub as a separate container alongside the Planet Nine ecosystem.

### Prerequisites
- Docker and Docker Compose installed
- Planet Nine ecosystem container running

### Deploy

```bash
cd linkhub

# Build and start LinkHub
docker-compose up -d linkhub

# Check logs
docker logs -f planet-nine-linkhub

# Stop
docker-compose down
```

### Access
- **LinkHub**: http://localhost:3010
- **Demo Mode**: http://localhost:3010
- **Authenticated**: http://localhost:3010?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE

### Environment Variables

Edit `docker-compose.yml` to configure:

- `PORT` - Server port (default: 3010)
- `FOUNT_BASE_URL` - Fount service URL (default: http://allyabase:3004/)

## Option 2: Integrated with Ecosystem Container

Add LinkHub to the existing Planet Nine ecosystem container.

### Update Dockerfile

Add to `/allyabase/deployment/docker/Dockerfile`:

```dockerfile
# After other git clones
RUN git clone https://www.github.com/planet-nine-app/the-advancement.git the-advancement

# After other npm installs
WORKDIR /usr/src/app/the-advancement/linkhub
RUN npm install

# Add to EXPOSE section
EXPOSE 3010
```

### Update start.sh

Add to `/allyabase/deployment/docker/start.sh` ecosystem.config.js:

```javascript
{
  name: 'linkhub',
  script: '/usr/src/app/the-advancement/linkhub/server.js',
  env: {
    LOCALHOST: 'true',
    PORT: '3010',
    FOUNT_BASE_URL: 'http://localhost:3004/'
  }
}
```

### Rebuild and Deploy

```bash
cd /path/to/allyabase/deployment/docker

# Rebuild container
docker build -t planetnine/allyabase:latest .

# Stop existing container
docker stop planet-nine-ecosystem
docker rm planet-nine-ecosystem

# Start new container
docker run -d \
  --name planet-nine-ecosystem \
  -p 2525:2525 \
  -p 2999:2999 \
  -p 3000:3000 \
  -p 3001:3001 \
  -p 3002:3002 \
  -p 3003:3003 \
  -p 3004:3004 \
  -p 3005:3005 \
  -p 3007:3007 \
  -p 3010:3010 \
  -p 7243:7243 \
  -p 7277:7277 \
  planetnine/allyabase:latest

# Check logs
docker logs -f planet-nine-ecosystem

# Check PM2 status
docker exec planet-nine-ecosystem pm2 list
```

## Testing

### Demo Mode
```bash
curl http://localhost:3010
```

Should return HTML with demo links.

### Authenticated Mode

Generate authentication:
```javascript
const timestamp = Date.now().toString();
const pubKey = "YOUR_PUBKEY";
const message = timestamp + pubKey;
const signature = sessionless.sign(message, privateKey);

const url = `http://localhost:3010?pubKey=${pubKey}&timestamp=${timestamp}&signature=${signature}`;
```

### Health Check
```bash
# Check LinkHub is running
curl http://localhost:3010 | grep "LinkHub"

# Check Fount connection
docker exec planet-nine-linkhub curl http://allyabase:3004/health
```

## Production Deployment

### SSL/TLS
Use nginx or Caddy as reverse proxy:

```nginx
server {
    listen 443 ssl;
    server_name linkhub.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3010;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Custom Domain
1. Point DNS A record to server IP
2. Configure SSL certificate
3. Update `FOUNT_BASE_URL` to production Fount URL

### Monitoring
```bash
# PM2 monitoring (if using Option 2)
docker exec planet-nine-ecosystem pm2 monit

# Container stats
docker stats planet-nine-linkhub

# Logs
docker logs -f --tail 100 planet-nine-linkhub
```

## Troubleshooting

### LinkHub not starting
```bash
# Check logs
docker logs planet-nine-linkhub

# Check if port is already in use
lsof -i :3010

# Restart container
docker restart planet-nine-linkhub
```

### Cannot connect to Fount
```bash
# Check network connectivity
docker exec planet-nine-linkhub curl http://allyabase:3004/health

# Verify FOUNT_BASE_URL
docker exec planet-nine-linkhub env | grep FOUNT
```

### Authentication not working
```bash
# Check signature format
# Message should be: timestamp + pubKey
# NOT: timestamp + pubKey + hash

# Verify Fount has user's carrierBag
curl "http://localhost:3004/bdo/YOUR_PUBKEY"
```

## Development

### Local Development with Hot Reload
```bash
cd linkhub
npm install
npm run dev

# In another terminal, watch for changes
nodemon server.js
```

### Testing with Real Data
1. Create user in Fount
2. Add links to carrierBag "links" collection
3. Generate authentication signature
4. Visit authenticated URL

## Architecture

```
┌─────────────────────┐
│   User Browser      │
└──────────┬──────────┘
           │ HTTP GET /?pubKey=...
           ▼
┌─────────────────────┐
│   LinkHub           │
│   (Port 3010)       │
└──────────┬──────────┘
           │ Verify signature
           │ Fetch BDO
           ▼
┌─────────────────────┐
│   Fount Service     │
│   (Port 3004)       │
└──────────┬──────────┘
           │ Return carrierBag
           ▼
┌─────────────────────┐
│   Generate SVG      │
│   Return HTML       │
└─────────────────────┘
```

## Security Notes

- LinkHub only reads from Fount (read-only access)
- No write operations to carrierBag
- All authentication via sessionless signatures
- No user data stored in LinkHub
- No tracking or analytics
- Privacy-first by design
