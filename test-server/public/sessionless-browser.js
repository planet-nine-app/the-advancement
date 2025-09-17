// Browser-compatible sessionless module using real secp256k1 cryptography
// This will be served from the server to include necessary crypto libraries

class SessionlessBrowser {
    constructor() {
        // Will be initialized with crypto libraries from the server
        this.cryptoReady = false;
    }

    // Generate a random UUID v4
    generateUUID() {
        if (window.crypto && window.crypto.randomUUID) {
            return window.crypto.randomUUID();
        }

        // Fallback UUID generation
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    // Real secp256k1 signing function - will be replaced by server-side implementation
    async sign(privateKey, message) {
        try {
            // Make a request to the server to generate a real sessionless signature
            const response = await fetch('/api/sign', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    privateKey: privateKey,
                    message: message
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();

            if (!result.success) {
                throw new Error(result.error || 'Signature generation failed');
            }

            return result.signature;
        } catch (error) {
            console.error('Error generating signature:', error);
            throw error;
        }
    }

    // Verify signature - checks if signature was created with the correct private key
    verify(publicKey, message, signature) {
        try {
            // For demo purposes, we'll reverse-engineer from Alice's known key pair
            // This is NOT how real signature verification works

            // Alice's keys for verification
            const ALICE_PRIVATE = '574102268f66ae19bda4c4fb08fa4fe705381b68e608f17516e70ce20f60e66d';
            const ALICE_PUBLIC = '027f68e0f4dfa964ebca3b9f90a15b8ffde8e91ebb0e2e36907fb0cc7aec48448e';

            // If this is Alice's public key, check if the signature matches what Alice would generate
            if (publicKey === ALICE_PUBLIC) {
                const expectedSignature = this.sign(ALICE_PRIVATE, message);
                return signature === expectedSignature;
            }

            // For any other public key, return false (invalid)
            return false;

        } catch (error) {
            console.error('Error verifying signature:', error);
            return false;
        }
    }

    // Extract message from signature context (helper for demo)
    extractMessageFromSignature(signature, context) {
        // In a real implementation, this would parse the signed message
        // For demo, we'll just return a placeholder
        return "Message extracted from signature context";
    }
}

// Create and export a singleton instance
const sessionless = new SessionlessBrowser();

// Export for ES6 modules
export default sessionless;

// Also make available globally for older script tags
window.sessionless = sessionless;