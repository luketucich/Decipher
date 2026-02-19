import SwiftUI

struct PlayView: View {
    @ObservedObject var viewModel: PlayViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let showCategoryIntroOnAppear: Bool
    let onClose: (() -> Void)?

    @State private var hasRunEntryAnimation = false
    @State private var showCategoryIntro = false
    @State private var categoryIntroOpacity = 0.0
    @State private var categoryIntroScale: CGFloat = 0.95
    @State private var contentOpacity = 1.0
    
    var body: some View {
        ZStack {
            PlayBackgroundView()
            
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        ErrorStateView(errorMessage: error)
                        
                        Button(action: {
                            closePlayView()
                        }) {
                            Text("Go Back")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppTheme.primary, AppTheme.primaryVariant],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                } else if let topic = viewModel.topic {
                    PlayContentView(
                        topic: topic,
                        viewModel: viewModel,
                        onClose: closePlayView
                    )
                } else {
                    EmptyStateView()
                }
            }
            .opacity(contentOpacity)

            if showCategoryIntro {
                PlayCategoryIntroView(
                    category: (viewModel.topic?.type ?? "Daily Topic"),
                    colorScheme: colorScheme
                )
                .scaleEffect(categoryIntroScale)
                .opacity(categoryIntroOpacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled()
        .onAppear {
            runEntryTransitionIfNeeded()
        }
    }

    init(
        viewModel: PlayViewModel,
        showCategoryIntroOnAppear: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.showCategoryIntroOnAppear = showCategoryIntroOnAppear
        self.onClose = onClose
    }

    private func closePlayView() {
        if let onClose {
            onClose()
            return
        }
        dismiss()
    }

    private func runEntryTransitionIfNeeded() {
        guard showCategoryIntroOnAppear, !hasRunEntryAnimation else {
            contentOpacity = 1
            return
        }

        hasRunEntryAnimation = true
        contentOpacity = 0
        showCategoryIntro = true

        withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
            categoryIntroOpacity = 1
            categoryIntroScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
            withAnimation(.easeInOut(duration: 0.22)) {
                categoryIntroOpacity = 0
                categoryIntroScale = 1.03
            }
            withAnimation(.easeOut(duration: 0.28)) {
                contentOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.08) {
            showCategoryIntro = false
            categoryIntroScale = 0.95
        }
    }
}

#Preview {
    PlayView(viewModel: PlayViewModel())
}

private struct PlayCategoryIntroView: View {
    let category: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))

            Text(category.uppercased())
                .font(.system(size: 32, weight: .black))
                .tracking(1.2)
                .foregroundColor(AppTheme.primary)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.buttonBackground(for: colorScheme))
        )
        .shadow(
            color: AppTheme.primary.opacity(colorScheme == .dark ? 0.35 : 0.18),
            radius: 20,
            x: 0,
            y: 10
        )
        .padding(.horizontal, 24)
    }
}
