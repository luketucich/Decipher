import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.35)
                .tint(AppTheme.primary)

            Text("Preparing today's puzzle...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}
