import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscription: UserSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: String?

    var body: some View {
        ZStack {
            AuraTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    heroOrb
                        .padding(.top, 24)

                    Text("Aura Premium")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Unlock unlimited wallpapers, custom prompts, and downloads.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 24)

                    benefitsCard
                    productList
                    purchaseButton

                    HStack(spacing: 24) {
                        Button("Restore") {
                            Task { await subscription.restore() }
                        }
                        Button("Close") { dismiss() }
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))

                    Text("Subscription renews automatically. Cancel anytime in Settings.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal)
            }
        }
        .onAppear(perform: pickDefaultProduct)
        .onChange(of: subscription.products.map(\.id)) { _, _ in
            pickDefaultProduct()
        }
        .onChange(of: subscription.isPremium) { _, newValue in
            if newValue { dismiss() }
        }
    }

    private var heroOrb: some View {
        ZStack {
            Circle()
                .fill(AuraTheme.auroraGradient)
                .frame(width: 130, height: 130)
                .blur(radius: 6)
                .shadow(color: AuraTheme.aurora1.opacity(0.5), radius: 30)
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var benefitsCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: 14) {
                benefit("Unlimited generations", icon: "infinity")
                benefit("Custom text prompts", icon: "text.cursor")
                benefit("Download to Photos", icon: "arrow.down.circle.fill")
                benefit("Priority access to new styles", icon: "sparkles")
            }
        }
    }

    private func benefit(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AuraTheme.accent)
                .frame(width: 22)
            Text(text).foregroundStyle(.white)
            Spacer()
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private var productList: some View {
        if !subscription.products.isEmpty {
            VStack(spacing: 12) {
                ForEach(subscription.products, id: \.id) { product in
                    productRow(product)
                }
            }
        } else if !subscription.productsLoadAttempted {
            // Initial load — show spinner.
            HStack(spacing: 8) {
                ProgressView().tint(.white)
                Text("Loading plans…")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.footnote)
            }
            .padding(.vertical, 8)
        } else {
            // Load finished but returned empty. Most common in dev: launched
            // via `simctl launch` (CLI), which bypasses the scheme's StoreKit
            // configuration. On a real device this means no App Store products
            // exist with these IDs yet.
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title3)
                    .foregroundStyle(AuraTheme.accent)
                Text("Couldn't load plans")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Launch from Xcode (⌘R) to load the local StoreKit config, or check your connection.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Button("Retry") {
                    Task { await subscription.loadProducts() }
                }
                .font(.caption.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(AuraTheme.accent, in: Capsule())
            }
            .padding(.vertical, 12)
        }
    }

    private func productRow(_ product: Product) -> some View {
        let isSelected = selectedID == product.id
        let isYearly = product.id.lowercased().contains("yearly")
        return Button {
            selectedID = product.id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .foregroundStyle(.white)
                        .font(.headline)
                    Text(product.description)
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .foregroundStyle(.white)
                        .font(.headline)
                    if isYearly {
                        Text("Best value")
                            .font(.caption2.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AuraTheme.accent, in: Capsule())
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(isSelected ? 0.06 : 0.02))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? AuraTheme.accent : Color.white.opacity(0.18), lineWidth: 2)
            )
        }
    }

    private var purchaseButton: some View {
        let isReady = !subscription.products.isEmpty && selectedID != nil
        return Button {
            guard
                let id = selectedID,
                let product = subscription.products.first(where: { $0.id == id })
            else { return }
            Task { await subscription.purchase(product) }
        } label: {
            HStack {
                if subscription.purchaseInProgress {
                    ProgressView().tint(.black)
                }
                Text(subscription.purchaseInProgress ? "Processing…" : "Start Premium")
            }
        }
        .buttonStyle(PrimaryAuroraButtonStyle())
        .disabled(!isReady || subscription.purchaseInProgress)
        .opacity(isReady ? 1 : 0.5)
    }

    private func pickDefaultProduct() {
        if selectedID == nil {
            selectedID = subscription.products.first(where: { $0.id.lowercased().contains("yearly") })?.id
                ?? subscription.products.first?.id
        }
    }
}
