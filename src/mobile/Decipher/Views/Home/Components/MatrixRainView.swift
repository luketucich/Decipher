import SwiftUI

struct MatrixRainView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var columns: [MatrixColumn] = []
    @State private var displayLink: CADisplayLink?
    
    let columnCount = 12
    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(columns) { column in
                    MatrixColumnView(
                        column: column,
                        characters: characters,
                        colorScheme: colorScheme
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .onAppear {
                setupColumns(width: geometry.size.width, height: geometry.size.height)
                startAnimation(height: geometry.size.height)
            }
            .onDisappear {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
        .ignoresSafeArea()
    }
    
    private func setupColumns(width: CGFloat, height: CGFloat) {
        let columnWidth = width / CGFloat(columnCount)
        columns = (0..<columnCount).map { index in
            MatrixColumn(
                id: UUID(),
                xPosition: CGFloat(index) * columnWidth,
                characters: generateRandomCharacters(),
                speed: Double.random(in: 0.5...1.5),
                offset: Double.random(in: -height...0)
            )
        }
    }
    
    private func generateRandomCharacters() -> [String] {
        (0..<20).map { _ in
            String(characters.randomElement() ?? "A")
        }
    }
    
    private func startAnimation(height: CGFloat) {
        // Use device's maximum refresh rate (120Hz on ProMotion, 60Hz otherwise)
        let link = CADisplayLink(target: TargetProxy {
            withAnimation(.linear(duration: 1/120.0)) {
                for index in columns.indices {
                    columns[index].offset += columns[index].speed * 2
                    
                    if columns[index].offset > height + 200 {
                        columns[index].offset = -200
                        columns[index].characters = generateRandomCharacters()
                    }
                }
            }
        }, selector: #selector(TargetProxy.tick))
        
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
}

// Helper class for CADisplayLink
class TargetProxy {
    private let action: () -> Void
    
    init(_ action: @escaping () -> Void) {
        self.action = action
    }
    
    @objc func tick() {
        action()
    }
}

struct MatrixColumn: Identifiable {
    let id: UUID
    let xPosition: CGFloat
    var characters: [String]
    let speed: Double
    var offset: Double
}

struct MatrixColumnView: View {
    let column: MatrixColumn
    let characters: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<column.characters.count, id: \.self) { index in
                Text(column.characters[index])
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(
                        AppTheme.primary.opacity(
                            index == 0 ? 0.9 : Double(column.characters.count - index) / Double(column.characters.count) * 0.3
                        )
                    )
            }
        }
        .offset(x: column.xPosition, y: column.offset)
    }
}
