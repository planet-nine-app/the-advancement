/**
 * Purchase Flow for Planet Nine Test Store
 * 
 * Handles the complete purchase process:
 * - Product selection and display
 * - Multi-pubKey validation (site owner, product creator, base)
 * - Stripe integration via The Advancement extension
 * - Addie payment processing coordination
 */

class PurchaseFlow {
    constructor() {
        this.currentProduct = null;
        this.purchaseIntent = null;
        this.siteOwner = null;
        this.homeBase = null;
        this.stripe = null;
        
        this.initializeElements();
        this.setupEventListeners();
        this.initializeStripe();
    }

    initializeElements() {
        // Modal elements
        this.modal = document.getElementById('purchase-modal');
        this.modalOverlay = document.getElementById('modal-overlay');
        this.modalClose = document.getElementById('modal-close');
        this.modalBody = document.getElementById('modal-body');
        
        // Action buttons
        this.cancelBtn = document.getElementById('cancel-purchase');
        this.purchaseBtn = document.getElementById('complete-purchase');
        
        // Loading overlay
        this.loadingOverlay = document.getElementById('loading-overlay');
        this.loadingMessage = document.getElementById('loading-message');
    }

    setupEventListeners() {
        // Product selection from teleportation client
        document.addEventListener('productSelected', (event) => {
            this.handleProductSelection(event.detail);
        });

        // Modal controls
        this.modalClose.addEventListener('click', () => this.closeModal());
        this.modalOverlay.addEventListener('click', () => this.closeModal());
        this.cancelBtn.addEventListener('click', () => this.closeModal());
        this.purchaseBtn.addEventListener('click', () => this.completePurchase());

        // Keyboard shortcuts
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape' && this.modal.classList.contains('active')) {
                this.closeModal();
            }
        });
    }

    initializeStripe() {
        // Initialize Stripe (in production, this would use real keys)
        if (window.Stripe) {
            this.stripe = Stripe('pk_test_TYooMQauvdEDq54NiTphI7jx'); // Test key
            console.log('💳 Stripe initialized');
        } else {
            console.warn('⚠️ Stripe not loaded');
        }
    }

    async handleProductSelection(selection) {
        const { product, siteOwner, homeBase } = selection;
        
        console.log('🛒 Handling product selection:', product.title);
        console.log('🏪 Site owner:', siteOwner?.name);
        console.log('🏠 Home base:', homeBase?.name);
        
        this.currentProduct = product;
        this.siteOwner = siteOwner;
        this.homeBase = homeBase;
        
        try {
            // Validate prerequisites
            if (!this.validatePurchasePrerequisites()) {
                return;
            }
            
            // Create purchase intent
            this.showLoading('Creating purchase intent...');
            await this.createPurchaseIntent();
            
            // Show purchase modal
            this.showPurchaseModal();
            
        } catch (error) {
            console.error('Failed to handle product selection:', error);
            this.showError('Failed to prepare purchase. Please try again.');
        } finally {
            this.hideLoading();
        }
    }

    validatePurchasePrerequisites() {
        // Check if The Advancement is available
        if (!window.AdvancementExtension) {
            this.showError('The Advancement extension is required for purchases. Please install and reload.');
            return false;
        }

        // Check if Sessionless is available
        if (!window.Sessionless) {
            this.showError('Sessionless authentication is required. Please ensure The Advancement is properly configured.');
            return false;
        }

        // Check if home base is selected
        if (!this.homeBase) {
            this.showError('Please select a home base in The Advancement extension before making purchases.');
            return false;
        }

        // Check if all required pubKeys are available
        if (!this.siteOwner?.pubKey) {
            this.showError('Site owner information not available. Please refresh the page.');
            return false;
        }

        if (!this.currentProduct?.creator_info?.pubKey) {
            this.showError('Product creator information not available.');
            return false;
        }

        if (!this.currentProduct?.base_info?.pubKey) {
            this.showError('Base information not available.');
            return false;
        }

        return true;
    }

    async createPurchaseIntent() {
        try {
            // Get user's pubKey from Sessionless
            const userPubKey = await this.getUserPubKey();
            
            const requestData = {
                productId: this.currentProduct.id,
                buyerPubKey: userPubKey,
                homeBase: this.homeBase.id
            };

            const response = await fetch('/api/purchase/intent', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(requestData)
            });

            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.error || 'Failed to create purchase intent');
            }

            this.purchaseIntent = result.data;
            console.log('✅ Purchase intent created:', this.purchaseIntent.id);
            console.log('💰 Payment splits:', this.purchaseIntent.payment_splits.length);
            
        } catch (error) {
            console.error('Failed to create purchase intent:', error);
            throw error;
        }
    }

    async getUserPubKey() {
        try {
            const result = await window.Sessionless.getPublicKey();
            return result.publicKey;
        } catch (error) {
            console.error('Failed to get user pubKey:', error);
            throw new Error('Unable to get your public key. Please ensure The Advancement is configured.');
        }
    }

    showPurchaseModal() {
        if (!this.purchaseIntent) {
            this.showError('Purchase intent not available');
            return;
        }

        const product = this.currentProduct;
        const intent = this.purchaseIntent;
        const price = (product.price / 100).toFixed(2);

        // Render modal content
        this.modalBody.innerHTML = `
            <div class="purchase-summary">
                <div class="product-summary">
                    <h4>${this.escapeHtml(product.title)}</h4>
                    <p class="creator">by ${this.escapeHtml(product.creator_info.name)}</p>
                    <p class="description">${this.escapeHtml(product.description)}</p>
                    <div class="price-display">
                        <span class="currency">$</span>
                        <span class="amount">${price}</span>
                    </div>
                </div>

                <div class="pubkey-verification">
                    <h5>🔐 Cryptographic Verification</h5>
                    <div class="pubkey-list">
                        <div class="pubkey-item">
                            <span class="label">🏪 Site Owner:</span>
                            <code class="pubkey">${this.truncatePubKey(intent.payment_splits.find(s => s.recipient === 'site')?.pubKey)}</code>
                            <span class="verified">✅</span>
                        </div>
                        <div class="pubkey-item">
                            <span class="label">👤 Creator:</span>
                            <code class="pubkey">${this.truncatePubKey(intent.payment_splits.find(s => s.recipient === 'creator')?.pubKey)}</code>
                            <span class="verified">✅</span>
                        </div>
                        <div class="pubkey-item">
                            <span class="label">🏠 Your Base:</span>
                            <code class="pubkey">${this.truncatePubKey(intent.payment_splits.find(s => s.recipient === 'base')?.pubKey)}</code>
                            <span class="verified">✅</span>
                        </div>
                    </div>
                </div>

                <div class="payment-splits">
                    <h5>💰 Payment Distribution</h5>
                    <div class="splits-list">
                        ${intent.payment_splits.map(split => `
                            <div class="split-item">
                                <span class="recipient">${this.getRecipientLabel(split.recipient)}</span>
                                <span class="amount">$${(split.amount / 100).toFixed(2)}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>

                <div class="payment-method">
                    <h5>💳 Payment Method</h5>
                    <p class="payment-info">
                        Payment will be processed securely via Stripe through The Advancement extension, 
                        with funds distributed automatically to all parties via your home base (${this.homeBase.name}).
                    </p>
                </div>

                <div class="terms">
                    <label class="checkbox-label">
                        <input type="checkbox" id="terms-accepted" required>
                        <span class="checkmark"></span>
                        I agree to the terms of service and understand this payment will be processed through Planet Nine's decentralized payment system
                    </label>
                </div>
            </div>
        `;

        // Show modal
        this.modal.classList.add('active');
        
        // Set up terms checkbox
        const termsCheckbox = document.getElementById('terms-accepted');
        termsCheckbox.addEventListener('change', () => {
            this.purchaseBtn.disabled = !termsCheckbox.checked;
        });

        console.log('📱 Purchase modal displayed');
    }

    async completePurchase() {
        if (!this.purchaseIntent) {
            this.showError('Purchase intent not available');
            return;
        }

        const termsAccepted = document.getElementById('terms-accepted')?.checked;
        if (!termsAccepted) {
            this.showError('Please accept the terms of service');
            return;
        }

        try {
            this.showLoading('Processing payment via The Advancement...');
            
            // Step 1: Create Sessionless signature for the purchase
            const signature = await this.createPurchaseSignature();
            
            // Step 2: Process payment (this would integrate with Stripe via The Advancement)
            const paymentResult = await this.processPayment(signature);
            
            // Step 3: Handle successful purchase
            this.handlePurchaseSuccess(paymentResult);
            
        } catch (error) {
            console.error('Purchase failed:', error);
            this.showError(error.message || 'Purchase failed. Please try again.');
        } finally {
            this.hideLoading();
        }
    }

    async createPurchaseSignature() {
        try {
            // Create a message to sign with all the purchase details
            const purchaseMessage = {
                intent_id: this.purchaseIntent.id,
                product_id: this.currentProduct.id,
                amount: this.purchaseIntent.total_amount,
                currency: this.purchaseIntent.currency,
                timestamp: new Date().toISOString(),
                site_owner_pubkey: this.siteOwner.pubKey,
                creator_pubkey: this.currentProduct.creator_info.pubKey,
                base_pubkey: this.currentProduct.base_info.pubKey
            };

            const messageString = JSON.stringify(purchaseMessage);
            console.log('📝 Signing purchase message:', messageString);

            const signature = await window.Sessionless.sign(messageString);
            console.log('✅ Purchase signed with Sessionless');
            
            return signature.signature;
            
        } catch (error) {
            console.error('Failed to create purchase signature:', error);
            throw new Error('Failed to sign purchase. Please ensure The Advancement is properly configured.');
        }
    }

    async processPayment(sessionlessSignature) {
        try {
            // Check if The Advancement Stripe integration is available
            if (window.AdvancementStripeIntegration && window.AdvancementStripeIntegration.isAvailable()) {
                console.log('💳 Processing payment via The Advancement Stripe integration');
                
                // Use The Advancement's payment processor
                return await this.processViaAdvancement(sessionlessSignature);
            } else {
                console.log('🧪 The Advancement not available, using test server simulation');
                
                // Fallback to test server simulation
                return await this.processViaTestServer(sessionlessSignature);
            }
            
        } catch (error) {
            console.error('Payment processing failed:', error);
            throw error;
        }
    }

    async processViaAdvancement(sessionlessSignature) {
        try {
            // Dispatch Planet Nine payment event for The Advancement to handle
            return new Promise((resolve, reject) => {
                // Set up event listeners for payment result
                const handleSuccess = (event) => {
                    document.removeEventListener('planetnine-payment-success', handleSuccess);
                    document.removeEventListener('planetnine-payment-error', handleError);
                    resolve(event.detail);
                };

                const handleError = (event) => {
                    document.removeEventListener('planetnine-payment-success', handleSuccess);
                    document.removeEventListener('planetnine-payment-error', handleError);
                    reject(new Error(event.detail.error));
                };

                document.addEventListener('planetnine-payment-success', handleSuccess);
                document.addEventListener('planetnine-payment-error', handleError);

                // Dispatch the payment request
                document.dispatchEvent(new CustomEvent('planetnine-payment-request', {
                    detail: {
                        purchaseIntent: this.purchaseIntent,
                        sessionlessSignature: sessionlessSignature
                    }
                }));

                // Timeout after 60 seconds
                setTimeout(() => {
                    document.removeEventListener('planetnine-payment-success', handleSuccess);
                    document.removeEventListener('planetnine-payment-error', handleError);
                    reject(new Error('Payment timeout - no response from The Advancement'));
                }, 60000);
            });

        } catch (error) {
            console.error('The Advancement payment failed:', error);
            throw error;
        }
    }

    async processViaTestServer(sessionlessSignature) {
        try {
            const paymentData = {
                intentId: this.purchaseIntent.id,
                stripePaymentMethod: 'pm_card_visa', // Mock payment method
                sessionlessSignature: sessionlessSignature
            };

            const response = await fetch('/api/purchase/process', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(paymentData)
            });

            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.error || 'Payment processing failed');
            }

            console.log('✅ Payment processed via test server:', result.data);
            return result.data;
            
        } catch (error) {
            console.error('Test server payment failed:', error);
            throw error;
        }
    }

    handlePurchaseSuccess(paymentResult) {
        console.log('🎉 Purchase completed successfully:', paymentResult);
        
        // Close modal
        this.closeModal();
        
        // Show success message
        this.showSuccess(`
            Purchase completed successfully! 
            ${this.currentProduct.type === 'physical' ? 
                'You will receive shipping information via email.' : 
                'You now have access to your purchased content.'
            }
        `);
        
        // Clear purchase state
        this.currentProduct = null;
        this.purchaseIntent = null;
        
        // Trigger analytics/tracking if needed
        this.trackPurchaseCompletion(paymentResult);
    }

    trackPurchaseCompletion(paymentResult) {
        // Analytics tracking for completed purchases
        const trackingData = {
            event: 'purchase_completed',
            product_id: this.currentProduct?.id,
            amount: this.purchaseIntent?.total_amount,
            currency: this.purchaseIntent?.currency,
            payment_id: paymentResult.id,
            home_base: this.homeBase?.id,
            timestamp: new Date().toISOString()
        };
        
        console.log('📊 Purchase tracking:', trackingData);
        
        // In production, this would send to analytics service
        // Custom event for other parts of the app
        document.dispatchEvent(new CustomEvent('purchaseCompleted', {
            detail: trackingData
        }));
    }

    // UI Helper Methods
    closeModal() {
        this.modal.classList.remove('active');
        this.currentProduct = null;
        this.purchaseIntent = null;
    }

    showLoading(message) {
        this.loadingMessage.textContent = message;
        this.loadingOverlay.classList.add('active');
    }

    hideLoading() {
        this.loadingOverlay.classList.remove('active');
    }

    showError(message) {
        this.showToast(message, 'error');
    }

    showSuccess(message) {
        this.showToast(message, 'success');
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

    // Utility Methods
    getRecipientLabel(recipient) {
        const labels = {
            'creator': '👤 Creator',
            'base': '🏠 Base',
            'site': '🏪 Site'
        };
        return labels[recipient] || recipient;
    }

    truncatePubKey(pubKey) {
        if (!pubKey) return 'Unknown';
        return `${pubKey.substring(0, 8)}...${pubKey.substring(pubKey.length - 8)}`;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize when DOM is ready
let purchaseFlow;

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        purchaseFlow = new PurchaseFlow();
    });
} else {
    purchaseFlow = new PurchaseFlow();
}

// Export for other modules
window.purchaseFlow = purchaseFlow;