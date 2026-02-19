import Foundation
import Supabase

struct APIError: LocalizedError, Codable {
    let statusCode: Int
    let message: String

    var errorDescription: String? { message }
}

class APIService {
    private let decoder = JSONDecoder()

    private struct DailyTopicRequest: Encodable {
        let date: String
    }

    private struct SubmitGameRequest: Encodable {
        let topicId: String
        let attempts: Int
        let guesses: [String]
        let skips: Int
        let duration: Int
        let success: Bool
    }

    private struct TopicStatsRequest: Encodable {
        let topicId: String
    }

    private struct EdgeErrorResponse: Decodable {
        let error: String
    }

    private func makePOSIXDateString(for date: Date, useLocalTime: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = useLocalTime ? .current : TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func mapFunctionError(_ error: Error, fallbackMessage: String) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        if let functionError = error as? FunctionsError {
            switch functionError {
            case .httpError(let statusCode, let data):
                if let parsed = try? decoder.decode(EdgeErrorResponse.self, from: data),
                   !parsed.error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return APIError(statusCode: statusCode, message: parsed.error)
                }
                return APIError(
                    statusCode: statusCode,
                    message: "Unexpected server response (\(statusCode))."
                )

            case .relayError:
                return APIError(statusCode: -1, message: fallbackMessage)

            @unknown default:
                return APIError(statusCode: -1, message: fallbackMessage)
            }
        }

        if let urlError = error as? URLError {
            return APIError(statusCode: urlError.errorCode, message: urlError.localizedDescription)
        }

        return APIError(statusCode: -1, message: fallbackMessage)
    }

    func fetchDailyTopic() async throws -> Topic {
        let localDate = makePOSIXDateString(for: Date(), useLocalTime: true)
        let request = DailyTopicRequest(date: localDate)

        var lastError: APIError?

        for attempt in 1...3 {
            do {
                let topic: Topic = try await SupabaseService.client.functions.invoke(
                    "daily-topic",
                    options: .init(body: request)
                )
                return topic
            } catch {
                let mappedError = mapFunctionError(
                    error,
                    fallbackMessage: "Unable to load today's topic. Please try again."
                )
                lastError = mappedError

                if mappedError.statusCode > 0 && mappedError.statusCode < 500 {
                    break
                }

                if attempt < 3 {
                    try? await Task.sleep(
                        nanoseconds: UInt64(0.4 * pow(2.0, Double(attempt - 1)) * 1_000_000_000)
                    )
                }
            }
        }

        throw lastError ?? APIError(
            statusCode: -1,
            message: "Unable to load today's topic. Please try again."
        )
    }

    func submitGame(
        topicId: String,
        attempts: Int,
        guesses: [String],
        skips: Int,
        duration: Int,
        success: Bool
    ) async throws {
        let request = SubmitGameRequest(
            topicId: topicId,
            attempts: attempts,
            guesses: guesses,
            skips: skips,
            duration: duration,
            success: success
        )

        do {
            let _: Submission = try await SupabaseService.client.functions.invoke(
                "submit-game",
                options: .init(body: request)
            )
        } catch {
            throw mapFunctionError(error, fallbackMessage: "Failed to submit game.")
        }
    }

    func fetchGameStats(topicId: String) async throws -> GameStats {
        let request = TopicStatsRequest(topicId: topicId)

        do {
            let stats: GameStats = try await SupabaseService.client.functions.invoke(
                "topic-stats",
                options: .init(body: request)
            )
            return stats
        } catch {
            throw mapFunctionError(error, fallbackMessage: "Unable to load game stats.")
        }
    }

    func moderateGuess(_ guess: String) async throws -> ModerationResponse {
        GuessModeration.moderate(guess)
    }
}
