//
//  AppIntent.swift
//  AdvanceWidget - Planet Nine Widget Actions
//
//  Created by Zach Babb on 9/13/25.
//

import WidgetKit
import AppIntents
import ActivityKit

// MARK: - Configuration Intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Planet Nine Widget" }
    static var description: IntentDescription { "Configure your Planet Nine widget." }

    @Parameter(title: "Card PubKey", default: "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a")
    var cardPubKey: String
}

// Control configuration
struct PlanetNineControlConfiguration: ControlConfigurationIntent {
    static var title: LocalizedStringResource { "Planet Nine Control" }
    static var description: IntentDescription { "Configure Planet Nine actions" }

    @Parameter(title: "Action Type", default: .foo)
    var actionType: ActionType
}

enum ActionType: String, AppEnum, CaseIterable {
    case foo = "foo"
    case bar = "bar"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Action Type")

    static var caseDisplayRepresentations: [ActionType : DisplayRepresentation] = [
        .foo: DisplayRepresentation(title: "Foo Action", subtitle: "Blue ocean action"),
        .bar: DisplayRepresentation(title: "Bar Action", subtitle: "Green plant action")
    ]
}

// MARK: - Action Intents
struct FooActionIntent: AppIntent {
    static var title: LocalizedStringResource { "Foo Action" }
    static var description: IntentDescription { "Triggers foo action with sessionless signature" }

    func perform() async throws -> some IntentResult {
        // Generate sessionless signature for "foo"
        let signature = try await generateSessionlessSignature(for: "foo")

        // Update live activity if running
        await updateLiveActivity(message: "foo", signature: signature, color: .blue)

        return .result()
    }
}

struct BarActionIntent: AppIntent {
    static var title: LocalizedStringResource { "Bar Action" }
    static var description: IntentDescription { "Triggers bar action with sessionless signature" }

    func perform() async throws -> some IntentResult {
        // Generate sessionless signature for "bar"
        let signature = try await generateSessionlessSignature(for: "bar")

        // Update live activity if running
        await updateLiveActivity(message: "bar", signature: signature, color: .green)

        return .result()
    }
}

// MARK: - Sessionless Integration
private let sessionless = Sessionless()

private func generateSessionlessSignature(for message: String) async throws -> String {
    print("🎴 Widget: Generating sessionless signature for '\(message)'")

    do {
        // Use Sessionless just like SafariWebExtensionHandler
        guard let signature = try await sessionless.sign(message: message) else {
            throw NSError(domain: "SessionlessError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate signature"])
        }
        print("🎴 Widget: Generated sessionless signature: \(signature.prefix(32))...")
        return signature
    } catch {
        print("❌ Widget: Error signing message with Sessionless: \(error)")
        throw error
    }
}

@MainActor
private func updateLiveActivity(message: String, signature: String, color: LiveActivityColor) async {
    let attributes = PlanetNineActivityAttributes()
    let state = PlanetNineActivityAttributes.ContentState(
        message: message,
        signature: signature,
        color: color,
        timestamp: Date()
    )

    // Update existing live activities
    for activity in Activity<PlanetNineActivityAttributes>.activities {
        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(30))
        await activity.update(content)
    }

    // If no activities exist, start one
    if Activity<PlanetNineActivityAttributes>.activities.isEmpty {
        do {
            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(30))
            _ = try Activity<PlanetNineActivityAttributes>.request(
                attributes: attributes,
                content: content
            )
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }
}

// MARK: - Live Activity Color
enum LiveActivityColor: String, Codable, CaseIterable, Hashable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
}
