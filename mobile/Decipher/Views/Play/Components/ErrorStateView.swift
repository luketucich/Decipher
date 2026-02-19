import SwiftUI

struct ErrorStateView: View {
    let errorMessage: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTheme.Fonts.errorIcon)
                .foregroundColor(AppTheme.failureColor(for: colorScheme))
            
            Text("Oops!")
                .font(AppTheme.Fonts.errorTitle)
                .foregroundColor(AppTheme.textColor(for: colorScheme))
            
            Text(errorMessage)
                .font(AppTheme.Fonts.errorMessage)
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.inputBackground(for: colorScheme))
        )
    }
}
