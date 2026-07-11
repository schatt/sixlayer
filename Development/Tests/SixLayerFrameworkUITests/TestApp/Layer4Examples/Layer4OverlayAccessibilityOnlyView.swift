//
//  Layer4OverlayAccessibilityOnlyView.swift
//  SixLayerFrameworkUITests
//
//  Deep-link host for Layer 4 overlay accessibility XCUITests (#316).
//  Launch: `-OpenLayer4OverlayAccessibility`
//  No scroll discovery — overlay expand/close affordances are on-screen at launch.
//

import SwiftUI
import SixLayerFramework

/// Minimal host exposing only the L4 overlay accessibility contract (`platformAppNavigation_L4` split).
/// Fixed narrow width so Layer 4 resolves `.overlayOuterSidebar` and exposes `L4OverlayShowSidebar`
/// at launch (wide windows would pick `.fullSplit` and hide the expand affordance). Refs #316 / #206.
struct Layer4OverlayAccessibilityOnlyView: View {
    @State private var showingNavigationSheet = false
    private let strategy = AppNavigationStrategy(
        implementation: .splitView,
        reasoning: "L4 overlay accessibility contract"
    )

    /// Below sidebar+detail budget (`textSidebar` min + 480 detail) so app-nav shell collapses outer → overlay.
    private static let overlayContractWidth: CGFloat = 300
    private static let overlayContractHeight: CGFloat = 500

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            EmptyView()
                .platformAppNavigation_L4(
                    // Nil binding: a two-way NavigationSplitViewVisibility binding can pin detail-only
                    // and hide L4OverlayShowSidebar (#207).
                    columnVisibility: nil,
                    showingNavigationSheet: $showingNavigationSheet,
                    strategy: strategy,
                    sidebar: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("L4OverlaySidebarContent")
                                .accessibilityIdentifier("L4OverlaySidebarContent")
                            Text("Overlay menu")
                        }
                        .padding()
                    },
                    detail: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("L4OverlayDetailContent")
                                .accessibilityIdentifier("L4OverlayDetailContent")
                            Button("L4OverlayDetailAction") { }
                                .accessibilityIdentifier("L4OverlayDetailAction")
                        }
                        .padding()
                        #if os(iOS)
                        .navigationTitle("L4OverlayContract")
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                    }
                )
                .frame(
                    width: Self.overlayContractWidth,
                    height: Self.overlayContractHeight,
                    alignment: .topLeading
                )
            Spacer(minLength: 0)
        }
        .platformFrame()
        .navigationTitle("L4 Overlay Accessibility")
        #if os(iOS) || os(macOS)
        .platformNavigationTitleDisplayMode_L4(.inline)
        #endif
    }
}
