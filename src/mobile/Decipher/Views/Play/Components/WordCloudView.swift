import SwiftUI

struct WordCloudView: View {
    let guesses: [GuessCount]
    @Environment(\.colorScheme) var colorScheme
    @State private var appeared = false
    
    // Limit to top 15 words for clean display
    private var displayGuesses: [GuessCount] {
        Array(guesses.prefix(15))
    }
    
    // Calculate font size based on rank/frequency
    private func fontSize(for index: Int, count: Int, maxCount: Int) -> CGFloat {
        let normalizedFrequency = Double(count) / Double(maxCount)
        
        // Map frequency to font size range
        // Top word: 32pt, smallest: 14pt
        let minSize: CGFloat = 14
        let maxSize: CGFloat = 32
        
        let size = minSize + CGFloat(normalizedFrequency) * (maxSize - minSize)
        return max(minSize, min(maxSize, size))
    }
    
    // Calculate opacity based on rank
    private func opacity(for index: Int) -> Double {
        let maxOpacity = 1.0
        let minOpacity = 0.5
        let normalized = Double(index) / Double(max(displayGuesses.count - 1, 1))
        return maxOpacity - (normalized * (maxOpacity - minOpacity))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Guesses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            if displayGuesses.isEmpty {
                Text("No guesses yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                FlowLayout(spacing: 12) {
                    ForEach(Array(displayGuesses.enumerated()), id: \.element.id) { index, guessCount in
                        let maxCount = displayGuesses.first?.count ?? 1
                        
                        Text(guessCount.guess)
                            .font(.system(
                                size: fontSize(for: index, count: guessCount.count, maxCount: maxCount),
                                weight: index < 3 ? .bold : .semibold
                            ))
                            .foregroundColor(
                                index < 3
                                    ? AppTheme.primary
                                    : AppTheme.textColor(for: colorScheme)
                            )
                            .opacity(opacity(for: index))
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? opacity(for: index) : 0)
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
        .onAppear {
            appeared = true
        }
    }
}

// Custom flow layout for word cloud
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}
