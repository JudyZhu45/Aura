import WidgetKit
import Foundation

struct AuraEntry: TimelineEntry {
    let date: Date
    let mood: String
    let displayDate: Date
    let imageData: Data?
    let hasContent: Bool

    static let placeholder = AuraEntry(
        date: .now,
        mood: "Calm",
        displayDate: .now,
        imageData: nil,
        hasContent: false
    )
}

struct AuraTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuraEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (AuraEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AuraEntry>) -> Void) {
        let entry = readEntry()
        // Refresh tomorrow at 00:01 so the "Today" label rolls over.
        let tomorrow = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
        let refreshAt = Calendar.current.date(byAdding: .minute, value: 1, to: tomorrow) ?? tomorrow
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func readEntry() -> AuraEntry {
        guard let snapshot = SharedStorage.readTodaySnapshot() else {
            return AuraEntry(
                date: .now,
                mood: "—",
                displayDate: .now,
                imageData: nil,
                hasContent: false
            )
        }
        return AuraEntry(
            date: .now,
            mood: snapshot.displayLabel,
            displayDate: snapshot.date,
            imageData: snapshot.imageData,
            hasContent: true
        )
    }
}
