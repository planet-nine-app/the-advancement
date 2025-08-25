/**
 * Background script for Safari native messaging
 */

console.log('🔧 The Advancement background script loaded');

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

// Handle messages from popup
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    console.log('📨 Background received message:', message);
    console.log('📨 Message type:', message.type);
    console.log('📨 Message payload:', message.payload);
    
    if (message.type === 'nativeMessage') {
        console.log('🔧 Background forwarding to Swift...');
        
        // Forward to Swift via native messaging
        browser.runtime.sendNativeMessage(
            "com.planetnine.the-advancement.The-Advancement",
            message.payload,
            //                              { action: "generateKeys", requestId: Date.now().toString() },
            (response) => {
                console.log('📥 Background received Swift response:', response);
                
                if (browser.runtime.lastError) {
                    console.log('❌ Background native messaging error:', browser.runtime.lastError);
                    sendResponse({
                        success: false,
                        error: browser.runtime.lastError.message
                    });
                } else {
                    console.log('✅ Background forwarding Swift response to popup');
                    sendResponse(response);
                }
            }
        );
        
        // Return true to indicate async response
        return true;
    } else {
        console.log('❌ Background: Unknown message type:', message.type);
    }
    
    return false;
});

console.log('✅ Background script ready for native messaging');
