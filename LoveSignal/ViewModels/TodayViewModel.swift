import Foundation
import SwiftUI

class TodayViewModel: ObservableObject {
    @Published var tips: [Tip] = []
    @Published var todayTip: Tip?
    @Published var favoriteTipIDs: Set<Int> = []

    init() {
        tips = Bundle.main.decode([Tip].self, from: "daily_tips.json")
        loadFavorites()
        setTodayTip()
    }

    private func setTodayTip() {
        guard !tips.isEmpty else { return }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % tips.count
        todayTip = tips[index]
    }

    func toggleFavorite(tip: Tip) {
        if favoriteTipIDs.contains(tip.id) {
            favoriteTipIDs.remove(tip.id)
        } else {
            favoriteTipIDs.insert(tip.id)
        }
        saveFavorites()
    }

    func isFavorite(tip: Tip) -> Bool {
        favoriteTipIDs.contains(tip.id)
    }

    var favoriteTips: [Tip] {
        tips.filter { favoriteTipIDs.contains($0.id) }
    }

    private func saveFavorites() {
        let ids = Array(favoriteTipIDs)
        UserDefaults.standard.set(ids, forKey: UserDefaultsKeys.favoriteTipIDs)
    }

    private func loadFavorites() {
        if let ids = UserDefaults.standard.array(forKey: UserDefaultsKeys.favoriteTipIDs) as? [Int] {
            favoriteTipIDs = Set(ids)
        }
    }

    func shareText(for tip: Tip) -> String {
        "💕 \(tip.title)\n\n\(tip.body)\n\n✨ 今日のアクション：\(tip.actionPoint)\n\n#LoveSignal #恋愛心理学"
    }
}
