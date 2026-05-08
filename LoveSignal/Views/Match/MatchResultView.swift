import SwiftUI

struct MatchResultView: View {
    @EnvironmentObject var vm: MatchViewModel
    @State private var selectedPartnerType: AttachmentType = .secure

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result = vm.result {
                    resultHeader(result)
                    scoreBreakdown(result)
                    typeDescription(result)
                    compatibilitySection
                }
                retryButton
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private func resultHeader(_ result: MatchResult) -> some View {
        RoseCard {
            VStack(spacing: 16) {
                Image("love-result")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Image(systemName: result.attachmentType.emoji)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(AppColors.accentRose)

                GradientTitle(text: result.attachmentType.rawValue, size: 26)
                Text("あなたの恋愛スタイルは \(result.attachmentType.rawValue) です。")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func scoreBreakdown(_ result: MatchResult) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(icon: "chart.bar.fill", text: "スコア詳細")
                let maxScore = max(result.scores.secure, result.scores.anxious, result.scores.avoidant, result.scores.disorganized, 1)
                ScoreBar(label: "安定型", value: result.scores.secure, maxValue: maxScore, color: Color(hex: "#4CAF90"))
                ScoreBar(label: "不安型", value: result.scores.anxious, maxValue: maxScore, color: AppColors.accentRose)
                ScoreBar(label: "回避型", value: result.scores.avoidant, maxValue: maxScore, color: AppColors.accentGold)
                ScoreBar(label: "混乱型", value: result.scores.disorganized, maxValue: maxScore, color: AppColors.accentLavender)
            }
        }
    }

    private func typeDescription(_ result: MatchResult) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(icon: "person.fill", text: "あなたの特徴")
                Text(result.attachmentType.description)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .lineSpacing(5)
                Divider()
                SectionTitle(icon: "heart.text.square.fill", text: "恋の傾向")
                Text(result.attachmentType.loveStyle)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .lineSpacing(5)
            }
        }
    }

    private var compatibilitySection: some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(icon: "heart.circle.fill", text: "相手タイプとの相性")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AttachmentType.allCases, id: \.self) { type in
                            Button { selectedPartnerType = type } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: type.emoji)
                                    Text(type.rawValue)
                                }
                                .font(AppFonts.caption(12))
                                .foregroundColor(selectedPartnerType == type ? .white : AppColors.textWarm)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(selectedPartnerType == type ? AppColors.accentRose : Color.white.opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                }

                if let myType = vm.result?.attachmentType {
                    let score = vm.compatibilityScore(type1: myType, type2: selectedPartnerType)
                    let comment = vm.compatibilityComment(type1: myType, type2: selectedPartnerType)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(myType.rawValue) × \(selectedPartnerType.rawValue)")
                                .font(AppFonts.headline(15))
                                .foregroundColor(AppColors.textDark)
                            Spacer()
                            Text("\(score)%")
                                .font(AppFonts.title(24))
                                .foregroundColor(AppColors.accentRose)
                        }
                        Text(comment)
                            .font(AppFonts.body(14))
                            .foregroundColor(AppColors.textWarm)
                            .lineSpacing(4)
                    }
                    .padding(14)
                    .background(AppColors.accentRose.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var retryButton: some View {
        Button { vm.resetQuiz() } label: {
            Label("もう一度診断する", systemImage: "arrow.clockwise")
                .font(AppFonts.headline(15))
                .foregroundColor(AppColors.accentRose)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct SectionTitle: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentRose)
            Text(text)
                .font(AppFonts.headline(16))
                .foregroundColor(AppColors.textDark)
        }
    }
}
