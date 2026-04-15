//
//  ManagedPlatformSettingsFlowGuideExampleTests.swift
//  Issue #209 — compile-checked managed settings + sub-pane example (see Framework/docs/ManagedPlatformSettingsFlowGuide.md)
//

import SwiftUI
import Testing
@testable import SixLayerFramework

// MARK: - Top-level panes (compile-time set)

private enum ManagedGuideTopPane: String, CaseIterable, Hashable, Sendable {
    case general
    case data
}

// MARK: - Sub-pane routes (detail stack)

private enum ManagedGuideSubPane: Hashable, Sendable {
    case cleanup
    /// Second push under **Data** (three-level: top-level → cleanup → confirm).
    case cleanupConfirm
}

private enum ManagedGuideEscapeHatchPattern: String, Hashable, Sendable {
    case splitHStack
    case twoColumnDataFlow
    case embeddedStacks
}

/// Example adapter for wiring a Layer 1 settings sidebar to managed top-level state.
private enum ManagedGuideL1SidebarSelectionAdapter {
    static func selectFromSidebarSettingKey(
        _ key: String,
        topLevel: inout PlatformManagedSettingsTopLevelState<ManagedGuideTopPane>,
        detailNavigation: inout PlatformManagedSettingsDetailNavigationState<ManagedGuideSubPane>
    ) {
        _ = key
        _ = topLevel
        _ = detailNavigation
    }
}

/// Mirrors the migration guide: managed top-level + detail `NavigationStack` for sub-panes.
private struct ManagedSettingsGuideExampleView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var topLevel = PlatformManagedSettingsTopLevelState<ManagedGuideTopPane>(
        deviceType: DeviceType.current
    )
    @State private var detailNav = PlatformManagedSettingsDetailNavigationState<ManagedGuideSubPane>()

    var body: some View {
        EmptyView()
            .platformManagedSettingsTopLevel_L4(
                columnVisibility: $columnVisibility,
                state: $topLevel,
                sidebar: { sidebar },
                detail: { detailColumn }
            )
    }

    @ViewBuilder private var sidebar: some View {
        List(ManagedGuideTopPane.allCases, id: \.self) { pane in
            Button(pane.rawValue.capitalized) {
                PlatformManagedSettingsFlowLogic.selectTopLevelPane(
                    pane,
                    topLevel: &topLevel,
                    detailNavigation: &detailNav
                )
            }
        }
        .navigationTitle("Settings")
    }

    @ViewBuilder private var detailColumn: some View {
        if topLevel.selectedTopLevel != nil {
            switch topLevel.selectedTopLevel! {
            case .general:
                EmptyView()
                    .platformManagedSettingsDetailNavigationStack_L4(state: $detailNav) {
                        List {
                            Text("General options")
                        }
                        .navigationTitle("General")
                    }
            case .data:
                EmptyView()
                    .platformManagedSettingsDetailNavigationStack_L4(state: $detailNav) {
                        List {
                            NavigationLink(value: ManagedGuideSubPane.cleanup) {
                                Text("Data cleanup")
                            }
                        }
                        .navigationTitle("Data")
                        .navigationDestination(for: ManagedGuideSubPane.self) { route in
                            switch route {
                            case .cleanup:
                                List {
                                    NavigationLink(value: ManagedGuideSubPane.cleanupConfirm) {
                                        Text("Confirm cleanup")
                                    }
                                }
                                .navigationTitle("Cleanup")
                            case .cleanupConfirm:
                                Text("Cleanup confirmation")
                                    .navigationTitle("Confirm")
                            }
                        }
                    }
            }
        } else {
            Text("Select a category")
                .foregroundStyle(.secondary)
        }
    }
}

/// Compile-checked manual-shell pattern for non-uniform detail layouts.
/// This mirrors the "escape hatch" guidance in docs: keep outer shell and customize detail freely.
private struct ManagedSettingsEscapeHatchGuideExampleView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var selectedCategory: AnyHashable? = "Data"

    /// Intentionally incomplete for red phase: this should include all documented patterns.
    static let documentedPatterns: Set<ManagedGuideEscapeHatchPattern> = [
        .splitHStack,
        .twoColumnDataFlow,
        .embeddedStacks
    ]

    var body: some View {
        EmptyView()
            .platformSettingsContainer_L4(
                columnVisibility: $columnVisibility,
                selectedCategory: $selectedCategory
            ) {
                List {
                    Button("General") { selectedCategory = "General" }
                    Button("Data") { selectedCategory = "Data" }
                }
                .navigationTitle("Settings")
            } detail: {
                Group {
                    switch selectedCategory as? String {
                    case "Data":
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cleanup queue")
                                Text("Integrity scan")
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Preview pane")
                                List {
                                    NavigationLink("Open details", destination: Text("Nested details"))
                                }
                            }
                        }
                    case "General":
                        VStack(alignment: .leading, spacing: 8) {
                            Text("General settings")
                            Text("Standard controls")
                        }
                    default:
                        Text("Select a category")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
    }
}

@Suite("Managed platform settings flow guide example (#209)")
struct ManagedPlatformSettingsFlowGuideExampleTests {

    @Test @MainActor
    func managedSettingsGuideExample_builds() {
        _ = ManagedSettingsGuideExampleView()
    }

    @Test @MainActor
    func escapeHatchGuideExample_buildsAndDocumentsPatterns() {
        _ = ManagedSettingsEscapeHatchGuideExampleView()
        #expect(ManagedSettingsEscapeHatchGuideExampleView.documentedPatterns.count == 3)
        #expect(ManagedSettingsEscapeHatchGuideExampleView.documentedPatterns.contains(.splitHStack))
        #expect(ManagedSettingsEscapeHatchGuideExampleView.documentedPatterns.contains(.twoColumnDataFlow))
        #expect(ManagedSettingsEscapeHatchGuideExampleView.documentedPatterns.contains(.embeddedStacks))
    }

    @Test @MainActor
    func l1SidebarSelection_wiresToManagedTopLevelState_andResetsDetailPath() {
        var topLevel = PlatformManagedSettingsTopLevelState<ManagedGuideTopPane>(
            orderedTopLevelPaneIDs: ManagedGuideTopPane.allCases,
            deviceType: .phone
        )
        var detailNav = PlatformManagedSettingsDetailNavigationState<ManagedGuideSubPane>()
        detailNav.push(.cleanup)

        ManagedGuideL1SidebarSelectionAdapter.selectFromSidebarSettingKey(
            "pane.data",
            topLevel: &topLevel,
            detailNavigation: &detailNav
        )

        #expect(topLevel.selectedTopLevel == .data)
        #expect(detailNav.path.isEmpty)
    }
}
