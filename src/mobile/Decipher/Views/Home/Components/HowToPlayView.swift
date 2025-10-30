import SwiftUI

struct HowToPlayView: View {
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
                        Text("HOW TO PLAY")
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
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(
                            icon: "target",
                            title: "Objective",
                            description: "Guess with as few hints as possible"
                        )
                        
                        InstructionRow(
                            icon: "lightbulb.fill",
                            title: "Hints",
                            description: "5 hints. Swipe left/right to navigate"
                        )
                        
                        InstructionRow(
                            icon: "checkmark.circle.fill",
                            title: "Win",
                            description: "Guess correctly on any hint"
                        )
                        
                        InstructionRow(
                            icon: "xmark.circle.fill",
                            title: "Lose",
                            description: "5 wrong guesses and you're out"
                        )
                    }
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

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
