import SwiftUI

struct SupportView: View {
    @Environment(\.colorScheme) var colorScheme
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
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        }
                    }
                    
                    // Content
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.primary)
                        
                        Text("Thanks for playing!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textColor(for: colorScheme))
                        
                        Text("Check out my other projects on GitHub")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if let url = URL(string: "https://github.com/luketucich") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("github.com/luketucich")
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
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 3)
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
