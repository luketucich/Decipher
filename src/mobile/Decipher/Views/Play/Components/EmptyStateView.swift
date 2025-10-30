import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("No topic available")
            .font(AppTheme.Fonts.emptyStateText)
            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
    }
}
