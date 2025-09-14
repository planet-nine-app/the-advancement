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
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: FooActionIntent()) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🌊")
                                .font(.system(size: 16))
                        )

                    Text("foo")
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
        .displayName("Planet Nine - Foo")
        .description("Trigger foo action with sessionless signature")
    }
}

struct AdvanceWidgetBarControl: ControlWidget {
    let kind: String = "AdvanceWidgetBarControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: BarActionIntent()) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("🌱")
                                .font(.system(size: 16))
                        )

                    Text("bar")
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
        .displayName("Planet Nine - Bar")
        .description("Trigger bar action with sessionless signature")
    }

}
