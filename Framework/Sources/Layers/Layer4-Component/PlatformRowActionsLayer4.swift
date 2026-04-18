import SwiftUI

// MARK: - Platform Row Actions Layer 4: Component Implementation

/// Platform-agnostic helpers for row actions (swipe actions, context menus, etc.)
/// Implements Issue #13: Add Row Actions Helpers to Six-Layer Architecture (Layer 4)
///
/// ## Cross-Platform Behavior
///
/// ### Row Actions (`platformRowActions_L4`)
/// **Semantic Purpose**: Quick actions available for list/table rows
/// - **iOS**: Uses `.swipeActions()` - swipe left/right on row to reveal actions
///   - Touch-based interaction (swipe gesture)
///   - Actions appear as buttons that slide in from the edge
///   - Supports full-swipe to trigger first action quickly
///   - Leading edge: Swipe right to reveal
///   - Trailing edge: Swipe left to reveal (most common)
/// - **macOS**: Uses `.contextMenu()` - right-click on row to reveal actions
///   - Mouse-based interaction (right-click)
///   - Actions appear as a context menu
///   - More traditional desktop interaction pattern
///
/// **When to Use**: Delete, edit, share, or other quick actions on list items
/// **Interaction Model**: iOS = swipe gesture, macOS = right-click menu
///
/// ### Context Menus (`platformContextMenu_L4`)
/// **Semantic Purpose**: Secondary actions and information via long-press/right-click
/// - **iOS**: 
///   - Long press (or 3D Touch on supported devices) to reveal
///   - Supports preview (iOS 16+) - shows preview of content before menu
///   - More visual, preview-based interaction
/// - **macOS**: 
///   - Right-click to reveal
///   - More commonly used than on iOS
///   - No preview support (macOS context menus don't support previews)
///   - Traditional desktop context menu pattern
///
/// **When to Use**: Secondary actions, information, or navigation options
/// **Interaction Model**: iOS = long press with preview, macOS = right-click menu
///
/// ## Platform Mapping
///
/// | Concept | iOS Interaction | macOS Interaction | Unified API |
/// |---------|----------------|-------------------|------------|
/// | Row Actions | Swipe gesture | Right-click menu | `platformRowActions_L4()` |
/// | Context Menu | Long press (with preview) | Right-click | `platformContextMenu_L4()` |
///
/// **Note**: The unified API automatically uses the appropriate interaction model for each platform.
/// Developers don't need to handle platform differences - the framework adapts automatically.
public extension View {
    
    /// Unified row action presentation helper
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS**: Swipe left/right on row to reveal action buttons
    ///   - Touch-based swipe gesture
    ///   - Actions slide in from the specified edge
    ///   - Supports full-swipe to quickly trigger first action
    /// - **macOS**: Right-click on row to reveal context menu with actions
    ///   - Mouse-based right-click interaction
    ///   - Actions appear as menu items
    ///
    /// **Use For**: Quick actions like delete, edit, share on list/table rows
    ///
    /// - Parameters:
    ///   - edge: Edge where actions appear (default: .trailing)
    ///   - allowsFullSwipe: Whether to allow full swipe to trigger first action (iOS only, ignored on macOS)
    ///   - actions: View builder for action buttons
    /// - Returns: View with row actions modifier applied
    @ViewBuilder
    func platformRowActions_L4<Actions: View>(
        edge: HorizontalEdge = .trailing,
        allowsFullSwipe: Bool = false,
        @ViewBuilder actions: @escaping () -> Actions
    ) -> some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            self.swipeActions(edge: edge, allowsFullSwipe: allowsFullSwipe) {
                actions()
            }
            .automaticCompliance(named: "platformRowActions_L4")
        } else {
            // Fallback for older iOS versions
            self
                .automaticCompliance(named: "platformRowActions_L4")
        }
        #elseif os(macOS)
        // macOS uses context menus for row actions
        self.contextMenu {
            actions()
        }
        .automaticCompliance(named: "platformRowActions_L4")
        #else
        self
            .automaticCompliance(named: "platformRowActions_L4")
        #endif
    }
    
    /// Unified context menu presentation helper (without preview)
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS**: Long press to reveal menu
    ///   - Touch-based long press gesture
    /// - **macOS**: Right-click to reveal menu
    ///   - Mouse-based right-click interaction
    ///   - Traditional desktop context menu
    ///
    /// **Use For**: Secondary actions, information, or navigation options
    ///
    /// - Parameters:
    ///   - menuItems: View builder for menu items
    /// - Returns: View with context menu modifier applied
    func platformContextMenu_L4<MenuItems: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems
    ) -> some View {
        #if os(iOS)
        self.contextMenu {
            menuItems()
        }
        .automaticCompliance(named: "platformContextMenu_L4")
        #elseif os(macOS)
        self.contextMenu {
            menuItems()
        }
        .automaticCompliance(named: "platformContextMenu_L4")
        #else
        self
            .automaticCompliance(named: "platformContextMenu_L4")
        #endif
    }
    
    /// Unified context menu presentation helper (with preview for iOS)
    ///
    /// **Cross-Platform Behavior:**
    /// - **iOS**: Long press to reveal menu with optional preview (iOS 16+)
    ///   - Touch-based long press gesture
    ///   - Preview shows content before menu appears (if provided)
    ///   - More visual, preview-based interaction
    /// - **macOS**: Right-click to reveal menu
    ///   - Mouse-based right-click interaction
    ///   - Preview parameter is ignored (macOS doesn't support previews)
    ///   - Traditional desktop context menu
    ///
    /// **Use For**: Secondary actions, information, or navigation options with preview
    ///
    /// - Parameters:
    ///   - menuItems: View builder for menu items
    ///   - preview: Preview view for iOS (ignored on macOS)
    /// - Returns: View with context menu modifier applied
    @available(iOS 16.0, *)
    func platformContextMenu_L4<MenuItems: View, Preview: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems,
        @ViewBuilder preview: @escaping () -> Preview
    ) -> some View {
        #if os(iOS)
        self.contextMenu {
            menuItems()
        } preview: {
            preview()
        }
        .automaticCompliance(named: "platformContextMenu_L4")
        #elseif os(macOS)
        // macOS doesn't support preview, so ignore it
        self.contextMenu {
            menuItems()
        }
        .automaticCompliance(named: "platformContextMenu_L4")
        #else
        self
            .automaticCompliance(named: "platformContextMenu_L4")
        #endif
    }
}

// MARK: - Row Action Button Helpers

/// Helper for creating row action buttons with consistent styling
public struct PlatformRowActionButton: View {
    let title: String
    let systemImage: String?
    let role: ButtonRole?
    let action: () -> Void
    
    public init(
        title: String,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
    
    public var body: some View {
        Button(role: role, action: action) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
        }
    }
}

/// Helper for creating destructive row action buttons
public struct PlatformDestructiveRowActionButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    public init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    public var body: some View {
        PlatformRowActionButton(
            title: title,
            systemImage: systemImage,
            role: .destructive,
            action: action
        )
    }
}

