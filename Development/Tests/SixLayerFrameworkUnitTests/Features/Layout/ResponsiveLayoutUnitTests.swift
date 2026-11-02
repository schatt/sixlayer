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
        let columns = ResponsiveLayout.gridColumns(for: 900, minWidth: 300)
        #expect(columns.count == 3)
    }

    @Test func gridColumns_narrowWidthYieldsAtLeastOne() {
        let columns = ResponsiveLayout.gridColumns(for: 100, minWidth: 300)
        #expect(columns.count == 1)
    }

    @Test func gridItemData_idDerivesFromTitle() {
        let item = GridItemData(
            title: "A",
            subtitle: "B",
            icon: "star",
            color: .blue
        )
        #expect(item.id == "A")
        #expect(item.title == "A")
        #expect(item.subtitle == "B")
        #expect(item.icon == "star")
    }
}

@Suite("ResponsiveLayout hosts (#469)", HostedViewTestIsolationTrait())
struct ResponsiveLayoutHostUnitTests {

    @Test @MainActor
    func adaptiveGridHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            ResponsiveLayout.adaptiveGrid {
                Text("Cell")
            }
        }
    }

    @Test @MainActor
    func verticalGridHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            ResponsiveLayout.verticalGrid {
                Text("Cell")
            }
        }
    }
}
