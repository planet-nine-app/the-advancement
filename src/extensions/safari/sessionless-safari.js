/**
 * Sessionless Safari Extension Implementation
 * Real cryptographic implementation using noble-secp256k1 and secure storage
 */

// Import the sessionless bundle (includes noble-secp256k1 and keccak)
// This will be loaded via script tag in the extension

// Safari Extension secure storage interface
class SafariSessionlessStorage {
    constructor() {
        this.storageKey = 'sessionless-keys';
    }

    // Save keys securely using Chrome Extension storage API
    async saveKeys(keys) {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                await chrome.storage.local.set({
                    [this.storageKey]: JSON.stringify(keys)
                });
                console.log('🔐 Keys saved to extension storage');
                return true;
            } else {
                // Fallback to localStorage (less secure but functional for testing)
                localStorage.setItem(this.storageKey, JSON.stringify(keys));
                console.log('🔐 Keys saved to localStorage (fallback)');
                return true;
            }
        } catch (error) {
            console.error('❌ Failed to save keys:', error);
            return false;
        }
    }

    // Get keys from secure storage
    async getKeys() {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                const result = await chrome.storage.local.get(this.storageKey);
                const keysString = result[this.storageKey];
                if (keysString) {
                    console.log('🔓 Keys retrieved from extension storage');
                    return JSON.parse(keysString);
                }
            } else {
                // Fallback to localStorage
                const keysString = localStorage.getItem(this.storageKey);
                if (keysString) {
                    console.log('🔓 Keys retrieved from localStorage (fallback)');
                    return JSON.parse(keysString);
                }
            }
            console.log('🚫 No keys found in storage');
            return null;
        } catch (error) {
            console.error('❌ Failed to get keys:', error);
            return null;
        }
    }

    // Check if keys exist
    async hasKeys() {
        const keys = await this.getKeys();
        return !!keys;
    }

    // Clear stored keys
    async clearKeys() {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                await chrome.storage.local.remove(this.storageKey);
            } else {
                localStorage.removeItem(this.storageKey);
            }
            console.log('🗑️ Keys cleared from storage');
            return true;
        } catch (error) {
            console.error('❌ Failed to clear keys:', error);
            return false;
        }
    }
}

// Initialize storage
const safariStorage = new SafariSessionlessStorage();

// Safari Sessionless Implementation
window.SafariSessionless = {
    version: '1.0.0',
    isNative: false, // Set to true when using actual Safari native extension
    storage: safariStorage,

    /**
     * Generate new cryptographic keys using real secp256k1
     * @param {string} seedPhrase - Optional seed phrase for deterministic generation
     * @returns {Promise<{publicKey: string, privateKey: string}>}
     */
    async generateKeys(seedPhrase = null) {
        try {
            console.log('🔑 Generating real cryptographic keys...');

            // Check if sessionless bundle is available
            if (typeof window.sessionless === 'undefined') {
                throw new Error('Sessionless crypto library not loaded');
            }

            // Use the sessionless library to generate keys
            const keys = await window.sessionless.generateKeys(
                // saveKeys function
                async (keys) => {
                    await safariStorage.saveKeys(keys);
                },
                // getKeys function  
                async () => {
                    return await safariStorage.getKeys();
                }
            );

            console.log('✅ Real cryptographic keys generated');
            console.log('📌 Public Key:', keys.pubKey);
            
            return {
                publicKey: keys.pubKey,
                privateKey: keys.privateKey
            };

        } catch (error) {
            console.error('❌ Key generation failed:', error);
            throw error;
        }
    },

    /**
     * Check if cryptographic keys exist
     * @returns {Promise<{hasKeys: boolean}>}
     */
    async hasKeys() {
        try {
            const hasKeys = await safariStorage.hasKeys();
            return { hasKeys };
        } catch (error) {
            console.error('❌ Failed to check keys:', error);
            return { hasKeys: false };
        }
    },

    /**
     * Get the public key
     * @returns {Promise<{publicKey: string}>}
     */
    async getPublicKey() {
        try {
            const keys = await safariStorage.getKeys();
            if (!keys) {
                throw new Error('No keys found');
            }
            return { publicKey: keys.pubKey };
        } catch (error) {
            console.error('❌ Failed to get public key:', error);
            throw error;
        }
    },

    /**
     * Get the address (derived from public key)
     * @returns {Promise<{address: string}>}
     */
    async getAddress() {
        try {
            const keys = await safariStorage.getKeys();
            if (!keys) {
                throw new Error('No keys found');
            }
            
            // For now, use a simple derivation (in production, this would be proper address derivation)
            const address = '0x' + keys.pubKey.slice(-40);
            return { address };
        } catch (error) {
            console.error('❌ Failed to get address:', error);
            throw error;
        }
    },

    /**
     * Sign a message using the stored private key
     * @param {string} message - The message to sign
     * @returns {Promise<{signature: string}>}
     */
    async sign(message) {
        try {
            if (!message || typeof message !== 'string') {
                throw new Error('Message must be a non-empty string');
            }

            // Check if sessionless bundle is available
            if (typeof window.sessionless === 'undefined') {
                throw new Error('Sessionless crypto library not loaded');
            }

            // Set up the getKeys function for sessionless
            window.sessionless.getKeys = async () => {
                return await safariStorage.getKeys();
            };

            // Sign the message
            const signature = await window.sessionless.sign(message);
            
            console.log('✅ Message signed successfully');
            return { signature };

        } catch (error) {
            console.error('❌ Message signing failed:', error);
            throw error;
        }
    },

    /**
     * Verify a signature against a message and public key
     * @param {string} signature - The signature to verify
     * @param {string} message - The original message
     * @param {string} publicKey - The public key to verify against
     * @returns {Promise<{valid: boolean}>}
     */
    async verifySignature(signature, message, publicKey) {
        try {
            // Check if sessionless bundle is available
            if (typeof window.sessionless === 'undefined') {
                throw new Error('Sessionless crypto library not loaded');
            }

            const isValid = window.sessionless.verifySignature(signature, message, publicKey);
            
            console.log('🔍 Signature verification:', isValid ? 'VALID' : 'INVALID');
            return { valid: isValid };

        } catch (error) {
            console.error('❌ Signature verification failed:', error);
            return { valid: false };
        }
    },

    /**
     * Authenticate with a challenge (sign + verify flow)
     * @param {string} challenge - The challenge to authenticate against
     * @returns {Promise<{success: boolean, signature: string, timestamp: number}>}
     */
    async authenticate(challenge) {
        try {
            const signResult = await this.sign(challenge);
            const publicKeyResult = await this.getPublicKey();
            
            // Verify the signature we just created
            const verifyResult = await this.verifySignature(
                signResult.signature, 
                challenge, 
                publicKeyResult.publicKey
            );

            if (!verifyResult.valid) {
                throw new Error('Self-verification failed');
            }

            return {
                success: true,
                signature: signResult.signature,
                publicKey: publicKeyResult.publicKey,
                timestamp: Date.now()
            };

        } catch (error) {
            console.error('❌ Authentication failed:', error);
            throw error;
        }
    },

    /**
     * Generate a UUID (utility function)
     * @returns {string}
     */
    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    },

    /**
     * Clear all stored keys (for testing/reset)
     * @returns {Promise<{success: boolean}>}
     */
    async clearKeys() {
        try {
            await safariStorage.clearKeys();
            return { success: true };
        } catch (error) {
            console.error('❌ Failed to clear keys:', error);
            return { success: false };
        }
    }
};

console.log('🔐 Safari Sessionless implementation loaded');