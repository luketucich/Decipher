import SwiftUI
import Combine

struct MatrixRainView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var drops: [MatrixDrop] = []
    @State private var screenWidth: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                
                ForEach(drops) { drop in
                    VStack(spacing: 4) {
                        ForEach(0..<drop.characters.count, id: \.self) { index in
                            Text(drop.characters[index])
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(
                                    AppTheme.primary.opacity(
                                        index == 0 ? 1.0 : max(0.05, Double(drop.characters.count - index) / Double(drop.characters.count) * 0.4)
                                    )
                                )
                        }
                    }
                    .position(x: drop.xPosition, y: drop.yPosition)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onAppear {
                screenWidth = geometry.size.width
                screenHeight = geometry.size.height
                setupDrops()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                screenWidth = newSize.width
                screenHeight = newSize.height
                setupDrops()
            }
            .onReceive(timer) { _ in
                updateDrops()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func setupDrops() {
        guard screenWidth > 0 else { return }
        
        let columnSpacing: CGFloat = 20
        let columnCount = Int(ceil(screenWidth / columnSpacing))
        
        drops = (0..<columnCount).map { index in
            let xPos = (CGFloat(index) * columnSpacing) + (columnSpacing / 2)
            return MatrixDrop(
                id: UUID(),
                xPosition: xPos,
                yPosition: CGFloat.random(in: -screenHeight...0),
                characters: generateRandomCharacters(),
                speed: CGFloat.random(in: 1.5...4.0),
                changeCounter: Int.random(in: 0...120),
                changeInterval: Int.random(in: 30...120)
            )
        }
    }
    
    private func generateRandomCharacters() -> [String] {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*")
        let length = Int.random(in: 12...25)
        return (0..<length).map { _ in String(chars.randomElement()!) }
    }
    
    private func updateDrops() {
        guard screenHeight > 0 else { return }
        
        for index in drops.indices {
            // Move drop down
            drops[index].yPosition += drops[index].speed
            
            // Occasionally change some characters for dynamic effect
            drops[index].changeCounter += 1
            if drops[index].changeCounter >= drops[index].changeInterval {
                drops[index].changeCounter = 0
                let randomIndex = Int.random(in: 0..<drops[index].characters.count)
                let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*")
                drops[index].characters[randomIndex] = String(chars.randomElement()!)
            }
            
            // Reset drop when it goes completely off screen
            let dropHeight = CGFloat(drops[index].characters.count) * 18
            if drops[index].yPosition - dropHeight > screenHeight {
                drops[index].yPosition = -CGFloat.random(in: 100...400)
                drops[index].characters = generateRandomCharacters()
                drops[index].speed = CGFloat.random(in: 1.5...4.0)
                drops[index].changeInterval = Int.random(in: 30...120)
            }
        }
    }
}

struct MatrixDrop: Identifiable {
    let id: UUID
    let xPosition: CGFloat
    var yPosition: CGFloat
    var characters: [String]
    var speed: CGFloat
    var changeCounter: Int
    var changeInterval: Int
}
