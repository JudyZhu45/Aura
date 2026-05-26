import SwiftUI
import Photos

struct HomeView: View {
    @EnvironmentObject var store: WallpaperStore
    @EnvironmentObject var subscription: UserSubscriptionManager
    @State private var saveError: String?
    @State private var showInstallSheet = false
    @State private var fallbackSavedAlert = false
    @State private var isWorking = false

    var body: some View {
        ZStack {
            backgroundLayer
            overlay
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallShortcutSheet(onReady: {
                // User came back saying "I've installed it" — kick off the shortcut once.
                showInstallSheet = false
                ShortcutsService.isMarkedInstalled = true
                ShortcutsService.runWallpaperShortcut()
            })
        }
        .alert("Saved to Photos", isPresented: $fallbackSavedAlert) {
            Button("Open Photos") { ShortcutsService.openPhotosApp() }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Set up the Aura Shortcut once for one-tap wallpaper next time. For now: tap the latest photo → Share → Use as Wallpaper.")
        }
        .alert("Couldn't save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let today = store.today,
           let img = ImageStorage.load(filename: today.imageFilename) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.55), .clear, .black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .transition(.opacity)
        } else {
            AuraTheme.backgroundGradient.ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var overlay: some View {
        VStack {
            if let today = store.today {
                FrostedCard {
                    VStack(spacing: 2) {
                        Text("Today")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(today.createdAt, style: .date)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }

            Spacer()

            if store.today != nil {
                Button(action: setAsWallpaper) {
                    HStack {
                        if isWorking { ProgressView().tint(.black) }
                        Label("Set as Wallpaper", systemImage: "photo.on.rectangle.angled")
                    }
                }
                .buttonStyle(PrimaryAuroraButtonStyle())
                .disabled(isWorking)
                .padding(.horizontal)
                .padding(.bottom, 28)
            } else {
                EmptyTodayState()
                    .padding(.bottom, 80)
            }
        }
    }

    /// Flow:
    /// 1. Save today's image to Photos.
    /// 2. If the user has installed the Aura Shortcut, run it — it grabs the latest photo
    ///    and calls the system Set Wallpaper action. ~2 taps total.
    /// 3. Otherwise show the install sheet (one-time onboarding).
    private func setAsWallpaper() {
        guard let today = store.today,
              let img = ImageStorage.load(filename: today.imageFilename) else { return }
        isWorking = true
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                guard status == .authorized || status == .limited else {
                    saveError = "Photo library access was denied. Enable it in Settings to save wallpapers."
                    isWorking = false
                    return
                }
                // Use PhotoKit so we know when the asset is actually saved, then run the Shortcut.
                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: img)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        isWorking = false
                        if !success {
                            saveError = error?.localizedDescription ?? "Failed to save."
                            return
                        }
                        if ShortcutsService.isMarkedInstalled {
                            ShortcutsService.runWallpaperShortcut()
                        } else {
                            // First time: walk user through installing the Shortcut.
                            showInstallSheet = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - One-time install sheet

private struct InstallShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onReady: () -> Void
    @State private var didTapInstall = false
    @State private var shortcutsMissing = false

    var body: some View {
        ZStack {
            AuraTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Circle()
                        .fill(AuraTheme.auroraGradient)
                        .frame(width: 110, height: 110)
                        .blur(radius: 4)
                        .padding(.top, 24)
                        .overlay(
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.top, 24)
                        )

                    VStack(spacing: 8) {
                        Text("One-tap wallpaper")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("iOS doesn't let apps set wallpapers directly. Install the Aura Shortcut once and we'll do it for you.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                    }

                    FrostedCard {
                        VStack(alignment: .leading, spacing: 14) {
                            if ShortcutsService.isInstallURLConfigured {
                                stepRow(1, "Tap the button below — it opens the Shortcut in the Shortcuts app.")
                                stepRow(2, "In Shortcuts, tap **Add Shortcut** at the bottom.")
                                stepRow(3, "Come back to Aura and tap **I've installed it**.")
                            } else {
                                stepRow(1, "Tap the button — it opens Shortcuts.app.")
                                stepRow(2, "Tap **+** and add **Get Latest Photos** (Count: 1).")
                                stepRow(3, "Add **Set Wallpaper** with that photo as input.")
                                stepRow(4, "Rename the shortcut to exactly `Aura Set Wallpaper`.")
                                stepRow(5, "Come back here and tap **I've installed it**.")
                            }
                        }
                    }

                    Button {
                        if ShortcutsService.isInstallURLConfigured {
                            didTapInstall = true
                            ShortcutsService.openInstallPage()
                        } else {
                            let opened = ShortcutsService.openShortcutsApp()
                            if opened {
                                didTapInstall = true
                            } else {
                                // Simulator (or user uninstalled Shortcuts.app).
                                shortcutsMissing = true
                            }
                        }
                    } label: {
                        Label(
                            ShortcutsService.isInstallURLConfigured ? "Get the Aura Shortcut" : "Open Shortcuts.app",
                            systemImage: "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(PrimaryAuroraButtonStyle())

                    Button {
                        ShortcutsService.isMarkedInstalled = true
                        onReady()
                    } label: {
                        Text("I've installed it")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(didTapInstall ? 0.12 : 0.06))
                            .clipShape(Capsule())
                    }
                    .disabled(!didTapInstall)
                    .opacity(didTapInstall ? 1 : 0.5)

                    Button("Skip — open Photos instead") {
                        dismiss()
                        ShortcutsService.openPhotosApp()
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
            }
        }
        .alert("Shortcuts.app not available", isPresented: $shortcutsMissing) {
            Button("Open Photos") {
                shortcutsMissing = false
                dismiss()
                ShortcutsService.openPhotosApp()
            }
            Button("OK", role: .cancel) { shortcutsMissing = false }
        } message: {
            Text("This device doesn't have the Shortcuts app installed — this is normal on the iOS Simulator. Test the Shortcut flow on a real iPhone, or use Photos for now.")
        }
        .interactiveDismissDisabled(false)
    }

    private func stepRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.subheadline.bold())
                .foregroundStyle(.black)
                .frame(width: 24, height: 24)
                .background(AuraTheme.accent, in: Circle())
            Text(.init(text))
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct EmptyTodayState: View {
    var body: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(AuraTheme.auroraGradient)
                .frame(width: 130, height: 130)
                .blur(radius: 6)
                .overlay(
                    Circle().stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: AuraTheme.aurora1.opacity(0.4), radius: 30)

            Text("No wallpaper yet today")
                .font(.title2).fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Head to the Generate tab to create one.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }
}
