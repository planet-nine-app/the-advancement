//
//  NFCViewController.swift
//  The Advancement
//
//  Created by Claude Code on 10/12/25.
//  NFC tag reading/writing and Julia verification
//

#if os(iOS)
import UIKit

class NFCViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let sessionless = Sessionless()
    private let nfcService = NFCService.shared

    private var lastReadTagData: NFCTagData?
    private var juliaUserUUID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "📱 NFC Keys"
        view.backgroundColor = .systemBackground

        setupUI()
        checkNFCAvailability()

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        NSLog("ADVANCEAPP-NFC: 📱 NFCViewController loaded")
    }

    private func setupUI() {
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Setup stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP-NFC: 📱 Close button tapped")
        dismiss(animated: true)
    }

    private func checkNFCAvailability() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add header
        let headerLabel = UILabel()
        headerLabel.text = "NFC Coordinating Keys"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textAlignment = .center
        stackView.addArrangedSubview(headerLabel)

        // Add separator
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)

        if NFCService.isNFCAvailable() {
            addNFCControls()
        } else {
            let errorView = createInfoLabel(
                title: "NFC Not Available",
                value: "This device does not support NFC or NFC is disabled"
            )
            errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            stackView.addArrangedSubview(errorView)
        }
    }

    private func addNFCControls() {
        // Info section
        let infoView = createInfoLabel(
            title: "How It Works",
            value: "Read NFC tags containing pubKey + signature pairs. Julia verifies the signature against the BDO message and adds as coordinating or interacting key based on BDO settings."
        )
        stackView.addArrangedSubview(infoView)

        // Read NFC button
        let readButton = createActionButton(
            title: "📖 Read NFC Tag",
            backgroundColor: .systemBlue,
            action: #selector(readNFCTapped)
        )
        stackView.addArrangedSubview(readButton)

        // Write NFC section header
        let writeHeaderLabel = UILabel()
        writeHeaderLabel.text = "Write New Tag"
        writeHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        writeHeaderLabel.textColor = .systemPurple
        stackView.addArrangedSubview(writeHeaderLabel)

        // Write NFC button (writes current user's key)
        let writeButton = createActionButton(
            title: "✍️ Write My Key to NFC Tag",
            backgroundColor: .systemPurple,
            action: #selector(writeNFCTapped)
        )
        stackView.addArrangedSubview(writeButton)

        // Julia user info
        if let uuid = getStoredJuliaUUID() {
            let juliaInfoView = createInfoLabel(
                title: "Julia User UUID",
                value: uuid
            )
            stackView.addArrangedSubview(juliaInfoView)
        }
    }

    // MARK: - NFC Actions

    @objc private func readNFCTapped() {
        NSLog("ADVANCEAPP-NFC: 📖 Read NFC button tapped")

        // Show loading state
        let loadingView = createInfoLabel(
            title: "Reading...",
            value: "Hold your iPhone near the NFC tag"
        )
        loadingView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        stackView.addArrangedSubview(loadingView)

        nfcService.readTag { [weak self] result in
            DispatchQueue.main.async {
                // Remove loading view
                loadingView.removeFromSuperview()

                switch result {
                case .success(let tagData):
                    NSLog("ADVANCEAPP-NFC: ✅ Successfully read NFC tag")
                    self?.handleReadSuccess(tagData)

                case .failure(let error):
                    NSLog("ADVANCEAPP-NFC: ❌ Failed to read NFC tag: %@", error.localizedDescription)
                    self?.handleReadFailure(error)
                }
            }
        }
    }

    @objc private func writeNFCTapped() {
        NSLog("ADVANCEAPP-NFC: ✍️ Write NFC button tapped")

        // Get current user's keys
        guard let keys = sessionless.getKeys() else {
            let errorView = createInfoLabel(
                title: "Error",
                value: "No sessionless keys available. Please ensure you're instantiated."
            )
            errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            stackView.addArrangedSubview(errorView)
            return
        }

        // Create signature for NFC tag
        // Message format should match what Julia expects to verify
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey
        guard let signature = sessionless.sign(message: message) else {
            let errorView = createInfoLabel(
                title: "Error",
                value: "Failed to create signature for NFC tag"
            )
            errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            stackView.addArrangedSubview(errorView)
            return
        }

        // Show loading state
        let loadingView = createInfoLabel(
            title: "Writing...",
            value: "Hold your iPhone near the NFC tag to write"
        )
        loadingView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        stackView.addArrangedSubview(loadingView)

        nfcService.writeTag(pubKey: keys.publicKey, signature: signature) { [weak self] result in
            DispatchQueue.main.async {
                // Remove loading view
                loadingView.removeFromSuperview()

                switch result {
                case .success:
                    NSLog("ADVANCEAPP-NFC: ✅ Successfully wrote NFC tag")
                    self?.handleWriteSuccess()

                case .failure(let error):
                    NSLog("ADVANCEAPP-NFC: ❌ Failed to write NFC tag: %@", error.localizedDescription)
                    self?.handleWriteFailure(error)
                }
            }
        }
    }

    // MARK: - Handle Read Success

    private func handleReadSuccess(_ tagData: NFCTagData) {
        lastReadTagData = tagData

        // Show tag data
        let tagDataView = createInfoLabel(
            title: "✅ Tag Read Successfully",
            value: """
            PubKey: \(tagData.pubKey.prefix(40))...
            Signature: \(tagData.signature.prefix(40))...
            """
        )
        tagDataView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(tagDataView)

        // Verify with Julia button
        let verifyButton = createActionButton(
            title: "🔐 Verify with Julia",
            backgroundColor: .systemGreen,
            action: #selector(verifyWithJuliaTapped)
        )
        stackView.addArrangedSubview(verifyButton)
    }

    private func handleReadFailure(_ error: NFCService.NFCError) {
        let errorMessage: String
        switch error {
        case .notSupported:
            errorMessage = "NFC is not supported on this device"
        case .readFailed(let message):
            errorMessage = "Read failed: \(message)"
        case .tagNotFound:
            errorMessage = "No NFC tag detected"
        case .invalidData:
            errorMessage = "Invalid data on NFC tag"
        default:
            errorMessage = "Unknown error occurred"
        }

        let errorView = createInfoLabel(
            title: "❌ Read Failed",
            value: errorMessage
        )
        errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorView)
    }

    // MARK: - Handle Write Success/Failure

    private func handleWriteSuccess() {
        let successView = createInfoLabel(
            title: "✅ Tag Written Successfully",
            value: "Your coordinating key has been written to the NFC tag"
        )
        successView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(successView)
    }

    private func handleWriteFailure(_ error: NFCService.NFCError) {
        let errorMessage: String
        switch error {
        case .notSupported:
            errorMessage = "NFC is not supported on this device"
        case .writeFailed(let message):
            errorMessage = "Write failed: \(message)"
        case .tagNotFound:
            errorMessage = "No writable NFC tag detected"
        default:
            errorMessage = "Unknown error occurred"
        }

        let errorView = createInfoLabel(
            title: "❌ Write Failed",
            value: errorMessage
        )
        errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorView)
    }

    // MARK: - Julia Verification

    @objc private func verifyWithJuliaTapped() {
        guard let tagData = lastReadTagData else {
            NSLog("ADVANCEAPP-NFC: ⚠️ No tag data to verify")
            return
        }

        NSLog("ADVANCEAPP-NFC: 🔐 Verifying tag with Julia...")

        // Ensure Julia user exists
        Task {
            await ensureJuliaUserExists()

            guard let juliaUUID = getStoredJuliaUUID() else {
                DispatchQueue.main.async {
                    let errorView = self.createInfoLabel(
                        title: "Error",
                        value: "Failed to create Julia user. Please try again."
                    )
                    errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
                    self.stackView.addArrangedSubview(errorView)
                }
                return
            }

            // Show loading
            let loadingView = self.createInfoLabel(
                title: "Verifying...",
                value: "Sending to Julia for verification"
            )
            loadingView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
            DispatchQueue.main.async {
                self.stackView.addArrangedSubview(loadingView)
            }

            do {
                let result = try await self.verifyWithJulia(
                    primaryUUID: juliaUUID,
                    tagData: tagData
                )

                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.displayVerificationResult(result)
                }
            } catch {
                NSLog("ADVANCEAPP-NFC: ❌ Verification failed: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.displayVerificationError(error)
                }
            }
        }
    }

    private func verifyWithJulia(primaryUUID: String, tagData: NFCTagData) async throws -> [String: Any] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        let payload: [String: Any] = [
            "timestamp": timestamp,
            "primaryUUID": primaryUUID,
            "pubKey": tagData.pubKey,
            "signature": tagData.signature
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let url = URL(string: "http://127.0.0.1:5111/nfc/verify") else {
            throw NSError(domain: "NFCError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create request"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        NSLog("ADVANCEAPP-NFC: 📡 Sending verification request to Julia")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NFCError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEAPP-NFC: 📡 Julia response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "NFCError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? [:]
    }

    private func displayVerificationResult(_ result: [String: Any]) {
        guard let success = result["success"] as? Bool, success else {
            displayVerificationError(NSError(
                domain: "NFCError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: result["error"] as? String ?? "Verification failed"]
            ))
            return
        }

        let keyType = result["keyType"] as? String ?? "unknown"
        let message = result["message"] as? String ?? ""
        let rotated = result["rotated"] as? Bool ?? false

        var resultText = """
        ✅ Verification Successful
        Key Type: \(keyType == "coordinating" ? "🔗 Coordinating Key" : "🤝 Interacting Key")
        """

        if !message.isEmpty {
            resultText += "\nMessage: \(message)"
        }

        if rotated {
            resultText += "\n\n🔄 Key Rotation: A new key was generated and BDO was rotated"
            if let newPubKey = result["newPubKey"] as? String {
                resultText += "\nNew PubKey: \(newPubKey.prefix(40))..."
            }
        }

        let successView = createInfoLabel(
            title: "Verification Result",
            value: resultText
        )
        successView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(successView)

        NSLog("ADVANCEAPP-NFC: ✅ Verification successful - keyType: %@, rotated: %d", keyType, rotated)
    }

    private func displayVerificationError(_ error: Error) {
        let errorView = createInfoLabel(
            title: "❌ Verification Failed",
            value: error.localizedDescription
        )
        errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorView)
    }

    // MARK: - UI Helper Methods

    private func createInfoLabel(title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .systemBlue

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.numberOfLines = 0
        valueLabel.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        return containerView
    }

    private func createActionButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Julia User Management

    private func ensureJuliaUserExists() async {
        NSLog("ADVANCEAPP-NFC: 📡 Ensuring Julia user exists...")

        // Check if user already exists
        if let existingUUID = getStoredJuliaUUID() {
            NSLog("ADVANCEAPP-NFC: ✅ Julia user already exists: %@", existingUUID)
            juliaUserUUID = existingUUID
            return
        }

        // Create new Julia user
        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP-NFC: ❌ No sessionless keys available")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP-NFC: ❌ Failed to sign Julia user creation")
            return
        }

        let userPayload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": keys.publicKey,
            "signature": signature
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userPayload),
                  let url = URL(string: "http://127.0.0.1:5111/user/create") else {
                NSLog("ADVANCEAPP-NFC: ❌ Failed to create Julia request")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let uuid = responseData["uuid"] as? String {

                // Store Julia user
                UserDefaults.standard.set(uuid, forKey: "juliaUserUUID")
                juliaUserUUID = uuid
                NSLog("ADVANCEAPP-NFC: ✅ Julia user created: %@", uuid)
            }
        } catch {
            NSLog("ADVANCEAPP-NFC: ❌ Failed to create Julia user: %@", error.localizedDescription)
        }
    }

    private func getStoredJuliaUUID() -> String? {
        return UserDefaults.standard.string(forKey: "juliaUserUUID")
    }
}
#endif
