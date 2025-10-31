import SwiftUI

struct WordCloudView: View {
    let guesses: [GuessCount]
    @Environment(\.colorScheme) var colorScheme
    @State private var appeared = false
    
    // Limit to top 20 words for optimal display
    private var displayGuesses: [GuessCount] {
        Array(guesses.prefix(20))
    }
    
    // Calculate font size with dramatic scaling - most common words MUCH larger
    private func fontSize(for index: Int, count: Int, maxCount: Int) -> CGFloat {
        let normalizedFrequency = Double(count) / Double(maxCount)
        // More aggressive exponential scaling for greater disparity
        let exponentialFrequency = pow(normalizedFrequency, 0.4)
        let minSize: CGFloat = 10
        let maxSize: CGFloat = 40
        let size = minSize + CGFloat(exponentialFrequency) * (maxSize - minSize)
        return max(minSize, min(maxSize, size))
    }
    
    // Calculate font weight based on frequency
    private func fontWeight(for index: Int, count: Int, maxCount: Int) -> Font.Weight {
        let normalizedFrequency = Double(count) / Double(maxCount)
        if normalizedFrequency > 0.8 {
            return .black
        } else if normalizedFrequency > 0.6 {
            return .heavy
        } else if normalizedFrequency > 0.4 {
            return .bold
        } else if normalizedFrequency > 0.2 {
            return .semibold
        } else {
            return .medium
        }
    }
    
    // Assign colors with variety - cycling through theme colors
    private func wordColor(for index: Int) -> Color {
        let colors = [
            AppTheme.primary,
            AppTheme.purple1,
            AppTheme.pink,
            AppTheme.purple2,
            AppTheme.pink2,
            AppTheme.primaryVariant,
            AppTheme.purple3,
            AppTheme.pinkVariant,
            AppTheme.success,
            AppTheme.teal
        ]
        return colors[index % colors.count]
    }
    
    // Calculate opacity based on frequency
    private func opacity(for index: Int, count: Int, maxCount: Int) -> Double {
        let normalizedFrequency = Double(count) / Double(maxCount)
        return 0.7 + (normalizedFrequency * 0.3) // Range: 0.7 to 1.0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Common Guesses")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if displayGuesses.isEmpty {
                Text("No guesses yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                CenteredWordCloudLayout(spacing: 6) {
                    ForEach(Array(displayGuesses.enumerated()), id: \.element.id) { index, guessCount in
                        let maxCount = displayGuesses.first?.count ?? 1
                        
                        Text(guessCount.guess)
                            .font(.system(
                                size: fontSize(for: index, count: guessCount.count, maxCount: maxCount),
                                weight: fontWeight(for: index, count: guessCount.count, maxCount: maxCount)
                            ))
                            .foregroundColor(wordColor(for: index))
                            .opacity(opacity(for: index, count: guessCount.count, maxCount: maxCount))
                            .scaleEffect(appeared ? 1 : 0.3)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.03),
                                value: appeared
                            )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
        .onAppear {
            appeared = true
        }
    }
}

// Centered word cloud layout - largest words in center, smaller words around edges
struct CenteredWordCloudLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(
            in: bounds.width,
            subviews: subviews
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }
    
    private func computeLayout(in maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        guard !subviews.isEmpty else { return (CGSize.zero, []) }
        
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var positions: [CGPoint] = []
        
        // Calculate word priorities (size = importance)
        let wordSizes = sizes.map { $0.width * $0.height }
        let maxWordSize = wordSizes.max() ?? 1
        
        var placedRects: [CGRect] = []
        let centerX = maxWidth / 2
        
        // Estimate height based on content
        let avgHeight: CGFloat = sizes.reduce(0) { $0 + $1.height } / CGFloat(sizes.count)
        let estimatedHeight = avgHeight * 5
        let centerY = estimatedHeight / 2
        
        for (index, size) in sizes.enumerated() {
            let wordSize = wordSizes[index]
            let priority = wordSize / maxWordSize
            
            var bestPosition: CGPoint?
            var bestScore: CGFloat = .infinity
            
            // Try positions starting from center
            for attempt in 0..<200 {
                // Radius grows based on attempt, but larger words stay closer to center
                let baseRadius = CGFloat(attempt) * 4.5
                let priorityFactor = 1.0 - (priority * 0.6) // Higher priority = smaller factor = stays closer
                let radius = baseRadius * priorityFactor
                
                // Random angle for more organic placement
                let angle = Double.random(in: 0...(2 * .pi))
                
                let offsetX = cos(angle) * radius
                let offsetY = sin(angle) * radius * 0.75 // Slightly flatten vertically
                
                let candidateX = centerX - (size.width / 2) + offsetX
                let candidateY = centerY - (size.height / 2) + offsetY
                
                // Keep within bounds
                let clampedX = max(spacing, min(candidateX, maxWidth - size.width - spacing))
                let clampedY = max(spacing, candidateY)
                
                let candidateRect = CGRect(
                    x: clampedX - spacing/2,
                    y: clampedY - spacing/2,
                    width: size.width + spacing,
                    height: size.height + spacing
                )
                
                // Check for collisions
                if !placedRects.contains(where: { $0.intersects(candidateRect) }) {
                    // Score based on distance from center - prefer center for large words
                    let distanceFromCenter = sqrt(pow(clampedX + size.width / 2 - centerX, 2) + pow(clampedY + size.height / 2 - centerY, 2))
                    let score = distanceFromCenter / (priority + 0.1) // Divide by priority to favor center for important words
                    
                    if score < bestScore {
                        bestScore = score
                        bestPosition = CGPoint(x: clampedX, y: clampedY)
                    }
                    
                    // Accept quickly for high priority words near center
                    if priority > 0.7 && distanceFromCenter < 80 {
                        break
                    }
                    
                    // Accept after checking enough positions
                    if attempt > 120 && bestPosition != nil {
                        break
                    }
                }
            }
            
            // Use best found position or fallback
            let finalPosition = bestPosition ?? CGPoint(x: spacing, y: CGFloat(index) * 40)
            positions.append(finalPosition)
            placedRects.append(CGRect(
                x: finalPosition.x - spacing/2,
                y: finalPosition.y - spacing/2,
                width: size.width + spacing,
                height: size.height + spacing
            ))
        }
        
        // Calculate final bounds
        let minY = placedRects.map { $0.minY }.min() ?? 0
        let maxY = placedRects.map { $0.maxY }.max() ?? 100
        let height = maxY - minY + spacing * 2
        
        // Adjust positions to remove top padding
        for i in 0..<positions.count {
            positions[i].y -= minY - spacing
        }
        
        return (CGSize(width: maxWidth, height: height), positions)
    }
}
