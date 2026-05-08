import Foundation

enum DateScene: String, Codable, CaseIterable {
    case cafe = "カフェ"
    case restaurant = "レストラン"
    case outdoor = "アウトドア"
    case culture = "文化系"
    case surprise = "サプライズ"

    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife"
        case .outdoor: return "leaf.fill"
        case .culture: return "theatermasks.fill"
        case .surprise: return "gift.fill"
        }
    }
}

enum DateStage: String, Codable, CaseIterable {
    case firstDate = "初デート"
    case earlyRelationship = "付き合い始め"
    case established = "安定期"
    case anniversary = "記念日"
    case any = "いつでも"

    var color: String {
        switch self {
        case .firstDate: return "#E94F75"
        case .earlyRelationship: return "#FF7A6B"
        case .established: return "#8B6FD6"
        case .anniversary: return "#C8904A"
        case .any: return "#746071"
        }
    }
}

struct DatePlan: Identifiable, Codable {
    let id: Int
    let title: String
    let scene: DateScene
    let stage: DateStage
    let budget: String
    let duration: String
    let description: String
    let keyPoint: String
    let caution: String
    let location: String
}
