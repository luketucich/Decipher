//
//  TopicModels.swift
//  Decipher
//
//  Created by Luke on 10/29/25.
//

import Foundation

struct Topic: Codable {
    let id: String
    let answer: String
    let date: String
    let type: String
    let hints: [Hint]
}

struct Hint: Codable {
    let id: String
    let content: String
    let type: String
    let order: Int
}

struct Submission: Codable {
    let id: String
    let topicId: String
    let attempts: Int
    let guesses: [String]
    let duration: Int
    let success: Bool
    let createdAt: String
}
