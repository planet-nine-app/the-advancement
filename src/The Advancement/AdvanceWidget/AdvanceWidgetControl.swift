//
//  AdvanceWidgetControl.swift
//  AdvanceWidget - Planet Nine Widget Control
//
//  Created by Zach Babb on 9/13/25.
//

import WidgetKit
import SwiftUI

struct AdvanceWidgetControl: ControlWidget {
    let kind: String = "AdvanceWidgetControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: kind,
            intent: PlanetNineControlConfiguration.self
        ) { configuration in
            ControlWidgetButton(action: configuration.actionType == .foo ? createFooActionIntent() : createBarActionIntent()) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(colorForActionType(configuration.actionType))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(iconForActionType(configuration.actionType))
                                .font(.system(size: 16))
                        )

                    Text(configuration.actionType.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text("Planet Nine")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.49, blue: 0.91),  // #667eea
                            Color(red: 0.46, green: 0.29, blue: 0.64)   // #764ba2
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .displayName("Planet Nine")
        .description("Quick actions for Planet Nine spells")
    }

    private func createFooActionIntent() -> FooActionIntent {
        return FooActionIntent()
    }

    private func createBarActionIntent() -> BarActionIntent {
        return BarActionIntent()
    }

    private func colorForActionType(_ actionType: ActionType) -> Color {
        switch actionType {
        case .foo:
            return Color.blue.opacity(0.3)
        case .bar:
            return Color.green.opacity(0.3)
        }
    }

    private func iconForActionType(_ actionType: ActionType) -> String {
        switch actionType {
        case .foo:
            return "🌊"
        case .bar:
            return "🌱"
        }
    }
}
