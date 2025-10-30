import SwiftUI

struct PlayContentView: View {
    let topic: Topic
    @ObservedObject var viewModel: PlayViewModel
    var isInputFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 0) {
            PlayHeaderView(
                topicNumber: viewModel.topicNumber,
                topicType: topic.type
            )
            
            PlayProgressBar(
                currentHintIndex: viewModel.currentHintIndex,
                onBackTapped: handleBackTapped
            )
            
            Spacer()
            
            if let currentHint = currentHint {
                PlayHintView(hint: currentHint)
            }
            
            Spacer()
            
            PlayInputField(
                text: $viewModel.userGuess,
                isFocused: isInputFocused,
                onSubmit: {
                    if viewModel.currentHintIndex < 5 && !viewModel.userGuess.isEmpty {
                        viewModel.currentHintIndex += 1
                    }
                    viewModel.userGuess = ""
                }
            )
            
            Spacer()
        }
    }
    
    private var currentHint: Hint? {
        topic.hints.first { $0.order == viewModel.currentHintIndex }
    }
    
    private func handleBackTapped() {
        // Handle back navigation
    }
}
