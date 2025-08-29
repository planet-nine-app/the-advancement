/**
 * Background script for Safari native messaging and spellbook management
 */

console.log('🔧 The Advancement background script loaded');

// ========================================
// Spellbook Manager for Background Script
// ========================================

class BackgroundSpellbookManager {
    constructor() {
        this.spellbook = null;
        this.lastFetch = null;
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    }

    async fetchSpellbookFromSwift(homeBase) {
        try {
            console.log('🔍 Background fetching spellbook via Swift...');

            // Use homeBase to determine BDO endpoint  
            let bdoUrl;
            if (homeBase?.env === 'test') {
                bdoUrl = 'http://127.0.0.1:5114/';
            } else if (homeBase?.env === 'local') {
                bdoUrl = 'http://localhost:3003/';
            } else {
                bdoUrl = 'https://dev.bdo.allyabase.com/';
            }

            console.log(`📡 Background requesting spellbook from: ${bdoUrl}`);

            // Send getSpellbook request to Swift (proper authentication)
            const response = await new Promise((resolve, reject) => {
                browser.runtime.sendNativeMessage(
                    "com.planetnine.the-advancement.The-Advancement",
                    {
                        action: 'getSpellbook',
                        baseUrl: bdoUrl,
                        requestId: Date.now().toString()
                    },
                    (swiftResponse) => {
                        if (browser.runtime.lastError) {
                            reject(new Error(browser.runtime.lastError.message));
                        } else {
                            resolve(swiftResponse);
                        }
                    }
                );
            });

            // Parse nested Swift response structure
            let actualSpellbook = null;
            
            if (response?.data?.spellbooks?.[0]?.spellbookName) {
                // Swift returns: { data: { spellbooks: [{ spellbookName: ..., spellTest: ... }] } }
                actualSpellbook = response.data.spellbooks[0];
                console.log('actual spellbook as expected', actualSpellbook)
            } else if (response?.spellbooks?.spellbookName) {
                // Fallback: direct spellbooks property
                actualSpellbook = response.spellbooks;
                console.log('actualSpellbook is unexpected, but still ok', actualSpellbook);
            }
            
            if (actualSpellbook?.spellbookName) {
                this.spellbook = actualSpellbook;
                this.lastFetch = Date.now();
                
                console.log('✅ Background successfully retrieved spellbook via Swift:', this.spellbook.spellbookName);
                console.log('📊 Background available spells:', Object.keys(this.spellbook).filter(key => key !== 'spellbookName'));
                console.log('this.spellbook here is: ', this.spellbook);
                
                return this.spellbook;
            } else {
                console.error('❌ Invalid Swift response structure:', response);
                throw new Error('No valid spellbook in Swift response');
            }

        } catch (error) {
            console.error('❌ Background failed to fetch spellbook via Swift:', error);
            throw error;
        }
    }

    async getSpellbook(homeBase) {
        // Check cache first
        if (this.spellbook && this.lastFetch && 
            (Date.now() - this.lastFetch) < this.cacheTimeout) {
            console.log('📦 Background using cached spellbook');
            return this.spellbook;
        }

        // Fetch fresh spellbook via Swift
        return await this.fetchSpellbookFromSwift(homeBase);
    }

    getSpellInfo(spellName) {
        if (!this.spellbook || !this.spellbook[spellName]) {
            return null;
        }

        return {
            name: spellName,
            ...this.spellbook[spellName],
            spellbookName: this.spellbook.spellbookName
        };
    }

    async refreshSpellbook(homeBase) {
        console.log('🔄 Background refreshing spellbook...');
        this.lastFetch = null; // Force refresh
        return await this.getSpellbook(homeBase);
    }
}

// Initialize spellbook manager - but it will get data through Swift, not direct HTTP
const spellbookManager = new BackgroundSpellbookManager();

// ========================================
// Spell Handling Functions
// ========================================

async function handleMagicSpell(message, spellInfo, homeBase, sendResponse) {
    console.log(`🔮 [STEP 3/6] BACKGROUND: Handling MAGIC spell: ${spellInfo.name}`);
    console.log(`💰 [STEP 3/6] BACKGROUND: Spell cost: ${spellInfo.cost}, resolver: ${spellInfo.resolver}`);
    console.log(`🎯 [STEP 3/6] BACKGROUND: Destinations:`, spellInfo.destinations);
    
    try {
        // Get first destination URL for Swift
        const firstDestination = spellInfo.destinations?.[0];
        if (!firstDestination) {
            throw new Error('No destinations found in spell');
        }
        
        console.log(`🏁 [STEP 3/6] BACKGROUND: First destination:`, firstDestination);
        console.log(`🌐 [STEP 3/6] BACKGROUND: First destination URL: ${firstDestination.stopURL}`);
        
        // Create MAGIC protocol payload
        console.log(`👤 [STEP 3/6] BACKGROUND: Getting fount user...`);
        const fountUser = await getFountUser(); // Get or create fount user
        console.log(`👤 [STEP 3/6] BACKGROUND: Fount user:`, fountUser);
        
        const magicPayload = {
            timestamp: Date.now().toString(),
            spell: spellInfo.name,
            casterUUID: fountUser.uuid,
            totalCost: spellInfo.cost,
            mp: spellInfo.mp,
            ordinal: fountUser.ordinal + 1,
            casterSignature: null, // Will be signed by Swift
            gateways: [] // Initially empty
        };
        
        console.log(`🔮 [STEP 3/6] BACKGROUND: MAGIC payload created:`, magicPayload);
        
        // Prepare native message for Swift to handle signature and casting
        const nativePayload = {
            action: 'castSpell',
            requestId: Date.now().toString(),
            spellName: spellInfo.name,
            magicPayload: magicPayload,
            destinations: spellInfo.destinations,
            firstDestinationURL: firstDestination.stopURL
        };
        
        console.log(`📤 [STEP 3/6] BACKGROUND: Sending to Swift:`, nativePayload);
        console.log(`🎯 [STEP 3/6] BACKGROUND: Swift will POST to: ${firstDestination.stopURL}${spellInfo.name}`);
        
        // Send to Swift for signature and casting
        browser.runtime.sendNativeMessage(
            "com.planetnine.the-advancement.The-Advancement",
            nativePayload,
            (response) => {
                console.log(`📥 [STEP 5/6] BACKGROUND: Received response from Swift:`, response);
                
                if (browser.runtime.lastError) {
                    console.error(`❌ [STEP 5/6] BACKGROUND: Native messaging error:`, browser.runtime.lastError);
                    sendResponse({
                        success: false,
                        error: browser.runtime.lastError.message
                    });
                } else if (response && response.success) {
                    console.log(`✅ [STEP 5/6] BACKGROUND: MAGIC spell completed successfully`);
                    console.log(`📤 [STEP 5/6] BACKGROUND: Forwarding response to content script...`);
                    let extra = {};
                    if(response.data && response.data.testServerResponse) {
                        extra = JSON.parse(JSON.stringify(response.data.testServerResponse));
                    }
                    
                    // Create clean response object that Safari can serialize
                    const cleanResponse = {
                        success: true,
                        data: {
                            message: `${spellInfo.name} completed successfully`,
                            extra,
                            spellName: spellInfo.name,
                            timestamp: Date.now()
                        }
                    };

                    console.log(`📤 [STEP 5/6] BACKGROUND: Sending clean response:`, cleanResponse);
                    sendResponse(cleanResponse);
                } else {
                    console.error(`❌ [STEP 5/6] BACKGROUND: Swift response error:`, response?.error || 'Unknown error');
                    sendResponse({
                        success: false,
                        error: response?.error || 'Unknown error from Swift'
                    });
                }
            }
        );
        
    } catch (error) {
        console.error(`❌ [STEP 3/6] BACKGROUND: MAGIC spell exception:`, error);
        sendResponse({
            success: false,
            error: error.message
        });
    }
}

async function handleRegularSpell(message, spellInfo, sendResponse) {
    console.log('⚡ Background handling regular spell:', spellInfo.name);
    
    try {
        // For regular spells, handle locally without native messaging
        // This would be for spells that don't need cryptographic signatures
        
        console.log('✅ Background regular spell completed');
        sendResponse({
            success: true,
            message: `Regular spell "${spellInfo.name}" completed`,
            data: {
                spellName: spellInfo.name,
                cost: spellInfo.cost,
                completed: true
            }
        });
        
    } catch (error) {
        console.error('❌ Background regular spell error:', error);
        sendResponse({
            success: false,
            error: error.message
        });
    }
}

// Helper function to get or create fount user
async function getFountUser() {
    try {
        // Try to get existing fount user from storage
        const stored = await new Promise((resolve) => {
            browser.storage.local.get('fountUser', (result) => {
                resolve(result.fountUser);
            });
        });
        
        if (stored && stored.uuid && stored.ordinal !== undefined) {
            console.log('🔍 Background: Using stored fount user:', stored);
            return stored;
        }
        
        // No stored user, create new one via Swift
        console.log('👤 Background: Creating new fount user via Swift...');
        const fountUser = await createFountUserViaSwift();
        
        // Store the user for future use
        await new Promise((resolve) => {
            browser.storage.local.set({ fountUser: fountUser }, resolve);
        });
        
        console.log('✅ Background: Created and stored new fount user:', fountUser);
        return fountUser;
        
    } catch (error) {
        console.error('❌ Background: Failed to get/create fount user:', error);
        throw error;
    }
}

// Create fount user via Swift native messaging
async function createFountUserViaSwift() {
    return new Promise((resolve, reject) => {
        browser.runtime.sendNativeMessage(
            "com.planetnine.the-advancement.The-Advancement",
            {
                action: 'createFountUser',
                requestId: Date.now().toString()
            },
            (response) => {
                if (browser.runtime.lastError) {
                    reject(new Error(browser.runtime.lastError.message));
                } else if (response && response.success && response.data) {
                    resolve(response.data);
                } else {
                    reject(new Error(response?.error || 'Failed to create fount user'));
                }
            }
        );
    });
}

// Test direct native messaging on startup
browser.runtime.sendNativeMessage(
    "com.planetnine.the-advancement.The-Advancement", 
    { action: "test", requestId: Date.now().toString() }, 
    function(response) {
        console.log('📥 Background startup test response:', response);
        if (browser.runtime.lastError) {
            console.log('❌ Background startup native messaging error:', browser.runtime.lastError);
        }
    }
);

// Handle messages from popup and content scripts using Promise returns instead of sendResponse
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    console.log('📨 Background received message:', message);
    console.log('📨 Message type:', message.type);
    
    // Return Promises instead of using sendResponse callbacks
    if (message.type === 'castSpell') {
        return handleCastSpell(message, sender);
    } else if (message.type === 'clearFountUser' || message.type === 'clearBdoUser') {
        return handleClearAction(message.type);
    } else if (message.type === 'getSpellbook') {
        return handleGetSpellbook(message);
    } else if (message.type === 'getBDOCard') {
        return handleGetBDOCard(message, sender);
    } else if (message.type === 'nativeMessage') {
        return handleNativeMessage(message);
    } else if (message.type === 'magicSpell') {
        return handleMagicSpell(message);
    } else {
        console.log('❌ Background: Unknown message type:', message.type);
        return Promise.resolve({ success: false, error: `Unknown message type: ${message.type}` });
    }
});

// Promise-based handler functions
async function handleClearAction(messageType) {
    console.log('🗑️ Background handling clear action:', messageType);
    
    return new Promise((resolve, reject) => {
        // Send clear action directly to Swift
        browser.runtime.sendNativeMessage(
            "com.planetnine.the-advancement.The-Advancement",
            {
                action: messageType,
                requestId: Date.now().toString()
            },
            (response) => {
                console.log('📥 Background received clear response from Swift:', response);
                
                if (browser.runtime.lastError) {
                    console.error('❌ Background clear action error:', browser.runtime.lastError);
                    resolve({
                        success: false,
                        error: browser.runtime.lastError.message
                    });
                } else if (response && response.success) {
                    console.log('✅ Background clear action successful');
                    resolve({
                        success: true,
                        data: { message: `${messageType} completed successfully` }
                    });
                } else {
                    console.error('❌ Background clear action Swift error:', response?.error);
                    resolve({
                        success: false,
                        error: response?.error || 'Clear action failed'
                    });
                }
            }
        );
    });
}

async function handleMagicSpellPromise(message, spellInfo, homeBase) {
    console.log(`🔮 [STEP 3/6] BACKGROUND: Handling MAGIC spell: ${spellInfo.name}`);
    console.log(`💰 [STEP 3/6] BACKGROUND: Spell cost: ${spellInfo.cost}, resolver: ${spellInfo.resolver}`);
    console.log(`🎯 [STEP 3/6] BACKGROUND: Destinations:`, spellInfo.destinations);
    
    return new Promise((resolve, reject) => {
        // Get first destination URL for Swift
        const firstDestination = spellInfo.destinations?.[0];
        if (!firstDestination) {
            resolve({
                success: false,
                error: 'No destinations found in spell'
            });
            return;
        }
        
        console.log(`🏁 [STEP 3/6] BACKGROUND: First destination:`, firstDestination);
        console.log(`🌐 [STEP 3/6] BACKGROUND: First destination URL: ${firstDestination.stopURL}`);
        
        // Create MAGIC protocol payload
        console.log(`👤 [STEP 3/6] BACKGROUND: Getting fount user...`);
        getFountUser().then(fountUser => {
            console.log(`👤 [STEP 3/6] BACKGROUND: Fount user:`, fountUser);
            
            const magicPayload = {
                timestamp: Date.now().toString(),
                spell: spellInfo.name,
                casterUUID: fountUser.uuid,
                totalCost: spellInfo.cost,
                mp: spellInfo.mp,
                ordinal: fountUser.ordinal + 1,
                casterSignature: null,
                gateways: []
            };
            
            console.log(`🔮 [STEP 3/6] BACKGROUND: MAGIC payload created:`, magicPayload);
            
            const nativePayload = {
                action: 'castSpell',
                requestId: Date.now().toString(),
                spellName: spellInfo.name,
                magicPayload: magicPayload,
                destinations: spellInfo.destinations,
                firstDestinationURL: firstDestination.stopURL
            };
            
            console.log(`📤 [STEP 3/6] BACKGROUND: Sending to Swift:`, nativePayload);
            console.log(`🎯 [STEP 3/6] BACKGROUND: Swift will POST to: ${firstDestination.stopURL}${spellInfo.name}`);
            
            browser.runtime.sendNativeMessage(
                "com.planetnine.the-advancement.The-Advancement",
                nativePayload,
                (response) => {
                    console.log(`📥 [STEP 5/6] BACKGROUND: Received response from Swift:`, response);
                    
                    if (browser.runtime.lastError) {
                        console.error(`❌ [STEP 5/6] BACKGROUND: Native messaging error:`, browser.runtime.lastError);
                        resolve({
                            success: false,
                            error: browser.runtime.lastError.message
                        });
                    } else if (response && response.success) {
                        console.log(`✅ [STEP 5/6] BACKGROUND: MAGIC spell completed successfully`);
                        console.log(`📤 [STEP 5/6] BACKGROUND: Forwarding response to content script...`);
                        
                        // Create clean response object that Safari can serialize
                        const cleanResponse = {
                            success: true,
                            data: {
                                message: `${spellInfo.name} completed successfully`,
                                testServerResponse: response.data?.testServerResponse || null,
                                spellName: spellInfo.name,
                                timestamp: Date.now()
                            }
                        };
                        
                        console.log(`📤 [STEP 5/6] BACKGROUND: Sending clean response:`, cleanResponse);
                        resolve(cleanResponse);
                    } else {
                        console.error(`❌ [STEP 5/6] BACKGROUND: Swift response error:`, response?.error || 'Unknown error');
                        resolve({
                            success: false,
                            error: response?.error || 'Unknown error from Swift'
                        });
                    }
                }
            );
        }).catch(error => {
            console.error(`❌ [STEP 3/6] BACKGROUND: Error getting fount user:`, error);
            resolve({
                success: false,
                error: `Failed to get fount user: ${error.message}`
            });
        });
    });
}

async function handleCastSpell(message, sender) {
    try {
        console.log(`📥 [STEP 2/6] BACKGROUND: Received castSpell message:`, message);
        console.log(`🪄 [STEP 2/6] BACKGROUND: Spell name: ${message.spellName}`);
        
        try {
            // Get home base from storage or use default
            console.log(`🏠 [STEP 2/6] BACKGROUND: Getting home base from storage...`);
            const homeBase = await new Promise((resolve) => {
                browser.storage.local.get('selectedHomeBase', (result) => {
                    resolve(result.selectedHomeBase || { env: 'test' });
                });
            });
            
            console.log(`🏠 [STEP 2/6] BACKGROUND: Using home base:`, homeBase);
            
            // Try to get spell from current spellbook
            console.log(`📚 [STEP 2/6] BACKGROUND: Looking up spell "${message.spellName}" in spellbook...`);
            let spellInfo = spellbookManager.getSpellInfo(message.spellName);
            
            if (!spellInfo) {
                console.log(`⚠️ [STEP 2/6] BACKGROUND: Spell "${message.spellName}" not found in cache, refreshing spellbook...`);
                
                // Refresh spellbook and try again
                await spellbookManager.refreshSpellbook(homeBase);
                spellInfo = spellbookManager.getSpellInfo(message.spellName);
                
                if (!spellInfo) {
                    console.error(`❌ [STEP 2/6] BACKGROUND: Spell "${message.spellName}" not found even after refresh`);
                    return {
                        success: false,
                        error: `Spell "${message.spellName}" not found in spellbook`
                    };
                }
            }
            
            console.log(`✅ [STEP 2/6] BACKGROUND: Found spell:`, spellInfo);
            console.log(`🔮 [STEP 2/6] BACKGROUND: Spell details - cost: ${spellInfo.cost}, mp: ${spellInfo.mp}, destinations:`, spellInfo.destinations);
            
            // Handle different spell types
            if (spellInfo.mp === true) {
                console.log(`⚡ [STEP 2/6] BACKGROUND: MAGIC protocol spell detected - forwarding to Swift...`);
                // MAGIC protocol spell - send to Swift for signing and casting
                return await handleMagicSpellPromise(message, spellInfo, homeBase);
            } else {
                console.log(`🔄 [STEP 2/6] BACKGROUND: Regular spell detected - handling locally...`);
                // Regular spell - handle locally
                return await handleRegularSpellPromise(message, spellInfo);
            }
            
        } catch (error) {
            console.error(`❌ [STEP 2/6] BACKGROUND: Exception in spell casting:`, error);
            return {
                success: false,
                error: error.message
            };
        }
    } catch (error) {
        console.error(`❌ [STEP 2/6] BACKGROUND: Outer exception in handleCastSpell:`, error);
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * Handle BDO card retrieval for castSpell integration
 */
async function handleGetBDOCard(message, sender) {
    console.log('🃏 Background handling getBDOCard request:', message.bdoPubKey);
    
    try {
        const { bdoPubKey } = message;
        
        if (!bdoPubKey) {
            throw new Error('bdoPubKey is required');
        }
        
        // Determine BDO URL based on environment
        // For now, use dev environment - could be enhanced to detect user's selected base
        const bdoUrl = 'https://dev.bdo.allyabase.com/';
        
        console.log(`🔍 Background requesting card from BDO: ${bdoUrl} with pubKey: ${bdoPubKey}`);
        
        // Send getBDOCard request to Swift for authenticated retrieval
        const swiftResponse = await new Promise((resolve, reject) => {
            browser.runtime.sendNativeMessage(
                "com.planetnine.the-advancement.The-Advancement",
                {
                    action: 'getBDOCard',
                    bdoPubKey: bdoPubKey,
                    baseUrl: bdoUrl,
                    requestId: Date.now().toString()
                },
                (response) => {
                    if (browser.runtime.lastError) {
                        reject(new Error(browser.runtime.lastError.message));
                    } else {
                        resolve(response);
                    }
                }
            );
        });
        
        console.log('📡 Background received Swift BDO response:', swiftResponse);
        
        if (swiftResponse && swiftResponse.success && swiftResponse.data) {
            return {
                success: true,
                data: swiftResponse.data
            };
        } else {
            return {
                success: false,
                error: swiftResponse?.error || 'Failed to retrieve card from BDO'
            };
        }
        
    } catch (error) {
        console.error('❌ Background BDO card retrieval error:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

async function handleGetSpellbook(message) {
    console.log('📚 Background handling getSpellbook request from popup');
    
    try {
        // Parse base URL to determine environment
        const baseUrl = message.baseUrl;
        let homeBase = { env: 'dev' }; // default
        
        if (baseUrl?.includes('127.0.0.1:5114')) {
            homeBase = { env: 'test' };
        } else if (baseUrl?.includes('localhost:3003')) {
            homeBase = { env: 'local' };
        }
        
        console.log('🏠 Background determined home base from URL:', homeBase);
        
        // Use spellbook manager (with caching and Swift integration)
        const spellbook = await spellbookManager.getSpellbook(homeBase);
        
        // Format response for popup (expects spellbooks array)
        const response = {
            success: true,
            data: {
                spellbooks: [spellbook] // Wrap single spellbook in array for popup
            }
        };
        
        console.log('✅ Background returning cached/fresh spellbook to popup');
        return response;
        
    } catch (error) {
        console.error('❌ Background getSpellbook error:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

async function handleNativeMessage(message) {
    console.log('🔧 Background forwarding to Swift...');
    console.log('🔧 Action:', message.payload?.action);
    console.log('🔧 Full payload:', message.payload);
    
    return new Promise((resolve, reject) => {
        // Forward ALL native messages to Swift
        browser.runtime.sendNativeMessage(
            "com.planetnine.the-advancement.The-Advancement",
            message.payload,
            (response) => {
                console.log('📥 Background received Swift response:', response);
                
                if (browser.runtime.lastError) {
                    console.log('❌ Background native messaging error:', browser.runtime.lastError);
                    resolve({
                        success: false,
                        error: browser.runtime.lastError.message
                    });
                } else if (response && response.success) {
                    console.log('✅ Background forwarding successful Swift response');
                    resolve({
                        success: true,
                        data: response.data || response
                    });
                } else {
                    console.error('❌ Background Swift response error:', response?.error || 'Unknown error');
                    resolve({
                        success: false,
                        error: response?.error || 'Unknown error from Swift'
                    });
                }
            }
        );
    });
}

async function handleMagicSpell(message) {
    console.log('🪄 Background processing MAGIC spell:', message.action);
    // This would handle the magicSpell type if needed
    return {
        success: false,
        error: 'magicSpell type not fully implemented in Promise pattern yet'
    };
}

console.log('✅ Background script ready for native messaging');
