import Foundation

@MainActor
final class GenerationLimitManager: ObservableObject {
    @Published private(set) var todayCount: Int = 0

    private let countKey = "aura.dailyCount"
    private let dateKey = "aura.dailyCountDate"
    static let freeLimit = 1

    init() {
        // Load directly into the stored property — does NOT publish (we're in init).
        let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        if Calendar.current.isDateInToday(storedDate) {
            self.todayCount = UserDefaults.standard.integer(forKey: countKey)
        } else {
            UserDefaults.standard.set(0, forKey: countKey)
            UserDefaults.standard.set(Date(), forKey: dateKey)
            self.todayCount = 0
        }
    }

    /// Call this from `.task` / button actions — never from inside a SwiftUI `body`,
    /// because it can mutate `@Published todayCount` and that would re-trigger the render.
    func refresh() {
        let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        let newCount: Int
        if Calendar.current.isDateInToday(storedDate) {
            newCount = UserDefaults.standard.integer(forKey: countKey)
        } else {
            UserDefaults.standard.set(0, forKey: countKey)
            UserDefaults.standard.set(Date(), forKey: dateKey)
            newCount = 0
        }
        if todayCount != newCount {
            todayCount = newCount   // only publish when something actually changed
        }
    }

    func canGenerate(isPremium: Bool) -> Bool {
        if isPremium { return true }
        refresh()   // safe — called from button-action Task, not from body
        return todayCount < Self.freeLimit
    }

    /// Pure read — safe to call from a view's `body`.
    func remainingToday(isPremium: Bool) -> Int {
        if isPremium { return Int.max }
        return max(0, Self.freeLimit - todayCount)
    }

    func recordGeneration() {
        todayCount += 1
        UserDefaults.standard.set(todayCount, forKey: countKey)
        UserDefaults.standard.set(Date(), forKey: dateKey)
    }
}
