import SwiftUI

struct GenerateView: View {
    @EnvironmentObject var preferences: StylePreferences
    @EnvironmentObject var subscription: UserSubscriptionManager
    @EnvironmentObject var limitManager: GenerationLimitManager
    @EnvironmentObject var store: WallpaperStore

    @State private var customPrompt: String = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AuraTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    promptCard
                    summaryCard
                    generateButton
                    if let err = errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
        }
        .task {
            // Refresh counter on appear (handles midnight rollover while app was open).
            limitManager.refresh()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create your wallpaper")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if subscription.isPremium {
                    Label("Premium · Unlimited", systemImage: "infinity")
                        .font(.footnote)
                        .foregroundStyle(AuraTheme.accent)
                } else {
                    let left = limitManager.remainingToday(isPremium: false)
                    Text("\(left) free generation\(left == 1 ? "" : "s") left today")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }
        }
    }

    private var promptCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Custom prompt")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if !subscription.isPremium {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AuraTheme.accent)
                    }
                }

                TextField(
                    "Describe your dream wallpaper…",
                    text: $customPrompt,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(AuraTheme.accent)
                .disabled(!subscription.isPremium)
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !subscription.isPremium {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Custom prompts are a Premium feature — unlock →")
                            .font(.caption)
                            .foregroundStyle(AuraTheme.accent)
                    }
                }
            }
        }
    }

    private var summaryCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Style")
                    .font(.headline)
                    .foregroundStyle(.white)
                row("Mood", preferences.mood.rawValue)
                row("Palette", preferences.palette.rawValue)
                row("Art style", preferences.artStyle.rawValue)
            }
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value).foregroundStyle(.white)
        }
        .font(.subheadline)
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack {
                if isGenerating {
                    ProgressView().tint(.black)
                }
                Text(isGenerating ? "Generating…" : "Generate Wallpaper")
            }
        }
        .buttonStyle(PrimaryAuroraButtonStyle())
        .disabled(isGenerating)
        .opacity(isGenerating ? 0.85 : 1)
    }

    private func generate() async {
        errorMessage = nil

        if !limitManager.canGenerate(isPremium: subscription.isPremium) {
            showPaywall = true
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        let custom = subscription.isPremium ? customPrompt : nil
        let prompt = preferences.composePrompt(custom: custom)

        do {
            let image = try await OpenAIService.generateImage(prompt: prompt)
            let filename = "wallpaper_\(UUID().uuidString).jpg"
            try ImageStorage.save(image, filename: filename)
            let wallpaper = Wallpaper(
                id: UUID(),
                createdAt: Date(),
                prompt: prompt,
                mood: preferences.mood.rawValue,
                palette: preferences.palette.rawValue,
                artStyle: preferences.artStyle.rawValue,
                imageFilename: filename
            )
            store.add(wallpaper)
            limitManager.recordGeneration()
            customPrompt = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
