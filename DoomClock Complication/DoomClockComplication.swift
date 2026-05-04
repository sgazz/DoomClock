import SwiftUI
import WidgetKit

struct DoomComplicationEntry: TimelineEntry {
    let date: Date
    let targetDate: Date?
    let mode: DoomMode
    let displayText: String
    let subtitle: String
    let progress: Double
}

struct DoomComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoomComplicationEntry {
        DoomComplicationEntry(
            date: Date(),
            targetDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            mode: .suspicious,
            displayText: "D-7",
            subtitle: "FICTIONAL COUNTDOWN",
            progress: 0.35
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoomComplicationEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoomComplicationEntry>) -> Void) {
        let currentEntry = entry()
        completion(Timeline(entries: [currentEntry], policy: .after(nextRefreshDate(for: currentEntry.targetDate))))
    }

    private func entry() -> DoomComplicationEntry {
        let settings = PersistenceService().loadSettings()
        let targetDate = settings.targetDate

        return DoomComplicationEntry(
            date: Date(),
            targetDate: targetDate,
            mode: settings.mode,
            displayText: CountdownFormatter.complicationText(from: targetDate),
            subtitle: CountdownFormatter.rectangularSubtitle(from: targetDate),
            progress: CountdownFormatter.progress(from: targetDate)
        )
    }

    private func nextRefreshDate(for targetDate: Date?) -> Date {
        guard let targetDate else {
            return Date().addingTimeInterval(60 * 60)
        }

        let remaining = targetDate.timeIntervalSinceNow
        guard remaining > 0 else {
            return Date().addingTimeInterval(60 * 60)
        }

        if remaining <= 60 * 60 {
            return Date().addingTimeInterval(5 * 60)
        }

        if remaining <= 24 * 60 * 60 {
            return Date().addingTimeInterval(15 * 60)
        }

        return Date().addingTimeInterval(60 * 60)
    }
}

struct DoomComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DoomComplicationEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.displayText)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .widgetAccentable()

        case .accessoryCircular:
            Gauge(value: entry.progress) {
                Text("D")
            } currentValueLabel: {
                Text(entry.displayText)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(entry.mode.primaryColor)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("D-DAY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(entry.mode.primaryColor.opacity(0.78))
                Text(entry.displayText)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
                Text(entry.subtitle)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.secondary)
            }
            .widgetAccentable()

        case .accessoryCorner:
            Gauge(value: entry.progress) {
                Text("D")
            } currentValueLabel: {
                Text(entry.displayText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(entry.mode.primaryColor)

        default:
            Text(entry.displayText)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .monospacedDigit()
        }
    }
}

struct DoomClockComplication: Widget {
    let kind = "DoomClockComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoomComplicationProvider()) { entry in
            DoomComplicationView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Doom Countdown")
        .description("Shows your fictional Doomsday countdown.")
        .supportedFamilies([
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct DoomClockComplicationBundle: WidgetBundle {
    var body: some Widget {
        DoomClockComplication()
    }
}
