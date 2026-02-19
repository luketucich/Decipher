import Foundation
import Combine

class PlayViewModel: ObservableObject {
    @Published var topic: Topic?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService()
    
    @MainActor
    func fetchDailyTopic() async {
        isLoading = true
        errorMessage = nil
        topic = nil
        
        do {
            topic = try await apiService.fetchDailyTopic()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func submitGame(
        topicId: String,
        attempts: Int,
        guesses: [String],
        skips: Int,
        duration: Int,
        success: Bool
    ) async throws {
        try await apiService.submitGame(
            topicId: topicId,
            attempts: attempts,
            guesses: guesses,
            skips: skips,
            duration: duration,
            success: success
        )
    }
    
    @MainActor
    func moderateGuess(_ guess: String) async throws -> (appropriate: Bool, message: String?) {
        let result = try await apiService.moderateGuess(guess)
        return (result.appropriate, result.message)
    }
}
