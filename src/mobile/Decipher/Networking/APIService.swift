//
//  APIService.swift
//  Decipher
//
//  Created by Luke on 10/29/25.
//

import Foundation

class APIService {
    
    private let baseURL = "http://localhost:3000"
    
    func fetchDailyTopic() async throws -> Topic {
        let url = URL(string: "\(baseURL)/play/daily")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        // If date is ISO, add this for auto-parsing (optional for now since date is String)
//         decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Topic.self, from: data)
    }
}
