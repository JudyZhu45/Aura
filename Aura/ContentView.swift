import SwiftUI

enum AuraTab: Hashable {
    case today, generate, history, settings
}

struct ContentView: View {
    @State private var selectedTab: AuraTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(AuraTab.today)

            GenerateView()
                .tabItem { Label("Generate", systemImage: "wand.and.stars") }
                .tag(AuraTab.generate)

            HistoryView()
                .tabItem { Label("History", systemImage: "square.grid.2x2") }
                .tag(AuraTab.history)

            PreferencesView()
                .tabItem { Label("Style", systemImage: "paintpalette") }
                .tag(AuraTab.settings)
        }
        .tint(AuraTheme.accent)
        .onOpenURL { url in
            // Deep link from the lock-screen widget: aura://today
            // For now any aura:// URL just brings us to the Today tab.
            guard url.scheme == "aura" else { return }
            switch url.host {
            case "today", nil: selectedTab = .today
            case "generate":   selectedTab = .generate
            case "history":    selectedTab = .history
            default:           selectedTab = .today
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSubscriptionManager())
        .environmentObject(GenerationLimitManager())
        .environmentObject(StylePreferences())
        .environmentObject(WallpaperStore())
        .environmentObject(NotificationSettings())
        .preferredColorScheme(.dark)
}
