import Foundation

enum TipCategory: String, Codable, CaseIterable {
    case meeting = "出会い"
    case date = "デート"
    case relationship = "関係"
    case selfGrowth = "自分磨き"

    var icon: String {
        switch self {
        case .meeting: return "sparkles"
        case .date: return "heart.fill"
        case .relationship: return "hands.sparkles.fill"
        case .selfGrowth: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .meeting: return "#E94F75"
        case .date: return "#FF7A6B"
        case .relationship: return "#8B6FD6"
        case .selfGrowth: return "#C8904A"
        }
    }
}

struct Tip: Identifiable, Codable {
    let id: Int
    let title: String
    let body: String
    let category: TipCategory
    let actionPoint: String
}
