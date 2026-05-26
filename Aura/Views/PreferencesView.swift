import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: StylePreferences
    @EnvironmentObject var notifications: NotificationSettings

    var body: some View {
        ZStack {
            AuraTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    notificationSection

                    Text("Your style")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top, 4)

                    pickerSection(
                        title: "Mood",
                        selection: $preferences.mood,
                        options: Mood.allCases
                    )
                    pickerSection(
                        title: "Color palette",
                        selection: $preferences.palette,
                        options: Palette.allCases
                    )
                    pickerSection(
                        title: "Art style",
                        selection: $preferences.artStyle,
                        options: ArtStyle.allCases
                    )

                    Text("These guide every wallpaper Aura generates.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        .alert(
            "Notifications are off",
            isPresented: $notifications.permissionDenied
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enable notifications for Aura in iOS Settings to get a daily reminder.")
        }
    }

    // MARK: - Notification section

    private var notificationSection: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(AuraTheme.accent)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily reminder")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(notifications.isEnabled
                             ? "Aura will ping you at \(formattedHour) every day."
                             : "Get a gentle nudge to generate today's wallpaper.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Toggle("", isOn: $notifications.isEnabled)
                        .labelsHidden()
                        .tint(AuraTheme.accent)
                }

                if notifications.isEnabled {
                    Divider().overlay(Color.white.opacity(0.1))
                    HStack {
                        Text("Time").foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Picker("Hour", selection: $notifications.hour) {
                            ForEach(0..<24, id: \.self) { h in
                                Text(displayHour(h)).tag(h)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AuraTheme.accent)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var formattedHour: String { displayHour(notifications.hour) }

    private func displayHour(_ h: Int) -> String {
        var comps = DateComponents()
        comps.hour = h
        comps.minute = 0
        let date = Calendar.current.date(from: comps) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "h a"
        return f.string(from: date)
    }

    // MARK: - Picker grid

    private func pickerSection<T>(
        title: String,
        selection: Binding<T>,
        options: [T]
    ) -> some View where T: Hashable & Identifiable & RawRepresentable, T.RawValue == String {
        FrostedCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(options) { option in
                        let isSelected = selection.wrappedValue == option
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            Text(option.rawValue)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Group {
                                        if isSelected {
                                            AuraTheme.auroraGradient
                                        } else {
                                            Color.white.opacity(0.08)
                                        }
                                    }
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}
