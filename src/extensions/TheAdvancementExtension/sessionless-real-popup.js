/**
 * Safari Web Extension Popup - Direct Native Messaging
 * Popup → browser.runtime.sendNativeMessage() → Swift Native App
 */

(function() {
    'use strict';

    class RealSessionlessPopup {
        constructor() {
            this.uuid = null;
            this.hash = 'advancement-popup';
            this.loadFromStorage();
        }

        // Direct native messaging to Swift - handles full spellbook flow
        async getSpellbooks(baseUrl) {
            const nativeMessage = {
                action: 'getSpellbook',
                baseUrl: baseUrl,
                requestId: Date.now().toString()
            };
            
            console.log('📤 JS→Swift: Sending getSpellbook message:', nativeMessage);
            
            return new Promise((resolve, reject) => {
                browser.runtime.sendNativeMessage("com.planetnine.theadvancement", nativeMessage, (response) => {
                    console.log('📥 Swift→JS: Received spellbook response:', response);
                    
                    if (browser.runtime.lastError) {
                        console.log('❌ Native messaging error:', browser.runtime.lastError);
                        reject(new Error(browser.runtime.lastError.message));
                    } else if (response && response.success) {
                        resolve(response.data);
                    } else {
                        reject(new Error(response?.error || 'Spellbook request failed'));
                    }
                });
            });
        }

        // Storage management (UUID only)
        saveToStorage() {
            const data = { uuid: this.uuid, hash: this.hash };
            localStorage.setItem('advancement-real-sessionless', JSON.stringify(data));
        }

        loadFromStorage() {
            try {
                const stored = localStorage.getItem('advancement-real-sessionless');
                if (stored) {
                    const data = JSON.parse(stored);
                    this.uuid = data.uuid;
                    this.hash = data.hash;
                }
            } catch (error) {
                // Storage load failed
            }
        }

        getUUID() {
            return this.uuid;
        }
    }

    window.RealSessionlessPopup = RealSessionlessPopup;

})();