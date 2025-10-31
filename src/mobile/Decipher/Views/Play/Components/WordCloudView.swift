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
    @State private var focusedWordIndex: Int?
    @State private var lastDragVelocity: CGSize = .zero
    
    private let minZoom: CGFloat = 0.8
    private let maxZoom: CGFloat = 2.0
    private let recenterDelay: TimeInterval = 3.0
    
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
                            let isFocused = focusedWordIndex == index
                            Text(word.word)
                                .font(.system(size: word.size, weight: .black))
                                .fontWeight(isFocused ? .black : word.weight)
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .opacity(isFocused ? 1.0 : word.opacity)
                                .shadow(
                                    color: isFocused ? (colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.3)) : .clear,
                                    radius: isFocused ? 8 : 0,
                                    x: 0,
                                    y: 0
                                )
                                .position(word.position)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
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
                                // Calculate drag velocity
                                lastDragVelocity = CGSize(
                                    width: value.translation.width - (offset.width - lastOffset.width),
                                    height: value.translation.height - (offset.height - lastOffset.height)
                                )
                                updateFocusedWord(in: geometry.size, dragDirection: lastDragVelocity)
                                startRecenterTimer()
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                lastDragVelocity = .zero
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to reset to default position
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            let guessCount = displayGuesses.count
                            let targetZoom: CGFloat = guessCount <= 5 ? 1.0 : (guessCount <= 10 ? 0.9 : 0.75)
                            scale = targetZoom
                            lastScale = targetZoom
                            offset = .zero
                            lastOffset = .zero
                        }
                        updateFocusedWord(in: geometry.size, dragDirection: .zero)
                    }
                    .clipped()
                    .onAppear {
                        layoutWords(in: geometry.size)
                        // Trigger zoom-in to zoom-out animation
                        if !hasAppeared {
                            // Calculate initial zoom based on number of guesses
                            // More guesses = start more zoomed out to show overview
                            let guessCount = displayGuesses.count
                            let initialZoom: CGFloat = guessCount <= 5 ? 1.4 : (guessCount <= 10 ? 1.2 : 1.0)
                            
                            scale = initialZoom
                            lastScale = initialZoom
                            
                            // Quick zoom out to default with spring
                            let targetZoom: CGFloat = guessCount <= 5 ? 1.0 : (guessCount <= 10 ? 0.9 : 0.75)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                                    scale = targetZoom
                                    lastScale = targetZoom
                                    hasAppeared = true
                                }
                                updateFocusedWord(in: geometry.size, dragDirection: .zero)
                            }
                        }
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        layoutWords(in: newSize)
                        updateFocusedWord(in: newSize, dragDirection: .zero)
                    }
                    .onChange(of: scale) { _, _ in
                        updateFocusedWord(in: geometry.size, dragDirection: .zero)
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
    
    private func updateFocusedWord(in size: CGSize, dragDirection: CGSize) {
        // Calculate the center of the visible viewport
        let viewportCenterX = size.width / 2
        let viewportCenterY = size.height / 2
        
        // If we're dragging, find the next word in the drag direction
        // Lowered threshold to make focus switch more easily
        let isDragging = dragDirection != .zero && (abs(dragDirection.width) > 0.5 || abs(dragDirection.height) > 0.5)
        
        if isDragging, let currentIndex = focusedWordIndex {
            // Find words in the direction of drag
            // Drag left (negative width) means content moves left, so we want words to the right
            // Drag up (negative height) means content moves up, so we want words below
            let searchDirection = CGSize(width: -dragDirection.width, height: -dragDirection.height)
            
            var bestCandidate: (index: Int, score: CGFloat)?
            let currentWord = placedWords[currentIndex]
            let currentX = (currentWord.position.x * scale) + offset.width
            let currentY = (currentWord.position.y * scale) + offset.height
            
            for (index, word) in placedWords.enumerated() {
                guard index != currentIndex else { continue }
                
                let transformedX = (word.position.x * scale) + offset.width
                let transformedY = (word.position.y * scale) + offset.height
                
                // Calculate vector from current word to candidate
                let dx = transformedX - currentX
                let dy = transformedY - currentY
                
                // Normalize search direction
                let searchMagnitude = sqrt(searchDirection.width * searchDirection.width + searchDirection.height * searchDirection.height)
                guard searchMagnitude > 0 else { continue }
                
                // Calculate dot product to see if word is in the right direction
                let dotProduct = (dx * searchDirection.width + dy * searchDirection.height) / searchMagnitude
                
                // Only consider words in the direction we're scrolling (positive dot product)
                if dotProduct > 0 {
                    let distance = sqrt(dx * dx + dy * dy)
                    // Score combines direction alignment and distance (prefer closer words in the right direction)
                    let score = dotProduct / distance
                    
                    if bestCandidate == nil || score > bestCandidate!.score {
                        bestCandidate = (index, score)
                    }
                }
            }
            
            // Switch to best candidate if found
            if let candidate = bestCandidate {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred(intensity: 0.6)
                focusedWordIndex = candidate.index
                return
            }
        }
        
        // Fallback: focus word closest to center (for initial load, zoom, etc.)
        var closestIndex: Int?
        var closestDistance: CGFloat = .infinity
        
        for (index, word) in placedWords.enumerated() {
            let transformedX = (word.position.x * scale) + offset.width
            let transformedY = (word.position.y * scale) + offset.height
            
            let distance = sqrt(pow(transformedX - viewportCenterX, 2) + pow(transformedY - viewportCenterY, 2))
            
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        // Only switch if there's no current focus or if we found something much closer
        if focusedWordIndex == nil || (!isDragging && closestDistance < 100) {
            if closestIndex != focusedWordIndex, closestIndex != nil {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred(intensity: 0.6)
            }
            focusedWordIndex = closestIndex
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
            let position = findPosition(
                width: estimatedWidth,
                height: estimatedHeight,
                centerX: centerX,
                centerY: centerY,
                placed: placed,
                containerSize: containerSize
            ) ?? CGPoint(x: centerX, y: centerY + CGFloat(placed.count) * 40) // Fallback: stack vertically
            
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
        let maxAttempts = 2000
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
        // Dramatic size variation - most common word is much larger
        let exponentialFrequency = pow(frequency, 0.5)
        let minSize: CGFloat = 10
        let maxSize: CGFloat = 42
        return minSize + CGFloat(exponentialFrequency) * (maxSize - minSize)
    }
    
    private func calculateWordWeight(frequency: Double) -> Font.Weight {
        // More dramatic weight variation to distinguish top guesses
        if frequency > 0.8 {
            return .black
        } else if frequency > 0.6 {
            return .heavy
        } else if frequency > 0.45 {
            return .bold
        } else if frequency > 0.3 {
            return .semibold
        } else if frequency > 0.2 {
            return .medium
        } else {
            return .light
        }
    }
    
    private func calculateWordOpacity(frequency: Double) -> Double {
        // More dramatic opacity variation to distinguish top guesses
        // Top guesses are very visible (0.95-1.0), rare guesses fade more (0.35-0.5)
        return 0.35 + (pow(frequency, 0.3) * 0.65)
    }
}
