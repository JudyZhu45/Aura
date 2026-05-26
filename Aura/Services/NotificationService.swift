import Foundation
import UserNotifications

/// Drives the daily local notification ("Your daily Aura is ready").
///
/// Local notifications need no entitlements — just a one-time auth prompt.
enum NotificationService {

    static let dailyIdentifier = "aura.daily"

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Schedule a repeating notification that fires at `hour:minute` every day.
    /// Replaces any existing daily notification.
    static func scheduleDaily(hour: Int, minute: Int = 0) {
        cancelDaily()

        let content = UNMutableNotificationContent()
        content.title = "Your daily Aura is ready"
        content.body = "Tap to generate today's wallpaper."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: dailyIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Notification schedule failed: \(error.localizedDescription)")
            }
        }
    }

    static func cancelDaily() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
    }
}
