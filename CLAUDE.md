# The Advancement - Privacy-First Browser Extensions

## Overview

**The Advancement** is Planet Nine's privacy-focused browser extension ecosystem that provides users with cryptographic authentication, intelligent input detection, natural typing simulation, and ad covering capabilities. It serves as the consumer-facing entry point to the Planet Nine ecosystem, offering privacy protection and convenience features without surveillance or data collection.

## Core Philosophy

- **Privacy by Design**: No data collection, tracking, or surveillance
- **Ad Covering over Blocking**: Cover ads with peaceful content while ensuring creators get paid
- **Sessionless Authentication**: Passwordless access using cryptographic keys
- **Natural Interaction**: Human-like typing simulation to avoid bot detection
- **Gaming Optional**: Users can choose between peaceful or interactive ad experiences
- **Planet Nine Gateway**: Primary entry point for users into the Planet Nine ecosystem
- **Decentralized Commerce**: Secure payment processing without centralized intermediaries

## 📚 Detailed Documentation

This main document provides an overview. For detailed information, see our modular documentation:

- **[Browser Extensions](docs/BROWSER-EXTENSIONS.md)** - Chrome & Safari extension architecture and implementation
- **[Ad Covering System](docs/AD-COVERING-SYSTEM.md)** - Complete Ficus/AdversementSystem with entertainment features
- **[Emojicoding System](docs/EMOJICODING.md)** - Revolutionary emoji-based UUID encoding
- **[Payment Processing](docs/PAYMENT-PROCESSING.md)** - Stripe integration & decentralized commerce
- **[MAGIC Protocol](docs/MAGIC-PROTOCOL.md)** - Complete spell casting implementation
- **[Test Environment](docs/TEST-ENVIRONMENT.md)** - Comprehensive testing infrastructure
- **[Technical Architecture](docs/TECHNICAL-ARCHITECTURE.md)** - Detailed implementation patterns

## Quick Start

### Chrome Extension
```bash
cd src/extensions/chrome
# Load unpacked extension in Chrome developer mode
```

### Safari Extension
```bash
cd src/extensions/safari
swift build -c release
# Install in Safari preferences
```

### Test Environment
```bash
cd test-server
npm install && npm start
open http://localhost:3456
# Complete Planet Nine purchase flow testing
```

## Key Features

### ✅ **Complete Payment Processing** (January 2025)
- **Multi-Party Transactions**: 70% creator, 20% base, 10% site payment splits
- **Stripe Integration**: Full payment processing through extension
- **Home Base Coordination**: Payment routing through user's selected Planet Nine base
- **Cross-Base Commerce**: Purchase from any Planet Nine base

### ✅ **Ad Covering System** (September 2025)
- **Dual Mode Experience**: Peaceful ficus plants OR interactive slime monsters
- **Real-Time Detection**: MutationObserver-based ad scanning
- **Creator-Friendly**: Ad impressions preserved, revenue protected
- **Entertainment System**: NES-inspired gaming with physics-based damage

### ✅ **Emojicoding System** (September 2025)
- **UUID Transformation**: Convert complex UUIDs to memorable emoji sequences
- **Perfect Accuracy**: Flawless round-trip conversion
- **iOS Integration**: Tap-to-copy and decode functionality
- **Visual Debug System**: Real-time encoding/decoding logs

### ✅ **MAGIC Protocol Integration** (August 2025)
- **Complete Spell Casting**: End-to-end MAGIC protocol implementation
- **Background Management**: Centralized spellbook with Swift integration
- **Real Nineum Balance**: Live currency tracking and updates
- **Cross-Application**: Universal spell casting across Planet Nine ecosystem

### ✅ **Fount Integration & CarrierBag System** (January 2025)
- **Direct Fount Integration**: Native Swift API calls to Fount service
- **User Instantiation**: Automatic Fount user creation with cryptographic keys
- **CarrierBag Architecture**: Persistent user-owned BDO containing 14 collections
- **Recipe Management**: Save and sync recipes through Fount carrierBag
- **Multi-Collection Support**: cookbook, apothecary, gallery, bookshelf, familiarPen, machinery, metallics, music, oracular, greenHouse, closet, games, events, contracts
- **Native UI**: InstantiationViewController and CarrierBagViewController for data visualization

### ✅ **BDO Emojicode Support** (October 2025)
- **Human-Readable Identifiers**: Public BDOs automatically receive 8-emoji codes (3 base + 5 unique)
- **Easy Sharing**: Share BDOs using memorable emojicodes instead of long cryptographic keys
- **Bidirectional Lookup**: Resolve emojicodes to pubKeys and vice versa
- **Query Parameter Support**: Retrieve BDOs using `?emojicode=...` query parameter
- **Base-Specific Codes**: Each Planet Nine base has unique 3-emoji signature
- **Automatic Assignment**: Emojicodes generated automatically when saving public BDOs
- **Direct Access**: Dedicated `/emoji/:emojicode` endpoint for instant BDO retrieval

### ✅ **Contract System Integration** (January 2025)
- **Covenant Emojicodes**: Contracts generate emojicodes for easy sharing and identification
- **Contract Saving**: Save contracts to carrierBag "contracts" collection via AdvanceKey
- **Contract Visualization**: Scaled SVG contract display in AdvanceKey keyboard with proper viewport fitting
- **Authorization UI**: Native Swift buttons (SIGN/View-Only) next to DEMOJI button based on participant status
- **Contract Signing**: Sign contract steps using Sessionless authentication through AdvanceKey
- **PubKey Display**: AdvanceKey public key exposed in main app for adding to contract participants
- **Shared Authentication**: Main app and AdvanceKey share same Sessionless keys via App Group keychain
- **Simplified BDO Structure**: Contracts store dark-theme SVG as `svgContent` with `bdoPubKey` and `emojicode` fields
- **Test Environment**: Covenant service on port 5122 (allyabase-base1 container)

### ✅ **NFC Coordinating Keys Integration** (October 2025)
- **NFC Reading**: Read NFC tags containing pubKey + signature tuples using CoreNFC
- **NFC Writing**: Write coordinating keys to NFC tags for physical key distribution
- **Julia Verification**: Automated verification flow through Julia service
- **BDO Integration**: Fetch and verify signatures against BDO-stored messages
- **Coordinating vs Interacting**: Automatic key type detection based on BDO `coordinating` flag
- **Key Rotation**: Automatic key rotation and new BDO creation when `rotate: true` in BDO
- **Native iOS UI**: Full NFCViewController with read/write/verify flows
- **Tag Data Format**: JSON-encoded `{pubKey, signature}` stored in NDEF format

## File Structure

```
the-advancement/
├── README.md                    # Project overview
├── CLAUDE.md                   # This documentation (now modular!)
├── docs/                       # Detailed documentation
│   ├── BROWSER-EXTENSIONS.md   # Chrome & Safari implementation
│   ├── AD-COVERING-SYSTEM.md   # Ficus/entertainment system
│   ├── EMOJICODING.md          # UUID emoji encoding
│   ├── PAYMENT-PROCESSING.md   # Stripe & commerce
│   ├── MAGIC-PROTOCOL.md       # Spell casting system
│   ├── TEST-ENVIRONMENT.md     # Testing infrastructure
│   └── TECHNICAL-ARCHITECTURE.md # Implementation patterns
├── test-server/                # Complete test environment
├── resources/                  # Assets (ficus.jpg, etc.)
└── src/
    └── extensions/
        ├── chrome/             # Chrome extension
        ├── safari/             # Safari extension + native app
        └── The Advancement/AdvanceKey/  # iOS keyboard extension
```

## Current Status (January 2025)

### ✅ Production Ready Features
- **Safari Extension**: Complete Planet Nine ecosystem integration
- **Payment Processing**: Multi-party Stripe integration with real cryptography
- **Home Base Management**: Three-environment base discovery and selection
- **Ad Covering System**: Dual-mode experience (plants/monsters) with entertainment
- **Emojicoding**: Perfect UUID ↔ emoji conversion with iOS integration
- **MAGIC Protocol**: Complete spell casting with background management
- **Contract System**: Full contract saving and signing via AdvanceKey with Covenant integration
- **Test Environment**: Comprehensive testing infrastructure

### 🚧 In Development
- **Chrome Extension**: Manifest v3 update and feature parity with Safari
- **Firefox Support**: Cross-browser compatibility expansion
- **Mobile Extensions**: iOS and Android extension capabilities

## NFC Coordinating Keys System

### Overview

The NFC system enables physical distribution and verification of cryptographic keys through NFC tags. Users can tap their iPhone to NFC tags to read coordinating keys and automatically add them to their Julia account after verification.

### Architecture

```
┌─────────────────┐
│   iPhone + NFC  │
│   Tag (NDEF)    │
└────────┬────────┘
         │ Read: {pubKey, signature}
         ▼
┌─────────────────┐
│  NFCService     │
│  (Swift)        │
└────────┬────────┘
         │ POST /nfc/verify
         ▼
┌─────────────────┐
│  Julia Service  │
│  (Node.js)      │
└────────┬────────┘
         │ 1. Fetch BDO by pubKey
         ▼
┌─────────────────┐
│  BDO Service    │
│  Returns: {     │
│    message,     │
│    coordinating,│
│    rotate       │
│  }              │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Verification   │
│  + Key Addition │
└─────────────────┘
```

### NFC Tag Format

Tags store JSON data in NDEF format:
```json
{
  "pubKey": "02a1b2c3...",
  "signature": "3045022100..."
}
```

### BDO Structure for NFC Keys

BDOs associated with NFC tags must contain:
```json
{
  "data": {
    "message": "Sign this to verify ownership",
    "coordinating": true,  // or false for interacting keys
    "rotate": false        // set to true to trigger key rotation
  }
}
```

### Verification Flow

1. **Read Tag**: iOS app reads NFC tag using CoreNFC
2. **Send to Julia**: `POST /nfc/verify` with `{primaryUUID, pubKey, signature}`
3. **Fetch BDO**: Julia fetches BDO using `bdo.getBDO(pubKey)`
4. **Verify Signature**: Julia verifies signature against BDO message
5. **Add Key**:
   - If `coordinating: true` → Add as coordinatingKey
   - If `coordinating: false` → Add as interactingKey
6. **Rotate** (if `rotate: true`):
   - Generate new keypair
   - Create new BDO with original data
   - Return new pubKey to iOS app

### Swift Implementation

**NFCService.swift** (`the-advancement/src/The Advancement/Shared (App)/NFCService.swift`):
- `readTag()` - Read NFC tags with NDEF format
- `writeTag()` - Write pubKey + signature to NFC tags
- Handles CoreNFC session lifecycle
- Returns NFCTagData struct

**NFCViewController.swift** (`the-advancement/src/The Advancement/Shared (App)/NFCViewController.swift`):
- Read/Write UI flows
- Julia verification integration
- Result display with key type and rotation status

### Julia Implementation

**Endpoint**: `POST /nfc/verify` (`julia/src/server/node/julia.js:605`)

**Request Body**:
```javascript
{
  "primaryUUID": "user-uuid",
  "pubKey": "02a1b2c3...",
  "signature": "3045022100...",
  "timestamp": "1697040000000"
}
```

**Response**:
```javascript
{
  "success": true,
  "message": "Key verified and added as coordinating key",
  "keyType": "coordinating",  // or "interacting"
  "pubKey": "02a1b2c3...",
  "rotated": false,            // true if rotation occurred
  "newPubKey": "02d4e5f6...",  // only if rotated
  "rotationUUID": "..."        // only if rotated
}
```

### Configuration

**iOS Info.plist** (`the-advancement/src/The Advancement/iOS (App)/Info.plist`):
```xml
<key>NFCReaderUsageDescription</key>
<string>The Advancement needs NFC access to read and write coordinating keys</string>
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
  <string>NDEF</string>
  <string>TAG</string>
</array>
```

**Xcode Capabilities**:
- Near Field Communication Tag Reading

### Usage Example

1. **Create BDO for NFC Key**:
```javascript
// In BDO service
const bdoData = {
  message: "Verify NFC key ownership",
  coordinating: true,
  rotate: false
};
await bdo.createBDO(pubKey, hash, bdoData);
```

2. **Write to NFC Tag** (iOS):
```swift
NFCService.shared.writeTag(
  pubKey: keys.publicKey,
  signature: signature
) { result in
  // Tag written
}
```

3. **Read and Verify** (iOS):
```swift
NFCService.shared.readTag { result in
  // Send to Julia for verification
  verifyWithJulia(tagData)
}
```

### Security Considerations

- **Signature Verification**: All NFC keys must be cryptographically signed
- **BDO Message**: Message in BDO prevents replay attacks
- **Key Rotation**: Automatic rotation invalidates old keys
- **No Secrets on Tag**: Only public keys and signatures stored on NFC tags

## BDO Emojicode Usage

### Overview

Emojicodes provide a human-friendly way to share and access public BDOs across the Planet Nine ecosystem. Instead of sharing long cryptographic keys, users can share memorable 8-emoji sequences.

### Emojicode Format

```
🌍🔑💎🌟💎🎨🐉📌
└─┬─┘└────┬────┘
  │       └─ 5 unique emoji (identifies specific BDO)
  └─ 3 base emoji (identifies Planet Nine base)
```

### API Integration

#### Get Emojicode for a BDO
```javascript
// Reverse lookup: pubKey → emojicode
GET /pubkey/{pubKey}/emojicode

Response:
{
  "pubKey": "02a1b2c3...",
  "emojicode": "🌍🔑💎🌟💎🎨🐉📌",
  "createdAt": 1697040000000
}
```

#### Retrieve BDO by Emojicode
```javascript
// Direct access
GET /emoji/🌍🔑💎🌟💎🎨🐉📌

Response:
{
  "emojicode": "🌍🔑💎🌟💎🎨🐉📌",
  "pubKey": "02a1b2c3...",
  "bdo": { ... },
  "createdAt": 1697040000000
}
```

#### Use Emojicode Query Parameter
```javascript
// In authenticated BDO requests
GET /user/{uuid}/bdo?timestamp={ts}&hash={hash}&signature={sig}&emojicode=🌍🔑💎🌟💎🎨🐉📌

Response:
{
  "uuid": "user-uuid",
  "bdo": { ... }
}
```

### Use Cases in The Advancement

**1. CarrierBag Sharing**
- Share recipes, contracts, or NFTs using emojicodes
- Users can tap/copy emojicodes for easy sharing
- iOS keyboard can detect and auto-decode emojicodes

**2. Contract Distribution**
- Contracts already generate emojicodes via Covenant
- Emojicodes enable easy contract sharing between users
- Sign contracts by entering emojicode instead of full pubKey

**3. Cross-Base Commerce**
- Products from other bases can be shared via emojicodes
- Simplified teleportation using emojicodes as identifiers
- Base discovery using base-specific emoji prefixes

**4. NFC Tag Enhancement**
- NFC tags could store emojicodes alongside pubKeys
- Quick visual verification of tag identity
- Human-readable tag labels

### Configuration

Set base emoji identifier via environment variable:
```bash
export BDO_BASE_EMOJI="🏰👑✨"
```

Each Planet Nine base should have unique base emoji for easy identification:
- Dev environment: `🌍🔑💎`
- Production base: `🏰👑✨`
- Test environment: `🧪🔬🧬`

## Integration with Planet Nine Ecosystem

The Advancement serves as the **primary consumer gateway** to Planet Nine:

- **🔐 Sessionless Authentication**: Passwordless login across all Planet Nine services
- **🏠 Home Base Selection**: User choice and persistent base management
- **💳 Payment Processing**: Secure commerce without intermediaries
- **🎯 MAGIC Protocol**: Universal spell casting across applications
- **📡 Teleported Commerce**: Cross-base product discovery and purchasing
- **📜 Contract Management**: Create, sign, and manage contracts through Covenant integration
- **📱 NFC Coordinating Keys**: Physical key distribution and verification through Julia
- **😀 BDO Emojicodes**: Human-friendly sharing of BDOs across the ecosystem

---

**The Advancement** represents the future of privacy-first web browsing - not through blocking and breaking the web, but through intelligent covering, cryptographic empowerment, and user-controlled commerce.