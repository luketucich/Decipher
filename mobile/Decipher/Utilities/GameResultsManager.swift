import Foundation

struct GameResult: Codable {
    let topicId: String
    let attempts: Int
    let guesses: [String]
    let guessesByHint: [Int: String]
    let failedHints: [Int]
    let skippedHints: [Int]
    let skips: Int
    let duration: Int
    let success: Bool
    let answer: String
    let completedAt: Date
    let topicNumber: Int
    let streak: Int

    enum CodingKeys: String, CodingKey {
        case topicId
        case attempts
        case guesses
        case guessesByHint
        case failedHints
        case skippedHints
        case skips
        case duration
        case success
        case answer
        case completedAt
        case topicNumber
        case streak
    }

    init(
        topicId: String,
        attempts: Int,
        guesses: [String],
        guessesByHint: [Int: String],
        failedHints: [Int],
        skippedHints: [Int],
        skips: Int,
        duration: Int,
        success: Bool,
        answer: String,
        completedAt: Date,
        topicNumber: Int,
        streak: Int
    ) {
        self.topicId = topicId
        self.attempts = attempts
        self.guesses = guesses
        self.guessesByHint = guessesByHint
        self.failedHints = failedHints
        self.skippedHints = skippedHints
        self.skips = skips
        self.duration = duration
        self.success = success
        self.answer = answer
        self.completedAt = completedAt
        self.topicNumber = topicNumber
        self.streak = streak
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topicId = try container.decode(String.self, forKey: .topicId)
        attempts = try container.decode(Int.self, forKey: .attempts)
        guesses = try container.decodeIfPresent([String].self, forKey: .guesses) ?? []
        guessesByHint = try container.decodeIfPresent([Int: String].self, forKey: .guessesByHint) ?? [:]
        failedHints = try container.decodeIfPresent([Int].self, forKey: .failedHints) ?? []
        skippedHints = try container.decodeIfPresent([Int].self, forKey: .skippedHints) ?? []
        skips = try container.decodeIfPresent(Int.self, forKey: .skips) ?? skippedHints.count
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? false
        answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? ""
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? Date()
        topicNumber = try container.decodeIfPresent(Int.self, forKey: .topicNumber) ?? 1
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    }
}

struct PlayerStats {
    let totalGames: Int
    let wins: Int
    let winRate: Double
    let bestAttempts: Int
    let bestTime: Int
    let currentStreak: Int
}

class GameResultsManager {
    private static let historyKey = "gameResultsHistory"
    private static let legacySingleKey = "gameResult"

    static func save(_ result: GameResult) {
        var history = loadHistory()

        if let existingIndex = history.firstIndex(where: { $0.topicId == result.topicId }) {
            history[existingIndex] = result
        } else {
            history.append(result)
        }

        history.sort {
            if $0.topicNumber == $1.topicNumber {
                return $0.completedAt < $1.completedAt
            }
            return $0.topicNumber < $1.topicNumber
        }

        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    static func load(topicId: String? = nil) -> GameResult? {
        let history = loadHistory()

        if let topicId {
            return history.last(where: { $0.topicId == topicId })
        }

        return history.last
    }

    static func loadHistory() -> [GameResult] {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let results = try? JSONDecoder().decode([GameResult].self, from: data) {
            return results
        }

        if let legacyData = UserDefaults.standard.data(forKey: legacySingleKey),
           let legacyResult = try? JSONDecoder().decode(GameResult.self, from: legacyData) {
            let migrated = [legacyResult]
            if let encoded = try? JSONEncoder().encode(migrated) {
                UserDefaults.standard.set(encoded, forKey: historyKey)
                UserDefaults.standard.removeObject(forKey: legacySingleKey)
            }
            return migrated
        }

        return []
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: historyKey)
        UserDefaults.standard.removeObject(forKey: legacySingleKey)
    }

    static func hasCompletedToday(topicId: String) -> Bool {
        load(topicId: topicId) != nil
    }

    static func currentWinStreak() -> Int {
        let history = loadHistory().sorted { lhs, rhs in
            if lhs.topicNumber == rhs.topicNumber {
                return lhs.completedAt < rhs.completedAt
            }
            return lhs.topicNumber < rhs.topicNumber
        }

        guard let latestTopicNumber = history.map(\.topicNumber).max() else {
            return 0
        }

        let latestByTopicNumber = history.reduce(into: [Int: Bool]()) { partialResult, result in
            partialResult[result.topicNumber] = result.success
        }

        guard latestByTopicNumber[latestTopicNumber] == true else {
            return 0
        }

        var cursor = latestTopicNumber
        var streak = 0
        while latestByTopicNumber[cursor] == true {
            streak += 1
            cursor -= 1
        }

        return streak
    }

    static func playerStats() -> PlayerStats {
        let history = loadHistory()
        let wins = history.filter(\.success)
        let bestAttempts = wins.map(\.attempts).min() ?? 0
        let bestTime = wins.map(\.duration).min() ?? 0
        let winRate = history.isEmpty ? 0 : (Double(wins.count) / Double(history.count))

        return PlayerStats(
            totalGames: history.count,
            wins: wins.count,
            winRate: winRate,
            bestAttempts: bestAttempts,
            bestTime: bestTime,
            currentStreak: currentWinStreak()
        )
    }
}
