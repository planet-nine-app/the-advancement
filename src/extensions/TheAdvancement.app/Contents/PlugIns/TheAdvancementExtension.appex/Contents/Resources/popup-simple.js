/**
 * Simplified Safari Extension Popup
 * Direct communication: Popup → browser.runtime.sendNativeMessage() → Swift
 */

(function() {
    'use strict';

    // Simple BDO client that delegates everything to Swift
    class BDOClient {
        constructor() {
            this.sessionless = new RealSessionlessPopup();
        }

        async getSpellbook(baseUrl) {
            return await this.sessionless.getSpellbooks(baseUrl);
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
            
            if (this.refreshBtn) {
                this.refreshBtn.addEventListener('click', () => this.refreshSpellbook());
            }
            
            // Auto-load on startup
            this.loadSpellbook();
        }

        async refreshSpellbook() {
            console.log('🔄 User clicked refresh spellbook');
            await this.loadSpellbook();
        }

        async loadSpellbook() {
            const testEnvironment = 'http://127.0.0.1:5114';
            
            try {
                this.showLoading(true);
                const result = await this.bdoClient.getSpellbook(testEnvironment);
                
                if (result.spells) {
                    this.renderSpells(result.spells);
                } else {
                    this.renderError('No spells in response');
                }
                
            } catch (error) {
                this.renderError(error.message);
            } finally {
                this.showLoading(false);
            }
        }

        renderSpells(spells) {
            if (!this.spellsList) return;
            
            if (!spells || spells.length === 0) {
                this.spellsList.innerHTML = '<div class="empty-state">📦 No spells available</div>';
                return;
            }

            const spellsHtml = spells.map(spell => `
                <div class="spell-card">
                    <h4>🪄 ${spell.name}</h4>
                    <p>${spell.description}</p>
                    <div class="spell-stats">
                        <span>💎 ${spell.cost} MP</span>
                        <span>⚗️ ${spell.resolver}</span>
                    </div>
                </div>
            `).join('');

            this.spellsList.innerHTML = spellsHtml;
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