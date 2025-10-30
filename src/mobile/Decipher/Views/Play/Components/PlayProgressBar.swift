import SwiftUI

struct PlayProgressBar: View {
    let currentHintIndex: Int
    let onBackTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Button(action: onBackTapped) {
                ZStack {
                    Circle()
                        .fill(AppTheme.buttonBackground(for: colorScheme))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chevron.left")
                        .font(AppTheme.Fonts.progressChevron)
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            Spacer()
            
            // Progress bar with segments
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            index < currentHintIndex ?
                            LinearGradient(
                                colors: [
                                    AppTheme.primaryVariant,
                                    AppTheme.primary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [
                                    AppTheme.unfilledProgressColor(for: colorScheme),
                                    AppTheme.unfilledProgressColor(for: colorScheme)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: 180)
            
            Spacer()
            
            // Step counter with background
            Text("\(currentHintIndex)/5")
                .font(AppTheme.Fonts.progressCounter)
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.buttonBackground(for: colorScheme))
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}
