import SwiftUI

struct TermsView: View {
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
                    Text("ABOUT")
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
                
                // Quick Links
                HStack(spacing: 12) {
Link(destination: URL(string: "https://github.com/luketucich/Decipher/blob/main/PRIVACY_POLICY.md")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 14))
                            Text("Privacy Policy")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primary)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        if let url = URL(string: "mailto:luketucichios@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                            Text("Support")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 8)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Terms Header
                        Text("TERMS & CONDITIONS")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1)
                            .foregroundColor(AppTheme.primary)
                            .padding(.top, 4)
                        
                        Text("Last Updated: January 15, 2025")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                            .padding(.bottom, 4)
                        
                        Group {
                            sectionTitle("1. Acceptance of Terms")
                            sectionText("By downloading, installing, or using Decipher, you agree to be bound by these Terms and Conditions. If you do not agree, do not use the app.")
                            
                            sectionTitle("2. Game Description")
                            sectionText("Decipher is a daily word guessing game where you attempt to guess the topic of the day based on AI-generated hints.")
                            
                            sectionTitle("3. User Conduct")
                            sectionText("You agree not to submit offensive, inappropriate, or explicit content as guesses. We reserve the right to filter and block such content without notice.")
                            
                            sectionTitle("4. Data Collection & Privacy")
                            sectionText("We collect minimal data: your guesses and game statistics are sent to our servers for game functionality only. No personal information, identifiers, or tracking data is collected. See our Privacy Policy for details.")
                            
                            sectionTitle("5. Intellectual Property")
                            sectionText("All content, including game design, hints, topics, and visual elements, are the property of Decipher and protected by copyright laws. Unauthorized use is prohibited.")
                            
                            sectionTitle("6. License to Use")
                            sectionText("This app is licensed, not sold. We grant you a limited, non-exclusive, non-transferable license to use Decipher for personal entertainment purposes only.")
                            
                            sectionTitle("7. Disclaimer of Warranties")
                            sectionText("The app is provided \"as is\" without warranties of any kind, express or implied. We do not guarantee uninterrupted or error-free operation.")
                            
                            sectionTitle("8. Limitation of Liability")
                            sectionText("We are not liable for any damages, including lost data or lost progress, arising from your use of the app.")
                            
                            sectionTitle("9. Changes to Terms")
                            sectionText("We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of modified terms.")
                            
                            sectionTitle("10. Governing Law")
                            sectionText("These terms are governed by the laws of your jurisdiction. You also agree to Apple's Licensed Application End User License Agreement (EULA).")
                            
                            sectionTitle("11. Contact")
                            sectionText("For questions about these terms, visit our Support page above.")
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: 400)
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
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppTheme.textColor(for: colorScheme))
    }
    
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
    }
    
}
