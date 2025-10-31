import Foundation

#if canImport(SwiftLevenshtein)
import SwiftLevenshtein
#elseif canImport(Levenshtein)
import Levenshtein
#endif

struct GuessMatcher {
    static func normalize(_ str: String) -> String {
        var s = str.lowercased()
        // Remove articles
        s = s.replacingOccurrences(of: "\\b(the|a|an)\\b", with: " ", options: .regularExpression)
        // Remove punctuation/symbols
        s = s.replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
        // Collapse whitespace
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isCorrectGuess(answer: String, guess: String) -> Bool {
        let normAnswer = normalize(answer)
        let normGuess = normalize(guess)

        if normAnswer == normGuess { return true }

        let maxLength = max(normAnswer.count, normGuess.count)
        let dist = editDistance(normAnswer, normGuess)
        let threshold = Int(ceil(Double(maxLength) * 0.45))
        return dist <= threshold
    }
}

private func editDistance(_ a: String, _ b: String) -> Int {
    #if canImport(SwiftLevenshtein)
    // Many SwiftLevenshtein packages expose a String extension like this:
    return a.levenshtein(b)
    #elseif canImport(Levenshtein)
    return Levenshtein.distance(a, b)
    #else
    // Fallback: pure Swift Levenshtein distance
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
                dp[i - 1][j] + 1,      // deletion
                dp[i][j - 1] + 1,      // insertion
                dp[i - 1][j - 1] + cost // substitution
            )
        }
    }
    return dp[n][m]
    #endif
}
