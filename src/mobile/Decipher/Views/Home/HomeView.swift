import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var playViewModel = PlayViewModel()
    @StateObject private var settings = AppSettings.shared
    @State private var navigateToPlay = false
    @State private var buttonPressed = false
    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var showSupport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                PlayBackgroundView()
                
                // Matrix rain effect
                MatrixRainView()
                    .opacity(colorScheme == .dark ? 0.15 : 0.25)
                    .onAppear {
                        // Preload topic to avoid lag on first play
                        Task {
                            await playViewModel.fetchDailyTopic()
                        }
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Title
                    VStack(spacing: 12) {
                        Text("DECIPHER")
                            .font(.system(size: 52, weight: .bold))
                            .tracking(3)
                            .foregroundColor(AppTheme.primary)
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, x: 0, y: 4)
                        
                        Text("Crack the Daily Topic")
                            .font(.system(size: 14, weight: .medium))
                            .tracking(1)
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Play Button
                    Button(action: handlePlayButton) {
                        Text("PLAY")
                            .font(.system(size: 20, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: AppTheme.primary.opacity(buttonPressed ? 0.5 : 0.4), radius: buttonPressed ? 10 : 20, x: 0, y: buttonPressed ? 4 : 8)
                    }
                    .scaleEffect(buttonPressed ? 0.97 : 1.0)
                    .padding(.horizontal, 32)
                    
                    // Bottom buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if settings.hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showHowToPlay = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("How to Play")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? .ultraThinMaterial : .thinMaterial)
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    colorScheme == .dark
                                                        ? AppTheme.primary.opacity(0.15)
                                                        : AppTheme.primary.opacity(0.08),
                                                    colorScheme == .dark
                                                        ? AppTheme.primary.opacity(0.05)
                                                        : AppTheme.primary.opacity(0.03)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: colorScheme == .dark 
                                                    ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                                                    : [Color.black.opacity(0.15), Color.black.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            )
                        }
                        
                        Button(action: {
                            if settings.hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSettings = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                Text("Settings")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primary)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? .ultraThinMaterial : .thinMaterial)
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    colorScheme == .dark
                                                        ? AppTheme.primary.opacity(0.15)
                                                        : AppTheme.primary.opacity(0.08),
                                                    colorScheme == .dark
                                                        ? AppTheme.primary.opacity(0.05)
                                                        : AppTheme.primary.opacity(0.03)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: colorScheme == .dark 
                                                    ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                                                    : [Color.black.opacity(0.15), Color.black.opacity(0.08)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Support button (smaller, less prominent)
                    Button(action: {
                        if settings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSupport = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                            Text("Support")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(AppTheme.primary.opacity(0.7))
                        .padding(.vertical, 10)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .navigationDestination(isPresented: $navigateToPlay) {
                PlayView(viewModel: playViewModel)
            }
            .overlay {
                if showHowToPlay {
                    HowToPlayView(isPresented: $showHowToPlay)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .overlay {
                if showSettings {
                    SettingsView(isPresented: $showSettings)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .overlay {
                if showSupport {
                    SupportView(isPresented: $showSupport)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
        }
        .preferredColorScheme(settings.appTheme.colorScheme)
    }
    
    private func handlePlayButton() {
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            buttonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            buttonPressed = false
            navigateToPlay = true
            
            // Only fetch if we don't have a topic already
            if playViewModel.topic == nil {
                playViewModel.isLoading = true
                Task {
                    await playViewModel.fetchDailyTopic()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
