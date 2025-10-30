import Foundation
import Combine

class PlayViewModel: ObservableObject {
    @Published var topic: Topic?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var userGuess: String = ""
    @Published var currentHintIndex: Int = 1
    @Published var topicNumber: Int = 1
    
    private let apiService = APIService()
    
    
    @MainActor
    func fetchDailyTopic() async {
        print("🚀 Starting fetch...")
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await apiService.fetchDailyTopic()
            topic = fetched
            topicNumber = 1
            isLoading = false
            print("✅ Fetch complete! Topic: \(fetched.answer)")
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            isLoading = false
            print("❌ Fetch failed: \(errorMsg)")
            print("❌ Full error: \(error)")
        }
    }
}
