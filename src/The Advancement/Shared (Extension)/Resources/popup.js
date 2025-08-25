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
            // Use new getSpellbook message type instead of sendToSwift
            // This uses background spellbook manager with caching
            const message = {
                type: 'getSpellbook',
                baseUrl: baseUrl
            };
            
            console.log('📤 Popup→Background: Sending getSpellbook message:', message);
            
            return new Promise((resolve, reject) => {
                browser.runtime.sendMessage(message, (response) => {
                    console.log('📥 Background→Popup: Received getSpellbook response:', response);
                    
                    if (browser.runtime.lastError) {
                        reject(new Error(browser.runtime.lastError.message));
                    } else if (response && response.success) {
                        resolve(response);
                    } else {
                        reject(new Error(response?.error || 'No response from background'));
                    }
                });
            });
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
            this.clearBdoUserBtn = document.getElementById('clear-bdo-user');
            this.clearFountUserBtn = document.getElementById('clear-fount-user');
            this.clearAllDataBtn = document.getElementById('clear-all-data');
            
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
            
            // Add clear data event listeners
            if (this.clearBdoUserBtn) {
                this.clearBdoUserBtn.addEventListener('click', () => this.clearBdoUser());
            }
            
            if (this.clearFountUserBtn) {
                this.clearFountUserBtn.addEventListener('click', () => this.clearFountUser());
            }
            
            if (this.clearAllDataBtn) {
                this.clearAllDataBtn.addEventListener('click', () => this.clearAllData());
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
        
        async clearBdoUser() {
            console.log('🗑️ User clicked clear BDO user');
            
            try {
                // Clear from extension storage (background script)
                if (typeof browser !== 'undefined' && browser.storage) {
                    await new Promise((resolve) => {
                        browser.storage.local.remove('bdoUser', resolve);
                    });
                }
                
                // Also clear via background script message
                await this.bdoClient.bridge.sendToSwift('clearBdoUser');
                
                // Show success message
                if (this.spellsList) {
                    this.spellsList.innerHTML = `
                        <div class="success-state">
                            <span class="success-icon">🗑️</span>
                            <h3>BDO User Cleared</h3>
                            <p>Stored BDO user has been cleared. A new user will be created on next spellbook fetch.</p>
                        </div>
                    `;
                }
                
                console.log('✅ BDO user cleared successfully');
                
            } catch (error) {
                console.log('❌ BDO user clear failed:', error);
                this.renderError(`Failed to clear BDO user: ${error.message}`);
            }
        }
        
        async clearFountUser() {
            console.log('🗑️ User clicked clear fount user');
            
            try {
                // Clear from extension storage (background script)
                if (typeof browser !== 'undefined' && browser.storage) {
                    await new Promise((resolve) => {
                        browser.storage.local.remove('fountUser', resolve);
                    });
                }
                
                // Also clear from Swift UserDefaults via native message
                await this.bdoClient.bridge.sendToSwift('clearFountUser');
                
                // Show success message
                if (this.spellsList) {
                    this.spellsList.innerHTML = `
                        <div class="success-state">
                            <span class="success-icon">🗑️</span>
                            <h3>Fount User Cleared</h3>
                            <p>Stored fount user has been cleared from both extension and Swift storage. A new user will be created on next spell cast.</p>
                        </div>
                    `;
                }
                
                console.log('✅ Fount user cleared successfully');
                
            } catch (error) {
                console.log('❌ Fount user clear failed:', error);
                this.renderError(`Failed to clear fount user: ${error.message}`);
            }
        }
        
        async clearAllData() {
            console.log('🗑️ User clicked clear all data');
            
            try {
                // Clear all extension storage
                if (typeof browser !== 'undefined' && browser.storage) {
                    await new Promise((resolve) => {
                        browser.storage.local.clear(resolve);
                    });
                }
                
                // Clear Swift UserDefaults for both BDO and fount users
                await this.bdoClient.bridge.sendToSwift('clearFountUser');
                await this.bdoClient.bridge.sendToSwift('clearBdoUser');
                
                // Show success message
                if (this.spellsList) {
                    this.spellsList.innerHTML = `
                        <div class="success-state">
                            <span class="success-icon">🧹</span>
                            <h3>All Data Cleared</h3>
                            <p>All stored data has been cleared from both extension and Swift storage. Fresh users will be created on next use.</p>
                            <button class="action-btn primary" onclick="location.reload()">
                                <span class="btn-icon">🔄</span>
                                Reload Popup
                            </button>
                        </div>
                    `;
                }
                
                console.log('✅ All data cleared successfully');
                
            } catch (error) {
                console.log('❌ Clear all data failed:', error);
                this.renderError(`Failed to clear all data: ${error.message}`);
            }
        }

        async loadSpellbook() {
            const testEnvironment = 'http://127.0.0.1:5114';
            
            try {
                this.showLoading(true);
                const result = await this.bdoClient.getSpellbook(testEnvironment);
                
                console.log('🧪 Popup received getSpellbook result:', result);
                console.log('🧪 result.spellbooks:', result.spellbooks);
                console.log('🧪 result.data:', result.data);
                console.log('🧪 result.data?.spellbooks:', result.data?.spellbooks);
                
                if (result.data?.spellbooks) {
                    // Handle Swift's nested structure: { data: { spellbooks: [...] } }
                    console.log('✅ Using result.data.spellbooks');
                    this.renderSpells(result.data.spellbooks);
                } else if (result.spellbooks) {
                    // Handle direct spellbooks array
                    console.log('✅ Using result.spellbooks');
                    this.renderSpells(result.spellbooks);
                } else {
                    console.warn('⚠️ No spellbooks found in result:', result);
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
                        ${spellbook.spellTest ? `
                        <div class="spell-section">
                            <strong>🧪 Test Destinations:</strong>
                            <div class="destinations">
                                ${spellbook.spellTest.destinations?.map(dest => 
                                    `<span class="destination-tag">🔗 ${dest.stopName}</span>`
                                ).join('') || 'None'}
                            </div>
                        </div>
                        ` : ''}
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
                            ${spellbook.spellTest ? `<span class="cost-tag">💰 Test Cost: ${spellbook.spellTest.cost || 'N/A'}</span>` : ''}
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
