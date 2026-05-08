import Foundation

enum PsychologyCategory: String, Codable, CaseIterable {
    case meeting = "出会い"
    case date = "デート"
    case deepen = "深める"
    case selfGrowth = "自分磨き"
    case attraction = "引き寄せ"

    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .date: return "heart.circle.fill"
        case .deepen: return "infinity"
        case .selfGrowth: return "star.circle.fill"
        case .attraction: return "sparkles"
        }
    }
}

struct PsychologyTechnique: Identifiable, Codable {
    let id: Int
    let name: String
    let category: PsychologyCategory
    let summary: String
    let scientificBasis: String
    let practicalTip: String
    let keyword: String
}
