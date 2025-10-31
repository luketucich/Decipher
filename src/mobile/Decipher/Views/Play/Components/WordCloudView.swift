import SwiftUI

struct WordPlacement {
    let word: String
    let count: Int
    let position: CGPoint
    let size: CGFloat
    let weight: Font.Weight
    let opacity: Double
    let bounds: CGRect
}

struct WordCloudView: View {
    let guesses: [GuessCount]
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var recenterTimer: Timer?
    @State private var placedWords: [WordPlacement] = []
    @State private var hasAppeared = false
    
    private let minZoom: CGFloat = 0.8
    private let maxZoom: CGFloat = 2.0
    private let recenterDelay: TimeInterval = 0.4
    
    // Include all unique guesses (GuessCount already has unique guesses with count)
    private var displayGuesses: [GuessCount] {
        // GuessCount already represents unique guesses with their counts
        // No need to filter for duplicates
        guesses
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Common Guesses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(hasAppeared ? 1.0 : 0.0)
            
            if displayGuesses.isEmpty {
                Text("No guesses yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(placedWords.enumerated()), id: \.offset) { index, word in
                            Text(word.word)
                                .font(.system(size: word.size, weight: word.weight))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .opacity(word.opacity)
                                .position(word.position)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { value in
                                let finalScale = lastScale * value
                                
                                if finalScale < minZoom {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        scale = minZoom
                                        lastScale = minZoom
                                    }
                                } else if finalScale > maxZoom {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        scale = maxZoom
                                        lastScale = maxZoom
                                    }
                                } else {
                                    scale = finalScale
                                    lastScale = finalScale
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                startRecenterTimer()
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .clipped()
                    .onAppear {
                        layoutWords(in: geometry.size)
                        // Trigger zoom-in to zoom-out animation
                        if !hasAppeared {
                            // Start zoomed in
                            scale = 1.5
                            lastScale = 1.5
                            
                            // Quick zoom out to normal with spring
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    hasAppeared = true
                                }
                            }
                        }
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        layoutWords(in: newSize)
                    }
                }
                .frame(height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
                .shadow(
                    color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .onAppear {
            // Initial state will be set in geometry reader's onAppear
        }
    }
    
    private func startRecenterTimer() {
        recenterTimer?.invalidate()
        recenterTimer = Timer.scheduledTimer(withTimeInterval: recenterDelay, repeats: false) { _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                offset = .zero
                lastOffset = .zero
            }
        }
    }
    
    // D3-cloud inspired layout algorithm
    private func layoutWords(in containerSize: CGSize) {
        guard !displayGuesses.isEmpty else {
            placedWords = []
            return
        }
        
        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        var placed: [WordPlacement] = []
        
        // Sort by count descending (most common first)
        let sortedGuesses = displayGuesses.sorted { $0.count > $1.count }
        let maxCount = sortedGuesses.first?.count ?? 1
        
        for (_, guess) in sortedGuesses.enumerated() {
            let normalizedFreq = Double(guess.count) / Double(maxCount)
            let size = calculateWordSize(frequency: normalizedFreq)
            let weight = calculateWordWeight(frequency: normalizedFreq)
            let opacity = calculateWordOpacity(frequency: normalizedFreq)
            
            // Estimate text bounds (approximation)
            let estimatedWidth = CGFloat(guess.guess.count) * size * 0.55
            let estimatedHeight = size * 1.3
            
            // Find position using spiral search
            if let position = findPosition(
                width: estimatedWidth,
                height: estimatedHeight,
                centerX: centerX,
                centerY: centerY,
                placed: placed,
                containerSize: containerSize
            ) {
                let bounds = CGRect(
                    x: position.x - estimatedWidth / 2,
                    y: position.y - estimatedHeight / 2,
                    width: estimatedWidth,
                    height: estimatedHeight
                )
                
                let placement = WordPlacement(
                    word: guess.guess,
                    count: guess.count,
                    position: position,
                    size: size,
                    weight: weight,
                    opacity: opacity,
                    bounds: bounds
                )
                placed.append(placement)
            }
        }
        
        placedWords = placed
    }
    
    // Archimedean spiral search for non-overlapping position
    private func findPosition(
        width: CGFloat,
        height: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        placed: [WordPlacement],
        containerSize: CGSize
    ) -> CGPoint? {
        let maxAttempts = 500
        let spiralStep: CGFloat = 2.0
        
        for attempt in 0..<maxAttempts {
            let t = Double(attempt) * 0.1
            let angle = t
            let radius = spiralStep * t
            
            // Favor horizontal spread by scaling x-axis more
            let x = centerX + CGFloat(cos(angle) * radius * 1.4)
            let y = centerY + CGFloat(sin(angle) * radius * 0.7)
            
            let testBounds = CGRect(
                x: x - width / 2,
                y: y - height / 2,
                width: width,
                height: height
            )
            
            // Check if in bounds
            guard testBounds.minX >= 0 && testBounds.maxX <= containerSize.width &&
                  testBounds.minY >= 0 && testBounds.maxY <= containerSize.height else {
                continue
            }
            
            // Check for collisions with placed words
            var hasCollision = false
            for placedWord in placed {
                if testBounds.intersects(placedWord.bounds) {
                    hasCollision = true
                    break
                }
            }
            
            if !hasCollision {
                return CGPoint(x: x, y: y)
            }
        }
        
        return nil
    }
    
    private func calculateWordSize(frequency: Double) -> CGFloat {
        // Balanced size variation
        let exponentialFrequency = pow(frequency, 0.4)
        let minSize: CGFloat = 14
        let maxSize: CGFloat = 32
        return minSize + CGFloat(exponentialFrequency) * (maxSize - minSize)
    }
    
    private func calculateWordWeight(frequency: Double) -> Font.Weight {
        // Dramatic weight variation for visual interest
        if frequency > 0.9 {
            return .black
        } else if frequency > 0.75 {
            return .heavy
        } else if frequency > 0.6 {
            return .bold
        } else if frequency > 0.45 {
            return .semibold
        } else if frequency > 0.3 {
            return .medium
        } else if frequency > 0.15 {
            return .regular
        } else {
            return .light
        }
    }
    
    private func calculateWordOpacity(frequency: Double) -> Double {
        // Smooth opacity variation - more visible overall
        return 0.5 + (pow(frequency, 0.5) * 0.5)
    }
}
