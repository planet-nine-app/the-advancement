// ========================================
// advancement-content.js
// Comprehensive Safari Extension Content Script
// Combines Sessionless functionality with Input Detection and Typing Simulation
// ========================================

(function() {
    'use strict';
    
    // Prevent multiple injections
    if (window.AdvancementExtension) {
        console.log('🔄 The Advancement Safari Extension already loaded, skipping...');
        return;
    }

    console.log('🚀 The Advancement Safari Extension loading...');
    
    // Add visual indicator that extension is loaded
    const indicator = document.createElement('div');
    indicator.id = 'advancement-extension-indicator';
    indicator.style.cssText = `
        position: fixed;
        top: 10px;
        right: 10px;
        background: linear-gradient(45deg, #9b59b6, #667eea);
        color: white;
        padding: 8px 12px;
        border-radius: 20px;
        font-family: Arial, sans-serif;
        font-size: 12px;
        font-weight: bold;
        z-index: 10000;
        border: 2px solid rgba(255,255,255,0.3);
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        opacity: 0.9;
    `;
    indicator.textContent = '🚀 The Advancement Active';
    
    // Add to page once DOM is ready
    if (document.body) {
        document.body.appendChild(indicator);
    } else {
        document.addEventListener('DOMContentLoaded', () => {
            document.body.appendChild(indicator);
        });
    }

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
    // Sessionless Integration (Real Crypto Implementation)
    // ========================================
    
    // Use the real Safari Sessionless implementation if available
    if (typeof window.SafariSessionless !== 'undefined') {
        console.log('🔐 Using real Safari Sessionless implementation');
        window.Sessionless = window.SafariSessionless;
    } else {
        console.warn('⚠️ SafariSessionless not available, using fallback');
        // Fallback implementation for testing
        window.Sessionless = {
        
        /**
         * Generate a new keypair in the native app
         * @param {string} [seedPhrase] - Optional seed phrase for deterministic key generation
         * @returns {Promise<{publicKey: string, address: string}>}
         */
        generateKeys: function(seedPhrase) {
            return new Promise((resolve, reject) => {
                // Check if we have Web Extension API
                if (typeof chrome !== 'undefined' && chrome.runtime) {
                    // Use Web Extension messaging
                    chrome.runtime.sendMessage({
                        type: 'sessionless-generate-keys',
                        data: { seedPhrase }
                    }, (response) => {
                        if (chrome.runtime.lastError) {
                            console.warn('Extension API error, using mock keys:', chrome.runtime.lastError);
                            resolve(this._generateMockKeys());
                            return;
                        }
                        
                        if (response && response.success) {
                            resolve(response.data);
                        } else {
                            console.warn('Extension key generation failed, using mock');
                            resolve(this._generateMockKeys());
                        }
                    });
                } else if (typeof safari !== 'undefined' && safari.extension) {
                    // Use Safari Legacy API
                    const requestId = generateRequestId();
                    storeCallback(requestId, resolve, reject);
                    safari.extension.dispatchMessage('generateKeys', {
                        requestId: requestId,
                        seedPhrase: seedPhrase
                    });
                } else {
                    // Fallback to mock implementation
                    console.log('📱 No extension API available, generating mock keys for testing');
                    resolve(this._generateMockKeys());
                }
            });
        },
        
        // Mock key generation for testing
        _generateMockKeys: function() {
            const mockKeys = {
                publicKey: '0x' + Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
                address: '0x' + Array(40).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')
            };
            
            localStorage.setItem('advancement-sessionless-keys', JSON.stringify(mockKeys));
            console.log('✅ Mock sessionless keys generated');
            return mockKeys;
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
                
                // Check for extension APIs
                if (typeof chrome !== 'undefined' && chrome.runtime) {
                    // Web Extension API
                    chrome.runtime.sendMessage({
                        type: 'sessionless-sign',
                        data: { message }
                    }, (response) => {
                        if (response && response.success) {
                            resolve(response.data);
                        } else {
                            // Mock signature for testing
                            resolve({ signature: '0x' + Array(128).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('') });
                        }
                    });
                } else if (typeof safari !== 'undefined' && safari.extension) {
                    // Safari Legacy API
                    const requestId = generateRequestId();
                    storeCallback(requestId, resolve, reject);
                    safari.extension.dispatchMessage('sign', {
                        requestId: requestId,
                        message: message
                    });
                } else {
                    // Mock signature for testing
                    resolve({ signature: '0x' + Array(128).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('') });
                }
            });
        },
        
        /**
         * Get the public key from native app
         * @returns {Promise<{publicKey: string}>}
         */
        getPublicKey: function() {
            return new Promise((resolve, reject) => {
                // Check for extension APIs
                if (typeof chrome !== 'undefined' && chrome.runtime) {
                    // Web Extension API
                    chrome.runtime.sendMessage({
                        type: 'sessionless-get-public-key'
                    }, (response) => {
                        if (response && response.success) {
                            resolve(response.data);
                        } else {
                            // Try localStorage fallback
                            const stored = localStorage.getItem('advancement-sessionless-keys');
                            if (stored) {
                                const keys = JSON.parse(stored);
                                resolve({ publicKey: keys.publicKey });
                            } else {
                                reject(new Error('No keys found'));
                            }
                        }
                    });
                } else if (typeof safari !== 'undefined' && safari.extension) {
                    // Safari Legacy API
                    const requestId = generateRequestId();
                    storeCallback(requestId, resolve, reject);
                    safari.extension.dispatchMessage('getPublicKey', {
                        requestId: requestId
                    });
                } else {
                    // Fallback to localStorage
                    const stored = localStorage.getItem('advancement-sessionless-keys');
                    if (stored) {
                        const keys = JSON.parse(stored);
                        resolve({ publicKey: keys.publicKey });
                    } else {
                        reject(new Error('No keys found'));
                    }
                }
            });
        },
        
        /**
         * Get the address from native app
         * @returns {Promise<{address: string}>}
         */
        getAddress: function() {
            return new Promise((resolve, reject) => {
                // Check for extension APIs
                if (typeof chrome !== 'undefined' && chrome.runtime) {
                    // Web Extension API
                    chrome.runtime.sendMessage({
                        type: 'sessionless-get-address'
                    }, (response) => {
                        if (response && response.success) {
                            resolve(response.data);
                        } else {
                            // Try localStorage fallback
                            const stored = localStorage.getItem('advancement-sessionless-keys');
                            if (stored) {
                                const keys = JSON.parse(stored);
                                resolve({ address: keys.address });
                            } else {
                                reject(new Error('No keys found'));
                            }
                        }
                    });
                } else if (typeof safari !== 'undefined' && safari.extension) {
                    // Safari Legacy API
                    const requestId = generateRequestId();
                    storeCallback(requestId, resolve, reject);
                    safari.extension.dispatchMessage('getAddress', {
                        requestId: requestId
                    });
                } else {
                    // Fallback to localStorage
                    const stored = localStorage.getItem('advancement-sessionless-keys');
                    if (stored) {
                        const keys = JSON.parse(stored);
                        resolve({ address: keys.address });
                    } else {
                        reject(new Error('No keys found'));
                    }
                }
            });
        },
        
        /**
         * Check if keys exist in native app
         * @returns {Promise<{hasKeys: boolean}>}
         */
        hasKeys: function() {
            return new Promise((resolve, reject) => {
                // Check for extension APIs
                if (typeof chrome !== 'undefined' && chrome.runtime) {
                    // Web Extension API
                    chrome.runtime.sendMessage({
                        type: 'sessionless-has-keys'
                    }, (response) => {
                        if (response && response.success) {
                            resolve(response.data);
                        } else {
                            // Check localStorage
                            const stored = localStorage.getItem('advancement-sessionless-keys');
                            resolve({ hasKeys: !!stored });
                        }
                    });
                } else if (typeof safari !== 'undefined' && safari.extension) {
                    // Safari Legacy API
                    const requestId = generateRequestId();
                    storeCallback(requestId, resolve, reject);
                    safari.extension.dispatchMessage('hasKeys', {
                        requestId: requestId
                    });
                } else {
                    // Check localStorage
                    const stored = localStorage.getItem('advancement-sessionless-keys');
                    resolve({ hasKeys: !!stored });
                }
            });
        },
        
        // Fallback version info
        version: '2.0.0-fallback',
        isNative: false
        };
    }

    // ========================================
    // Spellbook Integration System
    // ========================================
    
    class SpellbookManager {
        constructor() {
            this.spellbook = null;
            this.lastFetch = null;
            this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
            this.spellbookKeys = {
                uuid: null,
                pubKey: null
            };
        }

        async initializeFromSeededData() {
            // Use the same key and UUID from our seeding script
            this.spellbookKeys = {
                uuid: null, // Will be retrieved from BDO
                pubKey: 'a29435a4fb1a27a284a60b3409efeebbe6a64db606ff38aeead579ccf2262dc4'
            };
        }

        async fetchSpellbookFromBDO(homeBase) {
            console.log('📚 Fetching spellbook from home base BDO:', homeBase);
            
            if (!homeBase || !homeBase.dns || !homeBase.dns.bdo) {
                throw new Error('No BDO service available on home base');
            }

            try {
                // Initialize seeded data if needed
                await this.initializeFromSeededData();

                const bdoUrl = homeBase.dns.bdo.startsWith('http') ? 
                    homeBase.dns.bdo : 
                    `https://${homeBase.dns.bdo}`;
                    
                // For test environment, use the test base URL
                const testBdoUrl = bdoUrl.includes('dev.bdo') ? 
                    'http://127.0.0.1:5114' : bdoUrl;

                console.log('📡 Connecting to BDO:', testBdoUrl);

                // First, find the spellbook user UUID
                if (!this.spellbookKeys.uuid) {
                    console.log('🔍 Searching for spellbook in BDO...');
                    
                    // Try to find a user with a spellbook
                    const searchResponse = await fetch(`${testBdoUrl}/users`, {
                        method: 'GET',
                        headers: {
                            'Accept': 'application/json',
                            'User-Agent': 'The-Advancement-Safari/1.0.0'
                        }
                    });

                    if (searchResponse.ok) {
                        const users = await searchResponse.json();
                        
                        // Find user with spellbook data
                        for (const [uuid, userData] of Object.entries(users)) {
                            if (userData.bdo && userData.bdo.spellbookName) {
                                this.spellbookKeys.uuid = uuid;
                                console.log('✅ Found spellbook user UUID:', uuid);
                                break;
                            }
                        }
                    }
                }

                // If still no UUID found, try the seeded UUID pattern
                if (!this.spellbookKeys.uuid) {
                    console.log('⚠️ No spellbook user found, this may mean the seeding script needs to be run');
                    return null;
                }

                // Fetch the spellbook using the found UUID
                const spellbookUrl = `${testBdoUrl}/user/${this.spellbookKeys.uuid}/bdo`;
                console.log('📚 Fetching spellbook from:', spellbookUrl);

                const spellbookResponse = await fetch(spellbookUrl, {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'User-Agent': 'The-Advancement-Safari/1.0.0'
                    }
                });

                if (!spellbookResponse.ok) {
                    throw new Error(`Failed to fetch spellbook: ${spellbookResponse.status}`);
                }

                const spellbookData = await spellbookResponse.json();
                
                if (spellbookData.spellbookName) {
                    this.spellbook = spellbookData;
                    this.lastFetch = Date.now();
                    
                    console.log('✅ Successfully retrieved spellbook:', this.spellbook.spellbookName);
                    console.log('📊 Available spells:', Object.keys(this.spellbook).filter(key => key !== 'spellbookName'));
                    
                    return this.spellbook;
                } else {
                    throw new Error('Retrieved data is not a valid spellbook');
                }

            } catch (error) {
                console.error('❌ Failed to fetch spellbook from BDO:', error);
                throw error;
            }
        }

        async getSpellbook(homeBase) {
            // Check cache first
            if (this.spellbook && this.lastFetch && 
                (Date.now() - this.lastFetch) < this.cacheTimeout) {
                console.log('📦 Using cached spellbook');
                return this.spellbook;
            }

            // Fetch fresh spellbook
            return await this.fetchSpellbookFromBDO(homeBase);
        }

        getSpellInfo(spellName) {
            if (!this.spellbook || !this.spellbook[spellName]) {
                return null;
            }

            return {
                name: spellName,
                ...this.spellbook[spellName],
                spellbookName: this.spellbook.spellbookName
            };
        }

        listAvailableSpells() {
            if (!this.spellbook) {
                return [];
            }

            return Object.keys(this.spellbook)
                .filter(key => key !== 'spellbookName')
                .map(spellName => ({
                    name: spellName,
                    ...this.spellbook[spellName]
                }));
        }

        getSpellbookStatus() {
            return {
                loaded: !!this.spellbook,
                spellbookName: this.spellbook?.spellbookName || null,
                spellCount: this.spellbook ? Object.keys(this.spellbook).filter(k => k !== 'spellbookName').length : 0,
                lastFetch: this.lastFetch,
                cacheStatus: this.lastFetch && (Date.now() - this.lastFetch) < this.cacheTimeout ? 'valid' : 'expired'
            };
        }
    }

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
    const spellbookManager = new SpellbookManager();

    // Main extension object
    window.AdvancementExtension = {
        detector: detector,
        simulator: simulator,
        spellbookManager: spellbookManager,
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
            console.log('🔍 Manually scanning page for input fields and spells...');
            detector.detectFields();
            spellHandler.applySpellHandlers();
        },

        // Manual trigger for spell detection
        scanSpells: function() {
            console.log('🪄 Manually scanning page for spell elements...');
            spellHandler.applySpellHandlers();
        },

        // Spellbook access methods
        async loadSpellbook() {
            console.log('📚 Loading spellbook from home base...');
            
            try {
                const homeBase = await getHomeBaseForPopup();
                if (!homeBase) {
                    throw new Error('No home base configured');
                }

                return await spellbookManager.getSpellbook(homeBase);
            } catch (error) {
                console.error('Failed to load spellbook:', error);
                return null;
            }
        },

        getSpellbookStatus() {
            return spellbookManager.getSpellbookStatus();
        },

        getSpell(spellName) {
            return spellbookManager.getSpellInfo(spellName);
        },

        listSpells() {
            return spellbookManager.listAvailableSpells();
        }
    };

    // ========================================
    // Spell Element Detection and Handling
    // ========================================
    
    class SpellHandler {
        constructor(spellbookManager) {
            this.spellbookManager = spellbookManager;
        }

        applySpellHandlers(container = document) {
            const spellElements = container.querySelectorAll('[spell]');
            console.log(`🪄 Found ${spellElements.length} spell elements`);
            
            spellElements.forEach(element => {
                // Skip if already processed
                if (element.classList.contains('spell-element')) {
                    return;
                }
                
                element.classList.add('spell-element');
                
                // Add wand cursor on hover
                element.addEventListener('mouseenter', () => {
                    element.style.cursor = `url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><text y="24" font-size="20">🪄</text></svg>') 16 16, pointer`;
                });

                // Reset cursor on leave
                element.addEventListener('mouseleave', () => {
                    element.style.cursor = '';
                });
                
                // Add click handler
                element.addEventListener('click', (event) => {
                    event.preventDefault();
                    event.stopPropagation();
                    window.castSpell(element);
                });
                
                console.log('🪄 Spell handler applied to element:', element.getAttribute('spell'));
            });
        }

        async castSpell(element) {
            const spellType = element.getAttribute('spell');
            const spellComponents = element.getAttribute('spell-components');
            
            console.log(`🪄 Attempting to cast spell: ${spellType}`);
            
            try {
                // Check if spell exists in our spellbook
                const spellInfo = this.spellbookManager.getSpellInfo(spellType);
                
                if (!spellInfo) {
                    console.log(`⚠️ Spell "${spellType}" not found in spellbook - no spell behavior`);
                    return;
                }
                
                console.log(`✨ Casting spell from spellbook:`, spellInfo);
                
                // Handle different spell types
                if (spellType === 'magicard' && spellComponents) {
                    await this.handleMagicardNavigation(element, spellComponents);
                } else if (spellInfo.mp === true) {
                    await this.handleMagicSpell(spellInfo, element);
                } else {
                    await this.handleRegularSpell(spellInfo, element);
                }
                
            } catch (error) {
                console.error('❌ Error casting spell:', error);
                alert(`⚠️ Spell casting failed: ${error.message}`);
            }
        }

        async handleMagicardNavigation(element, spellComponentsStr) {
            try {
                const spellComponents = JSON.parse(spellComponentsStr);
                if (!spellComponents.bdoPubKey) {
                    alert('⚠️ Invalid navigation spell - missing bdoPubKey');
                    return;
                }
                
                const bdoPubKey = spellComponents.bdoPubKey;
                console.log('🗃️ Navigating to MagiCard with BDO pubKey:', bdoPubKey);
                
                // This would integrate with MagiCard navigation if available
                // For now, just show the navigation intent
                alert(`🗃️ MagiCard Navigation: ${bdoPubKey.substring(0, 16)}...`);
                
            } catch (error) {
                alert('⚠️ Invalid navigation spell - malformed spell-components JSON');
            }
        }

        async handleMagicSpell(spellInfo, element) {
            console.log('🔮 Processing MAGIC spell (mp=true):', spellInfo);
            
            // Get site contributors for multi-party participation
            const siteContributors = window.AdvancementExtension.getSiteContributors();
            console.log('🤝 Site contributors:', siteContributors);
            
            // Prepare spell for MAGIC protocol resolution
            const spellPayload = {
                name: spellInfo.name,
                cost: spellInfo.cost,
                destinations: spellInfo.destinations,
                resolver: spellInfo.resolver,
                mp: spellInfo.mp,
                siteContributors: siteContributors,
                timestamp: Date.now(),
                elementContext: {
                    tagName: element.tagName,
                    id: element.id,
                    className: element.className
                }
            };
            
            console.log('🚀 MAGIC spell payload prepared:', spellPayload);
            
            // TODO: Integrate with Fount resolver
            // For now, simulate successful spell casting
            
            // Calculate nineum rewards based on spell cost
            const baseReward = Math.floor(spellInfo.cost * 0.2); // 20% of spell cost as nineum
            const userReward = baseReward; // User gets base reward
            const contributorReward = Math.floor(baseReward * 0.5); // Contributors get 50% of base reward each
            
            console.log(`⭐ Nineum rewards calculated: User: ${userReward}, Contributors: ${contributorReward} each`);
            
            // Notify website of nineum earned
            this.awardNineum(userReward, 'spellTest spell casting');
            
            // Award nineum to site contributors
            if (siteContributors.length > 0) {
                console.log(`🤝 Awarding ${contributorReward} nineum to ${siteContributors.length} site contributors`);
                // In real implementation, this would go through Fount to distribute rewards
            }
            
            alert(`🔮 MAGIC Spell Cast: ${spellInfo.name}\nCost: ${spellInfo.cost} MP\nResolver: ${spellInfo.resolver}\nContributors: ${siteContributors.length}\n\n⭐ You earned ${userReward} Nineum!`);
        }

        async handleRegularSpell(spellInfo, element) {
            console.log('⚡ Processing regular spell (mp=false):', spellInfo);
            
            // Handle non-MAGIC spells
            alert(`⚡ Regular Spell Cast: ${spellInfo.name}\nCost: ${spellInfo.cost}\nResolver: ${spellInfo.resolver}`);
        }

        awardNineum(amount, source) {
            console.log(`⭐ Awarding ${amount} nineum from ${source}`);
            
            // Dispatch custom event to notify the website
            document.dispatchEvent(new CustomEvent('nineum-earned', {
                detail: {
                    amount: amount,
                    source: source,
                    timestamp: Date.now()
                }
            }));
            
            // If the website has a NineumManager, use it directly
            if (window.NineumManager && typeof window.NineumManager.addNineum === 'function') {
                window.NineumManager.addNineum(amount, source);
            }
        }
    }

    // Initialize spell handler
    const spellHandler = new SpellHandler(spellbookManager);

    // Add castSpell to window for global access
    window.castSpell = async function(element) {
        await spellHandler.castSpell(element);
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
                    console.log('🔄 Hysteresis reset, scanning for new fields and spells...');
                    
                    // Scan for input fields
                    detector.detectFields();
                    
                    // Scan for spell elements
                    spellHandler.applySpellHandlers();
                    
                }, 1500);
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
    // Extension Communication (Web Extension API)
    // ========================================
    
    // Check if we're in a Web Extension context
    if (typeof chrome !== 'undefined' && chrome.runtime) {
        console.log('🌉 Web Extension API detected, setting up communication...');
        
        // Handle messages from popup via Web Extension API
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            console.log('📨 Content script received message:', message.type);
            
            if (message.type === 'advancementRequest') {
                handlePopupRequest(message.data).then(result => {
                    sendResponse({ success: true, data: result });
                }).catch(error => {
                    sendResponse({ success: false, error: error.message });
                });
                return true; // Keep message channel open for async response
            }
        });
        
        // Notify background that content script is ready
        chrome.runtime.sendMessage({
            type: 'content-script-ready',
            data: { url: window.location.href }
        });
        
    } else if (typeof safari !== 'undefined' && safari.extension) {
        console.log('🍎 Safari Legacy API detected, setting up communication...');
        
        // Handle messages from popup via Safari Legacy API
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
        
    } else {
        console.log('ℹ️ No extension API detected, running in standalone mode');
    }

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
                    
                case 'loadSpellbook':
                    result = await window.AdvancementExtension.loadSpellbook();
                    break;
                    
                case 'getSpellbookStatus':
                    result = await window.AdvancementExtension.getSpellbookStatus();
                    break;
                    
                case 'listSpells':
                    result = await window.AdvancementExtension.listSpells();
                    break;
                    
                case 'getSpell':
                    result = await window.AdvancementExtension.getSpell(data.spellName);
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
    // Site Contributors System
    // ========================================
    
    // Initialize site contributors system for multi-party spell participation
    function initializeSiteContributors() {
        // Define the siteContributors global variable for websites to use
        if (!window.siteContributors) {
            window.siteContributors = [];
        }

        // Provide helper functions for site owners
        window.AdvancementExtension.setSiteContributors = function(contributors) {
            if (!Array.isArray(contributors)) {
                console.warn('siteContributors must be an array of {contributor: <pubKey>, percent: <number>} objects');
                return;
            }

            // Validate contributors format
            const validatedContributors = contributors.filter(contrib => {
                if (!contrib.contributor || typeof contrib.contributor !== 'string') {
                    console.warn('Invalid contributor pubKey:', contrib);
                    return false;
                }
                if (typeof contrib.percent !== 'number' || contrib.percent < 0 || contrib.percent > 1) {
                    console.warn('Invalid contributor percent (must be 0-1):', contrib);
                    return false;
                }
                return true;
            });

            // Check that percentages sum to <= 1
            const totalPercent = validatedContributors.reduce((sum, contrib) => sum + contrib.percent, 0);
            if (totalPercent > 1) {
                console.warn('Total contributor percentages exceed 100%:', totalPercent);
                return;
            }

            window.siteContributors = validatedContributors;
            console.log('✅ Site contributors updated:', validatedContributors);
        };

        window.AdvancementExtension.getSiteContributors = function() {
            return window.siteContributors || [];
        };

        window.AdvancementExtension.addSiteContributor = function(contributor, percent) {
            if (!contributor || typeof contributor !== 'string') {
                console.warn('Invalid contributor pubKey');
                return;
            }
            if (typeof percent !== 'number' || percent < 0 || percent > 1) {
                console.warn('Invalid percent (must be 0-1)');
                return;
            }

            // Check total won't exceed 100%
            const currentTotal = window.siteContributors.reduce((sum, contrib) => sum + contrib.percent, 0);
            if (currentTotal + percent > 1) {
                console.warn('Adding contributor would exceed 100% total');
                return;
            }

            window.siteContributors.push({ contributor, percent });
            console.log('✅ Site contributor added:', { contributor, percent });
        };

        console.log('🤝 Site contributors system initialized');
    }

    // ========================================
    // Initialization
    // ========================================
    
    // Initial setup when DOM is ready
    function initializeExtension() {
        console.log('🚀 Initializing The Advancement Safari Extension...');
        
        // Initialize site contributors system
        initializeSiteContributors();
        
        // Run initial field and spell detection
        setTimeout(() => {
            console.log('🔍 Running initial field detection...');
            detector.detectFields();
            
            console.log('🪄 Running initial spell detection...');
            spellHandler.applySpellHandlers();
            
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
            features: ['inputDetection', 'typingSimulation', 'sessionless', 'adCovering', 'spellHandling', 'spellbookIntegration', 'siteContributors']
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