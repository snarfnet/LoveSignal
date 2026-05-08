import Foundation
import SwiftUI

class PsychologyViewModel: ObservableObject {
    @Published var techniques: [PsychologyTechnique] = []
    @Published var selectedCategory: PsychologyCategory? = nil
    @Published var searchText: String = ""

    init() {
        techniques = Bundle.main.decode([PsychologyTechnique].self, from: "psychology_data.json")
    }

    var filteredTechniques: [PsychologyTechnique] {
        var result = techniques
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.contains(searchText) || $0.summary.contains(searchText) || $0.keyword.contains(searchText)
            }
        }
        return result
    }

    func techniques(for category: PsychologyCategory) -> [PsychologyTechnique] {
        techniques.filter { $0.category == category }
    }
}
