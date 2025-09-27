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
        NSLog("ADVANCEAPP: 📚 Loading recipes from SharedUserDefaults...")

        // Force sync
        SharedUserDefaults.shared.synchronize()

        // Get holdings
        holdings = SharedUserDefaults.getHoldings()
        NSLog("ADVANCEAPP: 📚 Found %d holdings", holdings.count)

        // Filter for recipes only
        holdings = holdings.filter { holding in
            (holding["type"] as? String) == "recipe"
        }

        NSLog("ADVANCEAPP: 📚 Found %d recipes after filtering", holdings.count)

        // Debug print
        SharedUserDefaults.debugPrint(prefix: "ADVANCEAPP")

        // Reload table
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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
