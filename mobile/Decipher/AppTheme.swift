import SwiftUI

struct AppTheme {
    // MARK: - Brand Colors (original purple accent)
    static let primary = Color(red: 0.64, green: 0.20, blue: 1.0)
    static let primaryVariant = Color(red: 0.54, green: 0.10, blue: 0.90)
    static let secondaryAccent = Color(red: 0.95, green: 0.25, blue: 0.75)
    static let secondaryAccentVariant = Color(red: 0.90, green: 0.20, blue: 0.60)

    static let successDark = Color(red: 0.00, green: 0.90, blue: 0.60)
    static let successLight = Color(red: 0.00, green: 0.70, blue: 0.45)
    static let failureDark = Color(red: 1.00, green: 0.20, blue: 0.50)
    static let failureLight = Color(red: 0.80, green: 0.15, blue: 0.40)
    static let successVariant = Color(red: 0.00, green: 0.80, blue: 0.50)
    static let failureVariant = Color(red: 0.90, green: 0.10, blue: 0.40)
    static let warningVariant = Color(red: 0.90, green: 0.40, blue: 0.00)
    static let warningDark = Color(red: 1.0, green: 0.50, blue: 0.00)
    static let warningLight = Color(red: 0.90, green: 0.40, blue: 0.00)

    static let backgroundGradientDarkTop = Color(red: 0.08, green: 0.02, blue: 0.15)
    static let backgroundGradientDarkBottom = Color(red: 0.12, green: 0.05, blue: 0.20)
    static let backgroundGradientLightTop = Color(red: 0.95, green: 0.88, blue: 1.0)
    static let backgroundGradientLightBottom = Color(red: 0.88, green: 0.75, blue: 0.98)

    static let hintTextDark = Color(red: 0.90, green: 0.75, blue: 1.0)
    static let hintTextLight = Color(red: 0.40, green: 0.10, blue: 0.60)

    struct Opacity {
        static let decorativeDark1 = 0.18
        static let decorativeLight1 = 0.32
        static let decorativeDark2 = 0.14
        static let decorativeLight2 = 0.23
        static let promptDark = 0.35
        static let promptLight = 0.42
        static let secondaryText = 0.72
        static let typeText = 0.62
        static let unfilledProgressDark = 0.14
        static let unfilledProgressLight = 0.19
        static let buttonBgDark = 0.10
        static let buttonBgLight = 0.70
        static let shadowFocused = 0.26
        static let shadowUnfocused = 0.08
    }

    struct Fonts {
        static let emptyStateText = Font.system(size: 18, weight: .medium)
        static let errorIcon = Font.system(size: 44, weight: .bold)
        static let errorTitle = Font.system(size: 24, weight: .bold)
        static let errorMessage = Font.system(size: 16, weight: .regular)
    }

    // MARK: - Surface Helpers
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
        colorScheme == .dark ? .white.opacity(Opacity.promptDark) : .black.opacity(Opacity.promptLight)
    }

    static func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .primary
    }

    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white.opacity(Opacity.secondaryText)
            : .primary.opacity(Opacity.secondaryText)
    }

    static func typeTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white.opacity(Opacity.typeText)
            : .black.opacity(Opacity.typeText)
    }

    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(Opacity.buttonBgDark)
            : Color.white
    }

    static func buttonBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(Opacity.buttonBgDark)
            : Color.white.opacity(Opacity.buttonBgLight)
    }

    static func unfilledProgressColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white.opacity(Opacity.unfilledProgressDark)
            : .black.opacity(Opacity.unfilledProgressLight)
    }

    static func hintTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? hintTextDark : hintTextLight
    }

    static func successColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? successDark : successLight
    }

    static func failureColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? failureDark : failureLight
    }

    static func warningColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? warningDark : warningLight
    }

    static func shadowOpacity(isFocused: Bool) -> Double {
        isFocused ? Opacity.shadowFocused : Opacity.shadowUnfocused
    }

    // MARK: - Typography Helpers
    static func hintContentFontSize(for content: String) -> Font {
        let length = content.count
        let size: CGFloat

        switch length {
        case 0...6: size = 50
        case 7...12: size = 44
        case 13...20: size = 38
        case 21...30: size = 34
        case 31...40: size = 30
        case 41...52: size = 27
        default: size = 24
        }

        return Font.system(size: size, weight: .semibold)
    }

    // MARK: - Liquid Glass
    static func liquidGlass(for colorScheme: ColorScheme) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .thinMaterial)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark
                                ? Color.white.opacity(0.05)
                                : Color.white.opacity(0.62),
                            colorScheme == .dark
                                ? Color.white.opacity(0.01)
                                : Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.30)
                        : Color.black.opacity(0.10),
                    radius: 10,
                    x: 0,
                    y: 3
                )
        }
    }

    static func modalBackdrop(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.50)
            : Color.black.opacity(0.20)
    }

    static func modalSurface(for colorScheme: ColorScheme) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.10, green: 0.06, blue: 0.17).opacity(0.97)
                        : Color.white.opacity(0.96)
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.06),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.42)
                        : Color.black.opacity(0.12),
                    radius: 14,
                    x: 0,
                    y: 6
                )
        }
    }
}
