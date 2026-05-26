import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var subscriptionManager = UserSubscriptionManager()
    @StateObject private var limitManager = GenerationLimitManager()
    @StateObject private var preferences = StylePreferences()
    @StateObject private var wallpaperStore = WallpaperStore()
    @StateObject private var notificationSettings = NotificationSettings()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(subscriptionManager)
                    .environmentObject(limitManager)
                    .environmentObject(preferences)
                    .environmentObject(wallpaperStore)
                    .environmentObject(notificationSettings)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                async let _ = subscriptionManager.loadProducts()
                async let _ = subscriptionManager.refreshEntitlements()
                notificationSettings.sync()

                try? await Task.sleep(for: .milliseconds(1500))
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
