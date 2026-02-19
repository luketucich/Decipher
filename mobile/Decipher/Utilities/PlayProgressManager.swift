import Foundation

struct PlayProgress: Codable {
    let topicId: String
    let currentHintIndex: Int
    let maxUnlockedHintIndex: Int
    let guesses: [Int: String]
    let failedAttempts: Set<Int>
    let skippedHints: Set<Int>
    let startTime: Date
    let elapsedActiveTime: TimeInterval

    enum CodingKeys: String, CodingKey {
        case topicId
        case currentHintIndex
        case maxUnlockedHintIndex
        case guesses
        case failedAttempts
        case skippedHints
        case startTime
        case elapsedActiveTime
    }

    init(
        topicId: String,
        currentHintIndex: Int,
        maxUnlockedHintIndex: Int,
        guesses: [Int: String],
        failedAttempts: Set<Int>,
        skippedHints: Set<Int>,
        startTime: Date,
        elapsedActiveTime: TimeInterval
    ) {
        self.topicId = topicId
        self.currentHintIndex = currentHintIndex
        self.maxUnlockedHintIndex = maxUnlockedHintIndex
        self.guesses = guesses
        self.failedAttempts = failedAttempts
        self.skippedHints = skippedHints
        self.startTime = startTime
        self.elapsedActiveTime = elapsedActiveTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topicId = try container.decode(String.self, forKey: .topicId)
        currentHintIndex = try container.decodeIfPresent(Int.self, forKey: .currentHintIndex) ?? 1
        maxUnlockedHintIndex = try container.decodeIfPresent(Int.self, forKey: .maxUnlockedHintIndex) ?? 1
        guesses = try container.decodeIfPresent([Int: String].self, forKey: .guesses) ?? [:]
        failedAttempts = try container.decodeIfPresent(Set<Int>.self, forKey: .failedAttempts) ?? []
        skippedHints = try container.decodeIfPresent(Set<Int>.self, forKey: .skippedHints) ?? []
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime) ?? Date()
        elapsedActiveTime = try container.decodeIfPresent(TimeInterval.self, forKey: .elapsedActiveTime)
            ?? max(0, Date().timeIntervalSince(startTime))
    }
    
    var elapsedSeconds: Int {
        max(0, Int(elapsedActiveTime.rounded(.down)))
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
