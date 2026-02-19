import Foundation

#if canImport(SwiftLevenshtein)
import SwiftLevenshtein
#elseif canImport(Levenshtein)
import Levenshtein
#endif

struct GuessMatcher {
    nonisolated static func normalize(_ str: String) -> String {
        var value = str.lowercased()
        value = value.replacingOccurrences(of: "\\b(the|a|an)\\b", with: " ", options: .regularExpression)
        value = value.replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func isCorrectGuess(
        answer: String,
        guess: String,
        topicType: String,
        aliases: [String] = []
    ) -> Bool {
        let normalizedAnswer = normalize(answer)
        let normalizedGuess = normalize(guess)

        if normalizedGuess.isEmpty {
            return false
        }

        let normalizedAliases = aliases
            .map(normalize)
            .filter { !$0.isEmpty }

        let fullNameCandidates = [normalizedAnswer] + normalizedAliases

        if fullNameCandidates.contains(normalizedGuess) {
            return true
        }

        let isPersonTopic = personTopicTypes.contains(topicType.lowercased())
        if isPersonTopic {
            let lastNameCandidates = fullNameCandidates
                .compactMap { $0.split(separator: " ").last.map(String.init) }

            if lastNameCandidates.contains(normalizedGuess) {
                return true
            }

            if normalizedGuess.split(separator: " ").count == 1 {
                return lastNameCandidates.contains {
                    isFuzzyMatch(answer: $0, guess: normalizedGuess)
                }
            }
        }

        return fullNameCandidates.contains {
            isFuzzyMatch(answer: $0, guess: normalizedGuess)
        }
    }

    nonisolated private static let personTopicTypes: Set<String> = [
        "historical figure",
        "public figure"
    ]

    nonisolated private static func isFuzzyMatch(answer: String, guess: String) -> Bool {
        if answer == guess {
            return true
        }

        let maxLength = max(answer.count, guess.count)
        if maxLength == 0 {
            return false
        }

        let dist = editDistance(answer, guess)
        let threshold = fuzzyThreshold(for: maxLength)
        return dist <= threshold
    }

    nonisolated private static func editDistance(_ a: String, _ b: String) -> Int {
        #if canImport(SwiftLevenshtein)
        return a.levenshtein(b)
        #elseif canImport(Levenshtein)
        return Levenshtein.distance(a, b)
        #else
        let aChars = Array(a)
        let bChars = Array(b)
        let n = aChars.count
        let m = bChars.count
        if n == 0 { return m }
        if m == 0 { return n }

        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                let cost = (aChars[i - 1] == bChars[j - 1]) ? 0 : 1
                dp[i][j] = min(
                    dp[i - 1][j] + 1,
                    dp[i][j - 1] + 1,
                    dp[i - 1][j - 1] + cost
                )
            }
        }

        return dp[n][m]
        #endif
    }

    nonisolated private static func fuzzyThreshold(for maxLength: Int) -> Int {
        if maxLength <= 4 {
            return 0
        }
        if maxLength <= 8 {
            return 1
        }
        return Int(ceil(Double(maxLength) * 0.28))
    }
}
