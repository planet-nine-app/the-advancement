/**
 * The Advancement - Background Service Worker
 * 
 * Handles extension lifecycle, messaging, and coordination between
 * content scripts and popup.
 */

console.log('🚀 The Advancement background service worker starting...');

// Extension lifecycle
browser.runtime.onInstalled.addListener((details) => {
  console.log('✅ The Advancement extension installed:', details.reason);
  
  // Initialize extension storage
  browser.storage.local.set({
    'advancement-version': browser.runtime.getManifest().version,
    'advancement-installed': Date.now(),
    'advancement-nineum-balance': 0
  });
});

browser.runtime.onStartup.addListener(() => {
  console.log('🔄 The Advancement extension startup');
});

// Message passing between content script and popup
browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('📨 Background received internal message:', request.type, 'from', sender.tab?.url || 'popup');
  
  switch (request.type) {
    case 'nineum-update':
      // Handle nineum balance updates
      handleNineumUpdate(request.data, sendResponse);
      return true; // Keep message channel open
      
    case 'spell-cast':
      // Handle spell casting events
      handleSpellCast(request.data, sendResponse);
      return true;
      
    case 'home-base-update':
      // Handle home base selection changes
      handleHomeBaseUpdate(request.data, sendResponse);
      return true;
      
    case 'get-extension-status':
      // Return extension status for popup
      sendResponse({
        success: true,
        data: {
          version: browser.runtime.getManifest().version,
          connected: true,
          features: ['sessionless', 'spellHandling', 'nineumRewards', 'homeBaseSelection']
        }
      });
      return true;
      
    case 'sessionless-generate-keys':
      // Handle key generation (fallback to mock for Web Extension)
      handleSessionlessGenerateKeys(request.data, sendResponse);
      return true;
      
    case 'sessionless-has-keys':
      // Check if keys exist
      handleSessionlessHasKeys(sendResponse);
      return true;
      
    case 'sessionless-get-public-key':
      // Get public key
      handleSessionlessGetPublicKey(sendResponse);
      return true;
      
    case 'sessionless-get-address':
      // Get address
      handleSessionlessGetAddress(sendResponse);
      return true;
      
    case 'sessionless-sign':
      // Sign message
      handleSessionlessSign(request.data, sendResponse);
      return true;
      
    case 'native-message':
      // Handle native messaging for Safari Web Extension
      handleNativeMessage(request.data, sendResponse);
      return true;
      
    case 'getBDOCard':
      // Handle BDO card retrieval requests
      handleGetBDOCard(request.bdoPubKey, sendResponse);
      return true;
      
    default:
      console.log('❓ Unknown message type:', request.type);
      sendResponse({ success: false, error: 'Unknown message type' });
      return false;
  }
});

// External message passing (from websites)
browser.runtime.onMessageExternal.addListener((request, sender, sendResponse) => {
  console.log('📨 Background received EXTERNAL message:', request.type, 'from', sender.tab?.url || 'external');
  console.log('📋 External message details:', request);
  
  switch (request.type) {
    case 'getBDOCard':
      // Handle BDO card retrieval requests from external websites
      console.log('📦 External request: getBDOCard for', request.bdoPubKey);
      handleGetBDOCard(request.bdoPubKey, sendResponse);
      return true; // Keep message channel open
      
    default:
      console.log('❓ Unknown external message type:', request.type);
      sendResponse({ success: false, error: 'Unknown external message type' });
      return false;
  }
});

// Nineum balance management
async function handleNineumUpdate(data, sendResponse) {
  try {
    const { amount, source } = data;
    
    // Get current balance
    const result = await browser.storage.local.get('advancement-nineum-balance');
    const currentBalance = result['advancement-nineum-balance'] || 0;
    const newBalance = currentBalance + amount;
    
    // Save new balance
    await browser.storage.local.set({
      'advancement-nineum-balance': newBalance,
      'advancement-last-nineum-source': source,
      'advancement-last-nineum-time': Date.now()
    });
    
    console.log(`⭐ Nineum updated: ${currentBalance} + ${amount} = ${newBalance} (from ${source})`);
    
    // Broadcast to all tabs
    broadcastToTabs({
      type: 'nineum-balance-updated',
      data: {
        previousBalance: currentBalance,
        newBalance: newBalance,
        amount: amount,
        source: source
      }
    });
    
    sendResponse({
      success: true,
      data: {
        previousBalance: currentBalance,
        newBalance: newBalance,
        amount: amount
      }
    });
    
  } catch (error) {
    console.error('❌ Error updating nineum:', error);
    sendResponse({ success: false, error: error.message });
  }
}

// Spell casting event handling
async function handleSpellCast(data, sendResponse) {
  try {
    const { spellName, cost, rewards } = data;
    
    console.log(`🪄 Spell cast: ${spellName} (cost: ${cost}, rewards: ${rewards})`);
    
    // Store spell history
    const spellHistory = await browser.storage.local.get('advancement-spell-history') || {};
    const history = spellHistory['advancement-spell-history'] || [];
    
    history.push({
      spellName,
      cost,
      rewards,
      timestamp: Date.now()
    });
    
    // Keep only last 100 spells
    if (history.length > 100) {
      history.splice(0, history.length - 100);
    }
    
    await browser.storage.local.set({
      'advancement-spell-history': history,
      'advancement-last-spell': spellName,
      'advancement-last-spell-time': Date.now()
    });
    
    sendResponse({ success: true, data: { spellName, timestamp: Date.now() } });
    
  } catch (error) {
    console.error('❌ Error handling spell cast:', error);
    sendResponse({ success: false, error: error.message });
  }
}

// Home base management
async function handleHomeBaseUpdate(data, sendResponse) {
  try {
    const { base } = data;
    
    await browser.storage.local.set({
      'advancement-home-base': JSON.stringify(base),
      'advancement-home-base-updated': Date.now()
    });
    
    console.log('🏠 Home base updated:', base.name);
    
    // Broadcast to all tabs
    broadcastToTabs({
      type: 'home-base-updated',
      data: { base }
    });
    
    sendResponse({ success: true, data: { base } });
    
  } catch (error) {
    console.error('❌ Error updating home base:', error);
    sendResponse({ success: false, error: error.message });
  }
}

// Broadcast message to all tabs
async function broadcastToTabs(message) {
  try {
    const tabs = await browser.tabs.query({});
    
    for (const tab of tabs) {
      try {
        await browser.tabs.sendMessage(tab.id, message);
      } catch (error) {
        // Ignore tabs that can't receive messages (chrome:// pages, etc.)
      }
    }
  } catch (error) {
    console.warn('⚠️ Error broadcasting to tabs:', error);
  }
}

// Tab management
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    console.log('📄 Page loaded:', tab.url);
    
    // Inject additional functionality if needed
    if (tab.url.includes('localhost:3456')) {
      console.log('🧪 Test page detected, ensuring full functionality');
    }
  }
});

// Handle extension icon clicks
browser.action.onClicked.addListener((tab) => {
  console.log('🖱️ Extension icon clicked, popup should open');
  // Popup will open automatically due to manifest configuration
});

// Error handling
self.addEventListener('error', (event) => {
  console.error('❌ Background script error:', event.error);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('❌ Unhandled promise rejection in background:', event.reason);
});

// Sessionless API handlers (delegate to content script's real implementation)
async function handleSessionlessGenerateKeys(data, sendResponse) {
  try {
    console.log('🔑 Background: Delegating key generation to content script');
    
    // The actual key generation will happen in the content script where
    // the sessionless crypto library is loaded. We just acknowledge the request.
    sendResponse({
      success: true,
      message: 'Key generation delegated to content script'
    });
    
  } catch (error) {
    console.error('❌ Key generation delegation error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

async function handleSessionlessHasKeys(sendResponse) {
  try {
    // Check extension storage for sessionless keys
    const result = await browser.storage.local.get('sessionless-keys');
    const hasKeys = !!result['sessionless-keys'];
    
    console.log('🔍 Background: Keys check result:', hasKeys);
    
    sendResponse({
      success: true,
      data: { hasKeys }
    });
    
  } catch (error) {
    console.error('❌ Has keys check error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

async function handleSessionlessGetPublicKey(sendResponse) {
  try {
    console.log('🔑 Background: Delegating public key retrieval to content script');
    
    // Delegate to content script where real sessionless is available
    sendResponse({
      success: true,
      message: 'Public key retrieval delegated to content script'
    });
    
  } catch (error) {
    console.error('❌ Get public key delegation error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

async function handleSessionlessGetAddress(sendResponse) {
  try {
    console.log('🔑 Background: Delegating address retrieval to content script');
    
    // Delegate to content script where real sessionless is available
    sendResponse({
      success: true,
      message: 'Address retrieval delegated to content script'
    });
    
  } catch (error) {
    console.error('❌ Get address delegation error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

async function handleSessionlessSign(data, sendResponse) {
  try {
    console.log('🔑 Background: Delegating message signing to content script');
    
    const { message } = data;
    if (!message) {
      sendResponse({ success: false, error: 'No message provided' });
      return;
    }
    
    // Delegate to content script where real sessionless is available
    sendResponse({
      success: true,
      message: 'Message signing delegated to content script'
    });
    
  } catch (error) {
    console.error('❌ Signing delegation error:', error);
    sendResponse({ success: false, error: error.message });
  }
}

// Safari Web Extension Native Messaging Handler
async function handleNativeMessage(data, sendResponse) {
  try {
    console.log('📤 Background: Sending native message:', data);
    
    // Use browser API for Safari Web Extension native messaging
    const response = await browser.runtime.sendNativeMessage(
      'com.planetnine.the-advancement.safari',
      data
    );
    
    console.log('📥 Background: Native app response:', response);
    
    sendResponse({
      success: true,
      data: response
    });
    
  } catch (error) {
    console.error('❌ Background: Native messaging error:', error);
    sendResponse({
      success: false,
      error: error.message
    });
  }
}

// BDO Card Retrieval Handler
async function handleGetBDOCard(bdoPubKey, sendResponse) {
  try {
    console.log(`📦 Background: Retrieving BDO card ${bdoPubKey}`);
    
    if (!bdoPubKey) {
      const errorResponse = {
        success: false,
        error: 'bdoPubKey is required'
      };
      console.log('📤 Background: Sending error response (missing bdoPubKey):', errorResponse);
      sendResponse(errorResponse);
      return;
    }
    
    // Use native messaging to handle BDO card retrieval via Swift
    const nativeRequest = {
      action: 'getBDOCard',
      bdoPubKey: bdoPubKey
    };
    
    // Check if we have Web Extension API
    if (typeof browser !== 'undefined' && browser.runtime) {
      console.log('📤 Background: Forwarding BDO card request to native app');
      
      try {
        const response = await browser.runtime.sendNativeMessage(
          'com.planetnine.the-advancement.safari',
          nativeRequest
        );
        
        console.log('📥 Background: Native app BDO response:', response);
        
        const finalResponse = {
          success: response?.success || false,
          data: response?.data || null,
          error: response?.error || (response?.success ? null : 'Failed to retrieve card from BDO')
        };
        
        console.log('📤 Background: Sending final response:', finalResponse);
        sendResponse(finalResponse);
        
      } catch (nativeError) {
        console.error('❌ Background: Native messaging error:', nativeError);
        
        const errorResponse = {
          success: false,
          error: `Native messaging failed: ${nativeError.message}`
        };
        console.log('📤 Background: Sending native error response:', errorResponse);
        sendResponse(errorResponse);
      }
      
    } else {
      // Fallback for environments without native messaging
      console.warn('⚠️ Native messaging not available, using fallback');
      
      const fallbackResponse = {
        success: false,
        error: 'BDO card retrieval not available in this environment - no native messaging'
      };
      console.log('📤 Background: Sending fallback response:', fallbackResponse);
      sendResponse(fallbackResponse);
    }
    
  } catch (error) {
    console.error('❌ Background: BDO card retrieval error:', error);
    
    const errorResponse = {
      success: false,
      error: error.message || 'Unknown BDO retrieval error'
    };
    console.log('📤 Background: Sending catch error response:', errorResponse);
    sendResponse(errorResponse);
  }
}

console.log('✅ The Advancement background service worker ready');