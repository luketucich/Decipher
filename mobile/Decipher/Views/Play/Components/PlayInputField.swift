import SwiftUI

struct PlayInputField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isDisabled: Bool
    var onSubmit: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(isDisabled ? "" : "Type your answer...")
                .foregroundColor(AppTheme.promptColor(for: colorScheme))
        )
        .font(.system(size: 19, weight: .semibold))
        .multilineTextAlignment(.center)
        .foregroundColor(AppTheme.textColor(for: colorScheme))
        .padding(.vertical, 18)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.inputBackground(for: colorScheme))
            .shadow(
                color: isFocused
                    ? AppTheme.primary.opacity(0.24)
                    : (colorScheme == .dark ? Color.clear : Color.black.opacity(0.04)),
                radius: isFocused ? 14 : 6,
                x: 0,
                y: isFocused ? 5 : 2
            )
        )
        .focused($isFocused)
        .disabled(isDisabled)
        .submitLabel(.done)
        .onSubmit(onSubmit)
        .padding(.horizontal, 28)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .opacity(isDisabled ? 0.55 : 1.0)
    }
}
