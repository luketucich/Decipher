import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var settings = AppSettings.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Spacer()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
                
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
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
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
                                .foregroundColor(AppTheme.textColor(for: colorScheme))
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.hapticsEnabled)
                                .tint(AppTheme.primary)
                        }
                        
                        Divider()
                            .background(AppTheme.primary.opacity(0.2))
                        
                        // Theme Selector
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 24)
                                
                                Text("Theme")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                            }
                            
                            HStack(spacing: 10) {
                                ForEach(AppSettings.AppTheme.allCases, id: \.self) { theme in
                                    ThemeButton(
                                        theme: theme,
                                        isSelected: settings.appTheme == theme,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                settings.appTheme = theme
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct ThemeButton: View {
    let theme: AppSettings.AppTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(theme.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppTheme.secondaryTextColor(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppTheme.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isSelected ? Color.clear : AppTheme.primary.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                )
        }
    }
}
