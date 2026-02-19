import SwiftUI

struct GameStatsView: View {
    let stats: GameStats?
    let isLoading: Bool
    @Environment(\.colorScheme) var colorScheme

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }

    private func formatPercentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func formatSkips(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatBox(
                    icon: "person.3.fill",
                    label: "Plays",
                    value: isLoading ? nil : "\(stats?.totalSubmissions ?? 0)",
                    isLoading: isLoading
                )

                StatBox(
                    icon: "clock.fill",
                    label: "Avg Time",
                    value: isLoading ? nil : formatTime(stats?.avgGuessTime ?? 0),
                    isLoading: isLoading
                )

                StatBox(
                    icon: "bolt.fill",
                    label: "Fastest",
                    value: isLoading ? nil : formatTime(stats?.fastestGuessTime ?? 0),
                    isLoading: isLoading
                )
            }

            HStack(spacing: 10) {
                StatBox(
                    icon: "forward.end.alt",
                    label: "Avg Skips",
                    value: isLoading ? nil : formatSkips(stats?.avgSkips ?? 0),
                    isLoading: isLoading
                )

                StatBox(
                    icon: "chart.pie.fill",
                    label: "Skip Rate",
                    value: isLoading ? nil : formatPercentage(stats?.skipRate ?? 0),
                    isLoading: isLoading
                )
            }

            if let stats = stats, !stats.commonGuesses.isEmpty {
                TopGuessesView(guesses: stats.commonGuesses)
            } else if !isLoading {
                EmptyTopGuessesView()
            }
        }
    }
}

struct StatBox: View {
    let icon: String
    let label: String
    let value: String?
    let isLoading: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))

            if isLoading {
                RoundedRectangle(cornerRadius: 5)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.28),
                                Color.gray.opacity(0.12),
                                Color.gray.opacity(0.28)
                            ],
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(width: 48, height: 17)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
                            isAnimating = true
                        }
                    }
            } else {
                Text(value ?? "--")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}

struct EmptyTopGuessesView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Text("Top Guesses")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("No one has guessed yet. Be the pace-setter.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}
