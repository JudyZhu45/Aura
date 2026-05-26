import Foundation
import StoreKit

@MainActor
final class UserSubscriptionManager: ObservableObject {
    // ⚠️ DEMO MODE — flip to `false` to re-enable the paywall + daily-limit gating.
    // While `true`, every user is treated as Premium: unlimited generations,
    // custom text prompts unlocked, history downloads unlocked, paywall never appears.
    static let demoUnlocked = true

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool = Self.demoUnlocked
    @Published var purchaseInProgress: Bool = false
    @Published var lastError: String?
    /// Becomes `true` after the first `loadProducts()` call completes (success or fail).
    /// Used by the paywall to distinguish "still loading" from "loaded but empty".
    @Published private(set) var productsLoadAttempted: Bool = false

    // TODO: replace these with your real StoreKit product IDs from App Store Connect.
    // The same IDs must exist in Resources/Aura.storekit for simulator testing.
    static let monthlyID = "com.aura.subscription.monthly"
    static let yearlyID = "com.aura.subscription.yearly"

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        do {
            let ids = [Self.monthlyID, Self.yearlyID]
            let loaded = try await Product.products(for: ids)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            lastError = "Could not load products: \(error.localizedDescription)"
        }
        productsLoadAttempted = true
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        if Self.demoUnlocked {
            isPremium = true
            return
        }
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}
