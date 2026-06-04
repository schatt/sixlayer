import SwiftUI

// MARK: - Platform Navigation Layer 4: Component Implementation
/// This layer provides platform-specific navigation components that implement
/// navigation patterns across iOS and macOS. This layer handles the specific
/// implementation of navigation components.

// MARK: - Navigation Types
// PlatformTitleDisplayMode is defined in PlatformUITypes.swift

// MARK: - Layer 4 compact outer overlay (issue #206)

private let layer4OverlayShowSidebarAccessibilityIdentifier = "L4OverlayShowSidebar"
private let layer4OverlayCloseSidebarAccessibilityIdentifier = "L4OverlayCloseSidebar"
private let layer4OverlayModalRootAccessibilityIdentifier = "L4OverlayModalRoot"

/// Detail-first shell with toolbar affordance and dismissible sheet for the outer sidebar (no column squeeze).
private struct Layer4OuterSidebarOverlayHost<SidebarSheet: View, Detail: View>: View {
    @State private var isOuterSidebarPresented = false
    @ViewBuilder let sidebarSheet: () -> SidebarSheet
    let detailContent: Detail

    @ViewBuilder
    private func overlaySheetContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                isOuterSidebarPresented = false
            } label: {
                Text("Close sidebar")
            }
            .accessibilityLabel("Close sidebar")
            .accessibilityHint("Dismisses the sidebar overlay and returns focus to the show sidebar button")
            .accessibilityIdentifier(layer4OverlayCloseSidebarAccessibilityIdentifier)
            sidebarSheet()
        }
        .padding()
        .accessibilityIdentifier(layer4OverlayModalRootAccessibilityIdentifier)
        .accessibilityAddTraits(.isModal)
    }

    var body: some View {
        let accessibilityState = NavigationLayoutResolver.layer4OverlayAccessibilityState(
            isOverlayPresented: isOuterSidebarPresented
        )
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    detailContent
                }
            } else {
                NavigationView {
                    detailContent
                }
            }
            #elseif os(macOS)
            NavigationStack {
                detailContent
            }
            #else
            detailContent
            #endif
        }
        .accessibilityHidden(accessibilityState.isUnderlyingContentAccessibilityHidden)
        .toolbar {
            // `.primaryAction` can fold into overflow on compact widths, hiding the control from XCUITest (#207).
            // Use `platformToolbarPlacement(.trailing)`: `.navigationBarTrailing` on iOS; `.automatic` on macOS (trailing unavailable there).
            ToolbarItem(placement: self.platformToolbarPlacement(.trailing)) {
                Button {
                    isOuterSidebarPresented = true
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .accessibilityLabel("Show sidebar")
                .accessibilityIdentifier(layer4OverlayShowSidebarAccessibilityIdentifier)
            }
        }
        .sheet(isPresented: $isOuterSidebarPresented) {
            overlaySheetContent()
        }
    }
}

// MARK: - Layer 4 measured split shell (issue #208)

/// Maps `NavigationSplitViewVisibility.detailOnly` into the compact presentation seed used with measured width (#208).
internal enum Layer4MeasuredSplitPresentationSync {
    static func seededPresentation(isDetailOnlyColumn: Bool) -> NavigationLayoutCompactPresentation? {
        isDetailOnlyColumn ? .detailOnlyCollapsedInner : nil
    }

    static func seededPresentation(columnVisibility: Binding<NavigationSplitViewVisibility>?) -> NavigationLayoutCompactPresentation? {
        seededPresentation(isDetailOnlyColumn: columnVisibility.map { $0.wrappedValue.isExplicitDetailOnly } ?? false)
    }
}

/// Hosts nested split shells with **container width** from `GeometryReader` and
/// `NavigationLayoutResolver.layer4CompactPresentationForTransition` so resize churn does not thrash modes.
private struct Layer4NestedSplitShellPresentationHost<Sidebar: View, Detail: View>: View {
    enum ShellKind: Equatable {
        case appNavigation
        case appNavigationMacOS12
        case settingsIPad
        case settingsMacOS
    }

    @State private var persistedPresentation: NavigationLayoutCompactPresentation?
    let kind: ShellKind
    let columnVisibility: Binding<NavigationSplitViewVisibility>?
    let sidebar: () -> Sidebar
    let detail: () -> Detail

    init(
        kind: ShellKind,
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.kind = kind
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar
        self.detail = detail
    }

    var body: some View {
        GeometryReader { geo in
            let width = NavigationLayoutResolver.layer4SanitizedSplitAxisWidthForPresentation(geo.size.width)
            let fresh = NavigationLayoutResolver.layer4CompactPresentation(forAvailableWidth: width)
            let columnSeeded = columnSeededPresentation()
            let prev = persistedPresentation ?? columnSeeded ?? fresh
            let presentation = NavigationLayoutResolver.layer4CompactPresentationForTransition(
                availableWidth: width,
                previousPresentation: prev
            )
            shellContent(presentation: presentation)
                .task(id: widthTaskID(width)) {
                    syncPersistedPresentationForWidth(width)
                }
                .onChange(of: columnVisibility.map { $0.wrappedValue }) { _, visibility in
                    applyColumnVisibilityToPersistedPresentation(visibility)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func columnSeededPresentation() -> NavigationLayoutCompactPresentation? {
        Layer4MeasuredSplitPresentationSync.seededPresentation(columnVisibility: columnVisibility)
    }

    private func syncPersistedPresentationForWidth(_ width: CGFloat) {
        let fresh = NavigationLayoutResolver.layer4CompactPresentation(forAvailableWidth: width)
        let seeded = columnSeededPresentation()
        let previous = persistedPresentation ?? seeded ?? fresh
        persistedPresentation = NavigationLayoutResolver.layer4CompactPresentationForTransition(
            availableWidth: width,
            previousPresentation: previous
        )
    }

    private func applyColumnVisibilityToPersistedPresentation(_ visibility: NavigationSplitViewVisibility?) {
        guard let visibility else { return }
        if visibility.isExplicitDetailOnly {
            persistedPresentation = .detailOnlyCollapsedInner
        } else if persistedPresentation == .detailOnlyCollapsedInner {
            persistedPresentation = nil
        }
    }

    private func widthTaskID(_ w: CGFloat) -> Int {
        Int((w * 100).rounded(.towardZero))
    }

    @ViewBuilder
    private func shellContent(presentation: NavigationLayoutCompactPresentation) -> some View {
        switch kind {
        case .appNavigation:
            EmptyView().layer4CreateAppNavigationSplitView(
                presentation: presentation,
                columnVisibility: columnVisibility,
                sidebar: sidebar,
                detail: detail
            )
        case .appNavigationMacOS12:
            EmptyView().layer4CreateAppNavigationMacOS12Split(
                presentation: presentation,
                sidebar: sidebar,
                detail: detail
            )
        case .settingsIPad:
            EmptyView().layer4CreateSettingsContainerForiPad(
                presentation: presentation,
                columnVisibility: columnVisibility,
                sidebar: sidebar,
                detail: detail
            )
        case .settingsMacOS:
            EmptyView().layer4CreateSettingsContainerForMacOS(
                presentation: presentation,
                columnVisibility: columnVisibility,
                sidebar: sidebar,
                detail: detail
            )
        }
    }
}

public extension View {
    
    /// Platform-specific navigation wrapper that provides consistent navigation patterns
    /// across iOS and macOS. On iOS 16+, wraps content in NavigationStack; iOS 15, wraps in NavigationView.
    /// On macOS, returns the content directly.
    /// Layer 4: Component Implementation
    func platformNavigation_L4<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let baseView: AnyView = {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                // Use NavigationStack on iOS 16+
                return AnyView(NavigationStack {
                    content()
                })
            } else {
                // Fallback to NavigationView for iOS 15 and earlier
                return AnyView(NavigationView {
                    content()
                })
            }
            #else
            return AnyView(content())
            #endif
        }()
        return baseView
    }
    

    /// Platform-conditional navigation destination hook
    /// iOS: forwards to .navigationDestination; macOS: no-op passthrough
    /// Layer 4: Component Implementation
    @ViewBuilder
    func platformNavigationDestination_L4<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            self.navigationDestination(item: item, destination: destination)
        } else {
            // iOS 15-16 fallback: no navigation destination support
            self
        }
        #else
        self
        #endif
    }
    

    /// Platform-specific navigation button with consistent styling and accessibility
    /// Layer 4: Component Implementation
    /// - Parameters:
    ///   - title: The button title text
    ///   - systemImage: The SF Symbol name for the button icon
    ///   - accessibilityLabel: Accessibility label for screen readers
    ///   - accessibilityHint: Accessibility hint for screen readers
    ///   - action: The action to perform when the button is tapped
    /// - Returns: A view with platform-specific navigation button styling
    func platformNavigationButton_L4(
        title: String,
        systemImage: String,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            #if os(macOS)
            if #available(macOS 11.0, *) {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.primary)
            } else {
                HStack {
                    Image(systemName: systemImage)
                    Text(title)
                }
                .foregroundColor(.primary)
            }
            #else
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            #endif
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        // Apply automaticCompliance directly to the Button so identifier goes to Button, not container
        // Pass hints as parameters (Option A) - explicit, no environment dependencies
        // Auto-generate identifierName from title (the thing being identified)
        .automaticCompliance(
            identifierName: sanitizeLabelText(title),
            identifierLabel: title,
            accessibilitySortPriority: 5.0  // Issue #165: Navigation elements have medium priority
        )
    }
    

    /// Platform-specific navigation title configuration
    /// Layer 4: Component Implementation
    func platformNavigationTitle_L4(_ title: String) -> some View {
        #if os(iOS)
        return self.navigationTitle(title)
            .automaticCompliance(
                identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
                identifierElementType: "Header",
                identifierLabel: title,
                accessibilityTraits: .isHeader  // Issue #165: Navigation titles are headers
            )
        #elseif os(macOS)
        return self.navigationTitle(title)
            .automaticCompliance(
                identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
                identifierElementType: "Header",
                identifierLabel: title,
                accessibilityTraits: .isHeader  // Issue #165: Navigation titles are headers
            )
        #else
        return self.navigationTitle(title)
            .automaticCompliance(
                identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
                identifierElementType: "Header",
                identifierLabel: title,
                accessibilityTraits: .isHeader  // Issue #165: Navigation titles are headers
            )
        #endif
    }
    

    /// Platform-specific navigation title display mode
    ///
    /// Applies navigation title display mode consistently across platforms, eliminating
    /// the need for platform-specific conditional compilation.
    ///
    /// - **iOS**: Applies `.navigationBarTitleDisplayMode()` with the specified mode
    /// - **macOS**: No-op (macOS doesn't have this concept)
    /// - **Other platforms**: No-op
    ///
    /// Available modes via `PlatformTitleDisplayMode`:
    /// - `.inline` - Compact inline title
    /// - `.large` - Large title style
    /// - `.automatic` - Platform-determined style
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // ✅ Good: Use platform abstraction (no conditional compilation needed)
    /// Text("Content")
    ///     .platformNavigationTitle_L4("My Title")
    ///     .platformNavigationTitleDisplayMode_L4(.inline)
    ///
    /// // ❌ Avoid: Platform-specific conditional compilation
    /// Text("Content")
    ///     .navigationTitle("My Title")
    ///     #if os(iOS)
    ///     .navigationBarTitleDisplayMode(.inline)
    ///     #endif
    /// ```
    ///
    /// - Parameter displayMode: The display mode to apply (`.inline`, `.large`, or `.automatic`)
    /// - Returns: A view with the platform-appropriate navigation title display mode applied
    /// Layer 4: Component Implementation
    func platformNavigationTitleDisplayMode_L4(_ displayMode: PlatformTitleDisplayMode) -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(displayMode.navigationBarDisplayMode)
        #else
        return self
        #endif
    }
    

    /// Platform-specific navigation bar title display mode
    /// Layer 4: Component Implementation
    func platformNavigationBarTitleDisplayMode_L4(_ displayMode: PlatformTitleDisplayMode) -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(displayMode.navigationBarDisplayMode)
        #else
        return self
        #endif
    }
    

    // Note: platformNavigationBarBackButtonHidden moved to PlatformSpecificViewExtensions.swift
    // to consolidate with existing platform-specific logic and avoid naming conflicts

    /// Platform-specific navigation bar items with leading and trailing content
    /// Layer 4: Component Implementation
    func platformNavigationBarItems_L4<L: View, T: View>(
        leading: L,
        trailing: T
    ) -> some View {
        #if os(iOS)
        return self.navigationBarItems(leading: leading, trailing: trailing)
        #else
        return self
        #endif
    }

    /// Platform-specific navigation bar items with leading content only
    /// Layer 4: Component Implementation
    func platformNavigationBarItems_L4<L: View>(
        leading: L
    ) -> some View {
        #if os(iOS)
        return self.navigationBarItems(leading: leading)
        #else
        return self
        #endif
    }

    /// Platform-specific navigation bar items with trailing content only
    /// Layer 4: Component Implementation
    func platformNavigationBarItems_L4<T: View>(
        trailing: T
    ) -> some View {
        #if os(iOS)
        return self.navigationBarItems(trailing: trailing)
        #else
        return self
        #endif
    }

    /// Platform-specific navigation link that adapts to the platform
    /// iOS: NavigationLink; macOS: Button with navigation state
    /// Layer 4: Component Implementation
    @ViewBuilder
    func platformNavigationLink_L4<Destination: View>(
        title: String,
        systemImage: String,
        isActive: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            Button(action: { isActive.wrappedValue = true }) {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.primary)
            }
            .automaticCompliance(
                identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
                identifierElementType: "Link",
                accessibilityTraits: .isLink  // Issue #165: Navigation links are links
            )
            .navigationDestination(isPresented: isActive) {
                destination()
            }
        } else {
            Button(action: { isActive.wrappedValue = true }) {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.primary)
            }
            .automaticCompliance(
                identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
                identifierElementType: "Link",
                accessibilityTraits: .isLink  // Issue #165: Navigation links are links
            )
            .background(
                NavigationLink(destination: destination(), isActive: isActive) {
                    EmptyView()
                }
            )
        }
        #elseif os(macOS)
        Button(action: { isActive.wrappedValue = true }) {
            #if os(macOS)
            if #available(macOS 11.0, *) {
                Label(title, systemImage: systemImage)
                    .foregroundColor(.primary)
            } else {
                HStack {
                    Image(systemName: systemImage)
                    Text(title)
                }
                .foregroundColor(.primary)
            }
            #else
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            #endif
        }
        .buttonStyle(PlainButtonStyle())
        .automaticCompliance(
            identifierName: sanitizeLabelText(title),  // Auto-generate identifierName from title
            identifierElementType: "Link",
            accessibilityTraits: .isLink  // Issue #165: Navigation links are links
        )
        #endif
    }

    /// Platform-specific navigation link with destination and label
    /// Layer 4: Component Implementation
    func platformNavigationLink_L4<Destination: View, Label: View>(
        destination: Destination,
        @ViewBuilder label: () -> Label
    ) -> some View {
        #if os(iOS)
        return NavigationLink(destination: destination, label: label)
            .accessibilityAddTraits(.isLink)  // Issue #165: Navigation links are links
        #elseif os(macOS)
        return NavigationLink(destination: destination, label: label)
            .accessibilityAddTraits(.isLink)  // Issue #165: Navigation links are links
        #else
        return NavigationLink(destination: destination, label: label)
            .accessibilityAddTraits(.isLink)  // Issue #165: Navigation links are links
        #endif
    }

    /// Platform-specific navigation link with value and destination
    /// Layer 4: Component Implementation
    func platformNavigationLink_L4<Value: Hashable, Destination: View, Label: View>(
        value: Value?,
        @ViewBuilder destination: @escaping (Value) -> Destination,
        @ViewBuilder label: () -> Label
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return AnyView(NavigationLink(value: value, label: label)
                .navigationDestination(for: Value.self) { value in
                    destination(value)
                }
                .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
        } else {
            // iOS 15 fallback: use traditional NavigationLink
            if let value = value {
                return AnyView(NavigationLink(destination: destination(value), label: label)
                    .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
            } else {
                return AnyView(NavigationLink(destination: EmptyView(), label: label)
                    .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
            }
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            return AnyView(NavigationLink(value: value, label: label)
                .navigationDestination(for: Value.self) { value in
                    destination(value)
                }
                .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
        } else {
            // macOS 12 fallback: use traditional NavigationLink
            if let value = value {
                return AnyView(NavigationLink(destination: destination(value), label: label)
                    .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
            } else {
                return AnyView(NavigationLink(destination: EmptyView(), label: label)
                    .accessibilityAddTraits(.isLink))  // Issue #165: Navigation links are links
            }
        }
        #else
        return AnyView(NavigationLink(value: value, label: label)
            .accessibilityAddTraits(.isLink)  // Issue #165: Navigation links are links
            .navigationDestination(for: Value.self) { value in
                destination(value)
            })
        #endif
    }

    /// Platform-specific navigation link with tag and destination
    /// Layer 4: Component Implementation
    func platformNavigationLink_L4<Tag: Hashable, Destination: View, Label: View>(
        tag: Tag,
        selection: Binding<Tag?>,
        @ViewBuilder destination: @escaping (Tag) -> Destination,
        @ViewBuilder label: () -> Label
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            return AnyView(NavigationLink(value: tag) {
                label()
            }
            .navigationDestination(for: Tag.self) { tag in
                destination(tag)
            })
        } else {
            // iOS 15 fallback: use traditional NavigationLink
            return AnyView(NavigationLink(destination: destination(tag), label: label))
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            return AnyView(NavigationLink(value: tag) {
                label()
            }
            .navigationDestination(for: Tag.self) { tag in
                destination(tag)
            })
        } else {
            // macOS 12 fallback: use traditional NavigationLink
            return AnyView(NavigationLink(destination: destination(tag), label: label))
        }
        #else
        return AnyView(NavigationLink(value: tag) {
            label()
        }
        .navigationDestination(for: Tag.self) { tag in
            destination(tag)
        })
        #endif
    }

    // Note: platformNavigationWithPath functions moved to PlatformSpecificViewExtensions.swift
    // to consolidate with existing platform-specific logic and avoid naming conflicts

    // Removed duplicate function - NavigationPath can already handle [Data]

    // Note: platformNavigationSplitContainer moved to PlatformSemanticLayer1.swift
    // This follows the 6-layer architecture principle of handling platform-specific
    // navigation at the semantic intent layer rather than the implementation layer

    // Note: platformNavigationViewStyle moved to PlatformSpecificViewExtensions.swift
    // to consolidate with existing platform-specific logic and avoid naming conflicts
    
    // MARK: - App Navigation Layer 4
    
    /// Helper to create NavigationSplitView with optional column visibility
    @ViewBuilder
    private func createNavigationSplitView<SidebarContent: View, DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        if let columnVisibility = columnVisibility {
            NavigationSplitView(columnVisibility: columnVisibility) {
                sidebar()
            } detail: {
                layer4DetailWithOptionalRevealChrome(
                    columnVisibility: columnVisibility,
                    detail: detail
                )
            }
        } else {
            NavigationSplitView {
                sidebar()
            } detail: {
                detail()
            }
        }
    }

    /// Detail column wrapper: split-edge reveal chrome when ``columnVisibility`` is provided (#324).
    @ViewBuilder
    private func layer4DetailWithOptionalRevealChrome<DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        detail()
            .platformSidebarSplitRevealChrome(columnVisibility: columnVisibility)
    }

    // MARK: - Layer 4 nested split shell (app + settings)

    @ViewBuilder
    private func layer4ResolverDetailOnly<DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        layer4DetailWithOptionalRevealChrome(
            columnVisibility: columnVisibility,
            detail: detail
        )
    }

    private func layer4OuterSidebarOverlay<Sidebar: View, Detail: View>(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        let sidebarContent = sidebar()
        let detailContent = detail()
        return Layer4OuterSidebarOverlayHost(
            sidebarSheet: { createSidebarSheetContent(sidebarContent: sidebarContent) },
            detailContent: detailContent
        )
    }

    @ViewBuilder
    fileprivate func layer4CreateAppNavigationSplitView<SidebarContent: View, DetailContent: View>(
        presentation: NavigationLayoutCompactPresentation,
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        switch presentation {
        case .fullSplit:
            createNavigationSplitView(
                columnVisibility: columnVisibility,
                sidebar: sidebar,
                detail: detail
            )
        case .detailOnlyCollapsedInner:
            layer4ResolverDetailOnly(columnVisibility: columnVisibility, detail: detail)
        case .overlayOuterSidebar:
            layer4OuterSidebarOverlay(
                sidebar: sidebar,
                detail: detail
            )
        }
    }

    @ViewBuilder
    fileprivate func layer4CreateAppNavigationMacOS12Split<SidebarContent: View, DetailContent: View>(
        presentation: NavigationLayoutCompactPresentation,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        switch presentation {
        case .fullSplit:
            platformHStackContainer(spacing: 0) {
                sidebar()
                detail()
            }
        case .detailOnlyCollapsedInner:
            layer4ResolverDetailOnly(columnVisibility: nil, detail: detail)
        case .overlayOuterSidebar:
            layer4OuterSidebarOverlay(
                sidebar: sidebar,
                detail: detail
            )
        }
    }

    @ViewBuilder
    private func platformAppNavigationSplitViewBranch<SidebarContent: View, DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        showingNavigationSheet: Binding<Bool>?,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            let sidebarView = sidebar()
            let detailView = detail()
            Layer4NestedSplitShellPresentationHost(
                kind: .appNavigation,
                columnVisibility: columnVisibility,
                sidebar: { sidebarView },
                detail: { detailView }
            )
        } else {
            let sidebarContent = sidebar()
            createDetailOnlyWithSheet(
                showingNavigationSheet: showingNavigationSheet,
                detail: detail,
                sidebarContent: sidebarContent
            )
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            let sidebarView = sidebar()
            let detailView = detail()
            Layer4NestedSplitShellPresentationHost(
                kind: .appNavigation,
                columnVisibility: columnVisibility,
                sidebar: { sidebarView },
                detail: { detailView }
            )
        } else {
            let sidebarView = sidebar()
            let detailView = detail()
            Layer4NestedSplitShellPresentationHost(
                kind: .appNavigationMacOS12,
                columnVisibility: columnVisibility,
                sidebar: { sidebarView },
                detail: { detailView }
            )
        }
        #else
        detail()
        #endif
    }
    
    /// Helper to create sidebar sheet content with platform-appropriate navigation wrapper
    @ViewBuilder
    private func createSidebarSheetContent<SidebarContent: View>(
        sidebarContent: SidebarContent
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            NavigationStack {
                sidebarContent
            }
        } else {
            NavigationView {
                sidebarContent
            }
        }
        #elseif os(macOS)
        sidebarContent
            .frame(minWidth: 400, minHeight: 300)
        #else
        sidebarContent
        #endif
    }
    
    /// Helper to create detail-only view with sidebar sheet
    @ViewBuilder
    private func createDetailOnlyWithSheet<DetailContent: View, SidebarContent: View>(
        showingNavigationSheet: Binding<Bool>?,
        @ViewBuilder detail: () -> DetailContent,
        sidebarContent: SidebarContent
    ) -> some View {
        detail()
            .sheet(isPresented: showingNavigationSheet ?? Binding(get: { false }, set: { _ in })) {
                createSidebarSheetContent(sidebarContent: sidebarContent)
            }
    }
    
    /// Platform-specific app navigation with intelligent device-aware pattern selection
    /// Automatically chooses between NavigationSplitView and detail-only based on device capabilities
    ///
    /// **Device-Aware Behavior:**
    /// - **iPad**: Always uses NavigationSplitView
    /// - **macOS**: Always uses NavigationSplitView
    /// - **iPhone Portrait**: Detail-only view (sidebar presented as sheet)
    /// - **iPhone Landscape (Large models)**: NavigationSplitView for Plus/Pro Max models
    /// - **iPhone Landscape (Standard models)**: Detail-only view
    ///
    /// **Toolbar leading (issue #323):** On the detail (or root) view, use
    /// ``View/platformAppNavigationSheetToolbarLeading(showingNavigationSheet:columnVisibility:visibility:systemImage:accessibilityIdentifier:)``
    /// or ``View/platformNavigationSheetButton(action:sidebarVisibility:visibility:columnVisibility:systemImage:accessibilityIdentifier:)``
    /// with ``PlatformNavigationSheetButtonVisibilityPolicy/phoneOrDetailOnly`` and the same `columnVisibility` /
    /// `showingNavigationSheet` bindings so iPhone and `.detailOnly` iPad split show the menu without app `#if os(iOS)` visibility logic.
    ///
    /// - Parameters:
    ///   - columnVisibility: Optional binding for NavigationSplitView column visibility. When provided,
    ///     Layer 4 applies ``View/platformSidebarSplitRevealChrome(columnVisibility:)`` on the detail
    ///     column (edge stripe; iOS leading-edge swipe to reveal). Omit only when the app owns chrome.
    ///   - showingNavigationSheet: Optional binding for sheet presentation (iPhone detail-only mode). Wire the toolbar button `action` to set this `true` when presenting the sidebar sheet.
    ///   - strategy: App navigation strategy from Layer 3
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: A view with platform-appropriate navigation pattern
    @MainActor
    @ViewBuilder
    func platformAppNavigation_L4<SidebarContent: View, DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        showingNavigationSheet: Binding<Bool>? = nil,
        strategy: AppNavigationStrategy,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        switch strategy.implementation {
        case .splitView:
            platformAppNavigationSplitViewBranch(
                columnVisibility: columnVisibility,
                showingNavigationSheet: showingNavigationSheet,
                sidebar: sidebar,
                detail: detail
            )

        case .detailOnly:
            // Use detail-only view with optional sheet for sidebar
            // Capture sidebar content before using in escaping closure
            let sidebarContent = sidebar()
            createDetailOnlyWithSheet(
                showingNavigationSheet: showingNavigationSheet,
                detail: detail,
                sidebarContent: sidebarContent
            )
        }
    }
    
    /// Platform-specific app navigation with automatic strategy detection
    /// Convenience function that automatically determines strategy from device capabilities
    ///
    /// **Toolbar leading (issue #323):** See strategy overload — use
    /// ``View/platformAppNavigationSheetToolbarLeading(showingNavigationSheet:columnVisibility:visibility:systemImage:accessibilityIdentifier:)``
    /// on detail content with the same bindings passed here.
    ///
    /// - Parameters:
    ///   - columnVisibility: Optional binding for NavigationSplitView column visibility. When provided,
    ///     Layer 4 applies ``View/platformSidebarSplitRevealChrome(columnVisibility:)`` on the detail
    ///     column (edge stripe; iOS leading-edge swipe to reveal). Omit only when the app owns chrome.
    ///   - showingNavigationSheet: Optional binding for sheet presentation (iPhone detail-only mode)
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: A view with platform-appropriate navigation pattern
    @MainActor
    @ViewBuilder
    func platformAppNavigation_L4<SidebarContent: View, DetailContent: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        showingNavigationSheet: Binding<Bool>? = nil,
        @ViewBuilder sidebar: () -> SidebarContent,
        @ViewBuilder detail: () -> DetailContent
    ) -> some View {
        // Get current device capabilities
        let deviceType = DeviceType.current
        let deviceCapabilities = DeviceCapabilities()
        let orientation = deviceCapabilities.orientation
        let screenSize = deviceCapabilities.screenSize
        
        // Get iPhone size category if applicable
        #if os(iOS)
        let iPhoneSizeCategory: iPhoneSizeCategory? = deviceType == .phone ? iPhoneSizeCategory.from(screenSize: screenSize) : nil
        #else
        let iPhoneSizeCategory: iPhoneSizeCategory? = nil
        #endif
        
        // Layer 2: Device and orientation-aware decision making
        let l2Decision = determineAppNavigationStrategy_L2(
            deviceType: deviceType,
            orientation: orientation,
            screenSize: screenSize,
            iPhoneSizeCategory: iPhoneSizeCategory
        )
        
        // Layer 3: Platform-aware strategy selection
        let l3Strategy = selectAppNavigationStrategy_L3(
            decision: l2Decision,
            platform: SixLayerPlatform.current
        )
        
        // Use strategy-based implementation
        platformAppNavigation_L4(
            columnVisibility: columnVisibility,
            showingNavigationSheet: showingNavigationSheet,
            strategy: l3Strategy,
            sidebar: sidebar,
            detail: detail
        )
    }
    
    // MARK: - Settings Container Layer 4

    /// Helper to create settings container for iPad (NavigationSplitView)
    /// - Parameters:
    ///   - columnVisibility: Optional binding for NavigationSplitView column visibility
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: NavigationSplitView on iOS 16+, NavigationView on iOS 15
    @ViewBuilder
    fileprivate func layer4CreateSettingsContainerForiPad<Sidebar: View, Detail: View>(
        presentation: NavigationLayoutCompactPresentation,
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        switch presentation {
        case .fullSplit:
            if #available(iOS 16.0, *) {
                createNavigationSplitView(
                    columnVisibility: columnVisibility,
                    sidebar: sidebar,
                    detail: detail
                )
            } else {
                NavigationView {
                    sidebar()
                    detail()
                }
                #if os(iOS)
                .navigationViewStyle(.columns)
                #else
                .navigationViewStyle(.automatic)
                #endif
            }
        case .detailOnlyCollapsedInner:
            layer4ResolverDetailOnly(columnVisibility: columnVisibility, detail: detail)
        case .overlayOuterSidebar:
            layer4OuterSidebarOverlay(
                sidebar: sidebar,
                detail: detail
            )
        }
    }
    
    /// Helper to create settings container for iPhone (NavigationStack with push/pop semantics on iOS 16+)
    /// - Parameters:
    ///   - selectedCategory: Binding to track category selection (controls detail display)
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: NavigationStack on iOS 16+, NavigationView on iOS 15
    @ViewBuilder
    private func createSettingsContainerForiPhone<Sidebar: View, Detail: View>(
        selectedCategory: Binding<AnyHashable?>?,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                if let isPresented = PlatformManagedSettingsFlowLogic.iPhoneTopLevelDetailNavigationIsPresented(
                    selectedCategory: selectedCategory
                ) {
                    sidebar()
                        .navigationDestination(isPresented: isPresented) {
                            detail()
                        }
                } else {
                    sidebar()
                }
            }
        } else {
            // iOS 15: legacy root swap (no unified stack back semantics)
            NavigationView {
                if let selectedCategory = selectedCategory, selectedCategory.wrappedValue != nil {
                    detail()
                } else {
                    sidebar()
                }
            }
        }
    }
    
    /// Helper to create settings container for macOS (NavigationSplitView)
    /// - Parameters:
    ///   - columnVisibility: Optional binding for NavigationSplitView column visibility
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: NavigationSplitView on macOS 13+, HStack on macOS 12
    @ViewBuilder
    fileprivate func layer4CreateSettingsContainerForMacOS<Sidebar: View, Detail: View>(
        presentation: NavigationLayoutCompactPresentation,
        columnVisibility: Binding<NavigationSplitViewVisibility>?,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        switch presentation {
        case .fullSplit:
            if #available(macOS 13.0, *) {
                createNavigationSplitView(
                    columnVisibility: columnVisibility,
                    sidebar: sidebar,
                    detail: detail
                )
            } else {
                HStack(spacing: 0) {
                    sidebar()
                    detail()
                }
            }
        case .detailOnlyCollapsedInner:
            layer4ResolverDetailOnly(columnVisibility: columnVisibility, detail: detail)
        case .overlayOuterSidebar:
            layer4OuterSidebarOverlay(
                sidebar: sidebar,
                detail: detail
            )
        }
    }
    
    /// Platform-specific settings container with intelligent device-aware pattern selection
    /// Automatically chooses between NavigationSplitView and NavigationStack based on device capabilities
    ///
    /// **Semantic Purpose**: Create settings views with sidebar + detail panes that adapt to device capabilities
    ///
    /// ## Cross-Platform Behavior
    ///
    /// ### iPad Settings Container
    /// **Semantic Purpose**: Settings with sidebar and detail in split view
    /// - **iOS 16+**: Uses `NavigationSplitView` for side-by-side sidebar and detail
    ///   - Both panes visible simultaneously
    ///   - User can adjust column visibility
    ///   - Optimal for larger screen real estate
    /// - **iOS 15**: Uses `NavigationView` with columns style as fallback
    ///   - Shows both sidebar and detail in column layout
    ///   - Maintains split view appearance on iPad
    ///
    /// **When to Use**: Settings screens, preferences, configuration views on iPad
    ///
    /// ### iPhone Settings Container
    /// **Semantic Purpose**: Settings with conditional detail display
    /// - **iOS 16+**: Uses `NavigationStack` with conditional display
    ///   - Shows sidebar when `selectedCategory` is `nil`
    ///   - Shows detail when `selectedCategory` is set
    ///   - Push/pop navigation pattern
    /// - **iOS 15**: Uses `NavigationView` as fallback
    ///   - Standard navigation pattern
    ///
    /// **When to Use**: Settings screens, preferences on iPhone
    ///
    /// ### macOS Settings Container
    /// **Semantic Purpose**: Settings with sidebar and detail in split view
    /// - **macOS 13+**: Uses `NavigationSplitView` for side-by-side sidebar and detail
    ///   - Both panes visible simultaneously
    ///   - User can adjust column visibility
    ///   - Native macOS split view behavior
    /// - **macOS 12**: Uses `HStack` as fallback
    ///   - Simple horizontal layout
    ///
    /// **When to Use**: Settings screens, preferences, configuration views on macOS
    ///
    /// ## Platform Mapping
    ///
    /// | Device | iOS Version | Implementation | Behavior |
    /// |--------|------------|----------------|----------|
    /// | iPad | iOS 16+ | NavigationSplitView | Side-by-side sidebar + detail |
    /// | iPad | iOS 15 | NavigationView (.columns) | Side-by-side sidebar + detail |
    /// | iPhone | iOS 16+ | NavigationStack | Conditional: sidebar or detail |
    /// | iPhone | iOS 15 | NavigationView | Standard navigation |
    /// | macOS | macOS 13+ | NavigationSplitView | Side-by-side sidebar + detail |
    /// | macOS | macOS 12 | HStack | Simple horizontal layout |
    ///
    /// **Note**: The unified API automatically uses the appropriate container for each platform.
    /// Developers don't need to handle platform differences - the framework adapts automatically.
    ///
    /// ## Usage Examples
    ///
    /// ### Basic Usage (Automatic Device Detection)
    ///
    /// ```swift
    /// struct SettingsView: View {
    ///     @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    ///     @State private var selectedCategory: String? = nil
    ///
    ///     var body: some View {
    ///         EmptyView()
    ///             .platformSettingsContainer_L4(
    ///                 columnVisibility: $columnVisibility,
    ///                 selectedCategory: $selectedCategory
    ///             ) {
    ///                 // Sidebar: List of settings categories
    ///                 SettingsCategoryList(selectedCategory: $selectedCategory)
    ///             } detail: {
    ///                 // Detail: Settings for selected category
    ///                 SettingsDetailView(category: selectedCategory)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// ### iPhone-Specific Usage (Category Selection)
    ///
    /// ```swift
    /// struct SettingsView: View {
    ///     @State private var selectedCategory: String? = nil
    ///
    ///     var body: some View {
    ///         EmptyView()
    ///             .platformSettingsContainer_L4(
    ///                 selectedCategory: $selectedCategory
    ///             ) {
    ///                 // Sidebar shown when selectedCategory is nil
    ///                 List {
    ///                     Button("General") { selectedCategory = "general" }
    ///                     Button("Privacy") { selectedCategory = "privacy" }
    ///                     Button("Notifications") { selectedCategory = "notifications" }
    ///                 }
    ///             } detail: {
    ///                 // Detail shown when selectedCategory is set
    ///                 if let category = selectedCategory {
    ///                     SettingsDetailView(category: category)
    ///                 }
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// ### iPad/macOS Usage (Column Visibility Control)
    ///
    /// ```swift
    /// struct SettingsView: View {
    ///     @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    ///
    ///     var body: some View {
    ///         EmptyView()
    ///             .platformSettingsContainer_L4(
    ///                 columnVisibility: $columnVisibility
    ///             ) {
    ///                 // Sidebar always visible on iPad/macOS
    ///                 SettingsCategoryList()
    ///             } detail: {
    ///                 // Detail pane
    ///                 SettingsDetailView()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// ### Minimal Usage (No Bindings)
    ///
    /// ```swift
    /// struct SettingsView: View {
    ///     var body: some View {
    ///         EmptyView()
    ///             .platformSettingsContainer_L4 {
    ///                 // Sidebar
    ///                 SettingsCategoryList()
    ///             } detail: {
    ///                 // Detail
    ///                 SettingsDetailView()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// ## Integration with Other Framework Components
    ///
    /// This function works seamlessly with:
    /// - `DeviceType.current` - Device detection
    /// - `PlatformDeviceCapabilities` - Capability assessment
    /// - `platformAppNavigation_L4` - Similar navigation pattern
    /// - `platformNavigationAction` - Navigation state management
    ///
    /// - Parameters:
    ///   - columnVisibility: Optional binding for NavigationSplitView column visibility (iPad/macOS)
    ///   - selectedCategory: Optional binding to track category selection (iPhone - controls detail display)
    ///   - sidebar: View builder for sidebar content
    ///   - detail: View builder for detail content
    /// - Returns: A view with platform-appropriate settings container pattern
    /// Layer 4: Component Implementation
    /// Implements Issue #58: Add platformSettingsContainer_L4 for Settings Views (Layer 4)
    func resolveSettingsContainerLayout_L4(
        availableWidth: CGFloat
    ) -> NavigationLayoutResolution {
        NavigationLayoutResolver.resolveSettingsContainer(availableWidth: availableWidth)
    }

    @MainActor
    @ViewBuilder
    func platformSettingsContainer_L4<Sidebar: View, Detail: View>(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        selectedCategory: Binding<AnyHashable?>? = nil,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        let deviceType = DeviceType.current
        
        #if os(iOS)
        switch PlatformManagedSettingsFlowLogic.topLevelSettingsShellPolicy(deviceType: deviceType) {
        case .splitSidebarDetail:
            // iPad: Use NavigationSplitView
            let sidebarView = sidebar()
            let detailView = detail()
            Layer4NestedSplitShellPresentationHost(
                kind: .settingsIPad,
                columnVisibility: columnVisibility,
                sidebar: { sidebarView },
                detail: { detailView }
            )
            
        case .stackWithSelectionPush:
            // iPhone/CarPlay: Use NavigationStack with selection-driven push semantics
            createSettingsContainerForiPhone(
                selectedCategory: selectedCategory,
                sidebar: sidebar,
                detail: detail
            )
            
        case .unsupportedSidebarFallback:
            // Unsupported top-level shell on current platform: show caller-provided sidebar only.
            sidebar()
        }
        #elseif os(macOS)
        // macOS: Always use NavigationSplitView
        let sidebarView = sidebar()
        let detailView = detail()
        Layer4NestedSplitShellPresentationHost(
            kind: .settingsMacOS,
            columnVisibility: columnVisibility,
            sidebar: { sidebarView },
            detail: { detailView }
        )
        #else
        // Other platforms: Default to sidebar
        sidebar()
        #endif
    }
}


