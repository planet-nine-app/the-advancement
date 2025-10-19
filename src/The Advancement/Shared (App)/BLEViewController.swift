//
//  BLEViewController.swift
//  The Advancement
//
//  Created by Claude Code on 1/15/25.
//  BLE key exchange and Julia verification
//

#if os(iOS)
import UIKit

class BLEViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let sessionless = Sessionless()
    private let bleService = BLEService.shared

    private var lastReceivedKeyData: BLEKeyData?
    private var juliaUserUUID: String?
    private var discoveredDevices: [BLEDiscoveredDevice] = []
    private var devicesTableView: UITableView?

    private enum BLEMode {
        case idle
        case advertising
        case scanning
    }

    private var currentMode: BLEMode = .idle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "📡 BLE Keys"
        view.backgroundColor = .systemBackground

        setupUI()

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        NSLog("ADVANCEAPP-BLE: 📱 BLEViewController loaded")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop any active BLE operations when view disappears
        bleService.stopAdvertising()
        bleService.stopScanning()
        bleService.disconnect()
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

        addBLEControls()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP-BLE: 📱 Close button tapped")
        dismiss(animated: true)
    }

    private func addBLEControls() {
        // Header
        let headerLabel = UILabel()
        headerLabel.text = "BLE Interacting Keys"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textAlignment = .center
        stackView.addArrangedSubview(headerLabel)

        // Separator
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)

        // Info section
        let infoView = createInfoLabel(
            title: "How It Works",
            value: "Share your key via BLE for others to scan, or scan nearby devices to receive their keys. Julia verifies signatures and adds them as interacting keys."
        )
        stackView.addArrangedSubview(infoView)

        // Share Key Section
        let shareHeaderLabel = UILabel()
        shareHeaderLabel.text = "Share My Key"
        shareHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        shareHeaderLabel.textColor = .systemPurple
        stackView.addArrangedSubview(shareHeaderLabel)

        let shareButton = createActionButton(
            title: "📢 Start Advertising My Key",
            backgroundColor: .systemPurple,
            action: #selector(shareKeyTapped)
        )
        stackView.addArrangedSubview(shareButton)

        // Scan Section
        let scanHeaderLabel = UILabel()
        scanHeaderLabel.text = "Receive Keys"
        scanHeaderLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        scanHeaderLabel.textColor = .systemBlue
        stackView.addArrangedSubview(scanHeaderLabel)

        let scanButton = createActionButton(
            title: "🔍 Scan for Nearby Keys",
            backgroundColor: .systemBlue,
            action: #selector(scanKeysTapped)
        )
        stackView.addArrangedSubview(scanButton)

        // Julia user info
        if let uuid = getStoredJuliaUUID() {
            let juliaInfoView = createInfoLabel(
                title: "Julia User UUID",
                value: uuid
            )
            stackView.addArrangedSubview(juliaInfoView)
        }
    }

    // MARK: - Share Key (Advertise)

    @objc private func shareKeyTapped() {
        NSLog("ADVANCEAPP-BLE: 📢 Share key button tapped")

        // Stop scanning if active
        if currentMode == .scanning {
            bleService.stopScanning()
        }

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

        // Create signature
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey
        guard let signature = sessionless.sign(message: message) else {
            let errorView = createInfoLabel(
                title: "Error",
                value: "Failed to create signature for BLE advertising"
            )
            errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            stackView.addArrangedSubview(errorView)
            return
        }

        // Show loading state
        let loadingView = createInfoLabel(
            title: "Starting...",
            value: "Preparing to advertise your key via BLE"
        )
        loadingView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        stackView.addArrangedSubview(loadingView)

        // Start advertising
        bleService.advertiseKey(pubKey: keys.publicKey, signature: signature, message: message) { [weak self] result in
            DispatchQueue.main.async {
                loadingView.removeFromSuperview()

                switch result {
                case .success:
                    NSLog("ADVANCEAPP-BLE: ✅ Successfully started advertising")
                    self?.currentMode = .advertising
                    self?.handleAdvertisingSuccess()

                case .failure(let error):
                    NSLog("ADVANCEAPP-BLE: ❌ Failed to start advertising: %@", error.localizedDescription)
                    self?.handleBLEError(error)
                }
            }
        }
    }

    private func handleAdvertisingSuccess() {
        let successView = createInfoLabel(
            title: "📢 Advertising Active",
            value: "Your key is now being advertised via BLE. Others can scan and receive it. Tap 'Stop Advertising' when done."
        )
        successView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(successView)

        // Add stop button
        let stopButton = createActionButton(
            title: "🛑 Stop Advertising",
            backgroundColor: .systemRed,
            action: #selector(stopAdvertisingTapped)
        )
        stackView.addArrangedSubview(stopButton)
    }

    @objc private func stopAdvertisingTapped() {
        NSLog("ADVANCEAPP-BLE: 🛑 Stop advertising tapped")
        bleService.stopAdvertising()
        currentMode = .idle

        // Refresh UI
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addBLEControls()

        let stoppedView = createInfoLabel(
            title: "Stopped",
            value: "No longer advertising your key"
        )
        stoppedView.backgroundColor = .systemGray6
        stackView.addArrangedSubview(stoppedView)
    }

    // MARK: - Scan for Keys

    @objc private func scanKeysTapped() {
        NSLog("ADVANCEAPP-BLE: 🔍 Scan keys button tapped")

        // Stop advertising if active
        if currentMode == .advertising {
            bleService.stopAdvertising()
        }

        currentMode = .scanning
        discoveredDevices = []

        // Show scanning state
        let scanningView = createInfoLabel(
            title: "🔍 Scanning...",
            value: "Looking for nearby Planet Nine devices"
        )
        scanningView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        stackView.addArrangedSubview(scanningView)

        // Create table view for discovered devices
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        tableView.layer.cornerRadius = 8
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
        stackView.addArrangedSubview(tableView)
        self.devicesTableView = tableView

        // Add stop scanning button
        let stopButton = createActionButton(
            title: "🛑 Stop Scanning",
            backgroundColor: .systemRed,
            action: #selector(stopScanningTapped)
        )
        stackView.addArrangedSubview(stopButton)

        // Start scanning
        bleService.scanForKeys { [weak self] devices in
            DispatchQueue.main.async {
                self?.discoveredDevices = devices
                self?.devicesTableView?.reloadData()
                NSLog("ADVANCEAPP-BLE: 📱 Discovered %d device(s)", devices.count)
            }
        }
    }

    @objc private func stopScanningTapped() {
        NSLog("ADVANCEAPP-BLE: 🛑 Stop scanning tapped")
        bleService.stopScanning()
        currentMode = .idle

        // Refresh UI
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addBLEControls()

        let stoppedView = createInfoLabel(
            title: "Stopped",
            value: "Scanning stopped"
        )
        stoppedView.backgroundColor = .systemGray6
        stackView.addArrangedSubview(stoppedView)
    }

    // MARK: - Connect and Read Key

    private func connectToDevice(_ device: BLEDiscoveredDevice) {
        NSLog("ADVANCEAPP-BLE: 🔗 Connecting to device: \(device.displayName)")

        // Show connecting state
        let connectingView = createInfoLabel(
            title: "Connecting...",
            value: "Connecting to \(device.displayName)"
        )
        connectingView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        stackView.addArrangedSubview(connectingView)

        bleService.connectAndReadKey(from: device) { [weak self] result in
            DispatchQueue.main.async {
                connectingView.removeFromSuperview()

                switch result {
                case .success(let keyData):
                    NSLog("ADVANCEAPP-BLE: ✅ Successfully received key data")
                    self?.handleKeyReceived(keyData, from: device)

                case .failure(let error):
                    NSLog("ADVANCEAPP-BLE: ❌ Failed to receive key: %@", error.localizedDescription)
                    self?.handleBLEError(error)
                }
            }
        }
    }

    // MARK: - Handle Key Received

    private func handleKeyReceived(_ keyData: BLEKeyData, from device: BLEDiscoveredDevice) {
        lastReceivedKeyData = keyData

        // Show key data
        let keyDataView = createInfoLabel(
            title: "✅ Key Received from \(device.displayName)",
            value: """
            PubKey: \(keyData.pubKey.prefix(40))...
            Signature: \(keyData.signature.prefix(40))...
            Message: \(keyData.message)
            """
        )
        keyDataView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(keyDataView)

        // Verify with Julia button
        let verifyButton = createActionButton(
            title: "🔐 Verify and Add as Interacting Key",
            backgroundColor: .systemGreen,
            action: #selector(verifyWithJuliaTapped)
        )
        stackView.addArrangedSubview(verifyButton)
    }

    // MARK: - Julia Verification

    @objc private func verifyWithJuliaTapped() {
        guard let keyData = lastReceivedKeyData else {
            NSLog("ADVANCEAPP-BLE: ⚠️ No key data to verify")
            return
        }

        NSLog("ADVANCEAPP-BLE: 🔐 Verifying key with Julia...")

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
                    keyData: keyData
                )

                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.displayVerificationResult(result)
                }
            } catch {
                NSLog("ADVANCEAPP-BLE: ❌ Verification failed: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    loadingView.removeFromSuperview()
                    self.displayVerificationError(error)
                }
            }
        }
    }

    private func verifyWithJulia(primaryUUID: String, keyData: BLEKeyData) async throws -> [String: Any] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        let payload: [String: Any] = [
            "timestamp": timestamp,
            "primaryUUID": primaryUUID,
            "pubKey": keyData.pubKey,
            "signature": keyData.signature
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let url = URL(string: "http://127.0.0.1:5111/nfc/verify") else {
            throw NSError(domain: "BLEError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create request"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        NSLog("ADVANCEAPP-BLE: 📡 Sending verification request to Julia")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BLEError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEAPP-BLE: 📡 Julia response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BLEError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? [:]
    }

    private func displayVerificationResult(_ result: [String: Any]) {
        guard let success = result["success"] as? Bool, success else {
            displayVerificationError(NSError(
                domain: "BLEError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: result["error"] as? String ?? "Verification failed"]
            ))
            return
        }

        let keyType = result["keyType"] as? String ?? "unknown"
        let message = result["message"] as? String ?? ""

        var resultText = """
        ✅ Verification Successful
        Key Type: 🤝 Interacting Key
        """

        if !message.isEmpty {
            resultText += "\nMessage: \(message)"
        }

        resultText += "\n\nThe key has been added to your Julia account and you can now interact with this user."

        let successView = createInfoLabel(
            title: "Verification Result",
            value: resultText
        )
        successView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        stackView.addArrangedSubview(successView)

        NSLog("ADVANCEAPP-BLE: ✅ Verification successful - keyType: %@", keyType)
    }

    private func displayVerificationError(_ error: Error) {
        let errorView = createInfoLabel(
            title: "❌ Verification Failed",
            value: error.localizedDescription
        )
        errorView.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorView)
    }

    // MARK: - Handle BLE Errors

    private func handleBLEError(_ error: BLEService.BLEError) {
        let errorMessage: String
        switch error {
        case .notSupported:
            errorMessage = "BLE is not supported on this device"
        case .bluetoothOff:
            errorMessage = "Bluetooth is turned off. Please enable it in Settings."
        case .unauthorized:
            errorMessage = "Bluetooth permission denied. Please enable in Settings."
        case .advertisingFailed(let message):
            errorMessage = "Advertising failed: \(message)"
        case .scanningFailed(let message):
            errorMessage = "Scanning failed: \(message)"
        case .connectionFailed(let message):
            errorMessage = "Connection failed: \(message)"
        case .readFailed(let message):
            errorMessage = "Read failed: \(message)"
        case .invalidData:
            errorMessage = "Invalid key data received"
        case .characteristicNotFound:
            errorMessage = "Device doesn't have required characteristics"
        case .serviceNotFound:
            errorMessage = "Planet Nine service not found on device"
        default:
            errorMessage = "Unknown error occurred"
        }

        let errorView = createInfoLabel(
            title: "❌ BLE Error",
            value: errorMessage
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
        NSLog("ADVANCEAPP-BLE: 📡 Ensuring Julia user exists...")

        // Check if user already exists
        if let existingUUID = getStoredJuliaUUID() {
            NSLog("ADVANCEAPP-BLE: ✅ Julia user already exists: %@", existingUUID)
            juliaUserUUID = existingUUID
            return
        }

        // Create new Julia user
        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP-BLE: ❌ No sessionless keys available")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP-BLE: ❌ Failed to sign Julia user creation")
            return
        }

        let userPayload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": keys.publicKey,
            "signature": signature,
            "user": [
                "uuid": "ble-user-\(UUID().uuidString)",
                "pubKey": keys.publicKey,
                "keys": [
                    "interactingKeys": [:],
                    "coordinatingKeys": [:]
                ]
            ]
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userPayload),
                  let url = URL(string: "http://127.0.0.1:5111/user/create") else {
                NSLog("ADVANCEAPP-BLE: ❌ Failed to create Julia request")
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
                NSLog("ADVANCEAPP-BLE: ✅ Julia user created: %@", uuid)
            }
        } catch {
            NSLog("ADVANCEAPP-BLE: ❌ Failed to create Julia user: %@", error.localizedDescription)
        }
    }

    private func getStoredJuliaUUID() -> String? {
        return UserDefaults.standard.string(forKey: "juliaUserUUID")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension BLEViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if discoveredDevices.isEmpty {
            return 1 // Show "No devices found" row
        }
        return discoveredDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)

        if discoveredDevices.isEmpty {
            cell.textLabel?.text = "No devices found..."
            cell.textLabel?.textColor = .systemGray
            cell.selectionStyle = .none
        } else {
            let device = discoveredDevices[indexPath.row]
            cell.textLabel?.text = "\(device.displayName) (\(device.signalStrength))"
            cell.textLabel?.textColor = .label
            cell.selectionStyle = .default
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard !discoveredDevices.isEmpty else { return }

        let device = discoveredDevices[indexPath.row]
        NSLog("ADVANCEAPP-BLE: 📱 Selected device: \(device.displayName)")

        // Stop scanning and connect
        bleService.stopScanning()
        connectToDevice(device)
    }
}
#endif
