//
//  AppDelegate.swift
//  iOS (App)
//
//  Created by Zach Babb on 8/23/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Check if user needs onboarding
        checkOnboardingStatus()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func checkOnboardingStatus() {
        // Check if user has completed onboarding by checking if they have a pubKey
        if SharedUserDefaults.getCurrentUserPubKey() == nil {
            NSLog("🔔 First launch detected - showing onboarding")
            // Onboarding will be shown via SceneDelegate
        } else {
            NSLog("✅ User already onboarded")
        }
    }

}
