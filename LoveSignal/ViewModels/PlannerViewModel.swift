import Foundation
import SwiftUI

class PlannerViewModel: ObservableObject {
    @Published var plans: [DatePlan] = []
    @Published var selectedScene: DateScene? = nil
    @Published var selectedStage: DateStage? = nil
    @Published var favoritePlanIDs: Set<Int> = []

    init() {
        plans = Bundle.main.decode([DatePlan].self, from: "date_plans.json")
        loadFavorites()
    }

    var filteredPlans: [DatePlan] {
        var result = plans
        if let scene = selectedScene {
            result = result.filter { $0.scene == scene }
        }
        if let stage = selectedStage {
            result = result.filter { $0.stage == stage }
        }
        return result
    }

    var favoritePlans: [DatePlan] {
        plans.filter { favoritePlanIDs.contains($0.id) }
    }

    func toggleFavorite(plan: DatePlan) {
        if favoritePlanIDs.contains(plan.id) {
            favoritePlanIDs.remove(plan.id)
        } else {
            favoritePlanIDs.insert(plan.id)
        }
        saveFavorites()
    }

    func isFavorite(plan: DatePlan) -> Bool {
        favoritePlanIDs.contains(plan.id)
    }

    private func saveFavorites() {
        let ids = Array(favoritePlanIDs)
        UserDefaults.standard.set(ids, forKey: UserDefaultsKeys.favoritePlanIDs)
    }

    private func loadFavorites() {
        if let ids = UserDefaults.standard.array(forKey: UserDefaultsKeys.favoritePlanIDs) as? [Int] {
            favoritePlanIDs = Set(ids)
        }
    }
}
