import Foundation

class APIService {
    private var baseURL = "https://decipher-wdx2.onrender.com"
    
    func fetchDailyTopic() async throws -> Topic {
        // Get client's local date in YYYY-MM-DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let localDate = formatter.string(from: Date())
        
        let url = URL(string: "\(baseURL)/play/daily?date=\(localDate)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(Topic.self, from: data)
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
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
