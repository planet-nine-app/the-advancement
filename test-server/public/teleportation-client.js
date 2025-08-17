/**
 * Teleportation Client for Planet Nine Test Store
 * 
 * Handles discovery and display of teleported products from user's home base
 * Integrates with The Advancement extension for seamless experience
 */

class TeleportationClient {
    constructor() {
        this.siteOwner = null;
        this.homeBase = null;
        this.teleportedProducts = [];
        this.isLoading = false;
        
        this.initializeElements();
        this.setupEventListeners();
    }

    initializeElements() {
        // Status elements
        this.advancementStatus = document.getElementById('advancement-status');
        this.statusIndicator = document.getElementById('status-indicator');
        this.statusText = document.getElementById('status-text');
        
        // Home base elements
        this.homeBaseIndicator = document.getElementById('home-base-indicator');
        this.homeBaseName = document.getElementById('home-base-name');
        this.basePubKeyLabel = document.getElementById('base-pubkey-label');
        this.basePubKey = document.getElementById('base-pubkey');
        
        // Feed elements
        this.feedStatus = document.getElementById('feed-status');
        this.statusMessage = document.getElementById('status-message');
        this.productsGrid = document.getElementById('products-grid');
        this.refreshBtn = document.getElementById('refresh-feed');
        
        // PubKey display
        this.sitePubKey = document.getElementById('site-pubkey');
    }

    setupEventListeners() {
        // Refresh button
        this.refreshBtn.addEventListener('click', () => {
            this.refreshTeleportedContent();
        });

        // Listen for Advancement extension events
        document.addEventListener('advancementReady', (event) => {
            console.log('🚀 The Advancement extension detected:', event.detail);
            this.handleAdvancementReady();
        });

        document.addEventListener('sessionlessReady', (event) => {
            console.log('🔐 Sessionless ready:', event.detail);
            this.handleSessionlessReady();
        });

        // Product click handlers will be added dynamically
    }

    async initialize() {
        console.log('🔍 Initializing teleportation client...');
        
        try {
            // Load site owner information
            await this.loadSiteOwner();
            
            // Check for The Advancement extension
            await this.checkAdvancementStatus();
            
            // Load user's home base
            await this.loadHomeBase();
            
            // Load teleported content
            await this.loadTeleportedContent();
            
        } catch (error) {
            console.error('Failed to initialize teleportation client:', error);
            this.showError('Failed to initialize. Please refresh the page.');
        }
    }

    async loadSiteOwner() {
        try {
            const response = await fetch('/api/site-owner');
            const result = await response.json();
            
            if (result.success) {
                this.siteOwner = result.data;
                this.sitePubKey.textContent = this.siteOwner.pubKey;
                console.log('✅ Site owner loaded:', this.siteOwner.name);
            } else {
                throw new Error(result.error || 'Failed to load site owner');
            }
        } catch (error) {
            console.error('Failed to load site owner:', error);
            this.sitePubKey.textContent = 'Failed to load';
        }
    }

    async checkAdvancementStatus() {
        // Check if The Advancement extension is available
        if (window.AdvancementExtension) {
            this.updateAdvancementStatus('online', 'The Advancement Connected');
            console.log('✅ The Advancement extension detected');
            return true;
        } else {
            this.updateAdvancementStatus('offline', 'The Advancement Not Detected');
            console.warn('⚠️ The Advancement extension not found');
            return false;
        }
    }

    async loadHomeBase() {
        try {
            // Try to get home base from The Advancement extension
            if (window.AdvancementExtension) {
                // This would integrate with the extension's storage
                const homeBase = this.getHomeBaseFromStorage();
                if (homeBase) {
                    this.setHomeBase(homeBase);
                    return;
                }
            }
            
            // Fallback: check localStorage
            const stored = localStorage.getItem('advancement-home-base');
            if (stored) {
                const homeBase = JSON.parse(stored);
                this.setHomeBase(homeBase);
            } else {
                this.showNoHomeBase();
            }
            
        } catch (error) {
            console.error('Failed to load home base:', error);
            this.showNoHomeBase();
        }
    }

    getHomeBaseFromStorage() {
        // This would integrate with The Advancement extension
        // For now, check localStorage as fallback
        try {
            const stored = localStorage.getItem('advancement-home-base');
            return stored ? JSON.parse(stored) : null;
        } catch {
            return null;
        }
    }

    setHomeBase(homeBase) {
        this.homeBase = homeBase;
        this.homeBaseName.textContent = homeBase.name;
        this.basePubKeyLabel.textContent = `${homeBase.name} Base`;
        this.basePubKey.textContent = homeBase.pubKey || 'Unknown';
        
        console.log('🏠 Home base set:', homeBase.name);
    }

    showNoHomeBase() {
        this.homeBaseName.textContent = 'No Home Base Selected';
        this.basePubKeyLabel.textContent = 'Select a home base in The Advancement';
        this.basePubKey.textContent = 'Not selected';
        
        this.showFeedMessage('🏠', 'Please select a home base in The Advancement extension to see teleported products.');
    }

    async loadTeleportedContent() {
        if (!this.homeBase) {
            this.showNoHomeBase();
            return;
        }

        this.setLoading(true);
        this.showFeedMessage('🔍', 'Teleporting products from your home base...');

        try {
            // Get user's pubKey for teleportation request
            const userPubKey = await this.getUserPubKey();
            
            // Request teleported content from the home base
            const teleportedData = await this.requestTeleportation(this.homeBase.id, userPubKey);
            
            if (teleportedData && teleportedData.products) {
                this.teleportedProducts = teleportedData.products;
                this.renderProducts();
                console.log(`✅ Teleported ${this.teleportedProducts.length} products from ${this.homeBase.name}`);
            } else {
                this.showFeedMessage('📦', 'No products available from your home base.');
            }
            
        } catch (error) {
            console.error('Teleportation failed:', error);
            this.showFeedMessage('❌', 'Failed to load teleported products. Please try again.');
        } finally {
            this.setLoading(false);
        }
    }

    async getUserPubKey() {
        // Try to get pubKey from The Advancement / Sessionless
        if (window.Sessionless && window.Sessionless.getPublicKey) {
            try {
                const result = await window.Sessionless.getPublicKey();
                return result.publicKey;
            } catch (error) {
                console.warn('Failed to get user pubKey from Sessionless:', error);
            }
        }
        
        // Fallback: generate a mock pubKey for testing
        return '0x' + Array.from({length: 64}, () => Math.floor(Math.random() * 16).toString(16)).join('');
    }

    async requestTeleportation(baseId, userPubKey) {
        const response = await fetch(`/api/teleport/${baseId}?pubKey=${encodeURIComponent(userPubKey)}`);
        const result = await response.json();
        
        if (!result.success) {
            throw new Error(result.error || 'Teleportation failed');
        }
        
        return result.data;
    }

    renderProducts() {
        this.productsGrid.innerHTML = '';
        this.feedStatus.style.display = 'none';

        if (this.teleportedProducts.length === 0) {
            this.showFeedMessage('📦', 'No products available from your home base.');
            return;
        }

        this.teleportedProducts.forEach(product => {
            const productCard = this.createProductCard(product);
            this.productsGrid.appendChild(productCard);
        });
    }

    createProductCard(product) {
        const card = document.createElement('div');
        card.className = 'product-card';
        card.dataset.productId = product.id;

        // Determine product icon based on type
        const typeIcons = {
            'ebook': '📚',
            'course': '🎓',
            'physical': '📦',
            'software': '💻',
            'default': '🎁'
        };
        const icon = typeIcons[product.type] || typeIcons.default;

        // Format price
        const price = (product.price / 100).toFixed(2);

        // Create metadata tags
        const metadataTags = [];
        if (product.metadata) {
            if (product.metadata.pages) metadataTags.push(`${product.metadata.pages} pages`);
            if (product.metadata.duration) metadataTags.push(product.metadata.duration);
            if (product.metadata.lessons) metadataTags.push(`${product.metadata.lessons} lessons`);
            if (product.metadata.format) metadataTags.push(product.metadata.format);
            if (product.type) metadataTags.push(product.type.toUpperCase());
        }

        card.innerHTML = `
            <div class="product-header">
                <div class="product-image">
                    ${icon}
                </div>
                <div class="product-info">
                    <h4 class="product-title">${this.escapeHtml(product.title)}</h4>
                    <p class="product-creator">by ${this.escapeHtml(product.creator_info?.name || 'Unknown')}</p>
                    <div class="product-price">$${price}</div>
                </div>
            </div>
            <p class="product-description">${this.escapeHtml(product.description)}</p>
            <div class="product-metadata">
                ${metadataTags.map(tag => `<span class="metadata-tag">${this.escapeHtml(tag)}</span>`).join('')}
            </div>
        `;

        // Add click handler
        card.addEventListener('click', () => {
            this.handleProductClick(product);
        });

        return card;
    }

    handleProductClick(product) {
        console.log('🛒 Product clicked:', product.title);
        
        // Dispatch custom event for purchase flow
        document.dispatchEvent(new CustomEvent('productSelected', {
            detail: { 
                product,
                siteOwner: this.siteOwner,
                homeBase: this.homeBase
            }
        }));
    }

    async refreshTeleportedContent() {
        console.log('🔄 Refreshing teleported content...');
        
        this.refreshBtn.classList.add('spinning');
        
        try {
            await this.loadHomeBase();
            await this.loadTeleportedContent();
        } catch (error) {
            console.error('Refresh failed:', error);
            this.showError('Failed to refresh content');
        } finally {
            this.refreshBtn.classList.remove('spinning');
        }
    }

    // Event handlers
    handleAdvancementReady() {
        this.updateAdvancementStatus('online', 'The Advancement Connected');
        this.loadHomeBase();
    }

    handleSessionlessReady() {
        console.log('🔐 Sessionless ready, reloading content...');
        this.loadTeleportedContent();
    }

    // UI Update Methods
    updateAdvancementStatus(status, text) {
        this.statusIndicator.className = `status-indicator ${status}`;
        this.statusText.textContent = text;
        
        const statusIcons = {
            online: '🟢',
            offline: '🔴',
            connecting: '⚪'
        };
        this.statusIndicator.textContent = statusIcons[status] || '⚪';
    }

    setLoading(loading) {
        this.isLoading = loading;
        this.refreshBtn.classList.toggle('spinning', loading);
    }

    showFeedMessage(icon, message) {
        this.feedStatus.style.display = 'block';
        this.productsGrid.innerHTML = '';
        
        this.statusMessage.innerHTML = `
            <span class="status-icon">${icon}</span>
            <p>${message}</p>
        `;
    }

    showError(message) {
        this.showToast(message, 'error');
    }

    showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        
        const container = document.getElementById('toast-container');
        container.appendChild(toast);
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    // Utility methods
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize when DOM is ready
let teleportationClient;

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        teleportationClient = new TeleportationClient();
        teleportationClient.initialize();
    });
} else {
    teleportationClient = new TeleportationClient();
    teleportationClient.initialize();
}

// Export for other modules
window.teleportationClient = teleportationClient;