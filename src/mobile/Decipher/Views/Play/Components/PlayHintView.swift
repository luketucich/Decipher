import SwiftUI

struct PlayHintView: View {
    let hint: Hint
    let topicType: String
    @Environment(\.colorScheme) var colorScheme
    
    private var hintIconName: String {
        switch topicType.lowercased() {
        case "category":
            return "tag.fill"
        case "emoji":
            return "face.smiling.inverse"
        case "quote":
            return "quote.opening"
        case "trivia":
            return "lightbulb.fill"
        case "definition":
            return "text.book.closed.fill"
        default:
            return "lightbulb.fill"
        }
    }
    
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon and hint type
            VStack(spacing: 8) {
                Image(systemName: hintIconName)
                    .font(AppTheme.Fonts.hintIcon)
                    .foregroundColor(AppTheme.primary)
                
                Text(topicType.uppercased())
                    .font(AppTheme.Fonts.hintType)
                    .tracking(1.2)
                    .foregroundColor(AppTheme.hintTypeColor())
            }
            
            // Hint content
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
}
