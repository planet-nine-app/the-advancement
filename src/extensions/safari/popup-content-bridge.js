/**
 * The Advancement Safari Extension Popup-Content Bridge
 * Handles communication between popup and content script for Sessionless integration
 */

(function() {
    'use strict';

    // ========================================
    // Safari Extension Bridge
    // ========================================
    
    class AdvancementPopupBridge {
        constructor() {
            this.messageHandlers = new Map();
            this.pendingRequests = new Map();
            this.setupMessageHandling();
        }

        setupMessageHandling() {
            // Listen for messages from content script
            if (typeof safari !== 'undefined' && safari.extension) {
                safari.extension.addEventListener('message', (event) => {
                    this.handleMessage(event);
                });
            }
        }

        handleMessage(event) {
            const { name, message } = event;
            
            if (name === 'advancementResponse') {
                this.handleResponse(message);
            } else if (name === 'baseStatusUpdate') {
                this.handleBaseStatusUpdate(message);
            } else if (name === 'sessionlessUpdate') {
                this.handleSessionlessUpdate(message);
            }
        }

        handleResponse(response) {
            const { requestId, success, data, error } = response;
            
            if (this.pendingRequests.has(requestId)) {
                const { resolve, reject } = this.pendingRequests.get(requestId);
                this.pendingRequests.delete(requestId);
                
                if (success) {
                    resolve(data);
                } else {
                    reject(new Error(error || 'Unknown error'));
                }
            }
        }

        handleBaseStatusUpdate(update) {
            // Broadcast to UI components that care about base status
            document.dispatchEvent(new CustomEvent('baseStatusUpdate', {
                detail: update
            }));
        }

        handleSessionlessUpdate(update) {
            // Broadcast sessionless state changes
            document.dispatchEvent(new CustomEvent('sessionlessUpdate', {
                detail: update
            }));
        }

        // Send message to content script
        sendMessage(action, data = {}) {
            return new Promise((resolve, reject) => {
                const requestId = this.generateRequestId();
                
                this.pendingRequests.set(requestId, { resolve, reject });
                
                // Clean up after timeout
                setTimeout(() => {
                    if (this.pendingRequests.has(requestId)) {
                        this.pendingRequests.delete(requestId);
                        reject(new Error('Request timeout'));
                    }
                }, 10000);
                
                if (typeof safari !== 'undefined' && safari.extension) {
                    safari.extension.dispatchMessage('advancementRequest', {
                        requestId,
                        action,
                        data
                    });
                } else {
                    reject(new Error('Safari extension API not available'));
                }
            });
        }

        generateRequestId() {
            return Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
        }

        // Sessionless API methods
        async generateKeys(seedPhrase) {
            return this.sendMessage('generateKeys', { seedPhrase });
        }

        async hasKeys() {
            return this.sendMessage('hasKeys');
        }

        async getPublicKey() {
            return this.sendMessage('getPublicKey');
        }

        async getAddress() {
            return this.sendMessage('getAddress');
        }

        async sign(message) {
            return this.sendMessage('sign', { message });
        }

        // Base management methods
        async discoverBases() {
            return this.sendMessage('discoverBases');
        }

        async checkBaseStatus(baseUrl) {
            return this.sendMessage('checkBaseStatus', { baseUrl });
        }

        async setHomeBase(base) {
            return this.sendMessage('setHomeBase', { base });
        }

        async getHomeBase() {
            return this.sendMessage('getHomeBase');
        }

        // Privacy settings methods
        async updatePrivacySettings(settings) {
            return this.sendMessage('updatePrivacySettings', { settings });
        }

        async getPrivacySettings() {
            return this.sendMessage('getPrivacySettings');
        }

        // Spellbook management methods
        async loadSpellbook() {
            return this.sendMessage('loadSpellbook');
        }

        async getSpellbookStatus() {
            return this.sendMessage('getSpellbookStatus');
        }

        async listSpells() {
            return this.sendMessage('listSpells');
        }

        async getSpell(spellName) {
            return this.sendMessage('getSpell', { spellName });
        }
    }

    // ========================================
    // Enhanced Base Discovery
    // ========================================
    
    class EnhancedBaseDiscoveryService {
        constructor(bridge) {
            this.bridge = bridge;
            this.discoveryEndpoint = 'https://dev.bdo.allyabase.com/bases';
            this.cache = {
                bases: null,
                timestamp: null,
                duration: 10 * 60 * 1000 // 10 minutes
            };
        }

        async discoverBases() {
            console.log('🔍 Enhanced base discovery starting...');
            
            try {
                // First try to get bases from content script (if available)
                const contentBases = await this.bridge.discoverBases().catch(() => null);
                
                if (contentBases && contentBases.length > 0) {
                    console.log('📡 Got bases from content script:', contentBases.length);
                    return this.processBases(contentBases);
                }
                
                // Fallback to direct discovery
                return await this.directDiscovery();
                
            } catch (error) {
                console.warn('⚠️ Enhanced discovery failed, using fallback:', error);
                return this.getFallbackBases();
            }
        }

        async directDiscovery() {
            console.log('🌐 Direct base discovery...');
            
            const response = await fetch(this.discoveryEndpoint, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                    'User-Agent': 'The-Advancement-Safari/1.0.0'
                }
            });

            if (!response.ok) {
                throw new Error(`Base discovery failed: ${response.status}`);
            }

            const basesData = await response.json();
            return this.processBases(basesData);
        }

        processBases(basesData) {
            const bases = [];
            
            if (Array.isArray(basesData)) {
                // Handle array format
                bases.push(...basesData.map(base => this.normalizeBase(base)));
            } else if (basesData && typeof basesData === 'object') {
                // Handle object format (from BDO)
                for (const [baseId, baseInfo] of Object.entries(basesData)) {
                    bases.push(this.normalizeBase({ id: baseId, ...baseInfo }));
                }
            }

            // Ensure we have at least the development base
            if (!bases.find(base => base.id === 'dev')) {
                bases.unshift(this.getDevBase());
            }

            return bases;
        }

        normalizeBase(baseData) {
            return {
                id: baseData.id || baseData.name?.toLowerCase() || 'unknown',
                name: baseData.name || baseData.id?.toUpperCase() || 'Unknown',
                description: baseData.description || `Planet Nine base: ${baseData.id}`,
                dns: baseData.dns || {},
                status: 'connecting',
                features: this.detectFeatures(baseData.dns || baseData),
                isHomeBase: false,
                metadata: {
                    discovered: Date.now(),
                    source: 'discovery'
                }
            };
        }

        detectFeatures(dns) {
            const features = [];
            
            if (dns) {
                if (dns.bdo) features.push('BDO');
                if (dns.sanora) features.push('Sanora');
                if (dns.dolores) features.push('Dolores');
                if (dns.fount) features.push('Fount');
                if (dns.addie) features.push('Addie');
                if (dns.julia) features.push('Julia');
                if (dns.pref) features.push('Pref');
            }
            
            return features;
        }

        getDevBase() {
            return {
                id: 'dev',
                name: 'DEV',
                description: 'Development Planet Nine base',
                dns: {
                    bdo: 'dev.bdo.allyabase.com',
                    sanora: 'dev.sanora.allyabase.com',
                    dolores: 'dev.dolores.allyabase.com',
                    fount: 'dev.fount.allyabase.com',
                    addie: 'dev.addie.allyabase.com'
                },
                status: 'connecting',
                features: ['BDO', 'Sanora', 'Dolores', 'Fount', 'Addie'],
                isHomeBase: false,
                metadata: {
                    discovered: Date.now(),
                    source: 'default'
                }
            };
        }

        getFallbackBases() {
            return [
                this.getDevBase(),
                {
                    id: 'local',
                    name: 'LOCAL',
                    description: 'Local development base',
                    dns: {
                        bdo: 'localhost:3003',
                        sanora: 'localhost:7243',
                        dolores: 'localhost:3007'
                    },
                    status: 'connecting',
                    features: ['BDO', 'Sanora', 'Dolores'],
                    isHomeBase: false,
                    metadata: {
                        discovered: Date.now(),
                        source: 'fallback'
                    }
                }
            ];
        }

        async checkBaseStatus(base) {
            try {
                // Try to use bridge first
                const status = await this.bridge.checkBaseStatus(base.dns.bdo).catch(() => null);
                if (status) {
                    return status;
                }
                
                // Fallback to direct check
                return await this.directStatusCheck(base);
                
            } catch (error) {
                console.warn(`Base ${base.name} status check failed:`, error);
                return 'offline';
            }
        }

        async directStatusCheck(base) {
            const bdoUrl = base.dns.bdo;
            if (!bdoUrl) return 'offline';

            const url = bdoUrl.startsWith('http') ? bdoUrl : `https://${bdoUrl}`;
            
            try {
                const response = await fetch(`${url}/health`, {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' },
                    signal: AbortSignal.timeout(5000)
                });

                return response.ok ? 'online' : 'offline';
            } catch {
                return 'offline';
            }
        }
    }

    // ========================================
    // Enhanced Storage with Bridge Integration
    // ========================================
    
    class EnhancedExtensionStorage {
        constructor(bridge) {
            this.bridge = bridge;
            this.storagePrefix = 'advancement-';
        }

        async getHomeBase() {
            try {
                // Try to get from content script first
                const bridgeBase = await this.bridge.getHomeBase().catch(() => null);
                if (bridgeBase) {
                    return bridgeBase;
                }
                
                // Fallback to local storage
                const stored = localStorage.getItem(this.storagePrefix + 'home-base');
                return stored ? JSON.parse(stored) : null;
            } catch (error) {
                console.warn('Failed to load home base:', error);
                return null;
            }
        }

        async setHomeBase(base) {
            try {
                // Save via bridge
                await this.bridge.setHomeBase(base);
                
                // Also save locally as backup
                localStorage.setItem(this.storagePrefix + 'home-base', JSON.stringify(base));
                console.log('💾 Home base saved via bridge:', base.name);
            } catch (error) {
                console.error('Failed to save home base via bridge:', error);
                
                // Fallback to local storage only
                localStorage.setItem(this.storagePrefix + 'home-base', JSON.stringify(base));
                console.log('💾 Home base saved locally as fallback:', base.name);
            }
        }

        async getSettings() {
            try {
                // Try to get from content script first
                const bridgeSettings = await this.bridge.getPrivacySettings().catch(() => null);
                if (bridgeSettings) {
                    return bridgeSettings;
                }
                
                // Fallback to local storage
                const stored = localStorage.getItem(this.storagePrefix + 'settings');
                return stored ? JSON.parse(stored) : this.getDefaultSettings();
            } catch (error) {
                console.warn('Failed to load settings:', error);
                return this.getDefaultSettings();
            }
        }

        async setSettings(settings) {
            try {
                // Save via bridge
                await this.bridge.updatePrivacySettings(settings);
                
                // Also save locally as backup
                localStorage.setItem(this.storagePrefix + 'settings', JSON.stringify(settings));
            } catch (error) {
                console.error('Failed to save settings via bridge:', error);
                
                // Fallback to local storage only
                localStorage.setItem(this.storagePrefix + 'settings', JSON.stringify(settings));
            }
        }

        getDefaultSettings() {
            return {
                emailMode: 'random',
                adMode: 'peaceful',
                autoDetection: true,
                naturalTyping: true,
                homeBase: null
            };
        }
    }

    // ========================================
    // Export for use by popup.js
    // ========================================
    
    window.AdvancementPopupBridge = AdvancementPopupBridge;
    window.EnhancedBaseDiscoveryService = EnhancedBaseDiscoveryService;
    window.EnhancedExtensionStorage = EnhancedExtensionStorage;

    console.log('🌉 Advancement popup-content bridge loaded');

})();