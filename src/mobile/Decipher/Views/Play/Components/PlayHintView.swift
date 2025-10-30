import SwiftUI

struct PlayHintView: View {
    let hint: Hint
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(hint.content)
            .font(AppTheme.hintContentFontSize(for: hint.content))
            .foregroundColor(AppTheme.hintTextColor(for: colorScheme))
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, 36)
            .padding(.top, 8)
            .animation(nil, value: hint.order) // Disable animation for content
    }
}
