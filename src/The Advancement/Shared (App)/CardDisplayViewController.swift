//
//  CardDisplayViewController.swift
//  The Advancement
//
//  Displays the user's default/current card with options to add or switch cards
//

#if os(iOS)
import UIKit

class CardDisplayViewController: UIViewController {

    private var currentCard: [String: Any]?
    private var allCards: [[String: Any]] = []

    private let cardContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor, // #e91e63 - Pink
            UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0).cgColor  // #9c27b0 - Purple
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 16
        return gradient
    }()

    private let cardBrandLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.alpha = 0.9
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardNumberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardExpiryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.alpha = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cardTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.alpha = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let addCardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add Card", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let switchCardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Switch Card", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 0.15)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 0.5).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No cards saved yet"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor(red: 0.66, green: 0.54, blue: 0.98, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "💳 My Card"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        setupUI()
        loadCards()

        addCardButton.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
        switchCardButton.addTarget(self, action: #selector(switchCardTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload cards when returning from PaymentMethodViewController
        loadCards()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame to match card container
        gradientLayer.frame = cardContainerView.bounds
    }

    private func setupUI() {
        // Add card container with gradient
        view.addSubview(cardContainerView)
        cardContainerView.layer.insertSublayer(gradientLayer, at: 0)
        cardContainerView.addSubview(cardBrandLabel)
        cardContainerView.addSubview(cardNumberLabel)
        cardContainerView.addSubview(cardExpiryLabel)
        cardContainerView.addSubview(cardTypeLabel)

        // Add buttons
        view.addSubview(addCardButton)
        view.addSubview(switchCardButton)

        // Add empty state
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            // Card container - centered in upper half
            cardContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            cardContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            cardContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            cardContainerView.heightAnchor.constraint(equalToConstant: 200),

            // Card brand (top left)
            cardBrandLabel.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 20),
            cardBrandLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 24),

            // Card type (top right)
            cardTypeLabel.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 20),
            cardTypeLabel.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -24),

            // Card number (center)
            cardNumberLabel.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor),
            cardNumberLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 24),

            // Card expiry (bottom left)
            cardExpiryLabel.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor, constant: -20),
            cardExpiryLabel.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 24),

            // Add card button
            addCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            addCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            addCardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            addCardButton.heightAnchor.constraint(equalToConstant: 50),

            // Switch card button
            switchCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            switchCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            switchCardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            switchCardButton.heightAnchor.constraint(equalToConstant: 50),

            // Empty state label (centered)
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor)
        ])
    }

    private func loadCards() {
        // Load saved cards from UserDefaults
        if let cardsData = UserDefaults.standard.data(forKey: "stripe_saved_cards"),
           let cards = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]] {
            allCards = cards

            // Find default card (first one marked as default, or just first card)
            currentCard = cards.first(where: { ($0["isDefault"] as? Bool) == true }) ?? cards.first

            updateUI()
        } else {
            allCards = []
            currentCard = nil
            updateUI()
        }
    }

    private func updateUI() {
        if let card = currentCard {
            // Show card
            cardContainerView.isHidden = false
            emptyStateLabel.isHidden = true

            let brand = (card["brand"] as? String ?? "card").uppercased()
            let last4 = card["last4"] as? String ?? "****"
            let expMonth = card["exp_month"] as? String ?? "**"
            let expYear = card["exp_year"] as? String ?? "****"

            cardBrandLabel.text = brand
            cardNumberLabel.text = "•••• •••• •••• \(last4)"
            cardExpiryLabel.text = "Expires \(expMonth)/\(expYear)"

            // Determine card type (saved, issued, or payout)
            if let cardId = card["id"] as? String {
                if cardId.starts(with: "ic_") {
                    cardTypeLabel.text = "PLANET NINE"
                } else if cardId.starts(with: "pm_") {
                    // Check if it's a payout card
                    let payoutCardId = UserDefaults.standard.string(forKey: "stripe_payout_card_id")
                    if payoutCardId == cardId {
                        cardTypeLabel.text = "PAYOUT CARD"
                    } else {
                        cardTypeLabel.text = "SAVED CARD"
                    }
                } else {
                    cardTypeLabel.text = ""
                }
            }

            // Show/hide switch button based on card count
            switchCardButton.isHidden = allCards.count <= 1

        } else {
            // No cards - show empty state
            cardContainerView.isHidden = true
            emptyStateLabel.isHidden = false
            switchCardButton.isHidden = true
        }
    }

    @objc private func addCardTapped() {
        NSLog("CARDDISPLAY: 💳 Add card tapped")

        let paymentVC = PaymentMethodViewController()
        let navController = UINavigationController(rootViewController: paymentVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func switchCardTapped() {
        NSLog("CARDDISPLAY: 🔄 Switch card tapped")

        guard allCards.count > 1 else {
            NSLog("CARDDISPLAY: ⚠️ No other cards to switch to")
            return
        }

        // Show action sheet with all cards
        let alert = UIAlertController(title: "Switch Card", message: "Select your default card", preferredStyle: .actionSheet)

        for (index, card) in allCards.enumerated() {
            let brand = (card["brand"] as? String ?? "Card").capitalized
            let last4 = card["last4"] as? String ?? "****"
            let isDefault = (card["isDefault"] as? Bool) == true

            let title = isDefault ? "\(brand) •••• \(last4) ✓" : "\(brand) •••• \(last4)"

            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.setDefaultCard(at: index)
            }

            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = switchCardButton
            popoverController.sourceRect = switchCardButton.bounds
        }

        present(alert, animated: true)
    }

    private func setDefaultCard(at index: Int) {
        guard index < allCards.count else { return }

        // Update default flag
        for i in 0..<allCards.count {
            allCards[i]["isDefault"] = (i == index)
        }

        // Save updated cards
        if let cardsData = try? JSONSerialization.data(withJSONObject: allCards) {
            UserDefaults.standard.set(cardsData, forKey: "stripe_saved_cards")
        }

        // Reload UI
        loadCards()

        NSLog("CARDDISPLAY: ✅ Default card updated to index \(index)")
    }
}

#endif
