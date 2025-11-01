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

### ✅ **Stripe Payout Cards for Sellers** (November 2025)
- **Receive Payments Tab**: Dedicated UI in iOS/Android apps for instant payout setup
- **Direct Debit Card Payouts**: Save debit cards to receive affiliate commissions
- **Instant Setup**: No KYC onboarding required - select card and start receiving payouts
- **Works with Issued Cards**: Planet Nine virtual cards can receive payouts
- **Two-State UI**: Not Setup (select card) → Setup (instant payouts active)
- **Affiliate Commission Support**: Enable 10% affiliate payouts from product sales
- **Instant Transfer Processing**: Automatic fund distribution to payout cards (~30 minutes)
- **SharedPreferences Storage**: Payout card IDs persisted across app sessions (Android)
- **UserDefaults Storage**: Payout card IDs persisted via standard storage (iOS)

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
- **CarrierBag Architecture**: Persistent user-owned BDO containing 15 collections
- **Save Spell Integration**: Universal save spell with automatic collection routing
- **Collection Mapping**: Automatic type-to-collection inference (recipe→cookbook, music→music, room→stacks, event→events, popup→events, book→bookshelf, contract→contracts)
- **Multi-Collection Support**: cookbook, apothecary, gallery, bookshelf, familiarPen, machinery, metallics, music, oracular, greenHouse, closet, games, events, contracts, stacks
- **HTML-Based UI**: Beautiful gradient interface with grid layout and shimmer animations
- **Glowy BAG Button**: Pink pulsing button in iOS app for easy carrierBag access
- **WebView Architecture**: WKWebView-based CarrierBagViewController with JavaScript bridge
- **Item Management**: View, copy, and remove saved items from any collection
- **Test Infrastructure**: Headless carrierBag test suite for validating save spell functionality

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

### ✅ **AdvanceKey Enhanced Display** (October 2025)
- **Matterport Integration**: Embedded 3D tour iframes below BDO SVG display
- **Vertical Scrolling**: Flexible layout with SVG (100px) + iframe (200px) allowing vertical scroll
- **Clean Interface**: Removed debug status labels to maximize display space
- **Optimized Layout**: WebView gains 30px additional vertical space (from 40px to 10px top margin)
- **BDO Visualization**: Dual-pane view showing both BDO card and 3D property tour
- **Room Listings**: Perfect for viewing roomz/stacks with interactive 3D tours

### ✅ **NFC Coordinating Keys Integration** (October 2025)
- **NFC Reading**: Read NFC tags containing pubKey + signature tuples using CoreNFC
- **NFC Writing**: Write coordinating keys to NFC tags for physical key distribution
- **Julia Verification**: Automated verification flow through Julia service
- **BDO Integration**: Fetch and verify signatures against BDO-stored messages
- **Coordinating vs Interacting**: Automatic key type detection based on BDO `coordinating` flag
- **Key Rotation**: Automatic key rotation and new BDO creation when `rotate: true` in BDO
- **Native iOS UI**: Full NFCViewController with read/write/verify flows
- **Tag Data Format**: JSON-encoded `{pubKey, signature}` stored in NDEF format

### ✅ **MP Ticket Purchases via MAGIC Protocol** (January 2025)
- **Single Spell Execution**: `arethaUserPurchase` spell handles MP validation, deduction, and nineum transfer atomically
- **Fount UUID Management**: Shared UserDefaults properly stores Fount UUID in App Group for AdvanceKey access
- **MAGIC Spell Integration**: AdvanceKey casts spells through Fount's `/resolve` endpoint
- **Automatic Experience**: 1:1 MP-to-experience granting handled by MAGIC resolver
- **Gateway Rewards**: Automatic 10% gateway reward distribution
- **Error Handling**: Insufficient MP or transfer failures handled gracefully by resolver
- **Complete Flow**: Validate MP → Transfer nineum → Create ticket BDO → Save to carrierBag

### ✅ **Android AdvanceKey Keyboard Extension** (October 2025)
- **WebView-Based Architecture**: Custom IME using WebView instead of Jetpack Compose to avoid lifecycle issues
- **4-Mode Interface**: ABC (standard keyboard), DEMOJI (emojicode decoding), MAGIC (spell casting), BDO (viewing posted BDOs)
- **JavaScript Bridge**: KeyboardJSInterface provides native Android methods to JavaScript
- **Text Input Integration**: Direct integration with InputMethodService for text insertion/deletion
- **BDO Display**: View and insert emojicodes from posted BDOs directly from keyboard
- **Spell Casting**: Cast MAGIC spells (arethaUserPurchase, teleport, grant) through keyboard
- **SharedPreferences Sync**: Posted BDOs shared between main app and keyboard extension
- **Hardware Acceleration**: WebView rendering optimized for keyboard performance
- **Implementation Files**:
  - `keyboard.html` - 4-mode UI with Planet Nine color scheme
  - `keyboard.js` - Mode switching and BDO display logic
  - `AdvanceKeyService.kt` - InputMethodService with WebView integration
  - `KeyboardJSInterface.kt` - JavaScript-to-Android bridge

### ✅ **Federated Wiki Auto-Deployment** (October 2025)
- **Single-Command Deployment**: Deploy production-ready federated wiki instances to Digital Ocean
- **SSL Automation**: Automatic Let's Encrypt certificate acquisition and auto-renewal
- **DNS Configuration**: Automatic A record creation for custom domains
- **Custom Theming**: Dark purple theme with glowing green text
- **Welcome Page**: Pre-configured landing page explaining allyabase and federation
- **Production Security**: UFW firewall, SSH keys, HTTPS-only access
- **Sessionless Authentication**: wiki-security-sessionless with automatic configuration and cookie secret generation
- **Allyabase Integration**: Pre-installed wiki-plugin-allyabase for launching Planet Nine bases
- **Cryptographic Owner Config**: Interactive configuration with Sessionless key generation
- **Port Separation**: Wiki on port 4000 (allyabase uses 3000) to avoid conflicts
- **Project Management**: Automatic droplet assignment to Digital Ocean projects

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
    ├── servers/                # Federated wiki deployment
    │   ├── CLAUDE.md           # Deployment system documentation
    │   ├── deploy-do.js        # Digital Ocean deployment orchestration
    │   ├── configure-owner.js  # Interactive owner configuration
    │   ├── setup-wiki.sh       # Server-side setup script
    │   ├── custom-style.css    # Dark purple theme
    │   ├── welcome-visitors.json # Landing page
    │   ├── do-token.json       # API token (gitignored)
    │   ├── owner.json          # Owner config (gitignored)
    │   └── package.json        # Dependencies
    ├── extensions/
    │   ├── chrome/             # Chrome extension
    │   ├── safari/             # Safari extension + native app
    │   └── The Advancement/AdvanceKey/  # iOS keyboard extension
    └── android/                # Android app
        └── app/src/main/
            ├── assets/         # WebView HTML/JS
            │   ├── main.html   # Main app WebView
            │   ├── main.js     # Main app JavaScript
            │   ├── keyboard.html # AdvanceKey keyboard UI
            │   └── keyboard.js # AdvanceKey keyboard logic
            └── java/app/planetnine/theadvancement/
                ├── crypto/     # Sessionless authentication
                ├── ime/        # AdvanceKey IME service
                └── ui/         # Main app UI
```

## Current Status (October 2025)

### ✅ Production Ready Features
- **Safari Extension**: Complete Planet Nine ecosystem integration
- **Payment Processing**: Multi-party Stripe integration with real cryptography
- **Home Base Management**: Three-environment base discovery and selection
- **Ad Covering System**: Dual-mode experience (plants/monsters) with entertainment
- **Emojicoding**: Perfect UUID ↔ emoji conversion with iOS integration
- **MAGIC Protocol**: Complete spell casting with background management
- **Contract System**: Full contract saving and signing via AdvanceKey with Covenant integration
- **AdvanceKey Enhanced Display**: BDO visualization with embedded 3D tour iframes
- **Test Environment**: Comprehensive testing infrastructure
- **Android App**: Native Android app with WebView-based main screen and AdvanceKey IME keyboard
- **Federated Wiki Auto-Deployment**: Single-command production wiki deployment with SSL, DNS, sessionless auth, and custom theming

### 🚧 In Development
- **Chrome Extension**: Manifest v3 update and feature parity with Safari
- **Firefox Support**: Cross-browser compatibility expansion
- **Android Feature Parity**: DEMOJI decoding, MAGIC spell casting, Contract system integration

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

## Android AdvanceKey Keyboard System

### Overview

The Android AdvanceKey keyboard is a custom Input Method Editor (IME) that provides the same functionality as the iOS keyboard extension, enabling users to view posted BDOs, decode emojicodes, and cast MAGIC spells directly from any text input field.

### Architecture

Unlike typical Android keyboards that use Jetpack Compose, AdvanceKey uses a WebView-based architecture to avoid lifecycle issues inherent in InputMethodService:

```
┌─────────────────────────────┐
│   InputMethodService        │
│   (AdvanceKeyService)       │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   WebView                   │
│   - keyboard.html           │
│   - keyboard.js             │
└──────────┬──────────────────┘
           │
           ▼ JavaScript Bridge
┌─────────────────────────────┐
│   KeyboardJSInterface       │
│   - insertText()            │
│   - deleteText()            │
│   - decodeEmojicode()       │
│   - castSpell()             │
│   - getPostedBDOs()         │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│   AdvanceKeyViewModel       │
│   - Emojicode decoding      │
│   - BDO fetching            │
│   - MAGIC spell casting     │
└─────────────────────────────┘
```

### Keyboard Modes

**1. ABC Mode (Standard Keyboard)**
- QWERTY layout with space, backspace, enter keys
- Direct text insertion through InputMethodService
- Basic typing functionality

**2. DEMOJI Mode (Emojicode Decoding)**
- Monitors clipboard for emojicodes (8 emoji characters)
- Decodes emojicodes by fetching BDO from BDO service
- Displays decoded BDO content

**3. MAGIC Mode (Spell Casting)**
- Available spells: `arethaUserPurchase`, `teleport`, `grant`
- Casts spells through Fount's `/resolve` endpoint
- Uses Sessionless authentication for signing

**4. BDO Mode (Posted BDO Viewing)**
- Displays all BDOs posted from main app
- Clickable emojicode cards for easy insertion
- Auto-refreshes when mode is opened

### Implementation Files

**keyboard.html** (`src/android/app/src/main/assets/keyboard.html`):
```html
<!-- 4 mode buttons: ABC | DEMOJI | MAGIC | BDO -->
<div id="modeButtons">
  <button class="mode-button selected" data-mode="standard">ABC</button>
  <button class="mode-button" data-mode="demoji">DEMOJI</button>
  <button class="mode-button" data-mode="magic">MAGIC</button>
  <button class="mode-button" data-mode="bdo">BDO</button>
</div>

<!-- Dynamic content area -->
<div id="contentArea"></div>
```

**keyboard.js** (`src/android/app/src/main/assets/keyboard.js`):
```javascript
// Mode switching
function switchMode(mode) {
  currentMode = mode;
  renderContent(mode);
}

// Insert text through Android interface
function handleKeyPress(key) {
  if (window.Android && window.Android.insertText) {
    window.Android.insertText(key);
  }
}

// Update BDOs from native code
window.updatePostedBDOs = function(bdosJson) {
  postedBDOs = JSON.parse(bdosJson);
  if (currentMode === 'bdo') {
    renderBDOPanel(document.getElementById('contentArea'));
  }
};
```

**AdvanceKeyService.kt** (`src/android/app/src/main/java/.../ime/AdvanceKeyService.kt`):
```kotlin
class AdvanceKeyService : InputMethodService(), LifecycleOwner {
    override fun onCreateInputView(): View? {
        val webView = android.webkit.WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true

            // Add JavaScript interface
            addJavascriptInterface(
                KeyboardJSInterface(this@AdvanceKeyService, viewModel, this),
                "Android"
            )

            // Load keyboard HTML
            loadUrl("file:///android_asset/keyboard.html")
        }
        return webView
    }
}
```

**KeyboardJSInterface.kt** (`src/android/app/src/main/java/.../ime/AdvanceKeyService.kt`):
```kotlin
class KeyboardJSInterface(
    private val service: AdvanceKeyService,
    private val viewModel: AdvanceKeyViewModel?,
    private val webView: android.webkit.WebView
) {
    @JavascriptInterface
    fun insertText(text: String) {
        service.currentInputConnection?.commitText(text, 1)
    }

    @JavascriptInterface
    fun deleteText() {
        service.currentInputConnection?.deleteSurroundingText(1, 0)
    }

    @JavascriptInterface
    fun getPostedBDOs(): String {
        val bdos = viewModel?.postedBDOs?.value ?: emptyList()
        return Gson().toJson(bdos)
    }
}
```

### Data Sharing Between Main App and Keyboard

**SharedPreferences** is used to share posted BDOs:

**Main App** (`MainViewModel.kt`):
```kotlin
private fun savePostedBDOs(bdos: List<PostedBDO>) {
    val bdosJson = gson.toJson(bdos)
    prefs.edit().putString("posted_bdos", bdosJson).apply()
}
```

**Keyboard Extension** (`AdvanceKeyViewModel.kt`):
```kotlin
private fun loadPostedBDOs() {
    val bdosJson = prefs.getString("posted_bdos", null)
    if (bdosJson != null) {
        val bdos = gson.fromJson(bdosJson, Array<PostedBDO>::class.java).toList()
        _postedBDOs.value = bdos
    }
}
```

### Configuration

**AndroidManifest.xml**:
```xml
<service
    android:name=".ime.AdvanceKeyService"
    android:label="AdvanceKey"
    android:permission="android.permission.BIND_INPUT_METHOD"
    android:exported="true">
    <intent-filter>
        <action android:name="android.view.InputMethod" />
    </intent-filter>
    <meta-data
        android:name="android.view.im"
        android:resource="@xml/method" />
</service>
```

### Usage

1. **Enable Keyboard**:
   - Settings → System → Languages & Input → On-screen keyboard → Manage keyboards
   - Toggle "AdvanceKey" ON

2. **Switch to AdvanceKey**:
   - Tap any text input field
   - Tap the yellow "Switch to AdvanceKey" button in main app
   - Or long-press spacebar and select AdvanceKey

3. **View Posted BDOs**:
   - Tap "BDO" mode button
   - See all posted BDOs with emojicodes
   - Tap emojicode to insert into current text field

### Why WebView Instead of Compose?

**Problem with Compose**: InputMethodService doesn't provide a proper ViewTreeLifecycleOwner, causing crashes:
```
java.lang.IllegalStateException: ViewTreeLifecycleOwner not found from android.widget.LinearLayout
```

**WebView Solution**:
- No lifecycle dependencies
- HTML/CSS provides rich UI capabilities
- JavaScript enables dynamic content updates
- Same architecture as main app (consistency)
- Hardware acceleration for smooth rendering

## Stripe Payout Cards Implementation (November 2025)

### Overview

The Advancement iOS and Android apps provide direct debit card payout functionality enabling users to receive instant affiliate commissions (~30 minutes) without complex KYC onboarding. This replaces the previous Stripe Connected Accounts approach with a simpler, faster payout method that works seamlessly with both external debit cards and Planet Nine issued virtual cards.

**Critical for Affiliate Flow**: Alice → Bob → Carl where Bob (affiliate) and Carl (creator) need to receive payments instantly.

### Architecture

```
┌────────────────────────────────────────────────────────┐
│  The Advancement App (iOS/Android)                     │
│  - Select debit card for payouts                       │
│  - Check payout card status                            │
└───────────────────┬────────────────────────────────────┘
                    │ Sessionless Auth
                    ▼
┌────────────────────────────────────────────────────────┐
│  Addie Backend                                         │
│  POST /payout-card/save                                │
│  GET /payout-card/status                               │
│  POST /payment/:id/process-transfers                   │
└───────────────────┬────────────────────────────────────┘
                    │ Stripe API
                    ▼
┌────────────────────────────────────────────────────────┐
│  Stripe Platform                                       │
│  - Direct Debit Card Transfers                         │
│  - Instant Payouts (~30 minutes)                       │
│  - Works with Stripe Issued Cards                      │
└────────────────────────────────────────────────────────┘
```

### iOS Implementation

**PaymentMethodViewController.swift** (`src/The Advancement/Shared (App)/PaymentMethodViewController.swift`):

**Two Payout Card Methods** (Lines 867-981):
```swift
// Save Payout Card
private func savePayoutCard(params: [String: Any], messageId: Any) {
    guard let paymentMethodId = params["paymentMethodId"] as? String else {
        sendResponse(messageId: messageId, error: "Missing paymentMethodId")
        return
    }

    // Signs request with Sessionless authentication
    // Signature: timestamp + pubKey + paymentMethodId
    // Calls POST /payout-card/save
    // Stores payoutCardId in UserDefaults
    // Returns payoutCardId + last4 + brand + expiry
}

// Get Payout Card Status
private func getPayoutCardStatus(messageId: Any) {
    // Signature: timestamp + pubKey
    // Calls GET /payout-card/status
    // Returns hasPayoutCard + card details if exists
}
```

**Message Handler Integration** (Lines 173-176):
```swift
case "savePayoutCard":
    savePayoutCard(params: params, messageId: messageId)
case "getPayoutCardStatus":
    getPayoutCardStatus(messageId: messageId)
```

**PaymentMethod.html** (`src/The Advancement/Shared (App)/Resources/PaymentMethod.html`):

**Two-State UI** (Lines 436-491):
1. **Payout Card Not Setup**:
   - Shows available debit cards
   - "Use for Payouts" buttons on each card
   - Instructions about instant payouts

2. **Payout Card Setup**:
   - Shows active payout card details
   - Card brand, last4, expiration
   - "Instant payouts enabled" message
   - Refresh button to check status

**JavaScript Functions** (Lines 1027-1161):
```javascript
async function checkPayoutCardStatus() {
    // Calls Swift backend via callSwift()
    // Updates UI: payout-card-not-setup or payout-card-setup
    // Loads available cards if not setup
}

async function selectPayoutCard(paymentMethodId) {
    // Confirms with user
    // Calls savePayoutCard() via Swift
    // Shows success message
    // Refreshes status display
}

async function loadAvailableCards() {
    // Fetches saved payment methods
    // Filters for debit cards only
    // Displays cards with "Use for Payouts" buttons
}
```

### Android Implementation

**PaymentMethodActivity.kt** (`src/android/app/src/main/java/.../ui/payment/PaymentMethodActivity.kt`):

**Two Suspend Functions** (Lines 509-574):
```kotlin
suspend fun savePayoutCard(paramsJson: String): String {
    Log.d(TAG, "💳 Saving payout card...")

    val params = gson.fromJson(paramsJson, Map::class.java)
    val paymentMethodId = params["paymentMethodId"] as? String
        ?: return gson.toJson(mapOf("error" to "Missing paymentMethodId"))

    val keys = sessionless.getKeys()
    val timestamp = System.currentTimeMillis().toString()

    // Signature: timestamp + keys.publicKey + paymentMethodId
    val signature = signMessage(timestamp + keys.publicKey + paymentMethodId)

    val body = mapOf(
        "timestamp" to timestamp,
        "pubKey" to keys.publicKey,
        "signature" to signature,
        "paymentMethodId" to paymentMethodId
    )

    val result = makeAuthenticatedRequest("/payout-card/save", "POST", body)

    // Store payout card ID in SharedPreferences
    if (result["payoutCardId"] != null) {
        val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
        prefs.edit().putString("stripe_payout_card_id", result["payoutCardId"] as String).apply()
    }

    return gson.toJson(result)
}

suspend fun getPayoutCardStatus(): String {
    Log.d(TAG, "🔍 Checking payout card status...")

    val keys = sessionless.getKeys()
    val timestamp = System.currentTimeMillis().toString()

    // Signature: timestamp + keys.publicKey
    val signature = signMessage(timestamp + keys.publicKey)

    val endpoint = "/payout-card/status?timestamp=$timestamp&pubKey=${keys.publicKey}&signature=$signature"
    val result = makeAuthenticatedRequest(endpoint, "GET")

    return gson.toJson(result)
}
```

**JavaScript Interface** (Lines 716-729):
```kotlin
@JavascriptInterface
fun savePayoutCard(paramsJson: String): String {
    var result = ""
    kotlinx.coroutines.runBlocking {
        result = activity.savePayoutCard(paramsJson)
    }
    return result
}

@JavascriptInterface
fun getPayoutCardStatus(paramsJson: String): String {
    var result = ""
    kotlinx.coroutines.runBlocking {
        result = activity.getPayoutCardStatus()
    }
    return result
}
```

**PaymentMethod.html** (`src/android/app/src/main/assets/PaymentMethod.html`):

Same two-state UI and JavaScript functions as iOS, but calls `callAndroid()` instead of `callSwift()`:

```javascript
async function checkPayoutCardStatus() {
    const status = await callAndroid('getPayoutCardStatus');
    // Same UI logic as iOS
}

async function selectPayoutCard(paymentMethodId) {
    const result = await callAndroid('savePayoutCard', { paymentMethodId });
    // Same success handling as iOS
}
```

### Addie Backend Endpoints

**Stripe Processor** (`addie/src/server/node/src/processors/stripe.js`):

**POST /payout-card/save** (Lines 672-735):
```javascript
app.post('/payout-card/save', async (req, res) => {
  try {
    const { timestamp, pubKey, signature, paymentMethodId } = req.body;

    // Verify signature: timestamp + pubKey + paymentMethodId
    if(!sessionless.verifySignature(signature, timestamp + pubKey + paymentMethodId, pubKey)) {
      res.status(403);
      return res.send({error: 'Auth error'});
    }

    // Get or create user
    let foundUser = await user.getUserByPublicKey(pubKey);
    if(!foundUser) {
      foundUser = await user.putUser({ pubKey });
    }

    // Save payout card (validates debit card only)
    const result = await stripe.savePayoutCard(foundUser, paymentMethodId);
    res.send(result);
  } catch(err) {
    res.status(404);
    res.send({error: err.message || 'Failed to save payout card'});
  }
});
```

**GET /payout-card/status** (Lines 737-770):
```javascript
app.get('/payout-card/status', async (req, res) => {
  try {
    const { timestamp, pubKey, signature } = req.query;

    // Verify signature: timestamp + pubKey
    if(!sessionless.verifySignature(signature, timestamp + pubKey, pubKey)) {
      res.status(403);
      return res.send({error: 'Auth error'});
    }

    const foundUser = await user.getUserByPublicKey(pubKey);
    if(!foundUser) {
      res.status(404);
      return res.send({error: 'User not found'});
    }

    const result = await stripe.getPayoutCard(foundUser);
    res.send(result);
  } catch(err) {
    res.status(404);
    res.send({error: err.message || 'Failed to check payout card status'});
  }
});
```

**POST /payment/:paymentIntentId/process-transfers** (Lines 801-873):
```javascript
app.post('/payment/:paymentIntentId/process-transfers', async (req, res) => {
  try {
    // Verify payment succeeded
    const paymentIntent = await stripeSDK.paymentIntents.retrieve(paymentIntentId);
    if(paymentIntent.status !== 'succeeded') {
      return res.send({error: 'Payment not yet succeeded'});
    }

    // Read payee metadata from payment intent
    const payeeCount = parseInt(paymentIntent.metadata.payee_count || '0');
    const transfers = [];

    for(let i = 0; i < payeeCount; i++) {
      const pubKey = paymentIntent.metadata[`payee_${i}_pubkey`];
      const amount = parseInt(paymentIntent.metadata[`payee_${i}_amount`]);

      // Look up payee's saved payout card
      const payeeUser = await user.getUserByPublicKey(pubKey);
      if(!payeeUser.stripePayoutCardId) {
        console.warn(`⚠️ Payee ${pubKey} does not have a payout card saved, skipping transfer`);
        continue;
      }

      // Create direct transfer to debit card (instant payout ~30 minutes)
      const transfer = await stripeSDK.transfers.create({
        amount: amount,
        currency: 'usd',
        destination: payeeUser.stripePayoutCardId,  // Payment method ID
        description: `Affiliate payout from ${paymentIntentId}`
      });

      transfers.push({
        pubKey: pubKey,
        amount: amount,
        transferId: transfer.id,
        destination: payeeUser.stripePayoutCardId
      });
    }

    res.send({
      success: true,
      transfers: transfers,
      paymentIntentId: paymentIntentId,
      totalTransfers: transfers.length
    });
  } catch(err) {
    res.status(500);
    res.send({error: err.message || 'Failed to process transfers'});
  }
});
```

**Stripe Processor Functions** (`stripe.js` lines 681-751):
```javascript
savePayoutCard: async (foundUser, paymentMethodId) => {
  try {
    const paymentMethod = await stripeSDK.paymentMethods.retrieve(paymentMethodId);

    // Validate debit card or issued card
    if(paymentMethod.card.funding !== 'debit' && !paymentMethod.card.issuer) {
      return {
        success: false,
        error: 'Only debit cards can be used as payout destinations'
      };
    }

    // Save to user record
    foundUser.stripePayoutCardId = paymentMethodId;
    await user.saveUser(foundUser);

    return {
      success: true,
      payoutCardId: paymentMethodId,
      last4: paymentMethod.card.last4,
      brand: paymentMethod.card.brand,
      expMonth: paymentMethod.card.exp_month,
      expYear: paymentMethod.card.exp_year
    };
  } catch(err) {
    return { success: false, error: err.message };
  }
},

getPayoutCard: async (foundUser) => {
  try {
    if(!foundUser.stripePayoutCardId) {
      return { success: true, hasPayoutCard: false };
    }

    const paymentMethod = await stripeSDK.paymentMethods.retrieve(foundUser.stripePayoutCardId);

    return {
      success: true,
      hasPayoutCard: true,
      payoutCardId: foundUser.stripePayoutCardId,
      last4: paymentMethod.card.last4,
      brand: paymentMethod.card.brand,
      expMonth: paymentMethod.card.exp_month,
      expYear: paymentMethod.card.exp_year
    };
  } catch(err) {
    return { success: false, error: err.message };
  }
}
```

### User Flow

**1. Initial Setup (Bob wants to receive affiliate commissions)**:
```
User opens The Advancement app
→ Taps "Receive Payments" tab
→ Sees "Payout Card Not Setup" state
→ Views list of available debit cards
→ Taps "Use for Payouts" on preferred card
→ Instant setup complete (~1 second)
→ Status changes to "Setup" with card details
→ Ready to receive payouts immediately
```

**2. Receiving Payments (Alice purchases from Bob's affiliate link)**:
```
Alice makes $50 purchase via Bob's link
→ Payment intent created with payee metadata:
   - Bob: $5 (10% affiliate)
   - Carl: $45 (90% revenue)
→ Alice completes payment via Stripe
→ Backend calls /payment/:id/process-transfers
→ Direct transfers created to payout cards:
   - $5 → Bob's saved debit card
   - $45 → Carl's saved debit card
→ Funds arrive in ~30 minutes (instant payout)
```

**3. Status Checking**:
```
User returns to "Receive Payments" tab
→ App calls getPayoutCardStatus()
→ Shows payout card details:
   - Brand: Visa
   - Last 4: 4242
   - Expires: 12/2025
   - Status: Instant payouts enabled
```

### Payment Intent Metadata Format

When creating payment intents with affiliate splits, payee information is stored in metadata:

```javascript
{
  "payee_count": "2",
  "payee_0_pubkey": "02a1b2c3...",  // Bob's pubKey
  "payee_0_amount": "500",           // $5 in cents
  "payee_1_pubkey": "02d4e5f6...",  // Carl's pubKey
  "payee_1_amount": "4500"           // $45 in cents
}
```

This metadata is read by `/payment/:id/process-transfers` to execute the instant payouts after payment confirmation.

### Storage

**iOS (UserDefaults)**:
```swift
UserDefaults.standard.set(payoutCardId, forKey: "stripe_payout_card_id")
```

**Android (SharedPreferences)**:
```kotlin
val prefs = getSharedPreferences("the_advancement", Context.MODE_PRIVATE)
prefs.edit().putString("stripe_payout_card_id", payoutCardId).apply()
```

**Addie User Record**:
```javascript
{
  uuid: "user-uuid",
  pubKey: "02a1b2c3...",
  stripeCustomerId: "cus_...",      // For making purchases
  stripePayoutCardId: "pm_...",     // For receiving payouts (debit card)
  stripeCardholderId: "ich_..."     // For virtual cards
}
```

### Testing

Comprehensive integration tests available in Sharon:
```bash
cd sharon
npm run test:the-advancement
```

**Test Coverage**:
- ✅ Check payout card status (initially empty)
- ✅ Save debit cards as payout destinations
- ✅ Validate debit-only restriction
- ✅ Create payment intents with payee splits
- ✅ Process instant transfers to payout cards
- ✅ Handle missing payout cards gracefully

See `/sharon/tests/the-advancement/payment-flows.test.js` and `/sharon/tests/the-advancement/README.md` for complete test documentation.

### Benefits over Connected Accounts

1. **Instant Setup**: No KYC onboarding required (~1 second vs 5-10 minutes)
2. **Faster Payouts**: ~30 minutes vs 2-3 business days
3. **Works with Issued Cards**: Planet Nine virtual cards can receive payouts immediately
4. **Simpler UX**: 2-state UI (setup/not setup) vs 3-state (not setup/pending/active)
5. **Lower Barrier**: Unbanked users with issued cards can receive payouts without traditional banking

### Trade-offs

- **Higher Fees**: 1.5% per payout vs 0.25% for Connected Accounts
- **US-Only**: Direct debit card transfers only work in the US (acceptable for beta)

**Decision**: The improved UX and instant setup justify the higher fees for our affiliate use case. Users can receive their first payout within 30 minutes of setup, compared to 2-3 days with Connected Accounts.

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