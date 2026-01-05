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
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ThemedCardStyleEnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ThemedCardStyleEnvironmentAccessor: View {
        let content: Content

        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.designTokens) private var colors
        @Environment(\.componentStates) private var componentStates

        var body: some View {
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
}

/// Themed list style that adapts to platform
public struct ThemedListStyle: ViewModifier {
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ThemedListStyleEnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ThemedListStyleEnvironmentAccessor: View {
        let content: Content
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.colorSystem) private var colors
        @Environment(\.platformStyle) private var platform
        
        var body: some View {
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
}

/// Themed navigation style that adapts to platform
public struct ThemedNavigationStyle: ViewModifier {
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ThemedNavigationStyleEnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ThemedNavigationStyleEnvironmentAccessor: View {
        let content: Content
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.colorSystem) private var colors
        @Environment(\.platformStyle) private var platform
        
        var body: some View {
            content
                .navigationViewStyle(navigationViewStyle)
                .background(colors.background)
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
}

/// Themed form style that adapts to platform
public struct ThemedFormStyle: ViewModifier {
    // NOTE: Environment properties moved to helper view to avoid SwiftUI warnings
    
    public func body(content: Content) -> some View {
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ThemedFormStyleEnvironmentAccessor(content: content)
    }
    
    // Helper view that defers environment access until view is installed
    private struct ThemedFormStyleEnvironmentAccessor: View {
        let content: Content
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.colorSystem) private var colors
        @Environment(\.platformStyle) private var platform
        
        var body: some View {
            // Convert PlatformStyle to SixLayerPlatform for PlatformStrategy (Issue #140)
            let sixLayerPlatform = convertPlatformStyle(platform)
            
            // Use PlatformStrategy to determine form style preference
            // Apply style directly to avoid Swift's type system limitations with `some FormStyle`
            // Use AnyView to wrap different return types
            switch sixLayerPlatform.defaultFormStylePreference {
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
        
        private func convertPlatformStyle(_ platform: PlatformStyle) -> SixLayerPlatform {
            switch platform {
            case .ios:
                return .iOS
            case .macOS:
                return .macOS
            case .watchOS:
                return .watchOS
            case .tvOS:
                return .tvOS
            case .visionOS:
                return .visionOS
            }
        }
    }
}

/// Themed text field style that adapts to design system
/// NOTE: TextFieldStyle protocol requires _body to be the entry point, so we access
/// @Environment directly in _body. SwiftUI may warn, but this is a protocol limitation.
/// The _body method is called when the view is installed, so environment is available.
public struct ThemedTextFieldStyle: TextFieldStyle {
    @Environment(\.designTokens) private var colors
    @Environment(\.componentStates) private var componentStates
    @Environment(\.spacingTokens) private var spacing

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(textFieldPadding)
            .background(colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                    .stroke(colors.border, lineWidth: componentStates.borderWidth.md)
            )
            .clipShape(RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm))
    }

    private var textFieldPadding: EdgeInsets {
        EdgeInsets(
            top: spacing.md,
            leading: spacing.lg,
            bottom: spacing.md,
            trailing: spacing.lg
        )
    }
}

/// Themed loading indicator that adapts to platform
public struct ThemedLoadingIndicator: View {
    @Environment(\.colorSystem) private var colors
    @Environment(\.platformStyle) private var platform
    @Environment(\.accessibilitySettings) private var accessibility
    @State private var isAnimating = false
    
    public init() {}
    
    public var body: some View {
        Group {
            if accessibility.reducedMotion {
                // Static indicator for reduced motion
                Circle()
                    .fill(colors.primary)
                    .frame(width: 20, height: 20)
            } else {
                // Animated indicator
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
        // CRITICAL: Access environment values lazily using a helper view to avoid SwiftUI warnings
        ThemedProgressBarEnvironmentAccessor(progress: progress, variant: variant)
        .automaticCompliance(named: "ThemedProgressBar")
    }
    
    // Helper view that defers environment access until view is installed
    private struct ThemedProgressBarEnvironmentAccessor: View {
        let progress: Double
        let variant: ProgressVariant
        
        // Access environment values here - this view is only created when body is called
        // and the view is installed, so environment is guaranteed to be available
        @Environment(\.designTokens) private var colors
        @Environment(\.componentStates) private var componentStates

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                        .fill(colors.surface)
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: componentStates.cornerRadius.sm)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }

        private var progressColor: Color {
            switch variant {
            case .primary: return colors.primary
            case .success: return colors.successText
            case .warning: return colors.warningText
            case .error: return colors.error
            }
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
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
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
