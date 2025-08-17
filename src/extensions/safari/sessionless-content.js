// ========================================
// sessionless-content.js
// Content script for native Sessionless Safari extension
// ========================================

(function() {
    'use strict';
    
    // Prevent multiple injections
    if (window.Sessionless) {
        return;
    }
    
    // Create global Sessionless object for web pages
    window.Sessionless = {
        
        /**
         * Generate a new keypair in the native app
         * @param {string} [seedPhrase] - Optional seed phrase for deterministic key generation
         * @returns {Promise<{publicKey: string, address: string}>}
         */
        generateKeys: function(seedPhrase) {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('generateKeys', {
                    requestId: requestId,
                    seedPhrase: seedPhrase
                });
            });
        },
        
        /**
         * Sign a message with the stored private key (happens in native app)
         * @param {string} message - The message to sign
         * @returns {Promise<{signature: string}>}
         */
        sign: function(message) {
            return new Promise((resolve, reject) => {
                if (!message || typeof message !== 'string') {
                    reject(new Error('Message must be a non-empty string'));
                    return;
                }
                
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('sign', {
                    requestId: requestId,
                    message: message
                });
            });
        },
        
        /**
         * Get the public key from native app
         * @returns {Promise<{publicKey: string}>}
         */
        getPublicKey: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('getPublicKey', {
                    requestId: requestId
                });
            });
        },
        
        /**
         * Get the address from native app
         * @returns {Promise<{address: string}>}
         */
        getAddress: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('getAddress', {
                    requestId: requestId
                });
            });
        },
        
        /**
         * Check if keys exist in native app
         * @returns {Promise<{hasKeys: boolean}>}
         */
        hasKeys: function() {
            return new Promise((resolve, reject) => {
                const requestId = generateRequestId();
                
                storeCallback(requestId, resolve, reject);
                
                safari.extension.dispatchMessage('hasKeys', {
                    requestId: requestId
                });
            });
        },
        
        /**
         * Create a user with native Sessionless authentication
         * High-level method that generates keys and signs registration
         * @param {string} [seedPhrase] - Optional seed phrase
         * @returns {Promise<{publicKey: string, address: string, signature: string, message: string}>}
         */
        createUser: function(seedPhrase) {
            return new Promise(async (resolve, reject) => {
                try {
                    // Generate keys in native app
                    const keys = await this.generateKeys(seedPhrase);
                    
                    // Create registration message
                    const timestamp = Date.now();
                    const message = `register:${keys.publicKey}:${timestamp}`;
                    
                    // Sign the registration message in native app
                    const signature = await this.sign(message);
                    
                    resolve({
                        publicKey: keys.publicKey,
                        address: keys.address,
                        signature: signature.signature,
                        message: message,
                        timestamp: timestamp
                    });
                } catch (error) {
                    reject(error);
                }
            });
        },
        
        /**
         * Authenticate with a server using Sessionless protocol
         * @param {string} challenge - Challenge from server
         * @returns {Promise<{signature: string, publicKey: string, address: string}>}
         */
        authenticate: function(challenge) {
            return new Promise(async (resolve, reject) => {
                try {
                    // Get current keys
                    const hasKeys = await this.hasKeys();
                    if (!hasKeys.hasKeys) {
                        reject(new Error('No keys found. Please generate keys first.'));
                        return;
                    }
                    
                    // Get public key and address
                    const [publicKey, address] = await Promise.all([
                        this.getPublicKey(),
                        this.getAddress()
                    ]);
                    
                    // Create authentication message
                    const timestamp = Date.now();
                    const authMessage = `auth:${challenge}:${publicKey.publicKey}:${timestamp}`;
                    
                    // Sign in native app
                    const signature = await this.sign(authMessage);
                    
                    resolve({
                        signature: signature.signature,
                        publicKey: publicKey.publicKey,
                        address: address.address,
                        message: authMessage,
                        timestamp: timestamp
                    });
                } catch (error) {
                    reject(error);
                }
            });
        },
        
        /**
         * Sign arbitrary data with native app
         * @param {Object} data - Data to sign
         * @returns {Promise<{signature: string, data: Object, timestamp: number}>}
         */
        signData: function(data) {
            return new Promise(async (resolve, reject) => {
                try {
                    const timestamp = Date.now();
                    const dataString = JSON.stringify({ ...data, timestamp });
                    
                    const signature = await this.sign(dataString);
                    
                    resolve({
                        signature: signature.signature,
                        data: data,
                        timestamp: timestamp,
                        signedMessage: dataString
                    });
                } catch (error) {
                    reject(error);
                }
            });
        },
        
        /**
         * Get complete identity info
         * @returns {Promise<{publicKey: string, address: string, hasKeys: boolean}>}
         */
        getIdentity: function() {
            return new Promise(async (resolve, reject) => {
                try {
                    const hasKeys = await this.hasKeys();
                    
                    if (!hasKeys.hasKeys) {
                        resolve({
                            publicKey: null,
                            address: null,
                            hasKeys: false
                        });
                        return;
                    }
                    
                    const [publicKey, address] = await Promise.all([
                        this.getPublicKey(),
                        this.getAddress()
                    ]);
                    
                    resolve({
                        publicKey: publicKey.publicKey,
                        address: address.address,
                        hasKeys: true
                    });
                } catch (error) {
                    reject(error);
                }
            });
        },
        
        /**
         * Utility method to verify the native app is connected
         * @returns {Promise<boolean>}
         */
        isNativeConnected: function() {
            return new Promise((resolve) => {
                const timeout = setTimeout(() => {
                    resolve(false);
                }, 5000); // 5 second timeout
                
                this.hasKeys().then(() => {
                    clearTimeout(timeout);
                    resolve(true);
                }).catch(() => {
                    clearTimeout(timeout);
                    resolve(false);
                });
            });
        },
        
        /**
         * Get version info
         * @returns {string}
         */
        version: '2.0.0',
        
        /**
         * Check if this is the native implementation
         * @returns {boolean}
         */
        isNative: true
    };
    
    // Private helper functions
    function generateRequestId() {
        return Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
    }
    
    function storeCallback(requestId, resolve, reject) {
        window._sessionlessCallbacks = window._sessionlessCallbacks || {};
        window._sessionlessCallbacks[requestId] = { 
            resolve: resolve, 
            reject: reject,
            timestamp: Date.now()
        };
        
        // Clean up old callbacks (older than 30 seconds)
        cleanupCallbacks();
    }
    
    function cleanupCallbacks() {
        if (!window._sessionlessCallbacks) return;
        
        const now = Date.now();
        const timeout = 30000; // 30 seconds
        
        for (const requestId in window._sessionlessCallbacks) {
            if (now - window._sessionlessCallbacks[requestId].timestamp > timeout) {
                const callback = window._sessionlessCallbacks[requestId];
                callback.reject(new Error('Request timeout'));
                delete window._sessionlessCallbacks[requestId];
            }
        }
    }
    
    // Handle responses from the Safari extension
    safari.extension.addEventListener('message', function(event) {
        if (event.name === 'sessionlessResponse') {
            const response = event.message;
            const requestId = response.requestId;
            
            if (requestId && window._sessionlessCallbacks && window._sessionlessCallbacks[requestId]) {
                const callbacks = window._sessionlessCallbacks[requestId];
                
                if (response.success) {
                    callbacks.resolve(response.data);
                } else {
                    callbacks.reject(new Error(response.error || 'Unknown error'));
                }
                
                // Clean up this specific callback
                delete window._sessionlessCallbacks[requestId];
            }
        }
    });
    
    // Dispatch ready event
    document.dispatchEvent(new CustomEvent('sessionlessReady', {
        detail: { 
            version: window.Sessionless.version,
            isNative: window.Sessionless.isNative
        }
    }));
    
    console.log('🔐 Sessionless Native Safari Extension loaded (v' + window.Sessionless.version + ')');
})();

// ========================================
// Example: Advanced Usage in Web Pages
// ========================================
/*
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Native Sessionless Demo</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; }
        .container { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .panel { background: #f8f9fa; padding: 20px; border-radius: 8px; border: 1px solid #e9ecef; }
        button { padding: 12px 24px; margin: 8px 4px; background: #007AFF; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; }
        button:hover { background: #0056CC; }
        button:disabled { background: #ccc; cursor: not-allowed; }
        #output { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 6px; margin-top: 20px; white-space: pre-wrap; font-family: 'SF Mono', Monaco, monospace; font-size: 13px; max-height: 400px; overflow-y: auto; }
        .error { color: #fc8181; }
        .success { color: #68d391; }
        .info { color: #63b3ed; }
        .status { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; margin-bottom: 10px; }
        .status.connected { background: #c6f6d5; color: #22543d; }
        .status.disconnected { background: #fed7d7; color: #742a2a; }
        h1 { color: #2d3748; margin-bottom: 10px; }
        h2 { color: #4a5568; font-size: 18px; margin-bottom: 15px; }
        .identity-card { background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 15px; margin: 10px 0; }
        .identity-card h3 { margin-top: 0; color: #2d3748; }
        .identity-card .field { margin: 8px 0; }
        .identity-card .label { font-weight: bold; color: #4a5568; }
        .identity-card .value { font-family: 'SF Mono', Monaco, monospace; font-size: 12px; color: #2d3748; word-break: break-all; }
    </style>
</head>
<body>
    <h1>🔐 Native Sessionless Demo</h1>
    <div id="connectionStatus" class="status disconnected">Checking connection...</div>
    
    <div class="container">
        <div class="panel">
            <h2>Key Management</h2>
            <button onclick="checkConnection()">Check Native Connection</button>
            <button onclick="checkHasKeys()">Check Has Keys</button>
            <button onclick="generateKeys()">Generate Random Keys</button>
            <button onclick="generateKeysWithSeed()">Generate Keys (Seed)</button>
            <button onclick="getIdentity()">Get Full Identity</button>
        </div>
        
        <div class="panel">
            <h2>Signing Operations</h2>
            <button onclick="signMessage()">Sign Custom Message</button>
            <button onclick="signData()">Sign JSON Data</button>
            <button onclick="createUser()">Create User Account</button>
            <button onclick="authenticate()">Authenticate</button>
        </div>
    </div>
    
    <div id="identity" class="identity-card" style="display: none;">
        <h3>Current Identity</h3>
        <div class="field">
            <div class="label">Public Key:</div>
            <div class="value" id="currentPublicKey">-</div>
        </div>
        <div class="field">
            <div class="label">Address:</div>
            <div class="value" id="currentAddress">-</div>
        </div>
        <div class="field">
            <div class="label">Has Keys:</div>
            <div class="value" id="currentHasKeys">-</div>
        </div>
    </div>
    
    <button onclick="clearOutput()" style="background: #6c757d;">Clear Output</button>
    
    <div id="output"></div>
    
    <script>
        let isConnected = false;
        
        function log(message, type = 'info') {
            const output = document.getElementById('output');
            const timestamp = new Date().toLocaleTimeString();
            const className = type === 'error' ? 'error' : type === 'success' ? 'success' : 'info';
            output.innerHTML += `<span class="${className}">[${timestamp}] ${message}</span>\n`;
            output.scrollTop = output.scrollHeight;
        }
        
        function clearOutput() {
            document.getElementById('output').innerHTML = '';
        }
        
        function updateConnectionStatus(connected) {
            isConnected = connected;
            const statusEl = document.getElementById('connectionStatus');
            if (connected) {
                statusEl.textContent = '✅ Native App Connected';
                statusEl.className = 'status connected';
            } else {
                statusEl.textContent = '❌ Native App Disconnected';
                statusEl.className = 'status disconnected';
            }
        }
        
        function updateIdentityCard(identity) {
            const card = document.getElementById('identity');
            if (identity && identity.hasKeys) {
                document.getElementById('currentPublicKey').textContent = identity.publicKey;
                document.getElementById('currentAddress').textContent = identity.address;
                document.getElementById('currentHasKeys').textContent = 'Yes';
                card.style.display = 'block';
            } else {
                document.getElementById('currentPublicKey').textContent = '-';
                document.getElementById('currentAddress').textContent = '-';
                document.getElementById('currentHasKeys').textContent = 'No';
                card.style.display = 'none';
            }
        }
        
        // Wait for Sessionless to be ready
        document.addEventListener('sessionlessReady', function(event) {
            log(`🚀 Sessionless extension ready! Version: ${event.detail.version} (Native: ${event.detail.isNative})`, 'success');
            checkConnection();
        });
        
        async function checkConnection() {
            try {
                log('🔍 Checking native app connection...');
                const connected = await Sessionless.isNativeConnected();
                updateConnectionStatus(connected);
                
                if (connected) {
                    log('✅ Native app is connected and responding', 'success');
                    // Auto-load identity if connected
                    getIdentity();
                } else {
                    log('❌ Native app is not responding', 'error');
                    log('Make sure the Sessionless native app is running', 'error');
                }
            } catch (error) {
                log(`❌ Connection check failed: ${error.message}`, 'error');
                updateConnectionStatus(false);
            }
        }
        
        async function checkHasKeys() {
            try {
                const result = await Sessionless.hasKeys();
                log(`Keys status: ${result.hasKeys ? 'Found' : 'Not found'}`, result.hasKeys ? 'success' : 'info');
                
                if (result.hasKeys) {
                    getIdentity();
                }
            } catch (error) {
                log(`❌ Error checking keys: ${error.message}`, 'error');
            }
        }
        
        async function generateKeys() {
            try {
                log('🔑 Generating new keypair in native app...');
                const result = await Sessionless.generateKeys();
                log('✅ Keys generated successfully!', 'success');
                log(`Public Key: ${result.publicKey}`);
                log(`Address: ${result.address}`);
                
                // Update identity display
                updateIdentityCard({
                    publicKey: result.publicKey,
                    address: result.address,
                    hasKeys: true
                });
            } catch (error) {
                log(`❌ Error generating keys: ${error.message}`, 'error');
            }
        }
        
        async function generateKeysWithSeed() {
            const seed = prompt('Enter seed phrase (for testing only):') || 'demo-seed-phrase-123';
            try {
                log(`🌱 Generating keypair from seed in native app...`);
                const result = await Sessionless.generateKeys(seed);
                log('✅ Keys generated from seed!', 'success');
                log(`Public Key: ${result.publicKey}`);
                log(`Address: ${result.address}`);
                
                updateIdentityCard({
                    publicKey: result.publicKey,
                    address: result.address,
                    hasKeys: true
                });
            } catch (error) {
                log(`❌ Error generating keys: ${error.message}`, 'error');
            }
        }
        
        async function getIdentity() {
            try {
                const identity = await Sessionless.getIdentity();
                
                if (identity.hasKeys) {
                    log('📋 Current identity:', 'success');
                    log(`  Public Key: ${identity.publicKey}`);
                    log(`  Address: ${identity.address}`);
                    updateIdentityCard(identity);
                } else {
                    log('ℹ️ No keys found', 'info');
                    updateIdentityCard(null);
                }
            } catch (error) {
                log(`❌ Error getting identity: ${error.message}`, 'error');
            }
        }
        
        async function signMessage() {
            const message = prompt('Enter message to sign:') || 'Hello from native Sessionless!';
            try {
                log(`✍️ Signing message in native app: "${message}"`);
                const result = await Sessionless.sign(message);
                log('✅ Message signed successfully!', 'success');
                log(`Signature: ${result.signature}`);
            } catch (error) {
                log(`❌ Error signing message: ${error.message}`, 'error');
            }
        }
        
        async function signData() {
            const data = {
                action: 'transfer',
                amount: 100,
                recipient: '0x1234567890abcdef',
                nonce: Math.floor(Math.random() * 1000000)
            };
            
            try {
                log('📊 Signing JSON data in native app...');
                log(`Data: ${JSON.stringify(data, null, 2)}`);
                
                const result = await Sessionless.signData(data);
                log('✅ Data signed successfully!', 'success');
                log(`Signature: ${result.signature}`);
                log(`Timestamp: ${result.timestamp}`);
            } catch (error) {
                log(`❌ Error signing data: ${error.message}`, 'error');
            }
        }
        
        async function createUser() {
            try {
                log('👤 Creating user with native Sessionless...');
                const result = await Sessionless.createUser();
                log('✅ User created successfully!', 'success');
                log(`Public Key: ${result.publicKey}`);
                log(`Address: ${result.address}`);
                log(`Registration Message: ${result.message}`);
                log(`Registration Signature: ${result.signature}`);
                
                updateIdentityCard({
                    publicKey: result.publicKey,
                    address: result.address,
                    hasKeys: true
                });
            } catch (error) {
                log(`❌ Error creating user: ${error.message}`, 'error');
            }
        }
        
        async function authenticate() {
            const challenge = 'server-challenge-' + Math.random().toString(36).substr(2, 9);
            try {
                log(`🔐 Authenticating with challenge: ${challenge}`);
                const result = await Sessionless.authenticate(challenge);
                log('✅ Authentication successful!', 'success');
                log(`Public Key: ${result.publicKey}`);
                log(`Address: ${result.address}`);
                log(`Auth Message: ${result.message}`);
                log(`Auth Signature: ${result.signature}`);
            } catch (error) {
                log(`❌ Authentication failed: ${error.message}`, 'error');
            }
        }
        
        // Auto-check connection on load
        setTimeout(() => {
            if (typeof Sessionless !== 'undefined') {
                checkConnection();
            } else {
                log('⏳ Waiting for Sessionless extension...', 'info');
            }
        }, 500);
    </script>
</body>
</html>
*/
