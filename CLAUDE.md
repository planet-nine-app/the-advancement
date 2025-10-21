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