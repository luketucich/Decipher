//
//  ContentView.swift
//  Decipher
//
//  Created by Luke on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    // Hardcoded data for testing (change later)
    let topicNumber = 1
    let topicType = "Historical Figure"
    let hint1 = "Famous Scientist"
    
    // For the input field
    @State private var userGuess: String = ""
    
    var body: some View {
        VStack {
            Text("Daily Decipher #\(topicNumber)")
                .padding(10)
            Text(topicType)
                .padding(10)
            Text("[Hint #1 Here")
                .padding(10)
            TextField("(input answer)", text: $userGuess)
                .padding(10)
        }
    }
}

#Preview {
    ContentView()
}
