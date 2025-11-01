import SwiftUI
import UIKit

struct WordPlacement {
    let word: String
    let count: Int
    let position: CGPoint
    let size: CGFloat
    let weight: Font.Weight
    let opacity: Double
    let bounds: CGRect
    let angle: CGFloat  // Rotation angle
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

    // Fitted values computed from layout so everything is visible
    @State private var fitScale: CGFloat = 1.0
    @State private var fitOffset: CGSize = .zero

    private let minZoom: CGFloat = 0.8
    private let maxZoom: CGFloat = 2.0
    private let recenterDelay: TimeInterval = 3.0

    private var displayGuesses: [GuessCount] {
        // Backend already handles normalization and aggregation
        // Just return the guesses as-is
        return guesses
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Top Guesses")
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
                                .foregroundColor(color(for: index))
                                .opacity(isFocused ? 1.0 : max(word.opacity, 0.5)) // ensure minimum readability
                                .shadow(
                                    color: isFocused ? (colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.2)) : .clear,
                                    radius: isFocused ? 6 : 0,
                                    x: 0,
                                    y: 0
                                )
                                .scaleEffect(isFocused ? 1.05 : 1.0)
                                .rotationEffect(.degrees(word.angle))
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
                        // Double tap to reset to fitted view (everything visible)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            scale = fitScale
                            lastScale = fitScale
                            offset = fitOffset
                            lastOffset = fitOffset
                        }
                        updateFocusedWord(in: geometry.size, dragDirection: .zero)
                    }
                    .clipped()
                    .onAppear {
                        layoutWords(in: geometry.size)
                        computeFit(in: geometry.size)
                        applyInitialFocus()
                        // Subtle intro animation: zoom slightly in, then to fit
                        if !hasAppeared {
                            let introZoom = min(fitScale * 1.1, maxZoom)
                            scale = introZoom
                            lastScale = introZoom

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
                                    scale = fitScale
                                    lastScale = fitScale
                                    offset = fitOffset
                                    lastOffset = fitOffset
                                    hasAppeared = true
                                }
                                updateFocusedWord(in: geometry.size, dragDirection: .zero)
                            }
                        }
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        layoutWords(in: newSize)
                        computeFit(in: newSize)
                        // Keep current zoom if user has changed it; otherwise keep fitted
                        if !hasAppeared {
                            scale = fitScale
                            lastScale = fitScale
                            offset = fitOffset
                            lastOffset = fitOffset
                        }
                        updateFocusedWord(in: newSize, dragDirection: .zero)
                    }
                    .onChange(of: scale) { _, _ in
                        updateFocusedWord(in: geometry.size, dragDirection: .zero)
                    }
                }
                .frame(height: 200)
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
            // Initial state set in geometry reader
        }
    }

    private func startRecenterTimer() {
        recenterTimer?.invalidate()
        recenterTimer = Timer.scheduledTimer(withTimeInterval: recenterDelay, repeats: false) { _ in
            // Only recenter if we're close to fitted zoom (i.e., user isn't zoomed way in)
            let nearFit = abs(scale - fitScale) < 0.1
            if nearFit {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                    offset = fitOffset
                    lastOffset = fitOffset
                }
            }
        }
    }

    private func applyInitialFocus() {
        // Default focus to the most frequent guess if available
        guard focusedWordIndex == nil, !placedWords.isEmpty else { return }
        if let maxCount = placedWords.map({ $0.count }).max(),
           let index = placedWords.firstIndex(where: { $0.count == maxCount }) {
            focusedWordIndex = index
        }
    }

    private func updateFocusedWord(in size: CGSize, dragDirection: CGSize) {
        // Calculate the center of the visible viewport
        let viewportCenterX = size.width / 2
        let viewportCenterY = size.height / 2

        // If we're dragging, find the next word in the drag direction
        let isDragging = dragDirection != .zero && (abs(dragDirection.width) > 0.5 || abs(dragDirection.height) > 0.5)

        if isDragging, let currentIndex = focusedWordIndex {
            let searchDirection = CGSize(width: -dragDirection.width, height: -dragDirection.height)

            var bestCandidate: (index: Int, score: CGFloat)?
            let currentWord = placedWords[currentIndex]
            let currentX = (currentWord.position.x * scale) + offset.width
            let currentY = (currentWord.position.y * scale) + offset.height

            for (index, word) in placedWords.enumerated() {
                guard index != currentIndex else { continue }

                let transformedX = (word.position.x * scale) + offset.width
                let transformedY = (word.position.y * scale) + offset.height

                let dx = transformedX - currentX
                let dy = transformedY - currentY

                let searchMagnitude = sqrt(searchDirection.width * searchDirection.width + searchDirection.height * searchDirection.height)
                guard searchMagnitude > 0 else { continue }

                let dotProduct = (dx * searchDirection.width + dy * searchDirection.height) / searchMagnitude

                if dotProduct > 0 {
                    let distance = sqrt(dx * dx + dy * dy)
                    let score = dotProduct / max(distance, 0.001)

                    if bestCandidate == nil || score > bestCandidate!.score {
                        bestCandidate = (index, score)
                    }
                }
            }

            if let candidate = bestCandidate {
                if candidate.index != focusedWordIndex {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred(intensity: 0.6)
                }
                focusedWordIndex = candidate.index
                return
            }
        }

        // If no dragging, prefer the most frequent word when no focus yet
        if focusedWordIndex == nil {
            applyInitialFocus()
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

        if focusedWordIndex == nil || (!isDragging && closestDistance < 100) {
            if closestIndex != focusedWordIndex, closestIndex != nil {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred(intensity: 0.6)
            }
            focusedWordIndex = closestIndex
        }
    }

    private func layoutWords(in containerSize: CGSize) {
        guard !displayGuesses.isEmpty else {
            placedWords = []
            return
        }

        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        var placed: [WordPlacement] = []

        let sortedGuesses = displayGuesses.sorted { $0.count > $1.count }
        let maxCount = sortedGuesses.first?.count ?? 1

        for (index, guess) in sortedGuesses.enumerated() {
            let currentFreq = Double(guess.count) / Double(maxCount)
            var currentSize = calculateWordSize(frequency: currentFreq)
            let weight = calculateWordWeight(frequency: currentFreq)
            let opacity = calculateWordOpacity(frequency: currentFreq)

            var placedSuccessfully = false
            var reductionFactor: CGFloat = 1.0
            // Allow more reductions as we go down the list to guarantee placement
            let maxReductions = 8

            for reduction in 0..<maxReductions {
                let font = UIFont.systemFont(ofSize: currentSize, weight: uiFontWeight(for: weight))
                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                let attributedText = NSAttributedString(string: guess.guess, attributes: attributes)
                var textSize = attributedText.boundingRect(
                    with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                    options: NSStringDrawingOptions([.usesLineFragmentOrigin, .usesFontLeading]),
                    context: NSStringDrawingContext()
                ).size
                textSize.width = ceil(textSize.width)
                textSize.height = ceil(textSize.height)

                let padding: CGFloat = 4.0
                let width = textSize.width + padding * 2
                let height = textSize.height + padding * 2

                // Only horizontal placement for now
                for angle in [0.0] {
                    let effectiveWidth = angle.truncatingRemainder(dividingBy: 180) == 0 ? width : height
                    let effectiveHeight = angle.truncatingRemainder(dividingBy: 180) == 0 ? height : width

                    let position = findPosition(
                        width: effectiveWidth,
                        height: effectiveHeight,
                        centerX: centerX,
                        centerY: centerY,
                        placed: placed,
                        containerSize: containerSize,
                        forcePlace: true,
                        wordIndex: index,
                        totalWords: sortedGuesses.count
                    )

                    let testBounds = CGRect(
                        x: position.x - effectiveWidth / 2,
                        y: position.y - effectiveHeight / 2,
                        width: effectiveWidth,
                        height: effectiveHeight
                    )

                    var hasCollision = false
                    for placedWord in placed {
                        // Tiny tolerance only for deep reductions to avoid invisible failure
                        let tolerance: CGFloat = reduction >= maxReductions - 2 ? 1.0 : 0.0
                        let inflatedBounds = placedWord.bounds.insetBy(dx: -tolerance, dy: -tolerance)
                        if testBounds.intersects(inflatedBounds) {
                            hasCollision = true
                            break
                        }
                    }

                    if !hasCollision {
                        let bounds = testBounds

                        let placement = WordPlacement(
                            word: guess.guess,
                            count: guess.count,
                            position: position,
                            size: currentSize,
                            weight: weight,
                            opacity: opacity,
                            bounds: bounds,
                            angle: angle
                        )
                        placed.append(placement)
                        placedSuccessfully = true
                        break
                    }
                }

                if placedSuccessfully {
                    break
                }

                // Reduce size if not placed; reduce more aggressively for less frequent words
                reductionFactor -= 0.12
                currentSize *= max(reductionFactor, 0.4)
            }

            // If still not placed, as a last resort, append minimally at center (rare)
            if !placedSuccessfully {
                let fallback = WordPlacement(
                    word: guess.guess,
                    count: guess.count,
                    position: CGPoint(x: centerX, y: centerY),
                    size: max(currentSize, 10),
                    weight: weight,
                    opacity: opacity,
                    bounds: CGRect(x: centerX - 1, y: centerY - 1, width: 2, height: 2),
                    angle: 0
                )
                placed.append(fallback)
            }
        }

        placedWords = placed
    }

    private func computeFit(in containerSize: CGSize) {
        guard !placedWords.isEmpty else {
            fitScale = 1.0
            fitOffset = .zero
            return
        }

        // Compute union of all word bounds
        var union = placedWords[0].bounds
        for w in placedWords.dropFirst() {
            union = union.union(w.bounds)
        }

        // Compute scale to fit union inside container with padding
        let padding: CGFloat = 12
        let availableWidth = max(containerSize.width - padding * 2, 1)
        let availableHeight = max(containerSize.height - padding * 2, 1)

        let scaleX = availableWidth / max(union.width, 1)
        let scaleY = availableHeight / max(union.height, 1)
        let targetScale = min(scaleX, scaleY)
        // Clamp to our zoom limits
        fitScale = min(max(targetScale, minZoom), maxZoom)

        // Compute offset to center union
        let unionCenter = CGPoint(x: union.midX, y: union.midY)
        let containerCenter = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)

        // offset is applied after scale, so we want scaled positions to land centered
        // position' = position * scale + offset => offset = containerCenter - unionCenter * scale
        let ox = containerCenter.x - unionCenter.x * fitScale
        let oy = containerCenter.y - unionCenter.y * fitScale
        fitOffset = CGSize(width: ox, height: oy)
    }

    private func findPosition(
        width: CGFloat,
        height: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        placed: [WordPlacement],
        containerSize: CGSize,
        forcePlace: Bool = false,
        wordIndex: Int = 0,
        totalWords: Int = 1
    ) -> CGPoint {
        let maxAttempts = 12000
        let spiralStep: CGFloat = 1.0
        let tStep: Double = 0.03

        let overlapTolerance: CGFloat = 0.0

        for attempt in 0..<maxAttempts {
            let t = Double(attempt) * tStep
            let angle = t
            let radius = spiralStep * t

            let x = centerX + CGFloat(cos(angle) * radius * 1.2)
            let y = centerY + CGFloat(sin(angle) * radius * 0.8)

            let testBounds = CGRect(
                x: x - width / 2,
                y: y - height / 2,
                width: width,
                height: height
            )

            let padding: CGFloat = 10
            let isWithinBounds = testBounds.minX >= padding &&
                                testBounds.maxX <= containerSize.width - padding &&
                                testBounds.minY >= padding &&
                                testBounds.maxY <= containerSize.height - padding

            if !isWithinBounds {
                continue
            }

            var hasCollision = false
            for placedWord in placed {
                let inflatedBounds = placedWord.bounds.insetBy(dx: -overlapTolerance, dy: -overlapTolerance)
                if testBounds.intersects(inflatedBounds) {
                    hasCollision = true
                    break
                }
            }

            if !hasCollision {
                return CGPoint(x: x, y: y)
            }
        }

        if forcePlace {
            let gridSize: CGFloat = 18
            let cols = Int(containerSize.width / gridSize)
            let rows = Int(containerSize.height / gridSize)

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * gridSize + gridSize / 2
                    let y = CGFloat(row) * gridSize + gridSize / 2

                    let testBounds = CGRect(
                        x: x - width / 2,
                        y: y - height / 2,
                        width: width,
                        height: height
                    )

                    if testBounds.minX >= 0 && testBounds.maxX <= containerSize.width &&
                       testBounds.minY >= 0 && testBounds.maxY <= containerSize.height {

                        var hasCollision = false
                        for placedWord in placed {
                            let inflatedBounds = placedWord.bounds.insetBy(dx: -overlapTolerance, dy: -overlapTolerance)
                            if testBounds.intersects(inflatedBounds) {
                                hasCollision = true
                                break
                            }
                        }

                        if !hasCollision {
                            return CGPoint(x: x, y: y)
                        }
                    }
                }
            }

            // Last resort: center
            return CGPoint(x: centerX, y: centerY)
        }

        return CGPoint(x: centerX, y: centerY)
    }

    private func uiFontWeight(for weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .black: return .black
        case .heavy: return .heavy
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        case .regular: return .regular
        case .light: return .light
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        default: return .regular
        }
    }

    private func calculateWordSize(frequency: Double) -> CGFloat {
        // Dramatic size variation - most common word is much larger
        let exponentialFrequency = pow(frequency, 0.5)
        let minSize: CGFloat = 11 // bump minimum for readability
        let maxSize: CGFloat = 42
        return minSize + CGFloat(exponentialFrequency) * (maxSize - minSize)
    }

    private func calculateWordWeight(frequency: Double) -> Font.Weight {
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
        // Keep a higher floor for readability
        return max(0.5, 0.35 + (pow(frequency, 0.3) * 0.65))
    }

    // Subtle color variation for visual interest
    private func color(for index: Int) -> Color {
        // Emphasize the top 3; otherwise default text color
        guard !placedWords.isEmpty else { return AppTheme.textColor(for: colorScheme) }
        let sorted = placedWords.enumerated().sorted { $0.element.count > $1.element.count }.map { $0.offset }
        if let first = sorted.first, index == first {
            return AppTheme.primary
        } else if sorted.dropFirst().first == index {
            return AppTheme.purple2
        } else if sorted.dropFirst(2).first == index {
            return AppTheme.pink
        } else {
            return AppTheme.textColor(for: colorScheme)
        }
    }
}
