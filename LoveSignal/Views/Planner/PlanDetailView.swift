import SwiftUI

struct PlanDetailView: View {
    let plan: DatePlan
    @EnvironmentObject var vm: PlannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        LoveHeroCard(imageName: "love-planner", title: plan.title, subtitle: plan.location, height: 220)
                        infoRow
                        detailCard(icon: "text.alignleft", title: "プラン詳細", color: AppColors.accentRose, text: plan.description)
                        detailCard(icon: "lightbulb.fill", title: "成功のポイント", color: AppColors.accentGold, text: plan.keyPoint)
                        detailCard(icon: "exclamationmark.triangle.fill", title: "注意点", color: AppColors.accentCoral, text: plan.caution)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(AppColors.accentRose)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HeartButton(isFavorite: vm.isFavorite(plan: plan)) {
                        vm.toggleFavorite(plan: plan)
                    }
                }
            }
        }
    }

    private var infoRow: some View {
        HStack(spacing: 12) {
            infoCard(icon: "yensign.circle.fill", label: "予算", value: plan.budget, color: AppColors.accentGold)
            infoCard(icon: "clock.fill", label: "所要時間", value: plan.duration, color: AppColors.accentRose)
        }
    }

    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption(11))
                .foregroundColor(AppColors.textWarm)
            Text(value)
                .font(AppFonts.headline(13))
                .foregroundColor(AppColors.textDark)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func detailCard(icon: String, title: String, color: Color, text: String) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(AppFonts.headline(16))
                        .foregroundColor(AppColors.textDark)
                }
                Text(text)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
