//
//  PlatformUIExtensionZerosUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for Platform UI extension zeros (#468).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform UI extension zeros (#468)", HostedViewTestIsolationTrait())
struct PlatformUIExtensionZerosUnitTests {

    // MARK: - AdaptiveFrameSizing

    @Test func adaptiveFrame_simpleFormUsesBasePlusFieldAndSectionContributions() {
        let metrics = FormContentMetrics(
            fieldCount: 3,
            estimatedComplexity: .simple,
            preferredLayout: .compact,
            sectionCount: 2,
            hasComplexContent: false
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 575)
        #expect(size.minHeight == 600)
    }

    @Test func adaptiveFrame_complexContentAddsHeightBonusAndCaps() {
        let metrics = FormContentMetrics(
            fieldCount: 12,
            estimatedComplexity: .complex,
            preferredLayout: .spacious,
            sectionCount: 6,
            hasComplexContent: true
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 800)
        #expect(size.minHeight == 1000)
    }

    @Test func adaptiveFrame_veryWideFieldCountCapsWidthAt900() {
        let metrics = FormContentMetrics(
            fieldCount: 20,
            estimatedComplexity: .veryComplex,
            preferredLayout: .custom,
            sectionCount: 8,
            hasComplexContent: true
        )
        let size = AdaptiveFrameSizing.dimensions(for: metrics)
        #expect(size.minWidth == 900)
        #expect(size.minHeight == 1000)
    }

    // MARK: - Named compliance / host smoke

    @Test @MainActor
    func navigationSheetButtonUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformNavigationSheetButton") {
            Text("Root").platformNavigationSheetButton(action: {})
        }
    }

    @Test @MainActor
    func listStyleHosts() {
        hostView {
            Text("Row").platformListStyle()
        }
    }

    @Test @MainActor
    func sidebarListStyleHosts() {
        hostView {
            Text("Row").platformSidebarListStyle()
        }
    }

    @Test @MainActor
    func advancedContainersHost() {
        hostView {
            Text("Grid").platformLazyVGridContainer()
        }
        hostView {
            Text("Scroll").platformScrollContainer()
        }
        hostView {
            Text("List").platformListContainer()
        }
        hostView {
            Text("Form").platformFormContainer()
        }
    }

    @Test @MainActor
    func contextMenuHosts() {
        hostView {
            Text("Item").platformContextMenu {
                Button("Edit") {}
            }
        }
    }

    @Test @MainActor
    func menuHosts() {
        hostView {
            Text("Menu").platformMenu {
                Button("One") {}
            }
        }
    }

    @Test @MainActor
    func dragDropHosts() {
        hostView {
            Text("Drop").platformOnDropText { _ in true }
        }
    }

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view())
        #expect(hosted != nil)
        #expect(
            log.contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
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
