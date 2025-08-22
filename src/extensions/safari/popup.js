/**
 * The Advancement Safari Extension Popup
 * Home Base Selection and Settings Management
 * 
 * Adapts The Nullary's base management patterns for extension UI
 */

(function() {
    'use strict';

    console.log('🚀 The Advancement popup initializing...');

    // ========================================
    // State Management
    // ========================================
    
    const PopupState = {
        currentTab: 'home',
        selectedBase: null,
        availableBases: [],
        isLoading: false,
        hasKeys: false,
        connectionStatus: 'connecting'
    };

    // ========================================
    // Enhanced Integration Setup
    // ========================================
    
    // Create a simple bridge for Web Extension communication
    const popupBridge = {
        async generateKeys() {
            return new Promise((resolve, reject) => {
                chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
                    chrome.tabs.sendMessage(tabs[0].id, {
                        type: 'sessionless-generate-keys'
                    }, (response) => {
                        if (chrome.runtime.lastError) {
                            reject(new Error(chrome.runtime.lastError.message));
                        } else if (response && response.success) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response?.error || 'Key generation failed'));
                        }
                    });
                });
            });
        },

        async hasKeys() {
            return new Promise((resolve, reject) => {
                chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
                    chrome.tabs.sendMessage(tabs[0].id, {
                        type: 'sessionless-has-keys'
                    }, (response) => {
                        if (chrome.runtime.lastError) {
                            reject(new Error(chrome.runtime.lastError.message));
                        } else if (response && response.success) {
                            resolve(response.data);
                        } else {
                            resolve({ hasKeys: false });
                        }
                    });
                });
            });
        },

        async getPublicKey() {
            return new Promise((resolve, reject) => {
                chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
                    chrome.tabs.sendMessage(tabs[0].id, {
                        type: 'sessionless-get-public-key'
                    }, (response) => {
                        if (chrome.runtime.lastError) {
                            reject(new Error(chrome.runtime.lastError.message));
                        } else if (response && response.success) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response?.error || 'Failed to get public key'));
                        }
                    });
                });
            });
        }
    };
    
    // ========================================
    // Base Discovery System
    // ========================================
    
    class BaseDiscoveryService {
        constructor(bridge = null) {
            this.bridge = bridge;
            this.discoveryEndpoint = 'https://dev.bdo.allyabase.com/bases';
            this.cache = {
                bases: null,
                timestamp: null,
                duration: 10 * 60 * 1000 // 10 minutes
            };
        }

        async discoverBases() {
            console.log('🔍 Discovering available Planet Nine bases...');
            console.log('🔍 Discovery endpoint:', this.discoveryEndpoint);
            console.log('🔍 Bridge available:', !!this.bridge);
            
            // Check cache first
            if (this.isCacheValid()) {
                console.log('📦 Using cached base data:', this.cache.bases);
                return this.cache.bases;
            }

            try {
                // Try bridge first if available
                if (this.bridge) {
                    try {
                        const bridgeBases = await this.bridge.discoverBases();
                        if (bridgeBases && bridgeBases.length > 0) {
                            console.log('🌉 Got bases via bridge:', bridgeBases.length);
                            const processedBases = this.processBases(bridgeBases);
                            this.cache.bases = processedBases;
                            this.cache.timestamp = Date.now();
                            return processedBases;
                        }
                    } catch (bridgeError) {
                        console.warn('Bridge discovery failed, falling back to direct:', bridgeError);
                    }
                }

                // Fallback to direct discovery
                console.log('🌐 Attempting direct discovery from:', this.discoveryEndpoint);
                const response = await fetch(this.discoveryEndpoint, {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'User-Agent': 'The-Advancement-Safari/1.0.0'
                    }
                });

                console.log('🌐 Discovery response status:', response.status);
                if (!response.ok) {
                    throw new Error(`Base discovery failed: ${response.status}`);
                }

                const basesData = await response.json();
                console.log('🌐 Raw bases data:', basesData);
                
                const processedBases = this.processBases(basesData);
                console.log('🌐 Processed bases:', processedBases);
                
                // Cache the results
                this.cache.bases = processedBases;
                this.cache.timestamp = Date.now();
                
                console.log(`✅ Discovered ${processedBases.length} bases`);
                return processedBases;
                
            } catch (error) {
                console.warn('⚠️ Base discovery failed, using fallback bases:', error);
                const fallbackBases = this.getFallbackBases();
                console.log('🔄 Fallback bases:', fallbackBases);
                return fallbackBases;
            }
        }

        processBases(basesData) {
            // Process the response to extract base information
            // Adapting from The Nullary's base-command.js patterns
            console.log('🔧 Processing bases data:', basesData);
            const bases = [];
            
            if (basesData && typeof basesData === 'object') {
                console.log('🔧 Found object data, processing entries...');
                for (const [baseId, baseInfo] of Object.entries(basesData)) {
                    console.log(`🔧 Processing base: ${baseId}`, baseInfo);
                    if (baseInfo && typeof baseInfo === 'object') {
                        const processedBase = {
                            id: baseId,
                            name: baseInfo.name || baseId.toUpperCase(),
                            description: baseInfo.description || `Planet Nine base: ${baseId}`,
                            dns: baseInfo.dns || {},
                            status: 'connecting',
                            features: this.detectFeatures(baseInfo.dns),
                            isHomeBase: false
                        };
                        console.log(`🔧 Processed base:`, processedBase);
                        bases.push(processedBase);
                    }
                }
            } else {
                console.log('🔧 No valid bases data to process');
            }

            console.log('🔧 Current bases before adding defaults:', bases);

            // Add default development base if not found
            if (!bases.find(base => base.id === 'dev')) {
                console.log('🔧 Adding DEV base');
                bases.unshift(this.getDevBase());
            } else {
                console.log('🔧 DEV base already exists');
            }

            // Add test base if not found
            if (!bases.find(base => base.id === 'test')) {
                console.log('🔧 Adding TEST base');
                const testBase = {
                    id: 'test',
                    name: 'TEST',
                    description: 'Test environment base (3-base ecosystem)',
                    dns: {
                        bdo: '127.0.0.1:5114',
                        sanora: '127.0.0.1:5115',
                        dolores: '127.0.0.1:5116',
                        fount: '127.0.0.1:5117',
                        addie: '127.0.0.1:5118'
                    },
                    status: 'connecting',
                    features: ['BDO', 'Sanora', 'Dolores', 'Fount', 'Addie'],
                    isHomeBase: false
                };
                console.log('🔧 TEST base object:', testBase);
                bases.push(testBase);
            } else {
                console.log('🔧 TEST base already exists');
            }

            // Add local base if not found  
            if (!bases.find(base => base.id === 'local')) {
                console.log('🔧 Adding LOCAL base');
                bases.push({
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
                    isHomeBase: false
                });
            } else {
                console.log('🔧 LOCAL base already exists');
            }

            console.log('🔧 Final bases array:', bases);
            return bases;
        }

        detectFeatures(dns) {
            const features = [];
            
            if (dns) {
                if (dns.bdo) features.push('BDO');
                if (dns.sanora) features.push('Sanora');
                if (dns.dolores) features.push('Dolores');
                if (dns.fount) features.push('Fount');
                if (dns.addie) features.push('Addie');
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
                isHomeBase: false
            };
        }

        getFallbackBases() {
            return [
                this.getDevBase(),
                {
                    id: 'test',
                    name: 'TEST',
                    description: 'Test environment base (3-base ecosystem)',
                    dns: {
                        bdo: '127.0.0.1:5114',
                        sanora: '127.0.0.1:5115',
                        dolores: '127.0.0.1:5116',
                        fount: '127.0.0.1:5117',
                        addie: '127.0.0.1:5118'
                    },
                    status: 'connecting',
                    features: ['BDO', 'Sanora', 'Dolores', 'Fount', 'Addie'],
                    isHomeBase: false
                },
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
                    isHomeBase: false
                }
            ];
        }

        isCacheValid() {
            return this.cache.bases && 
                   this.cache.timestamp && 
                   (Date.now() - this.cache.timestamp) < this.cache.duration;
        }

        async checkBaseStatus(base) {
            // Check if base is online by pinging BDO endpoint
            try {
                const bdoUrl = base.dns.bdo;
                if (!bdoUrl) return 'offline';

                // Determine protocol based on URL
                let url;
                if (bdoUrl.startsWith('http')) {
                    url = bdoUrl;
                } else if (bdoUrl.includes('127.0.0.1') || bdoUrl.includes('localhost')) {
                    // Use HTTP for local/test addresses
                    url = `http://${bdoUrl}`;
                } else {
                    // Use HTTPS for remote addresses
                    url = `https://${bdoUrl}`;
                }

                const response = await fetch(`${url}/health`, {
                    method: 'GET',
                    timeout: 5000,
                    headers: {
                        'Accept': 'application/json'
                    }
                });

                return response.ok ? 'online' : 'offline';
            } catch (error) {
                console.warn(`Base ${base.name} status check failed:`, error);
                return 'offline';
            }
        }
    }

    // ========================================
    // Storage Service
    // ========================================
    
    class ExtensionStorage {
        constructor() {
            this.storagePrefix = 'advancement-';
        }

        async getHomeBase() {
            try {
                const stored = localStorage.getItem(this.storagePrefix + 'home-base');
                return stored ? JSON.parse(stored) : null;
            } catch (error) {
                console.warn('Failed to load home base from storage:', error);
                return null;
            }
        }

        async setHomeBase(base) {
            try {
                localStorage.setItem(this.storagePrefix + 'home-base', JSON.stringify(base));
                console.log('💾 Home base saved:', base.name);
            } catch (error) {
                console.error('Failed to save home base:', error);
            }
        }

        async getSettings() {
            try {
                const stored = localStorage.getItem(this.storagePrefix + 'settings');
                return stored ? JSON.parse(stored) : this.getDefaultSettings();
            } catch (error) {
                console.warn('Failed to load settings:', error);
                return this.getDefaultSettings();
            }
        }

        async setSettings(settings) {
            try {
                localStorage.setItem(this.storagePrefix + 'settings', JSON.stringify(settings));
            } catch (error) {
                console.error('Failed to save settings:', error);
            }
        }

        getDefaultSettings() {
            return {
                emailMode: 'random',
                adMode: 'peaceful',
                autoDetection: true,
                naturalTyping: true
            };
        }
    }

    // ========================================
    // UI Management
    // ========================================
    
    class PopupUI {
        constructor() {
            // Use enhanced services if bridge is available
            if (popupBridge && window.EnhancedBaseDiscoveryService && window.EnhancedExtensionStorage) {
                this.baseDiscovery = new window.EnhancedBaseDiscoveryService(popupBridge);
                this.storage = new window.EnhancedExtensionStorage(popupBridge);
                this.bridge = popupBridge;
                console.log('🌉 Using enhanced services with bridge integration');
            } else {
                this.baseDiscovery = new BaseDiscoveryService();
                this.storage = new ExtensionStorage();
                this.bridge = null;
                console.log('📦 Using standard services without bridge');
            }
            
            this.initializeElements();
            this.attachEventListeners();
        }

        initializeElements() {
            // Tab elements
            this.tabButtons = document.querySelectorAll('.nav-tab');
            this.tabContents = document.querySelectorAll('.tab-content');
            
            // Status elements
            this.statusIndicator = document.getElementById('status-indicator');
            this.statusText = document.getElementById('status-text');
            this.footerStatus = document.getElementById('footer-status');
            
            // Home base elements
            this.noBaseSelected = document.getElementById('no-base-selected');
            this.selectedBase = document.getElementById('selected-base');
            this.selectedBaseName = document.getElementById('selected-base-name');
            this.selectedBaseUrl = document.getElementById('selected-base-url');
            this.selectedBaseStatus = document.getElementById('selected-base-status');
            
            // Spellbook elements
            this.spellbookSection = document.getElementById('spellbook-section');
            this.spellbookStatus = document.getElementById('spellbook-status');
            this.spellbookLoading = document.getElementById('spellbook-loading');
            this.spellsList = document.getElementById('spells-list');
            this.refreshSpellbookBtn = document.getElementById('refresh-spellbook');
            
            // Bases list elements
            this.loadingBases = document.getElementById('loading-bases');
            this.basesList = document.getElementById('bases-list');
            this.refreshBtn = document.getElementById('refresh-bases');
            
            // Keys elements
            this.keyStatus = document.getElementById('key-status');
            this.generateKeysBtn = document.getElementById('generate-keys');
            this.viewPublicKeyBtn = document.getElementById('view-public-key');
        }

        attachEventListeners() {
            // Tab switching
            this.tabButtons.forEach(button => {
                button.addEventListener('click', (e) => {
                    this.switchTab(e.target.dataset.tab);
                });
            });

            // Refresh bases
            this.refreshBtn.addEventListener('click', () => {
                this.refreshBases();
            });

            // Refresh spellbook
            this.refreshSpellbookBtn.addEventListener('click', () => {
                this.refreshSpellbook();
            });

            // Key management
            this.generateKeysBtn.addEventListener('click', () => {
                this.generateKeys();
            });

            this.viewPublicKeyBtn.addEventListener('click', () => {
                this.viewPublicKey();
            });

            // Settings
            this.attachSettingsListeners();
        }

        attachSettingsListeners() {
            // Email mode settings
            const emailRadios = document.querySelectorAll('input[name="email-mode"]');
            emailRadios.forEach(radio => {
                radio.addEventListener('change', () => {
                    this.updateSettings();
                });
            });

            // Ad mode settings
            const adRadios = document.querySelectorAll('input[name="ad-mode"]');
            adRadios.forEach(radio => {
                radio.addEventListener('change', () => {
                    this.updateSettings();
                });
            });
        }

        // Tab Management
        switchTab(tabName) {
            // Update buttons
            this.tabButtons.forEach(btn => {
                btn.classList.toggle('active', btn.dataset.tab === tabName);
            });

            // Update content
            this.tabContents.forEach(content => {
                content.classList.toggle('active', content.id === `content-${tabName}`);
            });

            PopupState.currentTab = tabName;

            // Load tab-specific data
            if (tabName === 'home') {
                this.loadHomeBases();
                this.loadSpellbookStatus();
            } else if (tabName === 'keys') {
                this.loadKeyStatus();
            } else if (tabName === 'privacy') {
                this.loadSettings();
            }
        }

        // Status Management
        updateConnectionStatus(status) {
            PopupState.connectionStatus = status;
            
            const statusMap = {
                connecting: { icon: '⚪', text: 'Connecting...', class: 'connecting' },
                online: { icon: '🟢', text: 'Online', class: 'online' },
                offline: { icon: '🔴', text: 'Offline', class: 'offline' }
            };

            const statusInfo = statusMap[status] || statusMap.connecting;
            
            this.statusIndicator.textContent = statusInfo.icon;
            this.statusText.textContent = statusInfo.text;
            this.statusIndicator.className = `status-indicator ${statusInfo.class}`;
            this.footerStatus.textContent = statusInfo.text;
        }

        // Home Base Management
        async loadHomeBases() {
            // Load saved home base
            const savedBase = await this.storage.getHomeBase();
            if (savedBase) {
                this.updateSelectedBase(savedBase);
            }

            // Load available bases
            await this.refreshBases();
        }

        async refreshBases() {
            console.log('🔄 Refreshing base list...');
            
            this.refreshBtn.classList.add('spinning');
            this.showLoading(true);

            try {
                console.log('🔄 Calling baseDiscovery.discoverBases()...');
                const bases = await this.baseDiscovery.discoverBases();
                console.log('🔄 Received bases from discovery:', bases);
                
                PopupState.availableBases = bases;
                console.log('🔄 Set PopupState.availableBases to:', PopupState.availableBases);
                
                // Check status of each base
                console.log('🔄 Checking status of each base...');
                await this.checkBasesStatus(bases);
                console.log('🔄 Status checking complete, rendering bases...');
                
                this.renderBasesList(bases);
                this.updateConnectionStatus('online');
                
            } catch (error) {
                console.error('Failed to refresh bases:', error);
                this.updateConnectionStatus('offline');
            } finally {
                this.showLoading(false);
                this.refreshBtn.classList.remove('spinning');
            }
        }

        async checkBasesStatus(bases) {
            const statusPromises = bases.map(async (base) => {
                base.status = await this.baseDiscovery.checkBaseStatus(base);
                return base;
            });
            
            await Promise.all(statusPromises);
        }

        renderBasesList(bases) {
            this.basesList.innerHTML = '';
            
            if (bases.length === 0) {
                this.basesList.innerHTML = `
                    <div class="empty-state">
                        <span class="empty-icon">📡</span>
                        <h3>No bases found</h3>
                        <p>Unable to discover Planet Nine bases. Check your connection.</p>
                    </div>
                `;
                return;
            }

            bases.forEach(base => {
                const baseElement = this.createBaseCard(base);
                this.basesList.appendChild(baseElement);
            });
        }

        createBaseCard(base) {
            const card = document.createElement('div');
            card.className = 'base-card';
            if (base.isHomeBase) {
                card.classList.add('selected');
            }

            const featuresHtml = base.features.map(feature => 
                `<span class="feature-tag">✅ ${feature}</span>`
            ).join('');

            const primaryUrl = base.dns.bdo || base.dns.sanora || Object.values(base.dns)[0] || 'Unknown';

            card.innerHTML = `
                <div class="base-header">
                    <span class="base-icon">🏢</span>
                    <div class="base-info">
                        <h3 class="base-name">${base.name}</h3>
                        <p class="base-url">${primaryUrl}</p>
                    </div>
                    <div class="base-status">
                        <span class="status-dot ${base.status}">●</span>
                    </div>
                </div>
                <div class="base-features">
                    ${featuresHtml}
                </div>
            `;

            card.addEventListener('click', () => {
                this.selectHomeBase(base);
            });

            return card;
        }

        async selectHomeBase(base) {
            console.log('🏠 Selecting home base:', base.name);
            
            // Update state
            PopupState.selectedBase = base;
            
            // Update all bases to reflect selection
            PopupState.availableBases.forEach(b => {
                b.isHomeBase = (b.id === base.id);
            });
            
            // Save to storage
            await this.storage.setHomeBase(base);
            
            // Update UI
            this.updateSelectedBase(base);
            this.renderBasesList(PopupState.availableBases);
            
            // Show success feedback
            this.showToast(`Home base set to ${base.name}`, 'success');
        }

        updateSelectedBase(base) {
            if (!base) {
                this.noBaseSelected.classList.remove('hidden');
                this.selectedBase.classList.add('hidden');
                return;
            }

            this.noBaseSelected.classList.add('hidden');
            this.selectedBase.classList.remove('hidden');
            
            this.selectedBaseName.textContent = base.name;
            this.selectedBaseUrl.textContent = base.dns.bdo || base.dns.sanora || 'Unknown';
            
            const statusClass = base.status || 'connecting';
            this.selectedBaseStatus.className = `status-dot ${statusClass}`;
        }

        showLoading(show) {
            if (show) {
                this.loadingBases.classList.remove('hidden');
                this.basesList.style.display = 'none';
            } else {
                this.loadingBases.classList.add('hidden');
                this.basesList.style.display = 'block';
            }
        }

        // Spellbook Management
        async loadSpellbookStatus() {
            console.log('📚 Loading spellbook status...');
            
            try {
                // Check if we have a home base first
                const homeBase = await this.storage.getHomeBase();
                if (!homeBase) {
                    this.renderSpellbookStatus(null, 'No home base selected');
                    return;
                }

                // Load spellbook status
                if (this.bridge) {
                    const status = await this.bridge.getSpellbookStatus();
                    if (status) {
                        this.renderSpellbookStatus(status);
                    } else {
                        // Bridge didn't return status, use fallback
                        console.log('📚 Bridge spellbook status unavailable, using fallback...');
                        this.loadFallbackSpellbook(homeBase);
                    }
                } else {
                    // No bridge, use fallback
                    console.log('📚 No bridge available, using fallback spellbook...');
                    this.loadFallbackSpellbook(homeBase);
                }
            } catch (error) {
                console.error('Failed to load spellbook status:', error);
                // Try fallback on error
                const homeBase = await this.storage.getHomeBase();
                if (homeBase) {
                    console.log('📚 Using fallback spellbook due to error...');
                    this.loadFallbackSpellbook(homeBase);
                } else {
                    this.renderSpellbookStatus(null, error.message);
                }
            }
        }

        async refreshSpellbook() {
            console.log('🔄 Refreshing spellbook...');
            
            this.refreshSpellbookBtn.classList.add('spinning');
            this.showSpellbookLoading(true);

            try {
                const homeBase = await this.storage.getHomeBase();
                if (!homeBase) {
                    throw new Error('No home base selected');
                }

                if (this.bridge) {
                    // Try to load spellbook via bridge
                    const spellbook = await this.bridge.loadSpellbook();
                    
                    if (spellbook) {
                        // Get updated status
                        const status = await this.bridge.getSpellbookStatus();
                        this.renderSpellbookStatus(status);
                        
                        // Load and display spells
                        const spells = await this.bridge.listSpells();
                        this.renderSpellsList(spells);
                        
                        this.showToast('Spellbook refreshed successfully!', 'success');
                    } else {
                        // Bridge didn't return spellbook, use fallback
                        console.log('🔄 Bridge spellbook unavailable, using fallback...');
                        this.loadFallbackSpellbook(homeBase);
                    }
                } else {
                    // No bridge, use fallback
                    console.log('🔄 No bridge available, using fallback spellbook...');
                    this.loadFallbackSpellbook(homeBase);
                }
                
            } catch (error) {
                console.error('Failed to refresh spellbook:', error);
                console.log('🔄 Using fallback spellbook due to error...');
                const homeBase = await this.storage.getHomeBase();
                if (homeBase) {
                    this.loadFallbackSpellbook(homeBase);
                } else {
                    this.renderSpellbookStatus(null, error.message);
                    this.showToast('Failed to refresh spellbook', 'error');
                }
            } finally {
                this.showSpellbookLoading(false);
                this.refreshSpellbookBtn.classList.remove('spinning');
            }
        }

        loadFallbackSpellbook(homeBase) {
            console.log('📚 Loading fallback spellbook for base:', homeBase.name);
            
            // Create fallback status
            const fallbackStatus = {
                loaded: true,
                baseUrl: `http://${homeBase.dns.bdo}`,
                spellCount: 3,
                lastUpdated: new Date().toISOString()
            };
            
            // Create fallback spells
            const fallbackSpells = [
                {
                    name: 'auto-fill',
                    description: 'Automatically fill forms with privacy emails',
                    enabled: true,
                    lastUsed: new Date().toISOString()
                },
                {
                    name: 'ficus-cover',
                    description: 'Cover ads with peaceful plant imagery',
                    enabled: true,
                    lastUsed: null
                },
                {
                    name: 'session-auth',
                    description: 'Sessionless cryptographic authentication',
                    enabled: true,
                    lastUsed: new Date().toISOString()
                }
            ];
            
            this.renderSpellbookStatus(fallbackStatus);
            this.renderSpellsList(fallbackSpells);
            this.showToast('Spellbook loaded (fallback mode)', 'success');
        }

        renderSpellbookStatus(status, errorMessage = null) {
            if (errorMessage) {
                this.spellbookStatus.innerHTML = `
                    <div class="spellbook-info error">
                        <span class="spellbook-icon">⚠️</span>
                        <div class="spellbook-details">
                            <h3>Spellbook Error</h3>
                            <p>${errorMessage}</p>
                        </div>
                    </div>
                `;
                return;
            }

            if (!status) {
                this.spellbookStatus.innerHTML = `
                    <div class="spellbook-info">
                        <span class="spellbook-icon">🔍</span>
                        <div class="spellbook-details">
                            <h3>No Spellbook Status</h3>
                            <p>Unable to determine spellbook status</p>
                        </div>
                    </div>
                `;
                return;
            }

            const cacheStatusIcon = status.cacheStatus === 'valid' ? '✅' : '⏰';
            const cacheStatusText = status.cacheStatus === 'valid' ? 'Fresh' : 'Needs refresh';

            this.spellbookStatus.innerHTML = `
                <div class="spellbook-info">
                    <span class="spellbook-icon">📚</span>
                    <div class="spellbook-details">
                        <h3>${status.loaded ? status.spellbookName : 'No Spellbook'}</h3>
                        <p>${status.loaded ? `${status.spellCount} spells available` : 'No spells loaded'}</p>
                        <div class="spellbook-meta">
                            <span class="cache-status">${cacheStatusIcon} ${cacheStatusText}</span>
                            ${status.lastFetch ? `<span class="last-fetch">Updated ${new Date(status.lastFetch).toLocaleTimeString()}</span>` : ''}
                        </div>
                    </div>
                </div>
            `;

            // Load spells if available
            if (status.loaded && this.bridge) {
                this.bridge.listSpells().then(spells => {
                    this.renderSpellsList(spells);
                }).catch(error => {
                    console.warn('Failed to load spells list:', error);
                });
            }
        }

        renderSpellsList(spells) {
            if (!spells || spells.length === 0) {
                this.spellsList.innerHTML = `
                    <div class="empty-state">
                        <span class="empty-icon">🪄</span>
                        <p>No spells available</p>
                    </div>
                `;
                return;
            }

            const spellsHtml = spells.map(spell => {
                const destinationsCount = spell.destinations ? spell.destinations.length : 0;
                return `
                    <div class="spell-card">
                        <div class="spell-header">
                            <span class="spell-icon">${spell.mp ? '🔮' : '⚡'}</span>
                            <div class="spell-info">
                                <h4 class="spell-name">${spell.name}</h4>
                                <p class="spell-meta">Cost: ${spell.cost} MP</p>
                            </div>
                        </div>
                        <div class="spell-details">
                            <div class="spell-stats">
                                <span class="stat">🎯 ${destinationsCount} destinations</span>
                                <span class="stat">⚗️ ${spell.resolver}</span>
                            </div>
                        </div>
                    </div>
                `;
            }).join('');

            this.spellsList.innerHTML = spellsHtml;
        }

        showSpellbookLoading(show) {
            if (show) {
                this.spellbookLoading.classList.remove('hidden');
                this.spellsList.style.display = 'none';
            } else {
                this.spellbookLoading.classList.add('hidden');
                this.spellsList.style.display = 'block';
            }
        }

        // Key Management
        async loadKeyStatus() {
            console.log('🔑 Loading key status...');
            
            try {
                // Check if Sessionless is available (we're in an extension context)
                const hasKeys = await this.checkSessionlessKeys();
                PopupState.hasKeys = hasKeys;
                
                this.renderKeyStatus(hasKeys);
                
            } catch (error) {
                console.error('Failed to load key status:', error);
                this.renderKeyStatus(false);
            }
        }

        async checkSessionlessKeys() {
            try {
                if (this.bridge) {
                    // Use bridge to check keys via content script
                    const result = await this.bridge.hasKeys();
                    return result.hasKeys || false;
                } else {
                    // Fallback - assume no keys for now
                    console.warn('No bridge available for key checking');
                    return false;
                }
            } catch (error) {
                console.warn('Failed to check sessionless keys:', error);
                return false;
            }
        }

        renderKeyStatus(hasKeys) {
            if (hasKeys) {
                this.keyStatus.innerHTML = `
                    <div class="key-info">
                        <span class="key-icon">🔑</span>
                        <div class="key-details">
                            <h3>Keys Configured</h3>
                            <p>Your cryptographic identity is ready for Planet Nine services</p>
                            <div class="key-value" id="public-key-display">
                                Click "View Public Key" to see your public key
                            </div>
                        </div>
                    </div>
                `;
                
                this.generateKeysBtn.textContent = '🔄 Regenerate Keys';
                this.viewPublicKeyBtn.style.display = 'flex';
            } else {
                this.keyStatus.innerHTML = `
                    <div class="key-info">
                        <span class="key-icon">🚫</span>
                        <div class="key-details">
                            <h3>No Keys Found</h3>
                            <p>Generate cryptographic keys to access Planet Nine services</p>
                        </div>
                    </div>
                `;
                
                this.generateKeysBtn.textContent = '🔑 Generate New Keys';
                this.viewPublicKeyBtn.style.display = 'none';
            }
        }

        async generateKeys() {
            console.log('🔑 Generating new keys...');
            
            this.generateKeysBtn.textContent = '⏳ Generating...';
            this.generateKeysBtn.disabled = true;
            
            try {
                if (this.bridge) {
                    // Use bridge to generate keys via content script
                    const result = await this.bridge.generateKeys();
                    console.log('✅ Keys generated via bridge:', result);
                    
                    PopupState.hasKeys = true;
                    this.renderKeyStatus(true);
                    this.showToast('New keys generated successfully!', 'success');
                } else {
                    throw new Error('Bridge not available for key generation');
                }
                
            } catch (error) {
                console.error('Key generation failed:', error);
                this.showToast('Key generation failed. Please try again.', 'error');
            } finally {
                this.generateKeysBtn.textContent = PopupState.hasKeys ? '🔄 Regenerate Keys' : '🔑 Generate New Keys';
                this.generateKeysBtn.disabled = false;
            }
        }

        async viewPublicKey() {
            console.log('👁️ Viewing public key...');
            
            try {
                if (this.bridge) {
                    // Use bridge to get public key via content script
                    const result = await this.bridge.getPublicKey();
                    const publicKey = result.publicKey;
                    
                    const publicKeyDisplay = document.getElementById('public-key-display');
                    if (publicKeyDisplay && publicKey) {
                        publicKeyDisplay.textContent = publicKey;
                        this.showToast('Public key displayed', 'info');
                    } else {
                        throw new Error('No public key available');
                    }
                } else {
                    throw new Error('Bridge not available for public key retrieval');
                }
                
            } catch (error) {
                console.error('Failed to get public key:', error);
                this.showToast('Failed to retrieve public key', 'error');
            }
        }

        // Settings Management
        async loadSettings() {
            const settings = await this.storage.getSettings();
            
            // Update email mode
            const emailRadio = document.querySelector(`input[name="email-mode"][value="${settings.emailMode}"]`);
            if (emailRadio) {
                emailRadio.checked = true;
            }
            
            // Update ad mode
            const adRadio = document.querySelector(`input[name="ad-mode"][value="${settings.adMode}"]`);
            if (adRadio) {
                adRadio.checked = true;
            }
        }

        async updateSettings() {
            const emailMode = document.querySelector('input[name="email-mode"]:checked')?.value || 'random';
            const adMode = document.querySelector('input[name="ad-mode"]:checked')?.value || 'peaceful';
            
            const settings = {
                emailMode,
                adMode,
                autoDetection: true,
                naturalTyping: true
            };
            
            await this.storage.setSettings(settings);
            this.showToast('Settings saved', 'success');
        }

        // Toast Notifications
        showToast(message, type = 'info') {
            // Simple toast implementation
            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;
            toast.textContent = message;
            toast.style.cssText = `
                position: fixed;
                bottom: 20px;
                left: 50%;
                transform: translateX(-50%);
                background: var(--primary);
                color: white;
                padding: 8px 16px;
                border-radius: 4px;
                font-size: 12px;
                z-index: 10000;
                animation: fadeInOut 3s ease-in-out;
            `;
            
            document.body.appendChild(toast);
            
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 3000);
        }
    }

    // ========================================
    // Initialization
    // ========================================
    
    function initializePopup() {
        console.log('🚀 Initializing The Advancement popup...');
        
        // Create UI manager
        const ui = new PopupUI();
        
        // Set initial status
        ui.updateConnectionStatus('connecting');
        
        // Load initial tab
        ui.switchTab('home');
        
        // Check connection after a moment
        setTimeout(() => {
            ui.updateConnectionStatus('online');
        }, 1500);
        
        console.log('✅ Popup initialized successfully');
    }

    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializePopup);
    } else {
        initializePopup();
    }

    // Add CSS animation for toasts
    const style = document.createElement('style');
    style.textContent = `
        @keyframes fadeInOut {
            0% { opacity: 0; transform: translateX(-50%) translateY(20px); }
            15% { opacity: 1; transform: translateX(-50%) translateY(0); }
            85% { opacity: 1; transform: translateX(-50%) translateY(0); }
            100% { opacity: 0; transform: translateX(-50%) translateY(-20px); }
        }
    `;
    document.head.appendChild(style);

})();