import Foundation

class APIService {
    
    private let baseURL = "http://localhost:3000"
    
    func fetchDailyTopic() async throws -> Topic {
        let url = URL(string: "\(baseURL)/play/daily")!
        
        print("🔍 Fetching from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Print the raw response
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
        }
        
        // Print raw JSON for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw JSON Response:")
            print(jsonString)
        }
        
        let decoder = JSONDecoder()
        let topic = try decoder.decode(Topic.self, from: data)
        
        print("✅ Successfully decoded topic: \(topic.answer)")
        
        return topic
    }
}
