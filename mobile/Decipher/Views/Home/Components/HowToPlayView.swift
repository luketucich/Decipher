import SwiftUI

struct HowToPlayView: View {
    @Binding var isPresented: Bool
    let resolvedColorScheme: ColorScheme

    var body: some View {
        ZStack {
            AppTheme.modalBackdrop(for: resolvedColorScheme)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    HStack {
                        Text("How To Play")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.textColor(for: resolvedColorScheme))

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textColor(for: resolvedColorScheme))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(AppTheme.buttonBackground(for: resolvedColorScheme))
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        InstructionRow(
                            icon: "target",
                            title: "Objective",
                            description: "Guess the daily answer in as few hints as possible.",
                            resolvedColorScheme: resolvedColorScheme
                        )

                        InstructionRow(
                            icon: "lightbulb.max.fill",
                            title: "Hints",
                            description: "You get 5 hints. Swipe left or right to review unlocked hints.",
                            resolvedColorScheme: resolvedColorScheme
                        )

                        InstructionRow(
                            icon: "forward.end.alt.fill",
                            title: "Skip",
                            description: "Skip consumes a hint. Skips are tracked in stats and share text.",
                            resolvedColorScheme: resolvedColorScheme
                        )

                        InstructionRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Stats",
                            description: "Check community guesses, speed, and skip trends after each game.",
                            resolvedColorScheme: resolvedColorScheme
                        )
                    }

                    Spacer().frame(height: 44)
                }
                .padding(22)
                .frame(maxWidth: .infinity)
                .background(
                    AppTheme.modalSurface(for: resolvedColorScheme)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    let resolvedColorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textColor(for: resolvedColorScheme))

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.secondaryTextColor(for: resolvedColorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
