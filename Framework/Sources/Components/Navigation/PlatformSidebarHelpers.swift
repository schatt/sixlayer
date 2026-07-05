import SwiftUI

// MARK: - Cross-Platform Sidebar Helpers

/// Cross-platform sidebar helpers that provide consistent behavior
/// while properly handling platform differences
public extension View {
    
    /// Cross-platform sidebar toggle button with platform-specific behavior
    /// iOS: Toggles sidebar visibility; macOS: Toggles sidebar visibility
    func platformSidebarToggleButton(columnVisibility: Binding<Bool>) -> some View {
        #if os(iOS)
        return iosSidebarToggleButton(columnVisibility: columnVisibility)
        #elseif os(macOS)
        return macSidebarToggleButton(columnVisibility: columnVisibility)
        #else
        return fallbackSidebarToggleButton(columnVisibility: columnVisibility)
        #endif
    }
    
    /// Cross-platform sidebar with platform-specific behavior
    /// iOS: No-op (no sidebar support); macOS: Full sidebar support
    func platformSidebar<Content: View>(
        columnVisibility: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        #if os(iOS)
        return iosSidebar(columnVisibility: columnVisibility, content: content)
        #elseif os(macOS)
        return macSidebar(columnVisibility: columnVisibility, content: content)
        #else
        return fallbackSidebar(content: content)
        #endif
    }

    /// Optional edge affordance and reveal gesture for split views in **detail-only** visibility (#324).
    ///
    /// **Automatic (Layer 4):** ``platformAppNavigation_L4(columnVisibility:…)`` and
    /// ``platformSettingsContainer_L4(columnVisibility:…)`` apply this on the detail column when a
    /// ``NavigationSplitViewVisibility`` binding is supplied.
    ///
    /// **Manual:** use on custom split/detail layouts that are not wrapped by those L4 helpers but
    /// still drive ``NavigationSplitView`` via the same binding.
    @ViewBuilder
    func platformSidebarSplitRevealChrome(
        columnVisibility: Binding<NavigationSplitViewVisibility>?
    ) -> some View {
        if let columnVisibility {
            modifier(PlatformSidebarSplitRevealChromeModifier(columnVisibility: columnVisibility))
        } else {
            self
        }
    }
}

// MARK: - Platform-Specific Sidebar Components

#if os(iOS)
/// iOS-specific sidebar toggle button implementation
private func iosSidebarToggleButton(columnVisibility: Binding<Bool>) -> some View {
    Button(action: {
        if #available(iOS 16.0, *) {
            // Toggle sidebar visibility
            columnVisibility.wrappedValue.toggle()
        } else {
            // No sidebar support in iOS 15
        }
    }) {
        Image(systemName: "sidebar.left")
    }
    .accessibilityLabel("Toggle Sidebar")
    .accessibilityHint("Show or hide the navigation sidebar")
    .disabled(!ProcessInfo.processInfo.isiOSAppOnMac && ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 16)
}

/// iOS-specific sidebar implementation
private func iosSidebar<Content: View>(
    columnVisibility: Binding<Bool>,
    @ViewBuilder content: () -> Content
) -> some View {
    // iOS doesn't have navigationSplitViewColumnVisibility
    return content()
}
#endif

#if os(macOS)
/// macOS-specific sidebar toggle button implementation
private func macSidebarToggleButton(columnVisibility: Binding<Bool>) -> some View {
    Button(action: {
        columnVisibility.wrappedValue.toggle()
    }) {
        Image(systemName: "sidebar.left")
    }
    .accessibilityLabel("Toggle Sidebar")
    .accessibilityHint("Show or hide the navigation sidebar")
}

/// macOS-specific sidebar implementation
private func macSidebar<Content: View>(
    columnVisibility: Binding<Bool>,
    @ViewBuilder content: () -> Content
) -> some View {
    // macOS has full sidebar support
    return content()
}
#endif

/// Fallback sidebar toggle button for other platforms
private func fallbackSidebarToggleButton(columnVisibility: Binding<Bool>) -> some View {
    Button(action: {
        columnVisibility.wrappedValue.toggle()
    }) {
        Image(systemName: "sidebar.left")
    }
    .accessibilityLabel("Toggle Sidebar")
    .accessibilityHint("Show or hide the navigation sidebar")
}

/// Fallback sidebar for other platforms
private func fallbackSidebar<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    return content()
}

// MARK: - Platform Sidebar Pull Indicator

/// Platform-specific sidebar pull indicator (#64, extended #324).
///
/// Shows a leading-edge stripe on **iOS and macOS** when ``isVisible`` is true (typically when the
/// split is detail-only). Other platforms return ``EmptyView``.
///
/// Prefer ``View/platformSidebarSplitRevealChrome(columnVisibility:)`` when you have a
/// ``NavigationSplitViewVisibility`` binding; use this function directly only for custom visibility logic.
///
/// ## Usage Example
/// ```swift
/// HStack {
///     platformSidebarPullIndicator(isVisible: sidebarIsResizable)
///     SidebarContent()
/// }
/// ```
@MainActor
@ViewBuilder
public func platformSidebarPullIndicator(isVisible: Bool) -> some View {
    if isVisible {
        platformSidebarPullIndicatorStripe()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    } else {
        EmptyView()
    }
}

@MainActor
@ViewBuilder
private func platformSidebarPullIndicatorStripe() -> some View {
    #if os(iOS) || os(macOS)
    HStack(spacing: 0) {
        platformHStackContainer(spacing: 2) {
            ForEach(0..<2, id: \.self) { _ in
                Rectangle()
                    .fill(Color.secondary.opacity(0.85))
                    .frame(width: 3, height: 22)
                    .cornerRadius(1)
            }
        }
        .padding(.leading, 8)
        Spacer(minLength: 0)
    }
    #else
    EmptyView()
    #endif
}

// MARK: - Split reveal chrome modifier (#324)

private struct PlatformSidebarSplitRevealChromeModifier: ViewModifier {
    @Binding var columnVisibility: NavigationSplitViewVisibility

    init(columnVisibility: Binding<NavigationSplitViewVisibility>) {
        _columnVisibility = columnVisibility
    }

    func body(content: Content) -> some View {
        let showAffordance = PlatformSidebarRevealChromePolicy.showsAffordance(for: columnVisibility)
        let applyGesture = PlatformSidebarRevealChromePolicy.shouldApplyRevealGesture(for: columnVisibility)

        ZStack(alignment: .leading) {
            content
            platformSidebarPullIndicator(isVisible: showAffordance)
        }
        .overlay(alignment: .leading) {
            if applyGesture {
                PlatformSidebarRevealEdgeGestureOverlay(columnVisibility: $columnVisibility)
            }
        }
    }
}

#if os(iOS)
/// Narrow leading-edge swipe target so scroll views in the detail column keep priority.
private struct PlatformSidebarRevealEdgeGestureOverlay: View {
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        Color.clear
            .frame(width: 24)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        guard PlatformSidebarRevealChromePolicy.shouldApplyRevealGesture(
                            for: columnVisibility
                        ) else { return }
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)
                        if horizontal > PlatformSidebarRevealChromePolicy.revealSwipeMinimumTranslation,
                           vertical < PlatformSidebarRevealChromePolicy.revealSwipeMaximumVerticalDrift {
                            columnVisibility = PlatformSidebarRevealChromePolicy.visibilityAfterReveal()
                        }
                    }
            )
            .accessibilityLabel("Show sidebar")
            .accessibilityHint("Swipe right to reveal the navigation sidebar")
            .accessibilityAddTraits(.isButton)
    }
}
#else
private struct PlatformSidebarRevealEdgeGestureOverlay: View {
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        EmptyView()
    }
}
#endif
