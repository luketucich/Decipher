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
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatBox(
                    icon: "person.3.fill",
                    label: "Submissions",
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
            
            if let stats = stats, !stats.commonGuesses.isEmpty {
                WordCloudView(guesses: stats.commonGuesses)
            } else if !isLoading {
                EmptyWordCloudView()
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            if isLoading {
                // Skeleton loading animation
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.15),
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: isAnimating ? .leading : .trailing,
                            endPoint: isAnimating ? .trailing : .leading
                        )
                    )
                    .frame(width: 50, height: 20)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                        ) {
                            isAnimating = true
                        }
                    }
            } else {
                Text(value ?? "—")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}

struct EmptyWordCloudView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Guesses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Text("Be the first to play today!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 32)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}
