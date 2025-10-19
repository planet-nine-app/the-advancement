//
//  SceneDelegate.swift
//  iOS (App)
//
//  Created by Zach Babb on 8/23/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create window
        window = UIWindow(windowScene: windowScene)

        // Check if user needs onboarding
        let rootViewController: UIViewController
        if SharedUserDefaults.getCurrentUserPubKey() == nil {
            // Show onboarding
            rootViewController = OnboardingViewController()
            NSLog("🚀 Showing onboarding screen")
        } else {
            // Show main app with new SVG-based interface
            rootViewController = MainViewController()
            NSLog("✅ Showing main app")
        }

        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }

    private func createPlaceholderMainViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Welcome to The Advancement"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])

        return vc
    }

}
