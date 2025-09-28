//
//  InstantiationViewController.swift
//  The Advancement
//
//  Shows Fount user information and instantiation details
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS)
class InstantiationViewController: UIViewController {

    private var userInfo: [String: Any] = [:]
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "⚡ Instantiation"
        view.backgroundColor = .systemBackground

        setupUI()
        loadFountUserInfo()

        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        NSLog("ADVANCEAPP: ⚡ InstantiationViewController loaded")
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

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: ⚡ Refresh button tapped")
        loadFountUserInfo()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: ⚡ Close button tapped")
        dismiss(animated: true)
    }

    private func loadFountUserInfo() {
        NSLog("ADVANCEAPP: ⚡ Loading Fount user info...")

        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Show loading state
        let loadingLabel = createInfoLabel(title: "Loading...", value: "Fetching Fount user information")
        stackView.addArrangedSubview(loadingLabel)

        // Use the same pubkey as the keyboard extension to get user info
        Task {
            do {
                let pubKey = "02a3b4c5d6e7f8910111213141516171819202122232425262728293031323334"
                let userInfo = try await fetchFountUserInfo(publicKey: pubKey)

                DispatchQueue.main.async {
                    self.displayUserInfo(userInfo, publicKey: pubKey)
                }
            } catch {
                NSLog("ADVANCEAPP: ⚠️ Failed to load Fount user info: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.displayError(error)
                }
            }
        }
    }

    private func fetchFountUserInfo(publicKey: String) async throws -> [String: Any] {
        let fountUrl = "http://127.0.0.1:5117/bdo/\(publicKey)"

        guard let url = URL(string: fountUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEAPP: 📡 Fetching user info from Fount")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? [:]
    }

    private func displayUserInfo(_ info: [String: Any], publicKey: String) {
        // Clear loading state
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add header
        let headerLabel = UILabel()
        headerLabel.text = "Fount User Instantiation"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textAlignment = .center
        stackView.addArrangedSubview(headerLabel)

        // Add separator
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)

        // Public Key
        let pubKeyView = createInfoLabel(title: "Public Key", value: publicKey)
        stackView.addArrangedSubview(pubKeyView)

        // BDO data if available
        if let dataDict = info["data"] as? [String: Any] {
            if let type = dataDict["type"] as? String {
                let typeView = createInfoLabel(title: "BDO Type", value: type)
                stackView.addArrangedSubview(typeView)
            }

            // CarrierBag info
            if let carrierBag = dataDict["carrierBag"] as? [String: Any] {
                let carrierBagHeader = UILabel()
                carrierBagHeader.text = "CarrierBag Contents"
                carrierBagHeader.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
                stackView.addArrangedSubview(carrierBagHeader)

                if let created = carrierBag["created"] as? String {
                    let createdView = createInfoLabel(title: "Created", value: formatDate(created))
                    stackView.addArrangedSubview(createdView)
                }

                if let lastUpdated = carrierBag["lastUpdated"] as? String {
                    let updatedView = createInfoLabel(title: "Last Updated", value: formatDate(lastUpdated))
                    stackView.addArrangedSubview(updatedView)
                }

                // Count items in each collection
                let collections = ["cookbook", "apothecary", "gallery", "bookshelf", "familiarPen", "machinery", "metallics", "music", "oracular", "greenHouse", "closet", "games"]

                for collection in collections {
                    if let items = carrierBag[collection] as? [Any] {
                        let emoji = getCollectionEmoji(collection)
                        let countView = createInfoLabel(title: "\(emoji) \(collection.capitalized)", value: "\(items.count) items")
                        stackView.addArrangedSubview(countView)
                    }
                }
            }
        }

        // User UUID if available
        if let owner = (info["data"] as? [String: Any])?["owner"] as? String {
            let ownerView = createInfoLabel(title: "User UUID", value: owner)
            stackView.addArrangedSubview(ownerView)
        }

        // Raw JSON for debugging
        let jsonView = createRawJSONView(info)
        stackView.addArrangedSubview(jsonView)

        NSLog("ADVANCEAPP: ⚡ Displayed user info with \(stackView.arrangedSubviews.count) elements")
    }

    private func displayError(_ error: Error) {
        // Clear loading state
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let errorLabel = createInfoLabel(title: "Error", value: error.localizedDescription)
        errorLabel.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorLabel)

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        retryButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        stackView.addArrangedSubview(retryButton)
    }

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

    private func createRawJSONView(_ data: [String: Any]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = "Raw JSON Data"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .systemBlue

        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            textView.text = String(data: jsonData, encoding: .utf8) ?? "Unable to format JSON"
        } catch {
            textView.text = "Error formatting JSON: \(error.localizedDescription)"
        }

        textView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textView])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            textView.heightAnchor.constraint(equalToConstant: 200)
        ])

        return containerView
    }

    private func getCollectionEmoji(_ collection: String) -> String {
        switch collection {
        case "cookbook": return "🍪"
        case "apothecary": return "🧪"
        case "gallery": return "🖼️"
        case "bookshelf": return "📚"
        case "familiarPen": return "🐾"
        case "machinery": return "⚙️"
        case "metallics": return "⚡"
        case "music": return "🎵"
        case "oracular": return "🔮"
        case "greenHouse": return "🌱"
        case "closet": return "👕"
        case "games": return "🎮"
        default: return "📦"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "Unknown date" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }
}
#endif