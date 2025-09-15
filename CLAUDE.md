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

## Architecture

### Browser Extension Framework

The Advancement supports multiple browsers with consistent functionality:

#### **Chrome Extension** (`src/extensions/chrome/`)
- **Manifest v1**: Current implementation (needs v3 update)
- **Content Scripts**: Input detection, typing simulation, auto-fill
- **Background Service**: Extension coordination and state management
- **No Native App**: All functionality runs in browser context

#### **Safari Extension** (`src/extensions/safari/`)
- **Native App Integration**: Secure XPC communication with macOS app
- **Keychain Storage**: Cryptographic keys stored in macOS Keychain
- **Comprehensive Features**: Full input detection + sessionless authentication + payment processing
- **Enhanced Security**: All crypto operations happen in native code
- **Home Base Management**: Complete three-environment base discovery and selection (DEV, TEST, LOCAL)
- **Payment Processing**: Stripe integration with multi-party payment splitting
- **Graceful Degradation**: Fallback functionality when bridge methods unavailable
- **Production Ready**: Real secp256k1 cryptography with compressed key format (02/03 prefix)

#### **iOS Extensions** (`src/The Advancement/`)
- **Advancekey**: Custom keyboard extension with 4-tab Planet Nine interface and real BDO integration
- **AdvanceLook**: QuickLook preview extension for .magicard files with Planet Nine branding
- **AdvanceWidget**: Complete widget system with main widget, control buttons, and live activities
- **AdvanceAction**: macOS Action Extension for displaying Planet Nine cards from selected text containing bdoPubKeys
- **Real Cryptography**: All extensions use actual `Sessionless().sign()` for signature generation
- **BDO Integration**: Keyboard, widget, and action extensions fetch real magistack cards from BDO service
- **Live Activities**: Widget controls trigger live activities with real signatures and color changes
- **No Mock Data**: Complete removal of placeholder/demo data in favor of real Planet Nine services

### iOS Extension Details

#### **Advancekey - Planet Nine Keyboard** ✅
**Location**: `src/The Advancement/Advancekey/`

A comprehensive iOS keyboard extension providing Planet Nine functionality directly within the keyboard interface:

**Features**:
- **4-Tab Interface**: Cards, Auth, Tools, Info tabs with Planet Nine gradient styling
- **BDO Card Display**: Fetches and displays real magistack cards using working BDO URL
- **Real Cryptography**: Uses sessionless authentication for all operations
- **WebKit Integration**: WKWebView for rendering SVG card content
- **Planet Nine Branding**: Complete visual integration with ecosystem styling

**Technical Implementation**:
```swift
// Real BDO integration (same URL as browser extensions)
let bdoURL = "http://127.0.0.1:5114/user/.../bdo?timestamp=...&signature=...&pubKey=..."

// Parse response like other extensions
if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
   let bdoObject = jsonObject["bdo"] as? [String: Any],
   let cardData = bdoObject["svgContent"] as? String {
    // Display real SVG content in WebView
}
```

#### **AdvanceLook - QuickLook Preview** ✅
**Location**: `src/The Advancement/AdvanceLook/`

QuickLook preview extension that displays Planet Nine branded previews for .magicard files:

**Features**:
- **File Type Registration**: Handles .magicard files for preview
- **Planet Nine UI**: Gradient backgrounds and branded preview interface
- **Multiple Formats**: Supports JSON cards, BDO references, and debug text files
- **Rich HTML Preview**: Generates comprehensive HTML with card metadata
- **Cross-Platform Sharing**: Works with Messages, AirDrop, and other sharing methods

**File Format Support**:
- **JSON Cards**: Full `MagiCardData` structure with SVG content
- **BDO References**: Files containing `bdopubkey:` for server lookup
- **Debug Files**: Text files for testing extension functionality

#### **AdvanceWidget - Widget System** ✅
**Location**: `src/The Advancement/AdvanceWidget/`

Complete iOS widget system with main widget, control buttons, and live activities:

**Components**:
1. **Main Widget (`AdvanceWidget.swift`)**:
   - **BDO Integration**: Fetches real magistack cards using same URL as keyboard
   - **Card Display**: Shows pubKey, load status, and Planet Nine branding
   - **Timeline Updates**: Refreshes every hour with real card data
   - **Error Handling**: Graceful fallback when BDO unavailable

2. **Control Widgets**:
   - **`AdvanceWidgetControl`**: Blue 🌊 "foo" action control
   - **`AdvanceWidgetBarControl`**: Green 🌱 "bar" action control
   - **Static Configuration**: Each control has dedicated function
   - **Real Signatures**: Uses `Sessionless().sign()` for message signing

3. **Live Activities (`AdvanceWidgetLiveActivity.swift`)**:
   - **Real Signature Display**: Shows actual cryptographic signatures
   - **Dynamic Colors**: Changes color based on action (blue/green)
   - **Dynamic Island**: Full support for iPhone 14 Pro+ Dynamic Island
   - **Lock Screen**: Rich notifications with signature and timestamp

**Technical Flow**:
```swift
// Real signature generation (no mocks)
func perform() async throws -> some IntentResult {
    guard let signature = try await sessionless.sign(message: "foo") else {
        throw NSError(domain: "SessionlessError", code: 1, userInfo: [...])
    }
    await updateLiveActivity(message: "foo", signature: signature, color: .blue)
    return .result()
}
```

**User Experience**:
- **Control Center**: Add two separate controls (foo/bar) to Control Center
- **Widget Gallery**: Main widget shows real BDO card with status
- **Live Activities**: Real-time signature display with color coding
- **Keychain Integration**: Secure key storage shared with other extensions

#### **AdvanceAction - macOS Action Extension** ✅
**Location**: `src/The Advancement/AdvanceAction/`

A macOS Action Extension that detects bdoPubKeys in selected text and displays corresponding Planet Nine cards:

**Features**:
- **Text Selection Detection**: Automatically detects when text containing bdoPubKeys is selected
- **Share Menu Integration**: Appears in the macOS Share menu when compatible text is selected
- **BDO Integration**: Fetches real magistack cards using same BDO URL as other extensions
- **WebKit Card Display**: Renders SVG card content with Planet Nine styling
- **Smart pubKey Detection**: Validates 66-character hex strings with 02/03 prefix
- **Pattern Extraction**: Can extract pubKeys from formatted text (e.g., "pubKey: 03abc...")

**Technical Implementation**:
```swift
// Action Extension configuration for text selection
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsText</key>
    <true/>
    <key>NSExtensionActivationSupportsWebPageWithMaxCount</key>
    <integer>1</integer>
</dict>

// pubKey validation
private func isBDOPubKey(_ text: String) -> Bool {
    let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard cleanText.count == 66 else { return false }
    guard cleanText.hasPrefix("02") || cleanText.hasPrefix("03") else { return false }
    let hexCharacters = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
    return cleanText.unicodeScalars.allSatisfy { hexCharacters.contains($0) }
}

// Same BDO URL pattern as other extensions
let bdoURL = "http://127.0.0.1:5114/user/3129c121-e443-4581-82c4-516fb0a2cc64/bdo?..."
```

**Configuration Details**:
- **Extension Point**: `com.apple.ui-services` for proper Action Extension registration
- **Service Integration**: Also configures traditional NSServices for broader compatibility
- **Touch Bar Support**: Includes Touch Bar integration attributes
- **Finder Integration**: Supports Finder preview items with NSActionTemplate icon

**User Experience**:
- **Share Menu**: Select text containing bdoPubKey → Share button → "Show Planet Nine Card"
- **Card Display**: 500x400 window with Planet Nine gradient styling and SVG card rendering
- **Error Handling**: Clear feedback for invalid text or connection issues
- **Immediate Feedback**: Shows "Action Extension is working!" message on load

### Core Components

#### 1. **InputDetector Class**
```javascript
class InputDetector {
    constructor() {
        this.loginKeywords = ['user', 'username', 'login', 'account', 'email'];
    }
    
    // Detects input fields across:
    detectFields() {
        // - Regular DOM elements
        // - Shadow DOM components  
        // - iframe embedded content
        // - Dynamically loaded forms
    }
}
```

**Features**:
- **Multi-DOM Support**: Scans regular DOM, Shadow DOM, and iframes
- **Keyword Detection**: Identifies login fields using semantic analysis
- **Visual Feedback**: Adds privacy icons next to detected fields
- **Dynamic Monitoring**: Responds to page changes and new content

#### 2. **TypingSimulator Class**
```javascript
class TypingSimulator {
    constructor(options = {}) {
        this.minDelay = options.minDelay || 50;  // 50-150ms delays
        this.maxDelay = options.maxDelay || 150;
        this.naturalMode = options.naturalMode !== false;
    }
    
    async typeIntoElement(element, text) {
        // Simulates natural human typing with:
        // - Variable keystroke delays
        // - Proper event sequences (keydown, keypress, input, keyup)
        // - Occasional longer pauses
        // - Random timing variations
    }
}
```

**Features**:
- **Human-like Timing**: Variable delays between keystrokes
- **Complete Events**: Full keyboard event simulation for compatibility
- **Natural Variations**: Occasional pauses and timing irregularities
- **Bot Detection Avoidance**: Realistic patterns to bypass automated detection

#### 3. **Sessionless Integration** (Safari Only)
```javascript
window.Sessionless = {
    generateKeys(seedPhrase): Promise<{publicKey, address}>,
    sign(message): Promise<{signature}>,
    authenticate(challenge): Promise<AuthResult>,
    hasKeys(): Promise<{hasKeys: boolean}>,
    // ... full cryptographic API
}
```

**Features**:
- **Native Cryptography**: All operations happen in secure native app
- **Keychain Storage**: Private keys never enter browser environment
- **secp256k1 Support**: Industry-standard elliptic curve cryptography
- **XPC Communication**: Secure inter-process communication

#### 4. **Home Base Management** (Safari Only - January 2025)
```javascript
// Complete popup interface for Planet Nine base selection
// Popup HTML with three-tab design: Home Base, Keys, Privacy
// Base discovery via multiple sources with intelligent caching
```

**Features**:
- **Three-Tab Popup**: Home Base selection, Keys management, Privacy settings
- **Three-Environment Support**: DEV (dev.allyabase.com), TEST (127.0.0.1:5114-5118), LOCAL (localhost)
- **Enhanced Base Discovery**: Multiple discovery methods with graceful fallbacks
- **Protocol Intelligence**: Automatic HTTP/HTTPS selection based on address (HTTP for 127.0.0.1/localhost)
- **Persistent Selection**: Home base choice saved in localStorage across sessions
- **Real-time Status**: Live connection status and base health monitoring
- **Bridge Communication**: Popup ↔ content script with robust error handling and fallbacks
- **Spellbook Integration**: Fallback spellbook functionality when bridge methods unavailable

#### 5. **Payment Processing System** (Safari Only - January 2025)
```javascript
window.AdvancementStripeIntegration = {
    async processPayment(purchaseIntent, sessionlessSignature): Promise<PaymentResult>,
    isAvailable(): boolean,
    getCapabilities(): PaymentCapabilities
}
```

**Complete Payment Flow**:
- **Multi-PubKey Verification**: Site owner, product creator, and base public keys validated
- **Stripe Integration**: Secure payment processing through The Advancement extension
- **Payment Splits**: Automatic 70% creator, 20% base, 10% site distribution
- **Addie Coordination**: Payment processing coordinated with user's selected home base
- **Event-Based Communication**: Website ↔ extension communication via custom events
- **Fallback Processing**: Graceful degradation when services unavailable

### Privacy Email System

The Advancement provides rotating privacy-focused email addresses:

```javascript
window.AdvancementExtension = {
    emails: [
        'letstest@planetnineapp.com',
        'privacy@planetnineapp.com', 
        'advancement@planetnineapp.com'
    ],
    
    getRandomEmail(): string  // Returns random privacy email
}
```

**Auto-fill Behavior**:
- **Click Detection**: Automatically fills email fields when clicked
- **Natural Typing**: Uses TypingSimulator for realistic input
- **Privacy Rotation**: Different emails for different sites
- **No Tracking**: Extension doesn't store which email was used where

## Ad Covering System (The Ficus Feature) ✅ (September 2025)

### Philosophy: Cover, Don't Block

Unlike traditional ad blockers, The Advancement **covers** ads instead of blocking them. **FULLY IMPLEMENTED** in Safari extension with dual-mode experience:

#### **AdversementSystem Class** ✅
```javascript
class AdversementSystem {
    constructor() {
        this.adStrings = ['ads_', 'ad-', 'ads-', 'googlesyndication', 'pagead2', 'fixed-ad'];
        this.coveredAds = new Set();
        this.isMonsterMode = false;
    }
    
    // Real-time ad detection using MutationObserver
    // Covers ads with ficus plants or slimes based on mode
    // Event-driven communication with entertainment system
}
```

#### **Entertainment System Integration** ✅
```javascript
class EntertainmentSystem {
    // NES-inspired gaming overlay with SVG coordinate system
    // Entity Component System for damage node physics
    // Custom event bridge for content script communication
    
    attackSlime(x, y) {
        const damage = Math.floor(Math.random() * 41) + 30; // 30-70 damage
        this.createDamageNode(damage, x, y); // Flying damage numbers
    }
}
```

**Implementation Features**:
- **Dual Mode Experience**: Peaceful ficus plants OR interactive slime monsters
- **Real-time Ad Detection**: MutationObserver scans for dynamic ads using keyword matching
- **Click-to-Attack**: Monster mode allows users to "attack" ad slimes with damage numbers
- **Physics-Based Animation**: ECS system with gravity, velocity, and lifetime components
- **Visual Polish**: Large, bold damage numbers with text shadows and smooth animations
- **Event-Driven Architecture**: Custom events bridge content script isolation
- **Performance Optimized**: Efficient DOM scanning and element management
- **FFVI Font Integration**: Custom Final Fantasy VI-style damage font successfully loaded with Safari-compatible path resolution

**Ad Detection Strings**:
- `ads_`, `ad-`, `ads-`, `googlesyndication`, `pagead2`, `fixed-ad`
- Scans element IDs, class names, and attributes
- Covers ads ≥50x50 pixels with overlays

**Benefits**:
- **Creator Support**: Ad impressions still count, creators get paid
- **User Experience**: Choice between peaceful plants or interactive gaming
- **Manifest v3 Compliant**: Works within Chrome extension limitations
- **Gaming Experience**: NES-inspired overlay with physics-based damage system

**Implementation Status**:
- ✅ **Safari**: Complete implementation with entertainment system
- 🚧 **Chrome**: Architecture ready for implementation

## Development Patterns

### No-Modules Architecture (Tauri Compatibility)

Both Chrome and Safari extensions use vanilla JavaScript without ES6 modules:

```javascript
// Global extension object available to web pages
window.AdvancementExtension = {
    detector: new InputDetector(),
    simulator: new TypingSimulator(),
    version: '1.0.0'
};

// No ES6 imports/exports - direct script inclusion
```

**Reasoning**:
- **Browser Compatibility**: Works across all extension environments
- **Tauri Integration**: Compatible with Nullary app architecture
- **Security**: Minimal dependencies reduce attack surface
- **Performance**: Direct script execution without module resolution

### Dynamic Content Monitoring

Both extensions use hysteresis-based DOM monitoring:

```javascript
let hysteresis = false;
const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
        if (!hysteresis && mutation.addedNodes.length) {
            hysteresis = true;
            setTimeout(() => {
                hysteresis = false;
                detector.detectFields();
            }, 1500);
        }
    }
});
```

**Benefits**:
- **Performance**: Prevents excessive DOM scanning
- **Compatibility**: Works with single-page applications
- **Responsiveness**: Detects dynamically loaded content
- **Efficiency**: Batches detection operations

## Test Environment (January 2025)

### Complete Purchase Flow Testing

The Advancement includes a comprehensive test server demonstrating the complete Planet Nine purchase flow:

**Location**: `test-server/`
**Purpose**: Test teleported product feeds, multi-pubKey verification, Stripe integration, Addie coordination, and MAGIC protocol spell casting

#### Test Server Features
- **Express.js API**: Complete backend with teleportation and payment endpoints
- **Mock Planet Nine Services**: Simulated Sanora, BDO, and Addie integration
- **Multi-PubKey System**: Site owner, product creator, and base public key verification
- **Stripe Integration**: Real payment processing through The Advancement extension
- **Payment Splits**: Automatic 70% creator, 20% base, 10% site distribution
- **Home Base Coordination**: Payments routed through user's selected Planet Nine base
- **MAGIC Protocol Gateway**: Full magic-gateway-js integration with spellTest support
- **Spell Casting**: End-to-end spell casting from extension to test server via MAGIC protocol
- **Author-Book Carousel**: Complete demonstration of Planet Nine ecosystem integration with PostWidget

#### Quick Start Testing
```bash
# Start test environment
cd the-advancement/test-server
npm install && npm start

# Open in Safari with The Advancement extension
open http://localhost:3456

# Configure home base in The Advancement popup
# Test complete purchase flow with teleported products
```

#### Test Data
- **3 Test Products**: Ebooks, courses, and physical products
- **Multiple Creators**: Alice Creator, Bob Developer with unique pubKeys
- **Multiple Bases**: DEV and LOCAL test bases
- **Payment Methods**: Stripe test cards with full payment processing
- **MAGIC Spells**: spellTest spell with proper MAGIC protocol structure and dual destinations

### Author-Book Carousel Implementation (September 2025)

The test server includes a complete author-book carousel demonstration showcasing Planet Nine ecosystem integration with prof, sanora, BDO, and dolores services.

#### Features
- **Author Profiles**: 3 mock authors (Sarah Mitchell, Marcus Chen, Isabella Rodriguez) with bios, locations, and genres
- **Book Catalog**: 6 ebooks (2 per author) with descriptions, prices, and visual covers
- **PostWidget Integration**: Uses dolores post-widget.js for consistent Planet Nine styling
- **Two Implementations**: Custom carousel and PostWidget-integrated versions for comparison
- **Responsive Design**: Mobile-friendly with horizontal scrolling book carousels

#### Technical Architecture
```
test-server/public/
├── authors.html + authors.js          # Custom implementation
├── authors-widget.html + authors-widget.js  # PostWidget integration
├── post-widget.js                     # From dolores (19KB)
└── seed-authors-and-books.js         # Seeding script for real services
```

#### PostWidget Integration Pattern
```javascript
// Individual PostWidget instances for each author/book
const postWidget = new window.PostWidget(postContainer, { debug: false });

// Author customization
postWidget.addElement('name', author.name);
postWidget.addElement('description', author.bio);
// + location 📍 and genres 🏷️ metadata

// Book customization  
postWidget.addElement('name', book.title);
postWidget.addElement('description', book.description);
// + visual covers with gradients, price 💰, genre 📚
```

#### Access Points
- **Custom Carousel**: `http://localhost:3456/authors.html`
- **PostWidget Version**: `http://localhost:3456/authors-widget.html`
- **Main Test Site**: `http://localhost:3456/`

#### Planet Nine Services Integration
- **prof**: Author profiles with sessionless authentication
- **sanora**: Ebook product hosting and marketplace
- **BDO**: Associations mapping authors to their books  
- **dolores**: PostWidget for consistent UI components

This demonstrates the complete Planet Nine pattern: content creators (authors) → products (books) → associations (BDO) → presentation (PostWidget) → commerce (future purchasing integration).

### MAGIC Protocol Integration (August 2025)

The Advancement now includes complete MAGIC protocol support for spell casting:

#### **spellTest Implementation** ✅
- **Full MAGIC Protocol**: Complete implementation following MAGIC protocol specification
- **Test Server Gateway**: magic-gateway-js integration with dual-destination routing
- **Extension Integration**: Content script handles spellTest detection and casting
- **Background Spellbook Manager**: Centralized spellbook management with Swift integration
- **End-to-End Flow**: Spell detection → background management → Swift signing → gateway processing

#### **Enhanced Architecture (Latest Update)**
- **Centralized Spellbook Management**: Background script manages all spellbook operations
- **Swift Integration**: All BDO requests go through Swift for proper authentication
- **Shared Cache**: Popup and content script share same spellbook cache (5-minute timeout)
- **Message Types**: `castSpell` for content script, `getSpellbook` for popup requests
- **Automatic Refresh**: Background refreshes spellbook when spells not found

#### **MAGIC Protocol Components**
- **Spell Detection**: Content script detects `[spell="spellTest"]` elements on web pages
- **Background Processing**: Background script handles spellbook lookup and MAGIC payload creation
- **Cryptographic Signing**: Swift handles secp256k1 signature via native messaging
- **Gateway Forwarding**: Test server acts as MAGIC gateway, forwards to fount resolver
- **Response Handling**: Extension displays server response with success/error states

#### **Updated Technical Flow**
1. **User Interaction**: Clicks element with `spell="spellTest"` attribute
2. **Content Script**: Sends `{ type: 'castSpell', spellName: 'spellTest' }` to background
3. **Background Script**: 
   - Checks cached spellbook or fetches via Swift from BDO
   - Finds spell, creates MAGIC payload with proper structure
   - Sends `{ action: 'castSpell' }` to Swift for signature and posting
4. **Swift Processing**: Signs payload, posts to `http://localhost:3456/magic/spell/spellTest`
5. **Test Server Gateway**: Processes spell, adds gateway entry, attempts fount forwarding
6. **Response Display**: Background forwards response to content script for user display

#### **Popup Integration**
- **Unified Management**: Popup now uses same background spellbook manager
- **Message Type**: Sends `{ type: 'getSpellbook' }` instead of direct Swift calls
- **Shared Cache**: Benefits from same 5-minute spellbook cache as content script
- **Proper Display**: Handles nested Swift response structure for spellbook rendering

#### **Test Server MAGIC Setup**
```javascript
// MAGIC protocol dependencies
const gateway = require('magic-gateway-js').default;
const sessionless = require('sessionless-node');
const fount = require('fount-js').default;

// Spellbook with dual destinations (required for gateway)
const spellbook = {
    spellTest: {
        cost: 400,
        destinations: [
            { stopName: 'test-server', stopURL: 'http://127.0.0.1:3456/' },
            { stopName: 'fount', stopURL: 'http://127.0.0.1:5116/magic/spell/' }
        ],
        resolver: 'fount',
        mp: true
    }
};

// Gateway endpoint: POST /magic/spell/spellTest
gateway.expressApp(app, fountUser, spellbook, 'test-server', sessionless, extraConfig, onSuccess);
```

## File Structure

```
the-advancement/
├── README.md                    # Main project overview
├── CLAUDE.md                   # This documentation
├── you-are-not-a-number.md     # Privacy philosophy
├── README-DEV.md               # Developer documentation
├── README-UX.md                # UX guidelines
├── README-NT.md                # Non-technical overview
├── resources/
│   └── ficus.jpg               # The famous ficus plant image
├── test-server/                # Complete test environment (NEW)
│   ├── README.md               # Test server documentation
│   ├── package.json            # Node.js dependencies
│   ├── server.js               # Express.js test server
│   └── public/
│       ├── index.html          # Test website
│       ├── styles.css          # Planet Nine styling
│       ├── main.js             # Application coordinator
│       ├── teleportation-client.js  # Product discovery
│       └── purchase-flow.js    # Payment processing
└── src/
    └── extensions/
        ├── chrome/
        │   ├── manifest.json           # Chrome extension manifest
        │   ├── content/
        │   │   ├── index.js           # Main extension logic
        │   │   ├── scripts/
        │   │   │   ├── InputDetector.js    # Input field detection
        │   │   │   └── TypingSimulator.js  # Natural typing simulation
        │   │   ├── styles.css         # Extension styling
        │   │   └── hello_world.html   # Extension popup
        │   └── assets/
        │       └── icons/
        │           └── hi_icon.png    # Extension icon
        └── safari/
            ├── README.md              # Safari-specific documentation
            ├── Info.plist            # Safari extension manifest (updated)
            ├── SessionlessApp.swift  # Native macOS app
            ├── advancement-content.js # Enhanced content script (updated)
            ├── popup.html             # Three-tab popup interface (NEW)
            ├── popup.css              # Planet Nine popup styling (NEW)
            ├── popup.js               # Base discovery and management (NEW)
            ├── popup-content-bridge.js # Popup ↔ content communication (NEW)
            ├── stripe-integration.js # Payment processing system (NEW)
            ├── sessionless-content.js # Legacy sessionless script
            ├── InputDetector.js      # Standalone input detector
            ├── TypingSimulator.js    # Standalone typing simulator
            ├── adversement.js        # Ad covering system (NEW - September 2025)
            ├── entertainment-system.js # Gaming overlay system (NEW - September 2025)
            └── ecs.js                # Entity Component System (NEW - September 2025)
```

## Key Dependencies

### Chrome Extension
- **Vanilla JavaScript**: No external dependencies
- **Chrome Extension API**: Manifest v1 (needs v3 update)
- **Content Script Injection**: Direct DOM access and manipulation

### Safari Extension
- **Swift**: Native macOS app with XPC services
- **secp256k1.swift**: Cryptographic library for key operations
- **Safari Extension API**: Native Safari extension framework
- **macOS Keychain**: Secure key storage

## User Experience

### Automatic Features
1. **Page Load**: Extension automatically scans for input fields
2. **Field Detection**: Visual indicators appear next to sensitive fields
3. **Click Auto-fill**: Clicking email fields triggers natural typing
4. **Dynamic Content**: New fields detected as pages change
5. **Ad Covering**: Ads get covered with peaceful plant images (planned)

### Manual Controls
```javascript
// Available in browser console on any page

// Chrome Extension
detector.detectFields();  // Manual field scan

// Safari Extension  
AdvancementExtension.scanPage();  // Manual field scan
AdvancementExtension.getRandomEmail();  // Get privacy email
Sessionless.generateKeys();  // Create cryptographic identity
```

### Visual Feedback
- **Privacy Icons**: 🎭 Gradient circular icons next to detected fields
- **Ficus Plants**: 🌿 Peaceful plant images covering ads with click-to-dismiss
- **Slime Monsters**: 👹 Interactive slime overlays in monster mode
- **Damage Numbers**: Large, bold flying damage text (30-70 damage) with physics
- **Click Feedback**: Visual confirmation of auto-fill actions
- **Gaming Console**: NES-inspired purple border overlay with ESC toggle

## Security Considerations

### Privacy Protection
- **No Data Collection**: Extensions don't collect or transmit user data
- **Local Operation**: All functionality happens locally
- **No Remote Servers**: No communication with external services
- **Sandboxed Execution**: Browser security model isolation

### Chrome Extension Security
- **Content Script Isolation**: Limited access to page context
- **No Eval**: No dynamic code execution
- **CSP Compliant**: Works with strict Content Security Policies
- **Manifest v3 Ready**: Architecture supports upcoming requirements

### Safari Extension Security
- **Native Cryptography**: All crypto operations in secure native code
- **Keychain Storage**: Private keys stored in macOS Keychain
- **XPC Communication**: Secure inter-process communication
- **Hardware Security**: Benefits from Apple's security framework

## Future Enhancements

### Immediate Roadmap
- **Ficus Implementation**: Complete the ad covering system
- **Manifest v3**: Update Chrome extension for new requirements
- **Firefox Support**: Add Firefox extension with same functionality
- **MAGIC Integration**: One-click shopping and web interactions

### Advanced Features
- **Teleportation Support**: Content discovery network integration
- **Multi-Identity**: Multiple cryptographic identities per user
- **Custom Privacy Emails**: User-configurable email addresses
- **Enhanced Gaming**: More interactive ad destruction experiences

### Cross-Platform Goals
- **Browser Parity**: Identical functionality across all browsers
- **Native Apps**: Secure cryptographic backends for each platform
- **Unified API**: Consistent JavaScript API regardless of browser
- **Mobile Support**: iOS and Android extension capabilities

## Integration with Planet Nine Ecosystem

### Sessionless Protocol ✅
- **Key Management**: Secure cryptographic identity storage in macOS Keychain
- **Authentication**: Passwordless login across Planet Nine services
- **Signing Operations**: Message and transaction signing capabilities
- **Purchase Verification**: Cryptographic signatures for all transactions

### Home Base Selection ✅ (January 2025)
- **Base Discovery**: Multiple discovery methods with intelligent fallbacks
- **User Choice**: Persistent home base selection across browser sessions
- **Service Integration**: Automatic coordination with user's selected base
- **Health Monitoring**: Real-time connection status and base availability

### Payment Processing ✅ (January 2025)
- **Multi-Party Transactions**: Site owner, creator, and base payment splits
- **Stripe Integration**: Secure payment processing through extension
- **Addie Coordination**: Payment processing via user's home base
- **Teleported Commerce**: Purchase products from any Planet Nine base

### MAGIC Protocol (Planned)
- **One-Click Actions**: Shopping, voting, liking without accounts
- **Micropayments**: Small payments for content and services
- **Cross-Site Integration**: Seamless interactions across websites

### Teleportation Network ✅ (Implemented in Test Environment)
- **Content Discovery**: Discover products from Planet Nine bases
- **Cryptographic Verification**: All teleported content signed and verified
- **Cross-Base Shopping**: Purchase from any base regardless of your home base
- **Privacy-Preserving**: Shop without revealing browsing history

## Testing and Development

### Local Development
```bash
# Chrome Extension
cd src/extensions/chrome
# Load unpacked extension in Chrome developer mode

# Safari Extension  
cd src/extensions/safari
swift build -c release
# Install in Safari preferences

# Test Environment (NEW)
cd test-server
npm install && npm start
# Complete Planet Nine purchase flow testing
```

### Testing Scenarios

#### Core Extension Features
- **Input Detection**: Test on forms with various field types
- **Typing Simulation**: Verify natural timing and event sequences
- **Dynamic Content**: Test on single-page applications
- **Cross-Domain**: Verify functionality across different websites
- **Performance**: Monitor memory usage and DOM scanning efficiency

#### Planet Nine Integration Testing (NEW)
- **Home Base Selection**: Test base discovery and persistent selection
- **Payment Processing**: Complete purchase flow with Stripe integration
- **Multi-PubKey Verification**: Site owner, creator, and base key validation
- **Teleported Commerce**: Product discovery from Planet Nine bases
- **Addie Coordination**: Payment routing through user's home base
- **Error Handling**: Graceful degradation when services unavailable

#### Test Environment Scenarios
```bash
# Test complete purchase flow
cd test-server && npm start
open http://localhost:3456

# Test cases:
# 1. Configure home base in The Advancement popup
# 2. Verify teleported product feed loads
# 3. Complete purchase with Stripe test card
# 4. Verify payment splits (70% creator, 20% base, 10% site)
# 5. Test error handling with services offline
```

### Browser Compatibility
- ✅ **Chrome**: Full input detection and typing functionality
- ✅ **Safari**: Complete Planet Nine integration (sessionless auth + home base + payments)
- 🚧 **Firefox**: Planned with same feature set
- 🚧 **Edge**: Planned using Chrome extension base

### Latest Updates (January 2025)

#### ✅ **Complete Payment Flow Integration (January 2025)**
- **Addie Integration**: Full integration with real Addie payment service for payment intent creation
- **Message-Passing Architecture**: Clean separation between extension and web page via custom DOM events
- **Stripe Elements**: Proper Stripe Elements implementation following Sanora pattern with real publishableKey from Addie
- **Safari Web Extension Messaging**: Consolidated message handlers in background.js for reliable communication
- **Payment Element Lifecycle**: Proper ready state management and element mounting for credit card forms
- **Real Cryptography**: All payment intents created with sessionless signatures through Swift native messaging
- **No Mock Data**: Complete removal of simulation/mock data in favor of real Addie service integration

#### 🔧 **Technical Implementation Details**
- **Content Script**: Handles purchase spells and sends payment requests to extension via `browser.runtime.sendMessage`
- **Background Script**: Routes payment requests to Swift, consolidates message handlers to prevent conflicts
- **Swift Integration**: Complete Addie user creation and signed payment intent requests via native messaging
- **Web Page Integration**: Event-driven payment processing with proper Stripe Elements lifecycle management
- **Error Handling**: Comprehensive error handling throughout the entire payment flow with user-friendly messaging

#### ✅ **Enhanced Safari Extension (January 22, 2025)**
- **Real Cryptography**: Implemented proper secp256k1 with compressed keys (02/03 prefix)
- **Three-Environment Support**: Complete DEV, TEST, and LOCAL base discovery and management
- **Protocol Intelligence**: Automatic HTTP for local addresses (127.0.0.1, localhost), HTTPS for remote
- **Robust Bridge Communication**: Enhanced popup-content bridge with comprehensive error handling
- **Graceful Degradation**: Fallback functionality when native bridge methods unavailable
- **Spellbook Fallbacks**: Working spellbook display even when full bridge implementation pending
- **TEST Environment Integration**: Full support for 3-base Docker ecosystem (ports 5114-5118)

#### 🔧 **Technical Improvements**
- **EnhancedBaseDiscoveryService**: Intelligent base discovery with multiple fallback strategies
- **EnhancedExtensionStorage**: Dual storage (bridge + localStorage) with automatic failover
- **Bridge Method Resilience**: All bridge methods return null instead of throwing on failure
- **Status Check Improvements**: Direct HTTP health checks with proper protocol selection
- **Error Recovery**: Comprehensive error handling throughout the popup interface

### Current Status (January 2025)
- ✅ **Safari Extension**: Production-ready with complete Planet Nine ecosystem integration
- ✅ **Home Base Management**: Full base discovery, selection, and persistent storage across three environments
- ✅ **Payment Processing**: Complete Stripe integration with multi-party payment splits
- ✅ **Test Environment**: Comprehensive testing infrastructure for development
- ✅ **Teleported Commerce**: Cross-base product discovery and purchasing
- ✅ **Robust Architecture**: Enhanced error handling and graceful degradation patterns

### Latest Safari Web Extension Fixes & MAGIC Protocol (August 2025)

#### ✅ **Safari Web Extension Messaging Resolution**
- **Complex Object Serialization**: Fixed Safari Web Extensions returning `true` instead of proper response objects
- **Background Response Structure**: Implemented consistent `{ success: true/false, data: {...}, error: "..." }` format
- **Native Message Handling**: Proper Swift response processing with validation and error handling
- **Promise-Based Architecture**: Converted from callback-based to Promise-based message handling for Safari Web Extensions

#### ✅ **Complete Clear Data Implementation**
- **Swift Integration**: Added `clearBdoUser` and `clearFountUser` handlers in SafariWebExtensionHandler.swift
- **Popup Functionality**: Removed blocking confirm dialogs that prevented execution in Safari popup context
- **Method Call Resolution**: Fixed popup clear functions to use proper `this.bdoClient.bridge.sendToSwift()` path
- **UserDefaults Management**: Complete Swift-side storage clearing for both BDO and fount users
- **Comprehensive Clear All**: Single action clears both browser storage and Swift UserDefaults

#### ✅ **Spell Casting Messaging Restored**
- **Browser Runtime API**: Restored `browser.runtime.sendMessage` for spell casting with Safari Legacy fallback
- **Content Script Fix**: Removed Chrome detection blocking that prevented Safari execution
- **Message Flow**: Complete content script ↔ background ↔ Swift messaging chain functional
- **Error Propagation**: Proper error handling and success responses throughout entire spell casting pipeline

#### ✅ **Complete MAGIC Protocol Implementation (August 2025)**
- **Full spellTest Flow**: End-to-end spell casting from browser element detection to server response
- **Background Spellbook Manager**: Centralized spellbook management with 5-minute caching in background script
- **Swift Cryptographic Integration**: All BDO operations and spell signing handled by Swift native messaging
- **Test Server Gateway**: Complete magic-gateway-js integration with dual-destination spell routing
- **Real Nineum Balance**: Test server displays actual nineum balance from fount user with 30-second auto-refresh
- **Global Fount User Management**: Single fount user instance managed globally in test server to prevent scope issues
- **Promise-Based Architecture**: Complete conversion to Promise-based messaging for Safari Web Extension compatibility

#### ✅ **Background Script Messaging Consolidation (January 2025)**
- **Unified Message Handlers**: Consolidated duplicate `handleGetBDOCard` and `handleCastSpell` functions that were causing parameter mismatches
- **Promise-Based Returns**: All message handlers now return Promises directly instead of callback-based `sendResponse` patterns
- **Function Signature Consistency**: Fixed external message handler to properly pass `sender` parameter to unified functions
- **BDO Card Retrieval Fix**: Resolved "getBDOCard requires bdoPubKey parameter" error through proper parameter extraction from message objects
- **Code Consolidation**: Removed duplicate functions causing confusion between internal/external message handling patterns
- **Safari Compatibility**: Complete Safari Web Extension API compliance with consistent Promise-based messaging architecture

## Contributing

The Advancement is part of the larger Planet Nine ecosystem. Areas for contribution:

- **Ad Detection**: Improve algorithms for identifying ad elements
- **Ficus Implementation**: Complete the peaceful ad covering system
- **Browser Support**: Add Firefox and Edge extensions
- **Gaming Features**: Design interactive ad destruction experiences
- **Performance**: Optimize DOM scanning and field detection
- **Security Audits**: Review cryptographic implementations
- **User Experience**: Better visual design and interaction patterns

## License

The Advancement browser extensions are open source and follow the same license as the broader Planet Nine project. The focus is on providing privacy-focused web browsing tools that empower users while supporting content creators.

---

**The Advancement** represents a new approach to web privacy - not through blocking and breaking the web, but through intelligent covering and cryptographic empowerment. As of January 2025, it serves as the production-ready consumer-facing gateway to the Planet Nine ecosystem, providing users with seamless access to decentralized commerce, secure authentication, and privacy-preserving web interactions. 

With complete home base management, multi-party payment processing, and teleported commerce capabilities, The Advancement demonstrates the future of user-controlled, privacy-first web experiences.