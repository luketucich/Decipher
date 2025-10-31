import SwiftUI

struct GameResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    let result: GameResult
    
    @State private var gameStats: GameStats?
    @State private var isLoadingStats = true
    @State private var showStats = false
    private let apiService = APIService()
    
    private var formattedDuration: String {
        let minutes = result.duration / 60
        let seconds = result.duration % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    private var statusIcon: String {
        result.success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private var statusColor: Color {
        result.success ? AppTheme.successColor(for: colorScheme) : AppTheme.failureColor(for: colorScheme)
    }
    
    private var shareText: String {
        let emojiGrid = (1...5).map { index in
            if result.success {
                if index == result.attempts {
                    return "🟢"  // Winning guess
                } else if index < result.attempts {
                    return "🔴"  // Failed attempts before winning
                } else {
                    return "⚪️"  // Unused hints
                }
            } else {
                return "🔴"  // All failed when lost
            }
        }.joined()
        
        let statusText = result.success ? "Won" : "Lost"
        return """
        Decipher #\(result.topicNumber)
        \(statusText) in \(result.attempts)/5 attempts
        \(emojiGrid)
        Time: \(formattedDuration)
        """
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Text("✕")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                
                // Stats
                VStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 48))
                        .foregroundColor(statusColor)
                    
                    Text(result.answer)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textColor(for: colorScheme))
                    
                    HStack(spacing: 32) {
                        StatItem(
                            icon: "target",
                            label: "Attempts",
                            value: "\(result.attempts)/5"
                        )
                        
                        StatItem(
                            icon: "clock.fill",
                            label: "Time",
                            value: formattedDuration
                        )
                    }
                }
                
                // Stats Toggle Button
                Button(action: {
                    if showStats {
                        // Smooth hide with spring
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showStats = false
                        }
                    } else {
                        // Slide in - slower, more natural
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            showStats = true
                        }
                        // Refetch stats when opening
                        Task {
                            isLoadingStats = true
                            await fetchGameStats()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showStats ? "chevron.up" : "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(showStats ? "Hide Stats" : "Show Game Stats")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.inputBackground(for: colorScheme))
                    )
                }
                
                // Game Stats Section (collapsible)
                if showStats {
                    GameStatsView(stats: gameStats, isLoading: isLoadingStats)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // Share Button
                Button(action: shareResults) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Share Results")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryVariant],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 3)
                }
                
                Spacer()
                    .frame(height: 32)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                AppTheme.liquidGlass(for: colorScheme)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .task {
            await fetchGameStats()
        }
    }
    
    private func circleColor(for index: Int) -> Color {
        if result.success {
            if index == result.attempts {
                return AppTheme.successColor(for: colorScheme)
            } else if index < result.attempts {
                return AppTheme.failureColor(for: colorScheme)
            } else {
                return Color.gray.opacity(0.3)
            }
        } else {
            return AppTheme.failureColor(for: colorScheme)
        }
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
            print("Error fetching game stats: \(error)")
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
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
        }
    }
}
