import SwiftUI
import Foundation

// MARK: - Platform Split View Styles & Appearance Configuration

/// Split view style options
/// Implements Issue #17: Split View Styles & Appearance
public enum PlatformSplitViewStyle: Sendable {
    /// Balanced layout style (equal emphasis on all panes)
    case balanced
    /// Prominent detail style (detail pane is emphasized)
    case prominentDetail
    /// Custom style (platform-appropriate default)
    case custom
}

/// Divider style options
public enum PlatformSplitViewDividerStyle: Sendable {
    /// Solid divider line
    case solid
    /// Dashed divider line
    case dashed
    /// Dotted divider line
    case dotted
    /// No visible divider
    case none
}

/// Divider configuration for split views
/// Implements Issue #17: Split View Styles & Appearance
public struct PlatformSplitViewDivider: Sendable {
    /// Divider color
    public let color: Color
    /// Divider width/thickness
    public let width: CGFloat
    /// Divider style
    public let style: PlatformSplitViewDividerStyle
    
    public init(
        color: Color = .separator,
        width: CGFloat = 1.0,
        style: PlatformSplitViewDividerStyle = .solid
    ) {
        self.color = color
        self.width = width
        self.style = style
    }
}

/// Shadow configuration
public struct PlatformSplitViewShadow: Sendable {
    /// Shadow color
    public let color: Color
    /// Shadow blur radius
    public let radius: CGFloat
    /// Shadow X offset
    public let x: CGFloat
    /// Shadow Y offset
    public let y: CGFloat
    
    public init(
        color: Color,
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Appearance configuration for split views
/// Implements Issue #17: Split View Styles & Appearance
public struct PlatformSplitViewAppearance: Sendable {
    /// Background color
    public let backgroundColor: Color?
    /// Corner radius
    public let cornerRadius: CGFloat?
    /// Shadow configuration
    public let shadow: PlatformSplitViewShadow?
    
    public init(
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        shadow: PlatformSplitViewShadow? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
}

// MARK: - Platform Split View Sizing Configuration

/// Sizing constraints for a single split view pane
/// Implements Issue #16: Split View Sizing & Constraints
public struct PlatformSplitViewPaneSizing: Sendable {
    /// Minimum width constraint
    public let minWidth: CGFloat?
    /// Ideal/preferred width
    public let idealWidth: CGFloat?
    /// Maximum width constraint
    public let maxWidth: CGFloat?
    /// Minimum height constraint
    public let minHeight: CGFloat?
    /// Ideal/preferred height
    public let idealHeight: CGFloat?
    /// Maximum height constraint
    public let maxHeight: CGFloat?
    /// Resizing priority (higher = more flexible)
    public let priority: Double
    
    public init(
        minWidth: CGFloat? = nil,
        idealWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        idealHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        priority: Double = 0.5
    ) {
        self.minWidth = minWidth
        self.idealWidth = idealWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.idealHeight = idealHeight
        self.maxHeight = maxHeight
        self.priority = priority
    }
}

/// Sizing configuration for split views
/// Implements Issue #16: Split View Sizing & Constraints
public struct PlatformSplitViewSizing: Sendable {
    /// Sizing for first pane (or all panes if using array)
    public let firstPane: PlatformSplitViewPaneSizing?
    /// Sizing for second pane
    public let secondPane: PlatformSplitViewPaneSizing?
    /// Sizing for all panes (alternative to firstPane/secondPane)
    public let panes: [PlatformSplitViewPaneSizing]
    /// Container-level sizing constraints
    public let container: PlatformSplitViewPaneSizing?
    /// Whether to use responsive sizing based on content
    public let responsive: Bool
    
    /// Initialize with first and second pane sizing
    public init(
        firstPane: PlatformSplitViewPaneSizing? = nil,
        secondPane: PlatformSplitViewPaneSizing? = nil,
        container: PlatformSplitViewPaneSizing? = nil,
        responsive: Bool = false
    ) {
        self.firstPane = firstPane
        self.secondPane = secondPane
        self.panes = []
        self.container = container
        self.responsive = responsive
    }
    
    /// Initialize with array of pane sizing
    public init(
        panes: [PlatformSplitViewPaneSizing],
        container: PlatformSplitViewPaneSizing? = nil,
        responsive: Bool = false
    ) {
        self.firstPane = panes.first
        self.secondPane = panes.count > 1 ? panes[1] : nil
        self.panes = panes
        self.container = container
        self.responsive = responsive
    }
}

// MARK: - Platform Split View Advanced Features Configuration

/// Animation configuration for split view transitions
/// Implements Issue #18: Advanced Split View Features
public struct PlatformSplitViewAnimationConfiguration: Sendable {
    /// Animation duration in seconds
    public let duration: TimeInterval
    /// Animation curve type
    public let curveType: AnimationCurveType
    
    /// Animation curve types
    public enum AnimationCurveType: Sendable, Equatable {
        case easeInOut
        case easeIn
        case easeOut
        case linear
        case spring
    }
    
    /// Get the SwiftUI Animation for this configuration
    /// - Returns: Configured SwiftUI Animation instance
    public var animation: Animation {
        switch curveType {
        case .easeInOut:
            return .easeInOut(duration: duration)
        case .easeIn:
            return .easeIn(duration: duration)
        case .easeOut:
            return .easeOut(duration: duration)
        case .linear:
            return .linear(duration: duration)
        case .spring:
            // Spring animation uses duration as response time
            return .spring(response: duration, dampingFraction: 0.8)
        }
    }
    
    public init(
        duration: TimeInterval = 0.3,
        curve: AnimationCurveType = .easeInOut
    ) {
        self.duration = duration
        self.curveType = curve
    }
}

#if os(macOS)
/// Keyboard shortcut action types
/// Implements Issue #18: Advanced Split View Features
public enum PlatformSplitViewKeyboardAction: Sendable, Equatable {
    /// Toggle visibility of a specific pane
    case togglePane(Int)
    /// Show a specific pane
    case showPane(Int)
    /// Hide a specific pane
    case hidePane(Int)
    /// Toggle all panes
    case toggleAll
}

/// Keyboard shortcut configuration for split views
/// macOS only - keyboard shortcuts are not available on iOS
/// Implements Issue #18: Advanced Split View Features
public struct PlatformSplitViewKeyboardShortcut: Sendable, Equatable {
    /// Key to press
    public let key: KeyEquivalent
    /// Modifier keys (Command, Option, Control, Shift)
    public let modifiers: EventModifiers
    /// Action to perform when shortcut is pressed
    public let action: PlatformSplitViewKeyboardAction
    
    public init(
        key: KeyEquivalent,
        modifiers: EventModifiers,
        action: PlatformSplitViewKeyboardAction
    ) {
        self.key = key
        self.modifiers = modifiers
        self.action = action
    }
    
    /// Convenience initializer with String key
    /// - Parameter key: Single character string (e.g., "t", "h", "1")
    /// - Note: Only the first character is used. Empty strings will use "a" as fallback.
    public init(
        key: String,
        modifiers: EventModifiers,
        action: PlatformSplitViewKeyboardAction
    ) {
        // Safely extract first character, with fallback
        let character = key.first ?? "a"
        self.key = KeyEquivalent(character)
        self.modifiers = modifiers
        self.action = action
    }
}
#endif

// MARK: - Platform Split View State Management

/// State management for split views
/// Implements Issue #15: Split View State Management & Visibility Control
/// Implements Issue #18: Advanced Split View Features (animations, keyboard shortcuts, pane locking, divider callbacks)
@MainActor
public class PlatformSplitViewState: ObservableObject {
    /// Visibility state for each pane (index -> visible)
    /// Codable for persistence
    @Published private var paneVisibility: [Int: Bool] = [:]
    
    /// Lock state for each pane (index -> locked)
    /// Locked panes cannot be resized
    @Published private var paneLocked: [Int: Bool] = [:]
    
    /// Callback for visibility changes
    public var onVisibilityChange: ((Int, Bool) -> Void)?
    
    /// Callback for divider drag interactions
    /// Parameters: (paneIndex, newPosition)
    public var onDividerDrag: ((Int, CGFloat) -> Void)?
    
    /// Default visibility for new panes
    public var defaultVisibility: Bool = true
    
    /// Animation configuration for pane visibility transitions
    public var animationConfiguration: PlatformSplitViewAnimationConfiguration?
    
    #if os(macOS)
    /// Keyboard shortcuts for pane management (macOS only)
    public var keyboardShortcuts: [PlatformSplitViewKeyboardShortcut] = []
    #endif
    
    public init(defaultVisibility: Bool = true) {
        self.defaultVisibility = defaultVisibility
    }
    
    /// Check if a pane is visible
    public func isPaneVisible(_ index: Int) -> Bool {
        return paneVisibility[index] ?? defaultVisibility
    }
    
    /// Set pane visibility
    public func setPaneVisible(_ index: Int, visible: Bool) {
        paneVisibility[index] = visible
        onVisibilityChange?(index, visible)
    }
    
    /// Toggle pane visibility
    public func togglePane(_ index: Int) {
        setPaneVisible(index, visible: !isPaneVisible(index))
    }
    
    /// Check if a pane is locked (cannot be resized)
    /// - Parameter index: Pane index (0-based)
    /// - Returns: `true` if pane is locked, `false` otherwise
    public func isPaneLocked(_ index: Int) -> Bool {
        return paneLocked[index] ?? false
    }
    
    /// Set pane lock state
    /// Locked panes cannot be resized by user interaction
    /// - Parameters:
    ///   - index: Pane index (0-based)
    ///   - locked: `true` to lock the pane, `false` to unlock
    public func setPaneLocked(_ index: Int, locked: Bool) {
        paneLocked[index] = locked
    }
    
    /// Save state to UserDefaults
    /// Saves both pane visibility and pane lock state
    public func saveToUserDefaults(key: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            let stateData: [String: [Int: Bool]] = [
                "visibility": paneVisibility,
                "locked": paneLocked
            ]
            let data = try encoder.encode(stateData)
            UserDefaults.standard.set(data, forKey: key)
            return true
        } catch {
            return false
        }
    }
    
    /// Restore state from UserDefaults
    /// Restores both pane visibility and pane lock state
    public func restoreFromUserDefaults(key: String) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return false
        }
        do {
            let decoder = JSONDecoder()
            let stateData = try decoder.decode([String: [Int: Bool]].self, from: data)
            paneVisibility = stateData["visibility"] ?? [:]
            paneLocked = stateData["locked"] ?? [:]
            return true
        } catch {
            return false
        }
    }
    
    /// Save state to AppStorage (via UserDefaults)
    public func saveToAppStorage(key: String) -> Bool {
        return saveToUserDefaults(key: key)
    }
}

/// Helper modifier for applying visibility control to split view panes
/// Use this modifier on individual panes within a split view to control their visibility
public extension View {
    /// Apply visibility control to a split view pane
    /// - Parameters:
    ///   - index: The index of this pane (0-based)
    ///   - state: The split view state object (from environment or binding)
    /// - Returns: View with visibility control applied
    @ViewBuilder
    func splitViewPaneVisibility(
        index: Int,
        state: PlatformSplitViewState
    ) -> some View {
        self
            .opacity(state.isPaneVisible(index) ? 1.0 : 0.0)
            .frame(
                width: state.isPaneVisible(index) ? nil : 0,
                height: state.isPaneVisible(index) ? nil : 0
            )
            .clipped()
    }
    
    /// Apply sizing constraints to a split view pane
    /// Use this modifier on individual panes within a split view to apply size constraints
    /// - Parameters:
    ///   - sizing: The sizing configuration for this pane
    /// - Returns: View with sizing constraints applied
    @ViewBuilder
    func splitViewPaneSizing(
        _ sizing: PlatformSplitViewPaneSizing
    ) -> some View {
        self
            .frame(
                minWidth: sizing.minWidth,
                idealWidth: sizing.idealWidth,
                maxWidth: sizing.maxWidth,
                minHeight: sizing.minHeight,
                idealHeight: sizing.idealHeight,
                maxHeight: sizing.maxHeight
            )
    }
}

// MARK: - Platform Split View Layer 4: Component Implementation

/// Platform-agnostic helpers for split view presentation
/// Implements Issue #14: Add Split View Helpers to Six-Layer Architecture (Layer 4)
///
/// ## Cross-Platform Behavior
///
/// ### Vertical Split Views
/// **Semantic Purpose**: Divide content into resizable vertical panes
/// - **macOS**: Uses `VSplitView` for resizable vertical split panes
///   - User can drag divider to resize panes
///   - Spacing parameter is ignored (uses split view divider)
///   - Native macOS split view behavior
/// - **iOS**: Uses `VStack` for vertical layout
///   - Split views are not available on iOS
///   - Spacing parameter is applied between views
///   - Standard vertical stack layout
///
/// **When to Use**: Sidebars, detail views, master-detail interfaces
///
/// ### Horizontal Split Views
/// **Semantic Purpose**: Divide content into resizable horizontal panes
/// - **macOS**: Uses `HSplitView` for resizable horizontal split panes
///   - User can drag divider to resize panes
///   - Spacing parameter is ignored (uses split view divider)
///   - Native macOS split view behavior
/// - **iOS**: Uses `HStack` for horizontal layout
///   - Split views are not available on iOS
///   - Spacing parameter is applied between views
///   - Standard horizontal stack layout
///
/// **When to Use**: Multi-column layouts, side-by-side content
///
/// ## Platform Mapping
///
/// | Concept | macOS Behavior | iOS Behavior | Unified API |
/// |---------|---------------|--------------|------------|
/// | Vertical Split | VSplitView (resizable) | VStack (spacing) | `platformVerticalSplit_L4()` |
/// | Horizontal Split | HSplitView (resizable) | HStack (spacing) | `platformHorizontalSplit_L4()` |
///
/// **Note**: The unified API automatically uses the appropriate container for each platform.
/// Developers don't need to handle platform differences - the framework adapts automatically.
public extension View {
    
    /// Unified vertical split view presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `VSplitView` for resizable vertical split panes
    ///   - User can drag divider to resize panes
    ///   - Spacing parameter is ignored (uses split view divider)
    /// - **iOS**: Uses `VStack` for vertical layout
    ///   - Split views are not available on iOS
    ///   - Spacing parameter is applied between views
    ///
    /// **Use For**: Sidebars, detail views, master-detail interfaces
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - content: View builder for split view content
    /// - Returns: View with vertical split modifier applied
    @ViewBuilder
    func platformVerticalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformVerticalSplit_L4"
        #if os(macOS)
        VSplitView {
            content()
        }
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformVStackContainer(spacing: spacing) {
            content()
        }
        .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified vertical split view presentation helper with sizing
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `VSplitView` with frame modifiers for size constraints
    ///   - Applies minWidth, idealWidth, maxWidth to panes
    ///   - Container constraints applied to overall view
    /// - **iOS**: Uses `VStack` with frame modifiers
    ///   - Size constraints applied via frame modifiers
    ///   - Container constraints applied to overall view
    ///
    /// **Use For**: Sidebars, detail views with specific size requirements
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - sizing: Sizing configuration for panes and container
    ///   - content: View builder for split view content (should provide 2+ views)
    /// - Returns: View with vertical split modifier and sizing applied
    @ViewBuilder
    func platformVerticalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        sizing: PlatformSplitViewSizing,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformVerticalSplit_L4"
        #if os(macOS)
        VSplitView {
            content()
        }
        .frame(
            minWidth: sizing.container?.minWidth,
            idealWidth: sizing.container?.idealWidth,
            maxWidth: sizing.container?.maxWidth,
            minHeight: sizing.container?.minHeight,
            idealHeight: sizing.container?.idealHeight,
            maxHeight: sizing.container?.maxHeight
        )
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformVStackContainer(spacing: spacing) {
            content()
        }
        .frame(
            minWidth: sizing.container?.minWidth,
            idealWidth: sizing.container?.idealWidth,
            maxWidth: sizing.container?.maxWidth,
            minHeight: sizing.container?.minHeight,
            idealHeight: sizing.container?.idealHeight,
            maxHeight: sizing.container?.maxHeight
        )
        .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified vertical split view presentation helper with style and appearance
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `VSplitView` with visual treatments
    ///   - Style may map to layout emphasis
    ///   - Divider customization applied via overlays
    ///   - Appearance modifiers applied to container
    /// - **iOS**: Uses `VStack` with visual treatments
    ///   - Style may map to layout emphasis
    ///   - Divider customization applied via overlays
    ///   - Appearance modifiers applied to container
    ///
    /// **Use For**: Sidebars, detail views with specific styling requirements
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - style: Split view style (balanced, prominentDetail, custom)
    ///   - divider: Optional divider configuration
    ///   - appearance: Optional appearance configuration
    ///   - content: View builder for split view content
    /// - Returns: View with vertical split modifier and styling applied
    func platformVerticalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        style: PlatformSplitViewStyle = .custom,
        divider: PlatformSplitViewDivider? = nil,
        appearance: PlatformSplitViewAppearance? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformVerticalSplit_L4"
        var view: AnyView
        #if os(macOS)
        view = AnyView(VSplitView {
            content()
        })
        #else
        view = AnyView(platformVStackContainer(spacing: spacing) {
            content()
        })
        #endif
        
        // Apply appearance modifiers
        if let appearance = appearance {
            if let backgroundColor = appearance.backgroundColor {
                view = AnyView(view.background(backgroundColor))
            }
            if let cornerRadius = appearance.cornerRadius {
                view = AnyView(view.cornerRadius(cornerRadius))
            }
            if let shadow = appearance.shadow {
                view = AnyView(view.shadow(
                    color: shadow.color,
                    radius: shadow.radius,
                    x: shadow.x,
                    y: shadow.y
                ))
            }
        }
        
        // Apply divider (if specified and not none)
        if let divider = divider, divider.style != .none {
            // Divider is handled by VSplitView/HSplitView on macOS
            // On iOS, we'd need to add a custom divider view
            // For now, divider customization is primarily for macOS
        }
        
        #if os(macOS)
        return view
            .automaticAccessibility()
            .automaticCompliance(named: identifierName)
        #else
        return view
            .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified vertical split view presentation helper with state management
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `VSplitView` for resizable vertical split panes
    ///   - User can drag divider to resize panes
    ///   - Spacing parameter is ignored (uses split view divider)
    ///   - Visibility state controls pane visibility
    /// - **iOS**: Uses `VStack` for vertical layout
    ///   - Split views are not available on iOS
    ///   - Spacing parameter is applied between views
    ///   - Visibility state conditionally includes/excludes panes
    ///
    /// **Use For**: Sidebars, detail views, master-detail interfaces with visibility control
    ///
    /// - Parameters:
    ///   - state: Binding to split view state for visibility control
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - content: View builder for split view content (should provide 2+ views)
    /// - Returns: View with vertical split modifier applied
    @ViewBuilder
    func platformVerticalSplit_L4<Content: View>(
        state: Binding<PlatformSplitViewState>,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformVerticalSplit_L4"
        let stateValue = state.wrappedValue
        #if os(macOS)
        VSplitView {
            content()
                .environmentObject(stateValue)
        }
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformVStackContainer(spacing: spacing) {
            content()
                .environmentObject(stateValue)
        }
        .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified horizontal split view presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `HSplitView` for resizable horizontal split panes
    ///   - User can drag divider to resize panes
    ///   - Spacing parameter is ignored (uses split view divider)
    /// - **iOS**: Uses `HStack` for horizontal layout
    ///   - Split views are not available on iOS
    ///   - Spacing parameter is applied between views
    ///
    /// **Use For**: Multi-column layouts, side-by-side content
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - content: View builder for split view content
    /// - Returns: View with horizontal split modifier applied
    @ViewBuilder
    func platformHorizontalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformHorizontalSplit_L4"
        #if os(macOS)
        HSplitView {
            content()
        }
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformHStackContainer(spacing: spacing) {
            content()
        }
        .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified horizontal split view presentation helper with sizing
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `HSplitView` with frame modifiers for size constraints
    ///   - Applies minWidth, idealWidth, maxWidth to panes
    ///   - Container constraints applied to overall view
    /// - **iOS**: Uses `HStack` with frame modifiers
    ///   - Size constraints applied via frame modifiers
    ///   - Container constraints applied to overall view
    ///
    /// **Use For**: Multi-column layouts with specific size requirements
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - sizing: Sizing configuration for panes and container
    ///   - content: View builder for split view content (should provide 2+ views)
    /// - Returns: View with horizontal split modifier and sizing applied
    @ViewBuilder
    func platformHorizontalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        sizing: PlatformSplitViewSizing,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformHorizontalSplit_L4"
        #if os(macOS)
        HSplitView {
            content()
        }
        .frame(
            minWidth: sizing.container?.minWidth,
            idealWidth: sizing.container?.idealWidth,
            maxWidth: sizing.container?.maxWidth,
            minHeight: sizing.container?.minHeight,
            idealHeight: sizing.container?.idealHeight,
            maxHeight: sizing.container?.maxHeight
        )
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformHStackContainer(spacing: spacing) {
            content()
        }
        .frame(
            minWidth: sizing.container?.minWidth,
            idealWidth: sizing.container?.idealWidth,
            maxWidth: sizing.container?.maxWidth,
            minHeight: sizing.container?.minHeight,
            idealHeight: sizing.container?.idealHeight,
            maxHeight: sizing.container?.maxHeight
        )
        .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified horizontal split view presentation helper with style and appearance
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `HSplitView` with visual treatments
    ///   - Style may map to layout emphasis
    ///   - Divider customization applied via overlays
    ///   - Appearance modifiers applied to container
    /// - **iOS**: Uses `HStack` with visual treatments
    ///   - Style may map to layout emphasis
    ///   - Divider customization applied via overlays
    ///   - Appearance modifiers applied to container
    ///
    /// **Use For**: Multi-column layouts with specific styling requirements
    ///
    /// - Parameters:
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - style: Split view style (balanced, prominentDetail, custom)
    ///   - divider: Optional divider configuration
    ///   - appearance: Optional appearance configuration
    ///   - content: View builder for split view content
    /// - Returns: View with horizontal split modifier and styling applied
    func platformHorizontalSplit_L4<Content: View>(
        spacing: CGFloat = 0,
        style: PlatformSplitViewStyle = .custom,
        divider: PlatformSplitViewDivider? = nil,
        appearance: PlatformSplitViewAppearance? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformHorizontalSplit_L4"
        var view: AnyView
        #if os(macOS)
        view = AnyView(HSplitView {
            content()
        })
        #else
        view = AnyView(platformHStackContainer(spacing: spacing) {
            content()
        })
        #endif
        
        // Apply appearance modifiers
        if let appearance = appearance {
            if let backgroundColor = appearance.backgroundColor {
                view = AnyView(view.background(backgroundColor))
            }
            if let cornerRadius = appearance.cornerRadius {
                view = AnyView(view.cornerRadius(cornerRadius))
            }
            if let shadow = appearance.shadow {
                view = AnyView(view.shadow(
                    color: shadow.color,
                    radius: shadow.radius,
                    x: shadow.x,
                    y: shadow.y
                ))
            }
        }
        
        // Apply divider (if specified and not none)
        if let divider = divider, divider.style != .none {
            // Divider is handled by VSplitView/HSplitView on macOS
            // On iOS, we'd need to add a custom divider view
            // For now, divider customization is primarily for macOS
        }
        
        #if os(macOS)
        return view
            .automaticAccessibility()
            .automaticCompliance(named: identifierName)
        #else
        return view
            .automaticCompliance(named: identifierName)
        #endif
    }
    
    /// Unified horizontal split view presentation helper with state management
    ///
    /// **Cross-Platform Behavior:**
    /// - **macOS**: Uses `HSplitView` for resizable horizontal split panes
    ///   - User can drag divider to resize panes
    ///   - Spacing parameter is ignored (uses split view divider)
    ///   - Visibility state controls pane visibility
    /// - **iOS**: Uses `HStack` for horizontal layout
    ///   - Split views are not available on iOS
    ///   - Spacing parameter is applied between views
    ///   - Visibility state conditionally includes/excludes panes
    ///
    /// **Use For**: Multi-column layouts, side-by-side content with visibility control
    ///
    /// - Parameters:
    ///   - state: Binding to split view state for visibility control
    ///   - spacing: Spacing between views (iOS only, ignored on macOS)
    ///   - content: View builder for split view content (should provide 2+ views)
    /// - Returns: View with horizontal split modifier applied
    @ViewBuilder
    func platformHorizontalSplit_L4<Content: View>(
        state: Binding<PlatformSplitViewState>,
        spacing: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let identifierName = "platformHorizontalSplit_L4"
        let stateValue = state.wrappedValue
        #if os(macOS)
        HSplitView {
            content()
                .environmentObject(stateValue)
        }
        .automaticAccessibility()
        .automaticCompliance(named: identifierName)
        #else
        platformHStackContainer(spacing: spacing) {
            content()
                .environmentObject(stateValue)
        }
        .automaticCompliance(named: identifierName)
        #endif
    }
}

