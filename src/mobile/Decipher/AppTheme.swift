import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let primary = Color(red: 0.64, green: 0.20, blue: 1.0)
    static let primaryVariant = Color(red: 0.54, green: 0.10, blue: 0.90)
    static let hintTextDark = Color(red: 0.90, green: 0.75, blue: 1.0)
    static let hintTextLight = Color(red: 0.40, green: 0.10, blue: 0.60)
    static let backgroundGradientDarkTop = Color(red: 0.08, green: 0.02, blue: 0.15)
    static let backgroundGradientDarkBottom = Color(red: 0.12, green: 0.05, blue: 0.20)
    static let backgroundGradientLightTop = Color(red: 0.95, green: 0.88, blue: 1.0)
    static let backgroundGradientLightBottom = Color(red: 0.88, green: 0.75, blue: 0.98)
    // Success colors - vibrant green with purple undertones
    static let success = Color(red: 0.00, green: 0.90, blue: 0.60)
    static let successVariant = Color(red: 0.00, green: 0.80, blue: 0.50)
    // Failure colors - vibrant red with purple undertones
    static let failure = Color(red: 1.00, green: 0.20, blue: 0.50)
    static let failureVariant = Color(red: 0.90, green: 0.10, blue: 0.40)
    
    // MARK: - Opacities
    struct Opacity {
        static let decorativeDark1 = 0.15
        static let decorativeLight1 = 0.25
        static let decorativeDark2 = 0.12
        static let decorativeLight2 = 0.2
        static let promptDark = 0.3
        static let promptLight = 0.5
        static let secondaryText = 0.7
        static let typeText = 0.6
        static let unfilledProgressDark = 0.1
        static let unfilledProgressLight = 0.15
        static let buttonBgDark = 0.08
        static let buttonBgLight = 0.6
        static let hintType = 0.7
        static let shadowFocused = 0.3
        static let shadowUnfocused = 0.1
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let emptyStateText = Font.system(size: 18, weight: .medium)
        static let inputText = Font.system(size: 18, weight: .medium)
        static let errorIcon = Font.system(size: 48)
        static let errorTitle = Font.system(size: 24, weight: .bold)
        static let errorMessage = Font.system(size: 16)
        static let hintIcon = Font.system(size: 28, weight: .semibold)
        static let hintType = Font.system(size: 11, weight: .bold)
        static let hintContent = Font.system(size: 28, weight: .semibold)
        static let headerDaily = Font.system(size: 18, weight: .semibold)
        static let headerType = Font.system(size: 15, weight: .medium)
        static let progressChevron = Font.system(size: 16, weight: .semibold)
        static let progressCounter = Font.system(size: 15, weight: .semibold)
    }
    
    // MARK: - Helper Functions
    static func backgroundGradientColors(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark
            ? [backgroundGradientDarkTop, backgroundGradientDarkBottom]
            : [backgroundGradientLightTop, backgroundGradientLightBottom]
    }
    
    static func decorativeOpacity1(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? Opacity.decorativeDark1 : Opacity.decorativeLight1
    }
    
    static func decorativeOpacity2(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? Opacity.decorativeDark2 : Opacity.decorativeLight2
    }
    
    static func promptColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.promptDark) : .gray.opacity(Opacity.promptLight)
    }
    
    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .primary
    }
    
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.secondaryText) : .primary.opacity(Opacity.secondaryText)
    }
    
    static func typeTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.typeText) : .primary.opacity(Opacity.typeText)
    }
    
    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.buttonBgDark) : .white
    }
    
    static func buttonBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.buttonBgDark) : .white.opacity(Opacity.buttonBgLight)
    }
    
    static func unfilledProgressColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white.opacity(Opacity.unfilledProgressDark) : .gray.opacity(Opacity.unfilledProgressLight)
    }
    
    static func hintTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? hintTextDark : hintTextLight
    }
    
    static func shadowOpacity(isFocused: Bool) -> Double {
        isFocused ? Opacity.shadowFocused : Opacity.shadowUnfocused
    }
    
    static func hintTypeColor() -> Color {
        primary.opacity(Opacity.hintType)
    }
    
    // Stepped font sizing every ~5 characters, capped at 52 max and 24 min
    static func hintContentFontSize(for content: String) -> Font {
        let length = content.count
        let size: CGFloat
        
        switch length {
        case 0...4:    size = 52
        case 5...9:    size = 48
        case 10...14:  size = 44
        case 15...19:  size = 40
        case 20...24:  size = 38
        case 25...29:  size = 36
        case 30...34:  size = 34
        case 35...39:  size = 32
        case 40...44:  size = 30
        case 45...49:  size = 28
        case 50...59:  size = 26
        default:       size = 24
        }
        
        return Font.system(size: size, weight: .semibold)
    }
}

