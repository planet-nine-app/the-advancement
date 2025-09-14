//
//  AdvanceWidget.swift
//  AdvanceWidget - Planet Nine MagiCard Widget
//
//  Created by Zach Babb on 9/13/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), cardData: MagiCardData.placeholder)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let cardData = await fetchBDOCard(pubKey: configuration.cardPubKey)
        return SimpleEntry(date: Date(), configuration: configuration, cardData: cardData)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Fetch the BDO card data (same as keyboard)
        let cardData = await fetchBDOCard(pubKey: configuration.cardPubKey)

        // Generate timeline entries every hour with real Planet Nine card data
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, cardData: cardData)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - BDO Integration (same as keyboard)
    private func fetchBDOCard(pubKey: String) async -> MagiCardData {
        print("🎴 Widget: Fetching BDO card for pubKey: \(pubKey)")

        // Use the same hardcoded working URL as the keyboard
        let bdoURL = "http://127.0.0.1:5114/user/3129c121-e443-4581-82c4-516fb0a2cc64/bdo?timestamp=1757775881380&hash=foo&signature=d2802f3e843b78e45b0940bc159094251dfe2c844300370e8c1019767f001eb720b46dc005552f9141c8e293584688064cca332dabc018db0247bdf7935838b0&pubKey=03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"

        guard let url = URL(string: bdoURL) else {
            print("❌ Widget: Invalid BDO URL")
            return MagiCardData.placeholder
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Parse the same way as the keyboard
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let bdoObject = jsonObject["bdo"] as? [String: Any],
               let cardData = bdoObject["svgContent"] as? String {

                print("✅ Widget: Successfully loaded BDO card")
                return MagiCardData(pubKey: pubKey, svgContent: cardData, isLoaded: true)
            } else {
                print("❌ Widget: Invalid BDO response structure")
                return MagiCardData.placeholder
            }
        } catch {
            print("❌ Widget: BDO request failed: \(error)")
            return MagiCardData.placeholder
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let cardData: MagiCardData?
}

struct MagiCardData {
    let pubKey: String
    let svgContent: String
    let isLoaded: Bool

    static let placeholder = MagiCardData(
        pubKey: "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a",
        svgContent: "",
        isLoaded: false
    )
}

struct AdvanceWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Planet Nine gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.91),  // #667eea
                    Color(red: 0.46, green: 0.29, blue: 0.64)   // #764ba2
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 4) {
                // Header
                HStack {
                    Text("🎴")
                        .font(.title2)
                    Text("Planet Nine")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }

                Spacer()

                // MagiCard representation with BDO integration
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        VStack(spacing: 2) {
                            // Card icon with Planet Nine styling
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Text("🎴")
                                        .font(.system(size: 12))
                                )

                            Text("MagiCard")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)

                            // Show real pubKey from BDO card
                            Text("\(entry.cardData?.pubKey.prefix(16) ?? "Loading")...")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)

                            // Status indicator based on real data
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(entry.cardData?.isLoaded == true ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                                Text(entry.cardData?.isLoaded == true ? "Loaded" : "Loading")
                                    .font(.system(size: 7))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    )

                Spacer()

                // Footer info
                HStack {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(12)
        }
    }
}

struct AdvanceWidget: Widget {
    let kind: String = "AdvanceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            AdvanceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.cardPubKey = "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.cardPubKey = "03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"
        return intent
    }
}

//#Preview(as: .systemSmall) {
//    AdvanceWidget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley, cardData: <#MagiCardData?#>)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}
