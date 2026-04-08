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

@Suite("Managed platform settings flow guide example (#209)")
struct ManagedPlatformSettingsFlowGuideExampleTests {

    @Test @MainActor
    func managedSettingsGuideExample_builds() {
        _ = ManagedSettingsGuideExampleView()
    }
}
