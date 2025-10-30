import SwiftUI

struct PlayView: View {
    @ObservedObject var viewModel: PlayViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            PlayBackgroundView()
            
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        ErrorStateView(errorMessage: error)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Go Back")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.primary)
                                )
                        }
                    }
                } else if let topic = viewModel.topic {
                    PlayContentView(topic: topic, viewModel: viewModel)
                } else {
                    EmptyStateView()
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .gesture(
            DragGesture()
                .onChanged { _ in }
        , including: .all
        )
    }
}

#Preview {
    PlayView(viewModel: PlayViewModel())
}
