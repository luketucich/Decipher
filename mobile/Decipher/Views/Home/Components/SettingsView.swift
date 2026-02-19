import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Binding var isPresented: Bool
    let resolvedColorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            AppTheme.modalBackdrop(for: resolvedColorScheme)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("SETTINGS")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(AppTheme.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Text("✕")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    
                    // Settings Options
                    VStack(spacing: 16) {
                        // Haptic Feedback Toggle
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 24)
                            
                            Text("Haptic Feedback")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textColor(for: resolvedColorScheme))
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.hapticsEnabled)
                                .tint(AppTheme.primary)
                        }
                        
                        Divider()
                            .background(AppTheme.primary.opacity(0.2))
                        
                        // Theme Selector
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 24)
                            
                            Text("Theme")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textColor(for: resolvedColorScheme))
                            
                            Spacer()
                            
                            ThemeSegmentedControl(
                                selection: $settings.appTheme,
                                resolvedColorScheme: resolvedColorScheme
                            )
                        }
                    }
                    
                    Spacer()
                        .frame(height: 97)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    AppTheme.modalSurface(for: resolvedColorScheme)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ThemeSegmentedControl: View {
    @Binding var selection: AppSettings.AppTheme
    let resolvedColorScheme: ColorScheme
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private func iconName(for theme: AppSettings.AppTheme) -> String {
        switch theme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "iphone"
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppSettings.AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    if AppSettings.shared.hapticsEnabled {
                        hapticFeedback.impactOccurred()
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = theme
                    }
                }) {
                    Image(systemName: iconName(for: theme))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selection == theme ? .white : AppTheme.secondaryTextColor(for: resolvedColorScheme))
                        .frame(width: 52, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selection == theme ? AppTheme.primary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    resolvedColorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.black.opacity(0.03)
                )
        )
    }
}
