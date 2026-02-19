import Foundation

struct GuessModeration {
    private static let profanity: Set<String> = [
        "ass", "asshole", "bastard", "bitch", "bullshit", "cock", "cunt",
        "damn", "dick", "douche", "fag", "faggot", "fuck", "fucking",
        "motherfucker", "nigger", "nigga", "piss", "porn", "pussy",
        "shit", "slut", "twat", "whore"
    ]

    private static let allowedCharacters: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.formUnion(.whitespacesAndNewlines)
        set.formUnion(CharacterSet(charactersIn: ".,!?\"'’:-;()&/"))
        return set
    }()

    static func moderate(_ guess: String) -> ModerationResponse {
        let trimmed = guess.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return ModerationResponse(appropriate: true, message: nil)
        }

        if !matchesAllowedCharacters(trimmed) {
            return ModerationResponse(
                appropriate: false,
                message: "Please use only letters, numbers, and basic punctuation."
            )
        }

        if containsProfanity(trimmed) {
            return ModerationResponse(
                appropriate: false,
                message: "Please keep your guesses appropriate and avoid offensive content."
            )
        }

        return ModerationResponse(appropriate: true, message: nil)
    }

    private static func matchesAllowedCharacters(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if !allowedCharacters.contains(scalar) {
                return false
            }
        }
        return true
    }

    private static func containsProfanity(_ text: String) -> Bool {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty {
            return false
        }

        let tokens = normalized.split(separator: " ").map(String.init)
        for token in tokens {
            if profanity.contains(token) {
                return true
            }
        }

        return false
    }
}
