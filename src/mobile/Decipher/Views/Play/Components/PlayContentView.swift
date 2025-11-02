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
    @Environment(\.dismiss) private var dismiss
    
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
    @State private var isCheckingModeration = false
    @State private var showModerationError = false
    @State private var moderationErrorMessage = ""
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button and progress bar aligned horizontally
            HStack(spacing: 0) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .padding(12)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                PlayHeaderView(
                    topicNumber: 1,
                    currentHintIndex: currentHintIndex,
                    failedAttempts: failedAttempts,
                    gameState: gameState
                )
                .animation(nil, value: currentHintIndex)
                
                Spacer()
                
                // Invisible placeholder to balance the layout
                Color.clear
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 8)
            }
            .padding(.top, 8)
            
            Spacer()
            
            if let hint = topic.hints.first(where: { $0.order == currentHintIndex }) {
                PlayHintView(hint: hint, topicType: hint.type)
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
                isDisabled: gameCompleted || currentHintIndex < maxUnlockedHintIndex || isCheckingModeration,
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
        .overlay {
            if showModerationError {
                VStack {
                    Spacer()
                    
                    Text(moderationErrorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.9))
                        )
                        .padding(.horizontal, 32)
                        .padding(.bottom, 120)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(2)
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
        
        // Check content moderation before processing guess
        isCheckingModeration = true
        Task {
            do {
                let isAppropriate = try await viewModel.moderateGuess(currentGuess)
                
                await MainActor.run {
                    isCheckingModeration = false
                    
                    if !isAppropriate {
                        // Show error and clear the inappropriate guess
                        if settings.hapticsEnabled {
                            notificationFeedback.notificationOccurred(.error)
                        }
                        moderationErrorMessage = "Please keep your guesses appropriate and avoid offensive language."
                        showModerationError = true
                        guesses[currentHintIndex] = ""
                        
                        // Hide error after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showModerationError = false
                        }
                        return
                    }
                    
                    // If appropriate, process the guess
                    processGuess(currentGuess)
                }
            } catch {
                // If moderation check fails, allow the guess through
                await MainActor.run {
                    isCheckingModeration = false
                    processGuess(currentGuess)
                }
            }
        }
    }
    
    private func processGuess(_ currentGuess: String) {
        let isCorrect = GuessMatcher.isCorrectGuess(answer: topic.answer, guess: currentGuess)
        
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
                    completedAt: Date(),
                    topicNumber: topic.topicNumber
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
            
            if currentHintIndex <= 5 && !gameCompleted {
                saveProgress()
            } else if gameCompleted {
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
                        completedAt: Date(),
                        topicNumber: topic.topicNumber
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
