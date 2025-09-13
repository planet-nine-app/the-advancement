import Cocoa
import SafariServices

class SessionlessApp: NSApplication {
    
    override func finishLaunching() {
        super.finishLaunching()
        
        // Hide from dock since this is a background service
        setActivationPolicy(.accessory)
        
        print("The Advancement macOS app started")
        
        // Check Safari extension status
        checkExtensionStatus()
    }
    
    private func checkExtensionStatus() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: "com.planetnine.theadvancement.extension") { (state, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Extension error: \(error.localizedDescription)")
                    return
                }
                
                if let state = state {
                    if state.isEnabled {
                        print("✅ Safari Web Extension is enabled")
                    } else {
                        print("⚠️ Safari Web Extension is disabled")
                        print("💡 Please enable The Advancement extension in Safari preferences")
                    }
                } else {
                    print("❓ Could not determine extension state")
                }
            }
        }
    }
}
