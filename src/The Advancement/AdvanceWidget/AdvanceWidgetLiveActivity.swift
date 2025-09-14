//
//  AdvanceWidgetLiveActivity.swift
//  AdvanceWidget - Planet Nine Live Activity
//
//  Created by Zach Babb on 9/13/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PlanetNineActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var message: String
        var signature: String
        var color: LiveActivityColor
        var timestamp: Date
    }
}

struct AdvanceWidgetLiveActivity: Widget {
    let kind: String = "AdvanceWidgetLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PlanetNineActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Text("🎴")
                        .font(.title2)
                    Text("Planet Nine")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()

                    // Color indicator
                    Circle()
                        .fill(colorForActivity(context.state.color))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Message: \(context.state.message)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Signature:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(context.state.signature.prefix(32) + "...")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                    }
                }

                Spacer()

                HStack {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(context.state.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
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
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("🎴")
                            .font(.title3)
                        Text("Planet Nine")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Circle()
                        .fill(colorForActivity(context.state.color))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text("Message: \(context.state.message)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)

                        Text("Signature: \(context.state.signature.prefix(20))...")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Text("🎴")
                    .font(.caption2)
            } compactTrailing: {
                Circle()
                    .fill(colorForActivity(context.state.color))
                    .frame(width: 16, height: 16)
            } minimal: {
                Circle()
                    .fill(colorForActivity(context.state.color))
                    .frame(width: 16, height: 16)
            }
        }
    }

    private func colorForActivity(_ color: LiveActivityColor) -> Color {
        switch color {
        case .blue:
            return Color.blue
        case .green:
            return Color.green
        case .purple:
            return Color.purple
        case .orange:
            return Color.orange
        }
    }
}

extension PlanetNineActivityAttributes {
    fileprivate static var preview: PlanetNineActivityAttributes {
        PlanetNineActivityAttributes()
    }
}

extension PlanetNineActivityAttributes.ContentState {
    fileprivate static var fooExample: PlanetNineActivityAttributes.ContentState {
        PlanetNineActivityAttributes.ContentState(
            message: "foo",
            signature: "d2802f3e843b78e45b0940bc159094251dfe2c844300370e8c1019767f001eb720b46dc005552f9141c8e293584688064cca332dabc018db0247bdf7935838b0",
            color: .blue,
            timestamp: Date()
        )
    }

    fileprivate static var barExample: PlanetNineActivityAttributes.ContentState {
        PlanetNineActivityAttributes.ContentState(
            message: "bar",
            signature: "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890abcdef12345678901234567890123456789012345678901234567890123456",
            color: .green,
            timestamp: Date()
        )
    }
}

#Preview("Notification", as: .content, using: PlanetNineActivityAttributes.preview) {
   AdvanceWidgetLiveActivity()
} contentStates: {
    PlanetNineActivityAttributes.ContentState.fooExample
    PlanetNineActivityAttributes.ContentState.barExample
}
