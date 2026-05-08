import Foundation

struct MatchQuestion: Identifiable, Codable {
    let id: Int
    let question: String
    let options: [MatchOption]
}

struct MatchOption: Codable {
    let text: String
    let scores: AttachmentScores
}

struct AttachmentScores: Codable {
    let secure: Int
    let anxious: Int
    let avoidant: Int
    let disorganized: Int
}

enum AttachmentType: String, Codable, CaseIterable {
    case secure = "安定型"
    case anxious = "不安型"
    case avoidant = "回避型"
    case disorganized = "混乱型"

    var emoji: String {
        switch self {
        case .secure: return "heart.fill"
        case .anxious: return "waveform.path.ecg"
        case .avoidant: return "moon.fill"
        case .disorganized: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .secure:
            return "安心感と自立のバランスを取りやすいタイプです。相手を信じながら、自分の気持ちも落ち着いて伝えられます。"
        case .anxious:
            return "相手との距離が少し空くと不安になりやすいタイプです。安心できる言葉や確認があると、本来の優しさを出しやすくなります。"
        case .avoidant:
            return "自分の時間やペースを大切にするタイプです。急に距離を縮めるより、信頼を積み重ねる関係が向いています。"
        case .disorganized:
            return "近づきたい気持ちと怖さが混ざりやすいタイプです。安全に話せる関係の中で、少しずつ気持ちを整理できます。"
        }
    }

    var loveStyle: String {
        switch self {
        case .secure:
            return "会話で誤解をほどきながら、穏やかに関係を育てるのが得意です。"
        case .anxious:
            return "愛情表現を大切にします。連絡頻度や安心できる言葉を共有すると関係が安定します。"
        case .avoidant:
            return "一人の時間を尊重されると安心します。無理に踏み込まず、自然なペースを守ると深まります。"
        case .disorganized:
            return "感情が揺れたときほど、急いで決めずに言葉にする時間が大切です。"
        }
    }
}

struct AttachmentCompatibility: Codable {
    let type1: AttachmentType
    let type2: AttachmentType
    let score: Int
    let comment: String
}

struct MatchResult: Codable {
    let attachmentType: AttachmentType
    let scores: AttachmentScores
    let date: Date
}
