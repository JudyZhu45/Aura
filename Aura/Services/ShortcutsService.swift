import UIKit

/// Drives the iOS Shortcuts-based "set wallpaper" flow.
///
/// iOS doesn't let third-party apps set the system wallpaper directly. But the Shortcuts app
/// has a built-in `Set Wallpaper` action. We piggy-back on that: install a one-time Shortcut
/// named exactly "Aura Set Wallpaper" that reads the most recent photo and applies it. Then
/// the app just opens `shortcuts://run-shortcut?name=Aura%20Set%20Wallpaper`.
enum ShortcutsService {

    /// Must match the user-facing name of the installed Shortcut exactly.
    static let shortcutName = "Aura Set Wallpaper"

    /// iCloud share link for the Shortcut that does the work.
    ///
    /// TODO: replace with your hosted link. To create the Shortcut yourself:
    ///   1. Open Shortcuts.app on iOS → tap "+" to create a new shortcut.
    ///   2. Add action: **Get Latest Photos** — Count: 1, Include Screenshots: off.
    ///   3. Add action: **Set Wallpaper** — Wallpaper: (Magic Variable from step 2),
    ///      Show Preview: off, Set Both Lock + Home Screen.
    ///   4. Rename the shortcut to exactly `Aura Set Wallpaper`.
    ///   5. Tap the share icon → "Copy iCloud Link" → paste here.
    static let installURL = URL(string: "https://www.icloud.com/shortcuts/REPLACE_WITH_YOUR_SHORTCUT_ID")!

    /// While the iCloud URL is the placeholder, fall back to walking the user
    /// through building the Shortcut manually in Shortcuts.app.
    static var isInstallURLConfigured: Bool {
        !installURL.absoluteString.contains("REPLACE_WITH_YOUR_SHORTCUT_ID")
    }

    /// Open Shortcuts.app to the main screen so user can build the shortcut by hand.
    /// Returns false if Shortcuts isn't available (e.g. iOS Simulator, or the user
    /// uninstalled it from a real device).
    @MainActor
    @discardableResult
    static func openShortcutsApp() -> Bool {
        guard let url = URL(string: "shortcuts://"),
              UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }

    /// We can't programmatically check if a Shortcut exists, so we cache the user's
    /// "I've installed it" confirmation here.
    static var isMarkedInstalled: Bool {
        get { UserDefaults.standard.bool(forKey: "aura.shortcutInstalled") }
        set { UserDefaults.standard.set(newValue, forKey: "aura.shortcutInstalled") }
    }

    static var canOpenShortcutsApp: Bool {
        guard let url = URL(string: "shortcuts://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Trigger the wallpaper shortcut. Returns false if the URL couldn't be opened
    /// (e.g. Shortcuts.app is uninstalled — rare on stock iOS).
    @MainActor
    @discardableResult
    static func runWallpaperShortcut() -> Bool {
        let encoded = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        guard let url = URL(string: "shortcuts://run-shortcut?name=\(encoded)") else { return false }
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
    }

    @MainActor
    static func openInstallPage() {
        UIApplication.shared.open(installURL)
    }

    /// Fallback if Shortcut isn't installed: jump to Photos so they can set manually.
    @MainActor
    static func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}
