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
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.inputBackground(for: colorScheme))
                    .shadow(color: AppTheme.primaryVariant.opacity(AppTheme.shadowOpacity(isFocused: isFocused)), radius: isFocused ? 20 : 12, x: 0, y: 4)
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
