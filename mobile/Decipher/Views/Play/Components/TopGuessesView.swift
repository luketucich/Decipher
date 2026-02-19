import SwiftUI

struct TopGuessesView: View {
    let guesses: [GuessCount]
    @Environment(\.colorScheme) var colorScheme
    @State private var hasAppeared = false

    private var displayGuesses: [GuessCount] {
        guesses.sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.guess < rhs.guess
            }
            return lhs.count > rhs.count
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("Top Guesses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            if displayGuesses.isEmpty {
                Text("No guesses yet")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                let maxCount = max(displayGuesses.first?.count ?? 1, 1)

                VStack(spacing: 8) {
                    ForEach(Array(displayGuesses.prefix(8).enumerated()), id: \.offset) { index, guess in
                        HStack(spacing: 10) {
                            Text(guess.guess)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .frame(width: 112, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(AppTheme.secondaryTextColor(for: colorScheme).opacity(0.12))
                                        .frame(height: 20)

                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(gradient(for: index))
                                        .frame(
                                            width: geometry.size.width * CGFloat(guess.count) / CGFloat(maxCount),
                                            height: 20
                                        )
                                        .scaleEffect(x: hasAppeared ? 1 : 0, y: 1, anchor: .leading)
                                }
                            }
                            .frame(height: 20)

                            Text("\(guess.count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                                .frame(width: 26, alignment: .trailing)
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(x: hasAppeared ? 0 : 12)
                        .animation(.spring(response: 0.44, dampingFraction: 0.8).delay(Double(index) * 0.04), value: hasAppeared)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
    }

    private func gradient(for index: Int) -> LinearGradient {
        switch index {
        case 0:
            return LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryVariant],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 1:
            return LinearGradient(
                colors: [AppTheme.secondaryAccent, AppTheme.secondaryAccentVariant],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [
                    AppTheme.secondaryTextColor(for: colorScheme).opacity(0.48),
                    AppTheme.secondaryTextColor(for: colorScheme).opacity(0.28)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
