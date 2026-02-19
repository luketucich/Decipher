import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))

            Text("No topic available")
                .font(AppTheme.Fonts.emptyStateText)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
        }
    }
}
