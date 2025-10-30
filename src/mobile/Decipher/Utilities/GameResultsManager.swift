import Foundation

struct GameResult: Codable {
    let topicId: String
    let attempts: Int
    let guesses: [String]
    let duration: Int
    let success: Bool
    let answer: String
    let completedAt: Date
}

class GameResultsManager {
    private static let key = "gameResult"
    
    static func save(_ result: GameResult) {
        if let encoded = try? JSONEncoder().encode(result) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> GameResult? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let result = try? JSONDecoder().decode(GameResult.self, from: data) else {
            return nil
        }
        return result
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static func hasCompletedToday(topicId: String) -> Bool {
        guard let result = load() else { return false }
        return result.topicId == topicId
    }
}
