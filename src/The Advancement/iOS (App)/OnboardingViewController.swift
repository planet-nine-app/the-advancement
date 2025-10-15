//
//  OnboardingViewController.swift
//  The Advancement
//
//  Onboarding flow for creating users across Planet Nine services
//

import UIKit

class OnboardingViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Greetings Human.\nWould you like to join\nThe Advancement?"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0) // Glowing green
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        // Add glow effect
        label.layer.shadowColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8).cgColor
        label.layer.shadowRadius = 20
        label.layer.shadowOpacity = 1.0
        label.layer.shadowOffset = .zero

        return label
    }()

    private let yesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Yes", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.6).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false

        // Add glow effect
        button.layer.shadowColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.6).cgColor
        button.layer.shadowRadius = 15
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = .zero

        return button
    }()

    private let hellYesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Hell Yes", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.6).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false

        // Add glow effect
        button.layer.shadowColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.6).cgColor
        button.layer.shadowRadius = 15
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = .zero

        return button
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Initiating connection to Planet Nine..."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.7)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Dark purplish background
        view.backgroundColor = UIColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 1.0)

        setupUI()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(yesButton)
        view.addSubview(hellYesButton)
        view.addSubview(loadingLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            // Yes button
            yesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            yesButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            yesButton.widthAnchor.constraint(equalToConstant: 200),
            yesButton.heightAnchor.constraint(equalToConstant: 60),

            // Hell Yes button
            hellYesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hellYesButton.topAnchor.constraint(equalTo: yesButton.bottomAnchor, constant: 20),
            hellYesButton.widthAnchor.constraint(equalToConstant: 200),
            hellYesButton.heightAnchor.constraint(equalToConstant: 60),

            // Loading label
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: hellYesButton.bottomAnchor, constant: 40),
            loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 20)
        ])
    }

    private func setupActions() {
        yesButton.addTarget(self, action: #selector(joinAdvancement), for: .touchUpInside)
        hellYesButton.addTarget(self, action: #selector(joinAdvancement), for: .touchUpInside)
    }

    @objc private func joinAdvancement() {
        // Disable buttons
        yesButton.isEnabled = false
        hellYesButton.isEnabled = false

        // Show loading
        UIView.animate(withDuration: 0.3) {
            self.loadingLabel.alpha = 1
        }
        activityIndicator.startAnimating()

        // Create users for all services
        Task {
            do {
                try await createPlanetNineUsers()

                // Transition to main app
                await MainActor.run {
                    transitionToMainApp()
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }

    private func createPlanetNineUsers() async throws {
        NSLog("🚀 Creating Planet Nine users...")

        // Generate keys using Sessionless
        let sessionless = Sessionless()

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        // Get or generate user keys
        let keys = sessionless.getKeys() ?? sessionless.generateKeys()
        guard let userPubKey = keys?.publicKey else {
            throw NSError(domain: "KeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get user keys"])
        }

        // Save pubKey to SharedUserDefaults
        SharedUserDefaults.setCurrentUserPubKey(userPubKey)

        NSLog("🔑 User pubKey: %@", userPubKey)

        // Create signature for user creation
        let message = timestamp + userPubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign message"])
        }

        // Create Fount user
        let userUUID = try await createFountUser(pubKey: userPubKey, timestamp: timestamp, signature: signature)

        // Create carrierBag for the user
        try await createCarrierBag(userUUID: userUUID, pubKey: userPubKey)

        // TODO: Create users for other services (Sanora, Dolores, etc.)

        NSLog("✅ Planet Nine users created successfully!")
    }

    private func createFountUser(pubKey: String, timestamp: String, signature: String) async throws -> String {
        updateLoadingStatus("Creating Fount user...")

        let url = URL(string: "http://localhost:5117/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Fount"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(errorMessage)"])
        }

        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let userUUID = responseJSON?["uuid"] as? String else {
            // Log the actual response to help debug
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("⚠️ Fount response: %@", responseString)
            }
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Fount user response"])
        }

        SharedUserDefaults.setCovenantUserUUID(userUUID)
        NSLog("✅ Fount user created: %@", userUUID)

        return userUUID
    }

    private func createCarrierBag(userUUID: String, pubKey: String) async throws {
        updateLoadingStatus("Creating carrierBag...")

        // BDO service endpoint (not Fount!)
        let url = URL(string: "http://localhost:5114/user/\(userUUID)/bdo")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create empty carrierBag with all collections
        let carrierBagData: [String: Any] = [
            "type": "carrierBag",
            "cookbook": [],
            "apothecary": [],
            "gallery": [],
            "bookshelf": [],
            "familiarPen": [],
            "machinery": [],
            "metallics": [],
            "music": [],
            "oracular": [],
            "greenHouse": [],
            "closet": [],
            "games": [],
            "events": [],
            "contracts": [],
            "stacks": []
        ]

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = ""
        let sessionless = Sessionless()
        let message = timestamp + hash + pubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign carrierBag creation"])
        }

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "hash": hash,
            "signature": signature,
            "bdo": carrierBagData
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from BDO service"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "CarrierBag creation failed: \(errorMessage)"])
        }

        NSLog("✅ CarrierBag created successfully")
    }

    private func updateLoadingStatus(_ status: String) {
        Task { @MainActor in
            loadingLabel.text = status
        }
    }

    private func transitionToMainApp() {
        NSLog("🎉 Transitioning to main app...")

        // Get the main view controller from storyboard or create programmatically
        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {

            // For now, create a simple placeholder main view controller
            // TODO: Replace with actual main view controller from storyboard
            let mainVC = createMainViewController()

            window.rootViewController = mainVC

            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
        }
    }

    private func createMainViewController() -> UIViewController {
        // Check if we have a main storyboard
        if let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() {
            return mainVC
        }

        // Fallback: Create simple placeholder
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

    private func showError(_ error: Error) {
        NSLog("❌ Error creating users: %@", error.localizedDescription)

        activityIndicator.stopAnimating()
        loadingLabel.text = "Error: \(error.localizedDescription)"
        loadingLabel.textColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)

        // Re-enable buttons
        yesButton.isEnabled = true
        hellYesButton.isEnabled = true
    }
}
