import SwiftUI

struct MatchView: View {
    @EnvironmentObject var vm: MatchViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                if vm.showResult {
                    MatchResultView()
                        .environmentObject(vm)
                } else if vm.questions.isEmpty {
                    EmptyStateView(icon: "heart.circle", message: "診断を読み込み中です。")
                } else {
                    quizContent
                }
            }
            .navigationTitle("相性診断")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var quizContent: some View {
        VStack(spacing: 0) {
            progressSection
                .padding(.horizontal, 20)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 22) {
                    LoveHeroCard(
                        imageName: "love-match",
                        title: "心の距離を診断",
                        subtitle: "答え方から、恋愛で安心しやすい関わり方を見つけます",
                        height: 220
                    )
                    .padding(.horizontal, 20)

                    if let result = vm.result, !vm.showResult {
                        savedResultBanner(result)
                            .padding(.horizontal, 20)
                    }

                    if let question = vm.currentQuestion {
                        questionCard(question)
                            .padding(.horizontal, 20)
                    }

                    navigationButtons
                        .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("質問 \(vm.currentQuestionIndex + 1) / \(vm.questions.count)")
                    .font(AppFonts.caption(13))
                    .foregroundColor(AppColors.textWarm)
                Spacer()
                Text("\(Int(vm.progress * 100))%")
                    .font(AppFonts.caption(13))
                    .foregroundColor(AppColors.accentRose)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.accentRose.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [AppColors.accentRose, AppColors.accentLavender], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(vm.currentQuestionIndex + 1) / CGFloat(max(vm.questions.count, 1)))
                }
            }
            .frame(height: 8)
        }
    }

    private func savedResultBanner(_ result: MatchResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.attachmentType.emoji)
                .foregroundColor(AppColors.accentRose)
                .font(.system(size: 26, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("前回の診断結果")
                    .font(AppFonts.caption(12))
                    .foregroundColor(AppColors.textWarm)
                Text(result.attachmentType.rawValue)
                    .font(AppFonts.headline(15))
                    .foregroundColor(AppColors.accentRose)
            }
            Spacer()
            Button("結果を見る") { vm.showResult = true }
                .font(AppFonts.caption(13))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppColors.accentRose)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding(15)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func questionCard(_ question: MatchQuestion) -> some View {
        RoseCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(AppColors.accentRose)
                    Text("恋愛スタイル診断")
                        .font(AppFonts.caption(13))
                        .foregroundColor(AppColors.textWarm)
                }

                Text(question.question)
                    .font(AppFonts.headline(18))
                    .foregroundColor(AppColors.textDark)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { idx in
                        optionButton(text: question.options[idx].text, index: idx, isSelected: vm.selectedAnswers[vm.currentQuestionIndex] == idx)
                    }
                }
            }
        }
    }

    private func optionButton(text: String, index: Int, isSelected: Bool) -> some View {
        Button {
            vm.selectAnswer(optionIndex: index)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppColors.accentRose : AppColors.textWarm.opacity(0.4))
                Text(text)
                    .font(AppFonts.body(14))
                    .foregroundColor(isSelected ? AppColors.textDark : AppColors.textWarm)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(14)
            .background(isSelected ? AppColors.accentRose.opacity(0.1) : Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? AppColors.accentRose.opacity(0.45) : Color.clear, lineWidth: 1.4)
            )
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if vm.currentQuestionIndex > 0 {
                Button { vm.previousQuestion() } label: {
                    Label("戻る", systemImage: "chevron.left")
                }
                .font(AppFonts.headline(15))
                .foregroundColor(AppColors.accentRose)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Spacer()

            let hasAnswer = vm.selectedAnswers[vm.currentQuestionIndex] != nil
            Button {
                if vm.isLastQuestion {
                    vm.submitQuiz()
                } else {
                    vm.nextQuestion()
                }
            } label: {
                HStack {
                    Text(vm.isLastQuestion ? "結果を見る" : "次へ")
                    Image(systemName: vm.isLastQuestion ? "heart.fill" : "chevron.right")
                }
            }
            .font(AppFonts.headline(15))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .background(hasAnswer ? AppColors.accentRose : AppColors.textWarm.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(!hasAnswer)
        }
    }
}
