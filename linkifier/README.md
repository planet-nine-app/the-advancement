# 🔗 Linkifier

Create shareable link BDOs for the Planet Nine ecosystem

## Overview

Linkifier is a simple CLI tool that creates public BDOs containing links. Each BDO gets a human-memorable emojicode that can be easily shared. When users tap the BDO, it opens the link in their default browser (not in a WebView).

## Installation

```bash
cd linkifier
npm install
chmod +x linkifier.js
```

## Usage

### Basic Usage

```bash
# Create a link BDO (auto-generates title from domain)
./linkifier.js https://github.com/planet-nine

# Create with custom title
./linkifier.js https://github.com/planet-nine "Planet Nine GitHub"
```

### Using Different BDO Services

```bash
# Local BDO service (default: http://localhost:3003)
./linkifier.js https://example.com

# Remote BDO service
./linkifier.js https://example.com --bdo-url=https://plr.bdo.allyabase.com
```

### Help

```bash
./linkifier.js --help
```

## Output Example

```
🔗 Linkifier - Planet Nine Link BDO Creator
==========================================

📎 URL: https://github.com/planet-nine
📝 Title: github.com
🌐 BDO Service: http://localhost:3003

🔑 Generating sessionless keys...
✅ Keys generated
   PubKey: 02a1b2c3d4e5f6a7...

📦 Creating BDO...
✅ BDO created successfully!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Link BDO Created!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎨 Emojicode:
   💚🌍🔑💎🌟💎🎨🐉📌

📋 Details:
   UUID: abc123-def456-...
   PubKey: 02a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5...
   Title: github.com
   URL: https://github.com/planet-nine

🔗 Access:
   By UUID: http://localhost:3003/user/abc123-def456-.../bdo
   By Emojicode: http://localhost:3003/emoji/💚🌍🔑💎🌟💎🎨🐉📌

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Features

- ✅ **Simple CLI** - Just pass a URL and optional title
- ✅ **Auto-title Generation** - Extracts domain name if no title provided
- ✅ **Public BDOs** - Automatically creates public BDO with emojicode
- ✅ **Beautiful SVG** - Green gradient design matching Planet Nine branding
- ✅ **External Links** - Opens in default browser via `target="_blank"`
- ✅ **Sessionless Keys** - Generates temporary keys for each link BDO
- ✅ **Flexible** - Works with any BDO service URL

## BDO Structure

Each link BDO contains:

```json
{
  "title": "github.com",
  "type": "link",
  "contentType": "external-link",
  "url": "https://github.com/planet-nine",
  "description": "Link to https://github.com/planet-nine",
  "svgContent": "<svg>...</svg>",
  "metadata": {
    "createdAt": "2025-01-06T...",
    "originalUrl": "https://github.com/planet-nine",
    "createdBy": "Linkifier CLI"
  }
}
```

## SVG Design

The generated SVG (320x100):
- Green gradient background (#10b981 → #059669)
- 🔗 emoji icon
- Title (truncated to 25 chars)
- "Tap to open link" subtitle
- Clickable `<a>` element with `target="_blank"`

## Use Cases

- **Quick Link Sharing** - Create shareable links for the Planet Nine ecosystem
- **Bookmarking** - Save important links as BDOs
- **Link Collections** - Build curated lists of resources
- **Deep Linking** - Create links to external content from Planet Nine apps

## Dependencies

- **bdo-js** - BDO client library
- **sessionless-node** - Cryptographic key generation and signing

## License

MIT
