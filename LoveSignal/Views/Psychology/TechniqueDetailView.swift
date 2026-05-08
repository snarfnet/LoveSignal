import SwiftUI

struct TechniqueDetailView: View {
    let technique: PsychologyTechnique
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        LoveHeroCard(imageName: "love-psychology", title: technique.name, subtitle: technique.keyword, height: 210)
                        detailSection(icon: "text.alignleft", title: "概要", content: technique.summary)
                        detailSection(icon: "graduationcap.fill", title: "心理学的な根拠", content: technique.scientificBasis)
                        detailSection(icon: "lightbulb.fill", title: "実践のコツ", content: technique.practicalTip, tint: AppColors.accentGold)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(technique.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(AppColors.accentRose)
                }
            }
        }
    }

    private func detailSection(icon: String, title: String, content: String, tint: Color = AppColors.accentRose) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(tint)
                    Text(title)
                        .font(AppFonts.headline(16))
                        .foregroundColor(AppColors.textDark)
                }
                Text(content)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
