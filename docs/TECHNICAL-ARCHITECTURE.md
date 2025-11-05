# Technical Architecture

The Advancement follows specific architectural patterns designed for security, performance, and cross-platform compatibility.

## Core Architecture Principles

### Privacy by Design
- **No Data Collection**: Extensions don't collect or transmit user data
- **Local Operation**: All functionality happens locally in browser/device
- **No Remote Servers**: No communication with external tracking services
- **Sandboxed Execution**: Browser security model isolation

### Security-First Development
- **Content Script Isolation**: Limited access to page context
- **No Eval**: No dynamic code execution
- **CSP Compliant**: Works with strict Content Security Policies
- **Minimal Dependencies**: Reduced attack surface area

## Browser Extension Architecture

### Content Script Patterns

#### Global Extension Object
```javascript
// Available to all web pages
window.AdvancementExtension = {
    detector: new InputDetector(),
    simulator: new TypingSimulator(),
    adversement: new AdversementSystem(),
    entertainment: new EntertainmentSystem(),
    version: '1.0.0',

    // Public API methods
    scanPage(): void,
    getRandomEmail(): string,
    toggleMonsterMode(): boolean
};
```

#### Event-Driven Communication
```javascript
// Cross-system communication via custom events
document.dispatchEvent(new CustomEvent('advancement-purchase-request', {
    detail: purchaseData
}));

document.addEventListener('advancement-payment-complete', (event) => {
    handlePaymentResult(event.detail);
});
```

### No-Modules Architecture (Tauri Compatibility)

**Reasoning**:
- **Browser Compatibility**: Works across all extension environments
- **Tauri Integration**: Compatible with Nullary app architecture
- **Security**: Minimal dependencies reduce attack surface
- **Performance**: Direct script execution without module resolution

```javascript
// Direct script inclusion pattern
<script src="InputDetector.js"></script>
<script src="TypingSimulator.js"></script>
<script src="adversement.js"></script>
<script src="entertainment-system.js"></script>
<script src="main.js"></script>
```

## Safari Extension Native Integration

### XPC Communication Architecture
```swift
// Secure inter-process communication
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        // Route to appropriate handler
        switch request.action {
        case "generateKeys":
            handleGenerateKeys(context: context)
        case "sign":
            handleSign(context: context)
        case "castSpell":
            handleCastSpell(context: context)
        }
    }
}
```

### Keychain Integration
```swift
// Secure key storage in macOS Keychain
class KeychainManager {
    static func storePrivateKey(_ key: Data, for identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed
        }
    }
}
```

## Dynamic Content Monitoring

### Hysteresis-Based Detection
```javascript
// Prevents excessive DOM scanning while maintaining responsiveness
let hysteresis = false;
const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
        if (!hysteresis && mutation.addedNodes.length) {
            hysteresis = true;
            setTimeout(() => {
                hysteresis = false;
                detector.detectFields();
            }, 1500); // Configurable delay
        }
    }
});

observer.observe(document.body, {
    childList: true,
    subtree: true
});
```

**Benefits**:
- **Performance**: Prevents excessive DOM scanning
- **Compatibility**: Works with single-page applications
- **Responsiveness**: Detects dynamically loaded content
- **Efficiency**: Batches detection operations

## Entity Component System (ECS)

### Entertainment System Architecture
```javascript
// Professional ECS for ad covering gaming features
class EntityComponentSystem {
    constructor() {
        this.entities = new Map();
        this.components = new Map();
        this.systems = [];
    }

    createEntity() {
        const id = this.generateId();
        this.entities.set(id, new Set());
        return id;
    }

    addComponent(entityId, componentType, data) {
        if (!this.components.has(componentType)) {
            this.components.set(componentType, new Map());
        }
        this.components.get(componentType).set(entityId, data);
        this.entities.get(entityId).add(componentType);
    }
}
```

### Component Types
```javascript
// Position component for spatial management
const Position = {
    create: (x, y) => ({ x, y }),
    update: (component, dx, dy) => {
        component.x += dx;
        component.y += dy;
    }
};

// Velocity component for physics simulation
const Velocity = {
    create: (dx, dy) => ({ dx, dy }),
    applyGravity: (component, gravity = 98) => {
        component.dy += gravity;
    }
};

// Render component for visual representation
const Render = {
    create: (text, fontSize, color) => ({ text, fontSize, color }),
    update: (component, properties) => {
        Object.assign(component, properties);
    }
};
```

### System Processing
```javascript
// Physics system for realistic movement
class PhysicsSystem {
    update(ecs, deltaTime) {
        const positions = ecs.components.get('Position');
        const velocities = ecs.components.get('Velocity');

        for (const [entityId, velocity] of velocities) {
            if (positions.has(entityId)) {
                const position = positions.get(entityId);

                // Apply velocity
                position.x += velocity.dx * deltaTime;
                position.y += velocity.dy * deltaTime;

                // Apply gravity
                velocity.dy += 98 * deltaTime; // 98 pixels/second²
            }
        }
    }
}
```

## Message Passing Architecture

### Background Script Coordination
```javascript
// Unified message handling for Safari Web Extension compatibility
async function handleMessage(message, sender) {
    try {
        let result;

        switch (message.type) {
            case 'castSpell':
                result = await handleCastSpell(message);
                break;
            case 'getSpellbook':
                result = await handleGetSpellbook(message);
                break;
            case 'processPayment':
                result = await handleProcessPayment(message);
                break;
            default:
                throw new Error(`Unknown message type: ${message.type}`);
        }

        return { success: true, data: result };
    } catch (error) {
        return { success: false, error: error.message };
    }
}
```

### Promise-Based Communication
```javascript
// Safari Web Extension compatible messaging
async function sendMessageToBackground(message) {
    if (typeof browser !== 'undefined' && browser.runtime) {
        // Modern Safari Web Extension API
        return await browser.runtime.sendMessage(message);
    } else if (typeof safari !== 'undefined') {
        // Safari Legacy API fallback
        return new Promise((resolve) => {
            safari.extension.dispatchMessage('message', message);
            safari.extension.addEventListener('message', function handler(event) {
                if (event.name === 'response') {
                    safari.extension.removeEventListener('message', handler);
                    resolve(event.message);
                }
            });
        });
    }
    throw new Error('No supported messaging API available');
}
```

## State Management

### Environment Configuration
```javascript
// Three-environment support with automatic switching
const environments = {
    DEV: {
        bdo: 'https://dev.bdo.allyabase.com',
        sanora: 'https://dev.sanora.allyabase.com',
        addie: 'https://dev.addie.allyabase.com'
    },
    TEST: {
        bdo: 'http://127.0.0.1:5117',
        sanora: 'http://127.0.0.1:5118',
        addie: 'http://127.0.0.1:5116'
    },
    LOCAL: {
        bdo: 'http://localhost:3003',
        sanora: 'http://localhost:7243',
        addie: 'http://localhost:3005'
    }
};

// Persistent environment selection
class EnvironmentManager {
    constructor() {
        this.current = localStorage.getItem('selected-environment') || 'DEV';
    }

    switch(environment) {
        if (environments[environment]) {
            this.current = environment;
            localStorage.setItem('selected-environment', environment);
            this.notifyChange();
        }
    }

    getServiceUrl(service) {
        return environments[this.current][service];
    }
}
```

### Cache Management
```javascript
// Intelligent caching with TTL
class CacheManager {
    constructor() {
        this.cache = new Map();
        this.ttl = new Map();
    }

    set(key, value, ttlMs = 300000) { // 5 minute default
        this.cache.set(key, value);
        this.ttl.set(key, Date.now() + ttlMs);
    }

    get(key) {
        if (this.ttl.has(key) && Date.now() > this.ttl.get(key)) {
            this.cache.delete(key);
            this.ttl.delete(key);
            return null;
        }
        return this.cache.get(key);
    }

    invalidate(key) {
        this.cache.delete(key);
        this.ttl.delete(key);
    }
}
```

## Error Handling Patterns

### Graceful Degradation
```javascript
// Comprehensive error handling with fallbacks
class ServiceClient {
    constructor(baseUrl, fallbackUrl = null) {
        this.baseUrl = baseUrl;
        this.fallbackUrl = fallbackUrl;
        this.retryCount = 3;
    }

    async request(endpoint, options = {}) {
        let lastError;

        // Try primary service
        for (let i = 0; i < this.retryCount; i++) {
            try {
                return await this.makeRequest(this.baseUrl + endpoint, options);
            } catch (error) {
                lastError = error;
                await this.delay(1000 * (i + 1)); // Exponential backoff
            }
        }

        // Try fallback service
        if (this.fallbackUrl) {
            try {
                return await this.makeRequest(this.fallbackUrl + endpoint, options);
            } catch (fallbackError) {
                console.warn('Fallback also failed:', fallbackError);
            }
        }

        throw new ServiceError('All service attempts failed', lastError);
    }
}
```

### User-Friendly Error Messages
```javascript
// Convert technical errors to user-friendly messages
const errorMessages = {
    'NETWORK_ERROR': 'Connection issue. Please check your internet and try again.',
    'SERVICE_UNAVAILABLE': 'Service temporarily unavailable. Please try again later.',
    'INVALID_SIGNATURE': 'Security verification failed. Please refresh and retry.',
    'PAYMENT_DECLINED': 'Payment method declined. Please try another card.',
    'INSUFFICIENT_FUNDS': 'Insufficient funds. Please try another payment method.',
    'RATE_LIMITED': 'Too many requests. Please wait a moment and try again.'
};

function getUserFriendlyError(error) {
    return errorMessages[error.code] || 'An unexpected error occurred. Please try again.';
}
```

## Performance Optimization

### DOM Scanning Efficiency
```javascript
// Optimized field detection with caching
class OptimizedInputDetector {
    constructor() {
        this.scanCache = new Map();
        this.observedElements = new WeakSet();
    }

    detectFields() {
        const cacheKey = this.generateCacheKey();
        if (this.scanCache.has(cacheKey)) {
            return this.scanCache.get(cacheKey);
        }

        const fields = this.performScan();
        this.scanCache.set(cacheKey, fields);

        // Cache cleanup after 30 seconds
        setTimeout(() => this.scanCache.delete(cacheKey), 30000);

        return fields;
    }

    generateCacheKey() {
        // Create key based on DOM structure
        return `${document.querySelectorAll('input').length}-${document.querySelectorAll('form').length}`;
    }
}
```

### Memory Management
```javascript
// Cleanup patterns for long-running content scripts
class MemoryManager {
    constructor() {
        this.observers = [];
        this.eventListeners = [];
        this.intervals = [];
        this.timeouts = [];
    }

    addObserver(observer) {
        this.observers.push(observer);
        return observer;
    }

    cleanup() {
        // Disconnect all observers
        this.observers.forEach(observer => observer.disconnect());
        this.observers = [];

        // Remove event listeners
        this.eventListeners.forEach(({ element, event, handler }) => {
            element.removeEventListener(event, handler);
        });
        this.eventListeners = [];

        // Clear intervals and timeouts
        this.intervals.forEach(clearInterval);
        this.timeouts.forEach(clearTimeout);
        this.intervals = [];
        this.timeouts = [];
    }
}
```

## Security Architecture

### Content Security Policy Compliance
```javascript
// CSP-compliant event handling
class CSPCompliantExtension {
    constructor() {
        this.eventHandlers = new Map();
        this.setupEventDelegation();
    }

    setupEventDelegation() {
        // Use event delegation instead of inline handlers
        document.addEventListener('click', (event) => {
            const handler = this.eventHandlers.get(event.target);
            if (handler) {
                handler(event);
            }
        });
    }

    registerHandler(element, handler) {
        this.eventHandlers.set(element, handler);
    }
}
```

### Input Sanitization
```javascript
// Comprehensive input validation
class InputSanitizer {
    static sanitizeHTML(input) {
        return input
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#x27;');
    }

    static validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    static validatePubKey(pubKey) {
        // Validate secp256k1 public key format
        const pubKeyRegex = /^(02|03)[0-9a-fA-F]{64}$/;
        return pubKeyRegex.test(pubKey);
    }
}
```

## Cross-Platform Compatibility

### Browser Feature Detection
```javascript
// Progressive enhancement based on browser capabilities
class BrowserCapabilities {
    static detect() {
        return {
            webExtensions: typeof browser !== 'undefined',
            safari: typeof safari !== 'undefined',
            chrome: typeof chrome !== 'undefined',
            cryptoSubtle: typeof crypto !== 'undefined' && crypto.subtle,
            serviceWorker: 'serviceWorker' in navigator,
            webAssembly: typeof WebAssembly !== 'undefined'
        };
    }

    static getOptimalImplementation() {
        const caps = this.detect();

        if (caps.safari && caps.webExtensions) {
            return 'safari-web-extension';
        } else if (caps.safari) {
            return 'safari-legacy';
        } else if (caps.chrome) {
            return 'chrome-extension';
        } else {
            return 'generic-web';
        }
    }
}
```

The technical architecture emphasizes security, performance, and maintainability while providing a robust foundation for privacy-focused web interactions across the Planet Nine ecosystem.