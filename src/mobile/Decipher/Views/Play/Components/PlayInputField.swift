import SwiftUI

struct PlayInputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TextField("", text: $text, prompt: Text("Type your answer...").foregroundColor(AppTheme.promptColor(for: colorScheme)))
            .font(AppTheme.Fonts.inputText)
            .multilineTextAlignment(.center)
            .foregroundColor(AppTheme.textColor(for: colorScheme))
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.inputBackground(for: colorScheme))
                    .shadow(color: AppTheme.primaryVariant.opacity(AppTheme.shadowOpacity(isFocused: isFocused.wrappedValue)), radius: isFocused.wrappedValue ? 20 : 12, x: 0, y: 4)
            )
            .focused(isFocused)
            .submitLabel(.done)
            .onSubmit ({onSubmit()})
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.25), value: isFocused.wrappedValue)
    }
}
