import Cocoa
import SafariServices

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide from dock since this is primarily a background service
        NSApp.setActivationPolicy(.accessory)
        
        print("The Advancement macOS app started")
        print("Safari Web Extension companion app ready")
        
        // Check if Safari Web Extension is enabled
        checkExtensionStatus()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("The Advancement app terminating")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running in background
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