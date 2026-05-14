import SwiftUI
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Color Name Types

/// Defensive enum for color names to prevent string-based anti-patterns
public enum ColorName: String, CaseIterable {
    // Background colors
    case background = "background"
    case backgroundColor = "backgroundColor"
    case systemBackground = "systemBackground"
    case secondaryBackgroundColor = "secondaryBackgroundColor"
    case tertiaryBackgroundColor = "tertiaryBackgroundColor"
    case groupedBackgroundColor = "groupedBackgroundColor"
    case secondaryGroupedBackgroundColor = "secondaryGroupedBackgroundColor"
    case tertiaryGroupedBackgroundColor = "tertiaryGroupedBackgroundColor"
    case cardBackground = "cardBackground"
    
    // Foreground colors
    case foregroundColor = "foregroundColor"
    case secondaryForegroundColor = "secondaryForegroundColor"
    case tertiaryForegroundColor = "tertiaryForegroundColor"
    case quaternaryForegroundColor = "quaternaryForegroundColor"
    case placeholderForegroundColor = "placeholderForegroundColor"
    case separatorColor = "separatorColor"
    case separator = "separator"
    case linkColor = "linkColor"
    case label = "label"
    case secondaryLabel = "secondaryLabel"
    case tertiaryLabel = "tertiaryLabel"
    case quaternaryLabel = "quaternaryLabel"
    
    // System colors
    case blue = "blue"
    case red = "red"
    case green = "green"
    case orange = "orange"
    case yellow = "yellow"
    case purple = "purple"
    case pink = "pink"
    case gray = "gray"
    case black = "black"
    case white = "white"
    case clear = "clear"
    case primary = "primary"
    case secondary = "secondary"
    case accentColor = "accentColor"
    
    // Additional SwiftUI system colors
    case cyan = "cyan"
    case mint = "mint"
    case teal = "teal"
    case indigo = "indigo"
    case brown = "brown"
    
    // System color variants (iOS 13+)
    case systemBlue = "systemBlue"
    case systemRed = "systemRed"
    case systemGreen = "systemGreen"
    case systemOrange = "systemOrange"
    case systemYellow = "systemYellow"
    case systemPurple = "systemPurple"
    case systemPink = "systemPink"
    case systemIndigo = "systemIndigo"
    case systemTeal = "systemTeal"
    case systemMint = "systemMint"
    case systemCyan = "systemCyan"
    case systemBrown = "systemBrown"
    
    // System gray scale
    case systemGray = "systemGray"
    case systemGray2 = "systemGray2"
    case systemGray3 = "systemGray3"
    case systemGray4 = "systemGray4"
    case systemGray5 = "systemGray5"
    case systemGray6 = "systemGray6"
    
    // Fill colors
    case systemFill = "systemFill"
    case secondarySystemFill = "secondarySystemFill"
    case tertiarySystemFill = "tertiarySystemFill"
    case quaternarySystemFill = "quaternarySystemFill"
    
    // Additional semantic colors
    case neutral = "neutral"
    case disabled = "disabled"
    case border = "border"
    case borderSecondary = "borderSecondary"
    case surface = "surface"
    case surfaceElevated = "surfaceElevated"
    
    var displayName: String {
        return self.rawValue
    }
    
    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> ColorName? {
        return ColorName(rawValue: string)
    }
}

// MARK: - Enhanced Platform Color System Extensions

/// Platform-specific color system that provides consistent theming
/// across iOS and macOS while respecting platform design guidelines
public extension Color {

    /// Direct system background color
    /// iOS: systemBackground; macOS: windowBackgroundColor
    /// watchOS: `UIColor.systemBackground` is not in the same shape as iOS (see `ShapeStyleSystem`; tvOS matrix #237, platform-color policy #276);
    /// use a dark canvas so `platformLabel` (`.primary` foreground) contrasts with `platformBackground`.
    static var systemBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(.systemBackground)
        #elseif os(macOS)
        return Color(.windowBackgroundColor)
        #elseif os(watchOS)
        return Color.black
        #else
        return Color.primary
        #endif
    }

    /// Platform background color (alias for systemBackground)
    /// iOS: systemBackground; macOS: windowBackgroundColor
    static var platformBackground: Color {
        return systemBackground
    }

    /// Platform system background color (alias for systemBackground)
    /// iOS: systemBackground; macOS: windowBackgroundColor
    static var platformSystemBackground: Color {
        return systemBackground
    }

    /// Platform secondary background color
    /// iOS: secondarySystemBackground; macOS: controlBackgroundColor
    static var platformSecondaryBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.secondary
        #endif
    }

    /// Platform tertiary background color
    /// iOS: tertiarySystemBackground; macOS: textBackgroundColor
    static var platformTertiaryBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(.tertiarySystemBackground)
        #elseif os(macOS)
        return Color(.textBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }

    /// Platform grouped background color
    /// iOS: systemGroupedBackground; macOS: controlBackgroundColor
    static var platformGroupedBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(.systemGroupedBackground)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.secondary
        #endif
    }

    /// Platform separator color
    /// iOS: separator; macOS: separatorColor
    static var platformSeparator: Color {
        #if os(iOS) || os(visionOS)
        return Color(.separator)
        #elseif os(macOS)
        return Color(.separatorColor)
        #else
        return Color.gray
        #endif
    }

    /// Platform label color
    /// iOS: label; macOS: labelColor
    static var platformLabel: Color {
        #if os(iOS) || os(visionOS)
        return Color(.label)
        #elseif os(macOS)
        return Color(.labelColor)
        #else
        return Color.primary
        #endif
    }

    /// Platform secondary label color
    /// iOS: secondaryLabel; macOS: secondaryLabelColor
    static var platformSecondaryLabel: Color {
        #if os(iOS) || os(visionOS)
        return Color(.secondaryLabel)
        #elseif os(macOS)
        return Color(.secondaryLabelColor)
        #else
        return Color.secondary
        #endif
    }

    /// Platform tertiary label color
    /// iOS: tertiaryLabel; macOS: tertiaryLabelColor
    static var platformTertiaryLabel: Color {
        #if os(iOS) || os(visionOS)
        return Color(.tertiaryLabel)
        #elseif os(macOS)
        return Color(.tertiaryLabelColor)
        #else
        return Color.secondary.opacity(0.6)
        #endif
    }

    /// Platform quaternary label color
    /// iOS: quaternaryLabel; macOS: quaternaryLabelColor
    static var platformQuaternaryLabel: Color {
        #if os(iOS)
        return Color(.quaternaryLabel)
        #elseif os(macOS)
        return Color(.quaternaryLabelColor)
        #else
        return Color.secondary.opacity(0.4)
        #endif
    }

    /// Platform system fill color
    /// iOS: systemFill; macOS: controlColor
    static var platformSystemFill: Color {
        #if os(iOS)
        return Color(.systemFill)
        #elseif os(macOS)
        return Color(.controlColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }

    /// Platform secondary system fill color
    /// iOS: secondarySystemFill; macOS: secondaryControlColor
    static var platformSecondarySystemFill: Color {
        #if os(iOS)
        return Color(.secondarySystemFill)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }

    /// Platform tertiary system fill color
    /// iOS: tertiarySystemFill; macOS: tertiaryControlColor
    static var platformTertiarySystemFill: Color {
        #if os(iOS)
        return Color(.tertiarySystemFill)
        #elseif os(macOS)
        return Color(.controlBackgroundColor).opacity(0.8)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }

    /// Platform quaternary system fill color
    /// iOS: quaternarySystemFill; macOS: quaternaryControlColor
    static var platformQuaternarySystemFill: Color {
        #if os(iOS)
        return Color(.quaternarySystemFill)
        #elseif os(macOS)
        return Color(.controlBackgroundColor).opacity(0.6)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }

    /// Platform tint color
    /// iOS: systemBlue; macOS: controlAccentColor
    static var platformTint: Color {
        #if os(iOS)
        return systemBlue
        #elseif os(macOS)
        return Color(.controlAccentColor)
        #else
        return Color.blue
        #endif
    }

    /// Platform destructive color (alias for systemRed)
    /// iOS: systemRed; macOS: systemRed
    static var platformDestructive: Color {
        return systemRed
    }

    /// Platform success color (alias for systemGreen)
    /// iOS: systemGreen; macOS: systemGreen
    static var platformSuccess: Color {
        return systemGreen
    }

    /// Platform warning color (alias for systemOrange)
    /// iOS: systemOrange; macOS: systemOrange
    static var platformWarning: Color {
        return systemOrange
    }

    /// Platform info color (alias for systemBlue)
    /// iOS: systemBlue; macOS: systemBlue
    static var platformInfo: Color {
        return systemBlue
    }
    
    /// Platform system gray6 color
    /// iOS: systemGray6; macOS: controlBackgroundColor
    static var platformSystemGray6: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Platform system gray5 color
    /// iOS: systemGray5; macOS: controlColor
    static var platformSystemGray5: Color {
        #if os(iOS)
        return Color(.systemGray5)
        #elseif os(macOS)
        return Color(.controlColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }
    
    /// Platform system gray4 color
    /// iOS: systemGray4; macOS: controlColor
    static var platformSystemGray4: Color {
        #if os(iOS)
        return Color(.systemGray4)
        #elseif os(macOS)
        return Color(.controlColor)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }
    
    /// Platform system gray3 color
    /// iOS: systemGray3; macOS: controlColor
    static var platformSystemGray3: Color {
        #if os(iOS)
        return Color(.systemGray3)
        #elseif os(macOS)
        return Color(.controlColor)
        #else
        return Color.gray.opacity(0.4)
        #endif
    }
    
    /// Platform system gray2 color
    /// iOS: systemGray2; macOS: controlColor
    static var platformSystemGray2: Color {
        #if os(iOS)
        return Color(.systemGray2)
        #elseif os(macOS)
        return Color(.controlColor)
        #else
        return Color.gray.opacity(0.5)
        #endif
    }
    
    /// Platform system gray color
    /// iOS: systemGray; macOS: systemGray
    static var platformSystemGray: Color {
        #if os(iOS)
        return Color(.systemGray)
        #elseif os(macOS)
        return Color(.systemGray)
        #else
        return Color.gray
        #endif
    }
    
    // MARK: - Direct System Color Properties
    
    /// Direct system blue color
    /// iOS: systemBlue; macOS: systemBlue
    static var systemBlue: Color {
        #if os(iOS)
        return Color(.systemBlue)
        #elseif os(macOS)
        return Color(.systemBlue)
        #else
        return Color.blue
        #endif
    }
    
    /// Direct system red color
    /// iOS: systemRed; macOS: systemRed
    static var systemRed: Color {
        #if os(iOS)
        return Color(.systemRed)
        #elseif os(macOS)
        return Color(.systemRed)
        #else
        return Color.red
        #endif
    }
    
    /// Direct system green color
    /// iOS: systemGreen; macOS: systemGreen
    static var systemGreen: Color {
        #if os(iOS)
        return Color(.systemGreen)
        #elseif os(macOS)
        return Color(.systemGreen)
        #else
        return Color.green
        #endif
    }
    
    /// Direct system orange color
    /// iOS: systemOrange; macOS: systemOrange
    static var systemOrange: Color {
        #if os(iOS)
        return Color(.systemOrange)
        #elseif os(macOS)
        return Color(.systemOrange)
        #else
        return Color.orange
        #endif
    }
    
    /// Direct system yellow color
    /// iOS: systemYellow; macOS: systemYellow
    static var systemYellow: Color {
        #if os(iOS)
        return Color(.systemYellow)
        #elseif os(macOS)
        return Color(.systemYellow)
        #else
        return Color.yellow
        #endif
    }
    
    /// Direct system purple color
    /// iOS: systemPurple; macOS: systemPurple
    static var systemPurple: Color {
        #if os(iOS)
        return Color(.systemPurple)
        #elseif os(macOS)
        return Color(.systemPurple)
        #else
        return Color.purple
        #endif
    }
    
    /// Direct system pink color
    /// iOS: systemPink; macOS: systemPink
    static var systemPink: Color {
        #if os(iOS)
        return Color(.systemPink)
        #elseif os(macOS)
        return Color(.systemPink)
        #else
        return Color.pink
        #endif
    }
    
    /// Direct system indigo color
    /// iOS: systemIndigo; macOS: systemIndigo
    static var systemIndigo: Color {
        #if os(iOS)
        return Color(.systemIndigo)
        #elseif os(macOS)
        return Color(.systemIndigo)
        #else
        return Color.indigo
        #endif
    }
    
    /// Direct system teal color
    /// iOS: systemTeal; macOS: systemTeal
    static var systemTeal: Color {
        #if os(iOS)
        return Color(.systemTeal)
        #elseif os(macOS)
        return Color(.systemTeal)
        #else
        return Color.teal
        #endif
    }
    
    /// Direct system mint color
    /// iOS: systemMint; macOS: systemMint
    static var systemMint: Color {
        #if os(iOS)
        return Color(.systemMint)
        #elseif os(macOS)
        return Color(.systemMint)
        #else
        return Color.mint
        #endif
    }
    
    /// Direct system cyan color
    /// iOS: systemCyan; macOS: systemCyan
    static var systemCyan: Color {
        #if os(iOS)
        return Color(.systemCyan)
        #elseif os(macOS)
        return Color(.systemCyan)
        #else
        return Color.cyan
        #endif
    }
    
    /// Direct system brown color
    /// iOS: systemBrown; macOS: systemBrown
    static var systemBrown: Color {
        #if os(iOS)
        return Color(.systemBrown)
        #elseif os(macOS)
        return Color(.systemBrown)
        #else
        return Color.brown
        #endif
    }
    
    /// Direct system gray color
    /// iOS: systemGray; macOS: systemGray
    static var systemGray: Color {
        return platformSystemGray
    }
    
    /// Direct system gray2 color
    /// iOS: systemGray2; macOS: controlColor
    static var systemGray2: Color {
        return platformSystemGray2
    }
    
    /// Direct system gray3 color
    /// iOS: systemGray3; macOS: controlColor
    static var systemGray3: Color {
        return platformSystemGray3
    }
    
    /// Direct system gray4 color
    /// iOS: systemGray4; macOS: controlColor
    static var systemGray4: Color {
        return platformSystemGray4
    }
    
    /// Direct system gray5 color
    /// iOS: systemGray5; macOS: controlColor
    static var systemGray5: Color {
        return platformSystemGray5
    }
    
    /// Direct system gray6 color
    /// iOS: systemGray6; macOS: controlBackgroundColor
    static var systemGray6: Color {
        return platformSystemGray6
    }
    
    /// Direct system fill color
    /// iOS: systemFill; macOS: controlColor
    static var systemFill: Color {
        return platformSystemFill
    }
    
    /// Direct secondary system fill color
    /// iOS: secondarySystemFill; macOS: secondaryControlColor
    static var secondarySystemFill: Color {
        return platformSecondarySystemFill
    }
    
    /// Direct tertiary system fill color
    /// iOS: tertiarySystemFill; macOS: tertiaryControlColor
    static var tertiarySystemFill: Color {
        return platformTertiarySystemFill
    }
    
    /// Direct quaternary system fill color
    /// iOS: quaternarySystemFill; macOS: quaternaryControlColor
    static var quaternarySystemFill: Color {
        return platformQuaternarySystemFill
    }
    
    /// Platform secondary background color (alias for existing)
    static var secondaryBackground: Color {
        return platformSecondaryBackground
    }
    
    /// Platform tertiary background color
    static var tertiaryBackground: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #elseif os(macOS)
        return Color(.controlBackgroundColor).opacity(0.5)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Platform primary background color (alias for existing)
    static var primaryBackground: Color {
        return platformBackground
    }
    
    /// Platform card background color
    static var cardBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Platform grouped background color
    static var groupedBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #elseif os(macOS)
        return Color(.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }
    
    /// Platform separator color
    static var separator: Color {
        #if os(iOS)
        return Color(.separator)
        #elseif os(macOS)
        return Color(.separatorColor)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }
    
    /// Platform label color
    static var label: Color {
        #if os(iOS)
        return Color(.label)
        #elseif os(macOS)
        return Color(.labelColor)
        #else
        return Color.primary
        #endif
    }
    
    /// Platform secondary label color
    static var secondaryLabel: Color {
        #if os(iOS)
        return Color(.secondaryLabel)
        #elseif os(macOS)
        return Color(.secondaryLabelColor)
        #else
        return Color.secondary
        #endif
    }
    
    // MARK: - Additional Cross-Platform Colors (Feature Request)
    
    /// Cross-platform primary label color (alias for existing platformLabel)
    static var platformPrimaryLabel: Color {
        return platformLabel
    }
    
    /// Cross-platform placeholder text color
    /// iOS: placeholderText; macOS: placeholderTextColor
    static var platformPlaceholderText: Color {
        #if os(iOS)
        return Color(.placeholderText)
        #elseif os(macOS)
        return Color(.placeholderTextColor)
        #else
        return Color.secondary.opacity(0.6)
        #endif
    }
    
    /// Cross-platform opaque separator color
    /// iOS: opaqueSeparator; macOS: separatorColor
    static var platformOpaqueSeparator: Color {
        #if os(iOS)
        return Color(.opaqueSeparator)
        #elseif os(macOS)
        return Color(.separatorColor)
        #else
        return Color.gray.opacity(0.5)
        #endif
    }
    
    /// Cross-platform button text color for use on colored backgrounds
    /// Provides high-contrast text color that adapts to accessibility settings
    /// iOS: White (adapts to high contrast mode when enabled)
    /// macOS: White (system colors automatically adapt)
    /// This color is designed for text placed on colored button backgrounds (primary, destructive, etc.)
    /// Note: White provides maximum contrast on colored backgrounds and is appropriate for both normal and high contrast modes
    static var platformButtonTextOnColor: Color {
        // White provides maximum contrast on colored backgrounds
        // In high contrast mode, the system may adjust background colors, but white text remains optimal
        return Color.white
    }
    
    /// Cross-platform shadow color for overlays and elevation
    /// Provides platform-appropriate shadow colors that adapt to accessibility settings
    /// iOS: Black with platform-appropriate opacity
    /// macOS: Black with platform-appropriate opacity
    /// This color is designed for shadows, overlays, and elevation effects
    static var platformShadowColor: Color {
        #if os(iOS)
        // iOS: Use black with standard shadow opacity
        // In high contrast mode, shadows may be adjusted by the system
        return Color.black.opacity(0.1)
        #elseif os(macOS)
        // macOS: Lighter shadow for subtle elevation
        return Color.black.opacity(0.05)
        #elseif os(tvOS)
        // tvOS: More pronounced shadows for TV viewing distance
        return Color.black.opacity(0.2)
        #elseif os(visionOS)
        // visionOS: Moderate shadows for spatial computing
        return Color.black.opacity(0.15)
        #else
        // Other platforms: Standard shadow
        return Color.black.opacity(0.1)
        #endif
    }
    
    // MARK: - Business Logic Color Aliases
    
    /// Background color alias for business logic
    /// Maps to platform background color
    static var backgroundColor: Color {
        return platformBackground
    }
    
    /// Secondary background color alias for business logic
    /// Maps to platform secondary background color
    static var secondaryBackgroundColor: Color {
        return platformSecondaryBackground
    }
    
    /// Tertiary background color alias for business logic
    /// Maps to platform tertiary background color
    static var tertiaryBackgroundColor: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #elseif os(macOS)
        return Color(.textBackgroundColor)
        #else
        return Color.gray
        #endif
    }
    
    /// Grouped background color alias for business logic
    /// Maps to platform grouped background color
    static var groupedBackgroundColor: Color {
        return platformGroupedBackground
    }
    
    /// Secondary grouped background color alias for business logic
    /// Maps to platform secondary grouped background color
    static var secondaryGroupedBackgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(.textBackgroundColor)
        #else
        return Color.gray
        #endif
    }
    
    /// Tertiary grouped background color alias for business logic
    /// Maps to platform tertiary grouped background color
    static var tertiaryGroupedBackgroundColor: Color {
        #if os(iOS)
        return Color(.tertiarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return Color.gray
        #endif
    }
    
    /// Foreground color alias for business logic
    /// Maps to platform label color
    static var foregroundColor: Color {
        return platformLabel
    }
    
    /// Secondary foreground color alias for business logic
    /// Maps to platform secondary label color
    static var secondaryForegroundColor: Color {
        return platformSecondaryLabel
    }
    
    /// Tertiary foreground color alias for business logic
    /// Maps to platform tertiary label color
    static var tertiaryForegroundColor: Color {
        return platformTertiaryLabel
    }
    
    /// Quaternary foreground color alias for business logic
    /// Maps to platform quaternary label color
    static var quaternaryForegroundColor: Color {
        return platformQuaternaryLabel
    }
    
    /// Placeholder foreground color alias for business logic
    /// Maps to platform placeholder text color
    static var placeholderForegroundColor: Color {
        return platformPlaceholderText
    }
    
    /// Separator color alias for business logic
    /// Maps to platform separator color
    static var separatorColor: Color {
        return platformSeparator
    }
    
    /// Link color alias for business logic
    /// Maps to platform link color
    static var linkColor: Color {
        #if os(iOS)
        return Color(.link)
        #elseif os(macOS)
        return Color(.linkColor)
        #else
        return Color.blue
        #endif
    }
    
    // MARK: - Custom Color Resolution
    
    /// Resolves a color by name for business logic
    /// Supports both system colors and custom color names
    static func named(_ colorName: String?) -> Color? {
        guard let colorName = colorName, !colorName.isEmpty else { return nil }
        
        // Use enum-based approach instead of string matching
        guard let colorNameEnum = ColorName(rawValue: colorName) else {
            // Unknown color name - log for debugging but don't crash
            print("Warning: Unknown color name '\(colorName)', returning nil")
            return nil
        }
        
        // Map business logic color names to platform colors using enum
        switch colorNameEnum {
        case .background:
            return backgroundColor
        case .backgroundColor:
            return backgroundColor
        case .systemBackground:
            return systemBackground
        case .secondaryBackgroundColor:
            return secondaryBackgroundColor
        case .tertiaryBackgroundColor:
            return tertiaryBackgroundColor
        case .groupedBackgroundColor:
            return groupedBackgroundColor
        case .secondaryGroupedBackgroundColor:
            return secondaryGroupedBackgroundColor
        case .tertiaryGroupedBackgroundColor:
            return tertiaryGroupedBackgroundColor
        case .cardBackground:
            return cardBackground
        case .foregroundColor:
            return foregroundColor
        case .secondaryForegroundColor:
            return secondaryForegroundColor
        case .tertiaryForegroundColor:
            return tertiaryForegroundColor
        case .quaternaryForegroundColor:
            return quaternaryForegroundColor
        case .placeholderForegroundColor:
            return placeholderForegroundColor
        case .separatorColor:
            return separatorColor
        case .separator:
            return separator
        case .linkColor:
            return linkColor
        case .label:
            return label
        case .secondaryLabel:
            return secondaryLabel
        case .tertiaryLabel:
            return platformTertiaryLabel
        case .quaternaryLabel:
            return platformQuaternaryLabel
        // System colors
        case .blue:
            return Color.blue
        case .red:
            return Color.red
        case .green:
            return Color.green
        case .orange:
            return Color.orange
        case .yellow:
            return Color.yellow
        case .purple:
            return Color.purple
        case .pink:
            return Color.pink
        case .gray:
            return Color.gray
        case .black:
            return Color.black
        case .white:
            return Color.white
        case .clear:
            return Color.clear
        case .primary:
            return Color.primary
        case .secondary:
            return Color.secondary
        case .accentColor:
            return Color.accentColor
        // Additional SwiftUI system colors
        case .cyan:
            return Color.cyan
        case .mint:
            return Color.mint
        case .teal:
            return Color.teal
        case .indigo:
            return Color.indigo
        case .brown:
            return Color.brown
        // System color variants
        case .systemBlue:
            return systemBlue
        case .systemRed:
            return systemRed
        case .systemGreen:
            return systemGreen
        case .systemOrange:
            return systemOrange
        case .systemYellow:
            return systemYellow
        case .systemPurple:
            return systemPurple
        case .systemPink:
            return systemPink
        case .systemIndigo:
            return systemIndigo
        case .systemTeal:
            return systemTeal
        case .systemMint:
            return systemMint
        case .systemCyan:
            return systemCyan
        case .systemBrown:
            return systemBrown
        // System gray scale
        case .systemGray:
            return systemGray
        case .systemGray2:
            return systemGray2
        case .systemGray3:
            return systemGray3
        case .systemGray4:
            return systemGray4
        case .systemGray5:
            return systemGray5
        case .systemGray6:
            return systemGray6
        // Fill colors
        case .systemFill:
            return systemFill
        case .secondarySystemFill:
            return secondarySystemFill
        case .tertiarySystemFill:
            return tertiarySystemFill
        case .quaternarySystemFill:
            return quaternarySystemFill
        // Additional semantic colors
        case .neutral:
            return Color.gray
        case .disabled:
            return Color.gray.opacity(0.5)
        case .border:
            return platformSeparator
        case .borderSecondary:
            return platformSeparator.opacity(0.5)
        case .surface:
            return platformSecondaryBackground
        case .surfaceElevated:
            return platformTertiaryBackground
        }
    }
    
    /// Resolves a color by name with a default fallback
    /// Returns the named color if found, otherwise returns the default color
    /// - Parameters:
    ///   - colorName: The name of the color to resolve
    ///   - default: The default color to return if the named color is not found
    /// - Returns: A non-optional Color
    static func named(_ colorName: String?, default: Color) -> Color {
        return named(colorName) ?? `default`
    }

    /// Cross-platform setFill method for graphics contexts
    /// - Parameter context: The graphics context to set fill color on
    func setFill(on context: CGContext) {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let uiColor = UIColor(self)
        context.setFillColor(uiColor.cgColor)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        context.setFillColor(nsColor.cgColor)
        #endif
    }

    /// Cross-platform setFill method that works on any graphics context
    /// Automatically handles platform differences internally
    func setFill() {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let uiColor = UIColor(self)
        uiColor.setFill()
        #elseif os(macOS)
        let nsColor = NSColor(self)
        nsColor.setFill()
        #endif
    }

    /// Cross-platform setStroke method for outlines
    func setStroke() {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let uiColor = UIColor(self)
        uiColor.setStroke()
        #elseif os(macOS)
        let nsColor = NSColor(self)
        nsColor.setStroke()
        #endif
    }

    // MARK: - Platform-Specific Color Access

    /// Platform-specific color accessor
    /// Returns `UIColor` on UIKit-based platforms, `NSColor` on macOS
    var platformColor: Any {
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return UIColor(self)
        #elseif os(macOS)
        return NSColor(self)
        #else
        return self
        #endif
    }

    // MARK: - Alpha and Opacity Methods

    /// Create a color with modified opacity
    /// - Parameter opacity: The opacity value (0.0 to 1.0)
    /// - Returns: A new color with the specified opacity
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }

    /// Create a color with modified alpha
    /// - Parameter alpha: The alpha value (0.0 to 1.0)
    /// - Returns: A new color with the specified alpha
    func withAlpha(_ alpha: Double) -> Color {
        self.opacity(alpha)
    }

    // MARK: - Graphics Context Operations

    /// Set this color as fill and fill a rectangle
    /// - Parameters:
    ///   - rect: The rectangle to fill
    ///   - context: The graphics context to draw in
    func fill(_ rect: CGRect, in context: CGContext) {
        context.saveGState()
        setFill(on: context)
        context.fill(rect)
        context.restoreGState()
    }

    /// Set this color as stroke and stroke a rectangle
    /// - Parameters:
    ///   - rect: The rectangle to stroke
    ///   - context: The graphics context to draw in
    ///   - lineWidth: The stroke width (optional, uses current context width if not specified)
    func stroke(_ rect: CGRect, in context: CGContext, lineWidth: CGFloat? = nil) {
        context.saveGState()
        if let lineWidth = lineWidth {
            context.setLineWidth(lineWidth)
        }
        setStroke()
        context.stroke(rect)
        context.restoreGState()
    }

    /// Set this color as stroke and stroke a path
    /// - Parameters:
    ///   - context: The graphics context to draw in
    ///   - lineWidth: The stroke width (optional)
    func stroke(in context: CGContext, lineWidth: CGFloat? = nil) {
        context.saveGState()
        if let lineWidth = lineWidth {
            context.setLineWidth(lineWidth)
        }
        setStroke()
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Color Manipulation

    /// Create a lighter version of this color
    /// - Parameter amount: How much to lighten (0.0 = no change, 1.0 = white)
    /// - Returns: A lighter version of this color
    func lighter(by amount: Double = 0.2) -> Color {
        #if os(iOS)
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: min(brightness + amount, 1.0), opacity: alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: min(brightness + amount, 1.0), opacity: alpha)
        #else
        return self
        #endif
    }

    /// Create a darker version of this color
    /// - Parameter amount: How much to darken (0.0 = no change, 1.0 = black)
    /// - Returns: A darker version of this color
    func darker(by amount: Double = 0.2) -> Color {
        #if os(iOS)
        let uiColor = UIColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: max(brightness - amount, 0.0), opacity: alpha)
        #elseif os(macOS)
        let nsColor = NSColor(self)
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(hue: hue, saturation: saturation, brightness: max(brightness - amount, 0.0), opacity: alpha)
        #else
        return self
        #endif
    }

    // MARK: - Cross-Platform Rectangle Filling

    /// Fill a rectangle with this color using cross-platform approach
    /// - Parameter rect: The rectangle to fill (can be CGRect or NSRect)
    func fillRect(_ rect: Any) {
        #if os(iOS) || os(tvOS)
        if let cgRect = rect as? CGRect {
            setFill()
            // CGRect doesn't have fill() - we need to use CGContext
            if let context = UIGraphicsGetCurrentContext() {
                context.fill(cgRect)
            }
        }
        #elseif os(macOS)
        if let nsRect = rect as? NSRect {
            setFill()
            nsRect.fill()
        } else if let cgRect = rect as? CGRect {
            // Convert CGRect to NSRect for macOS
            let nsRect = NSRectFromCGRect(cgRect)
            setFill()
            nsRect.fill()
        }
        #endif
    }

    /// Fill a rectangle with this color using CGContext approach (unified)
    /// - Parameters:
    ///   - rect: The rectangle to fill
    ///   - context: The graphics context (optional, uses current if not provided)
    func fillRectangle(_ rect: Any, in context: CGContext? = nil) {
        #if os(iOS) || os(tvOS)
        if let cgRect = rect as? CGRect {
            if let context = context {
                fill(cgRect, in: context)
            } else {
                setFill()
                if let currentContext = UIGraphicsGetCurrentContext() {
                    currentContext.fill(cgRect)
                }
            }
        }
        #elseif os(macOS)
        if let cgRect = rect as? CGRect {
            if let context = context {
                fill(cgRect, in: context)
            } else {
                setFill()
                if let currentContext = NSGraphicsContext.current?.cgContext {
                    currentContext.fill(cgRect)
                }
            }
        } else if let nsRect = rect as? NSRect {
            let cgRect = NSRectToCGRect(nsRect)
            if let context = context {
                fill(cgRect, in: context)
            } else {
                setFill()
                if let currentContext = NSGraphicsContext.current?.cgContext {
                    currentContext.fill(cgRect)
                }
            }
        }
        #endif
    }

    // MARK: - Platform-Agnostic Rectangle Filling


    /// Fill a rectangle with this color using size only (origin defaults to .zero)
    /// - Parameters:
    ///   - size: The size of the rectangle to fill
    ///   - context: The graphics context (optional, uses current if not provided)
    func fillRect(size: CGSize, in context: Any? = nil) {
        #if os(iOS) || os(tvOS)
        let rect = CGRect(origin: .zero, size: size)
        if let rendererContext = context as? UIGraphicsImageRendererContext {
            fill(rect, in: rendererContext.cgContext)
        } else {
            setFill()
            if let currentContext = UIGraphicsGetCurrentContext() {
                currentContext.fill(rect)
            }
        }
        #elseif os(macOS)
        let rect = CGRect(origin: .zero, size: size)
        if let context = context {
            fill(rect, in: context as! CGContext)
        } else {
            setFill()
            if let currentContext = NSGraphicsContext.current?.cgContext {
                currentContext.fill(rect)
            }
        }
        #endif
    }

    /// Fill the entire current graphics context bounds with this color
    /// - Parameter context: The graphics context (optional, uses current if not provided)
    func fillBounds(in context: CGContext? = nil) {
        #if os(iOS) || os(tvOS)
        if let context = context {
            let bounds = context.boundingBoxOfClipPath
            fill(bounds, in: context)
        } else if let currentContext = UIGraphicsGetCurrentContext() {
            let bounds = currentContext.boundingBoxOfClipPath
            fill(bounds, in: currentContext)
        }
        #elseif os(macOS)
        if let context = context {
            let bounds = context.boundingBoxOfClipPath
            fill(bounds, in: context)
        } else if let currentContext = NSGraphicsContext.current?.cgContext {
            let bounds = currentContext.boundingBoxOfClipPath
            fill(bounds, in: currentContext)
        }
        #endif
    }
}

// MARK: - Cross-Platform Rectangle Extensions

/// Cross-platform rectangle type that works with both NSRect and CGRect
public struct PlatformRect {
    #if os(macOS)
    public let nsRect: NSRect
    #else
    public let cgRect: CGRect
    #endif

    public var origin: CGPoint {
        #if os(macOS)
        return CGPoint(x: nsRect.origin.x, y: nsRect.origin.y)
        #else
        return cgRect.origin
        #endif
    }

    public var size: CGSize {
        #if os(macOS)
        return CGSize(width: nsRect.size.width, height: nsRect.size.height)
        #else
        return cgRect.size
        #endif
    }

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        #if os(macOS)
        self.nsRect = NSRect(x: x, y: y, width: width, height: height)
        #else
        self.cgRect = CGRect(x: x, y: y, width: width, height: height)
        #endif
    }

    public init(origin: CGPoint, size: CGSize) {
        #if os(macOS)
        self.nsRect = NSRect(origin: origin, size: size)
        #else
        self.cgRect = CGRect(origin: origin, size: size)
        #endif
    }

    /// Fill this rectangle with a color
    public func fill(with color: Color) {
        #if os(macOS)
        color.fillRectangle(nsRect)
        #else
        color.fillRectangle(cgRect)
        #endif
    }
}

// MARK: - Convenience Extensions for Native Rectangle Types


// MARK: - View Extensions for Platform Colors

public extension View {

    /// Apply platform secondary background color
    /// iOS: secondarySystemBackground; macOS: controlBackgroundColor
    func platformSecondaryBackgroundColor() -> some View {
        self.background(Color.platformSecondaryBackground)
    }

    /// Apply platform grouped background color
    /// iOS: systemGroupedBackground; macOS: controlBackgroundColor
    func platformGroupedBackgroundColor() -> some View {
        self.background(Color.platformGroupedBackground)
    }

    /// Apply platform foreground color
    /// iOS: label; macOS: labelColor
    func platformForegroundColor() -> some View {
        self.foregroundColor(Color.platformLabel)
    }

    /// Apply platform secondary foreground color
    /// iOS: secondaryLabel; macOS: secondaryLabelColor
    func platformSecondaryForegroundColor() -> some View {
        self.foregroundColor(Color.platformSecondaryLabel)
    }

    /// Apply platform tertiary foreground color
    /// iOS: tertiaryLabel; macOS: tertiaryLabelColor
    func platformTertiaryForegroundColor() -> some View {
        self.foregroundColor(Color.platformTertiaryLabel)
    }

    /// Apply platform tint color
    /// iOS: systemBlue; macOS: controlAccentColor
    func platformTintColor() -> some View {
        self.foregroundColor(Color.platformTint)
    }

    /// Apply platform destructive color
    /// iOS: systemRed; macOS: systemRedColor
    func platformDestructiveColor() -> some View {
        self.foregroundColor(Color.platformDestructive)
    }

    /// Apply platform success color
    /// iOS: systemGreen; macOS: systemGreenColor
    func platformSuccessColor() -> some View {
        self.foregroundColor(Color.platformSuccess)
    }

    /// Apply platform warning color
    /// iOS: systemOrange; macOS: systemOrangeColor
    func platformWarningColor() -> some View {
        self.foregroundColor(Color.platformWarning)
    }

    /// Apply platform info color
    /// iOS: systemBlue; macOS: systemBlueColor
    func platformInfoColor() -> some View {
        self.foregroundColor(Color.platformInfo)
    }
}

// MARK: - Material Name Types

/// Defensive enum for material names to prevent string-based anti-patterns
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public enum MaterialName: String, CaseIterable {
    case regularMaterial = "regularMaterial"
    case thinMaterial = "thinMaterial"
    case thickMaterial = "thickMaterial"
    case ultraThinMaterial = "ultraThinMaterial"
    case ultraThickMaterial = "ultraThickMaterial"
    
    var displayName: String {
        return self.rawValue
    }
    
    /// Safe factory method that can't fail at runtime
    static func from(string: String) -> MaterialName? {
        return MaterialName(rawValue: string)
    }
}

// MARK: - Material Extension

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension Material {
    
    /// Resolves a material by name for business logic
    /// Supports SwiftUI semantic material names
    /// Thread-safe and cross-platform
    static func named(_ materialName: String?) -> Material? {
        guard let materialName = materialName, !materialName.isEmpty else { return nil }
        
        // Use enum-based approach instead of string matching
        guard let materialNameEnum = MaterialName(rawValue: materialName) else {
            // Unknown material name - log for debugging but don't crash
            print("Warning: Unknown material name '\(materialName)', returning nil")
            return nil
        }
        
        // Map material names to SwiftUI materials using enum
        switch materialNameEnum {
        case .regularMaterial:
            return .regularMaterial
        case .thinMaterial:
            return .thinMaterial
        case .thickMaterial:
            return .thickMaterial
        case .ultraThinMaterial:
            return .ultraThinMaterial
        case .ultraThickMaterial:
            return .ultraThickMaterial
        }
    }
}
