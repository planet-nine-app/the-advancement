//
//  PreviewViewController.swift
//  AdvanceLook - Planet Nine MagiCard QuickLook Extension
//
//  Created by Zach Babb on 9/13/25.
//

import UIKit
import QuickLook
import WebKit

class PreviewViewController: UIViewController, QLPreviewingController {

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎴 AdvanceLook: PreviewViewController viewDidLoad called")
        setupWebView()
    }

    private func setupWebView() {
        webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        view.addSubview(webView)
    }

    func preparePreviewOfFile(at url: URL) async throws {
        print("🔍 AdvanceLook: preparePreviewOfFile called with URL: \(url)")
        print("🔍 AdvanceLook: File extension: \(url.pathExtension)")

        do {
            let data = try Data(contentsOf: url)
            print("🔍 AdvanceLook: File size: \(data.count) bytes")
            if let preview = String(data: data.prefix(100), encoding: .utf8) {
                print("🔍 AdvanceLook: First 100 chars: \(preview)")
            }
        } catch {
            print("❌ AdvanceLook: Error reading file: \(error)")
            throw error
        }

        // Parse the Planet Nine card file
        let cardData = try parseMagiCardFile(at: url)
        print("✅ AdvanceLook: Successfully parsed card data")

        // Generate the preview content
        let previewHTML = generateCardPreviewHTML(cardData)
        print("✅ AdvanceLook: Generated HTML preview (\(previewHTML.count) characters)")

        // Display the preview
        await MainActor.run {
            print("🎴 AdvanceLook: Loading HTML in webView")
            webView.loadHTMLString(previewHTML, baseURL: nil)
        }
    }

    // MARK: - File Parsing

    private func parseMagiCardFile(at url: URL) throws -> MagiCardData {
        let data = try Data(contentsOf: url)

        // First, try to parse as JSON (our custom format)
        if let jsonCard = try? parseJSONCard(data) {
            return jsonCard
        }

        // If it's not JSON, try to parse as BDO reference
        if let bdoCard = try? parseBDOReference(data) {
            return bdoCard
        }

        // For debugging: if it's a text file, create a test card
        if url.pathExtension.lowercased() == "txt" {
            return createDebugCard(from: data)
        }

        throw MagiCardError.invalidFormat
    }

    private func parseJSONCard(_ data: Data) throws -> MagiCardData {
        let decoder = JSONDecoder()
        return try decoder.decode(MagiCardData.self, from: data)
    }

    private func parseBDOReference(_ data: Data) throws -> MagiCardData {
        guard let content = String(data: data, encoding: .utf8),
              content.lowercased().contains("bdopubkey") else {
            throw MagiCardError.invalidFormat
        }

        // Extract pubKey from content (simplified parsing)
        let lines = content.components(separatedBy: .newlines)
        var pubKey = "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"

        for line in lines {
            if line.lowercased().contains("bdopubkey:") {
                let components = line.components(separatedBy: ":")
                if components.count > 1 {
                    pubKey = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
                break
            }
        }

        return MagiCardData(
            type: "magicard",
            version: "1.0",
            pubKey: pubKey,
            svgContent: generatePlaceholderSVG(for: pubKey),
            metadata: MagiCardMetadata(
                title: "Planet Nine Card",
                description: "Loading from BDO...",
                spells: ["navigate"],
                signature: nil
            )
        )
    }

    private func createDebugCard(from data: Data) -> MagiCardData {
        let content = String(data: data, encoding: .utf8) ?? "Unknown content"

        return MagiCardData(
            type: "magicard",
            version: "1.0",
            pubKey: "debug-test-key",
            svgContent: generateDebugSVG(content: content),
            metadata: MagiCardMetadata(
                title: "🔧 Debug Test Card",
                description: "Extension is working! This is a test file.",
                spells: ["debug"],
                signature: "test-signature"
            )
        )
    }

    // MARK: - Preview Generation

    private func generateCardPreviewHTML(_ card: MagiCardData) -> String {
        let spellCount = card.metadata.spells.count
        let isVerified = card.metadata.signature != nil

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 20px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: calc(100vh - 40px);
                    display: flex;
                    flex-direction: column;
                }

                .card-container {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 16px;
                    padding: 20px;
                    backdrop-filter: blur(10px);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                }

                .card-header {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    margin-bottom: 16px;
                    padding-bottom: 16px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
                }

                .card-title {
                    font-size: 24px;
                    font-weight: bold;
                    margin: 0;
                }

                .verification-badge {
                    background: \(isVerified ? "rgba(40, 167, 69, 0.3)" : "rgba(255, 193, 7, 0.3)");
                    border: 1px solid \(isVerified ? "rgba(40, 167, 69, 0.5)" : "rgba(255, 193, 7, 0.5)");
                    border-radius: 20px;
                    padding: 6px 12px;
                    font-size: 12px;
                    font-weight: 500;
                }

                .card-content {
                    flex: 1;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: rgba(255, 255, 255, 0.05);
                    border-radius: 12px;
                    margin: 16px 0;
                    min-height: 200px;
                    overflow: hidden;
                }

                .card-info {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 16px;
                    margin-top: 16px;
                }

                .info-item {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 8px;
                    padding: 12px;
                    text-align: center;
                }

                .info-label {
                    font-size: 12px;
                    opacity: 0.8;
                    margin-bottom: 4px;
                }

                .info-value {
                    font-size: 16px;
                    font-weight: bold;
                }

                .cta-section {
                    background: rgba(255, 255, 255, 0.15);
                    border-radius: 12px;
                    padding: 16px;
                    margin-top: 20px;
                    text-align: center;
                }

                .cta-title {
                    font-size: 18px;
                    font-weight: bold;
                    margin-bottom: 8px;
                }

                .cta-description {
                    font-size: 14px;
                    opacity: 0.9;
                    margin-bottom: 16px;
                    line-height: 1.4;
                }

                .cta-button {
                    background: rgba(0, 123, 255, 0.4);
                    border: 1px solid rgba(0, 123, 255, 0.6);
                    border-radius: 8px;
                    color: white;
                    padding: 12px 24px;
                    font-size: 16px;
                    font-weight: 500;
                    text-decoration: none;
                    display: inline-block;
                }

                .pubkey-display {
                    background: rgba(0, 0, 0, 0.3);
                    border-radius: 6px;
                    padding: 8px;
                    font-family: 'SF Mono', monospace;
                    font-size: 10px;
                    word-break: break-all;
                    margin-top: 8px;
                }
            </style>
        </head>
        <body>
            <div class="card-container">
                <div class="card-header">
                    <h1 class="card-title">🎴 \(card.metadata.title)</h1>
                    <div class="verification-badge">
                        \(isVerified ? "✅ Verified" : "⏳ Pending")
                    </div>
                </div>

                <div class="card-content">
                    \(card.svgContent)
                </div>

                <div class="card-info">
                    <div class="info-item">
                        <div class="info-label">Type</div>
                        <div class="info-value">🎴 MagiCard</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Spells</div>
                        <div class="info-value">✨ \(spellCount)</div>
                    </div>
                </div>

                <div class="pubkey-display">
                    <strong>PubKey:</strong> \(card.pubKey)
                </div>

                <div class="cta-section">
                    <div class="cta-title">🌍 Planet Nine Extension Working!</div>
                    <div class="cta-description">
                        This preview is generated by the AdvanceLook QuickLook extension using UI-based approach.
                    </div>
                    <a href="advancement://magicard?pubkey=\(card.pubKey)" class="cta-button">
                        🚀 Open in The Advancement
                    </a>
                </div>
            </div>
        </body>
        </html>
        """
    }

    private func generatePlaceholderSVG(for pubKey: String) -> String {
        return """
        <svg width="300" height="200" viewBox="0 0 300 200" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <linearGradient id="cardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
                    <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
                </linearGradient>
            </defs>

            <rect width="300" height="200" fill="url(#cardGrad)" rx="16"/>
            <circle cx="150" cy="60" r="25" fill="rgba(255,255,255,0.3)"/>
            <text x="150" y="70" text-anchor="middle" fill="white" font-size="24">🎴</text>
            <text x="150" y="110" text-anchor="middle" fill="white" font-size="18" font-weight="bold">Planet Nine Card</text>
            <text x="150" y="130" text-anchor="middle" fill="rgba(255,255,255,0.8)" font-size="12">Loading from BDO...</text>
            <rect x="20" y="150" width="260" height="20" fill="rgba(255,255,255,0.2)" rx="10"/>
            <text x="150" y="163" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-size="10">\(String(pubKey.prefix(40)))...</text>
        </svg>
        """
    }

    private func generateDebugSVG(content: String) -> String {
        return """
        <svg width="400" height="200" viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <linearGradient id="debugGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:#28a745;stop-opacity:1" />
                    <stop offset="100%" style="stop-color:#20c997;stop-opacity:1" />
                </linearGradient>
            </defs>

            <rect width="400" height="200" fill="url(#debugGrad)" rx="16"/>
            <circle cx="200" cy="60" r="25" fill="rgba(255,255,255,0.3)"/>
            <text x="200" y="70" text-anchor="middle" fill="white" font-size="24">🔧</text>
            <text x="200" y="110" text-anchor="middle" fill="white" font-size="18" font-weight="bold">UI Extension Working!</text>
            <text x="200" y="130" text-anchor="middle" fill="rgba(255,255,255,0.9)" font-size="14">QLPreviewingController loaded</text>
            <text x="200" y="160" text-anchor="middle" fill="rgba(255,255,255,0.8)" font-size="12">File: \(content.prefix(30))...</text>
        </svg>
        """
    }
}

// MARK: - Data Models

struct MagiCardData: Codable {
    let type: String
    let version: String
    let pubKey: String
    let svgContent: String
    let metadata: MagiCardMetadata
}

struct MagiCardMetadata: Codable {
    let title: String
    let description: String
    let spells: [String]
    let signature: String?
}

enum MagiCardError: Error {
    case invalidFormat
    case networkError
    case parsingError
}