//
//  PlayViewModel.swift
//  Decipher
//
//  Created by Luke on 10/29/25.
//

import Foundation

@Observable class PlayViewModel {
    var topic: Topic?  // Fetched topic (optional until loaded)
    var isLoading: Bool = true
    var errorMessage: String?  // For errors
    
    var userGuess: String = ""  // Keep for input
    
    private let apiService = APIService()  // Our networking service
    
    init() {
        Task {  // Async init
            await loadDailyTopic()
        }
    }
    
    func loadDailyTopic() async {
        do {
            topic = try await apiService.fetchDailyTopic()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // Later: Add guess checker here
}
