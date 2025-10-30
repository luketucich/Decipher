//
//  ContentView.swift
//  Decipher
//
//  Created by Luke on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PlayViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.isLoading {
                Text("Loading...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
            } else if let topic = viewModel.topic {
                Text("Daily Decipher #1")  // Placeholder; calculate later
                Text(topic.type)
                
                if let firstHint = topic.hints.first(where: { $0.order == 1 }) {
                    Text("[Hint #1 Here] \(firstHint.content)")
                }
                
                TextField("(input answer)", text: $viewModel.userGuess)
                
                Button("Submit") {
                    print("Guess: \(viewModel.userGuess)")
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
