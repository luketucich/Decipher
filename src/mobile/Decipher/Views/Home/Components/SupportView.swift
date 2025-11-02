import SwiftUI

struct SupportView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("SUPPORT")
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
                    
                    // Content
                    VStack(spacing: 16) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.primary)
                        
                        Text("Enjoying Decipher?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        Text("If you like the app and want to support development, consider buying me a coffee!")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        Button(action: {
                            if let url = URL(string: "https://buymeacoffee.com/luketucich") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Buy Me a Coffee")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryVariant],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: AppTheme.primary.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    AppTheme.liquidGlass(for: colorScheme)
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
