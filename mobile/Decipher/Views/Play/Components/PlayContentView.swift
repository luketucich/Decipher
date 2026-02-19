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
    let onClose: (() -> Void)?
    @ObservedObject var settings = AppSettings.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentHintIndex = 1
    @State private var maxUnlockedHintIndex = 1
    @State private var guesses: [Int: String] = [:]
    @State private var failedAttempts: Set<Int> = []
    @State private var skippedHints: Set<Int> = []
    @State private var gameState: GameState = .playing
    @State private var isMovingForward = true
    @State private var startTime = Date()
    @State private var elapsedActiveTime: TimeInterval = 0
    @State private var activeSessionStartedAt: Date?
    @State private var gameCompleted = false
    @State private var showResults = false
    @State private var gameResult: GameResult?
    @State private var isCheckingModeration = false
    @State private var showModerationError = false
    @State private var moderationErrorMessage = ""

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var currentGuess: String {
        guesses[currentHintIndex] ?? ""
    }

    private var isInputDisabled: Bool {
        gameCompleted || currentHintIndex < maxUnlockedHintIndex || isCheckingModeration
    }

    private var canSubmitCurrentGuess: Bool {
        !isInputDisabled && !currentGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSkipCurrentHint: Bool {
        !gameCompleted && !isCheckingModeration && currentHintIndex <= 5
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: closePlayView) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .padding(12)
                }
                .padding(.leading, 8)

                Spacer()

                PlayHeaderView(
                    topicNumber: topic.topicNumber,
                    currentHintIndex: currentHintIndex,
                    failedAttempts: failedAttempts,
                    skippedHints: skippedHints,
                    gameState: gameState
                )
                .animation(nil, value: currentHintIndex)

                Spacer()

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

            VStack(spacing: 10) {
                if showModerationError {
                    Text(moderationErrorMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.failureColor(for: colorScheme).opacity(0.9))
                        )
                        .padding(.horizontal, 28)
                        .transition(.scale.combined(with: .opacity))
                }

                PlayInputField(
                    text: Binding(
                        get: { currentGuess },
                        set: { guesses[currentHintIndex] = $0 }
                    ),
                    isFocused: $isInputFocused,
                    isDisabled: isInputDisabled,
                    onSubmit: handleSubmit
                )

                HStack(spacing: 12) {
                    Button(action: handleSkip) {
                        Label("Skip", systemImage: "forward.end.alt")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.buttonBackground(for: colorScheme))
                            )
                    }
                    .disabled(!canSkipCurrentHint)
                    .opacity(canSkipCurrentHint ? 1 : 0.45)

                    Button(action: handleSubmit) {
                        Label("Guess", systemImage: "paperplane.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.primaryVariant],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(!canSubmitCurrentGuess)
                    .opacity(canSubmitCurrentGuess ? 1 : 0.45)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = false
        }
        .gesture(swipeGesture)
        .onAppear {
            loadProgress()
            startActiveSessionIfNeeded()
        }
        .onDisappear {
            pauseActiveSessionIfNeeded()
            saveProgress()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
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
        guard canSubmitCurrentGuess else { return }
        let normalizedGuess = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines)
        guesses[currentHintIndex] = normalizedGuess

        if GuessMatcher.isCorrectGuess(
            answer: topic.answer,
            guess: normalizedGuess,
            topicType: topic.type,
            aliases: topic.aliases ?? []
        ) {
            processGuess(normalizedGuess)
            return
        }

        isCheckingModeration = true
        Task {
            do {
                let (isAppropriate, message) = try await viewModel.moderateGuess(normalizedGuess)

                await MainActor.run {
                    isCheckingModeration = false

                    if !isAppropriate {
                        if settings.hapticsEnabled {
                            notificationFeedback.notificationOccurred(.error)
                        }
                        moderationErrorMessage = message ?? "Please keep your guesses appropriate."
                        showModerationError = true
                        guesses[currentHintIndex] = ""

                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showModerationError = false
                        }
                        return
                    }

                    processGuess(normalizedGuess)
                }
            } catch {
                await MainActor.run {
                    isCheckingModeration = false
                    processGuess(normalizedGuess)
                }
            }
        }
    }

    private func handleSkip() {
        guard canSkipCurrentHint else { return }
        isInputFocused = false
        showModerationError = false

        let skippedHint = currentHintIndex
        guesses[skippedHint] = nil
        failedAttempts.remove(skippedHint)
        skippedHints.insert(skippedHint)

        if settings.hapticsEnabled {
            impactFeedback.impactOccurred()
        }

        if skippedHint < 5 {
            isMovingForward = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentHintIndex += 1
                maxUnlockedHintIndex = max(maxUnlockedHintIndex, currentHintIndex)
            }
            saveProgress()
        } else {
            completeGame(success: false)
        }
    }

    private func processGuess(_ submittedGuess: String) {
        let isCorrect = GuessMatcher.isCorrectGuess(
            answer: topic.answer,
            guess: submittedGuess,
            topicType: topic.type,
            aliases: topic.aliases ?? []
        )

        isInputFocused = false
        isMovingForward = true
        skippedHints.remove(currentHintIndex)

        if isCorrect {
            if settings.hapticsEnabled {
                notificationFeedback.notificationOccurred(.success)
            }
            completeGame(success: true)
            return
        }

        if settings.hapticsEnabled {
            if currentHintIndex < 5 {
                impactFeedback.impactOccurred()
            } else {
                notificationFeedback.notificationOccurred(.error)
            }
        }

        failedAttempts.insert(currentHintIndex)
        if currentHintIndex < 5 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentHintIndex += 1
                maxUnlockedHintIndex = max(maxUnlockedHintIndex, currentHintIndex)
            }
            saveProgress()
        } else {
            completeGame(success: false)
        }
    }

    private func completeGame(success: Bool) {
        let finalAttempts = success ? currentHintIndex : 5
        let finalSkippedHints = skippedHints.filter { $0 <= finalAttempts }.sorted()
        let finalFailedHints = failedAttempts.filter { $0 <= finalAttempts }.sorted()
        let finalGuesses = compactGuesses(upTo: finalAttempts)
        let finalGuessesByHint = guesses
            .filter { $0.key <= finalAttempts }
            .reduce(into: [Int: String]()) { partialResult, item in
                let trimmed = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    partialResult[item.key] = trimmed
                }
            }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            gameState = success ? .won : .lost
            maxUnlockedHintIndex = 5
            gameCompleted = true
        }

        let duration = finalizedElapsedPlaySeconds()

        Task {
            let skipCount = finalSkippedHints.count

            try? await viewModel.submitGame(
                topicId: topic.id,
                attempts: finalAttempts,
                guesses: finalGuesses,
                skips: skipCount,
                duration: duration,
                success: success
            )

            var result = GameResult(
                topicId: topic.id,
                attempts: finalAttempts,
                guesses: finalGuesses,
                guessesByHint: finalGuessesByHint,
                failedHints: finalFailedHints,
                skippedHints: finalSkippedHints,
                skips: skipCount,
                duration: duration,
                success: success,
                answer: topic.answer,
                completedAt: Date(),
                topicNumber: topic.topicNumber,
                streak: 0
            )
            GameResultsManager.save(result)
            let streakValue = GameResultsManager.currentWinStreak()
            result = GameResult(
                topicId: result.topicId,
                attempts: result.attempts,
                guesses: result.guesses,
                guessesByHint: result.guessesByHint,
                failedHints: result.failedHints,
                skippedHints: result.skippedHints,
                skips: result.skips,
                duration: result.duration,
                success: result.success,
                answer: result.answer,
                completedAt: result.completedAt,
                topicNumber: result.topicNumber,
                streak: streakValue
            )
            GameResultsManager.save(result)
            PlayProgressManager.clear()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                gameResult = result
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showResults = true
                }
            }
        }
    }

    private func compactGuesses(upTo hint: Int) -> [String] {
        guesses
            .filter { $0.key <= hint }
            .sorted { $0.key < $1.key }
            .map(\.value)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func loadProgress() {
        if let result = GameResultsManager.load(topicId: topic.id) {
            gameResult = result
            gameCompleted = true
            gameState = result.success ? .won : .lost
            currentHintIndex = min(max(result.attempts, 1), 5)
            maxUnlockedHintIndex = 5
            failedAttempts = Set(result.failedHints)
            skippedHints = Set(result.skippedHints)
            elapsedActiveTime = TimeInterval(result.duration)
            activeSessionStartedAt = nil

            if result.guessesByHint.isEmpty {
                var guessCursor = 0
                for hintIndex in 1...currentHintIndex {
                    if skippedHints.contains(hintIndex) {
                        continue
                    }
                    guard guessCursor < result.guesses.count else { break }
                    guesses[hintIndex] = result.guesses[guessCursor]
                    guessCursor += 1
                }
            } else {
                guesses = result.guessesByHint
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showResults = true
                }
            }
            return
        }

        guard let progress = PlayProgressManager.load(),
              progress.topicId == topic.id else {
            startTime = Date()
            elapsedActiveTime = 0
            activeSessionStartedAt = nil
            return
        }

        currentHintIndex = progress.currentHintIndex
        maxUnlockedHintIndex = progress.maxUnlockedHintIndex
        guesses = progress.guesses
        failedAttempts = progress.failedAttempts
        skippedHints = progress.skippedHints
        startTime = progress.startTime
        elapsedActiveTime = max(0, progress.elapsedActiveTime)
        activeSessionStartedAt = nil
    }

    private func saveProgress() {
        guard !gameCompleted else { return }
        let inProgressSession = activeSessionStartedAt.map { max(0, Date().timeIntervalSince($0)) } ?? 0

        let progress = PlayProgress(
            topicId: topic.id,
            currentHintIndex: currentHintIndex,
            maxUnlockedHintIndex: maxUnlockedHintIndex,
            guesses: guesses,
            failedAttempts: failedAttempts,
            skippedHints: skippedHints,
            startTime: startTime,
            elapsedActiveTime: elapsedActiveTime + inProgressSession
        )
        PlayProgressManager.save(progress)
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard !gameCompleted else { return }

        switch phase {
        case .active:
            startActiveSessionIfNeeded()
        case .inactive, .background:
            pauseActiveSessionIfNeeded()
            saveProgress()
        @unknown default:
            pauseActiveSessionIfNeeded()
            saveProgress()
        }
    }

    private func startActiveSessionIfNeeded() {
        guard !gameCompleted, activeSessionStartedAt == nil else { return }
        activeSessionStartedAt = Date()
    }

    private func pauseActiveSessionIfNeeded() {
        guard let activeSessionStartedAt else { return }
        elapsedActiveTime += max(0, Date().timeIntervalSince(activeSessionStartedAt))
        self.activeSessionStartedAt = nil
    }

    private func finalizedElapsedPlaySeconds() -> Int {
        pauseActiveSessionIfNeeded()
        return max(0, Int(elapsedActiveTime.rounded(.down)))
    }

    private func closePlayView() {
        if let onClose {
            onClose()
            return
        }
        dismiss()
    }
}
