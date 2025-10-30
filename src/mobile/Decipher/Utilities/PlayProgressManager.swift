import Foundation

struct PlayProgress: Codable {
    let topicId: String
    let currentHintIndex: Int
    let maxUnlockedHintIndex: Int
    let guesses: [Int: String]
    let failedAttempts: Set<Int>
    let startTime: Date
    
    var elapsedSeconds: Int {
        Int(Date().timeIntervalSince(startTime))
    }
}

class PlayProgressManager {
    private static let key = "playProgress"
    
    static func save(_ progress: PlayProgress) {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func load() -> PlayProgress? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let progress = try? JSONDecoder().decode(PlayProgress.self, from: data) else {
            return nil
        }
        return progress
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

