# Planet Nine Store Deployment System

## Overview

The Planet Nine Store Deployment System enables you to launch privacy-first digital artifact stores that serve federated feeds following modern syndication specifications (Libris, Scribus, Canimus).

Two deployment options:
1. **deploy-store.js** - Deploy to Digital Ocean droplet with SSL, DNS, and production infrastructure
2. **make-store.js** - Run locally for testing and development

## Quick Start

### Local Store (Testing)

```bash
# Navigate to your artifact directory
cd /path/to/my-digital-artifacts

# Create and run local store
node /path/to/tools/make-store.js "My Bookstore"

# Store available at: http://localhost:8080
```

### Production Store (Digital Ocean)

```bash
# Deploy to Digital Ocean
cd /path/to/the-advancement/src/servers
node deploy-store.js my-store /path/to/artifacts --project allyabase

# Store live at: https://my-store.allyabase.com
```

## Supported Artifact Types

### Books (Libris Feed)
- **Extensions**: `.epub`, `.pdf`, `.mobi`, `.azw3`
- **Metadata**: Title, author, ISBN, page count, publisher
- **Feed Spec**: [Libris Specification](/specs/libris.md)

### Blog Posts (Scribus Feed)
- **Extensions**: `.md`, `.html`
- **Metadata**: Title, author, published date, tags, categories
- **Feed Spec**: [Scribus Specification](/specs/scribus.md)

### Music (Canimus Feed)
- **Extensions**: `.mp3`, `.flac`, `.m4a`, `.ogg`, `.wav`
- **Metadata**: Title, artist, album, track number, duration
- **Feed Spec**: [Canimus Specification](https://github.com/PlaidWeb/Canimus)

## Local Store (make-store.js)

### Features
- ✅ Local HTTP server on port 8080
- ✅ Automatic artifact scanning
- ✅ LLM-powered feed generation
- ✅ Beautiful dark-themed landing page
- ✅ Instant setup (no deployment required)
- ✅ Perfect for testing before production

### Usage

```bash
node make-store.js <store-name> [artifact-path] [options]

Arguments:
  <store-name>      Name for your store
  [artifact-path]   Path to artifacts (default: current directory)

Options:
  --port <p>  Server port (default: 8080)

Examples:
  node make-store.js "My Bookstore"
  node make-store.js "Music Shop" ./albums --port 3000
```

### What It Does

1. **Scans** artifact directory for `.epub`, `.mp3`, `.md` files
2. **Generates** feeds using Claude AI for metadata extraction
3. **Creates** `.store/` directory with feeds and index page
4. **Starts** HTTP server serving feeds and artifacts
5. **Displays** beautiful landing page with feed links

### Directory Structure

```
your-artifact-folder/
├── book1.epub
├── book2.pdf
├── track1.mp3
├── post1.md
└── .store/                    # Auto-generated
    ├── index.html             # Landing page
    └── feeds/
        ├── libris-feed.json   # Books feed
        ├── scribus-feed.json  # Posts feed
        └── canimus-feed.json  # Music feed
```

### Feed URLs

```
http://localhost:8080/              # Landing page
http://localhost:8080/feeds/libris-feed.json   # Books
http://localhost:8080/feeds/scribus-feed.json  # Posts
http://localhost:8080/feeds/canimus-feed.json  # Music
http://localhost:8080/books/book1.epub         # Download artifacts
```

## Production Store (deploy-store.js)

### Features
- ✅ Digital Ocean droplet deployment
- ✅ SSL certificates (Let's Encrypt)
- ✅ DNS configuration (A records)
- ✅ Sanora feed service
- ✅ Nginx reverse proxy
- ✅ UFW firewall security
- ✅ Automatic artifact upload
- ✅ Production-ready infrastructure

### Prerequisites

1. **Digital Ocean Account**
   - API token with read/write access
   - SSH keys added to account
   - Domain managed in Digital Ocean DNS

2. **API Token Setup**
   ```bash
   cd the-advancement/src/servers
   echo '{"token": "dop_v1_..."}' > do-token.json
   ```

3. **Anthropic API Key** (for feed generation)
   ```bash
   export ANTHROPIC_API_KEY="your-api-key"
   ```

### Usage

```bash
node deploy-store.js <store-name> <artifact-path> [options]

Arguments:
  <store-name>      Store name (becomes subdomain)
  <artifact-path>   Path to directory with artifacts

Options:
  --skip-config  Skip owner configuration
  --region <r>   DO region (default: nyc3)
  --size <s>     Droplet size (default: s-1vcpu-1gb)
  --project <p>  DO project name/ID
  --ssh-key <k>  Custom SSH key path

Examples:
  node deploy-store.js bookstore ./books --project allyabase
  node deploy-store.js music-shop ./albums --region sfo3 --size s-2vcpu-4gb
```

### Deployment Process

1. **Artifact Scanning**
   - Scans provided directory for digital artifacts
   - Counts books, music, posts
   - Validates at least 1 artifact exists

2. **Feed Generation**
   - Uses Claude AI to extract metadata from files
   - Generates Libris feed for books
   - Generates Scribus feed for posts
   - Generates Canimus feed for music
   - Saves feeds to local `feeds/` directory

3. **Owner Configuration** (interactive)
   - Prompts for owner name
   - Prompts for location emoji (3 emoji)
   - Prompts for federation emoji (1 emoji)
   - Prompts for domain name
   - Generates Sessionless keypair
   - Saves to `owner.json`

4. **Droplet Creation**
   - Creates Ubuntu 22.04 droplet
   - Region: `nyc3` (or specified)
   - Size: `s-1vcpu-1gb` (or specified)
   - Adds all SSH keys from DO account
   - Tags: `planet-nine`, `store`, `sanora`
   - Assigns to specified project

5. **DNS Configuration**
   - Extracts root domain (e.g., `allyabase.com`)
   - Creates A record pointing to droplet IP
   - Supports subdomains (e.g., `store.allyabase.com`)

6. **Artifact Upload**
   - Uploads all books to `/root/artifacts/books/`
   - Uploads all music to `/root/artifacts/music/`
   - Uploads all posts to `/root/artifacts/posts/`

7. **Feed Upload**
   - Uploads `libris-feed.json` to `/root/feeds/`
   - Uploads `scribus-feed.json` to `/root/feeds/`
   - Uploads `canimus-feed.json` to `/root/feeds/`

8. **Server Setup** (`setup-store.sh`)
   - Waits for cloud-init to complete
   - Updates system packages
   - Installs: nginx, certbot, ufw
   - Configures firewall (ports 22, 80, 443)
   - Installs Node.js 20 LTS
   - Clones and installs Sanora
   - Creates systemd service for Sanora
   - Copies feeds to Sanora public directory
   - Obtains SSL certificate (if domain provided)
   - Configures nginx reverse proxy
   - Enables certbot auto-renewal

### Droplet Architecture

```
Port Configuration:
  22  - SSH
  80  - HTTP (Let's Encrypt challenge)
  443 - HTTPS (nginx → Sanora)
  7243 - Sanora (internal)

Directory Structure:
  /root/artifacts/
    ├── books/
    ├── music/
    └── posts/

  /root/feeds/
    ├── libris-feed.json
    ├── scribus-feed.json
    └── canimus-feed.json

  /root/sanora/
    └── src/server/node/
        ├── sanora.js
        └── public/
            └── feeds/
                ├── libris-feed.json
                ├── scribus-feed.json
                └── canimus-feed.json

Services:
  sanora.service - Systemd service running Sanora
  nginx.service  - Reverse proxy to Sanora
  certbot.timer  - SSL certificate auto-renewal
```

### Feed Endpoints

After deployment, your store serves feeds at:

```
https://your-store.allyabase.com/feeds/libris-feed.json   # Books
https://your-store.allyabase.com/feeds/scribus-feed.json  # Posts
https://your-store.allyabase.com/feeds/canimus-feed.json  # Music
```

Sanora also provides dynamic feed endpoints:

```
GET /feeds/books/:uuid    - Libris feed for user's books
GET /feeds/posts/:uuid    - Scribus feed for user's posts
GET /feeds/music/:uuid    - Canimus feed for user's music
GET /feeds/all/:uuid      - Combined feed (all types)
GET /feeds/base           - Base feed (all products from all users)
```

See [Sanora Feed Documentation](/sanora/CLAUDE.md#feed-endpoints-november-2025) for details.

## Feed Generation (LLM-Powered)

Both `deploy-store.js` and `make-store.js` use the [Feed Generator](/tools/feed-generator/) to create feeds from artifacts.

### How It Works

1. **File Scanning**
   - Recursively scans directory
   - Detects file types by extension
   - Copies files to temporary directory

2. **Metadata Extraction** (Claude AI)
   - Reads file contents
   - Extracts title, author, description, etc.
   - Handles various formats (EPUB, PDF, MP3, MD)
   - Uses specialized prompts per artifact type

3. **Feed Assembly**
   - Converts metadata to spec-compliant JSON
   - Adds URLs for accessing artifacts
   - Generates complete feed file

### Example Feed Output

**Libris (Books)**:
```json
{
  "type": "feed",
  "name": "My Bookstore Books",
  "url": "http://localhost:8080/feeds/libris-feed.json",
  "items": [
    {
      "type": "book",
      "name": "The Great Novel",
      "author": {
        "type": "author",
        "name": "Jane Author"
      },
      "isbn": "978-3-16-148410-0",
      "summary": "A captivating story...",
      "content": [
        {
          "type": "application/epub+zip",
          "url": "http://localhost:8080/books/great-novel.epub"
        }
      ]
    }
  ]
}
```

## Security Features

### Firewall (UFW)
- Default deny incoming
- Only ports 22, 80, 443 open
- All other ports blocked

### SSL/TLS
- Let's Encrypt certificates (free)
- TLS 1.2+ only
- HTTP → HTTPS redirect
- Auto-renewal via systemd timer

### SSH Keys
- Uses SSH keys from Digital Ocean account
- No password authentication
- Key auto-detection (ed25519 or RSA)

### Sessionless Authentication
- Owner keypair generated via Sessionless
- No passwords stored
- Cryptographic identity

## Troubleshooting

### Local Store Issues

**Port Already in Use**:
```bash
# Use different port
node make-store.js "My Store" . --port 3000
```

**No Artifacts Found**:
```bash
# Check file extensions
ls -la *.epub *.mp3 *.md
```

**Feed Generation Fails**:
```bash
# Ensure Anthropic API key is set
export ANTHROPIC_API_KEY="your-key"
```

### Production Store Issues

**SSH Connection Timeout**:
```
Error: SSH connection timeout
```
**Solution**: Droplet still initializing. Wait 2-3 minutes and try manually:
```bash
ssh root@<droplet-ip>
```

**SSL Certificate Failure**:
```
⚠️  SSL certificate installation failed
```
**Possible causes**:
1. DNS not propagated (wait 5-30 minutes)
2. Port 80 blocked (check firewall)
3. Domain not pointing to droplet IP

**Manual fix**:
```bash
ssh root@<droplet-ip>
certbot --nginx -d your-domain.com
```

**DNS Record Already Exists**:
```
⚠️  Could not create DNS record automatically
Error 422: Record already exists
```
**Solution**: Delete existing record or manually update it to point to new droplet IP.

**No SSH Keys Found**:
```
⚠️  No SSH private key found
```
**Solution**: Use `--ssh-key` option:
```bash
node deploy-store.js my-store ./artifacts --ssh-key ~/.ssh/custom_key
```

## Comparison: Local vs Production

| Feature | make-store.js | deploy-store.js |
|---------|---------------|-----------------|
| **Deployment** | Instant (local) | ~5 minutes (DO) |
| **SSL** | ❌ No | ✅ Yes (Let's Encrypt) |
| **DNS** | ❌ No | ✅ Yes (A records) |
| **Cost** | Free | ~$6/month (droplet) |
| **Accessibility** | Localhost only | Public internet |
| **Use Case** | Testing, dev | Production stores |
| **Firewall** | ❌ No | ✅ UFW configured |
| **Auto-Renewal** | N/A | ✅ Certbot timer |
| **Custom Domain** | ❌ No | ✅ Yes |
| **Sanora Service** | ❌ No | ✅ Systemd service |

## Integration with Planet Nine

This store deployment system integrates with the broader Planet Nine ecosystem:

- **Federated Feeds**: Libris, Scribus, Canimus specifications enable cross-store discovery
- **Sanora**: Powers dynamic feed generation from uploaded products
- **Sessionless Auth**: Owner keypairs enable cryptographic identity
- **Privacy-First**: No tracking, no surveillance, local-first storage
- **Decentralized**: Each store is independent, federated via feeds

## Development Workflow

### 1. Create Artifacts Locally

```bash
mkdir my-digital-artifacts
cd my-digital-artifacts

# Add books, music, blog posts
cp ~/Documents/my-book.epub .
cp ~/Music/my-track.mp3 .
cp ~/Blog/my-post.md .
```

### 2. Test Locally

```bash
node /path/to/tools/make-store.js "Test Store"
# Visit http://localhost:8080
# Test feed URLs
# Verify artifacts are accessible
```

### 3. Deploy to Production

```bash
cd /path/to/the-advancement/src/servers
node deploy-store.js test-store ~/my-digital-artifacts --project allyabase
# Wait for deployment
# Visit https://test-store.allyabase.com
```

### 4. Update Artifacts

```bash
# Add new artifacts locally
cp ~/Documents/new-book.epub ~/my-digital-artifacts/

# Regenerate feeds
node /path/to/tools/make-store.js "Test Store" ~/my-digital-artifacts

# Re-deploy
node deploy-store.js test-store ~/my-digital-artifacts --project allyabase
```

## Future Enhancements

- [ ] Automated backups to Digital Ocean Spaces
- [ ] Multi-store management dashboard
- [ ] Custom domain validation before deployment
- [ ] Artifact versioning and updates
- [ ] User-uploaded artifacts via web interface
- [ ] Payment processing for paid artifacts
- [ ] Analytics and download tracking (privacy-preserving)
- [ ] Federation discovery protocol
- [ ] Cross-store search and recommendations

## References

- **Libris Specification**: `/specs/libris.md`
- **Scribus Specification**: `/specs/scribus.md`
- **Canimus Specification**: https://github.com/PlaidWeb/Canimus
- **Feed Generator**: `/tools/feed-generator/`
- **Sanora Documentation**: `/sanora/CLAUDE.md`
- **Digital Ocean API**: https://docs.digitalocean.com/reference/api/
- **Let's Encrypt**: https://letsencrypt.org

---

**Status**: Production-ready ✅

**Last Updated**: November 2025

**Maintainer**: Planet Nine Team
