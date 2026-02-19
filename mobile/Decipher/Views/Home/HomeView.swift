import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var playViewModel = PlayViewModel()
    @StateObject private var settings = AppSettings.shared

    @State private var showPlayView = false
    @State private var buttonPressed = false
    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var showTerms = false
    @State private var playerStats = GameResultsManager.playerStats()
    @State private var isLaunchingTransition = false
    @State private var homeContentOpacity = 1.0
    @State private var showTopBar = false
    @State private var showHero = false
    @State private var showActions = false
    @State private var showHomeContainer = false

    var body: some View {
        ZStack {
            PlayBackgroundView()

            MatrixRainView()
                .opacity(colorScheme == .dark ? 0.36 : 0.42)

            VStack(spacing: 0) {
                HStack {
                    StreakBadge(streak: playerStats.currentStreak)

                    Spacer()

                    Button(action: {
                        if settings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showTerms = true
                        }
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(AppTheme.buttonBackground(for: colorScheme))
                            )
                    }
                }
                .opacity(showTopBar ? 1 : 0)
                .offset(y: showTopBar ? 0 : -14)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 14) {
                    Text("DECIPHER")
                        .font(.system(size: 52, weight: .black))
                        .tracking(2.2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryVariant],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AppTheme.primary.opacity(0.25), radius: 10, x: 0, y: 5)

                    Text("Crack the Daily Topic")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(0.7)
                        .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                }
                .opacity(showHero ? 1 : 0)
                .offset(y: showHero ? 0 : 22)

                Spacer()

                Button(action: handlePlayButton) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .black))
                        Text("PLAY DAILY")
                            .font(.system(size: 20, weight: .bold))
                            .tracking(1.2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(
                        color: AppTheme.primary.opacity(buttonPressed ? 0.25 : 0.4),
                        radius: buttonPressed ? 8 : 16,
                        x: 0,
                        y: buttonPressed ? 3 : 7
                    )
                }
                .opacity(showActions ? 1 : 0)
                .offset(y: showActions ? 0 : 18)
                .scaleEffect(buttonPressed ? 0.98 : 1.0)
                .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    HomeSecondaryButton(
                        title: "How To Play",
                        icon: "questionmark.bubble.fill"
                    ) {
                        if settings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showHowToPlay = true
                        }
                    }

                    HomeSecondaryButton(
                        title: "Settings",
                        icon: "gearshape.fill"
                    ) {
                        if settings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSettings = true
                        }
                    }
                }
                .opacity(showActions ? 1 : 0)
                .offset(y: showActions ? 0 : 18)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                Spacer().frame(height: 34)
            }
            .opacity(showHomeContainer ? homeContentOpacity : 0)
            .offset(y: showHomeContainer ? 0 : 16)
            .scaleEffect(showHomeContainer ? 1 : 0.985)
            .blur(radius: showHomeContainer ? 0 : 4)
            .allowsHitTesting(!isLaunchingTransition)

            if showPlayView {
                PlayView(
                    viewModel: playViewModel,
                    showCategoryIntroOnAppear: true,
                    onClose: handlePlayClose
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .overlay {
            if showHowToPlay {
                HowToPlayView(
                    isPresented: $showHowToPlay,
                    resolvedColorScheme: colorScheme
                )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .overlay {
            if showSettings {
                SettingsView(
                    isPresented: $showSettings,
                    resolvedColorScheme: colorScheme
                )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .overlay {
            if showTerms {
                TermsView(
                    isPresented: $showTerms,
                    resolvedColorScheme: colorScheme
                )
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .task {
            playerStats = GameResultsManager.playerStats()
            await playViewModel.fetchDailyTopic()
        }
        .onAppear {
            playerStats = GameResultsManager.playerStats()
            resetLaunchTransitionState()
            runHomeEntranceAnimation()
        }
        .preferredColorScheme(settings.appTheme.colorScheme)
    }

    private func handlePlayButton() {
        guard !isLaunchingTransition else { return }

        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        runLaunchTransitionAndNavigate()

        if playViewModel.topic == nil {
            playViewModel.isLoading = true
            Task {
                await playViewModel.fetchDailyTopic()
            }
        }
    }

    private func runLaunchTransitionAndNavigate() {
        isLaunchingTransition = true

        withAnimation(.easeInOut(duration: 0.1)) {
            buttonPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            buttonPressed = false
        }

        withAnimation(.easeOut(duration: 0.24)) {
            homeContentOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.28)) {
                showPlayView = true
            }
            isLaunchingTransition = false
        }
    }

    private func resetLaunchTransitionState() {
        isLaunchingTransition = false
        homeContentOpacity = 1
    }

    private func handlePlayClose() {
        withAnimation(.easeInOut(duration: 0.28)) {
            showPlayView = false
            homeContentOpacity = 1
        }
    }

    private func runHomeEntranceAnimation() {
        showHomeContainer = false
        showTopBar = false
        showHero = false
        showActions = false

        withAnimation(.easeOut(duration: 0.32)) {
            showHomeContainer = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            withAnimation(.easeOut(duration: 0.24)) {
                showTopBar = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                showHero = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showActions = true
            }
        }
    }
}

private struct StreakBadge: View {
    let streak: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.primary)

            Text("\(streak)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textColor(for: colorScheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.buttonBackground(for: colorScheme))
        )
    }
}

private struct HomeSecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(AppTheme.textColor(for: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.buttonBackground(for: colorScheme))
            )
        }
    }
}

#Preview {
    HomeView()
}
