# 🔗 LinkHub - Planet Nine's Linktree Alternative

LinkHub is Planet Nine's first business - a privacy-first, cryptographically-secured link management service. Users can display their carrierBag links in beautiful SVG layouts without tracking or surveillance.

## Overview

LinkHub fetches a user's links from their Fount carrierBag and displays them in one of three responsive SVG templates based on link count:

- **Compact Layout** (1-6 links) - Large vertical cards
- **Grid Layout** (7-13 links) - 2-column grid
- **Dense Layout** (14-20 links) - 3-column compact grid

## Installation

```bash
cd linkhub
npm install
```

## Usage

### Start the Server

```bash
npm start
```

Server runs on `http://localhost:3010` by default.

### Demo Mode (Unauthenticated)

Visit `http://localhost:3010` to see demo links.

### Authenticated Mode (Real User Links)

To display a user's actual links from their carrierBag:

```
http://localhost:3010?pubKey=YOUR_PUBKEY&timestamp=TIMESTAMP&signature=SIGNATURE
```

**Authentication Flow:**
1. User provides their pubKey
2. User signs message: `timestamp + pubKey`
3. Server verifies signature using sessionless-node
4. Server fetches user's Fount BDO
5. Server extracts `carrierBag.links` collection
6. Server generates appropriate SVG template

## SVG Templates

### Template 1: Compact Layout (1-6 links)
- Large 600x90px cards
- Vertical stack
- Prominent titles
- Arrow indicator
- Best for showcasing a few important links

### Template 2: Grid Layout (7-13 links)
- 2-column grid
- 290x80px cards
- Medium density
- Great for social profiles and projects

### Template 3: Dense Layout (14-20 links)
- 3-column grid
- 190x65px cards
- High density
- Perfect for extensive link collections

## Features

✅ **Privacy-First** - No tracking, no analytics, no surveillance
✅ **Cryptographic Auth** - Sessionless authentication via signatures
✅ **Beautiful SVGs** - 6 gradient color schemes (green, blue, purple, pink, orange, red)
✅ **Responsive** - Adapts layout based on link count
✅ **Planet Nine Integration** - Direct carrierBag integration
✅ **Purchase CTA** - Subscription placeholder ($9.99/year)

## Environment Variables

- `PORT` - Server port (default: 3010)
- `FOUNT_BASE_URL` - Fount service URL (default: https://plr.allyabase.com/plugin/allyabase/fount/)

## NPM Dependencies

- **bdo-js** - BDO client library
- **fount-js** - Fount integration for carrierBag access
- **addie-js** - Payment processing (future)
- **sessionless-node** - Cryptographic signature verification
- **express** - Web server

## Business Model

**Subscription**: $9.99/year

**Features:**
- Custom subdomain (yourname.linkhub.planetnine.app)
- Unlimited links (up to 20 displayed)
- Custom themes (future)
- Analytics dashboard (privacy-preserving, future)
- Custom domain support (future)

## Purchase Flow (TODO)

The purchase CTA currently shows a placeholder. Future implementation:

1. User clicks "Get Started"
2. Payment modal appears (using The Advancement)
3. Stripe payment via addie-js
4. Subscription BDO created in carrierBag
5. User assigned subdomain
6. Access granted to custom settings

## Example carrierBag Links Structure

```json
{
  "carrierBag": {
    "links": [
      {
        "title": "github.com",
        "url": "https://github.com/yourname",
        "type": "link",
        "svgContent": "<svg>...</svg>",
        "savedAt": "2025-01-07T12:00:00Z"
      },
      {
        "title": "twitter.com",
        "url": "https://twitter.com/yourname",
        "type": "link",
        "svgContent": "<svg>...</svg>",
        "savedAt": "2025-01-07T12:01:00Z"
      }
    ]
  }
}
```

## Development Roadmap

### Phase 1 (Current)
- ✅ Basic server with Express
- ✅ Fount integration
- ✅ Three SVG templates
- ✅ Sessionless authentication
- ✅ Demo mode
- 🚧 Purchase CTA placeholder

### Phase 2 (Next)
- [ ] Stripe payment integration via addie-js
- [ ] Subscription management
- [ ] Custom subdomain assignment
- [ ] User dashboard

### Phase 3 (Future)
- [ ] Custom themes
- [ ] Link click analytics (privacy-preserving)
- [ ] Custom domain support
- [ ] QR code generation
- [ ] Link scheduling
- [ ] Social media preview images

## License

MIT

## About Planet Nine

Planet Nine is building a privacy-first ecosystem for commerce and communication. LinkHub is our first business built on top of the Planet Nine infrastructure, demonstrating how apps can leverage carrierBag for user data storage.

**Key Principles:**
- Privacy by design
- Cryptographic authentication
- User-owned data
- No surveillance capitalism
