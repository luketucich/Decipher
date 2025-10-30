import SwiftUI

struct PlayInputField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isDisabled: Bool
    var onSubmit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TextField("", text: $text, prompt: Text(isDisabled ? "" : "Type your answer...").foregroundColor(AppTheme.promptColor(for: colorScheme)))
            .font(AppTheme.Fonts.inputText)
            .multilineTextAlignment(.center)
            .foregroundColor(AppTheme.textColor(for: colorScheme))
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? .ultraThinMaterial : .thinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark 
                                        ? Color.white.opacity(0.04) 
                                        : Color.black.opacity(0.02),
                                    colorScheme == .dark 
                                        ? Color.white.opacity(0.01) 
                                        : Color.black.opacity(0.005)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isFocused 
                                ? AppTheme.primary.opacity(0.6)
                                : (colorScheme == .dark 
                                    ? Color.white.opacity(0.1) 
                                    : Color.black.opacity(0.12)),
                            lineWidth: isFocused ? 2 : 1.5
                        )
                }
                .shadow(
                    color: isFocused 
                        ? AppTheme.primary.opacity(0.3)
                        : (colorScheme == .dark ? Color.clear : Color.black.opacity(0.05)),
                    radius: isFocused ? 20 : 8,
                    x: 0,
                    y: isFocused ? 8 : 2
                )
            )
            .focused($isFocused)
            .disabled(isDisabled)
            .submitLabel(.done)
            .onSubmit(onSubmit)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.25), value: isFocused)
            .opacity(isDisabled ? 0.6 : 1.0)
    }
}
