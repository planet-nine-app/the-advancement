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

## Integration with Planet Nine Ecosystem

The Advancement serves as the **primary consumer gateway** to Planet Nine:

- **🔐 Sessionless Authentication**: Passwordless login across all Planet Nine services
- **🏠 Home Base Selection**: User choice and persistent base management
- **💳 Payment Processing**: Secure commerce without intermediaries
- **🎯 MAGIC Protocol**: Universal spell casting across applications
- **📡 Teleported Commerce**: Cross-base product discovery and purchasing
- **📜 Contract Management**: Create, sign, and manage contracts through Covenant integration

---

**The Advancement** represents the future of privacy-first web browsing - not through blocking and breaking the web, but through intelligent covering, cryptographic empowerment, and user-controlled commerce.