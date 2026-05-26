import Foundation

/// Bridge between the main app and the widget extension via App Group.
///
/// The App Group identifier must match the entitlements file of BOTH targets
/// (Aura.entitlements + AuraWidgets.entitlements).
enum SharedStorage {
    static let appGroupID = "group.com.aura.app"

    // MARK: - UserDefaults

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    enum Key {
        static let todayMood = "today.mood"
        static let todayPalette = "today.palette"
        static let todayArtStyle = "today.artStyle"
        static let todayDate = "today.date"
        static let hasContent = "today.hasContent"
    }

    // MARK: - File container

    /// The shared file URL where we drop a small JPEG preview for the widget.
    /// Returns nil if App Group isn't configured (e.g. running without entitlements).
    static var todayImageURL: URL? {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        return container.appendingPathComponent("today.jpg")
    }

    // MARK: - Snapshot

    struct TodaySnapshot {
        let mood: String
        let palette: String
        let artStyle: String
        let date: Date
        let imageData: Data?

        var displayLabel: String { mood }
    }

    static func readTodaySnapshot() -> TodaySnapshot? {
        let d = defaults
        guard d.bool(forKey: Key.hasContent) else { return nil }
        let mood = d.string(forKey: Key.todayMood) ?? "Aura"
        let palette = d.string(forKey: Key.todayPalette) ?? ""
        let artStyle = d.string(forKey: Key.todayArtStyle) ?? ""
        let date = (d.object(forKey: Key.todayDate) as? Date) ?? Date()
        var imageData: Data?
        if let url = todayImageURL {
            imageData = try? Data(contentsOf: url)
        }
        return TodaySnapshot(
            mood: mood,
            palette: palette,
            artStyle: artStyle,
            date: date,
            imageData: imageData
        )
    }
}
