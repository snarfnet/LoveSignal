import SwiftUI

struct TodayView: View {
    @EnvironmentObject var vm: TodayViewModel
    @State private var showFavorites = false
    @State private var showShareSheet = false
    @State private var shareText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        LoveHeroCard(
                            imageName: "love-hero",
                            title: "LoveSignal",
                            subtitle: "相手の気持ちと、自分の心をやさしく読み解く恋愛ガイド"
                        )
                        .padding(.horizontal, 20)

                        if let tip = vm.todayTip {
                            todayTipCard(tip)
                        }

                        quickGuide

                        tipsSection
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("今日のヒント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFavorites.toggle() } label: {
                        Image(systemName: showFavorites ? "heart.fill" : "heart")
                            .foregroundColor(AppColors.accentRose)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    private func todayTipCard(_ tip: Tip) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 16) {
                Image("love-today")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack {
                    CategoryBadge(text: tip.category.rawValue, color: Color(hex: tip.category.color))
                    Spacer()
                    Button {
                        shareText = vm.shareText(for: tip)
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.textWarm)
                    }
                    HeartButton(isFavorite: vm.isFavorite(tip: tip)) {
                        vm.toggleFavorite(tip: tip)
                    }
                }

                Text(tip.title)
                    .font(AppFonts.title(22))
                    .foregroundColor(AppColors.textDark)
                    .fixedSize(horizontal: false, vertical: true)

                Text(tip.body)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppColors.accentRose)
                    Text(tip.actionPoint)
                        .font(AppFonts.headline(14))
                        .foregroundColor(AppColors.textDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(AppColors.accentRose.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private var quickGuide: some View {
        HStack(spacing: 10) {
            MiniGuide(icon: "eye.fill", title: "見る", text: "表情")
            MiniGuide(icon: "bubble.left.and.bubble.right.fill", title: "聞く", text: "言葉")
            MiniGuide(icon: "heart.text.square.fill", title: "整える", text: "距離感")
        }
        .padding(.horizontal, 20)
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: showFavorites ? "お気に入り" : "ヒント一覧", icon: showFavorites ? "heart.fill" : "sparkles")

            let displayTips = showFavorites ? vm.favoriteTips : vm.tips
            if displayTips.isEmpty {
                EmptyStateView(icon: showFavorites ? "heart.slash" : "sparkles", message: showFavorites ? "お気に入りはまだありません。" : "ヒントを読み込み中です。")
            } else {
                ForEach(displayTips) { tip in
                    TipRowCard(tip: tip, isFavorite: vm.isFavorite(tip: tip)) {
                        vm.toggleFavorite(tip: tip)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct MiniGuide: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentRose)
            Text(title)
                .font(AppFonts.headline(13))
                .foregroundColor(AppColors.textDark)
            Text(text)
                .font(AppFonts.caption(11))
                .foregroundColor(AppColors.textWarm)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TipRowCard: View {
    let tip: Tip
    let isFavorite: Bool
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tip.category.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: tip.category.color))
                .frame(width: 42, height: 42)
                .background(Color(hex: tip.category.color).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(tip.title)
                    .font(AppFonts.headline(15))
                    .foregroundColor(AppColors.textDark)
                    .lineLimit(1)
                Text(tip.body)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.textWarm)
                    .lineLimit(2)
            }

            Spacer()
            HeartButton(isFavorite: isFavorite, action: onFavorite)
        }
        .padding(14)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AppColors.shadowColor, radius: 8, x: 0, y: 4)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
