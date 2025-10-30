import SwiftUI

struct ErrorStateView: View {
    let errorMessage: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTheme.Fonts.errorIcon)
                .foregroundColor(AppTheme.primary)
            
            Text("Oops!")
                .font(AppTheme.Fonts.errorTitle)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Text(errorMessage)
                .font(AppTheme.Fonts.errorMessage)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
