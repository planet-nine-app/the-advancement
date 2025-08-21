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
        this.initializeNineumBalance();
        
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

    initializeNineumBalance() {
        // Initialize nineum balance from localStorage or default to 0
        const savedBalance = localStorage.getItem('advancement-nineum-balance');
        this.nineumBalance = savedBalance ? parseInt(savedBalance, 10) : 0;
        
        console.log('⭐ Nineum balance initialized:', this.nineumBalance);
        this.updateNineumDisplay();
        
        // Listen for nineum updates from spell casting
        document.addEventListener('nineum-earned', (event) => {
            this.addNineum(event.detail.amount, event.detail.source);
        });
        
        // Expose nineum management globally for The Advancement
        window.NineumManager = {
            getBalance: () => this.nineumBalance,
            addNineum: (amount, source) => this.addNineum(amount, source),
            setBalance: (amount) => this.setNineumBalance(amount)
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