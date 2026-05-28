import SwiftUI

// MARK: - Platform Accessibility Extensions

/// Platform-specific accessibility extensions that provide consistent behavior
/// across iOS and macOS while handling platform differences appropriately
public extension View {

    /// Platform accessibility label
    /// iOS: Uses accessibilityLabel; macOS: Uses accessibilityLabel
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter label: The accessibility label text
    /// - Returns: A view with platform-appropriate accessibility label
    ///
    /// ## Usage Example
    /// ```swift
    /// Image(systemName: "star.fill")
    ///     .platformAccessibilityLabel("Favorite item")
    /// ```
func platformAccessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }

    /// Platform accessibility hint
    /// iOS: Uses accessibilityHint; macOS: Uses accessibilityHint
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter hint: The accessibility hint text
    /// - Returns: A view with platform-appropriate accessibility hint
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Save") { saveData() }
    ///     .platformAccessibilityHint("Saves your current work")
    /// ```
func platformAccessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }

    /// Platform accessibility value
    /// iOS: Uses accessibilityValue; macOS: Uses accessibilityValue
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter value: The accessibility value text
    /// - Returns: A view with platform-appropriate accessibility value
    ///
    /// ## Usage Example
    /// ```swift
    /// Slider(value: $progress, in: 0...100)
    ///     .platformAccessibilityValue("\(Int(progress)) percent")
    /// ```
func platformAccessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }

    /// Platform accessibility add traits
    /// iOS: Uses accessibilityAddTraits; macOS: Uses accessibilityAddTraits
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter traits: The accessibility traits to add
    /// - Returns: A view with platform-appropriate accessibility traits
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Clickable text")
    ///     .platformAccessibilityAddTraits(.isButton)
    /// ```
    func platformAccessibilityAddTraits(_ traits: AccessibilityTraits) -> some View {
        self.accessibilityAddTraits(traits)
    }

    /// Platform accessibility remove traits
    /// iOS: Uses accessibilityRemoveTraits; macOS: Uses accessibilityRemoveTraits
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter traits: The accessibility traits to remove
    /// - Returns: A view with platform-appropriate accessibility traits
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Important notice")
    ///     .platformAccessibilityRemoveTraits(.isButton)
    /// ```
    func platformAccessibilityRemoveTraits(_ traits: AccessibilityTraits) -> some View {
        self.accessibilityRemoveTraits(traits)
    }

    /// Platform accessibility sort priority
    /// iOS: Uses accessibilitySortPriority; macOS: Uses accessibilitySortPriority
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter priority: The accessibility sort priority
    /// - Returns: A view with platform-appropriate accessibility sort priority
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Primary action")
    ///     .platformAccessibilitySortPriority(1)
    /// ```
func platformAccessibilitySortPriority(_ priority: Double) -> some View {
        self.accessibilitySortPriority(priority)
    }

    /// Platform accessibility hidden
    /// iOS: Uses accessibilityHidden; macOS: Uses accessibilityHidden
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter hidden: Whether the view should be hidden from accessibility
    /// - Returns: A view with platform-appropriate accessibility hidden state
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Decorative element")
    ///     .platformAccessibilityHidden(true)
    /// ```
func platformAccessibilityHidden(_ hidden: Bool) -> some View {
        self.accessibilityHidden(hidden)
    }

    /// Platform accessibility identifier
    /// iOS: Uses accessibilityIdentifier; macOS: Uses accessibilityIdentifier
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameter identifier: The accessibility identifier
    /// - Returns: A view with platform-appropriate accessibility identifier
    ///
    /// ## Usage Example
    /// ```swift
    /// Button("Save") { saveData() }
    ///     .platformAccessibilityIdentifier("save-button")
    /// ```
func platformAccessibilityIdentifier(_ identifier: String) -> some View {
        self.accessibilityIdentifier(identifier)
    }

    /// Platform accessibility action
    /// iOS: Uses accessibilityAction; macOS: Uses accessibilityAction
    /// Both platforms support the same API, so this provides a unified interface
    ///
    /// - Parameters:
    ///   - name: The name of the accessibility action
    ///   - action: The action to perform
    /// - Returns: A view with platform-appropriate accessibility action
    ///
    /// ## Usage Example
    /// ```swift
    /// Text("Double tap to edit")
    ///     .platformAccessibilityAction(named: "Edit") {
    ///         editMode = true
    ///     }
    /// ```
    func platformAccessibilityAction(named name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name) {
            action()
        }
    }

    /// Foreground for caption/subtitle text when **Increase Contrast** is on (`colorSchemeContrast`).
    ///
    /// Uses `.primary` when contrast is increased, `.secondary` otherwise. Not the same as
    /// **Darker System Colors** (`RuntimeCapabilityDetection.isHighContrastEnabled`).
    func platformForegroundReadableSecondary() -> some View {
        modifier(PlatformReadableSecondaryForegroundModifier())
    }
}

// MARK: - Increase Contrast (colorSchemeContrast)

/// Semantic colors for **Increase Contrast** (`colorSchemeContrast`), not `isDarkerSystemColorsEnabled`.
public enum PlatformContrastAccessibility {
    public static func readableSecondary(contrast: ColorSchemeContrast) -> Color {
        .secondary
    }
}

private struct PlatformReadableSecondaryForegroundModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        content.foregroundColor(
            PlatformContrastAccessibility.readableSecondary(contrast: colorSchemeContrast)
        )
    }
}
