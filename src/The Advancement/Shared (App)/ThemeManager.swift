//
//  ThemeManager.swift
//  The Advancement
//
//  Manages theme loading and CSS injection for WebViews
//

import Foundation

// MARK: - Theme Models

struct ThemeColors: Codable {
    struct Background: Codable {
        let primary: String
        let secondary: String
        let overlay: String
        let overlayDark: String
    }

    struct Accent: Codable {
        let primary: String
        let secondary: String
        let success: String
        let successDark: String
        let error: String
        let purple: String
        let purpleDark: String
        let pink: String
        let pinkDark: String
    }

    struct Text: Codable {
        let primary: String
        let secondary: String
        let muted: String
    }

    struct Border: Codable {
        let primary: String
        let active: String
        let success: String
        let successActive: String
    }

    struct Button: Codable {
        let successStart: String
        let successEnd: String
        let secondaryBg: String
        let secondaryText: String
        let secondaryBorder: String
        let disabled: String
    }

    struct Card: Codable {
        let bgStart: String
        let bgEnd: String
        let borderDefault: String
        let borderHover: String
    }

    struct Shadow: Codable {
        let accent: String
        let success: String
        let successHover: String
        let card: String
    }

    let background: Background
    let accent: Accent
    let text: Text
    let border: Border
    let button: Button
    let card: Card
    let shadow: Shadow
}

struct Theme: Codable {
    let name: String
    let version: String
    let colors: ThemeColors
}

// MARK: - Theme Manager

class ThemeManager {
    static let shared = ThemeManager()

    private var currentTheme: Theme?

    private init() {
        loadDefaultTheme()
    }

    // MARK: - Public Methods

    /// Load a theme from a JSON file in the Resources/Themes directory
    func loadTheme(named themeName: String) -> Theme? {
        guard let themeURL = Bundle.main.url(forResource: themeName, withExtension: "json", subdirectory: "Resources/Themes") else {
            NSLog("ThemeManager: ❌ Could not find theme file: \(themeName).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: themeURL)
            let theme = try JSONDecoder().decode(Theme.self, from: data)
            currentTheme = theme
            NSLog("ThemeManager: ✅ Loaded theme: \(theme.name) v\(theme.version)")
            return theme
        } catch {
            NSLog("ThemeManager: ❌ Failed to load theme: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load the default theme (default.json)
    func loadDefaultTheme() {
        _ = loadTheme(named: "default")
    }

    /// Save a custom theme to UserDefaults
    func saveCustomTheme(_ theme: Theme) {
        do {
            let data = try JSONEncoder().encode(theme)
            UserDefaults.standard.set(data, forKey: "customTheme")
            currentTheme = theme
            NSLog("ThemeManager: ✅ Saved custom theme: \(theme.name)")
        } catch {
            NSLog("ThemeManager: ❌ Failed to save custom theme: \(error.localizedDescription)")
        }
    }

    /// Load a custom theme from UserDefaults
    func loadCustomTheme() -> Theme? {
        guard let data = UserDefaults.standard.data(forKey: "customTheme") else {
            return nil
        }

        do {
            let theme = try JSONDecoder().decode(Theme.self, from: data)
            currentTheme = theme
            NSLog("ThemeManager: ✅ Loaded custom theme: \(theme.name)")
            return theme
        } catch {
            NSLog("ThemeManager: ❌ Failed to load custom theme: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get the current theme (custom or default)
    func getCurrentTheme() -> Theme {
        if let customTheme = loadCustomTheme() {
            return customTheme
        }

        if let current = currentTheme {
            return current
        }

        // Fallback: create a hardcoded default theme
        return createFallbackTheme()
    }

    /// Generate CSS variables from the current theme
    func generateThemeCSS() -> String {
        let theme = getCurrentTheme()

        // Extract hex values and convert to rgba for fill and shadow colors
        let pinkHex = theme.colors.accent.pink.replacingOccurrences(of: "#", with: "")
        let yellowHex = theme.colors.accent.primary.replacingOccurrences(of: "#", with: "")
        let purpleHex = theme.colors.accent.secondary.replacingOccurrences(of: "#", with: "")
        let successHex = theme.colors.accent.success.replacingOccurrences(of: "#", with: "")

        let pinkRGB = hexToRGB(pinkHex)
        let yellowRGB = hexToRGB(yellowHex)
        let purpleRGB = hexToRGB(purpleHex)
        let successRGB = hexToRGB(successHex)

        return """
        :root {
            /* Background Colors */
            --bg-primary: \(theme.colors.background.primary);
            --bg-secondary: \(theme.colors.background.secondary);
            --bg-overlay: \(theme.colors.background.overlay);
            --bg-overlay-dark: \(theme.colors.background.overlayDark);
            --bg-black: #000000;

            /* Accent Colors */
            --accent-primary: \(theme.colors.accent.primary);
            --accent-secondary: \(theme.colors.accent.secondary);
            --accent-success: \(theme.colors.accent.success);
            --accent-success-dark: \(theme.colors.accent.successDark);
            --accent-error: \(theme.colors.accent.error);
            --accent-purple: \(theme.colors.accent.purple);
            --accent-purple-dark: \(theme.colors.accent.purpleDark);
            --accent-purple-light: \(theme.colors.accent.secondary);
            --accent-pink: \(theme.colors.accent.pink);
            --accent-pink-dark: \(theme.colors.accent.pinkDark);
            --accent-yellow: \(theme.colors.accent.primary);

            /* Text Colors */
            --text-primary: \(theme.colors.text.primary);
            --text-secondary: \(theme.colors.text.secondary);
            --text-muted: \(theme.colors.text.muted);

            /* Border Colors */
            --border-primary: \(theme.colors.border.primary);
            --border-active: \(theme.colors.border.active);
            --border-success: \(theme.colors.border.success);
            --border-success-active: \(theme.colors.border.successActive);

            /* Button Colors */
            --btn-success-start: \(theme.colors.button.successStart);
            --btn-success-end: \(theme.colors.button.successEnd);
            --btn-secondary-bg: \(theme.colors.button.secondaryBg);
            --btn-secondary-text: \(theme.colors.button.secondaryText);
            --btn-secondary-border: \(theme.colors.button.secondaryBorder);
            --btn-disabled: \(theme.colors.button.disabled);

            /* Card Colors */
            --card-bg-start: \(theme.colors.card.bgStart);
            --card-bg-end: \(theme.colors.card.bgEnd);
            --card-border-default: \(theme.colors.card.borderDefault);
            --card-border-hover: \(theme.colors.card.borderHover);

            /* Shadow Colors */
            --shadow-accent: \(theme.colors.shadow.accent);
            --shadow-success: \(theme.colors.shadow.success);
            --shadow-success-hover: \(theme.colors.shadow.successHover);
            --shadow-card: \(theme.colors.shadow.card);
            --shadow-purple: rgba(\(purpleRGB.r), \(purpleRGB.g), \(purpleRGB.b), 0.5);
            --shadow-yellow: rgba(\(yellowRGB.r), \(yellowRGB.g), \(yellowRGB.b), 0.6);

            /* Alpha Colors (for fills with opacity) */
            --pink-fill: rgba(\(pinkRGB.r), \(pinkRGB.g), \(pinkRGB.b), 0.2);
            --yellow-fill: rgba(\(yellowRGB.r), \(yellowRGB.g), \(yellowRGB.b), 0.15);
            --purple-fill: rgba(\(purpleRGB.r), \(purpleRGB.g), \(purpleRGB.b), 0.15);
            --purple-input: rgba(\(purpleRGB.r), \(purpleRGB.g), \(purpleRGB.b), 0.15);
            --success-fill: rgba(\(successRGB.r), \(successRGB.g), \(successRGB.b), 0.15);
            --button-active: rgba(\(successRGB.r), \(successRGB.g), \(successRGB.b), 0.3);
        }
        """
    }

    /// Helper function to convert hex color to RGB components
    private func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Int((rgb & 0xFF0000) >> 16)
        let g = Int((rgb & 0x00FF00) >> 8)
        let b = Int(rgb & 0x0000FF)

        return (r, g, b)
    }

    /// Inject theme CSS into a WebView by evaluating JavaScript
    func injectThemeIntoWebView(_ webView: Any, completion: ((Bool) -> Void)? = nil) {
        guard let wkWebView = webView as? WKWebView else {
            NSLog("ThemeManager: ❌ Invalid WebView type")
            completion?(false)
            return
        }

        let themeCSS = generateThemeCSS()

        // Create JavaScript to inject CSS into the page
        let javascript = """
        (function() {
            // Remove existing theme style if it exists
            var existingStyle = document.getElementById('theme-variables');
            if (existingStyle) {
                existingStyle.remove();
            }

            // Create new style element
            var style = document.createElement('style');
            style.id = 'theme-variables';
            style.innerHTML = `\(themeCSS)`;

            // Inject into document head
            document.head.appendChild(style);

            return true;
        })();
        """

        wkWebView.evaluateJavaScript(javascript) { result, error in
            if let error = error {
                NSLog("ThemeManager: ❌ Failed to inject theme: \(error.localizedDescription)")
                completion?(false)
            } else {
                NSLog("ThemeManager: ✅ Theme injected successfully")
                completion?(true)
            }
        }
    }

    // MARK: - Private Methods

    private func createFallbackTheme() -> Theme {
        return Theme(
            name: "Planet Nine Dark (Fallback)",
            version: "1.0",
            colors: ThemeColors(
                background: ThemeColors.Background(
                    primary: "#1a0033",
                    secondary: "#2d0a4e",
                    overlay: "rgba(255, 255, 255, 0.05)",
                    overlayDark: "rgba(0, 0, 0, 0.8)"
                ),
                accent: ThemeColors.Accent(
                    primary: "#fbbf24",
                    secondary: "#a78bfa",
                    success: "#10b981",
                    successDark: "#059669",
                    error: "#ef4444",
                    purple: "#8b5cf6",
                    purpleDark: "#7c3aed",
                    pink: "#ec4899",
                    pinkDark: "#db2777"
                ),
                text: ThemeColors.Text(
                    primary: "#e0d4f7",
                    secondary: "#d1c4e9",
                    muted: "#a78bfa"
                ),
                border: ThemeColors.Border(
                    primary: "rgba(167, 139, 250, 0.3)",
                    active: "#a78bfa",
                    success: "rgba(16, 185, 129, 0.3)",
                    successActive: "#10b981"
                ),
                button: ThemeColors.Button(
                    successStart: "#10b981",
                    successEnd: "#059669",
                    secondaryBg: "rgba(167, 139, 250, 0.2)",
                    secondaryText: "#a78bfa",
                    secondaryBorder: "rgba(167, 139, 250, 0.5)",
                    disabled: "#4b5563"
                ),
                card: ThemeColors.Card(
                    bgStart: "rgba(167, 139, 250, 0.1)",
                    bgEnd: "rgba(139, 92, 246, 0.1)",
                    borderDefault: "rgba(167, 139, 250, 0.3)",
                    borderHover: "#a78bfa"
                ),
                shadow: ThemeColors.Shadow(
                    accent: "rgba(251, 191, 36, 0.5)",
                    success: "rgba(16, 185, 129, 0.4)",
                    successHover: "rgba(16, 185, 129, 0.6)",
                    card: "rgba(167, 139, 250, 0.3)"
                )
            )
        )
    }

    /// Create a debug test theme with blue, light gray, white, and red
    func createDebugTestTheme() -> Theme {
        return Theme(
            name: "Debug Test Theme",
            version: "1.0",
            colors: ThemeColors(
                background: ThemeColors.Background(
                    primary: "#0066cc",           // Blue
                    secondary: "#0052a3",         // Darker blue
                    overlay: "rgba(255, 255, 255, 0.1)",
                    overlayDark: "rgba(0, 0, 0, 0.8)"
                ),
                accent: ThemeColors.Accent(
                    primary: "#ff0000",           // Red
                    secondary: "#cc0000",         // Darker red
                    success: "#ff0000",           // Red
                    successDark: "#cc0000",       // Darker red
                    error: "#ff0000",
                    purple: "#ff0000",
                    purpleDark: "#cc0000",
                    pink: "#ff0000",
                    pinkDark: "#cc0000"
                ),
                text: ThemeColors.Text(
                    primary: "#ffffff",           // White
                    secondary: "#d3d3d3",         // Light gray
                    muted: "#d3d3d3"              // Light gray
                ),
                border: ThemeColors.Border(
                    primary: "rgba(255, 0, 0, 0.3)",       // Red with opacity
                    active: "#ff0000",                      // Red
                    success: "rgba(255, 0, 0, 0.3)",
                    successActive: "#ff0000"
                ),
                button: ThemeColors.Button(
                    successStart: "#ff0000",               // Red
                    successEnd: "#cc0000",                 // Darker red
                    secondaryBg: "rgba(255, 0, 0, 0.2)",
                    secondaryText: "#ff0000",
                    secondaryBorder: "rgba(255, 0, 0, 0.5)",
                    disabled: "#808080"
                ),
                card: ThemeColors.Card(
                    bgStart: "rgba(255, 0, 0, 0.1)",
                    bgEnd: "rgba(204, 0, 0, 0.1)",
                    borderDefault: "rgba(255, 0, 0, 0.3)",
                    borderHover: "#ff0000"
                ),
                shadow: ThemeColors.Shadow(
                    accent: "rgba(255, 0, 0, 0.5)",
                    success: "rgba(255, 0, 0, 0.4)",
                    successHover: "rgba(255, 0, 0, 0.6)",
                    card: "rgba(255, 0, 0, 0.3)"
                )
            )
        )
    }

    /// Apply the debug test theme (blue, light gray, white, red)
    func applyDebugTestTheme() {
        let testTheme = createDebugTestTheme()
        currentTheme = testTheme
        NSLog("ThemeManager: 🔵 Applied debug test theme (blue, light gray, white, red)")
    }
}

// MARK: - WebKit Import

import WebKit
