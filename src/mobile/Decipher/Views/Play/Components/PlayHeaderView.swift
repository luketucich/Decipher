import SwiftUI

struct PlayHeaderView: View {
    let topicNumber: Int
    let topicType: String
    let currentHintIndex: Int
    let failedAttempts: Set<Int>
    let gameState: GameState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var animateWin = false
    @State private var progressAnimations: [Bool] = Array(repeating: false, count: 5)
    @State private var pulseAnimation = false
    
    private var hintIconName: String {
        switch topicType.lowercased() {
        case "category":
            return "tag.fill"
        case "emoji":
            return "face.smiling.inverse"
        case "quote":
            return "quote.opening"
        case "trivia":
            return "lightbulb.fill"
        case "definition":
            return "text.book.closed.fill"
        default:
            return "lightbulb.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon and hint type
            VStack(spacing: 8) {
                Image(systemName: hintIconName)
                    .font(AppTheme.Fonts.hintIcon)
                    .foregroundColor(AppTheme.primary)
                
                Text(topicType.uppercased())
                    .font(AppTheme.Fonts.hintType)
                    .tracking(1.2)
                    .foregroundColor(AppTheme.hintTypeColor())
            }
            
            // Progress bar
            HStack(spacing: 6) {
                ForEach(Array(0..<5), id: \.self) { (index: Int) in
                    ProgressSegment(
                        index: index,
                        currentHintIndex: currentHintIndex,
                        failedAttempts: failedAttempts,
                        gameState: gameState,
                        colorScheme: colorScheme,
                        animateWin: animateWin,
                        progressAnimations: progressAnimations
                    )
                }
            }
            .frame(maxWidth: 220)
            .onChange(of: gameState) { _, newValue in
                if newValue == .won {
                    triggerWinAnimation()
                } else if newValue == .lost {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        pulseAnimation = true
                    }
                }
            }
            .onChange(of: failedAttempts) { _, _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    pulseAnimation.toggle()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
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
    let gameState: GameState
    let colorScheme: ColorScheme
    let animateWin: Bool
    let progressAnimations: [Bool]
    
    @State private var shimmerAnimation = false
    @State private var popAnimation = false
    
    private var hintOrder: Int { index + 1 }
    private var isFuture: Bool { hintOrder > currentHintIndex }
    
    private var gradientColors: [Color] {
        if gameState == .won {
            return [AppTheme.successVariant, AppTheme.success]
        } else if gameState == .lost {
            return [AppTheme.failureVariant, AppTheme.failure]
        } else if isFuture {
            return [
                AppTheme.unfilledProgressColor(for: colorScheme),
                AppTheme.unfilledProgressColor(for: colorScheme)
            ]
        } else if failedAttempts.contains(hintOrder) {
            return [AppTheme.failureVariant, AppTheme.failure]
        } else {
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
}
