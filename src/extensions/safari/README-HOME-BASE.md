# The Advancement Safari Extension - Home Base Selection

## Overview

The Advancement Safari extension now includes a comprehensive home base selection system that allows users to choose their primary Planet Nine base for enhanced features across The Nullary apps. This implementation adapts The Nullary's base management patterns for the browser extension environment.

## Features

### 🏠 **Home Base Management**
- **Base Discovery**: Automatic discovery of available Planet Nine bases via BDO
- **Real-time Status**: Live status checking (online/offline) for each base
- **Visual Selection**: Clean UI for browsing and selecting home bases
- **Persistent Storage**: Home base choice saved across browser sessions

### 🔐 **Sessionless Integration**
- **Key Management**: Generate and manage cryptographic keys via native macOS app
- **Secure Storage**: Private keys stored in macOS Keychain for maximum security
- **Cross-Service Authentication**: Seamless authentication across Planet Nine services
- **Public Key Display**: View public key for sharing and verification

### 🎭 **Privacy Controls**
- **Email Auto-fill**: Rotating privacy emails with smart detection
- **Ad Covering**: Peaceful (Ficus) or Gaming mode ad covering options
- **Natural Typing**: Human-like typing simulation to avoid bot detection
- **Settings Sync**: Privacy preferences synchronized with content script

## Architecture

### Component Overview

```
Safari Extension
├── popup.html              # Main popup interface
├── popup.css               # Extension-specific styling
├── popup.js                # Core popup logic
├── popup-content-bridge.js # Communication bridge
├── advancement-content.js   # Content script (enhanced)
└── Info.plist             # Safari extension manifest
```

### Key Classes

#### **1. AdvancementPopupBridge**
Handles secure communication between popup and content script:
- **Message Routing**: Routes actions between popup and content environments
- **Request Management**: Handles asynchronous request/response cycles
- **Sessionless API**: Provides popup access to native cryptographic functions
- **Storage Sync**: Synchronizes settings between popup and page contexts

#### **2. EnhancedBaseDiscoveryService**
Discovers and manages Planet Nine bases:
- **Multi-source Discovery**: Content script → Direct API → Fallback bases
- **Status Monitoring**: Real-time connectivity checks for each base
- **Intelligent Caching**: 10-minute cache with automatic refresh
- **Feature Detection**: Automatically detects available services per base

#### **3. PopupUI**
Manages the complete popup user interface:
- **Tab Management**: Home Base, Keys, Privacy settings tabs
- **Base Selection**: Interactive base cards with status indicators
- **Key Operations**: Generate keys, view public key, check key status
- **Settings Management**: Privacy preferences and ad covering options

### Communication Flow

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Popup     │◄──►│   Bridge         │◄──►│ Content Script  │
│   (UI)      │    │   (Messages)     │    │ (Sessionless)   │
└─────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Native macOS   │
                    │  App (Keys)     │
                    └─────────────────┘
```

## Usage

### For Users

#### **Home Base Selection**
1. Click The Advancement toolbar icon in Safari
2. Navigate to "🏠 Home Base" tab
3. Browse available Planet Nine bases
4. Click a base card to select it as your home base
5. Selected base is automatically saved and used across Nullary apps

#### **Key Management**
1. Switch to "🔐 Keys" tab in popup
2. Click "Generate New Keys" for first-time setup
3. Keys are securely stored in macOS Keychain
4. Use "View Public Key" to see your public key for sharing
5. Keys work across all Planet Nine services

#### **Privacy Settings**
1. Open "🎭 Privacy" tab in popup
2. Configure email auto-fill behavior:
   - **Random**: Rotating privacy emails (recommended)
   - **Disabled**: No automatic email filling
3. Choose ad covering mode:
   - **Peaceful**: Cover ads with ficus plants
   - **Gaming**: Interactive ad "destruction" experience
   - **Disabled**: No ad covering

### For Developers

#### **Integration with The Nullary**
The home base selection integrates seamlessly with The Nullary apps:

```javascript
// Apps can detect user's home base via localStorage
const homeBase = JSON.parse(localStorage.getItem('advancement-home-base'));
if (homeBase) {
    console.log('User home base:', homeBase.name);
    // Enable enhanced features for home base users
}
```

#### **Sessionless Authentication**
When The Advancement is installed, Nullary apps gain access to secure authentication:

```javascript
// Check if The Advancement is available
if (window.Sessionless && window.Sessionless.isNative) {
    // Use native macOS cryptography via The Advancement
    const signature = await window.Sessionless.sign(message);
    
    // Authenticate with home base
    const auth = await authenticateWithBase(homeBase, signature);
}
```

#### **Privacy Email Integration**
The extension provides privacy emails for auto-fill:

```javascript
// Get random privacy email
const email = window.AdvancementExtension.getRandomEmail();
// Returns one of: letstest@planetnineapp.com, privacy@planetnineapp.com, etc.
```

## Technical Details

### Base Discovery Process

1. **Content Script Discovery**: First attempts to discover bases via enhanced content script
2. **Direct API Discovery**: Falls back to direct BDO API calls if content script unavailable
3. **Fallback Bases**: Uses hardcoded development and local bases as final fallback
4. **Status Validation**: Each discovered base is validated with health checks
5. **Caching**: Results cached for 10 minutes to improve performance

### Security Considerations

#### **Key Storage**
- **Private keys**: Stored exclusively in macOS Keychain, never in browser
- **Public data**: Home base selection and settings stored in localStorage
- **Communication**: All popup-content communication uses requestId tokens
- **Isolation**: Each component operates in appropriate security context

#### **Network Security**
- **HTTPS Only**: All base discovery uses HTTPS endpoints
- **Timeout Protection**: Network requests timeout after 5 seconds
- **Error Handling**: Graceful degradation when services unavailable
- **CORS Compliance**: Respects browser security policies

### Performance Optimizations

- **Lazy Loading**: Popup content loaded only when opened
- **Intelligent Caching**: Base data cached with smart invalidation
- **Debounced Updates**: UI updates debounced to prevent excessive redraws
- **Memory Cleanup**: Event listeners and timers properly cleaned up

## Future Enhancements

### Planned Features
- **Multiple Home Bases**: Support for secondary/backup base selection
- **Base Health Monitoring**: Background monitoring with notifications
- **Enhanced Privacy Emails**: User-configurable email domains
- **MAGIC Integration**: One-click payments and transactions
- **Cross-Browser Sync**: Sync settings across Chrome/Firefox/Safari

### Integration Opportunities
- **Teleportation Protocol**: Enhanced content discovery via home base
- **Julia Messaging**: P2P messaging through home base connections
- **Fount Transactions**: Direct payment processing via home base
- **Covenant Contracts**: Digital contract signing with home base witnesses

## Files Added/Modified

### New Files
- `popup.html` - Main popup interface with three-tab design
- `popup.css` - Complete styling using Planet Nine color scheme
- `popup.js` - Core popup logic with base discovery and management
- `popup-content-bridge.js` - Communication bridge between popup and content script
- `README-HOME-BASE.md` - This documentation

### Modified Files
- `Info.plist` - Added toolbar item and popup configuration
- `advancement-content.js` - Enhanced with popup message handling and base management

## Benefits

### For Users
- **Simplified Setup**: One-click home base selection for Planet Nine services
- **Enhanced Privacy**: Secure key management without passwords or personal info
- **Seamless Experience**: Home base choice persists across all Nullary apps
- **Visual Feedback**: Clear status indicators and friendly error messages

### For Developers
- **Consistent Patterns**: Reuses proven base management patterns from The Nullary
- **Secure Foundation**: Built on tested Sessionless and BDO protocols
- **Easy Integration**: Simple APIs for Nullary apps to detect and use home base
- **Future-Proof**: Architecture supports planned Planet Nine enhancements

The home base selection system transforms The Advancement from a simple privacy extension into a comprehensive gateway to the Planet Nine ecosystem, providing users with a secure, convenient way to access decentralized services while maintaining their privacy and control.