import SwiftUI

// MARK: - Platform Navigation Split View Helpers

/// Platform-aware 2-column navigation split view helper
/// Automatically chooses the appropriate navigation pattern based on device type, orientation, and screen size
///
/// **iOS Behavior:**
/// - **iPad**: Always uses `NavigationSplitView` (regardless of orientation)
/// - **iPhone Portrait**: Uses `NavigationStack` (detail-only with content accessible via navigation)
/// - **iPhone Landscape**: Uses `NavigationSplitView` for large devices (Plus/ProMax), `NavigationStack` for smaller devices
///
/// **macOS Behavior:**
/// - Always uses `NavigationSplitView` (package platforms require macOS 15+)
///
/// - Parameters:
///   - content: View builder for the content column
///   - detail: View builder for the detail column
/// - Returns: A view with platform-appropriate navigation pattern
@MainActor
@ViewBuilder
public func platformNavigationSplitView<Content: View, Detail: View>(
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
) -> some View {
    #if os(iOS)
    let deviceType = DeviceType.current
    let deviceCapabilities = DeviceCapabilities()
    let orientation = deviceCapabilities.orientation
    let screenSize = deviceCapabilities.screenSize
    
    let iPhoneSizeCategory: iPhoneSizeCategory? = deviceType == .phone 
        ? iPhoneSizeCategory.from(screenSize: screenSize) 
        : nil
    
    let decision = determineAppNavigationStrategy_L2(
        deviceType: deviceType,
        orientation: orientation,
        screenSize: screenSize,
        iPhoneSizeCategory: iPhoneSizeCategory
    )
    
    // Package platforms require iOS 17+ (#340).
    if decision.useSplitView {
        NavigationSplitView {
            content()
        } detail: {
            detail()
        }
    } else {
        NavigationStack {
            detail()
        }
    }
    #elseif os(macOS)
    // Package platforms require macOS 15+ (#340).
    NavigationSplitView {
        content()
    } detail: {
        detail()
    }
    #else
    NavigationView {
        content()
    }
    #endif
}

/// Platform-aware 3-column navigation split view helper
/// Automatically chooses the appropriate navigation pattern based on device type, orientation, and screen size
///
/// **iOS Behavior:**
/// - **iPad**: Always uses `NavigationSplitView` with sidebar, content, and detail columns
/// - **iPhone Portrait**: Uses `NavigationStack` (detail-only, sidebar and content accessible via navigation)
/// - **iPhone Landscape**: Uses `NavigationSplitView` for large devices (Plus/ProMax), `NavigationStack` for smaller devices
///
/// **macOS Behavior:**
/// - Always uses `NavigationSplitView` with all three columns (package platforms require macOS 15+)
///
/// - Parameters:
///   - sidebar: View builder for the sidebar column
///   - content: View builder for the content column
///   - detail: View builder for the detail column
/// - Returns: A view with platform-appropriate navigation pattern
@MainActor
@ViewBuilder
public func platformNavigationSplitView<Sidebar: View, Content: View, Detail: View>(
    @ViewBuilder sidebar: () -> Sidebar,
    @ViewBuilder content: () -> Content,
    @ViewBuilder detail: () -> Detail
) -> some View {
    #if os(iOS)
    let deviceType = DeviceType.current
    let deviceCapabilities = DeviceCapabilities()
    let orientation = deviceCapabilities.orientation
    let screenSize = deviceCapabilities.screenSize
    
    let iPhoneSizeCategory: iPhoneSizeCategory? = deviceType == .phone 
        ? iPhoneSizeCategory.from(screenSize: screenSize) 
        : nil
    
    let decision = determineAppNavigationStrategy_L2(
        deviceType: deviceType,
        orientation: orientation,
        screenSize: screenSize,
        iPhoneSizeCategory: iPhoneSizeCategory
    )
    
    // Package platforms require iOS 17+ (#340).
    if decision.useSplitView {
        NavigationSplitView {
            sidebar()
        } content: {
            content()
        } detail: {
            detail()
        }
    } else {
        NavigationStack {
            detail()
        }
    }
    #elseif os(macOS)
    // Package platforms require macOS 15+ (#340).
    NavigationSplitView {
        sidebar()
    } content: {
        content()
    } detail: {
        detail()
    }
    #else
    NavigationView {
        sidebar()
    }
    #endif
}

// MARK: - Cross-Platform Navigation Helpers

/// Cross-platform navigation helpers that provide consistent behavior
/// while properly handling platform differences
@MainActor
public struct PlatformNavigationHelpers {
    
    /// Cross-platform app navigation with platform-specific behavior
    /// iOS: Uses NavigationSplitView; macOS: Uses NavigationSplitView
        static func platformAppNavigation<SidebarContent: View, DetailContent: View>(
        columnVisibility: Binding<Bool>,
        showingSidebar: Binding<Bool>,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        #if os(iOS)
        return iosAppNavigation(columnVisibility: columnVisibility, showingSidebar: showingSidebar, sidebar: sidebar, detail: detail)
        #elseif os(macOS)
        return macAppNavigation(columnVisibility: columnVisibility, showingSidebar: showingSidebar, sidebar: sidebar, detail: detail)
        #else
        return fallbackAppNavigation(sidebar: sidebar, detail: detail)
        #endif
    }
    
    /// Cross-platform navigation action with platform-specific behavior
    /// iOS: Hides sidebar after navigation; macOS: Maintains sidebar state
        static func platformNavigationAction<T>(
        to pane: T,
        selectedPane: Binding<T?>,
        columnVisibility: Binding<Bool>?,
        showingSidebar: Binding<Bool>?
    ) {
        #if os(iOS)
        iosNavigationAction(to: pane, selectedPane: selectedPane, columnVisibility: columnVisibility, showingSidebar: showingSidebar)
        #elseif os(macOS)
        macNavigationAction(to: pane, selectedPane: selectedPane, columnVisibility: columnVisibility, showingSidebar: showingSidebar)
        #else
        fallbackNavigationAction(to: pane, selectedPane: selectedPane)
        #endif
    }
}

// MARK: - Platform-Specific Navigation Components

#if os(iOS)
/// iOS-specific app navigation implementation
private func iosAppNavigation<SidebarContent: View, DetailContent: View>(
    columnVisibility: Binding<Bool>,
    showingSidebar: Binding<Bool>,
    @ViewBuilder sidebar: () -> SidebarContent,
    @ViewBuilder detail: () -> DetailContent
) -> some View {
    // Package platforms require iOS 17+ (#340).
    NavigationSplitView {
        sidebar()
    } detail: {
        detail()
    }
}

/// iOS-specific navigation action implementation
private func iosNavigationAction<T>(
    to pane: T,
    selectedPane: Binding<T?>,
    columnVisibility: Binding<Bool>?,
    showingSidebar: Binding<Bool>?
) {
    // Update selection
    selectedPane.wrappedValue = pane
    
    // iOS: Hide sidebar after navigation (mobile users expect full-screen content)
    if let cv = columnVisibility {
        cv.wrappedValue = false
    }
    // Don't force sidebar visibility on iOS
}
#endif

#if os(macOS)
/// macOS-specific app navigation implementation
private func macAppNavigation<SidebarContent: View, DetailContent: View>(
    columnVisibility: Binding<Bool>,
    showingSidebar: Binding<Bool>,
    @ViewBuilder sidebar: () -> SidebarContent,
    @ViewBuilder detail: () -> DetailContent
) -> some View {
    // Package platforms require macOS 15+ (#340).
    NavigationSplitView {
        sidebar()
    } detail: {
        detail()
    }
}

/// macOS-specific navigation action implementation
private func macNavigationAction<T>(
    to pane: T,
    selectedPane: Binding<T?>,
    columnVisibility: Binding<Bool>?,
    showingSidebar: Binding<Bool>?
) {
    // Update selection
    selectedPane.wrappedValue = pane
    
    // macOS: Maintain sidebar state for desktop users
    if let cv = columnVisibility {
        cv.wrappedValue = true
    }
}
#endif

/// Fallback navigation action for other platforms
private func fallbackNavigationAction<T>(
    to pane: T,
    selectedPane: Binding<T?>
) {
    selectedPane.wrappedValue = pane
}

/// Fallback app navigation for other platforms
private func fallbackAppNavigation<SidebarContent: View, DetailContent: View>(
    @ViewBuilder sidebar: () -> SidebarContent,
    @ViewBuilder detail: () -> DetailContent
) -> some View {
    detail()
}
