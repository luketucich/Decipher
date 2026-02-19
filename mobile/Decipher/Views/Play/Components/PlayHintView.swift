import SwiftUI

struct PlayHintView: View {
    let hint: Hint
    let topicType: String
    @Environment(\.colorScheme) var colorScheme

    private var hintIconName: String {
        switch topicType.lowercased() {
        case "category":
            return "square.grid.2x2.fill"
        case "emoji":
            return "face.smiling.fill"
        case "quote":
            return "quote.bubble.fill"
        case "trivia":
            return "sparkles"
        case "definition":
            return "book.closed.fill"
        default:
            return "lightbulb.fill"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: hintIconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.primary)

                Text(topicType.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(AppTheme.buttonBackground(for: colorScheme))
            )

            Text(hint.content)
                .font(AppTheme.hintContentFontSize(for: hint.content))
                .foregroundColor(AppTheme.hintTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 26)
                .padding(.vertical, 10)
                .animation(nil, value: hint.order)
        }
    }
}
