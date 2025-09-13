# The Advancement - Safari Extension

## Overview

The Safari extension for **The Advancement** provides comprehensive privacy and convenience features, combining sessionless authentication, intelligent input detection, natural typing simulation, ad covering capabilities, and Planet Nine ecosystem integration. It features a sophisticated popup interface for home base management, spellbook functionality, and privacy settings.

This architecture includes both a content script system and a popup-based management interface, with bridge communication between components.

## Features

### 🏠 **Home Base Management** (NEW - January 2025)
- **Three-Tab Popup Interface**: Home Base selection, Keys management, Privacy settings
- **Multi-Environment Support**: DEV (dev.allyabase.com), TEST (127.0.0.1:5114-5118), LOCAL (localhost)
- **Base Discovery System**: Multiple discovery methods with intelligent fallbacks
- **Persistent Selection**: Home base choice saved across browser sessions
- **Real-time Status Monitoring**: Live connection status and base health checks
- **Protocol Intelligence**: Automatic HTTP/HTTPS selection based on address

### 📚 **Spellbook Integration** (NEW - January 2025)
- **BDO-Based Spellbook Fetching**: Retrieves spellbooks from home base's BDO service
- **Real-time Spell Management**: Load, list, and execute spells from selected base
- **Fallback System**: Local spellbook when bridge communication unavailable
- **Spell Status Tracking**: Monitor spell usage and availability
- **Auto-refresh Functionality**: Manual and automatic spellbook updates

### 🔐 **Sessionless Authentication**
- **Real secp256k1 Cryptography**: Industry-standard elliptic curve cryptography with compressed keys (02/03 prefix)
- **Cryptographic Key Management**: Secure key generation and storage
- **Passwordless Authentication**: No shared secrets or personal information required
- **Bridge Communication**: Secure popup ↔ content script messaging
- **Graceful Degradation**: Fallback functionality when native bridge unavailable

### 🕵️ **Intelligent Input Detection**
- **Email Field Detection**: Automatically identifies email input fields across all websites
- **Login Field Recognition**: Detects username/login fields using keyword analysis
- **Shadow DOM Support**: Works with modern web components and shadow DOM
- **iframe Compatibility**: Scans input fields within embedded frames
- **Dynamic Content Monitoring**: Detects fields added after page load

### ⌨️ **Natural Typing Simulation**
- **Human-like Typing**: Variable delays between keystrokes (50-150ms)
- **Natural Variations**: Occasional longer pauses and timing variations
- **Complete Event Simulation**: Proper keydown, keypress, input, keyup, change, and blur events
- **Bot Detection Avoidance**: Realistic typing patterns to avoid automated detection

### 🌿 **Ad Covering System** (Planned)
- **Ficus Feature**: Cover ads with peaceful plant images instead of blocking
- **Content Creator Support**: Ensures creators still get paid for ad impressions
- **Gaming Mode**: Optional "kill the ad" interactive experience
- **Click-to-Dismiss**: Simple tap anywhere on ad to make it disappear

### 🎭 **Privacy Features**
- **Privacy Email Rotation**: Multiple privacy-focused email addresses
- **Field Marking**: Visual indicators on detected input fields
- **Ad Experience Settings**: Choose between peaceful or gaming mode
- **Auto-detection Controls**: Toggle automatic field detection

## Architecture

The Safari extension follows a **dual-layer architecture** with separate concerns for user interface and content functionality:

### **Layer 1: Popup Interface** (User Management)
- **`popup.html`**: Three-tab interface (Home Base, Keys, Privacy)
- **`popup.js`**: Main UI logic and user interaction handling
- **`popup-content-bridge.js`**: Bridge communication and enhanced services
- **`popup.css`**: Styling following Planet Nine design patterns

### **Layer 2: Content Script** (Web Page Integration)
- **`advancement-content.js`**: Comprehensive content script with full functionality
- **`sessionless-real.js`**: Real secp256k1 cryptographic implementation
- **`secp256k1-real.js`**: Low-level cryptographic operations

### **Bridge Communication System**

```javascript
// Three-tier bridge architecture:

1. AdvancementPopupBridge (popup-content-bridge.js)
   ├── Safari extension messaging interface
   ├── Enhanced base discovery and storage
   └── Spellbook management coordination

2. EnhancedBaseDiscoveryService (popup-content-bridge.js)
   ├── Multi-source base discovery (content script → API → fallback)
   ├── Protocol-aware status checking (HTTP/HTTPS)
   └── Intelligent caching and fallback strategies

3. SpellbookManager (advancement-content.js)
   ├── BDO-based spellbook fetching from home bases
   ├── Real-time spell loading and management
   └── Fallback spellbook when bridge unavailable
```

### **Key Components**

#### **Popup Management (popup.js)**
```javascript
class PopupUI {
    constructor() {
        // Bridge instantiation
        this.bridge = new AdvancementPopupBridge();
        this.baseDiscovery = new EnhancedBaseDiscoveryService(this.bridge);
        this.storage = new EnhancedExtensionStorage(this.bridge);
    }
    
    // Tab management, base selection, spellbook loading
}
```

#### **Content Script Integration (advancement-content.js)**
```javascript
// Global APIs available to web pages
window.RealSessionless = {
    generateKeys(), hasKeys(), getPublicKey(), sign(), authenticate()
}

window.AdvancementExtension = {
    // Input detection, typing simulation, privacy features
    detector: new InputDetector(),
    simulator: new TypingSimulator(),
    spellbookManager: new SpellbookManager(),
    
    // APIs for web page interaction
    scanPage(), getRandomEmail(), loadSpellbook()
}
```

#### **Bridge Communication (popup-content-bridge.js)**
```javascript
class AdvancementPopupBridge {
    // Safari extension messaging
    sendMessage(action, data) {
        return safari.extension.dispatchMessage('advancementRequest', {
            requestId, action, data
        });
    }
    
    // Comprehensive API methods
    async generateKeys(), hasKeys(), getPublicKey(), sign()
    async discoverBases(), checkBaseStatus(), setHomeBase(), getHomeBase()
    async loadSpellbook(), getSpellbookStatus(), listSpells()
}
```

### **Environment Management**

The extension supports three Planet Nine environments:

#### **DEV Environment** (Production Development)
- **Base URLs**: `dev.bdo.allyabase.com`, `dev.sanora.allyabase.com`, etc.
- **Protocol**: HTTPS
- **Purpose**: Integration with production Planet Nine development infrastructure

#### **TEST Environment** (3-Base Docker Ecosystem)
- **Base URLs**: `127.0.0.1:5114-5118` (BDO, Sanora, Dolores, Fount, Addie)
- **Protocol**: HTTP (automatic detection)
- **Purpose**: Local testing with complete 3-base ecosystem

#### **LOCAL Environment** (Single-Service Development)
- **Base URLs**: `localhost:3003`, `localhost:7243`, etc.
- **Protocol**: HTTP (automatic detection)
- **Purpose**: Individual service development and testing

## Project Structure

```
safari/
├── manifest.json                # Chrome-style manifest (new format)
├── Info.plist                  # Safari extension manifest (legacy)
│
├── # === POPUP INTERFACE ===
├── popup.html                  # Three-tab popup UI (Home Base, Keys, Privacy)
├── popup.css                   # Planet Nine styling for popup
├── popup.js                    # Main popup logic and UI management
├── popup-content-bridge.js     # Bridge communication and enhanced services
│
├── # === CONTENT SCRIPTS ===
├── advancement-content.js      # Main content script (full functionality)
├── sessionless-real.js         # Real secp256k1 implementation
├── secp256k1-real.js           # Low-level cryptographic operations
├── sessionless-content.js      # Legacy sessionless-only script
│
├── # === STANDALONE COMPONENTS ===
├── InputDetector.js            # Standalone input detection class
├── TypingSimulator.js          # Standalone typing simulation class
├── stripe-integration.js       # Payment processing integration
│
├── # === NATIVE APP (Future) ===
├── SessionlessApp.swift        # Native macOS app (XPC bridge)
│
└── README.md                   # This documentation
```

### **File Purposes**

#### **Popup Layer**
- **`popup.html`**: HTML structure for three-tab interface
- **`popup.css`**: Styling following Planet Nine design patterns
- **`popup.js`**: PopupUI class, tab management, base selection, spellbook integration
- **`popup-content-bridge.js`**: AdvancementPopupBridge, EnhancedBaseDiscoveryService, EnhancedExtensionStorage

#### **Content Script Layer**
- **`advancement-content.js`**: Complete content script with SpellbookManager, message handling
- **`sessionless-real.js`**: Real cryptographic implementation with proper secp256k1
- **`secp256k1-real.js`**: Low-level cryptographic primitives

#### **Component Layer**
- **`InputDetector.js`**: Standalone input field detection across DOM types
- **`TypingSimulator.js`**: Human-like typing simulation with natural timing
- **`stripe-integration.js`**: Payment processing for Planet Nine commerce

### **Key Architecture Decisions**

#### **1. Dual-Layer Separation**
- **Popup Layer**: User management, settings, base selection
- **Content Layer**: Web page integration, real-time functionality

#### **2. Bridge Communication**
- **AdvancementPopupBridge**: Safari extension messaging interface
- **Enhanced Services**: Intelligent fallback and caching strategies
- **Message Routing**: Popup ↔ Content Script ↔ Native App (future)

#### **3. Environment Abstraction**
- **Protocol Intelligence**: Automatic HTTP/HTTPS based on address
- **Multi-Source Discovery**: Content script → Direct API → Hardcoded fallbacks
- **Persistent Storage**: localStorage with bridge backup

#### **4. Graceful Degradation**
- **Bridge Unavailable**: Fall back to direct operations
- **Service Offline**: Use cached data and fallback spellbooks
- **Network Issues**: Maintain functionality with local storage

## Current Status & Known Issues

### ✅ **Working Features**
- **Popup Interface**: Three-tab UI loads and displays correctly
- **Base Discovery**: DEV, TEST, and LOCAL bases discovered and displayed
- **Base Selection**: Users can select home base (persisted to localStorage)
- **Protocol Intelligence**: Automatic HTTP for 127.0.0.1/localhost, HTTPS for remote
- **Real Cryptography**: Proper secp256k1 with compressed keys (02/03 prefix)
- **Fallback Systems**: Graceful degradation when bridge methods unavailable
- **Fallback Spellbook**: Local spellbook display when bridge/BDO unavailable

### 🚧 **In Development**
- **Safari Extension Messaging**: Bridge communication between popup and content script
- **Full Spellbook Integration**: Real-time spellbook fetching from home base BDO
- **Native App Integration**: XPC communication for secure cryptographic operations
- **Payment Processing**: Stripe integration for Planet Nine commerce

### ⚠️ **Known Issues**

#### **Bridge Communication**
```javascript
// Current issue: Safari extension messaging not fully implemented
// Symptoms: "this.bridge.getHomeBase is not a function" errors
// Status: AdvancementPopupBridge exists but Safari messaging layer incomplete
```

#### **Content Script Integration**
```javascript
// Issue: Popup can't communicate with content script SpellbookManager
// Impact: Spellbook falls back to local instead of fetching from BDO
// Solution: Implement Safari extension message routing
```

#### **Native App Dependency**
```javascript
// Issue: Current implementation expects native macOS app for crypto
// Impact: Extension works in fallback mode only
// Options: 1) Implement native app, 2) Use browser-based crypto
```

## Development Workflow

### **Quick Testing**
```bash
# 1. Start TEST environment
cd /path/to/allyabase/deployment/docker
./test-all-bases.sh --build

# 2. Load extension in Safari
# Safari > Develop > Show Extension Builder
# Add extension from safari/ directory

# 3. Test popup functionality
# Click extension icon → verify three tabs work
# Select TEST base → verify spellbook loads (fallback)
```

### **Debug Bridge Communication**
```javascript
// In popup console:
console.log('Bridge instance:', this.bridge);
console.log('Available methods:', Object.getOwnPropertyNames(this.bridge));

// Check if AdvancementPopupBridge was created
console.log('AdvancementPopupBridge available:', !!window.AdvancementPopupBridge);
```

### **Test Spellbook Integration**
```javascript
// In content script console (on any webpage):
console.log('SpellbookManager:', window.AdvancementExtension?.spellbookManager);
console.log('Available spells:', await window.AdvancementExtension?.listSpells());
```

## Next Steps for Full Integration

### **Priority 1: Safari Extension Messaging**
1. Implement Safari extension message routing between popup and content script
2. Connect AdvancementPopupBridge.sendMessage() to actual Safari messaging API
3. Add message handlers in content script for bridge requests

### **Priority 2: Spellbook BDO Integration**
1. Connect popup spellbook refresh to content script SpellbookManager
2. Test real spellbook fetching from TEST environment (127.0.0.1:5114)
3. Implement proper error handling and fallback strategies

### **Priority 3: Architecture Decision**
1. **Option A**: Implement native macOS app for secure cryptographic operations
2. **Option B**: Use browser-based cryptography (current sessionless-real.js implementation)
3. **Option C**: Hybrid approach with progressive enhancement

## Setup Instructions

### 1. Create Native App with Proper secp256k1

**Package.swift** (for native app):
```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SessionlessApp",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "SessionlessApp",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift")
            ],
            path: "Sources"
        )
    ]
)
```

### 2. Updated SessionlessKeyManager with Real secp256k1

```swift
import secp256k1

class SessionlessKeyManager {
    
    private func generatePublicKeyAndAddress(from privateKey: Data) throws -> (Data, String) {
        // Create secp256k1 context
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw SessionlessError.cryptographyError("Failed to create secp256k1 context")
        }
        defer { secp256k1_context_destroy(context) }
        
        // Verify private key is valid
        let privateKeyBytes = [UInt8](privateKey.prefix(32))
        guard secp256k1_ec_seckey_verify(context, privateKeyBytes) == 1 else {
            throw SessionlessError.cryptographyError("Invalid private key")
        }
        
        // Generate public key
        var publicKeyObj = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(context, &publicKeyObj, privateKeyBytes) == 1 else {
            throw SessionlessError.cryptographyError("Failed to create public key")
        }
        
        // Serialize public key (compressed)
        var publicKeyBytes = [UInt8](repeating: 0, count: 33)
        var publicKeyLen = 33
        guard secp256k1_ec_pubkey_serialize(context, &publicKeyBytes, &publicKeyLen, &publicKeyObj, UInt32(SECP256K1_EC_COMPRESSED)) == 1 else {
            throw SessionlessError.cryptographyError("Failed to serialize public key")
        }
        
        let publicKeyData = Data(publicKeyBytes)
        
        // Generate Ethereum-style address (last 20 bytes of keccak256 hash)
        let uncompressedKeyBytes = getUncompressedPublicKey(context: context, publicKey: &publicKeyObj)
        let address = generateEthereumAddress(from: uncompressedKeyBytes)
        
        return (publicKeyData, address)
    }
    
    private func signWithSecp256k1(_ hash: Data, privateKey: Data) throws -> Data {
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN)) else {
            throw SessionlessError.cryptographyError("Failed to create secp256k1 context")
        }
        defer { secp256k1_context_destroy(context) }
        
        let privateKeyBytes = [UInt8](privateKey.prefix(32))
        let hashBytes = [UInt8](hash.prefix(32))
        
        var signature = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_sign(context, &signature, hashBytes, privateKeyBytes, nil, nil) == 1 else {
            throw SessionlessError.signingFailed
        }
        
        // Serialize signature in DER format
        var derSignature = [UInt8](repeating: 0, count: 72)
        var derSignatureLen = 72
        guard secp256k1_ecdsa_signature_serialize_der(context, &derSignature, &derSignatureLen, &signature) == 1 else {
            throw SessionlessError.cryptographyError("Failed to serialize signature")
        }
        
        return Data(derSignature.prefix(derSignatureLen))
    }
}
```

### 3. XPC Service Configuration

**SessionlessApp/Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>app.sessionless.native</string>
    <key>CFBundleName</key>
    <string>Sessionless</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSMainStoryboardFile</key>
    <string>Main</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSXPCServices</key>
    <dict>
        <key>app.sessionless.safari-helper</key>
        <dict>
            <key>ServiceType</key>
            <string>Application</string>
        </dict>
    </dict>
</dict>
</plist>
```

### 4. Safari Extension Configuration

**SessionlessSafariExtension/Info.plist**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Sessionless</string>
    <key>CFBundleIdentifier</key>
    <string>app.sessionless.safari-extension</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.Safari.extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).SessionlessSafariExtension</string>
        <key>SFSafariContentScript</key>
        <array>
            <dict>
                <key>Script</key>
                <string>sessionless-content.js</string>
            </dict>
        </array>
        <key>SFSafariWebsiteAccess</key>
        <dict>
            <key>Level</key>
            <string>All</string>
        </dict>
        <key>SFSafariExtensionDisplayName</key>
        <string>Sessionless</string>
    </dict>
</dict>
</plist>
```

## Security Benefits

### 🔒 **Native-Only Cryptography**
- Private keys never enter browser environment
- All signing operations happen in secure native code
- No JavaScript crypto dependencies

### 🛡️ **Keychain Integration**
- Private keys stored in macOS Keychain
- Hardware-level encryption when available
- Device-only access (no iCloud sync)

### 🌉 **Secure Bridge Architecture**
- Safari extension acts as message broker only
- XPC communication between extension and native app
- Minimal attack surface for web-based attacks

### 🔑 **Proper secp256k1**
- Uses battle-tested secp256k1 implementation
- Bitcoin/Ethereum compatible signatures
- Deterministic key generation from seed phrases

## Build and Distribution

### Development Build:
```bash
# Clone the secp256k1 library
git submodule add https://github.com/GigaBitcoin/secp256k1.swift.git

# Open in Xcode
open SessionlessApp.xcodeproj

# Build both native app and Safari extension
```

### App Store Distribution:
1. **Sandbox Entitlements**: Add `com.apple.security.files.user-selected.read-write`
2. **XPC Service**: Ensure XPC service is properly embedded
3. **Safari Extension**: Submit both app and extension together

### Developer Distribution:
```bash
# Notarize the native app
xcrun notarytool submit SessionlessApp.app

# Create installer package
productbuild --component SessionlessApp.app /Applications SessionlessInstaller.pkg
```

## Usage Example

```javascript
// Check if native app is running
const connected = await Sessionless.isNativeConnected();
if (!connected) {
    console.log('Please launch the Sessionless app');
    return;
}

// Generate keys (stored securely in native app)
const keys = await Sessionless.generateKeys();
console.log('Public key:', keys.publicKey);
console.log('Address:', keys.address);

// Sign a message (signing happens in native app)
const signature = await Sessionless.sign('Hello, Sessionless!');
console.log('Signature:', signature.signature);
```

## Consistency Across Browsers

To maintain consistency, create similar native apps for other platforms:

- **Chrome/Edge**: Use Native Messaging API with same native app
- **Firefox**: Use Native Messaging with WebExtensions
- **Universal**: Detect browser and use appropriate bridge

This architecture provides maximum security while maintaining cross-browser compatibility through consistent JavaScript APIs.
