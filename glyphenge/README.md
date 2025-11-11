# ✨ Glyphenge - Planet Nine's Mystical Link Tapestry

Glyphenge is Planet Nine's first enchantment from The Enchantment Emporium - a privacy-first, cryptographically-secured link weaving service. Users can display their carrierBag links in beautiful runic SVG tapestries without tracking or surveillance.

## Overview

Glyphenge weaves a user's links from their carrierBag into one of three mystical SVG tapestry patterns based on link count:

- **Compact Tapestry** (1-6 links) - Large vertical glyphs
- **Grid Tapestry** (7-13 links) - 2-column runic pattern
- **Dense Tapestry** (14-20 links) - 3-column compact weave

## Enchantment Flow

### For Link Creators:
1. Collect links in AdvanceKey (auto-saves to carrierBag "links" collection)
2. Visit **The Enchantment Emporium** in The Advancement app
3. Cast the **Glyphenge Enchantment** via MAGIC protocol
4. Receive your emojicode rune 😀🔗💎🌟...
5. Share your emojicode - anyone can view your tapestry!

### For Link Viewers:
1. Receive an emojicode from a friend
2. Visit: `glyphenge.com?emojicode=😀🔗💎🌟...`
3. View the mystical link tapestry
4. No app required! Public access for everyone.

## Installation

```bash
cd glyphenge
npm install
```

## Usage

### Start the Tapestry Weaver

```bash
npm start
```

Server runs on `http://localhost:3010` by default.

### Demo Tapestry (Unauthenticated)

Visit `http://localhost:3010` to see a demo link tapestry.

### Public Access via Emojicode

To view a user's enchanted tapestry:

```
http://localhost:3010?emojicode=😀🔗💎🌟...
```

**No authentication required for viewers!** Glyphenge acts as a public proxy, fetching the enchanted BDO from the BDO service using the emojicode rune.

### Alphanumeric URLs (Browser-Friendly)

For easier sharing in browsers where emoji URLs may be problematic:

```
http://localhost:3010/t/02a1b2c3d4e5f6a7
```

Every tapestry gets **both URL formats**:
- **Emojicode URL**: Persistent, human-memorable, fun to share
- **Alphanumeric URL**: Browser-friendly, easier to copy/paste

**Note**: Alphanumeric URLs use in-memory storage and are lost on server restart. For long-term sharing, always use emojicodes.

### Legacy Authenticated Mode

For backward compatibility with direct carrierBag access:

```
http://localhost:3010?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE
```

## SVG Tapestry Patterns

### Pattern 1: Compact Tapestry (1-6 links)
- Large 600x90px runic cards
- Vertical weave
- Prominent glyphs
- Mystical arrow indicators
- Best for showcasing key destinations

### Pattern 2: Grid Tapestry (7-13 links)
- 2-column runic grid
- 290x80px cards
- Balanced density
- Perfect for social realms and projects

### Pattern 3: Dense Tapestry (14-20 links)
- 3-column compact weave
- 190x65px cards
- High density runes
- Ideal for extensive link collections

## Features

✨ **Privacy-First** - No tracking, no analytics, no surveillance
🔐 **Cryptographic Auth** - Sessionless signature verification
🎨 **Mystical SVGs** - 6 gradient color schemes (green, blue, purple, pink, orange, red)
📱 **Responsive Weaving** - Adapts pattern based on link count
🌐 **Public Access** - Anyone can view via emojicode, no app required
✨ **Enchantment Emporium** - Created via MAGIC protocol spell casting
🔮 **Emojicode Runes** - Human-memorable identifiers for sharing

## Environment Variables

- `PORT` - Server port (default: 3010)
- `FOUNT_BASE_URL` - Fount service URL
- `BDO_BASE_URL` - BDO service URL for fetching BDOs by emojicode or pubKey

**Architecture Note**: Glyphenge returns only identifiers (emojicode, pubKey), not full URLs. **Clients construct URLs** based on their own environment. This eliminates the need for the server to know its deployment context.

**Docker Testing**: Simply set the PORT to match your container port mapping:

```bash
# For Docker Base 1 (port 5125)
PORT=5125 node server.js

# Or use the convenience script
./start-for-docker-tests.sh
```

## NPM Dependencies

- **bdo-js** - BDO client library (fetches enchanted tapestries by emojicode)
- **fount-js** - Fount integration for carrierBag access (legacy)
- **addie-js** - Payment processing via MAGIC protocol
- **sessionless-node** - Cryptographic signature verification
- **express** - Tapestry weaver web server

## The Enchantment Emporium

Glyphenge is the first enchantment available in **The Enchantment Emporium** - a mystical location within The Advancement app where users can cast MAGIC spells to create Planet Nine services.

### Casting the Glyphenge Enchantment:

1. **Gather Your Links** - Links auto-collected in AdvanceKey carrierBag
2. **Visit the Emporium** - Navigate to The Enchantment Emporium
3. **Select Glyphenge** - Choose the link tapestry enchantment
4. **Cast the Spell** - MAGIC protocol creates your enchanted BDO
5. **Receive Your Rune** - Emojicode generated for sharing
6. **Share Your Tapestry** - Send emojicode to friends & followers

### Enchantment Cost:
- MP (Magic Points) or nineum via MAGIC protocol
- One-time enchantment casting
- Permanent public tapestry

### Word of Power Protection:
- **Client-Side Validation**: Word of power validation happens entirely in the browser using SHA256 hashing
- **No Server-Side Secrets**: Server never receives or validates the word of power
- **Hash Comparison**: Enchantment definitions store SHA256 hash of the word of power (e.g., hash of "abracadabra")
- **Secure Flow**: User enters word → Browser hashes input → Compares with stored hash → Only casts spell if match
- **Privacy Preserving**: Word of power never transmitted over network

## BDO Structure (Enchanted Tapestry)

```json
{
  "title": "My Glyphenge",
  "type": "glyphenge",
  "links": [
    {
      "title": "github.com",
      "url": "https://github.com/yourname",
      "svgContent": "<svg>...</svg>",
      "savedAt": "2025-01-08T12:00:00Z"
    },
    {
      "title": "twitter.com",
      "url": "https://twitter.com/yourname",
      "svgContent": "<svg>...</svg>",
      "savedAt": "2025-01-08T12:01:00Z"
    }
  ],
  "emojicode": "😀🔗💎🌟💎🎨🐉📌",
  "createdAt": "2025-01-08T12:00:00Z"
}
```

## Development Roadmap

### Phase 1 (Current)
- ✅ Tapestry weaver server with Express
- ✅ BDO service integration for emojicode lookups
- ✅ Three SVG tapestry patterns
- ✅ Public access via emojicode (no auth required)
- ✅ Demo tapestry mode
- 🚧 Enchantment Emporium integration

### Phase 2 (Next)
- [ ] Enchantment Emporium view controller
- [ ] Glyphenge enchantment spell via MAGIC protocol
- [ ] Emojicode generation and storage
- [ ] Share functionality in app

### Phase 3 (Future)
- [ ] Custom tapestry themes
- [ ] Link rune click analytics (privacy-preserving)
- [ ] Custom domain weaving
- [ ] QR code runes
- [ ] Time-based link scheduling
- [ ] Social realm preview images

## License

MIT

## About Planet Nine & The Enchantment Emporium

Planet Nine is building a privacy-first mystical ecosystem for commerce and communication. **The Enchantment Emporium** is where users cast spells to create Planet Nine services.

**Glyphenge** is the first enchantment, demonstrating how MAGIC spells can create public services from user-owned carrierBag data.

**Key Magical Principles:**
- Privacy by enchantment design
- Cryptographic spell casting
- User-owned mystical data
- No surveillance magic
- Public access to enchanted creations
