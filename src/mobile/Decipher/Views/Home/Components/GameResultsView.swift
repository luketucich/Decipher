import SwiftUI

struct GameResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    let result: GameResult
    
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
        result.success ? AppTheme.success : AppTheme.failure
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
        VStack {
            Spacer()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                }
                
                // Stats
                VStack(spacing: 16) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 60))
                        .foregroundColor(statusColor)
                    
                    Text("Answer: \(result.answer)")
                        .font(.system(size: 18, weight: .bold))
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
                    
                    // Visual progress
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { index in
                            Circle()
                                .fill(circleColor(for: index))
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Share Button
                Button(action: shareResults) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share Results")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryVariant],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func circleColor(for index: Int) -> Color {
        if result.success {
            if index == result.attempts {
                return AppTheme.success
            } else if index < result.attempts {
                return AppTheme.failure
            } else {
                return Color.gray.opacity(0.3)
            }
        } else {
            return AppTheme.failure
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
        }
    }
}
