/**
 * Combined popup script for Safari compatibility
 */

(function() {
    'use strict';

    // Popup bridge for communicating with background script
    class PopupBridge {
        async sendToSwift(action, payload = {}) {
            const message = {
                type: 'nativeMessage',
                payload: {
                    action: action,
                    requestId: Date.now().toString(),
                    ...payload
                }
            };
            
            console.log('📤 Popup→Background: Sending message:', message);
            
            return new Promise((resolve, reject) => {
                browser.runtime.sendMessage(message, (response) => {
                    console.log('📥 Background→Popup: Received response:', response);
                    
                    if (browser.runtime.lastError) {
                        console.log('❌ Popup messaging error:', browser.runtime.lastError);
                        reject(new Error(browser.runtime.lastError.message));
                    } else if (response && response.success) {
                        resolve(response.data);
                    } else {
                        reject(new Error(response?.error || 'Request failed'));
                    }
                });
            });
        }

        async getSpellbooks(baseUrl) {
            //const resp = this.sendToSwift('generateKeys');
            //console.log('beofre getting spellbooks we generate new keys', resp);
            return await this.sendToSwift('getSpellbook', { baseUrl: baseUrl });
        }

        async generateKeys() {
            return await this.sendToSwift('generateKeys');
        }
    }

    // Simple BDO client that delegates everything to Swift via background
    class BDOClient {
        constructor() {
            this.bridge = new PopupBridge();
        }

        async getSpellbook(baseUrl) {
            return await this.bridge.getSpellbooks(baseUrl);
        }

        async generateKeys() {
            return await this.bridge.generateKeys();
        }

        async healthCheck(baseUrl) {
            try {
                const response = await fetch(`${baseUrl}/`, { method: 'GET', timeout: 5000 });
                return response.status < 500;
            } catch (error) {
                return false;
            }
        }
    }

    // Simple popup UI
    class SimplePopupUI {
        constructor() {
            this.bdoClient = new BDOClient();
            this.spellsList = document.getElementById('spells-list');
            this.refreshBtn = document.getElementById('refresh-spellbook');
            this.generateKeysBtn = document.getElementById('generate-keys');
            
            // Setup tab navigation
            this.setupTabNavigation();
            
            if (this.refreshBtn) {
                this.refreshBtn.addEventListener('click', () => this.refreshSpellbook());
            }
            
            if (this.generateKeysBtn) {
                console.log('🔑 Generate keys button found, adding event listener');
                this.generateKeysBtn.addEventListener('click', () => {
                    console.log('🔑 Generate keys button clicked!');
                    this.generateKeys();
                });
            } else {
                console.log('❌ Generate keys button not found');
            }
            
            // Auto-load on startup
            this.loadSpellbook();
        }

        setupTabNavigation() {
            console.log('🔧 Setting up tab navigation');
            
            const tabButtons = document.querySelectorAll('.nav-tab');
            const tabContents = document.querySelectorAll('.tab-content');
            
            tabButtons.forEach(button => {
                button.addEventListener('click', (e) => {
                    console.log('🔄 Tab clicked:', e.target.dataset.tab);
                    
                    const targetTab = e.target.dataset.tab;
                    
                    // Remove active class from all tabs and contents
                    tabButtons.forEach(btn => btn.classList.remove('active'));
                    tabContents.forEach(content => content.classList.remove('active'));
                    
                    // Add active class to clicked tab and corresponding content
                    e.target.classList.add('active');
                    const targetContent = document.getElementById(`content-${targetTab}`);
                    if (targetContent) {
                        targetContent.classList.add('active');
                    }
                });
            });
        }

        async refreshSpellbook() {
            console.log('🔄 User clicked refresh spellbook');
            await this.loadSpellbook();
        }

        async generateKeys() {
            console.log('🔑 User clicked generate keys');
            console.log('🔑 Generate keys method called');
            
            try {
                const result = await this.bdoClient.generateKeys();
                console.log('✅ Keys generated successfully:', result);
                
                // Show success message
                if (this.spellsList) {
                    this.spellsList.innerHTML = `
                        <div class="success-state">
                            <span class="success-icon">✅</span>
                            <h3>Keys Generated</h3>
                            <p>New cryptographic keys have been generated and stored securely.</p>
                            <p><strong>Public Key:</strong> ${result.publicKey}</p>
                        </div>
                    `;
                }
                
                // Auto-refresh spellbook with new keys
                setTimeout(() => this.loadSpellbook(), 2000);
                
            } catch (error) {
                console.log('❌ Key generation failed:', error);
                this.renderError(`Key generation failed: ${error.message}`);
            }
        }

        async loadSpellbook() {
            const testEnvironment = 'http://127.0.0.1:5114';
            
            try {
                this.showLoading(true);
                const result = await this.bdoClient.getSpellbook(testEnvironment);
                
                if (result.spellbooks) {
                    this.renderSpells(result.spellbooks);
                } else {
                    this.renderError('No spellbooks in response');
                }
                
            } catch (error) {
                this.renderError(error.message);
            } finally {
                this.showLoading(false);
            }
        }

        renderSpells(spellbooks) {
            if (!this.spellsList) return;
            
            if (!spellbooks || spellbooks.length === 0) {
                this.spellsList.innerHTML = '<div class="empty-state">📦 No spellbooks available</div>';
                return;
            }

            const spellbooksHtml = spellbooks.map(spellbook => `
                <div class="spell-card">
                    <h4>📚 ${spellbook.spellbookName || spellbook.name || 'Unknown Spellbook'}</h4>
                    <div class="spell-details">
                        <div class="spell-section">
                            <strong>Join Destinations:</strong>
                            <div class="destinations">
                                ${spellbook.joinup?.destinations?.map(dest => 
                                    `<span class="destination-tag">🔗 ${dest.stopName}</span>`
                                ).join('') || 'None'}
                            </div>
                        </div>
                        <div class="spell-section">
                            <strong>Link Destinations:</strong>
                            <div class="destinations">
                                ${spellbook.linkup?.destinations?.map(dest => 
                                    `<span class="destination-tag">🔗 ${dest.stopName}</span>`
                                ).join('') || 'None'}
                            </div>
                        </div>
                        <div class="spell-costs">
                            <span class="cost-tag">💰 Join Cost: ${spellbook.joinup?.cost || 'N/A'}</span>
                            <span class="cost-tag">💰 Link Cost: ${spellbook.linkup?.cost || 'N/A'}</span>
                        </div>
                    </div>
                </div>
            `).join('');

            this.spellsList.innerHTML = spellbooksHtml;
        }

        renderError(errorMessage) {
            if (!this.spellsList) return;
            
            this.spellsList.innerHTML = `
                <div class="error-state">
                    <span class="error-icon">❌</span>
                    <h3>Spellbook Error</h3>
                    <p>${errorMessage}</p>
                </div>
            `;
        }

        showLoading(show) {
            const loading = document.getElementById('spellbook-loading');
            if (loading) {
                loading.style.display = show ? 'block' : 'none';
            }
            if (this.spellsList) {
                this.spellsList.style.display = show ? 'none' : 'block';
            }
        }
    }

    // Initialize when DOM ready
    function initializePopup() {
        new SimplePopupUI();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializePopup);
    } else {
        initializePopup();
    }

})();
