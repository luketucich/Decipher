import SwiftUI

struct PlayBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: AppTheme.backgroundGradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppTheme.primary.opacity(AppTheme.decorativeOpacity1(for: colorScheme)))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -180, y: -260)

            Circle()
                .fill(AppTheme.primaryVariant.opacity(AppTheme.decorativeOpacity2(for: colorScheme)))
                .frame(width: 300, height: 300)
                .blur(radius: 66)
                .offset(x: 190, y: 360)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(AppTheme.primaryVariant.opacity(colorScheme == .dark ? 0.09 : 0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .rotationEffect(.degrees(28))
                .offset(x: 130, y: -170)
        }
    }
}
