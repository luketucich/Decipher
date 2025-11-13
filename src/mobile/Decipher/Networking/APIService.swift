import Foundation

struct APIError: LocalizedError, Codable {
    let statusCode: Int
    let message: String
    var errorDescription: String? { message }
}

class APIService {
    private var baseURL = "https://decipher-wdx2.onrender.com"
    private let decoder = JSONDecoder()
    
    private func makePOSIXDateString(for date: Date, useLocalTime: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = useLocalTime ? .current : TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func fetchDailyTopic() async throws -> Topic {
        // Use client's local calendar day but ensure ASCII digits/consistent format
        let localDate = makePOSIXDateString(for: Date(), useLocalTime: true)
        
        let url = URL(string: "\(baseURL)/play/daily?date=\(localDate)")!
        var lastError: Error?
        
        // Retry up to 3 times for transient failures (5xx, network hiccups)
        for attempt in 1...3 {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    return try decoder.decode(Topic.self, from: data)
                } else if let httpResponse = response as? HTTPURLResponse {
                    // Try to surface server error message { error: "..." }
                    if let serverErr = try? decoder.decode([String: String].self, from: data),
                       let message = serverErr["error"] {
                        throw APIError(statusCode: httpResponse.statusCode, message: message)
                    }
                    throw APIError(statusCode: httpResponse.statusCode, message: "Unexpected server response (\(httpResponse.statusCode)).")
                } else {
                    throw URLError(.badServerResponse)
                }
            } catch {
                lastError = error
                // Only retry on transient errors or 5xx
                if let apiErr = error as? APIError, apiErr.statusCode < 500 {
                    break
                }
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: UInt64(0.4 * pow(2.0, Double(attempt - 1)) * 1_000_000_000))
                    continue
                }
            }
        }
        // Propagate last error with a friendly fallback
        if let apiErr = lastError as? APIError { throw apiErr }
        if let urlErr = lastError as? URLError { throw urlErr }
        throw APIError(statusCode: -1, message: "Unable to load today’s topic. Please try again.")
    }
    
    func submitGame(topicId: String, attempts: Int, guesses: [String], duration: Int, success: Bool) async throws {
        let url = URL(string: "\(baseURL)/play/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "topicId": topicId,
            "attempts": attempts,
            "guesses": guesses,
            "duration": duration,
            "success": success
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse,
               let serverErr = try? decoder.decode([String: String].self, from: data),
               let message = serverErr["error"] {
                throw APIError(statusCode: httpResponse.statusCode, message: message)
            }
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchGameStats(topicId: String) async throws -> GameStats {
        let url = URL(string: "\(baseURL)/play/stats/\(topicId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse,
               let serverErr = try? decoder.decode([String: String].self, from: data),
               let message = serverErr["error"] {
                throw APIError(statusCode: httpResponse.statusCode, message: message)
            }
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(GameStats.self, from: data)
    }
    
    func moderateGuess(_ guess: String) async throws -> ModerationResponse {
        let url = URL(string: "\(baseURL)/play/moderate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["guess": guess]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse,
               let serverErr = try? decoder.decode([String: String].self, from: data),
               let message = serverErr["error"] {
                throw APIError(statusCode: httpResponse.statusCode, message: message)
            }
            throw URLError(.badServerResponse)
        }
        
        return try decoder.decode(ModerationResponse.self, from: data)
    }
}
