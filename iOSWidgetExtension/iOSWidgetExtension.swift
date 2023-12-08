//
//  iOSWidgetExtension.swift
//  iOSWidgetExtension
//
//  Created by Cameron Little on 2023-12-08.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), slot: nil, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), slot: 1, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, slot: 1, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    
    let slot: UInt8?
    let configuration: ConfigurationAppIntent
}

struct iOSWidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let slot = entry.slot {
            VStack {
                HStack {
                    Text("P\(slot+1)").gcLabel()
                    Spacer()
                    Button(intent: PressAIntent()) {
                        Text("A")
                    }
                        .buttonStyle(GCCButton(
                            color: GameCubeColors.green,
                            width: 60,
                            height: 60
                        ))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .fixedSize(horizontal: false, vertical: false)
                }
                Spacer()
                Button(intent: PressBIntent()) {
                    Text("B")
                }
                .buttonStyle(GCCButton(
                    color: GameCubeColors.red,
                    width: 50,
                    height: 50
                ))
            }
        } else {
            Text("Not connected").gcLabel()
        }
    }
}

struct iOSWidgetExtension: Widget {
    let kind: String = "iOSWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            iOSWidgetExtensionEntryView(entry: entry)
                .containerBackground(GameCubeColors.purple, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    iOSWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, slot: nil, configuration: ConfigurationAppIntent())
    SimpleEntry(date: .now, slot: 1, configuration: ConfigurationAppIntent())
}
