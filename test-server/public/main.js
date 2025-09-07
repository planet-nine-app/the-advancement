/**
 * Main Application Controller for Planet Nine Test Store
 * 
 * Coordinates all aspects of the test application:
 * - Integration with The Advancement extension
 * - Teleportation client management
 * - Purchase flow coordination
 * - Real-time status updates
 */

class TestStoreApp {
    constructor() {
        this.initialized = false;
        this.advancementDetected = false;
        this.sessionlessReady = false;
        
        this.initializeApp();
    }

    async initializeApp() {
        console.log('🚀 Initializing Planet Nine Test Store...');
        
        try {
            // Wait for DOM to be ready
            await this.waitForDOM();
            
            // Set up global event listeners
            this.setupGlobalEventListeners();
            
            // Check for The Advancement extension
            this.checkForAdvancement();
            
            // Monitor extension readiness
            this.monitorExtensionReadiness();
            
            // Initialize components
            await this.initializeComponents();
            
            this.initialized = true;
            console.log('✅ Test store initialized successfully');
            
        } catch (error) {
            console.error('❌ Failed to initialize test store:', error);
            this.showGlobalError('Failed to initialize application. Please refresh the page.');
        }
    }

    async waitForDOM() {
        return new Promise((resolve) => {
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', resolve);
            } else {
                resolve();
            }
        });
    }

    setupGlobalEventListeners() {
        // Listen for Advancement extension events
        document.addEventListener('advancementReady', (event) => {
            console.log('🚀 The Advancement extension ready:', event.detail);
            this.handleAdvancementReady(event.detail);
        });

        document.addEventListener('sessionlessReady', (event) => {
            console.log('🔐 Sessionless ready:', event.detail);
            this.handleSessionlessReady(event.detail);
        });

        // Listen for purchase events
        document.addEventListener('purchaseCompleted', (event) => {
            console.log('🎉 Purchase completed:', event.detail);
            this.handlePurchaseCompleted(event.detail);
        });

        // Listen for visibility changes (tab switching)
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden && this.initialized) {
                this.handleVisibilityChange();
            }
        });

        // Listen for online/offline status
        window.addEventListener('online', () => {
            console.log('🌐 Back online');
            this.handleOnlineStatusChange(true);
        });

        window.addEventListener('offline', () => {
            console.log('📴 Gone offline');
            this.handleOnlineStatusChange(false);
        });

        // Global error handling
        window.addEventListener('error', (event) => {
            console.error('Global error:', event.error);
            this.handleGlobalError(event.error);
        });

        window.addEventListener('unhandledrejection', (event) => {
            console.error('Unhandled promise rejection:', event.reason);
            this.handleGlobalError(event.reason);
        });
    }

    checkForAdvancement() {
        // Check if The Advancement extension is available
        if (typeof window.AdvancementExtension !== 'undefined') {
            console.log('✅ The Advancement extension detected immediately');
            this.advancementDetected = true;
            this.updateAdvancementStatus();
        } else {
            console.log('⏳ Waiting for The Advancement extension...');
            
            // Poll for The Advancement extension for up to 10 seconds
            let checks = 0;
            const maxChecks = 50; // 10 seconds with 200ms intervals
            
            const checkInterval = setInterval(() => {
                checks++;
                
                if (typeof window.AdvancementExtension !== 'undefined') {
                    console.log('✅ The Advancement extension detected after polling');
                    this.advancementDetected = true;
                    this.updateAdvancementStatus();
                    clearInterval(checkInterval);
                } else if (checks >= maxChecks) {
                    console.log('⚠️ The Advancement extension not found after 10 seconds');
                    this.updateAdvancementStatus();
                    clearInterval(checkInterval);
                }
            }, 200);
        }
    }

    monitorExtensionReadiness() {
        // Monitor for Sessionless readiness
        if (typeof window.Sessionless !== 'undefined') {
            console.log('✅ Sessionless detected immediately');
            this.sessionlessReady = true;
        } else {
            // Wait for sessionless to become available
            let checks = 0;
            const maxChecks = 25; // 5 seconds
            
            const checkInterval = setInterval(() => {
                checks++;
                
                if (typeof window.Sessionless !== 'undefined') {
                    console.log('✅ Sessionless detected after polling');
                    this.sessionlessReady = true;
                    
                    // Dispatch ready event
                    document.dispatchEvent(new CustomEvent('sessionlessReady', {
                        detail: {
                            version: window.Sessionless.version,
                            isNative: window.Sessionless.isNative
                        }
                    }));
                    
                    clearInterval(checkInterval);
                } else if (checks >= maxChecks) {
                    console.log('⚠️ Sessionless not found after 5 seconds');
                    clearInterval(checkInterval);
                }
            }, 200);
        }
    }

    async initializeComponents() {
        console.log('🔧 Initializing app components...');
        
        // Set up siteContributors for spell integration
        this.setupSiteContributors();
        
        // Initialize nineum balance system
        await this.initializeNineumBalance();
        
        // Initialize magistack testing functionality
        this.initializeMagistackTesting();
        
        // Components are initialized by their own scripts:
        // - teleportationClient (teleportation-client.js)
        // - purchaseFlow (purchase-flow.js)
        
        // Wait a moment for them to initialize
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Verify components are available
        if (typeof window.teleportationClient === 'undefined') {
            console.warn('⚠️ Teleportation client not found');
        }
        
        if (typeof window.purchaseFlow === 'undefined') {
            console.warn('⚠️ Purchase flow not found');
        }
        
        console.log('✅ Component initialization complete');
    }

    // Event Handlers
    handleAdvancementReady(detail) {
        this.advancementDetected = true;
        this.updateAdvancementStatus();
        
        // Update features based on Advancement capabilities
        this.updateFeatureAvailability();
        
        // Show welcome message for first-time users
        if (this.isFirstTimeUser()) {
            this.showWelcomeMessage();
        }
    }

    handleSessionlessReady(detail) {
        this.sessionlessReady = true;
        console.log(`🔐 Sessionless v${detail.version} ready (native: ${detail.isNative})`);
        
        // Update UI to reflect Sessionless availability
        this.updateSessionlessStatus();
    }

    handlePurchaseCompleted(detail) {
        console.log('🎉 Purchase completed in main app:', detail);
        
        // Update any relevant UI
        this.updateAfterPurchase(detail);
        
        // Send to analytics (if implemented)
        this.trackEvent('purchase_completed', detail);
    }

    handleVisibilityChange() {
        console.log('👁️ Tab became visible, refreshing status...');
        
        // Refresh status when user returns to tab
        this.refreshApplicationStatus();
    }

    handleOnlineStatusChange(isOnline) {
        console.log(`🌐 Network status: ${isOnline ? 'online' : 'offline'}`);
        
        // Update UI based on network status
        this.updateNetworkStatus(isOnline);
        
        if (isOnline && this.initialized) {
            // Refresh content when back online
            this.refreshContentAfterReconnect();
        }
    }

    handleGlobalError(error) {
        // Don't spam the console with minor errors
        if (error.message && error.message.includes('Non-Error promise rejection captured')) {
            return;
        }
        
        console.error('Handling global error:', error);
        
        // Show user-friendly error message
        this.showGlobalError('An unexpected error occurred. Some features may not work properly.');
    }

    // Status Update Methods
    updateAdvancementStatus() {
        const statusElement = document.getElementById('advancement-status');
        const indicatorElement = document.getElementById('status-indicator');
        const textElement = document.getElementById('status-text');
        
        if (this.advancementDetected) {
            indicatorElement.className = 'status-indicator online';
            indicatorElement.textContent = '🟢';
            textElement.textContent = 'The Advancement Connected';
            statusElement.title = 'The Advancement browser extension is active';
        } else {
            indicatorElement.className = 'status-indicator offline';
            indicatorElement.textContent = '🔴';
            textElement.textContent = 'The Advancement Not Found';
            statusElement.title = 'Please install The Advancement browser extension';
        }
    }

    updateSessionlessStatus() {
        // Update any Sessionless-specific UI elements
        console.log('🔐 Updating Sessionless status in UI');
    }

    updateFeatureAvailability() {
        // Enable/disable features based on The Advancement availability
        const networkDependentElements = document.querySelectorAll('[data-requires-advancement]');
        
        networkDependentElements.forEach(element => {
            if (this.advancementDetected) {
                element.removeAttribute('disabled');
                element.classList.remove('disabled');
            } else {
                element.setAttribute('disabled', 'true');
                element.classList.add('disabled');
            }
        });
    }

    updateNetworkStatus(isOnline) {
        document.body.classList.toggle('offline', !isOnline);
        
        if (!isOnline) {
            this.showToast('You are offline. Some features may not work.', 'warning');
        }
    }

    // Utility Methods
    isFirstTimeUser() {
        return !localStorage.getItem('advancement-test-store-visited');
    }

    showWelcomeMessage() {
        localStorage.setItem('advancement-test-store-visited', 'true');
        
        setTimeout(() => {
            this.showToast('Welcome! The Advancement extension is connected. Try purchasing a teleported product.', 'success');
        }, 1000);
    }

    async refreshApplicationStatus() {
        try {
            // Re-check The Advancement status
            this.checkForAdvancement();
            
            // Refresh teleported content if available
            if (window.teleportationClient && window.teleportationClient.refreshTeleportedContent) {
                await window.teleportationClient.refreshTeleportedContent();
            }
            
        } catch (error) {
            console.error('Failed to refresh application status:', error);
        }
    }

    async refreshContentAfterReconnect() {
        try {
            console.log('🔄 Refreshing content after reconnecting...');
            
            // Refresh teleported content
            if (window.teleportationClient) {
                await window.teleportationClient.refreshTeleportedContent();
            }
            
            this.showToast('Content refreshed after reconnecting', 'info');
            
        } catch (error) {
            console.error('Failed to refresh content after reconnect:', error);
        }
    }

    updateAfterPurchase(purchaseDetail) {
        // Could update purchase history, user balance, etc.
        console.log('📊 Updating UI after purchase:', purchaseDetail);
    }

    trackEvent(eventName, data) {
        // Analytics tracking
        console.log(`📊 Event: ${eventName}`, data);
        
        // In production, this would send to analytics service
        if (window.gtag) {
            window.gtag('event', eventName, data);
        }
    }

    // Toast Notifications
    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        
        const container = document.getElementById('toast-container');
        if (container) {
            container.appendChild(toast);
            
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 5000);
        }
    }

    showGlobalError(message) {
        this.showToast(message, 'error');
    }

    // Debug Methods (for development)
    getDebugInfo() {
        return {
            initialized: this.initialized,
            advancementDetected: this.advancementDetected,
            sessionlessReady: this.sessionlessReady,
            teleportationClient: typeof window.teleportationClient !== 'undefined',
            purchaseFlow: typeof window.purchaseFlow !== 'undefined',
            components: {
                AdvancementExtension: typeof window.AdvancementExtension !== 'undefined',
                Sessionless: typeof window.Sessionless !== 'undefined',
                Stripe: typeof window.Stripe !== 'undefined'
            }
        };
    }

    async initializeNineumBalance() {
        console.log('⭐ Initializing nineum balance from fount user...');
        
        try {
            // Fetch real nineum balance from fount user
            const response = await fetch('/api/nineum-balance');
            const result = await response.json();
            
            if (result.success) {
                this.nineumBalance = result.data.nineumCount;
                console.log(`⭐ Nineum balance loaded from fount: ${this.nineumBalance} (User: ${result.data.uuid})`);
            } else {
                // Fallback to localStorage or default
                const savedBalance = localStorage.getItem('advancement-nineum-balance');
                this.nineumBalance = result.fallbackBalance || (savedBalance ? parseInt(savedBalance, 10) : 0);
                console.log(`⚠️ Using fallback nineum balance: ${this.nineumBalance} (${result.error})`);
            }
        } catch (error) {
            console.error('❌ Failed to fetch nineum balance from fount:', error);
            // Fallback to localStorage or default
            const savedBalance = localStorage.getItem('advancement-nineum-balance');
            this.nineumBalance = savedBalance ? parseInt(savedBalance, 10) : 0;
            console.log(`⚠️ Using localStorage fallback: ${this.nineumBalance}`);
        }
        
        this.updateNineumDisplay();
        
        // Set up automatic balance refresh every 30 seconds
        this.startNineumBalanceRefresh();
        
        // Listen for nineum updates from spell casting
        document.addEventListener('nineum-earned', (event) => {
            this.addNineum(event.detail.amount, event.detail.source);
        });
        
        // Expose nineum management globally for The Advancement
        window.NineumManager = {
            getBalance: () => this.nineumBalance,
            addNineum: (amount, source) => this.addNineum(amount, source),
            setBalance: (amount) => this.setNineumBalance(amount),
            refresh: () => this.refreshNineumBalance()
        };
    }

    updateNineumDisplay() {
        const nineumAmountElement = document.getElementById('nineum-amount');
        if (nineumAmountElement) {
            nineumAmountElement.textContent = this.nineumBalance.toLocaleString();
            
            // Add visual effect for balance changes
            nineumAmountElement.style.animation = 'none';
            setTimeout(() => {
                nineumAmountElement.style.animation = 'sparkle 0.8s ease-out';
            }, 10);
        }
    }

    addNineum(amount, source = 'spell casting') {
        const previousBalance = this.nineumBalance;
        this.nineumBalance += amount;
        
        console.log(`⭐ Nineum earned! +${amount} from ${source} (${previousBalance} → ${this.nineumBalance})`);
        
        // Save to localStorage
        localStorage.setItem('advancement-nineum-balance', this.nineumBalance.toString());
        
        // Update display with animation
        this.updateNineumDisplay();
        
        // Show toast notification
        this.showToast(`+${amount} Nineum earned from ${source}!`, 'success');
        
        // Update spell info if visible
        this.updateSpellStatusAfterEarning();
    }

    setNineumBalance(amount) {
        this.nineumBalance = amount;
        localStorage.setItem('advancement-nineum-balance', amount.toString());
        this.updateNineumDisplay();
    }

    startNineumBalanceRefresh() {
        // Refresh nineum balance every 30 seconds
        this.nineumRefreshInterval = setInterval(() => {
            this.refreshNineumBalance();
        }, 30000);
        
        console.log('⭐ Nineum balance auto-refresh started (every 30 seconds)');
    }

    async refreshNineumBalance() {
        try {
            const response = await fetch('/api/nineum-balance');
            const result = await response.json();
            
            if (result.success) {
                const oldBalance = this.nineumBalance;
                this.nineumBalance = result.data.nineumCount;
                
                if (oldBalance !== this.nineumBalance) {
                    console.log(`⭐ Nineum balance updated: ${oldBalance} → ${this.nineumBalance}`);
                    this.updateNineumDisplay();
                    
                    // Show notification if balance increased
                    if (this.nineumBalance > oldBalance) {
                        const earned = this.nineumBalance - oldBalance;
                        this.showToast(`+${earned} Nineum earned!`, 'success');
                    }
                }
            } else {
                console.log('⚠️ Failed to refresh nineum balance:', result.error);
            }
        } catch (error) {
            console.error('❌ Nineum balance refresh failed:', error);
        }
    }

    updateSpellStatusAfterEarning() {
        const spellStatusElement = document.getElementById('spell-status');
        if (spellStatusElement) {
            spellStatusElement.textContent = 'Spell cast successfully! Nineum earned.';
            spellStatusElement.style.color = 'var(--secondary)';
            
            // Reset status after a moment
            setTimeout(() => {
                spellStatusElement.textContent = 'Ready to cast (siteContributors configured)';
            }, 3000);
        }
    }

    setupSiteContributors() {
        // Set up siteContributors window variable for spell integration
        // This allows the site owner to participate in spell transactions
        window.siteContributors = [
            {
                contributor: '0x1234567890abcdef1234567890abcdef12345678901234567890abcdef12345678', // Site owner pubKey
                percent: 0.1 // 10% of spell transaction
            }
        ];
        
        console.log('🪄 Site contributors configured for spell integration:', window.siteContributors);
        
        // Update spell status indicator
        const spellStatusElement = document.getElementById('spell-status');
        if (spellStatusElement) {
            spellStatusElement.textContent = 'Ready to cast (siteContributors configured)';
            spellStatusElement.style.color = 'var(--secondary)';
        }
    }

    initializeMagistackTesting() {
        console.log('🃏 Initializing magistack testing functionality...');
        
        const loadButton = document.getElementById('load-magistack-btn');
        const inputField = document.getElementById('bdo-pubkey-input');
        const statusElement = document.getElementById('magistack-status-message');
        const displayElement = document.getElementById('magistack-display');
        
        if (!loadButton || !inputField) {
            console.warn('⚠️ Magistack testing elements not found');
            return;
        }
        
        // Set up load magistack button handler
        loadButton.addEventListener('click', async () => {
            const bdoPubKey = inputField.value.trim();
            
            if (!bdoPubKey) {
                this.updateMagistackStatus('error', '❌', 'Please enter a BDO public key');
                return;
            }
            
            await this.loadMagistackFromBDO(bdoPubKey);
        });
        
        // Set up Enter key handler for input field
        inputField.addEventListener('keypress', (event) => {
            if (event.key === 'Enter') {
                loadButton.click();
            }
        });
        
        console.log('✅ Magistack testing initialized');
    }
    
    async loadMagistackFromBDO(bdoPubKey) {
        console.log(`🃏 Loading magistack with BDO pubKey: ${bdoPubKey}`);
        
        const loadButton = document.getElementById('load-magistack-btn');
        const originalText = loadButton.textContent;
        
        try {
            // Update UI to loading state
            loadButton.disabled = true;
            loadButton.textContent = '⏳ Loading...';
            this.updateMagistackStatus('loading', '⏳', 'Fetching magistack from BDO...');
            
            // BDO requires authenticated requests - must use extension
            console.log('🔌 Using The Advancement extension for authenticated BDO access');
            let magistackData = await this.loadMagistackViaExtension(bdoPubKey);
            
            if (magistackData) {
                this.displayMagistackData(magistackData);
                this.updateMagistackStatus('success', '✅', 'Magistack loaded successfully');
            } else {
                this.updateMagistackStatus('error', '❌', 'No magistack data found for this pubKey');
            }
            
        } catch (error) {
            console.error('❌ Failed to load magistack:', error);
            this.updateMagistackStatus('error', '❌', `Failed to load magistack: ${error.message}`);
        } finally {
            // Reset button state
            loadButton.disabled = false;
            loadButton.textContent = originalText;
        }
    }
    
    async loadMagistackViaExtension(bdoPubKey) {
        try {
            console.log(`🔐 Requesting authenticated BDO access for pubKey: ${bdoPubKey}`);
            
            // Debug extension availability
            console.log('🔍 Checking extension availability...');
            console.log('typeof browser:', typeof browser);
            console.log('browser.runtime:', !!browser?.runtime);
            console.log('browser.runtime.sendMessage:', !!browser?.runtime?.sendMessage);
            console.log('window.browser:', !!window.browser);
            
            // Also check for extension availability (both APIs)
            console.log('🔍 Checking extension availability...');
            console.log('typeof safari:', typeof safari);
            console.log('safari.extension:', !!safari?.extension);
            console.log('typeof browser:', typeof browser);
            console.log('browser.runtime:', !!browser?.runtime);
            console.log('window.castSpellBridge:', !!window.castSpellBridge);
            console.log('window.AdvancementExtension:', !!window.AdvancementExtension);
            
            console.log('📱 Attempting to retrieve magistack via The Advancement extension');
            
            // Try the BDO bridge first if available (best option)
            if (window.castSpellBridge) {
                try {
                    console.log('🌉 Using BDO bridge for card retrieval');
                    const response = await window.castSpellBridge({
                        bdoPubKey: bdoPubKey,
                        action: 'getBDOCard'
                    });
                    console.log('📥 BDO bridge response:', response);
                    
                    if (response && response.success && response.data) {
                        console.log('✅ Successfully retrieved magistack data via BDO bridge');
                        return response.data;
                    } else {
                        console.log('❌ BDO bridge returned unsuccessful response');
                    }
                } catch (bridgeError) {
                    console.log('❌ BDO bridge failed:', bridgeError.message);
                }
            }
            
            // Try Safari Legacy API if available (primary method for Safari extensions)
            if (typeof safari !== 'undefined' && safari.extension) {
                try {
                    console.log('🍎 Using Safari Legacy API for BDO access');
                    
                    const response = await new Promise((resolve, reject) => {
                        // Generate unique request ID
                        const requestId = 'getBDOCard_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                        
                        // Set up response listener
                        const messageHandler = function(event) {
                            if (event.name === 'getBDOCardResponse' && event.message.requestId === requestId) {
                                safari.extension.removeEventListener('message', messageHandler);
                                
                                console.log('📥 Received Safari response:', event.message);
                                
                                if (event.message.success) {
                                    resolve(event.message);
                                } else {
                                    reject(new Error(event.message.error || 'Safari extension failed'));
                                }
                            }
                        };
                        
                        // Add listener and send message
                        safari.extension.addEventListener('message', messageHandler);
                        
                        console.log('📤 Sending Safari message with requestId:', requestId);
                        safari.extension.dispatchMessage('getBDOCard', {
                            requestId: requestId,
                            bdoPubKey: bdoPubKey
                        });
                        
                        // Timeout after 10 seconds
                        setTimeout(() => {
                            safari.extension.removeEventListener('message', messageHandler);
                            reject(new Error('Safari extension request timeout'));
                        }, 10000);
                    });
                    
                    if (response && response.success && response.data) {
                        console.log('✅ Successfully retrieved magistack data via Safari Legacy API');
                        return response.data;
                    } else {
                        throw new Error(response?.error || 'Safari extension returned no data');
                    }
                    
                } catch (safariError) {
                    console.log('❌ Safari Legacy API failed:', safariError.message);
                }
            }
            
            // Try Safari Web Extension API as fallback
            if (typeof browser !== 'undefined' && browser.runtime) {
                try {
                    console.log('🌐 Trying Safari Web Extension API as fallback');
                    const extensionId = "com.planetnine.the-advancement.The-Advancement.Extension";
                    
                    const response = await new Promise((resolve, reject) => {
                        console.log('📤 Sending Web Extension message with extension ID:', extensionId);
                        browser.runtime.sendMessage(extensionId, {
                            type: 'getBDOCard',
                            bdoPubKey: bdoPubKey
                        }, (response) => {
                            console.log('📥 Received Web Extension response:', response);
                            if (browser.runtime.lastError) {
                                console.error('❌ Web Extension error:', browser.runtime.lastError);
                                reject(new Error(browser.runtime.lastError.message));
                            } else {
                                resolve(response);
                            }
                        });
                    });
                    
                    if (response && response.success && response.data) {
                        console.log('✅ Successfully retrieved magistack data via Web Extension API');
                        return response.data;
                    } else {
                        throw new Error(response?.error || 'Web Extension returned no data');
                    }
                    
                } catch (webExtError) {
                    console.log('❌ Safari Web Extension API failed:', webExtError.message);
                }
            }
            
            // If all methods failed
            throw new Error('The Advancement Safari extension is required for authenticated BDO access. Please install and enable The Advancement extension in Safari, then refresh this page. All communication methods failed: BDO bridge not available, Safari Legacy API failed, Web Extension API failed.');
            
        } catch (error) {
            console.error('❌ Extension BDO access error:', error);
            throw error;
        }
    }

    async loadMagistackViaFallback(bdoPubKey) {
        const bdoEndpoints = [
            'https://dev.bdo.allyabase.com/',
            'http://127.0.0.1:5114/',
            'http://localhost:3003/'
        ];
        
        let lastError;
        
        for (const bdoUrl of bdoEndpoints) {
            try {
                console.log(`🔍 Trying BDO endpoint: ${bdoUrl}${bdoPubKey}`);
                
                const response = await fetch(`${bdoUrl}${bdoPubKey}`, {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                    }
                });
                
                console.log(`📡 BDO response: ${response.status} ${response.statusText}`);
                
                if (response.ok) {
                    const data = await response.json();
                    console.log('✅ Successfully retrieved magistack data from:', bdoUrl);
                    return data;
                } else if (response.status === 404) {
                    console.log(`❌ Magistack not found at ${bdoUrl} (404)`);
                    lastError = new Error(`Magistack not found at ${bdoUrl}`);
                    continue; // Try next endpoint
                } else {
                    console.log(`❌ BDO request failed at ${bdoUrl}: ${response.status} ${response.statusText}`);
                    lastError = new Error(`BDO request failed: ${response.status} ${response.statusText}`);
                    continue; // Try next endpoint
                }
                
            } catch (networkError) {
                console.log(`🌐 Network error for ${bdoUrl}:`, networkError.message);
                lastError = networkError;
                continue; // Try next endpoint
            }
        }
        
        // If we get here, all endpoints failed
        console.error('❌ All BDO endpoints failed');
        throw lastError || new Error('All BDO endpoints failed to respond');
    }
    
    displayMagistackData(magistackData) {
        const displayElement = document.getElementById('magistack-display');
        
        if (!displayElement) {
            console.error('❌ Magistack display element not found');
            return;
        }
        
        // Clear previous content
        displayElement.innerHTML = '';
        displayElement.classList.add('has-content');
        
        console.log('📋 Magistack data received:', magistackData);
        
        // If this is a menu/membership catalog, display it appropriately
        if (magistackData.title && (magistackData.type === 'menu' || magistackData.type === 'membership')) {
            this.displayMagistackCatalog(magistackData, displayElement);
        } else if (magistackData.cards && Array.isArray(magistackData.cards)) {
            // If it has cards array, display all cards
            this.displayMagistackCards(magistackData.cards, displayElement);
        } else if (magistackData.svgContent || magistackData.svg) {
            // Single card with SVG content
            this.displaySingleMagistackCard(magistackData, displayElement);
        } else {
            // Generic JSON display
            this.displayGenericMagistackData(magistackData, displayElement);
        }
    }
    
    displayMagistackCatalog(catalogData, container) {
        const catalogCard = document.createElement('div');
        catalogCard.className = 'magistack-card';
        
        catalogCard.innerHTML = `
            <div class="magistack-card-title">
                ${catalogData.type === 'membership' ? '👑' : '🍽️'} ${catalogData.title}
            </div>
            <div class="magistack-card-content">
                <div class="catalog-info">
                    <p><strong>Type:</strong> ${catalogData.type}</p>
                    <p><strong>Description:</strong> ${catalogData.description || 'No description'}</p>
                    ${catalogData.metadata ? `<p><strong>Total Cards:</strong> ${catalogData.metadata.totalCards || 'Unknown'}</p>` : ''}
                    ${catalogData.tiers ? `<p><strong>Tiers:</strong> ${catalogData.tiers.length}</p>` : ''}
                    ${catalogData.menus ? `<p><strong>Menu Categories:</strong> ${Object.keys(catalogData.menus).length}</p>` : ''}
                    ${catalogData.cards ? `<p><strong>Available Cards:</strong> ${catalogData.cards.length}</p>` : ''}
                </div>
            </div>
        `;
        
        container.appendChild(catalogCard);
        
        // If there are individual cards, display them too
        if (catalogData.cards && catalogData.cards.length > 0) {
            this.displayMagistackCards(catalogData.cards, container);
        }
    }
    
    displayMagistackCards(cards, container) {
        cards.forEach((card, index) => {
            const cardElement = document.createElement('div');
            cardElement.className = 'magistack-card';
            
            cardElement.innerHTML = `
                <div class="magistack-card-title">
                    🃏 Card ${index + 1}: ${card.name || card.cardName || 'Unnamed Card'}
                </div>
                <div class="magistack-card-content">
                    ${card.svgContent || card.svg || '<p>No SVG content available</p>'}
                </div>
            `;
            
            container.appendChild(cardElement);
        });
    }
    
    displaySingleMagistackCard(cardData, container) {
        const cardElement = document.createElement('div');
        cardElement.className = 'magistack-card';
        
        cardElement.innerHTML = `
            <div class="magistack-card-title">
                🃏 ${cardData.name || cardData.title || 'Magistack Card'}
            </div>
            <div class="magistack-card-content">
                ${cardData.svgContent || cardData.svg || '<p>No SVG content available</p>'}
            </div>
        `;
        
        container.appendChild(cardElement);
    }
    
    displayGenericMagistackData(data, container) {
        const dataCard = document.createElement('div');
        dataCard.className = 'magistack-card';
        
        dataCard.innerHTML = `
            <div class="magistack-card-title">
                📋 Magistack Data
            </div>
            <div class="magistack-card-content">
                <pre style="background: #f8f9fa; padding: 1rem; border-radius: 4px; overflow-x: auto; font-size: 12px;">
${JSON.stringify(data, null, 2)}
                </pre>
            </div>
        `;
        
        container.appendChild(dataCard);
    }
    
    updateMagistackStatus(type, icon, message) {
        const statusElement = document.getElementById('magistack-status-message');
        
        if (!statusElement) return;
        
        const iconElement = statusElement.querySelector('.status-icon');
        const textElement = statusElement.querySelector('p');
        
        if (iconElement) iconElement.textContent = icon;
        if (textElement) textElement.textContent = message;
        
        // Update colors based on status type
        const colors = {
            'loading': '#f39c12',
            'success': '#27ae60', 
            'error': '#e74c3c',
            'info': '#3498db'
        };
        
        if (textElement && colors[type]) {
            textElement.style.color = colors[type];
        }
    }

    logDebugInfo() {
        console.table(this.getDebugInfo());
    }
}

// Initialize the main application
let testStoreApp;

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        testStoreApp = new TestStoreApp();
    });
} else {
    testStoreApp = new TestStoreApp();
}

// Make available globally for debugging
window.testStoreApp = testStoreApp;

// Console shortcuts for debugging
window.debugTestStore = () => testStoreApp.logDebugInfo();
window.refreshTestStore = () => testStoreApp.refreshApplicationStatus();
window.addTestNineum = (amount = 100) => {
    if (window.NineumManager) {
        window.NineumManager.addNineum(amount, 'debug test');
        console.log(`⭐ Added ${amount} test nineum`);
    } else {
        console.warn('NineumManager not available');
    }
};

console.log('📋 Debug commands available:');
console.log('  - debugTestStore() - Show debug information');
console.log('  - refreshTestStore() - Refresh application status');
console.log('  - addTestNineum(amount) - Add test nineum to balance');
console.log('  - testStoreApp.getDebugInfo() - Get detailed debug info');