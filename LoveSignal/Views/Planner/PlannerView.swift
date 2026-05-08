import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var vm: PlannerViewModel
    @State private var selectedPlan: DatePlan?
    @State private var showFavoritesOnly = false

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        LoveHeroCard(
                            imageName: "love-planner",
                            title: "デートを物語にする",
                            subtitle: "相手との距離感、予算、時間に合わせて自然なプランを提案"
                        )
                        .padding(.horizontal, 20)

                        sceneFilter
                        stageFilter
                        plansSection
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("デートプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFavoritesOnly.toggle() } label: {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(AppColors.accentRose)
                    }
                }
            }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
                    .environmentObject(vm)
            }
        }
    }

    private var sceneFilter: some View {
        chipScroll {
            filterChip(label: "すべて", icon: "square.grid.2x2.fill", isSelected: vm.selectedScene == nil) { vm.selectedScene = nil }
            ForEach(DateScene.allCases, id: \.self) { scene in
                filterChip(label: scene.rawValue, icon: scene.icon, isSelected: vm.selectedScene == scene) {
                    vm.selectedScene = vm.selectedScene == scene ? nil : scene
                }
            }
        }
    }

    private var stageFilter: some View {
        chipScroll {
            filterChip(label: "ステージ", icon: "flag.fill", isSelected: vm.selectedStage == nil) { vm.selectedStage = nil }
            ForEach(DateStage.allCases, id: \.self) { stage in
                filterChip(label: stage.rawValue, icon: "heart", isSelected: vm.selectedStage == stage) {
                    vm.selectedStage = vm.selectedStage == stage ? nil : stage
                }
            }
        }
    }

    private func chipScroll<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) { content() }
                .padding(.horizontal, 20)
        }
    }

    private func filterChip(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(AppFonts.caption(12))
            .foregroundColor(isSelected ? .white : AppColors.textWarm)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(isSelected ? AppColors.accentRose : Color.white.opacity(0.75))
            .clipShape(Capsule())
        }
    }

    private var plansSection: some View {
        LazyVStack(spacing: 14) {
            let displayPlans = showFavoritesOnly ? vm.favoritePlans : vm.filteredPlans
            if displayPlans.isEmpty {
                EmptyStateView(icon: showFavoritesOnly ? "heart.slash" : "map", message: showFavoritesOnly ? "お気に入りのプランはまだありません。" : "条件に合うプランが見つかりません。")
            } else {
                ForEach(displayPlans) { plan in
                    planCard(plan)
                        .padding(.horizontal, 20)
                        .onTapGesture { selectedPlan = plan }
                }
            }
        }
    }

    private func planCard(_ plan: DatePlan) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    CategoryBadge(text: plan.scene.rawValue, color: AppColors.accentRose)
                    CategoryBadge(text: plan.stage.rawValue, color: Color(hex: plan.stage.color))
                    Spacer()
                    HeartButton(isFavorite: vm.isFavorite(plan: plan)) {
                        vm.toggleFavorite(plan: plan)
                    }
                }

                Text(plan.title)
                    .font(AppFonts.title(19))
                    .foregroundColor(AppColors.textDark)

                Text(plan.description)
                    .font(AppFonts.body(13))
                    .foregroundColor(AppColors.textWarm)
                    .lineLimit(3)

                HStack(spacing: 14) {
                    Label(plan.budget, systemImage: "yensign.circle.fill")
                    Label(plan.duration, systemImage: "clock.fill")
                }
                .font(AppFonts.caption(12))
                .foregroundColor(AppColors.accentGold)
            }
        }
    }
}
