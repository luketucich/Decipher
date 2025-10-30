import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
            .tint(AppTheme.primary)
    }
}
