# The Advancement - Safari Extension

## Overview

The Safari extension for **The Advancement** provides comprehensive privacy and convenience features, combining sessionless authentication, intelligent input detection, natural typing simulation, and ad covering capabilities. It's designed to protect user privacy while making web browsing more convenient and secure.

This architecture keeps all Sessionless cryptography in the native macOS app, with the Safari extension acting as a secure bridge.

## Features

### 🔐 Sessionless Authentication
- **Cryptographic Key Management**: Secure key generation and storage using macOS Keychain
- **Passwordless Authentication**: No shared secrets or personal information required
- **Native App Integration**: Communicates with native macOS app for secure operations
- **secp256k1 Support**: Industry-standard elliptic curve cryptography

### 🕵️ Intelligent Input Detection
- **Email Field Detection**: Automatically identifies email input fields across all websites
- **Login Field Recognition**: Detects username/login fields using keyword analysis
- **Shadow DOM Support**: Works with modern web components and shadow DOM
- **iframe Compatibility**: Scans input fields within embedded frames
- **Dynamic Content Monitoring**: Detects fields added after page load

### ⌨️ Natural Typing Simulation
- **Human-like Typing**: Variable delays between keystrokes (50-150ms)
- **Natural Variations**: Occasional longer pauses and timing variations
- **Complete Event Simulation**: Proper keydown, keypress, input, keyup, change, and blur events
- **Bot Detection Avoidance**: Realistic typing patterns to avoid automated detection

### 🌿 Ad Covering System (Planned)
- **Ficus Feature**: Cover ads with peaceful plant images instead of blocking
- **Content Creator Support**: Ensures creators still get paid for ad impressions
- **Gaming Mode**: Optional "kill the ad" interactive experience
- **Click-to-Dismiss**: Simple tap anywhere on ad to make it disappear

### 🎭 Privacy Icons
- **Field Marking**: Visual indicators on detected input fields
- **Disguise Self Icons**: Gradient circular icons next to sensitive fields
- **User Control**: Click icons for privacy options and controls

## Architecture

### Content Script (`advancement-content.js`)
The main content script combines all extension functionality:

```javascript
// Global objects available to web pages
window.Sessionless      // Cryptographic authentication API
window.AdvancementExtension  // Privacy and convenience features
```

### Native App Integration (`SessionlessApp.swift`)
- **XPC Communication**: Secure inter-process communication with Safari
- **Keychain Storage**: Encrypted key storage using macOS security framework
- **Cryptographic Operations**: All signing operations happen in native app
- **Background Service**: Runs as accessory app (hidden from dock)

### Component Classes
- **InputDetector**: Scans pages for email and login fields
- **TypingSimulator**: Provides natural typing automation
- **SessionlessCore**: Handles cryptographic operations
- **SessionlessKeyManager**: Manages secure key storage

## Project Structure

```
safari/
├── advancement-content.js    # Main content script (combined functionality)
├── sessionless-content.js    # Legacy sessionless-only script
├── SessionlessApp.swift      # Native macOS app
├── InputDetector.js         # Standalone input detection class
├── TypingSimulator.js       # Standalone typing simulation class
├── Info.plist              # Safari extension manifest
└── README.md               # This documentation
```

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
