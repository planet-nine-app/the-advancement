//
//  CookbookViewController.swift
//  The Advancement
//
//  Native Swift cookbook interface
//

#if os(iOS)
import UIKit
typealias PlatformTableView = UITableView
typealias PlatformTableViewCell = UITableViewCell
#elseif os(macOS)
import Cocoa
// macOS table view would need different implementation
#endif

#if os(iOS)
class CookbookViewController: UITableViewController {

    private var holdings: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "🍪 Cookbook"

        // Setup table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipeCell")

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

        // Load recipes
        loadRecipes()

        NSLog("ADVANCEAPP: 📚 CookbookViewController loaded")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecipes() // Refresh when view appears
    }

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: 📚 Refresh button tapped")
        loadRecipes()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: 📚 Close button tapped")
        dismiss(animated: true)
    }

    private func loadRecipes() {
        NSLog("ADVANCEAPP: 📚 Loading recipes from SharedUserDefaults and Fount...")

        // Force sync
        SharedUserDefaults.shared.synchronize()

        // Get holdings from SharedUserDefaults (immediate display)
        holdings = SharedUserDefaults.getHoldings()
        NSLog("ADVANCEAPP: 📚 Found %d holdings from SharedUserDefaults", holdings.count)

        // Filter for recipes only
        holdings = holdings.filter { holding in
            (holding["type"] as? String) == "recipe"
        }

        NSLog("ADVANCEAPP: 📚 Found %d recipes after filtering", holdings.count)

        // Debug print
        SharedUserDefaults.debugPrint(prefix: "ADVANCEAPP")

        // Also try to load from Fount carrierBag (async)
        Task {
            do {
                let fountRecipes = try await loadRecipesFromFount()
                NSLog("ADVANCEAPP: 📚 Loaded %d recipes from Fount carrierBag", fountRecipes.count)

                // Merge with existing recipes (Fount is source of truth)
                DispatchQueue.main.async {
                    self.holdings = fountRecipes
                    self.tableView.reloadData()
                }
            } catch {
                NSLog("ADVANCEAPP: ⚠️ Failed to load from Fount: %@", error.localizedDescription)
            }
        }

        // Reload table with current data
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    private func loadRecipesFromFount() async throws -> [[String: Any]] {
        // Use the same pubkey as the keyboard extension
        let pubKey = "02a3b4c5d6e7f8910111213141516171819202122232425262728293031323334"

        let fountUrl = "http://127.0.0.1:5117/bdo/\(pubKey)"

        guard let url = URL(string: fountUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEAPP: 📡 Fetching carrierBag from Fount")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject,
              let dataDict = bdoData["data"] as? [String: Any],
              let carrierBag = dataDict["carrierBag"] as? [String: Any],
              let cookbook = carrierBag["cookbook"] as? [[String: Any]] else {
            NSLog("ADVANCEAPP: 📦 No carrierBag cookbook found in BDO")
            return []
        }

        NSLog("ADVANCEAPP: 📚 Found %d recipes in Fount carrierBag", cookbook.count)
        return cookbook
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return holdings.isEmpty ? 1 : holdings.count // Show empty state if no recipes
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)

        if holdings.isEmpty {
            // Empty state
            cell.textLabel?.text = "📚 No recipes saved yet"
            cell.detailTextLabel?.text = "Use the Planet Nine keyboard to save recipes"
            cell.textLabel?.textColor = .systemGray
            cell.selectionStyle = .none
        } else {
            // Recipe cell
            let holding = holdings[indexPath.row]
            let title = holding["title"] as? String ?? "Untitled Recipe"
            let bdoPubKey = holding["bdoPubKey"] as? String ?? "unknown"
            let savedAt = holding["savedAt"] as? String ?? ""

            cell.textLabel?.text = title
            cell.detailTextLabel?.text = "BDO: \(String(bdoPubKey.prefix(16)))... • \(formatDate(savedAt))"
            cell.textLabel?.textColor = .label
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard !holdings.isEmpty else { return }

        let holding = holdings[indexPath.row]
        let title = holding["title"] as? String ?? "Untitled Recipe"
        let bdoPubKey = holding["bdoPubKey"] as? String ?? "unknown"

        NSLog("ADVANCEAPP: 📚 Selected recipe: %@ (%@)", title, bdoPubKey)

        // Show recipe details (for now, just an alert)
        let alert = UIAlertController(
            title: title,
            message: "BDO PubKey: \(bdoPubKey)\n\nRecipe details would be shown here.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helper Methods

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
