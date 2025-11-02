import Foundation

struct Topic: Codable {
    let id: String
    let answer: String
    let date: String
    let type: String
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
    let commonGuesses: [GuessCount]
}

struct ModerationResponse: Codable {
    let appropriate: Bool
    let message: String?
}
