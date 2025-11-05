//
//  HTMLTemplateService.swift
//  AdvanceKey
//
//  Created by Claude on 9/20/25.
//

import Foundation

public enum TemplateError: Error, LocalizedError {
    case templateNotFound(String)
    case templateLoadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let message):
            return "Template not found: \(message)"
        case .templateLoadFailed(let message):
            return "Template load failed: \(message)"
        }
    }
}

public class HTMLTemplateService {

    // MARK: - Product Template Methods

    /// Generates HTML for products using the template
    public static func generateProductsHTML(products: [SanoraService.Product]) throws -> String {
        guard let templatePath = Bundle(for: HTMLTemplateService.self).path(forResource: "products-template", ofType: "html") else {
            throw TemplateError.templateNotFound("products-template.html not found in bundle")
        }

        guard let template = try? String(contentsOfFile: templatePath) else {
            throw TemplateError.templateLoadFailed("Failed to load products-template.html from \(templatePath)")
        }

        let productsHTML = products.map { product in
            generateProductCardHTML(product: product)
        }.joined(separator: "\n")

        let emptyStateHTML = products.isEmpty ? generateProductsEmptyState() : ""
        let emojicodingJS = try loadEmojicodingJS()

        return template
            .replacingOccurrences(of: "{{PRODUCTS_HTML}}", with: productsHTML)
            .replacingOccurrences(of: "{{EMPTY_STATE}}", with: emptyStateHTML)
            .replacingOccurrences(of: "{{EMOJICODING_JS}}", with: emojicodingJS)
    }

    private static func generateProductCardHTML(product: SanoraService.Product) -> String {
        let imageHTML = product.imageURL?.isEmpty == false ?
            "style=\"background-image: url('\(product.imageURL!)')\"" : ""

        let imageContent = product.imageURL?.isEmpty == false ? "" : "📦"

        let escapedTitle = escapeHTML(product.title)
        let escapedDescription = escapeHTML(product.description)
        let escapedProductId = escapeHTML(product.productId)
        let escapedUUID = escapeHTML(product.uuid)

        return """
        <div class="product-card" onclick="viewProduct('\(escapedProductId)', '\(escapedTitle)', '\(escapedDescription)', '\(escapedUUID)')">
            <div class="product-image" \(imageHTML)>
                \(imageContent)
            </div>
            <div class="product-title">\(escapedTitle)</div>
            <div class="product-description">\(escapedDescription)</div>
            <div class="product-uuid">UUID: \(escapedUUID)</div>
            <div class="product-price">\(product.formattedPrice)</div>
            <button class="buy-button" onclick="event.stopPropagation(); buyProduct('\(escapedProductId)', '\(escapedTitle)', \(product.price), '\(escapedDescription)', '\(escapedUUID)')">
                Buy Now
            </button>
        </div>
        """
    }

    private static func generateProductsEmptyState() -> String {
        return """
        <div class="empty-state">
            <h2>🌟 No Products Available</h2>
            <p>Products from Sanora will appear here when available</p>
        </div>
        """
    }

    // MARK: - Payment Template Methods

    /// Generates HTML for payment methods using the template
    public static func generatePaymentHTML(
        selectedProduct: SanoraService.Product,
        paymentMethods: [PaymentMethod]
    ) throws -> String {
        guard let templatePath = Bundle(for: HTMLTemplateService.self).path(forResource: "payment-template", ofType: "html") else {
            throw TemplateError.templateNotFound("payment-template.html not found in bundle")
        }

        guard let template = try? String(contentsOfFile: templatePath) else {
            throw TemplateError.templateLoadFailed("Failed to load payment-template.html from \(templatePath)")
        }

        let productSummaryHTML = generateProductSummaryHTML(product: selectedProduct)
        let paymentMethodsHTML = paymentMethods.map { method in
            generatePaymentMethodHTML(method: method)
        }.joined(separator: "\n")

        let addPaymentHTML = generateAddPaymentHTML()
        let emptyStateHTML = paymentMethods.isEmpty ? generatePaymentEmptyState() : ""

        return template
            .replacingOccurrences(of: "{{PRODUCT_SUMMARY}}", with: productSummaryHTML)
            .replacingOccurrences(of: "{{PAYMENT_METHODS_HTML}}", with: paymentMethodsHTML)
            .replacingOccurrences(of: "{{ADD_PAYMENT_OPTION}}", with: addPaymentHTML)
            .replacingOccurrences(of: "{{EMPTY_STATE}}", with: emptyStateHTML)
    }

    private static func generateProductSummaryHTML(product: SanoraService.Product) -> String {
        let escapedTitle = escapeHTML(product.title)
        let escapedDescription = escapeHTML(product.description)

        return """
        <div class="product-summary">
            <h2>\(escapedTitle)</h2>
            <div class="price">\(product.formattedPrice)</div>
            <div class="description">\(escapedDescription)</div>
        </div>
        """
    }

    private static func generatePaymentMethodHTML(method: PaymentMethod) -> String {
        let iconClass = getPaymentIconClass(brand: method.brand)
        let escapedId = escapeHTML(method.id)
        let escapedBrand = escapeHTML(method.brand)
        let escapedLast4 = escapeHTML(method.last4)

        return """
        <div class="payment-method" id="\(escapedId)" onclick="selectPaymentMethod('\(escapedId)', {brand: '\(escapedBrand)', last4: '\(escapedLast4)'})">
            <div class="payment-info">
                <div class="payment-icon \(iconClass)">💳</div>
                <div class="payment-details">
                    <div class="payment-name">\(escapedBrand.capitalized)</div>
                    <div class="payment-last4">•••• \(escapedLast4)</div>
                </div>
            </div>
            <div class="select-indicator"></div>
        </div>
        """
    }

    private static func generateAddPaymentHTML() -> String {
        return """
        <div class="add-payment" onclick="addPaymentMethod()">
            <div class="icon">➕</div>
            <div class="text">Add New Payment Method</div>
        </div>
        """
    }

    private static func generatePaymentEmptyState() -> String {
        return """
        <div class="empty-state">
            <h2>💳 No Payment Methods</h2>
            <p>Add a payment method to complete your purchase</p>
        </div>
        """
    }

    // MARK: - Helper Methods

    private static func getPaymentIconClass(brand: String) -> String {
        switch brand.lowercased() {
        case "visa":
            return "visa-icon"
        case "mastercard":
            return "mastercard-icon"
        case "amex", "american express":
            return "amex-icon"
        default:
            return "default-icon"
        }
    }

    private static func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }

    internal static func loadEmojicodingJS() throws -> String {
        guard let jsPath = Bundle(for: HTMLTemplateService.self).path(forResource: "emojicoding", ofType: "js") else {
            throw TemplateError.templateNotFound("emojicoding.js not found in bundle")
        }

        guard let jsContent = try? String(contentsOfFile: jsPath) else {
            throw TemplateError.templateLoadFailed("Failed to load emojicoding.js from \(jsPath)")
        }

        return jsContent
    }

}

// MARK: - Supporting Data Structures

public struct PaymentMethod {
    public let id: String
    public let brand: String
    public let last4: String
    public let type: String

    public init(id: String, brand: String, last4: String, type: String = "card") {
        self.id = id
        self.brand = brand
        self.last4 = last4
        self.type = type
    }
}