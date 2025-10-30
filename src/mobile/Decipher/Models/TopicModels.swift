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
