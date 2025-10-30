import SwiftUI

struct PlayBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient - adapts to color scheme
            LinearGradient(
                colors: AppTheme.backgroundGradientColors(for: colorScheme),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            Circle()
                .fill(AppTheme.primary.opacity(AppTheme.decorativeOpacity1(for: colorScheme)))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -150, y: -250)
            
            Circle()
                .fill(AppTheme.primaryVariant.opacity(AppTheme.decorativeOpacity2(for: colorScheme)))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 180, y: 400)
        }
    }
}
