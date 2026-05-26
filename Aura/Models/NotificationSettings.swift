import Foundation

@MainActor
final class NotificationSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "aura.notifEnabled")
            apply()
        }
    }
    @Published var hour: Int {
        didSet {
            UserDefaults.standard.set(hour, forKey: "aura.notifHour")
            if isEnabled { apply() }
        }
    }
    @Published var permissionDenied: Bool = false

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "aura.notifEnabled")
        let stored = UserDefaults.standard.integer(forKey: "aura.notifHour")
        self.hour = (stored == 0) ? 8 : stored
    }

    /// Re-sync OS state with our stored preferences. Call at app launch.
    func sync() {
        Task { @MainActor in
            let status = await NotificationService.authorizationStatus()
            if status == .denied {
                permissionDenied = true
                isEnabled = false
                return
            }
            if isEnabled && status == .authorized {
                NotificationService.scheduleDaily(hour: hour)
            } else if !isEnabled {
                NotificationService.cancelDaily()
            }
        }
    }

    /// Called from `didSet` of `isEnabled` / `hour`. Asks for permission
    /// the first time the user turns it on.
    private func apply() {
        Task { @MainActor in
            if isEnabled {
                let status = await NotificationService.authorizationStatus()
                if status == .notDetermined {
                    let ok = await NotificationService.requestAuthorization()
                    if !ok {
                        // User denied at prompt — roll the toggle back.
                        isEnabled = false
                        permissionDenied = true
                        return
                    }
                } else if status == .denied {
                    isEnabled = false
                    permissionDenied = true
                    return
                }
                NotificationService.scheduleDaily(hour: hour)
            } else {
                NotificationService.cancelDaily()
            }
        }
    }
}
