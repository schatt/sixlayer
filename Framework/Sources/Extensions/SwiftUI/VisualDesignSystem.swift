import Foundation
import SwiftUI

// MARK: - Design System Bridge
// Comprehensive theming system that maps external design tokens to SixLayer components

/// Protocol for design system implementations that map design tokens to SixLayer components
public protocol DesignSystem: Sendable {
    /// The name of this design system
    var name: String { get }

    /// Get colors for a specific theme
    func colors(for theme: Theme) -> DesignTokens.Colors

    /// Get typography for a specific theme
    func typography(for theme: Theme) -> DesignTokens.Typography

    /// Get spacing tokens
    func spacing() -> DesignTokens.Spacing

    /// Get component state tokens
    func componentStates() -> DesignTokens.ComponentStates
}

/// Design tokens that can be mapped from external design systems
public struct DesignTokens: Sendable {
    public struct Colors: Sendable {
        // Core semantic colors
        public let primary: Color
        public let secondary: Color
        public let accent: Color
        public let destructive: Color
        public let success: Color
        public let warning: Color
        public let info: Color

        // Surface colors
        public let background: Color
        public let surface: Color
        public let surfaceElevated: Color

        // Text colors
        public let text: Color
        public let textSecondary: Color
        public let textTertiary: Color
        public let textDisabled: Color

        // Interactive states
        public let hover: Color
        public let pressed: Color
        public let focused: Color
        public let disabled: Color

        // Border colors
        public let border: Color
        public let borderSecondary: Color
        public let borderFocus: Color

        // Status colors
        public let error: Color
        public let warningText: Color
        public let successText: Color
        public let infoText: Color

        public init(
            primary: Color,
            secondary: Color,
            accent: Color,
            destructive: Color,
            success: Color,
            warning: Color,
            info: Color,
            background: Color,
            surface: Color,
            surfaceElevated: Color,
            text: Color,
            textSecondary: Color,
            textTertiary: Color,
            textDisabled: Color,
            hover: Color,
            pressed: Color,
            focused: Color,
            disabled: Color,
            border: Color,
            borderSecondary: Color,
            borderFocus: Color,
            error: Color,
            warningText: Color,
            successText: Color,
            infoText: Color
        ) {
            self.primary = primary
            self.secondary = secondary
            self.accent = accent
            self.destructive = destructive
            self.success = success
            self.warning = warning
            self.info = info
            self.background = background
            self.surface = surface
            self.surfaceElevated = surfaceElevated
            self.text = text
            self.textSecondary = textSecondary
            self.textTertiary = textTertiary
            self.textDisabled = textDisabled
            self.hover = hover
            self.pressed = pressed
            self.focused = focused
            self.disabled = disabled
            self.border = border
            self.borderSecondary = borderSecondary
            self.borderFocus = borderFocus
            self.error = error
            self.warningText = warningText
            self.successText = successText
            self.infoText = infoText
        }
    }

    public struct Typography: Sendable {
        public let largeTitle: Font
        public let title1: Font
        public let title2: Font
        public let title3: Font
        public let headline: Font
        public let body: Font
        public let callout: Font
        public let subheadline: Font
        public let footnote: Font
        public let caption1: Font
        public let caption2: Font

        public init(
            largeTitle: Font,
            title1: Font,
            title2: Font,
            title3: Font,
            headline: Font,
            body: Font,
            callout: Font,
            subheadline: Font,
            footnote: Font,
            caption1: Font,
            caption2: Font
        ) {
            self.largeTitle = largeTitle
            self.title1 = title1
            self.title2 = title2
            self.title3 = title3
            self.headline = headline
            self.body = body
            self.callout = callout
            self.subheadline = subheadline
            self.footnote = footnote
            self.caption1 = caption1
            self.caption2 = caption2
        }
    }

    public struct Spacing: Sendable {
        public let xs: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat
        public let xxl: CGFloat

        public init(xs: CGFloat, sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat, xxl: CGFloat) {
            self.xs = xs
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
            self.xxl = xxl
        }
    }

    public struct ComponentStates: Sendable {
        public let cornerRadius: ComponentCornerRadius
        public let borderWidth: ComponentBorderWidth
        public let shadow: ComponentShadow
        public let opacity: ComponentOpacity

        public init(
            cornerRadius: ComponentCornerRadius,
            borderWidth: ComponentBorderWidth,
            shadow: ComponentShadow,
            opacity: ComponentOpacity
        ) {
            self.cornerRadius = cornerRadius
            self.borderWidth = borderWidth
            self.shadow = shadow
            self.opacity = opacity
        }
    }

    public struct ComponentCornerRadius: Sendable {
        public let none: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat
        public let full: CGFloat

        public init(none: CGFloat, sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat, full: CGFloat) {
            self.none = none
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
            self.full = full
        }
    }

    public struct ComponentBorderWidth: Sendable {
        public let none: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat

        public init(none: CGFloat, sm: CGFloat, md: CGFloat, lg: CGFloat) {
            self.none = none
            self.sm = sm
            self.md = md
            self.lg = lg
        }
    }

    public struct ComponentShadow: Sendable {
        public let none: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        public let sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        public let md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        public let lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)

        public init(
            none: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat),
            sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat),
            md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat),
            lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        ) {
            self.none = none
            self.sm = sm
            self.md = md
            self.lg = lg
        }
    }

    public struct ComponentOpacity: Sendable {
        public let disabled: Double
        public let pressed: Double
        public let hover: Double

        public init(disabled: Double, pressed: Double, hover: Double) {
            self.disabled = disabled
            self.pressed = pressed
            self.hover = hover
        }
    }
}

/// Default SixLayer design system implementation
public struct SixLayerDesignSystem: DesignSystem {
    public let name = "SixLayer"

    private let colorTokens: [Theme: DesignTokens.Colors]
    private let typographyTokens: [Theme: DesignTokens.Typography]
    private let spacingTokens: DesignTokens.Spacing
    private let componentStatesTokens: DesignTokens.ComponentStates

    public init(
        colorTokens: [Theme: DesignTokens.Colors]? = nil,
        typographyTokens: [Theme: DesignTokens.Typography]? = nil,
        spacingTokens: DesignTokens.Spacing? = nil,
        componentStatesTokens: DesignTokens.ComponentStates? = nil
    ) {
        self.colorTokens = colorTokens ?? Self.defaultColorTokens()
        self.typographyTokens = typographyTokens ?? Self.defaultTypographyTokens()
        self.spacingTokens = spacingTokens ?? Self.defaultSpacingTokens()
        self.componentStatesTokens = componentStatesTokens ?? Self.defaultComponentStatesTokens()
    }

    public func colors(for theme: Theme) -> DesignTokens.Colors {
        return colorTokens[theme] ?? colorTokens[.light]!
    }

    public func typography(for theme: Theme) -> DesignTokens.Typography {
        return typographyTokens[theme] ?? typographyTokens[.light]!
    }

    public func spacing() -> DesignTokens.Spacing {
        return spacingTokens
    }

    public func componentStates() -> DesignTokens.ComponentStates {
        return componentStatesTokens
    }

    private static func defaultColorTokens() -> [Theme: DesignTokens.Colors] {
        let platform = Self.detectPlatformStyle()

        return [
            .light: Self.createColorsForTheme(.light, platform: platform),
            .dark: Self.createColorsForTheme(.dark, platform: platform)
        ]
    }

    private static func createColorsForTheme(_ theme: Theme, platform: PlatformStyle) -> DesignTokens.Colors {
        let _ = theme == .dark // Reserved for future dark mode enhancements

        // Use platform-appropriate base colors
        let primary = Color.platformTint
        let secondary = Color.platformSecondaryLabel
        let background = Color.platformBackground
        let surface = Color.platformSecondaryBackground

        return DesignTokens.Colors(
            primary: primary,
            secondary: secondary,
            accent: primary.opacity(0.8),
            destructive: Color.platformDestructive,
            success: Color.platformSuccess,
            warning: Color.platformWarning,
            info: Color.platformInfo,
            background: background,
            surface: surface,
            surfaceElevated: surface.opacity(0.9),
            text: Color.platformLabel,
            textSecondary: Color.platformSecondaryLabel,
            textTertiary: Color.platformTertiaryLabel,
            textDisabled: Color.platformQuaternaryLabel,
            hover: primary.opacity(0.1),
            pressed: primary.opacity(0.2),
            focused: primary.opacity(0.3),
            disabled: Color.platformQuaternaryLabel.opacity(0.5),
            border: Color.platformSeparator,
            borderSecondary: Color.platformSeparator.opacity(0.5),
            borderFocus: primary,
            error: Color.platformDestructive,
            warningText: Color.platformWarning,
            successText: Color.platformSuccess,
            infoText: Color.platformInfo
        )
    }

    private static func defaultTypographyTokens() -> [Theme: DesignTokens.Typography] {
        let platform = Self.detectPlatformStyle()
        let accessibility = AccessibilitySettings()

        return [
            .light: Self.createTypographyForTheme(.light, platform: platform, accessibility: accessibility),
            .dark: Self.createTypographyForTheme(.dark, platform: platform, accessibility: accessibility)
        ]
    }

    private static func createTypographyForTheme(_ theme: Theme, platform: PlatformStyle, accessibility: AccessibilitySettings) -> DesignTokens.Typography {
        let scaleFactor = accessibility.typographyScaleFactor

        return DesignTokens.Typography(
            largeTitle: Font.platformLargeTitle.scale(scaleFactor),
            title1: Font.platformTitle.scale(scaleFactor),
            title2: Font.platformTitle2.scale(scaleFactor),
            title3: Font.platformTitle3.scale(scaleFactor),
            headline: Font.platformHeadline.scale(scaleFactor),
            body: Font.platformBody.scale(scaleFactor),
            callout: Font.platformCallout.scale(scaleFactor),
            subheadline: Font.platformSubheadline.scale(scaleFactor),
            footnote: Font.platformFootnote.scale(scaleFactor),
            caption1: Font.platformCaption.scale(scaleFactor),
            caption2: Font.platformCaption2.scale(scaleFactor)
        )
    }

    private static func defaultSpacingTokens() -> DesignTokens.Spacing {
        return DesignTokens.Spacing(
            xs: 4,
            sm: 8,
            md: 16,
            lg: 24,
            xl: 32,
            xxl: 48
        )
    }

    private static func defaultComponentStatesTokens() -> DesignTokens.ComponentStates {
        let platform = Self.detectPlatformStyle()

        let cornerRadius = DesignTokens.ComponentCornerRadius(
            none: 0,
            sm: platform == .ios ? 8 : 6,
            md: platform == .ios ? 12 : 8,
            lg: platform == .ios ? 16 : 12,
            xl: 24,
            full: 999
        )

        let borderWidth = DesignTokens.ComponentBorderWidth(
            none: 0,
            sm: 0.5,
            md: 1,
            lg: 2
        )

        let shadowColor = Color.platformShadowColor
        let shadow = DesignTokens.ComponentShadow(
            none: (color: .clear, radius: 0, x: 0, y: 0),
            sm: (color: shadowColor, radius: 2, x: 0, y: 1),
            md: (color: shadowColor, radius: 4, x: 0, y: 2),
            lg: (color: shadowColor, radius: 8, x: 0, y: 4)
        )

        let opacity = DesignTokens.ComponentOpacity(
            disabled: 0.5,
            pressed: 0.7,
            hover: 0.8
        )

        return DesignTokens.ComponentStates(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            shadow: shadow,
            opacity: opacity
        )
    }

    private static func detectPlatformStyle() -> PlatformStyle {
        #if os(iOS)
        return .ios
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .ios
        #endif
    }
}

/// High contrast design system for accessibility
public struct HighContrastDesignSystem: DesignSystem {
    public let name = "HighContrast"

    private let colorTokens: [Theme: DesignTokens.Colors]
    private let typographyTokens: [Theme: DesignTokens.Typography]
    private let spacingTokens: DesignTokens.Spacing
    private let componentStatesTokens: DesignTokens.ComponentStates

    public init() {
        self.colorTokens = Self.createHighContrastColorTokens()
        self.typographyTokens = Self.createHighContrastTypographyTokens()
        self.spacingTokens = Self.createHighContrastSpacingTokens()
        self.componentStatesTokens = Self.createHighContrastComponentStatesTokens()
    }

    public func colors(for theme: Theme) -> DesignTokens.Colors {
        return colorTokens[theme] ?? colorTokens[.light]!
    }

    public func typography(for theme: Theme) -> DesignTokens.Typography {
        return typographyTokens[theme] ?? typographyTokens[.light]!
    }

    public func spacing() -> DesignTokens.Spacing {
        return spacingTokens
    }

    public func componentStates() -> DesignTokens.ComponentStates {
        return componentStatesTokens
    }

    private static func createHighContrastColorTokens() -> [Theme: DesignTokens.Colors] {
        let lightColors = DesignTokens.Colors(
            primary: Color.black,
            secondary: Color.gray,
            accent: Color.blue,
            destructive: Color.red,
            success: Color.green,
            warning: Color.orange,
            info: Color.blue,
            background: Color.white,
            surface: Color.white,
            surfaceElevated: Color.gray.opacity(0.1),
            text: Color.black,
            textSecondary: Color.gray,
            textTertiary: Color.gray.opacity(0.7),
            textDisabled: Color.gray.opacity(0.5),
            hover: Color.blue.opacity(0.1),
            pressed: Color.blue.opacity(0.2),
            focused: Color.blue,
            disabled: Color.gray.opacity(0.3),
            border: Color.black,
            borderSecondary: Color.gray,
            borderFocus: Color.blue,
            error: Color.red,
            warningText: Color.orange,
            successText: Color.green,
            infoText: Color.blue
        )

        let darkColors = DesignTokens.Colors(
            primary: Color.white,
            secondary: Color.gray,
            accent: Color.cyan,
            destructive: Color.red,
            success: Color.green,
            warning: Color.yellow,
            info: Color.cyan,
            background: Color.black,
            surface: Color.black,
            surfaceElevated: Color.gray.opacity(0.2),
            text: Color.white,
            textSecondary: Color.gray,
            textTertiary: Color.gray.opacity(0.7),
            textDisabled: Color.gray.opacity(0.5),
            hover: Color.cyan.opacity(0.1),
            pressed: Color.cyan.opacity(0.2),
            focused: Color.cyan,
            disabled: Color.gray.opacity(0.3),
            border: Color.white,
            borderSecondary: Color.gray,
            borderFocus: Color.cyan,
            error: Color.red,
            warningText: Color.yellow,
            successText: Color.green,
            infoText: Color.cyan
        )

        return [.light: lightColors, .dark: darkColors]
    }

    private static func createHighContrastTypographyTokens() -> [Theme: DesignTokens.Typography] {
        let _ = Self.detectPlatformStyle() // Reserved for future platform-specific typography
        let accessibility = AccessibilitySettings()
        let scaleFactor = accessibility.typographyScaleFactor

        // High contrast typography - bolder weights for better readability
        let baseTypography = DesignTokens.Typography(
            largeTitle: Font.platformLargeTitle.weight(.black).scale(scaleFactor),
            title1: Font.platformTitle.weight(.black).scale(scaleFactor),
            title2: Font.platformTitle2.weight(.black).scale(scaleFactor),
            title3: Font.platformTitle3.weight(.bold).scale(scaleFactor),
            headline: Font.platformHeadline.weight(.bold).scale(scaleFactor),
            body: Font.platformBody.weight(.semibold).scale(scaleFactor),
            callout: Font.platformCallout.weight(.semibold).scale(scaleFactor),
            subheadline: Font.platformSubheadline.weight(.semibold).scale(scaleFactor),
            footnote: Font.platformFootnote.weight(.semibold).scale(scaleFactor),
            caption1: Font.platformCaption.weight(.semibold).scale(scaleFactor),
            caption2: Font.platformCaption2.weight(.semibold).scale(scaleFactor)
        )

        return [.light: baseTypography, .dark: baseTypography]
    }

    private static func createHighContrastSpacingTokens() -> DesignTokens.Spacing {
        // Slightly larger spacing for high contrast
        return DesignTokens.Spacing(
            xs: 6,
            sm: 10,
            md: 18,
            lg: 28,
            xl: 36,
            xxl: 52
        )
    }

    private static func createHighContrastComponentStatesTokens() -> DesignTokens.ComponentStates {
        let platform = Self.detectPlatformStyle()

        let cornerRadius = DesignTokens.ComponentCornerRadius(
            none: 0,
            sm: platform == .ios ? 6 : 4,
            md: platform == .ios ? 10 : 6,
            lg: platform == .ios ? 14 : 10,
            xl: 20,
            full: 999
        )

        let borderWidth = DesignTokens.ComponentBorderWidth(
            none: 0,
            sm: 1,
            md: 2,
            lg: 3
        )

        let shadowColor = Color.black
        let shadow = DesignTokens.ComponentShadow(
            none: (color: .clear, radius: 0, x: 0, y: 0),
            sm: (color: shadowColor, radius: 4, x: 0, y: 2),
            md: (color: shadowColor, radius: 8, x: 0, y: 4),
            lg: (color: shadowColor, radius: 16, x: 0, y: 8)
        )

        let opacity = DesignTokens.ComponentOpacity(
            disabled: 0.4,
            pressed: 0.6,
            hover: 0.7
        )

        return DesignTokens.ComponentStates(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            shadow: shadow,
            opacity: opacity
        )
    }

    private static func detectPlatformStyle() -> PlatformStyle {
        #if os(iOS)
        return .ios
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .ios
        #endif
    }
}

/// Example of how to create a custom design system from external design tokens
public struct CustomDesignSystem: DesignSystem {
    public let name: String
    private let colorTokens: [Theme: DesignTokens.Colors]
    private let typographyTokens: [Theme: DesignTokens.Typography]
    private let spacingTokens: DesignTokens.Spacing
    private let componentStatesTokens: DesignTokens.ComponentStates

    /// Initialize with design tokens from an external source (Figma, JSON, etc.)
    /// - Parameters:
    ///   - name: Name of the design system
    ///   - colorTokens: Color tokens for different themes
    ///   - typographyTokens: Typography tokens for different themes
    ///   - spacingTokens: Spacing tokens
    ///   - componentStatesTokens: Component state tokens
    public init(
        name: String,
        colorTokens: [Theme: DesignTokens.Colors],
        typographyTokens: [Theme: DesignTokens.Typography],
        spacingTokens: DesignTokens.Spacing,
        componentStatesTokens: DesignTokens.ComponentStates
    ) {
        self.name = name
        self.colorTokens = colorTokens
        self.typographyTokens = typographyTokens
        self.spacingTokens = spacingTokens
        self.componentStatesTokens = componentStatesTokens
    }

    public func colors(for theme: Theme) -> DesignTokens.Colors {
        return colorTokens[theme] ?? colorTokens[.light] ?? SixLayerDesignSystem().colors(for: theme)
    }

    public func typography(for theme: Theme) -> DesignTokens.Typography {
        return typographyTokens[theme] ?? typographyTokens[.light] ?? SixLayerDesignSystem().typography(for: theme)
    }

    public func spacing() -> DesignTokens.Spacing {
        return spacingTokens
    }

    public func componentStates() -> DesignTokens.ComponentStates {
        return componentStatesTokens
    }

    /// Convenience initializer for creating from a design token dictionary
    /// This shows how to map external design tokens (from Figma, JSON, etc.) to SixLayer
    public static func fromDesignTokenDictionary(
        name: String,
        tokens: [String: Any]
    ) -> CustomDesignSystem {
        // This is an example of how you might parse external design tokens
        // In practice, you'd implement parsing logic for your specific token format

        // Example token structure you might get from Figma or design system JSON:
        // {
        //   "colors": {
        //     "light": {
        //       "primary": "#007AFF",
        //       "background": "#FFFFFF",
        //       ...
        //     },
        //     "dark": {
        //       "primary": "#0A84FF",
        //       "background": "#000000",
        //       ...
        //     }
        //   },
        //   "typography": {
        //     "body": { "size": 16, "weight": "regular" },
        //     ...
        //   },
        //   "spacing": {
        //     "sm": 8,
        //     ...
        //   }
        // }

        // For now, return a default implementation
        // You'd implement the actual parsing logic here
        let defaultDesignSystem = SixLayerDesignSystem()

        return CustomDesignSystem(
            name: name,
            colorTokens: [
                .light: defaultDesignSystem.colors(for: .light),
                .dark: defaultDesignSystem.colors(for: .dark)
            ],
            typographyTokens: [
                .light: defaultDesignSystem.typography(for: .light),
                .dark: defaultDesignSystem.typography(for: .dark)
            ],
            spacingTokens: defaultDesignSystem.spacing(),
            componentStatesTokens: defaultDesignSystem.componentStates()
        )
    }
}

// MARK: - Visual Design System
// Comprehensive theming system for cross-platform UI consistency

/// Central theme manager for the SixLayer Framework
@MainActor
public class VisualDesignSystem: ObservableObject {
    public static let shared = VisualDesignSystem()

    @Published public var currentTheme: Theme
    @Published public var platformStyle: PlatformStyle
    @Published public var accessibilitySettings: AccessibilitySettings
    @Published public var designSystem: DesignSystem

    /// Theme change callback - called when theme changes
    public var onThemeChange: (() -> Void)?

    /// Previous theme for change detection
    private var previousTheme: Theme = .light
    
    private init() {
        self.currentTheme = Self.detectSystemTheme()
        self.platformStyle = Self.detectPlatformStyle()
        self.accessibilitySettings = Self.detectAccessibilitySettings()
        self.designSystem = SixLayerDesignSystem()
        self.previousTheme = self.currentTheme

        // Listen for system theme changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSAppearanceChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTheme()
            }
        }

        // Listen for iOS theme changes
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIScreen.modeDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTheme()
            }
        }
        #endif
    }

    /// Initialize with a custom design system
    public init(designSystem: DesignSystem) {
        self.currentTheme = Self.detectSystemTheme()
        self.platformStyle = Self.detectPlatformStyle()
        self.accessibilitySettings = Self.detectAccessibilitySettings()
        self.designSystem = designSystem
        self.previousTheme = self.currentTheme
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Theme Detection
    
    /// Check if we're running in a test environment
    /// NSApp.effectiveAppearance can assert/crash in test environments, especially on macOS
    private static func isTestEnvironment() -> Bool {
        #if DEBUG
        // Check for XCTest environment variables
        let environment = ProcessInfo.processInfo.environment
        if environment["XCTestConfigurationFilePath"] != nil ||
           environment["XCTestSessionIdentifier"] != nil ||
           environment["XCTestBundlePath"] != nil ||
           NSClassFromString("XCTestCase") != nil {
            return true
        }
        // Check for Swift Testing framework (Testing.Test class)
        if NSClassFromString("Testing.Test") != nil {
            return true
        }
        return false
        #else
        return false
        #endif
    }
    
    private static func detectSystemTheme() -> Theme {
        // In test environments, default to light theme to avoid crashes
        if isTestEnvironment() {
            return .light
        }
        
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
        return .light // Fallback for iOS when no window is available
        #elseif os(macOS)
        // NSApp should be available in normal app contexts, but we've already checked for test environment
        let appearance = NSApp.effectiveAppearance
        return appearance.name == .darkAqua ? .dark : .light
        #else
        return .light
        #endif
    }
    
    private static func detectPlatformStyle() -> PlatformStyle {
        #if os(iOS)
        return .ios
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #else
        return .ios // Default fallback
        #endif
    }
    
    private static func detectAccessibilitySettings() -> AccessibilitySettings {
        #if os(iOS)
        return AccessibilitySettings(
            voiceOverSupport: UIAccessibility.isVoiceOverRunning,
            keyboardNavigation: true,
            highContrastMode: UIAccessibility.isDarkerSystemColorsEnabled,
            dynamicType: true,
            reducedMotion: UIAccessibility.isReduceMotionEnabled,
            hapticFeedback: true
        )
        #elseif os(macOS)
        return AccessibilitySettings(
            voiceOverSupport: NSWorkspace.shared.isVoiceOverEnabled,
            keyboardNavigation: true,
            highContrastMode: false,
            dynamicType: true,
            reducedMotion: false,
            hapticFeedback: false
        )
        #else
        return AccessibilitySettings()
        #endif
    }
    
    private func updateTheme() {
        let newTheme = Self.detectSystemTheme()
        let themeChanged = newTheme != previousTheme

        currentTheme = newTheme
        accessibilitySettings = Self.detectAccessibilitySettings()

        // Update previous theme
        previousTheme = newTheme

        // Trigger theme change callback if theme actually changed
        if themeChanged {
            onThemeChange?()
        }
    }

    /// Switch to a different design system
    /// - Parameter designSystem: The new design system to use
    public func switchDesignSystem(_ designSystem: DesignSystem) {
        self.designSystem = designSystem
        onThemeChange?()
    }

    /// Get the current design tokens for colors
    public var currentColors: DesignTokens.Colors {
        designSystem.colors(for: currentTheme)
    }

    /// Get the current design tokens for typography
    public var currentTypography: DesignTokens.Typography {
        designSystem.typography(for: currentTheme)
    }

    /// Get the current spacing tokens
    public var currentSpacing: DesignTokens.Spacing {
        designSystem.spacing()
    }

    /// Get the current component state tokens
    public var currentComponentStates: DesignTokens.ComponentStates {
        designSystem.componentStates()
    }
}

// MARK: - Theme Definitions

public enum Theme: String, CaseIterable, Sendable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    public var effectiveTheme: Theme {
        if self == .auto {
            return .light // Simplified for now
        }
        return self
    }
}

public enum PlatformStyle: String, CaseIterable, Sendable {
    case ios = "ios"
    case macOS = "macOS"
    case watchOS = "watchOS"
    case tvOS = "tvOS"
    case visionOS = "visionOS"
    
    /// Convert PlatformStyle to SixLayerPlatform
    /// Eliminates duplicate conversion functions across codebase (Issue #140)
    public var sixLayerPlatform: SixLayerPlatform {
        switch self {
        case .ios: return .iOS
        case .macOS: return .macOS
        case .watchOS: return .watchOS
        case .tvOS: return .tvOS
        case .visionOS: return .visionOS
        }
    }
}

// MARK: - Color System (Legacy Compatibility)

/// Legacy ColorSystem for backward compatibility - now delegates to DesignSystem
public struct ColorSystem: Sendable {
    public let primary: Color
    public let secondary: Color
    public let accent: Color
    public let background: Color
    public let surface: Color
    public let text: Color
    public let textSecondary: Color
    public let border: Color
    public let error: Color
    public let warning: Color
    public let success: Color
    public let info: Color

    @MainActor
    public init(theme: Theme, platform: PlatformStyle) {
        // Get colors from the current design system
        let designSystem = VisualDesignSystem.shared.designSystem
        let colors = designSystem.colors(for: theme)

        self.primary = colors.primary
        self.secondary = colors.secondary
        self.accent = colors.accent
        self.background = colors.background
        self.surface = colors.surface
        self.text = colors.text
        self.textSecondary = colors.textSecondary
        self.border = colors.border
        self.error = colors.error
        self.warning = colors.warningText
        self.success = colors.successText
        self.info = colors.infoText
    }

    public init(from designSystem: DesignSystem, theme: Theme) {
        let colors = designSystem.colors(for: theme)

        self.primary = colors.primary
        self.secondary = colors.secondary
        self.accent = colors.accent
        self.background = colors.background
        self.surface = colors.surface
        self.text = colors.text
        self.textSecondary = colors.textSecondary
        self.border = colors.border
        self.error = colors.error
        self.warning = colors.warningText
        self.success = colors.successText
        self.info = colors.infoText
    }
}

// MARK: - Typography System (Legacy Compatibility)

/// Legacy TypographySystem for backward compatibility - now delegates to DesignSystem
public struct TypographySystem: Sendable {
    public let largeTitle: Font
    public let title1: Font
    public let title2: Font
    public let title3: Font
    public let headline: Font
    public let body: Font
    public let callout: Font
    public let subheadline: Font
    public let footnote: Font
    public let caption1: Font
    public let caption2: Font

    @MainActor
    public init(platform: PlatformStyle, accessibility: AccessibilitySettings) {
        // Get typography from the current design system
        let designSystem = VisualDesignSystem.shared.designSystem
        let typography = designSystem.typography(for: VisualDesignSystem.shared.currentTheme)

        self.largeTitle = typography.largeTitle
        self.title1 = typography.title1
        self.title2 = typography.title2
        self.title3 = typography.title3
        self.headline = typography.headline
        self.body = typography.body
        self.callout = typography.callout
        self.subheadline = typography.subheadline
        self.footnote = typography.footnote
        self.caption1 = typography.caption1
        self.caption2 = typography.caption2
    }

    public init(from designSystem: DesignSystem, theme: Theme) {
        let typography = designSystem.typography(for: theme)

        self.largeTitle = typography.largeTitle
        self.title1 = typography.title1
        self.title2 = typography.title2
        self.title3 = typography.title3
        self.headline = typography.headline
        self.body = typography.body
        self.callout = typography.callout
        self.subheadline = typography.subheadline
        self.footnote = typography.footnote
        self.caption1 = typography.caption1
        self.caption2 = typography.caption2
    }
}

// MARK: - Accessibility Settings Extension

public extension AccessibilitySettings {
    var typographyScaleFactor: CGFloat {
        // Simplified scale factor for now
        return 1.0
    }
}

public enum ContentSizeCategory: String, CaseIterable {
    case extraSmall = "extraSmall"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    case extraExtraLarge = "extraExtraLarge"
    case extraExtraExtraLarge = "extraExtraExtraLarge"
    case accessibilityMedium = "accessibilityMedium"
    case accessibilityLarge = "accessibilityLarge"
    case accessibilityExtraLarge = "accessibilityExtraLarge"
    case accessibilityExtraExtraLarge = "accessibilityExtraExtraLarge"
    case accessibilityExtraExtraExtraLarge = "accessibilityExtraExtraExtraLarge"
}

// MARK: - View Extensions

public extension View {
    /// Apply the current theme colors to this view
    func themedColors() -> some View {
        self.environmentObject(VisualDesignSystem.shared)
    }
    
    /// Apply platform-specific styling
    func platformStyled() -> some View {
        self.environmentObject(VisualDesignSystem.shared)
    }
    
    /// Apply accessibility-aware styling
    func accessibilityStyled() -> some View {
        self.environmentObject(VisualDesignSystem.shared)
    }
}

// MARK: - Environment Values

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = Theme.light
}

private struct PlatformStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue = PlatformStyle.ios
}

private struct ColorSystemEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue = ColorSystem(from: SixLayerDesignSystem(), theme: .light)
}

private struct TypographySystemEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue = TypographySystem(from: SixLayerDesignSystem(), theme: .light)
}

private struct DesignSystemEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue: DesignSystem = SixLayerDesignSystem()
}

private struct DesignTokensEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue = SixLayerDesignSystem().colors(for: .light)
}

private struct SpacingTokensEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue = SixLayerDesignSystem().spacing()
}

private struct ComponentStatesEnvironmentKey: EnvironmentKey {
    // Use default design system for environment key defaults to avoid main actor isolation issues
    static let defaultValue = SixLayerDesignSystem().componentStates()
}

public extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }

    var platformStyle: PlatformStyle {
        get { self[PlatformStyleEnvironmentKey.self] }
        set { self[PlatformStyleEnvironmentKey.self] = newValue }
    }

    var colorSystem: ColorSystem {
        get { self[ColorSystemEnvironmentKey.self] }
        set { self[ColorSystemEnvironmentKey.self] = newValue }
    }

    var typographySystem: TypographySystem {
        get { self[TypographySystemEnvironmentKey.self] }
        set { self[TypographySystemEnvironmentKey.self] = newValue }
    }

    var designSystem: DesignSystem {
        get { self[DesignSystemEnvironmentKey.self] }
        set { self[DesignSystemEnvironmentKey.self] = newValue }
    }

    var designTokens: DesignTokens.Colors {
        get { self[DesignTokensEnvironmentKey.self] }
        set { self[DesignTokensEnvironmentKey.self] = newValue }
    }

    var spacingTokens: DesignTokens.Spacing {
        get { self[SpacingTokensEnvironmentKey.self] }
        set { self[SpacingTokensEnvironmentKey.self] = newValue }
    }

    var componentStates: DesignTokens.ComponentStates {
        get { self[ComponentStatesEnvironmentKey.self] }
        set { self[ComponentStatesEnvironmentKey.self] = newValue }
    }
}

// MARK: - Font Extension

extension Font {
    func scale(_ factor: CGFloat) -> Font {
        // This is a simplified scaling approach
        // In a real implementation, you'd want to use Dynamic Type
        return self
    }
}
