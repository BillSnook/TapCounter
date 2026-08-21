//
//  TapCounterComplication.swift
//  TapCounterWatchWidget
//
//  A small (circular) and medium (rectangular) complication that just
//  shows the app icon and opens TapCounter when tapped. No live counter
//  data yet — this is a placeholder to get a launcher complication on the
//  watch face; a follow-up can wire it to CounterStore for real values.
//

import WidgetKit
import SwiftUI

struct TapCounterTimelineEntry: TimelineEntry {
    let date: Date
}

struct TapCounterTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TapCounterTimelineEntry {
        TapCounterTimelineEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TapCounterTimelineEntry) -> Void) {
        completion(TapCounterTimelineEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TapCounterTimelineEntry>) -> Void) {
        // Static content for now, so a single entry that never refreshes.
        // Switch to a real refresh policy once this shows live counts.
        let timeline = Timeline(entries: [TapCounterTimelineEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

struct TapCounterComplicationView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            HStack(spacing: 8) {
                AppIconImage()
                    .frame(width: 32, height: 32)
                Text("TapCounter")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .widgetAccentable()
        default:
            // .accessoryCircular (the "small" complication)
            AppIconImage()
                .widgetAccentable()
        }
    }
}

/// The app icon, clipped to whatever shape the current complication slot uses
/// (circle for accessoryCircular, rounded rect for accessoryRectangular).
private struct AppIconImage: View {
    var body: some View {
        Image("ComplicationIcon")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(ContainerRelativeShape())
    }
}

struct TapCounterComplication: Widget {
    let kind: String = "TapCounterComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TapCounterTimelineProvider()) { _ in
            TapCounterComplicationView()
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("TapCounter")
        .description("Opens TapCounter.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
