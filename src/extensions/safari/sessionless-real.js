/**
 * Real Sessionless Implementation for Safari Extension
 * Self-contained cryptographic implementation using Web Crypto API
 * and noble-secp256k1 (if available) or fallback crypto
 */

// Real secp256k1 crypto implementation
class SessionlessCrypto {
    constructor() {
        this.isReady = false;
        this.secp = null;
        this.init();
    }

    async init() {
        // Wait for RealSecp256k1 to be available
        let attempts = 0;
        while (typeof window.RealSecp256k1 === 'undefined' && attempts < 100) {
            await new Promise(resolve => setTimeout(resolve, 50));
            attempts++;
        }

        if (typeof window.RealSecp256k1 !== 'undefined') {
            this.secp = window.RealSecp256k1;
            // Wait for secp to be ready
            while (!this.secp.isReady) {
                await new Promise(resolve => setTimeout(resolve, 10));
            }
            this.isReady = true;
            console.log('🔐 Using real secp256k1 implementation');
        } else {
            console.error('❌ RealSecp256k1 not available');
            this.isReady = false;
        }
    }

    // Generate a random private key
    async generatePrivateKey() {
        if (!this.isReady || !this.secp) {
            throw new Error('Secp256k1 not ready');
        }
        
        return await this.secp.generatePrivateKey();
    }

    // Derive compressed public key from private key
    async getPublicKey(privateKey) {
        if (!this.isReady || !this.secp) {
            throw new Error('Secp256k1 not ready');
        }
        
        return await this.secp.getPublicKey(privateKey);
    }

    // Sign a message using secp256k1
    async sign(message, privateKey) {
        if (!this.isReady || !this.secp) {
            throw new Error('Secp256k1 not ready');
        }
        
        return await this.secp.sign(message, privateKey);
    }

    // Verify signature using secp256k1
    async verifySignature(signature, message, publicKey) {
        if (!this.isReady || !this.secp) {
            throw new Error('Secp256k1 not ready');
        }
        
        return await this.secp.verifySignature(signature, message, publicKey);
    }

    // SHA-256 hash using Web Crypto API
    async sha256(message) {
        if (typeof window !== 'undefined' && window.crypto && window.crypto.subtle) {
            const encoder = new TextEncoder();
            const data = encoder.encode(message);
            const hash = await window.crypto.subtle.digest('SHA-256', data);
            return this.arrayBufferToHex(hash);
        } else {
            // Simple fallback hash (NOT cryptographically secure)
            let hash = 0;
            for (let i = 0; i < message.length; i++) {
                const char = message.charCodeAt(i);
                hash = ((hash << 5) - hash) + char;
                hash = hash & hash; // Convert to 32-bit integer
            }
            return Math.abs(hash).toString(16).padStart(64, '0');
        }
    }

    // Keccak-256 (simplified - in real implementation would use proper keccak)
    async keccak256(message) {
        // For now, use SHA-256 as fallback
        // In a real implementation, this would be proper Keccak-256
        return await this.sha256(message);
    }

    // Utility functions
    bytesToHex(bytes) {
        return Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    arrayBufferToHex(buffer) {
        return Array.from(new Uint8Array(buffer), byte => byte.toString(16).padStart(2, '0')).join('');
    }

    hexToBytes(hex) {
        const bytes = new Uint8Array(hex.length / 2);
        for (let i = 0; i < hex.length; i += 2) {
            bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
        }
        return bytes;
    }
}

// Initialize crypto
const crypto = new SessionlessCrypto();

// Storage class for secure key management
class SafariSessionlessStorage {
    constructor() {
        this.storageKey = 'sessionless-keys';
    }

    async saveKeys(keys) {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                await chrome.storage.local.set({
                    [this.storageKey]: JSON.stringify(keys)
                });
                console.log('🔐 Keys saved to extension storage');
                return true;
            } else {
                localStorage.setItem(this.storageKey, JSON.stringify(keys));
                console.log('🔐 Keys saved to localStorage (fallback)');
                return true;
            }
        } catch (error) {
            console.error('❌ Failed to save keys:', error);
            return false;
        }
    }

    async getKeys() {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                const result = await chrome.storage.local.get(this.storageKey);
                const keysString = result[this.storageKey];
                if (keysString) {
                    return JSON.parse(keysString);
                }
            } else {
                const keysString = localStorage.getItem(this.storageKey);
                if (keysString) {
                    return JSON.parse(keysString);
                }
            }
            return null;
        } catch (error) {
            console.error('❌ Failed to get keys:', error);
            return null;
        }
    }

    async hasKeys() {
        const keys = await this.getKeys();
        return !!keys;
    }

    async clearKeys() {
        try {
            if (typeof chrome !== 'undefined' && chrome.storage) {
                await chrome.storage.local.remove(this.storageKey);
            } else {
                localStorage.removeItem(this.storageKey);
            }
            return true;
        } catch (error) {
            console.error('❌ Failed to clear keys:', error);
            return false;
        }
    }
}

// Initialize storage
const storage = new SafariSessionlessStorage();

// Real Sessionless Implementation
window.RealSessionless = {
    version: '1.0.0-real',
    isNative: false,
    storage: storage,
    crypto: crypto,

    async generateKeys(seedPhrase = null) {
        try {
            console.log('🔑 Generating real cryptographic keys...');

            // Wait for crypto to be ready
            while (!crypto.isReady) {
                await new Promise(resolve => setTimeout(resolve, 10));
            }

            // Generate private key
            const privateKey = await crypto.generatePrivateKey();
            
            // Derive public key
            const pubKey = await crypto.getPublicKey(privateKey);

            const keys = {
                privateKey,
                pubKey
            };

            // Save keys
            await storage.saveKeys(keys);

            console.log('✅ Real cryptographic keys generated');
            console.log('📌 Public Key:', pubKey);
            
            return {
                publicKey: pubKey,
                privateKey: privateKey
            };

        } catch (error) {
            console.error('❌ Key generation failed:', error);
            throw error;
        }
    },

    async hasKeys() {
        try {
            const hasKeys = await storage.hasKeys();
            return { hasKeys };
        } catch (error) {
            console.error('❌ Failed to check keys:', error);
            return { hasKeys: false };
        }
    },

    async getPublicKey() {
        try {
            const keys = await storage.getKeys();
            if (!keys) {
                throw new Error('No keys found');
            }
            return { publicKey: keys.pubKey };
        } catch (error) {
            console.error('❌ Failed to get public key:', error);
            throw error;
        }
    },

    async getAddress() {
        try {
            const keys = await storage.getKeys();
            if (!keys) {
                throw new Error('No keys found');
            }
            
            // Simple address derivation (last 40 chars of public key)
            const address = '0x' + keys.pubKey.slice(-40);
            return { address };
        } catch (error) {
            console.error('❌ Failed to get address:', error);
            throw error;
        }
    },

    async sign(message) {
        try {
            if (!message || typeof message !== 'string') {
                throw new Error('Message must be a non-empty string');
            }

            // Wait for crypto to be ready
            while (!crypto.isReady) {
                await new Promise(resolve => setTimeout(resolve, 10));
            }

            const keys = await storage.getKeys();
            if (!keys) {
                throw new Error('No keys available for signing');
            }

            const signature = await crypto.sign(message, keys.privateKey);
            
            console.log('✅ Message signed successfully');
            return { signature };

        } catch (error) {
            console.error('❌ Message signing failed:', error);
            throw error;
        }
    },

    async verifySignature(signature, message, publicKey) {
        try {
            // Wait for crypto to be ready
            while (!crypto.isReady) {
                await new Promise(resolve => setTimeout(resolve, 10));
            }

            const isValid = await crypto.verifySignature(signature, message, publicKey);
            
            console.log('🔍 Signature verification:', isValid ? 'VALID' : 'INVALID');
            return { valid: isValid };

        } catch (error) {
            console.error('❌ Signature verification failed:', error);
            return { valid: false };
        }
    },

    async authenticate(challenge) {
        try {
            const signResult = await this.sign(challenge);
            const publicKeyResult = await this.getPublicKey();
            
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

    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    },

    async clearKeys() {
        try {
            await storage.clearKeys();
            return { success: true };
        } catch (error) {
            console.error('❌ Failed to clear keys:', error);
            return { success: false };
        }
    }
};

console.log('🔐 Real Sessionless implementation loaded (self-contained)');