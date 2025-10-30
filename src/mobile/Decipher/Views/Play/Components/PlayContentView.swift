import SwiftUI
import UIKit

enum GameState {
    case playing
    case won
    case lost
}

struct PlayContentView: View {
    let topic: Topic
    @ObservedObject var viewModel: PlayViewModel
    @ObservedObject var settings = AppSettings.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentHintIndex = 1
    @State private var maxUnlockedHintIndex = 1
    @State private var guesses: [Int: String] = [:]
    @State private var failedAttempts: Set<Int> = []
    @State private var gameState: GameState = .playing
    @State private var isMovingForward = true
    @State private var startTime = Date()
    @State private var gameCompleted = false
    @State private var gameWon = false
    @State private var showResults = false
    @State private var gameResult: GameResult?
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 0) {
            if let hint = topic.hints.first(where: { $0.order == currentHintIndex }) {
                PlayHeaderView(
                    topicNumber: 1,
                    topicType: hint.type,
                    currentHintIndex: currentHintIndex,
                    failedAttempts: failedAttempts,
                    gameState: gameState
                )
                .animation(nil, value: currentHintIndex)
            }
            
            Spacer()
            
            if let hint = topic.hints.first(where: { $0.order == currentHintIndex }) {
                PlayHintView(hint: hint)
                    .transition(.asymmetric(
                        insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
                    ))
                    .id(hint.order)
            }
            
            Spacer()
            
            PlayInputField(
                text: Binding(
                    get: { guesses[currentHintIndex] ?? "" },
                    set: { guesses[currentHintIndex] = $0 }
                ),
                isFocused: $isInputFocused,
                isDisabled: gameCompleted || currentHintIndex < maxUnlockedHintIndex,
                onSubmit: handleSubmit
            )
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = false
        }
        .gesture(swipeGesture)
        .onAppear(perform: loadProgress)
        .onDisappear(perform: saveProgress)
        .overlay {
            if showResults, let result = gameResult {
                GameResultsView(isPresented: $showResults, result: result)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                isInputFocused = false
                
                if value.translation.width < -50 && currentHintIndex < maxUnlockedHintIndex {
                    if settings.hapticsEnabled {
                        impactFeedback.impactOccurred()
                    }
                    isMovingForward = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentHintIndex += 1
                    }
                } else if value.translation.width > 50 && currentHintIndex > 1 {
                    if settings.hapticsEnabled {
                        impactFeedback.impactOccurred()
                    }
                    isMovingForward = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentHintIndex -= 1
                    }
                }
            }
    }
    
    private func handleSubmit() {
        guard !gameCompleted, currentHintIndex <= 5, !(guesses[currentHintIndex] ?? "").isEmpty else { return }
        
        let currentGuess = guesses[currentHintIndex] ?? ""
        let isCorrect = currentGuess.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == topic.answer.lowercased()
        
        isInputFocused = false
        isMovingForward = true
        
        if isCorrect {
            // Win haptic - success notification
            if settings.hapticsEnabled {
                notificationFeedback.notificationOccurred(.success)
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                gameState = .won
                maxUnlockedHintIndex = 5
                gameCompleted = true
                gameWon = true
            }
            
            Task {
                let duration = Int(Date().timeIntervalSince(startTime))
                let allGuesses = (1...currentHintIndex).compactMap { guesses[$0] }
                
                try? await viewModel.submitGame(
                    topicId: topic.id,
                    attempts: currentHintIndex,
                    guesses: allGuesses,
                    duration: duration,
                    success: true
                )
                
                // Save result and show results sheet
                let result = GameResult(
                    topicId: topic.id,
                    attempts: currentHintIndex,
                    guesses: allGuesses,
                    duration: duration,
                    success: true,
                    answer: topic.answer,
                    completedAt: Date()
                )
                GameResultsManager.save(result)
                PlayProgressManager.clear()
                
                // Show results after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    gameResult = result
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showResults = true
                    }
                }
            }
        } else {
            // Different haptics for wrong guess vs losing
            if settings.hapticsEnabled {
                if currentHintIndex < 5 {
                    // Wrong guess haptic - light impact
                    impactFeedback.impactOccurred()
                } else {
                    // Lose haptic - error notification
                    notificationFeedback.notificationOccurred(.error)
                }
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                failedAttempts.insert(currentHintIndex)
                if currentHintIndex < 5 {
                    currentHintIndex += 1
                    maxUnlockedHintIndex = max(maxUnlockedHintIndex, currentHintIndex)
                } else {
                    gameState = .lost
                    gameCompleted = true
                    gameWon = false
                }
            }
            
            if currentHintIndex < 5 {
                saveProgress()
            } else {
                Task {
                    let duration = Int(Date().timeIntervalSince(startTime))
                    let allGuesses = (1...5).compactMap { guesses[$0] }
                    
                    try? await viewModel.submitGame(
                        topicId: topic.id,
                        attempts: 5,
                        guesses: allGuesses,
                        duration: duration,
                        success: false
                    )
                    
                    // Save result and show results sheet
                    let result = GameResult(
                        topicId: topic.id,
                        attempts: 5,
                        guesses: allGuesses,
                        duration: duration,
                        success: false,
                        answer: topic.answer,
                        completedAt: Date()
                    )
                    GameResultsManager.save(result)
                    PlayProgressManager.clear()
                    
                    // Show results after brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        gameResult = result
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showResults = true
                        }
                    }
                }
            }
        }
    }
    
    private func loadProgress() {
        // Check if game is already completed
        if let result = GameResultsManager.load(), result.topicId == topic.id {
            gameResult = result
            gameCompleted = true
            gameWon = result.success
            gameState = result.success ? .won : .lost
            currentHintIndex = result.attempts
            maxUnlockedHintIndex = 5
            
            // Reconstruct guesses from result
            for (index, guess) in result.guesses.enumerated() {
                guesses[index + 1] = guess
            }
            
            // Show results immediately if already completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showResults = true
                }
            }
            return
        }
        
        // Load progress if game is in progress
        guard let progress = PlayProgressManager.load(),
              progress.topicId == topic.id else {
            startTime = Date()
            return
        }
        
        currentHintIndex = progress.currentHintIndex
        maxUnlockedHintIndex = progress.maxUnlockedHintIndex
        guesses = progress.guesses
        failedAttempts = progress.failedAttempts
        startTime = progress.startTime
    }
    
    private func saveProgress() {
        guard !gameCompleted else { return }
        
        let progress = PlayProgress(
            topicId: topic.id,
            currentHintIndex: currentHintIndex,
            maxUnlockedHintIndex: maxUnlockedHintIndex,
            guesses: guesses,
            failedAttempts: failedAttempts,
            startTime: startTime
        )
        PlayProgressManager.save(progress)
    }
}
