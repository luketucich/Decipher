import SwiftUI

struct TopGuessesView: View {
    let guesses: [GuessCount]
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false
    
    // Show all guesses, no limit
    
    private var displayGuesses: [GuessCount] {
        // Show all guesses sorted by count
        return guesses.sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Top Guesses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .center)

            if displayGuesses.isEmpty {
                Text("No guesses yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                let maxCount = displayGuesses.first?.count ?? 1
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(Array(displayGuesses.enumerated()), id: \.offset) { index, guess in
                            HStack(spacing: 12) {
                                // Left spacer for centering
                                Spacer()
                                    .frame(width: 12)
                                
                                // Guess text
                                Text(guess.guess)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                                    .frame(width: 100, alignment: .leading)
                                    .lineLimit(1)
                                
                                // Bar chart - much wider
                                ZStack(alignment: .leading) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.secondaryTextColor(for: colorScheme).opacity(0.1))
                                        .frame(height: 20)
                                    
                                    // Filled bar
                                    GeometryReader { geometry in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(barColor(for: index))
                                            .frame(width: geometry.size.width * CGFloat(guess.count) / CGFloat(maxCount), height: 20)
                                            .scaleEffect(x: hasAppeared ? 1 : 0, y: 1, anchor: .leading)
                                    }
                                    .frame(height: 20)
                                }
                                .frame(height: 20)
                                
                                // Count
                                Text("\(guess.count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                                    .frame(width: 35, alignment: .trailing)
                                
                                // Right spacer to push scroll bar far to the right
                                Spacer()
                                    .frame(width: 12)
                            }
                            .frame(height: 30)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(x: hasAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05), value: hasAppeared)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.visible)
                .frame(maxHeight: 250)
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
            withAnimation {
                hasAppeared = true
            }
        }
    }
    
    private func barColor(for index: Int) -> LinearGradient {
        switch index {
        case 0:
            // Top guess - vibrant primary purple
            return LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryVariant],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 1:
            // Second guess - much darker purple3
            return LinearGradient(
                colors: [AppTheme.purple3.opacity(0.5), AppTheme.purple3.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 2:
            // Third guess - even darker purple3
            return LinearGradient(
                colors: [AppTheme.purple3.opacity(0.3), AppTheme.purple3.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            // Rest - muted gray
            return LinearGradient(
                colors: [AppTheme.secondaryTextColor(for: colorScheme).opacity(0.4), AppTheme.secondaryTextColor(for: colorScheme).opacity(0.25)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
