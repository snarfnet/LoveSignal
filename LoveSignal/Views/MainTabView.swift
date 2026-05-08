import SwiftUI

struct MainTabView: View {
    @StateObject private var todayVM = TodayViewModel()
    @StateObject private var psychologyVM = PsychologyViewModel()
    @StateObject private var matchVM = MatchViewModel()
    @StateObject private var plannerVM = PlannerViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#FFF7F8"))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.accentRose)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(AppColors.accentRose)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            TodayView()
                .environmentObject(todayVM)
                .tabItem { Label("今日", systemImage: "sparkles") }

            PsychologyView()
                .environmentObject(psychologyVM)
                .tabItem { Label("心理", systemImage: "brain.head.profile") }

            MatchView()
                .environmentObject(matchVM)
                .tabItem { Label("診断", systemImage: "heart.circle.fill") }

            PlannerView()
                .environmentObject(plannerVM)
                .tabItem { Label("プラン", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .accentColor(AppColors.accentRose)
    }
}
