import SwiftUI

struct PlayView: View {
    @FocusState private var isInputFocused: Bool
    @StateObject private var viewModel = PlayViewModel()
    
    var body: some View {
        ZStack {
            PlayBackgroundView()
            contentView
        }
        .onTapGesture {
            isInputFocused = false
        }
        .task {
            await viewModel.fetchDailyTopic()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch (viewModel.isLoading, viewModel.topic, viewModel.errorMessage) {
        case (true, _, _):
            LoadingView()
        case (_, _, let error?):
            ErrorStateView(errorMessage: error)
        case (_, let topic?, _):
            PlayContentView(
                topic: topic,
                viewModel: viewModel,
                isInputFocused: $isInputFocused
            )
        default:
            EmptyStateView()
        }
    }
}

#Preview {
    PlayView()
}
