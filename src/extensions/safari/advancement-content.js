// ========================================
// advancement-content.js
// Comprehensive Safari Extension Content Script
// Combines Sessionless functionality with Input Detection and Typing Simulation
// ========================================

(function() {
    'use strict';
    
    // Prevent multiple injections
    if (window.AdvancementExtension) {
        return;
    }

    console.log('🚀 The Advancement Safari Extension loading...');

    // ========================================
    // InputDetector Class
    // ========================================
    class InputDetector {
        constructor() {
            this.loginKeywords = ['user', 'username', 'login', 'account', 'email'];
        }

        searchNode(node) {
            const inputs = [];
            const shadowRoot = node.shadowRoot;
            
            if (shadowRoot) {
                // Search within shadow DOM
                shadowRoot.querySelectorAll('input').forEach((input) => inputs.push(input));
                
                // Continue searching child shadow DOMs
                shadowRoot.querySelectorAll('*').forEach(child => {
                    inputs.push(...this.searchNode(child));
                });
            }

            // Search regular children
            node.querySelectorAll('*').forEach((child) => {
                if (child.shadowRoot) {
                    inputs.push(...this.searchNode(child));
                }
            });

            return inputs;
        }

        findInputsInShadowDOM(root) {
            return this.searchNode(root);
        }

        findInputsInIframes() {
            const inputs = [];
            const iframes = document.getElementsByTagName('iframe');

            for (const iframe of iframes) {
                try {
                    const iframeInputs = iframe.contentDocument.getElementsByTagName('input');
                    inputs.push(...iframeInputs);
                } catch (e) {
                    console.log('Cannot access iframe content (likely cross-origin):', e);
                }
            }

            return inputs;
        }

        isLoginField(input) {
            const fieldIdentifiers = [
                input.id.toLowerCase(),
                input.name.toLowerCase(),
                input.placeholder.toLowerCase(),
                input.getAttribute('aria-label')?.toLowerCase() || '',
            ];

            return this.loginKeywords.some((keyword) =>
                fieldIdentifiers.some((identifier) => identifier.includes(keyword))
            );
        }

        markField(input, className) {
            input.classList.add(className);
            const iconContainer = document.createElement('div');
            iconContainer.className = 'disguise-self';
            iconContainer.style.cssText = `
                display: inline-block;
                width: 20px;
                height: 20px;
                background: linear-gradient(45deg, #667eea, #764ba2);
                border-radius: 50%;
                margin-left: 5px;
                cursor: pointer;
                position: relative;
                top: 3px;
            `;
            iconContainer.innerHTML = '🎭';
            
            if (input.parentNode) {
                input.parentNode.insertBefore(iconContainer, input.nextSibling);
            }

            iconContainer.addEventListener('click', () => {
                console.log(`🎭 Clicked disguise self icon for ${className}`);
                // Future: Open privacy options modal
            });
        }

        detectFields() {
            // Find all input fields on the page
            const inputs = document.getElementsByTagName('input');
            console.log('🔍 Found ' + inputs.length + ' inputs');

            const inputsByQuerySelector = document.querySelectorAll('input');
            console.log('🔍 Method 2 - querySelectorAll:', inputsByQuerySelector.length);

            const shadowInputs = this.findInputsInShadowDOM(document.body);
            console.log('🔍 Method 3 - Shadow DOM inputs:', shadowInputs.length);

            // Process regular inputs
            for (const input of inputs) {
                if (
                    input.type === 'email' ||
                    input.id.toLowerCase().includes('email') ||
                    input.name.toLowerCase().includes('email')
                ) {
                    this.markField(input, 'email-field');
                    continue;
                }
                if (this.isLoginField(input)) {
                    this.markField(input, 'login-field');
                }
            }

            // Process shadow DOM inputs
            for (const input of shadowInputs) {
                console.log('🔍 Processing shadow input:', input);
                if (
                    input.type === 'email' ||
                    input.id.toLowerCase().includes('email') ||
                    input.name.toLowerCase().includes('email')
                ) {
                    this.markField(input, 'email-field');
                    continue;
                }
                if (this.isLoginField(input)) {
                    console.log('🔍 Found a login field');
                    this.markField(input, 'login-field');
                }
            }
        }
    }

    // ========================================
    // TypingSimulator Class
    // ========================================
    class TypingSimulator {
        constructor(options = {}) {
            this.minDelay = options.minDelay || 50;
            this.maxDelay = options.maxDelay || 150;
            this.naturalMode = options.naturalMode !== false;
        }

        async typeIntoElement(element, text) {
            element.focus();

            if (element.value) {
                element.value = '';
                this.triggerEvent(element, 'input');
            }

            for (let i = 0; i < text.length; i++) {
                const char = text[i];
                const keyDetails = this.getKeyDetails(char);

                this.triggerKeyEvent(element, 'keydown', keyDetails);
                this.triggerKeyEvent(element, 'keypress', keyDetails);

                element.value = text.substring(0, i + 1);
                this.triggerEvent(element, 'input');
                this.triggerKeyEvent(element, 'keyup', keyDetails);

                await this.delay();
            }

            this.triggerEvent(element, 'change');
            element.blur();
            this.triggerEvent(element, 'blur');
        }

        getKeyDetails(char) {
            return {
                key: char,
                code: `Key${char.toUpperCase()}`,
                keyCode: char.charCodeAt(0),
                which: char.charCodeAt(0),
                shiftKey: /[A-Z]/.test(char),
                bubbles: true,
                cancelable: true,
            };
        }

        triggerKeyEvent(element, eventType, keyDetails) {
            const event = new KeyboardEvent(eventType, {
                ...keyDetails,
                view: window,
                composed: true,
            });

            Object.defineProperties(event, {
                keyCode: { value: keyDetails.keyCode },
                which: { value: keyDetails.which },
                key: { value: keyDetails.key },
            });

            element.dispatchEvent(event);
        }

        triggerEvent(element, eventType) {
            const event = new Event(eventType, {
                bubbles: true,
                cancelable: true,
                composed: true,
            });
            element.dispatchEvent(event);
        }

        delay() {
            let delay = Math.random() * (this.maxDelay - this.minDelay) + this.minDelay;

            if (this.naturalMode) {
                if (Math.random() < 0.1) {
                    delay *= 2;
                }
                delay += (Math.random() - 0.5) * 25;
            }

            return new Promise((resolve) => setTimeout(resolve, delay));
        }
    }

    // ========================================
    // Sessionless Integration (existing functionality)
    // ========================================
    
    // Create global Sessionless object for web pages
    window.Sessionless = {
        
        /**
         * Generate a new keypair in the native app
         * @param {string} [seedPhrase] - Optional seed phrase for deterministic key generation
         * @returns {Promise<{publicKey: string, address: string}>}
         */
        generateKeys: function(seedPhrase) {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('generateKeys', {
                    requestId: requestId,
                    seedPhrase: seedPhrase
                });
            });
        },
        
        /**
         * Sign a message with the stored private key (happens in native app)
         * @param {string} message - The message to sign
         * @returns {Promise<{signature: string}>}
         */
        sign: function(message) {
            return new Promise((resolve, reject) => {
                if (!message || typeof message !== 'string') {
                    reject(new Error('Message must be a non-empty string'));
                    return;
                }
                
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('sign', {
                    requestId: requestId,
                    message: message
                });
            });
        },
        
        /**
         * Get the public key from native app
         * @returns {Promise<{publicKey: string}>}
         */
        getPublicKey: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('getPublicKey', {
                    requestId: requestId
                });
            });
        },
        
        /**
         * Get the address from native app
         * @returns {Promise<{address: string}>}
         */
        getAddress: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('getAddress', {
                    requestId: requestId
                });
            });
        },
        
        /**
         * Check if keys exist in native app
         * @returns {Promise<{hasKeys: boolean}>}
         */
        hasKeys: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('hasKeys', {
                    requestId: requestId
                });
            });
        },
        
        // ... (include all other sessionless methods from the original file)
        
        version: '2.0.0',
        isNative: true
    };

    // ========================================
    // Main Extension Logic
    // ========================================
    
    // Initialize components
    const detector = new InputDetector();
    const simulator = new TypingSimulator({
        minDelay: 50,
        maxDelay: 150,
        naturalMode: true,
    });

    // Main extension object
    window.AdvancementExtension = {
        detector: detector,
        simulator: simulator,
        version: '1.0.0',
        
        // Email addresses for auto-fill
        emails: [
            'letstest@planetnineapp.com',
            'privacy@planetnineapp.com', 
            'advancement@planetnineapp.com'
        ],
        
        // Get random email
        getRandomEmail: function() {
            return this.emails[Math.floor(Math.random() * this.emails.length)];
        },
        
        // Manual trigger for field detection
        scanPage: function() {
            console.log('🔍 Manually scanning page for input fields...');
            detector.detectFields();
        }
    };

    // ========================================
    // Page Monitoring and Auto-fill Logic
    // ========================================
    
    let hysteresis = false;
    
    // Monitor for dynamic content changes
    const observer = new MutationObserver((mutations) => {
        for (const mutation of mutations) {
            if (!hysteresis && mutation.addedNodes.length) {
                hysteresis = true;
                setTimeout(() => {
                    hysteresis = false;
                    console.log('🔄 Hysteresis reset, scanning for new fields...');
                }, 1500);
                detector.detectFields();
            }
        }
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true,
    });

    // Auto-fill functionality
    document.addEventListener('click', async (event) => {
        const element = event.target;
        console.log('🖱️ Clicked element:', element);
        
        if (element.type === 'email') {
            element.focus();
            const email = window.AdvancementExtension.getRandomEmail();
            console.log('📧 Auto-filling email field with:', email);
            
            await simulator.typeIntoElement(element, email);
            event.preventDefault();
        }
    });

    // ========================================
    // Ad Covering System (TODO: Implement Ficus)
    // ========================================
    
    // TODO: Implement the famous "ficus" ad covering feature
    function coverAdsWithFicus() {
        // This will cover ads with peaceful plant images
        console.log('🌿 TODO: Implement ficus ad covering');
        
        // Future implementation:
        // 1. Detect ad elements
        // 2. Cover them with ficus plant images
        // 3. Add click-to-dismiss functionality
        // 4. Optional gaming mode where users can "kill" ads
    }

    // ========================================
    // Safari Extension Communication
    // ========================================
    
    // Handle messages from popup
    safari.extension.addEventListener('message', function(event) {
        if (event.name === 'advancementRequest') {
            handlePopupRequest(event.message);
        } else if (event.name === 'sessionlessResponse') {
            const response = event.message;
            const requestId = response.requestId;
            
            if (requestId && window._sessionlessCallbacks && window._sessionlessCallbacks[requestId]) {
                const callbacks = window._sessionlessCallbacks[requestId];
                
                if (response.success) {
                    callbacks.resolve(response.data);
                } else {
                    callbacks.reject(new Error(response.error || 'Unknown error'));
                }
                
                // Clean up this specific callback
                delete window._sessionlessCallbacks[requestId];
            }
        }
    });

    // Handle popup requests
    async function handlePopupRequest(request) {
        const { requestId, action, data } = request;
        
        try {
            let result;
            
            switch (action) {
                case 'generateKeys':
                    result = await window.Sessionless.generateKeys(data.seedPhrase);
                    break;
                    
                case 'hasKeys':
                    result = await window.Sessionless.hasKeys();
                    break;
                    
                case 'getPublicKey':
                    result = await window.Sessionless.getPublicKey();
                    break;
                    
                case 'getAddress':
                    result = await window.Sessionless.getAddress();
                    break;
                    
                case 'sign':
                    result = await window.Sessionless.sign(data.message);
                    break;
                    
                case 'discoverBases':
                    result = await discoverBasesForPopup();
                    break;
                    
                case 'checkBaseStatus':
                    result = await checkBaseStatusForPopup(data.baseUrl);
                    break;
                    
                case 'setHomeBase':
                    result = await setHomeBaseForPopup(data.base);
                    break;
                    
                case 'getHomeBase':
                    result = await getHomeBaseForPopup();
                    break;
                    
                case 'updatePrivacySettings':
                    result = await updatePrivacySettingsForPopup(data.settings);
                    break;
                    
                case 'getPrivacySettings':
                    result = await getPrivacySettingsForPopup();
                    break;
                    
                default:
                    throw new Error(`Unknown action: ${action}`);
            }
            
            // Send success response
            safari.extension.dispatchMessage('advancementResponse', {
                requestId,
                success: true,
                data: result
            });
            
        } catch (error) {
            // Send error response
            safari.extension.dispatchMessage('advancementResponse', {
                requestId,
                success: false,
                error: error.message
            });
        }
    }

    // Base discovery integration
    async function discoverBasesForPopup() {
        try {
            // This could integrate with existing base discovery logic
            // For now, return a simplified list
            return [
                {
                    id: 'dev',
                    name: 'DEV',
                    description: 'Development Planet Nine base',
                    dns: {
                        bdo: 'dev.bdo.allyabase.com',
                        sanora: 'dev.sanora.allyabase.com',
                        dolores: 'dev.dolores.allyabase.com'
                    }
                }
            ];
        } catch (error) {
            console.warn('Base discovery failed:', error);
            return [];
        }
    }

    async function checkBaseStatusForPopup(baseUrl) {
        try {
            const response = await fetch(`${baseUrl}/health`, {
                method: 'GET',
                signal: AbortSignal.timeout(5000)
            });
            return response.ok ? 'online' : 'offline';
        } catch {
            return 'offline';
        }
    }

    // Home base management
    async function setHomeBaseForPopup(base) {
        try {
            localStorage.setItem('advancement-home-base', JSON.stringify(base));
            console.log('🏠 Home base set from popup:', base.name);
            return { success: true };
        } catch (error) {
            console.error('Failed to set home base:', error);
            throw error;
        }
    }

    async function getHomeBaseForPopup() {
        try {
            const stored = localStorage.getItem('advancement-home-base');
            return stored ? JSON.parse(stored) : null;
        } catch (error) {
            console.warn('Failed to get home base:', error);
            return null;
        }
    }

    // Privacy settings management
    async function updatePrivacySettingsForPopup(settings) {
        try {
            // Update the extension's privacy settings
            if (settings.emailMode) {
                // This could affect the email auto-fill behavior
                console.log('📧 Email mode updated:', settings.emailMode);
            }
            
            if (settings.adMode) {
                // This could affect the ad covering behavior
                console.log('🌿 Ad mode updated:', settings.adMode);
            }
            
            localStorage.setItem('advancement-privacy-settings', JSON.stringify(settings));
            return { success: true };
        } catch (error) {
            console.error('Failed to update privacy settings:', error);
            throw error;
        }
    }

    async function getPrivacySettingsForPopup() {
        try {
            const stored = localStorage.getItem('advancement-privacy-settings');
            return stored ? JSON.parse(stored) : {
                emailMode: 'random',
                adMode: 'peaceful',
                autoDetection: true,
                naturalTyping: true
            };
        } catch (error) {
            console.warn('Failed to get privacy settings:', error);
            return null;
        }
    }
    
    // Private helper functions
    function generateRequestId() {
        return Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
    }
    
    function storeCallback(requestId, resolve, reject) {
        window._sessionlessCallbacks = window._sessionlessCallbacks || {};
        window._sessionlessCallbacks[requestId] = { 
            resolve: resolve, 
            reject: reject,
            timestamp: Date.now()
        };
        
        // Clean up old callbacks (older than 30 seconds)
        cleanupCallbacks();
    }
    
    function cleanupCallbacks() {
        if (!window._sessionlessCallbacks) return;
        
        const now = Date.now();
        const timeout = 30000; // 30 seconds
        
        for (const requestId in window._sessionlessCallbacks) {
            if (now - window._sessionlessCallbacks[requestId].timestamp > timeout) {
                const callback = window._sessionlessCallbacks[requestId];
                callback.reject(new Error('Request timeout'));
                delete window._sessionlessCallbacks[requestId];
            }
        }
    }
    
    // Handle responses from the Safari extension
    safari.extension.addEventListener('message', function(event) {
        if (event.name === 'sessionlessResponse') {
            const response = event.message;
            const requestId = response.requestId;
            
            if (requestId && window._sessionlessCallbacks && window._sessionlessCallbacks[requestId]) {
                const callbacks = window._sessionlessCallbacks[requestId];
                
                if (response.success) {
                    callbacks.resolve(response.data);
                } else {
                    callbacks.reject(new Error(response.error || 'Unknown error'));
                }
                
                // Clean up this specific callback
                delete window._sessionlessCallbacks[requestId];
            }
        }
    });

    // ========================================
    // Initialization
    // ========================================
    
    // Initial setup when DOM is ready
    function initializeExtension() {
        console.log('🚀 Initializing The Advancement Safari Extension...');
        
        // Run initial field detection
        setTimeout(() => {
            console.log('🔍 Running initial field detection...');
            detector.detectFields();
            
            // TODO: Initialize ad covering system
            // coverAdsWithFicus();
            
        }, 3000);
    }

    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeExtension);
    } else {
        initializeExtension();
    }
    
    // Dispatch ready events
    document.dispatchEvent(new CustomEvent('sessionlessReady', {
        detail: { 
            version: window.Sessionless.version,
            isNative: window.Sessionless.isNative
        }
    }));
    
    document.dispatchEvent(new CustomEvent('advancementReady', {
        detail: { 
            version: window.AdvancementExtension.version,
            features: ['inputDetection', 'typingSimulation', 'sessionless', 'adCovering']
        }
    }));
    
    console.log('🔐 Sessionless Native Safari Extension loaded (v' + window.Sessionless.version + ')');
    console.log('🚀 The Advancement Safari Extension loaded (v' + window.AdvancementExtension.version + ')');
    
    // Load Stripe integration
    const stripeScript = document.createElement('script');
    stripeScript.src = safari.extension.baseURI + 'stripe-integration.js';
    stripeScript.onload = () => {
        console.log('💳 Stripe integration loaded');
    };
    stripeScript.onerror = () => {
        console.warn('⚠️ Failed to load Stripe integration');
    };
    document.head.appendChild(stripeScript);
    
})();

// ========================================
// Export for other scripts (if needed)
// ========================================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { AdvancementExtension: window.AdvancementExtension };
}