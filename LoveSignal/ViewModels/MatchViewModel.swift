import Foundation
import SwiftUI

class MatchViewModel: ObservableObject {
    @Published var questions: [MatchQuestion] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswers: [Int: Int] = [:]
    @Published var result: MatchResult? = nil
    @Published var showResult: Bool = false

    private var scores = AttachmentScores(secure: 0, anxious: 0, avoidant: 0, disorganized: 0)

    init() {
        questions = Bundle.main.decode([MatchQuestion].self, from: "match_questions.json")
        loadSavedResult()
    }

    var currentQuestion: MatchQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }

    func selectAnswer(optionIndex: Int) {
        selectedAnswers[currentQuestionIndex] = optionIndex
    }

    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    func submitQuiz() {
        var secure = 0, anxious = 0, avoidant = 0, disorganized = 0
        for (qIndex, aIndex) in selectedAnswers {
            guard qIndex < questions.count else { continue }
            let question = questions[qIndex]
            guard aIndex < question.options.count else { continue }
            let s = question.options[aIndex].scores
            secure += s.secure
            anxious += s.anxious
            avoidant += s.avoidant
            disorganized += s.disorganized
        }
        scores = AttachmentScores(secure: secure, anxious: anxious, avoidant: avoidant, disorganized: disorganized)
        let attachmentType = determineType(secure: secure, anxious: anxious, avoidant: avoidant, disorganized: disorganized)
        result = MatchResult(attachmentType: attachmentType, scores: scores, date: Date())
        saveResult()
        showResult = true
    }

    private func determineType(secure: Int, anxious: Int, avoidant: Int, disorganized: Int) -> AttachmentType {
        let max = [secure, anxious, avoidant, disorganized].max() ?? 0
        if secure == max { return .secure }
        if anxious == max { return .anxious }
        if avoidant == max { return .avoidant }
        return .disorganized
    }

    func resetQuiz() {
        currentQuestionIndex = 0
        selectedAnswers = [:]
        showResult = false
    }

    func compatibilityScore(type1: AttachmentType, type2: AttachmentType) -> Int {
        switch (type1, type2) {
        case (.secure, .secure): return 95
        case (.secure, .anxious), (.anxious, .secure): return 80
        case (.secure, .avoidant), (.avoidant, .secure): return 75
        case (.secure, .disorganized), (.disorganized, .secure): return 70
        case (.anxious, .anxious): return 55
        case (.anxious, .avoidant), (.avoidant, .anxious): return 50
        case (.anxious, .disorganized), (.disorganized, .anxious): return 60
        case (.avoidant, .avoidant): return 65
        case (.avoidant, .disorganized), (.disorganized, .avoidant): return 58
        case (.disorganized, .disorganized): return 45
        default: return 60
        }
    }

    func compatibilityComment(type1: AttachmentType, type2: AttachmentType) -> String {
        switch (type1, type2) {
        case (.secure, .secure):
            return "最高の組み合わせ！お互いに信頼し合い、安心できる深い絆を育てられます。"
        case (.secure, .anxious), (.anxious, .secure):
            return "安定型のサポートが不安型に安心感を与え、バランスの取れた関係になりやすいです。"
        case (.secure, .avoidant), (.avoidant, .secure):
            return "安定型の忍耐と回避型の成長意欲があれば、深い信頼関係を築けます。"
        case (.anxious, .anxious):
            return "お互いの不安が増幅しやすいため、コミュニケーションの工夫が大切です。"
        case (.anxious, .avoidant), (.avoidant, .anxious):
            return "追いかける・逃げるパターンになりがち。お互いのニーズを言語化する練習が鍵。"
        case (.avoidant, .avoidant):
            return "自立心が強い同士。深い絆を築くには、意識的に感情を共有する機会を作りましょう。"
        default:
            return "どんな組み合わせも、お互いを理解し尊重する気持ちで素敵な関係になれます。"
        }
    }

    private func saveResult() {
        if let result = result,
           let data = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.matchResult)
        }
    }

    private func loadSavedResult() {
        if let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.matchResult),
           let saved = try? JSONDecoder().decode(MatchResult.self, from: data) {
            result = saved
        }
    }
}
