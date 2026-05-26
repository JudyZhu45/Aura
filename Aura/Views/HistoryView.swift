import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: WallpaperStore
    @EnvironmentObject var subscription: UserSubscriptionManager
    @State private var showPaywall = false
    @State private var selected: Wallpaper?

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AuraTheme.backgroundGradient.ignoresSafeArea()

                if store.wallpapers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundStyle(AuraTheme.accent.opacity(0.7))
                        Text("No wallpapers yet")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Generate your first one to see it here.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(store.wallpapers) { wp in
                                Button {
                                    selected = wp
                                } label: {
                                    thumbnail(for: wp)
                                }
                            }
                        }
                        .padding(6)
                    }
                }
            }
            .navigationTitle("History")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(item: $selected) { wp in
            DetailView(wallpaper: wp, showPaywall: $showPaywall)
                .environmentObject(subscription)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
        }
    }

    private func thumbnail(for wp: Wallpaper) -> some View {
        ZStack {
            if let img = ImageStorage.load(filename: wp.imageFilename) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.white.opacity(0.05)
            }
        }
        .frame(height: 230)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct DetailView: View {
    let wallpaper: Wallpaper
    @Binding var showPaywall: Bool
    @EnvironmentObject var subscription: UserSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var savedToast = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = ImageStorage.load(filename: wallpaper.imageFilename) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Button(action: download) {
                        Label(
                            subscription.isPremium ? "Download" : "Download (Premium)",
                            systemImage: subscription.isPremium ? "arrow.down.circle.fill" : "lock.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding()
                Spacer()
                if savedToast {
                    Text("Saved to Photos")
                        .font(.footnote)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private func download() {
        if !subscription.isPremium {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showPaywall = true
            }
            return
        }
        guard let img = ImageStorage.load(filename: wallpaper.imageFilename) else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { savedToast = false }
        }
    }
}
