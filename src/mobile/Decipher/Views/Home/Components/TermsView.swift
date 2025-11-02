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
                    Text("TERMS & CONDITIONS")
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Last Updated: \(formattedDate())")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                        
                        Group {
                            sectionTitle("1. Acceptance of Terms")
                            sectionText("By downloading, installing, or using Decipher, you agree to be bound by these Terms and Conditions.")
                            
                            sectionTitle("2. Game Description")
                            sectionText("Decipher is a daily word guessing game where you attempt to guess the topic of the day based on AI-generated hints.")
                            
                            sectionTitle("3. User Conduct")
                            sectionText("You agree not to submit offensive, inappropriate, or explicit content as guesses. We reserve the right to filter and block such content.")
                            
                            sectionTitle("4. Data Collection")
                            sectionText("We collect minimal data including your game attempts, guesses, and completion statistics to improve the game experience. No personal information is collected.")
                            
                            sectionTitle("5. Intellectual Property")
                            sectionText("All content, including game design, hints, and topics, are the property of Decipher and protected by copyright laws.")
                            
                            sectionTitle("6. Disclaimer")
                            sectionText("The game is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the app.")
                            
                            sectionTitle("7. Changes to Terms")
                            sectionText("We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of modified terms.")
                            
                            sectionTitle("8. Contact")
                            sectionText("For questions about these terms, please contact us through our GitHub page.")
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
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}
