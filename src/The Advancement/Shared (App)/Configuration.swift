//
//  Configuration.swift
//  The Advancement
//
//  Centralized configuration for Planet Nine service URLs
//

import Foundation

public struct Configuration {
    // MARK: - Environment Configuration

    /// The subdomain for this environment (e.g., "hitchhikers", "dev", "production")
    public static let subdomain: String = "hitchhikers"

    /// The base domain (e.g., "allyabase.com")
    public static let baseDomain: String = "allyabase.com"

    /// Use HTTPS for production, HTTP for local development
    public static let useHTTPS: Bool = true

    // MARK: - Service Names

    private enum Service: String {
        case bdo = "bdo"
        case addie = "addie"
        case fount = "fount"
        case nexus = "nexus"
        case sanora = "sanora"
        case covenant = "covenant"
    }

    // MARK: - URL Generation

    /// Generate a service URL based on subdomain and domain
    /// Format: https://subdomain.service.domain.tld
    private static func serviceURL(for service: Service) -> String {
        let scheme = useHTTPS ? "https" : "http"
        return "\(scheme)://\(subdomain).\(service.rawValue).\(baseDomain)"
    }

    // MARK: - Service URLs

    /// BDO service base URL (Basic Data Objects)
    public static let bdoBaseURL: String = serviceURL(for: .bdo)

    /// Addie service base URL (Payment/AI service)
    public static let addieBaseURL: String = serviceURL(for: .addie)

    /// Fount service base URL (MAGIC protocol resolver)
    public static let fountBaseURL: String = serviceURL(for: .fount)

    /// Nexus service base URL (Wiki/documentation)
    public static let nexusBaseURL: String = serviceURL(for: .nexus)

    /// Sanora service base URL (Synonym service)
    public static let sanoraBaseURL: String = serviceURL(for: .sanora)

    /// Covenant service base URL (Contract service)
    public static let covenantBaseURL: String = serviceURL(for: .covenant)

    // MARK: - Common Endpoints

    public struct BDO {
        public static func createUser() -> String {
            return "\(bdoBaseURL)/user/create"
        }

        public static func putBDO(userUUID: String) -> String {
            return "\(bdoBaseURL)/user/\(userUUID)/bdo"
        }

        public static func getEmojicode(pubKey: String) -> String {
            return "\(bdoBaseURL)/pubkey/\(pubKey)/emojicode"
        }

        public static var baseURL: String {
            return "\(bdoBaseURL)/"
        }
    }

    public struct Addie {
        public static func createUser() -> String {
            return "\(addieBaseURL)/user/create"
        }

        public static func chargeWithSavedMethod() -> String {
            return "\(addieBaseURL)/charge-with-saved-method"
        }
    }

    public struct Fount {
        public static func createUser() -> String {
            return "\(fountBaseURL)/user/create"
        }

        public static func getBDO(bdoPubKey: String) -> String {
            return "\(fountBaseURL)/bdo/\(bdoPubKey)"
        }

        public static func createBDO() -> String {
            return "\(fountBaseURL)/bdo"
        }

        public static func getUser(userUUID: String) -> String {
            return "\(fountBaseURL)/user/\(userUUID)"
        }

        public static func grantExperience(userUUID: String) -> String {
            return "\(fountBaseURL)/user/\(userUUID)/grant"
        }

        public static func resolve(spellName: String) -> String {
            return "\(fountBaseURL)/resolve/\(spellName)"
        }
    }

    public struct Sanora {
        public static var baseURL: String {
            return sanoraBaseURL
        }
    }

    public struct Covenant {
        public static func signContract(contractUuid: String) -> String {
            return "\(covenantBaseURL)/contract/\(contractUuid)/sign"
        }
    }

    // MARK: - Debug Info

    public static func printConfiguration() {
        print("🌍 The Advancement Configuration")
        print("   Subdomain: \(subdomain)")
        print("   Domain: \(baseDomain)")
        print("   HTTPS: \(useHTTPS)")
        print("")
        print("📡 Service URLs:")
        print("   BDO:      \(bdoBaseURL)")
        print("   Addie:    \(addieBaseURL)")
        print("   Fount:    \(fountBaseURL)")
        print("   Nexus:    \(nexusBaseURL)")
        print("   Sanora:   \(sanoraBaseURL)")
        print("   Covenant: \(covenantBaseURL)")
    }
}
