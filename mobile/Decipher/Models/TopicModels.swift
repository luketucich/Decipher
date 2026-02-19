import Foundation

struct Topic: Codable {
    let id: String
    let answer: String
    let date: String
    let type: String
    let aliases: [String]?
    let hints: [Hint]
    let topicNumber: Int
}

struct Hint: Codable {
    let id: String
    let content: String
    let type: String
    let order: Int
}

struct Submission: Codable {
    let id: String
    let topicId: String
    let attempts: Int
    let guesses: [String]
    let skips: Int?
    let duration: Int
    let success: Bool
    let createdAt: String
}

struct GuessCount: Codable, Identifiable {
    var id: String { guess }
    let guess: String
    let count: Int
}

struct GameStats: Codable {
    let totalSubmissions: Int
    let avgGuessTime: Int
    let fastestGuessTime: Int
    let avgSkips: Double
    let skipRate: Double
    let commonGuesses: [GuessCount]

    enum CodingKeys: String, CodingKey {
        case totalSubmissions
        case avgGuessTime
        case fastestGuessTime
        case avgSkips
        case skipRate
        case commonGuesses
    }

    init(
        totalSubmissions: Int,
        avgGuessTime: Int,
        fastestGuessTime: Int,
        avgSkips: Double,
        skipRate: Double,
        commonGuesses: [GuessCount]
    ) {
        self.totalSubmissions = totalSubmissions
        self.avgGuessTime = avgGuessTime
        self.fastestGuessTime = fastestGuessTime
        self.avgSkips = avgSkips
        self.skipRate = skipRate
        self.commonGuesses = commonGuesses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalSubmissions = try container.decodeIfPresent(Int.self, forKey: .totalSubmissions) ?? 0
        avgGuessTime = try container.decodeIfPresent(Int.self, forKey: .avgGuessTime) ?? 0
        fastestGuessTime = try container.decodeIfPresent(Int.self, forKey: .fastestGuessTime) ?? 0
        avgSkips = try container.decodeIfPresent(Double.self, forKey: .avgSkips) ?? 0
        skipRate = try container.decodeIfPresent(Double.self, forKey: .skipRate) ?? 0
        commonGuesses = try container.decodeIfPresent([GuessCount].self, forKey: .commonGuesses) ?? []
    }
}

struct ModerationResponse: Codable {
    let appropriate: Bool
    let message: String?
}
