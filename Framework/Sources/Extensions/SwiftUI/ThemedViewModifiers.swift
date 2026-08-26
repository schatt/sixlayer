import Foundation
import SwiftUI

// MARK: - Themed View Modifiers
// Comprehensive view modifiers for applying theme-aware styling

// ThemedButtonStyle removed due to compilation issues - using AdaptiveUIPatterns.AdaptiveButton instead

public enum ButtonVariant: String, CaseIterable {
    case primary = "primary"
    case secondary = "secondary"
    case outline = "outline"
    case ghost = "ghost"
}

public enum ButtonSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
}

/// Themed card style that adapts to platform and theme
public struct ThemedCardStyle: ViewModifier {
    public func body(content: Content) -> some View {
        let colors = ThemePreference.designTokens
        let componentStates = ThemePreference.componentStates
        content
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: componentStates.cornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: componentStates.cornerRadius.md)
                    .stroke(colors.border, lineWidth: componentStates.borderWidth.sm)
            )
            .shadow(
                color: componentStates.shadow.md.color,
                radius: componentStates.shadow.md.radius,
                x: componentStates.shadow.md.x,
                y: componentStates.shadow.md.y
            )
    }
}

/// Themed list style that adapts to platform
public struct ThemedListStyle: ViewModifier {
    public func body(content: Content) -> some View {
        let colors = ThemePreference.colorSystem
        content
            #if os(iOS)
            .listStyle(.insetGrouped)
            #elseif os(macOS)
            .listStyle(.sidebar)
            #else
            .listStyle(.plain)
            #endif
            .modifier(ScrollContentBackgroundModifier())
            .background(colors.background)
    }
}

/// Themed navigation style that adapts to platform
public struct ThemedNavigationStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .navigationViewStyle(navigationViewStyle)
            .background(ThemePreference.colorSystem.background)
    }

    private var navigationViewStyle: some NavigationViewStyle {
        #if os(iOS)
        return .stack
        #elseif os(macOS)
        return .columns
        #else
        return .stack
        #endif
    }
}

/// Themed form style that adapts to platform
public struct ThemedFormStyle: ViewModifier {
    public func body(content: Content) -> some View {
        let colors = ThemePreference.colorSystem
        let platform = ThemePreference.platformStyle
        // Use PlatformStrategy to determine form style preference (Issue #140)
        // Apply style directly to avoid Swift's type system limitations with `some FormStyle`
        switch platform.sixLayerPlatform.defaultFormStylePreference {
        case .grouped:
            return AnyView(content
                .formStyle(.grouped)
                .background(colors.background))
        case .automatic:
            return AnyView(content
                .formStyle(.automatic)
                .background(colors.background))
        }
    }
}

/// Themed text field style that adapts to design system
public struct ThemedTextFieldStyle: TextFieldStyle {
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.modifier(ThemedTextFieldTokenModifier())
    }
}

/// ViewModifier body is MainActor-isolated, so it can read ThemePreference without Environment.
private struct ThemedTextFieldTokenModifier: ViewModifier {
    func body(content: Content) -> some View {
        let colors = ThemePreference.designTokens
        let componentStates = ThemePreference.componentStates
        let spacing = ThemePreference.spacingTokens
        content
            .padding(EdgeInsets(
                top: spacing.md,
                leading: spacing.lg,
                bottom: spacing.md,
                trailing: spacing.lg
            ))
            .background(colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                    .stroke(colors.border, lineWidth: componentStates.borderWidth.md)
            )
            .clipShape(RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm))
    }
}

/// Themed loading indicator that adapts to platform
public struct ThemedLoadingIndicator: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        let colors = ThemePreference.colorSystem
        let reduceMotion = PlatformReduceMotionPreference.isReduceMotionEnabled
        Group {
            if reduceMotion {
                Circle()
                    .fill(colors.primary)
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(colors.primary, lineWidth: 3)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    }
            }
        }
        .automaticCompliance(named: "ThemedLoadingIndicator")
    }
}

/// Themed progress bar that adapts to platform
public struct ThemedProgressBar: View {
    let progress: Double
    let variant: ProgressVariant

    public init(progress: Double, variant: ProgressVariant = .primary) {
        self.progress = max(0, min(1, progress))
        self.variant = variant
    }

    public var body: some View {
        let colors = ThemePreference.designTokens
        let componentStates = ThemePreference.componentStates
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                    .fill(colors.surface)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                    .fill(progressColor(colors: colors))
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
        .automaticCompliance(named: "ThemedProgressBar")
    }

    private func progressColor(colors: DesignTokens.Colors) -> Color {
        switch variant {
        case .primary: return colors.primary
        case .success: return colors.successText
        case .warning: return colors.warningText
        case .error: return colors.error
        }
    }
}

public enum ProgressVariant: String, CaseIterable {
    case primary = "primary"
    case success = "success"
    case warning = "warning"
    case error = "error"
}

// MARK: - View Extensions

public extension View {
    /// Apply themed button styling - use AdaptiveUIPatterns.AdaptiveButton instead
    // func themedButton(variant: ButtonVariant = .primary, size: ButtonSize = .medium) -> some View {
    //     self.buttonStyle(ThemedButtonStyle(variant: variant, size: size))
    // }
    
    /// Apply themed card styling
    func themedCard() -> some View {
        self.modifier(ThemedCardStyle())
    }
    
    /// Apply themed list styling
    func themedList() -> some View {
        self.modifier(ThemedListStyle())
    }
    
    /// Apply themed navigation styling
    func themedNavigation() -> some View {
        self.modifier(ThemedNavigationStyle())
    }
    
    /// Apply themed form styling
    func themedForm() -> some View {
        self.modifier(ThemedFormStyle())
    }
    
    /// Apply themed text field styling
    func themedTextField() -> some View {
        self.textFieldStyle(ThemedTextFieldStyle())
    }
}

// MARK: - ScrollContentBackground Modifier

/// Platform-aware scrollContentBackground modifier that handles iOS 17.0+ availability
struct ScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS) || os(macOS)
        if #available(iOS 17.0, macOS 14.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
        #else
        // scrollContentBackground is not available on tvOS / watchOS SwiftUI surface (#237).
        content
        #endif
    }
}

// MARK: - Environment Extensions

private struct AccessibilitySettingsEnvironmentKey: EnvironmentKey {
    static let defaultValue = AccessibilitySettings()
}

public extension EnvironmentValues {
    var accessibilitySettings: AccessibilitySettings {
        get { self[AccessibilitySettingsEnvironmentKey.self] }
        set { self[AccessibilitySettingsEnvironmentKey.self] = newValue }
    }
}
