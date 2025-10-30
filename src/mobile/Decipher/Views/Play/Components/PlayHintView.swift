import SwiftUI

struct PlayHintView: View {
    let hint: Hint
    
    @Environment(\.colorScheme) var colorScheme
    
    private var hintIconName: String {
        switch hint.type.lowercased() {
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
            // Icon with integrated hint type
            VStack(spacing: 8) {
                Image(systemName: hintIconName)
                    .font(AppTheme.Fonts.hintIcon)
                    .foregroundColor(AppTheme.primary)
                
                Text(hint.type.uppercased())
                    .font(AppTheme.Fonts.hintType)
                    .tracking(1.2)
                    .foregroundColor(AppTheme.hintTypeColor())
            }
            
            Text(hint.content)
                .font(AppTheme.hintContentFontSize(for: hint.content))
                .foregroundColor(AppTheme.hintTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 36)
        }
    }
}
