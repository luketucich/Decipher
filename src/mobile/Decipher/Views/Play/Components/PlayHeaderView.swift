import SwiftUI

struct PlayHeaderView: View {
    let topicNumber: Int
    let topicType: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text("Daily Decipher #\(topicNumber)")
                .font(AppTheme.Fonts.headerDaily)
                .foregroundColor(AppTheme.primary)
            
            Text(topicType)
                .font(AppTheme.Fonts.headerType)
                .foregroundColor(AppTheme.typeTextColor(for: colorScheme))
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}
