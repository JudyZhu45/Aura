import Foundation
import UIKit
import WidgetKit

struct Wallpaper: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let prompt: String
    let mood: String
    let palette: String
    let artStyle: String
    let imageFilename: String
}

@MainActor
final class WallpaperStore: ObservableObject {
    @Published private(set) var wallpapers: [Wallpaper] = []

    private let key = "aura.wallpapers"

    init() { load() }

    var today: Wallpaper? {
        wallpapers.first { Calendar.current.isDateInToday($0.createdAt) }
    }

    func add(_ wallpaper: Wallpaper) {
        wallpapers.insert(wallpaper, at: 0)
        save()
        publishToWidget(wallpaper)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Wallpaper].self, from: data) else { return }
        wallpapers = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(wallpapers) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Drop a small JPEG preview + metadata into the shared App Group so the
    /// lock-screen widget can show today's wallpaper.
    private func publishToWidget(_ wp: Wallpaper) {
        // 1. Write metadata into shared UserDefaults
        let d = SharedStorage.defaults
        d.set(wp.mood, forKey: SharedStorage.Key.todayMood)
        d.set(wp.palette, forKey: SharedStorage.Key.todayPalette)
        d.set(wp.artStyle, forKey: SharedStorage.Key.todayArtStyle)
        d.set(wp.createdAt, forKey: SharedStorage.Key.todayDate)
        d.set(true, forKey: SharedStorage.Key.hasContent)

        // 2. Write a downscaled JPEG to the shared container.
        //    Widget memory budget is 30 MB total but we keep it tiny: ~256px wide.
        if let dst = SharedStorage.todayImageURL,
           let img = ImageStorage.load(filename: wp.imageFilename),
           let resized = img.resizedForWidget(maxDimension: 256),
           let data = resized.jpegData(compressionQuality: 0.75) {
            try? data.write(to: dst, options: .atomic)
        }

        // 3. Ping WidgetKit to refresh.
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension UIImage {
    /// Downscale so the longest side is `maxDimension`. Used to keep widget JPEGs tiny.
    func resizedForWidget(maxDimension: CGFloat) -> UIImage? {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        if scale >= 1.0 { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
