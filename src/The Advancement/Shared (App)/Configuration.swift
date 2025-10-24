//
//  Configuration.swift
//  The Advancement
//
//  Centralized configuration for Planet Nine service URLs
//

import Foundation

public struct Configuration {
    // MARK: - Environment Configuration

    /// Environment mode: "production", "test", or "local"
    public static let environment: String = "production"  // Change to "test" for local testing
    //public static let environment: String = "test"  // Change to "test" for local testing

    /// Test base number (1, 2, or 3) - only used when environment = "test"
    public static let testBaseNumber: Int = 1

    /// The subdomain for this environment (e.g., "hitchhikers", "dev", "production")
    public static let subdomain: String = "hitchhikers"

    /// The base domain (e.g., "allyabase.com")
    public static let baseDomain: String = "allyabase.com"

    /// Use HTTPS for production, HTTP for local development
    public static let useHTTPS: Bool = environment == "production"

    // MARK: - Service Names

    private enum Service: String {
        case bdo = "bdo"
        case addie = "addie"
        case fount = "fount"
        case nexus = "nexus"
        case sanora = "sanora"
        case covenant = "covenant"
        case dolores = "dolores"
    }

    // MARK: - URL Generation

    /// Generate a service URL based on environment
    /// - Production: https://subdomain.service.domain.tld
    /// - Test: http://127.0.0.1:port (based on testBaseNumber)
    /// - Local: http://localhost:port
    private static func serviceURL(for service: Service) -> String {
        switch environment {
        case "test":
            let portBase = 5000 + (testBaseNumber * 100)
            let port: Int
            switch service {
            case .bdo:
                port = portBase + 14
            case .addie:
                port = portBase + 16 // Not in test environment yet
            case .fount:
                port = portBase + 17
            case .nexus:
                port = 7001 // Not in test environment yet
            case .sanora:
                port = portBase + 21
            case .covenant:
                port = portBase + 22
            case .dolores:
                port = portBase + 18
            }
            return "http://127.0.0.1:\(port)"

        case "local":
            let port: Int
            switch service {
            case .bdo:
                port = 3003
            case .addie:
                port = 3004
            case .fount:
                port = 3006
            case .nexus:
                port = 3005
            case .sanora:
                port = 7243
            case .covenant:
                port = 3011
            case .dolores:
                port = 3007
            }
            return "http://localhost:\(port)"

        default: // "production"
            let scheme = useHTTPS ? "https" : "http"
            return "\(scheme)://\(subdomain).\(service.rawValue).\(baseDomain)"
        }
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

    /// Dolores service base URL (Discovery/audio service)
    public static let doloresBaseURL: String = serviceURL(for: .dolores)

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

    public struct Dolores {
        public static func audioPlayer(feedUrl: String) -> String {
            guard let encodedFeedUrl = feedUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return "\(doloresBaseURL)/audio-player.html"
            }
            return "\(doloresBaseURL)/audio-player.html?feedUrl=\(encodedFeedUrl)"
        }

        public static var baseURL: String {
            return doloresBaseURL
        }
    }

    // MARK: - Debug Info

    public static func printConfiguration() {
        print("🌍 The Advancement Configuration")
        print("   Environment: \(environment)")
        if environment == "test" {
            print("   Test Base: #\(testBaseNumber)")
        } else if environment == "production" {
            print("   Subdomain: \(subdomain)")
            print("   Domain: \(baseDomain)")
        }
        print("   HTTPS: \(useHTTPS)")
        print("")
        print("📡 Service URLs:")
        print("   BDO:      \(bdoBaseURL)")
        print("   Addie:    \(addieBaseURL)")
        print("   Fount:    \(fountBaseURL)")
        print("   Nexus:    \(nexusBaseURL)")
        print("   Sanora:   \(sanoraBaseURL)")
        print("   Covenant: \(covenantBaseURL)")
        print("   Dolores:  \(doloresBaseURL)")
        print("")
        print("💡 To change environment, edit Configuration.swift:")
        print("   - Set environment to \"test\" for local testing (127.0.0.1:ports)")
        print("   - Set environment to \"local\" for localhost development")
        print("   - Set environment to \"production\" for deployed services")
    }
}
