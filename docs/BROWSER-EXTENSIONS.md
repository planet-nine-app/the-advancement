# Browser Extensions

The Advancement supports multiple browsers with consistent functionality across Chrome and Safari platforms.

## Chrome Extension (`src/extensions/chrome/`)

### Architecture
- **Manifest v1**: Current implementation (needs v3 update)
- **Content Scripts**: Input detection, typing simulation, auto-fill
- **Background Service**: Extension coordination and state management
- **No Native App**: All functionality runs in browser context

### Core Components

#### InputDetector Class
```javascript
class InputDetector {
    constructor() {
        this.loginKeywords = ['user', 'username', 'login', 'account', 'email'];
    }

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

#### TypingSimulator Class
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

## Safari Extension (`src/extensions/safari/`)

### Enhanced Architecture
- **Native App Integration**: Secure XPC communication with macOS app
- **Keychain Storage**: Cryptographic keys stored in macOS Keychain
- **Comprehensive Features**: Full input detection + sessionless authentication + payment processing
- **Enhanced Security**: All crypto operations happen in native code
- **Home Base Management**: Complete three-environment base discovery and selection (DEV, TEST, LOCAL)
- **Payment Processing**: Stripe integration with multi-party payment splitting
- **Graceful Degradation**: Fallback functionality when bridge methods unavailable
- **Production Ready**: Real secp256k1 cryptography with compressed key format (02/03 prefix)

### Sessionless Integration
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

### Home Base Management (January 2025)
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

## File Structure

```
src/extensions/
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
├── safari/
│   ├── README.md              # Safari-specific documentation
│   ├── Info.plist            # Safari extension manifest (updated)
│   ├── SessionlessApp.swift  # Native macOS app
│   ├── advancement-content.js # Enhanced content script (updated)
│   ├── popup.html             # Three-tab popup interface (NEW)
│   ├── popup.css              # Planet Nine popup styling (NEW)
│   ├── popup.js               # Base discovery and management (NEW)
│   ├── popup-content-bridge.js # Popup ↔ content communication (NEW)
│   ├── stripe-integration.js # Payment processing system (NEW)
│   ├── sessionless-content.js # Legacy sessionless script
│   ├── InputDetector.js      # Standalone input detector
│   ├── TypingSimulator.js    # Standalone typing simulator
│   ├── adversement.js        # Ad covering system
│   ├── entertainment-system.js # Gaming overlay system
│   └── ecs.js                # Entity Component System
```

## Security Considerations

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

## Browser Compatibility

- ✅ **Chrome**: Full input detection and typing functionality
- ✅ **Safari**: Complete Planet Nine integration (sessionless auth + home base + payments)
- 🚧 **Firefox**: Planned with same feature set
- 🚧 **Edge**: Planned using Chrome extension base