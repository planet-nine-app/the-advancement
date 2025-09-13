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
        // Stripe will be initialized when we get the publishable key from payment intent
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

        // NEW: Payment intent from The Advancement extension
        document.addEventListener('advancement-payment-intent', (event) => {
            this.handleAdvancementPaymentIntent(event.detail);
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

    initializeStripe(publishableKey) {
        if (!publishableKey) {
            console.error('❌ No publishable key provided to initialize Stripe');
            return false;
        }
        
        if (window.Stripe) {
            this.stripe = Stripe(publishableKey);
            console.log('💳 Stripe initialized with key:', publishableKey);
            return true;
        } else {
            console.warn('⚠️ Stripe not loaded');
            return false;
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

    async handleAdvancementPaymentIntent(paymentData) {
        console.log('💳 [NEW FLOW] Received payment intent from The Advancement extension:', paymentData);
        
        const { processor, paymentIntent, purchaseData } = paymentData;
        
        if (processor !== 'stripe') {
            console.error('❌ Unsupported payment processor:', processor);
            this.showError(`Unsupported payment processor: ${processor}`);
            return;
        }

        try {
            console.log('💳 [NEW FLOW] Processing Stripe payment with intent:', paymentIntent);
            console.log('💰 [NEW FLOW] Purchase amount: $' + (purchaseData.amount / 100).toFixed(2));
            console.log('📦 [NEW FLOW] Product:', purchaseData.name);

            // Debug: Log the exact structure we received
            console.log('🔍 [NEW FLOW] Debug paymentIntent structure:', JSON.stringify(paymentIntent, null, 2));
            
            // Initialize Stripe with the publishable key from Addie response
            if (paymentIntent.publishableKey) {
                console.log('💳 [NEW FLOW] Initializing Stripe with publishable key from Addie');
                if (!this.initializeStripe(paymentIntent.publishableKey)) {
                    throw new Error('Failed to initialize Stripe with provided publishable key');
                }
            } else {
                console.error('❌ [NEW FLOW] No publishableKey found in Addie response');
                throw new Error('No publishable key provided by payment processor');
            }

            // Show loading overlay
            this.showLoading('Processing Stripe payment...');

            // Initialize Stripe Elements with the payment intent
            // Note: Addie returns paymentIntent string directly, not nested client_secret
            let clientSecret;
            if (typeof paymentIntent === 'string') {
                clientSecret = paymentIntent;
            } else if (paymentIntent.paymentIntent) {
                clientSecret = paymentIntent.paymentIntent;
            } else if (paymentIntent.client_secret) {
                clientSecret = paymentIntent.client_secret;
            } else {
                console.error('❌ [NEW FLOW] Could not find client secret in:', paymentIntent);
                throw new Error('Invalid payment intent format - no client secret found');
            }
            
            console.log('🔑 [NEW FLOW] Using clientSecret:', clientSecret);
            
            const elements = this.stripe.elements({
                clientSecret: clientSecret
            });

            // Create payment element
            const paymentElement = elements.create('payment');
            
            // Store elements and paymentElement for later use
            this.stripeElements = elements;
            this.stripePaymentElement = paymentElement;
            
            // Create a simple payment form overlay
            this.showStripePaymentOverlay(paymentIntent, purchaseData, elements, paymentElement);

        } catch (error) {
            console.error('❌ [NEW FLOW] Stripe processing error:', error);
            this.showError(`Stripe payment failed: ${error.message}`);
            this.hideLoading();
        }
    }

    showStripePaymentOverlay(paymentIntent, purchaseData, elements, paymentElement) {
        console.log('💳 [NEW FLOW] Showing Stripe payment overlay');

        // Remove any existing payment overlay
        const existingOverlay = document.getElementById('stripe-payment-overlay');
        if (existingOverlay) {
            existingOverlay.remove();
        }

        // Create payment overlay
        const overlay = document.createElement('div');
        overlay.id = 'stripe-payment-overlay';
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: rgba(0, 0, 0, 0.8);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 999999;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        `;

        // Create payment form
        const paymentForm = document.createElement('div');
        paymentForm.style.cssText = `
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            width: 95%;
            max-width: 600px;
            min-height: 400px;
            position: relative;
        `;

        paymentForm.innerHTML = `
            <h3 style="margin: 0 0 20px 0; color: #333; text-align: center;">
                Complete Payment
            </h3>
            
            <div class="payment-summary" style="margin-bottom: 20px; padding: 15px; background: #f5f5f5; border-radius: 8px;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong>${purchaseData.name}</strong>
                        <div style="color: #666; font-size: 14px;">Product ID: ${purchaseData.productId}</div>
                    </div>
                    <div style="font-size: 24px; font-weight: bold; color: #333;">
                        $${(purchaseData.amount / 100).toFixed(2)}
                    </div>
                </div>
            </div>
            
            <div id="payment-element" style="
                margin: 30px 0; 
                padding: 20px; 
                border: 1px solid #e0e0e0; 
                border-radius: 8px; 
                background: #fafafa;
                min-height: 120px;
            ">
                <!-- Stripe Elements will mount here -->
            </div>
            
            <div style="display: flex; gap: 12px; margin-top: 20px;">
                <button id="cancel-stripe-btn" style="
                    flex: 1;
                    background: #f0f0f0;
                    color: #333;
                    border: none;
                    border-radius: 8px;
                    padding: 12px 24px;
                    font-size: 14px;
                    cursor: pointer;
                ">Cancel</button>
                
                <button id="submit-payment-btn" style="
                    flex: 2;
                    background: linear-gradient(45deg, #667eea, #764ba2);
                    color: white;
                    border: none;
                    border-radius: 8px;
                    padding: 12px 24px;
                    font-size: 14px;
                    cursor: pointer;
                    font-weight: 600;
                ">Pay $${(purchaseData.amount / 100).toFixed(2)}</button>
            </div>
            
            <div id="payment-messages" style="margin-top: 16px; text-align: center; font-size: 14px;"></div>
        `;

        overlay.appendChild(paymentForm);
        document.body.appendChild(overlay);
        
        // Mount the Stripe payment element immediately
        console.log('💳 [NEW FLOW] Attempting to mount payment element...');
        
        // Verify the payment element div exists
        const paymentElementDiv = document.getElementById('payment-element');
        console.log('💳 [NEW FLOW] Payment element div found:', paymentElementDiv);
        
        if (!paymentElementDiv) {
            console.error('❌ [NEW FLOW] #payment-element div not found in DOM');
            return;
        }
        
        try {
            paymentElement.mount('#payment-element');
            console.log('💳 [NEW FLOW] Payment element mount successful');
        } catch (error) {
            console.error('❌ [NEW FLOW] Payment element mount failed:', error);
        }

        // Wait for payment element to be ready before enabling the form
        let isPaymentElementReady = false;
        paymentElement.on('ready', () => {
            console.log('💳 [NEW FLOW] Payment element ready');
            isPaymentElementReady = true;
            const submitBtn = overlay.querySelector('#submit-payment-btn');
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.style.opacity = '1';
            }
        });

        // Handle payment element changes for validation
        paymentElement.on('change', (event) => {
            console.log('💳 [NEW FLOW] Payment element changed:', event);
        });

        // Initially disable submit button until payment element is ready
        const submitBtn = overlay.querySelector('#submit-payment-btn');
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.style.opacity = '0.6';
        }

        // Hide the main loading overlay now that we have our payment form
        this.hideLoading();

        // Setup event handlers
        this.setupStripePaymentHandlers(overlay, elements, paymentIntent, purchaseData, () => isPaymentElementReady);
    }

    setupStripePaymentHandlers(overlay, elements, paymentIntent, purchaseData, isReadyCallback) {
        const submitBtn = overlay.querySelector('#submit-payment-btn');
        const cancelBtn = overlay.querySelector('#cancel-stripe-btn');
        const messagesDiv = overlay.querySelector('#payment-messages');

        // Cancel handler
        cancelBtn.addEventListener('click', () => {
            console.log('💳 [NEW FLOW] Payment cancelled by user');
            overlay.remove();
        });

        // Submit handler
        submitBtn.addEventListener('click', async () => {
            console.log('💳 [NEW FLOW] Processing Stripe payment...');
            
            // Check if payment element is ready
            if (!isReadyCallback || !isReadyCallback()) {
                console.warn('💳 [NEW FLOW] Payment element not ready yet');
                messagesDiv.innerHTML = '<span style="color: #f44336;">Please wait for the payment form to load completely.</span>';
                return;
            }
            
            submitBtn.disabled = true;
            submitBtn.textContent = 'Processing...';
            messagesDiv.innerHTML = '<span style="color: #666;">Processing payment...</span>';

            try {
                const { error } = await this.stripe.confirmPayment({
                    elements,
                    confirmParams: {
                        return_url: window.location.href,
                    },
                    redirect: 'if_required'
                });

                if (error) {
                    console.error('❌ [NEW FLOW] Stripe payment error:', error);
                    messagesDiv.innerHTML = `<span style="color: #f44336;">❌ ${error.message}</span>`;
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Retry Payment';
                } else {
                    console.log('✅ [NEW FLOW] Stripe payment successful!');
                    messagesDiv.innerHTML = '<span style="color: #4CAF50;">✅ Payment successful!</span>';
                    
                    // Close overlay after short delay
                    setTimeout(() => {
                        overlay.remove();
                        this.showSuccess(`Payment of $${(purchaseData.amount / 100).toFixed(2)} completed successfully for ${purchaseData.name}!`);
                    }, 2000);
                }
            } catch (error) {
                console.error('❌ [NEW FLOW] Stripe payment exception:', error);
                messagesDiv.innerHTML = `<span style="color: #f44336;">❌ Payment failed: ${error.message}</span>`;
                submitBtn.disabled = false;
                submitBtn.textContent = 'Retry Payment';
            }
        });

        // Close on escape
        const escapeHandler = (e) => {
            if (e.key === 'Escape') {
                overlay.remove();
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
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
