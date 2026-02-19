import SwiftUI
import UIKit

struct GameResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    let result: GameResult

    @State private var gameStats: GameStats?
    @State private var isLoadingStats = true
    @State private var showStats = false
    @State private var playerStats = GameResultsManager.playerStats()

    private let apiService = APIService()

    private var formattedDuration: String {
        let minutes = result.duration / 60
        let seconds = result.duration % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    private var statusTitle: String {
        result.success ? "Puzzle Cracked" : "Out of Hints"
    }

    private var statusIcon: String {
        result.success ? "checkmark.seal.fill" : "xmark.octagon.fill"
    }

    private var statusColor: Color {
        result.success ? AppTheme.successColor(for: colorScheme) : AppTheme.failureColor(for: colorScheme)
    }

    private var formattedWinRate: String {
        let percentage = Int((playerStats.winRate * 100).rounded())
        return "\(percentage)%"
    }

    private var shareText: String {
        let emojiGrid = (1...5).map { hintIndex -> String in
            if result.skippedHints.contains(hintIndex) {
                return "🟠"
            }

            if result.success && hintIndex == result.attempts {
                return "🟢"
            }

            if result.failedHints.contains(hintIndex) {
                return "🔴"
            }

            if !result.success && hintIndex <= result.attempts {
                return "🔴"
            }

            return "⚪️"
        }.joined()

        let statusText = result.success ? "Solved" : "Missed"
        let statusEmoji = result.success ? "🟢" : "🔴"
        let hintsLine = result.success
            ? "\(result.attempts)/5 hints"
            : "5/5 hints"
        let skipLabel = result.skips == 1 ? "1 skip" : "\(result.skips) skips"
        let streakValue = max(result.streak, 0)

        return """
        Daily Decipher #\(result.topicNumber)
        \(statusEmoji) \(statusText) in \(hintsLine)
        ⏱ \(formattedDuration) • ⏭ \(skipLabel) • 🔥 \(streakValue)

        \(emojiGrid)
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .onTapGesture {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 16) {
                Capsule()
                    .fill(AppTheme.secondaryTextColor(for: colorScheme).opacity(0.25))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusTitle)
                            .font(.system(size: 23, weight: .bold))
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        Text("Decipher #\(result.topicNumber)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                    Spacer()

                    Image(systemName: statusIcon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(statusColor)
                }

                Text(result.answer)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    ResultMetricPill(label: "Hints", value: "\(result.attempts)/5", icon: "number.circle.fill")
                    ResultMetricPill(label: "Skips", value: "\(result.skips)", icon: "forward.end.alt")
                    ResultMetricPill(label: "Time", value: formattedDuration, icon: "clock.fill")
                }

                HStack(spacing: 10) {
                    ResultMetricPill(label: "Streak", value: "\(max(result.streak, 0))", icon: "flame.fill")
                    ResultMetricPill(label: "Win Rate", value: formattedWinRate, icon: "chart.line.uptrend.xyaxis")
                    ResultMetricPill(
                        label: "Best Time",
                        value: playerStats.bestTime > 0 ? formatTime(playerStats.bestTime) : "--",
                        icon: "bolt.fill"
                    )
                }

                Button(action: {
                    if showStats {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showStats = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                            showStats = true
                        }
                        Task {
                            isLoadingStats = true
                            await fetchGameStats()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showStats ? "chevron.up.circle.fill" : "chart.xyaxis.line")
                            .font(.system(size: 14, weight: .semibold))
                        Text(showStats ? "Hide Community Stats" : "Show Community Stats")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.buttonBackground(for: colorScheme))
                    )
                }

                if showStats {
                    GameStatsView(stats: gameStats, isLoading: isLoadingStats)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                Button(action: shareResults) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Share Results")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: AppTheme.primary.opacity(0.32), radius: 12, x: 0, y: 4)
                }

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
            .background(
                AppTheme.liquidGlass(for: colorScheme)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            playerStats = GameResultsManager.playerStats()
            await fetchGameStats()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        }
        return "\(secs)s"
    }

    private func fetchGameStats() async {
        do {
            let stats = try await apiService.fetchGameStats(topicId: result.topicId)
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.gameStats = stats
                    self.isLoadingStats = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoadingStats = false
            }
        }
    }

    private func shareResults() {
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}

private struct ResultMetricPill: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(AppTheme.buttonBackground(for: colorScheme))
        )
    }
}
