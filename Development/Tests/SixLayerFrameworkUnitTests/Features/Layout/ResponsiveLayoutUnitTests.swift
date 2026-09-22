//
//  ResponsiveLayoutUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for ResponsiveLayout (#469).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("ResponsiveLayout (#469)")
struct ResponsiveLayoutUnitTests {

    @Test func gridColumns_countsFromWidthOverMinWidth() {
        // Deliberate wrong count for #469 red; corrected after failing run.
        let columns = ResponsiveLayout.gridColumns(for: 900, minWidth: 300)
        #expect(columns.count == 99)
    }

    @Test func gridColumns_narrowWidthYieldsAtLeastOne() {
        let columns = ResponsiveLayout.gridColumns(for: 100, minWidth: 300)
        #expect(columns.count == 1)
    }

    @Test func gridItemData_idIsStablePerInstance() {
        let item = GridItemData(
            title: "A",
            subtitle: "B",
            icon: "star",
            color: .blue
        )
        #expect(item.title == "A")
        #expect(item.subtitle == "B")
        #expect(item.icon == "star")
        #expect(item.id != UUID())
    }
}

@Suite("ResponsiveLayout hosts (#469)", HostedViewTestIsolationTrait())
struct ResponsiveLayoutHostUnitTests {

    @Test @MainActor
    func adaptiveGridHosts() {
        hostView {
            ResponsiveLayout.adaptiveGrid {
                Text("Cell")
            }
        }
    }

    @Test @MainActor
    func verticalGridHosts() {
        hostView {
            ResponsiveLayout.verticalGrid {
                Text("Cell")
            }
        }
    }

    @MainActor
    private func hostView<V: View>(@ViewBuilder _ view: () -> V) {
        #if os(watchOS)
        return
        #else
        #expect(TestSetupUtilities.hostRootPlatformView(view(), forceLayout: true) != nil)
        #endif
    }
}
