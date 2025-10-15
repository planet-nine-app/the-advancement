//
//  CarrierBagViewController.swift
//  The Advancement
//
//  Shows the contents of the user's carrierBag with all collections
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS)
class CarrierBagViewController: UITableViewController {

    private var carrierBagData: [String: Any] = [:]
    private var collections: [(name: String, emoji: String, items: [Any])] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "🎒 Carrier Bag"
        view.backgroundColor = .systemBackground

        // Setup table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CollectionCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")

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

        loadCarrierBagData()

        NSLog("ADVANCEAPP: 🎒 CarrierBagViewController loaded")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCarrierBagData() // Refresh when view appears
    }

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: 🎒 Refresh button tapped")
        loadCarrierBagData()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: 🎒 Close button tapped")
        dismiss(animated: true)
    }

    private func loadCarrierBagData() {
        NSLog("ADVANCEAPP: 🎒 Loading carrierBag data from Fount...")

        // Show loading state
        collections = []
        tableView.reloadData()

        // Use the stored Addie UUID for BDO access
        Task {
            do {
                let uuid = getStoredAddieUUID()
                let carrierBag = try await fetchCarrierBagFromBDO(uuid: uuid)

                DispatchQueue.main.async {
                    self.processCarrierBagData(carrierBag)
                }
            } catch {
                NSLog("ADVANCEAPP: ⚠️ Failed to load carrierBag: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showError(error)
                }
            }
        }
    }

    private func fetchCarrierBagFromBDO(uuid: String) async throws -> [String: Any] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let bdoUrl = "http://127.0.0.1:5114/user/\(uuid)/bdo?timestamp=\(timestamp)&hash=\(hash)"

        guard let url = URL(string: bdoUrl) else {
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO URL"])
        }

        NSLog("ADVANCEAPP: 📡 Fetching carrierBag from BDO")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "BDO error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject,
              let dataDict = bdoData["data"] as? [String: Any],
              let carrierBag = dataDict["carrierBag"] as? [String: Any] else {
            NSLog("ADVANCEAPP: 📦 No carrierBag found in BDO")
            return [:]
        }

        NSLog("ADVANCEAPP: 🎒 Found carrierBag with keys: %@", Array(carrierBag.keys).joined(separator: ", "))
        return carrierBag
    }

    private func processCarrierBagData(_ carrierBag: [String: Any]) {
        carrierBagData = carrierBag
        collections = []

        // Define all available collections with their emojis
        let collectionDefinitions = [
            ("cookbook", "🍪"),
            ("apothecary", "🧪"),
            ("gallery", "🖼️"),
            ("bookshelf", "📚"),
            ("familiarPen", "🐾"),
            ("machinery", "⚙️"),
            ("metallics", "⚡"),
            ("music", "🎵"),
            ("oracular", "🔮"),
            ("greenHouse", "🌱"),
            ("closet", "👕"),
            ("games", "🎮"),
            ("events", "🎫"),
            ("contracts", "📜"),
            ("stacks", "🏠")
        ]

        // Process each collection
        for (name, emoji) in collectionDefinitions {
            if let items = carrierBag[name] as? [Any] {
                collections.append((name: name, emoji: emoji, items: items))
                NSLog("ADVANCEAPP: 📦 Found %d items in %@", items.count, name)
            } else {
                // Show empty collections too
                collections.append((name: name, emoji: emoji, items: []))
            }
        }

        // Sort collections by name for consistent display
        collections.sort { $0.name < $1.name }

        // Reload table
        tableView.reloadData()

        NSLog("ADVANCEAPP: 🎒 Processed %d collections", collections.count)
    }

    private func showError(_ error: Error) {
        collections = []

        // Create an error collection to display the error
        let errorCollection = (name: "Error", emoji: "⚠️", items: [error.localizedDescription])
        collections = [errorCollection]

        tableView.reloadData()
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return max(collections.count, 1) // At least 1 section for empty state
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if collections.isEmpty {
            return 1 // Empty state
        }

        let collection = collections[section]
        return max(collection.items.count, 1) // At least 1 row to show "empty" state
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if collections.isEmpty {
            return "🎒 Carrier Bag"
        }

        let collection = collections[section]
        return "\(collection.emoji) \(collection.name.capitalized) (\(collection.items.count))"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)

        if collections.isEmpty {
            // Empty state
            cell.textLabel?.text = "🎒 Loading carrier bag..."
            cell.detailTextLabel?.text = "Fetching data from Fount"
            cell.textLabel?.textColor = .systemGray
            cell.selectionStyle = .none
            return cell
        }

        let collection = collections[indexPath.section]

        if collection.items.isEmpty {
            // Empty collection
            cell.textLabel?.text = "Empty \(collection.name)"
            cell.detailTextLabel?.text = "No items in this collection yet"
            cell.textLabel?.textColor = .systemGray2
            cell.selectionStyle = .none
        } else {
            // Item in collection
            let item = collection.items[indexPath.row]

            if let itemDict = item as? [String: Any] {
                // Structured item (like recipes, ebooks, etc.)
                let title = itemDict["title"] as? String ?? "Untitled Item"
                let type = itemDict["type"] as? String ?? "unknown"
                let savedAt = itemDict["savedAt"] as? String ?? ""

                cell.textLabel?.text = title

                // Enhanced display for ebooks
                if type.lowercased() == "ebook" {
                    var details: [String] = ["📚 Ebook"]

                    if let price = itemDict["price"] as? Int, price > 0 {
                        let dollarAmount = Double(price) / 100.0
                        details.append(String(format: "$%.2f", dollarAmount))
                    }

                    if let purchasedFromNexus = itemDict["purchasedFromNexus"] as? Bool, purchasedFromNexus {
                        details.append("Purchased via Nexus")
                    }

                    details.append(formatDate(savedAt))

                    cell.detailTextLabel?.text = details.joined(separator: " • ")
                } else {
                    // Default display for other item types
                    cell.detailTextLabel?.text = "Type: \(type) • \(formatDate(savedAt))"
                }

                cell.accessoryType = .disclosureIndicator
            } else {
                // Simple item (string or other)
                cell.textLabel?.text = String(describing: item)
                cell.detailTextLabel?.text = "Simple item"
                cell.accessoryType = .none
            }

            cell.textLabel?.textColor = .label
            cell.selectionStyle = .default
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard !collections.isEmpty else { return }

        let collection = collections[indexPath.section]

        if collection.items.isEmpty {
            return // No action for empty collections
        }

        let item = collection.items[indexPath.row]

        // Show item details
        showItemDetails(item: item, collectionName: collection.name, collectionEmoji: collection.emoji)
    }

    // MARK: - Helper Methods

    private func showItemDetails(item: Any, collectionName: String, collectionEmoji: String) {
        var title = "\(collectionEmoji) Item Details"
        var message = ""

        if let itemDict = item as? [String: Any] {
            title = itemDict["title"] as? String ?? title

            // Enhanced formatting for ebooks
            if let type = itemDict["type"] as? String, type.lowercased() == "ebook" {
                var details: [String] = []

                if let description = itemDict["description"] as? String, !description.isEmpty {
                    details.append("📖 Description: \(description)")
                }

                if let price = itemDict["price"] as? Int, price > 0 {
                    let dollarAmount = Double(price) / 100.0
                    details.append("💰 Price: \(String(format: "$%.2f", dollarAmount))")
                }

                if let productId = itemDict["productId"] as? String, !productId.isEmpty {
                    details.append("🆔 Product ID: \(productId)")
                }

                if let savedAt = itemDict["savedAt"] as? String {
                    details.append("📅 Added: \(formatDate(savedAt))")
                }

                if let purchasedFromNexus = itemDict["purchasedFromNexus"] as? Bool, purchasedFromNexus {
                    details.append("🛒 Purchased via The Advancement Nexus")
                }

                message = details.joined(separator: "\n\n")
            } else {
                // Default formatting for other item types
                var details: [String] = []
                for (key, value) in itemDict {
                    if key != "title" {
                        details.append("\(key): \(value)")
                    }
                }
                message = details.joined(separator: "\n")
            }
        } else {
            message = "Raw data: \(item)"
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add copy button for product ID if it's an ebook
        if let itemDict = item as? [String: Any] {
            if let type = itemDict["type"] as? String, type.lowercased() == "ebook",
               let productId = itemDict["productId"] as? String, !productId.isEmpty {
                alert.addAction(UIAlertAction(title: "Copy Product ID", style: .default) { _ in
                    UIPasteboard.general.string = productId
                    NSLog("ADVANCEAPP: 📋 Copied Product ID to clipboard")
                })
            }

            // Keep existing BDO PubKey copy functionality
            if let bdoPubKey = itemDict["bdoPubKey"] as? String {
                alert.addAction(UIAlertAction(title: "Copy BDO PubKey", style: .default) { _ in
                    UIPasteboard.general.string = bdoPubKey
                    NSLog("ADVANCEAPP: 📋 Copied BDO PubKey to clipboard")
                })
            }
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)

        NSLog("ADVANCEAPP: 🔍 Showing details for item in %@", collectionName)
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "Unknown date" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    // MARK: - Section Header Customization

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            headerView.textLabel?.textColor = .systemBlue
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    // MARK: - UUID Management

    private func getStoredAddieUUID() -> String {
        // Get UUID from stored Addie user data
        if let existingUser = UserDefaults.standard.data(forKey: "addieUser"),
           let userData = try? JSONSerialization.jsonObject(with: existingUser) as? [String: Any],
           let uuid = userData["uuid"] as? String {
            NSLog("ADVANCEAPP: 🔄 Using stored Addie UUID: %@", uuid)
            return uuid
        }

        NSLog("ADVANCEAPP: ❌ No Addie user found, using fallback UUID")
        return "no-uuid-available"
    }
}
#endif