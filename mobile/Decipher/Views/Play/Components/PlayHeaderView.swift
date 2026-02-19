import SwiftUI

struct PlayHeaderView: View {
    let topicNumber: Int
    let currentHintIndex: Int
    let failedAttempts: Set<Int>
    let skippedHints: Set<Int>
    let gameState: GameState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var animateWin = false
    @State private var progressAnimations: [Bool] = Array(repeating: false, count: 5)
    
    var body: some View {
        VStack(spacing: 7) {
            Text("Daily Decipher #\(topicNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))

            HStack(spacing: 6) {
                ForEach(Array(0..<5), id: \.self) { (index: Int) in
                    ProgressSegment(
                        index: index,
                        currentHintIndex: currentHintIndex,
                        failedAttempts: failedAttempts,
                        skippedHints: skippedHints,
                        gameState: gameState,
                        colorScheme: colorScheme,
                        animateWin: animateWin,
                        progressAnimations: progressAnimations
                    )
                }
            }
            .frame(maxWidth: 220)
        }
        .onChange(of: gameState) { _, newValue in
            if newValue == .won {
                triggerWinAnimation()
            }
        }
    }
    
    private func triggerWinAnimation() {
        for index in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                    progressAnimations[index] = true
                }
            }
        }
        
        withAnimation(.easeInOut(duration: 0.3).delay(0.4)) {
            animateWin = true
        }
    }
}

struct ProgressSegment: View {
    let index: Int
    let currentHintIndex: Int
    let failedAttempts: Set<Int>
    let skippedHints: Set<Int>
    let gameState: GameState
    let colorScheme: ColorScheme
    let animateWin: Bool
    let progressAnimations: [Bool]
    
    @State private var shimmerAnimation = false
    @State private var popAnimation = false
    
    private var hintOrder: Int { index + 1 }
    private var isFuture: Bool {
        if gameState == .won {
            return hintOrder > currentHintIndex
        }
        if gameState == .lost {
            return false
        }
        return hintOrder > currentHintIndex
    }

    private var segmentState: SegmentState {
        if isFuture {
            return .future
        }

        if skippedHints.contains(hintOrder) {
            return .skipped
        }

        if failedAttempts.contains(hintOrder) {
            return .failed
        }

        if gameState == .won && hintOrder == currentHintIndex {
            return .won
        }

        if gameState == .lost {
            return .failed
        }

        return .active
    }
    
    private var gradientColors: [Color] {
        switch segmentState {
        case .won:
            return [AppTheme.successVariant, AppTheme.successColor(for: colorScheme)]
        case .failed:
            return [AppTheme.failureVariant, AppTheme.failureColor(for: colorScheme)]
        case .skipped:
            return [AppTheme.warningVariant, AppTheme.warningColor(for: colorScheme)]
        case .future:
            return [
                AppTheme.unfilledProgressColor(for: colorScheme),
                AppTheme.unfilledProgressColor(for: colorScheme)
            ]
        case .active:
            return [AppTheme.primaryVariant, AppTheme.primary]
        }
    }
    
    var body: some View {
        ZStack {
            // Base progress segment
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 6)
                .shadow(
                    color: glowColor.opacity(isFuture ? 0 : 0.35),
                    radius: popAnimation ? 6 : 3,
                    x: 0,
                    y: 2
                )
                .scaleEffect(
                    x: popAnimation ? 1.15 : 1.0,
                    y: popAnimation ? 1.5 : 1.0
                )
                .animation(
                    .interpolatingSpring(stiffness: 300, damping: 15),
                    value: gradientColors
                )
                .onChange(of: progressAnimations[index]) { _, newValue in
                    if newValue && gameState == .won {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            popAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                popAnimation = false
                            }
                        }
                    }
                }
            
            // Shimmer effect for win state
            if gameState == .won && animateWin {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.6),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .frame(width: 20)
                    .offset(x: shimmerAnimation ? 60 : -60)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 0.8)
                            .delay(Double(index) * 0.1)
                            .repeatCount(1, autoreverses: false)
                        ) {
                            shimmerAnimation = true
                        }
                    }
                    .mask(
                        RoundedRectangle(cornerRadius: 4)
                            .frame(height: 6)
                    )
            }
        }
    }

    private var glowColor: Color {
        switch segmentState {
        case .won:
            return AppTheme.successColor(for: colorScheme)
        case .failed:
            return AppTheme.failureColor(for: colorScheme)
        case .skipped:
            return AppTheme.warningColor(for: colorScheme)
        case .future:
            return .clear
        case .active:
            return AppTheme.primary
        }
    }
}

private enum SegmentState {
    case future
    case active
    case failed
    case skipped
    case won
}
