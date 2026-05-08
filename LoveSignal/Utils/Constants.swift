import SwiftUI

struct AppColors {
    static let backgroundTop = Color(hex: "#FFF7F8")
    static let backgroundBottom = Color(hex: "#F4ECFF")
    static let accentRose = Color(hex: "#E94F75")
    static let accentCoral = Color(hex: "#FF7A6B")
    static let accentGold = Color(hex: "#C8904A")
    static let accentLavender = Color(hex: "#8B6FD6")
    static let textDark = Color(hex: "#2B1B2F")
    static let textWarm = Color(hex: "#746071")
    static let cardBackground = Color.white.opacity(0.92)
    static let shadowColor = Color(hex: "#8B6FD6").opacity(0.16)
}

struct AppFonts {
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
    static func headline(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func caption(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
}

enum UserDefaultsKeys {
    static let favoriteTipIDs = "favoriteTipIDs"
    static let favoritePlanIDs = "favoritePlanIDs"
    static let matchResult = "matchResult"
    static let matchAnswers = "matchAnswers"
}
