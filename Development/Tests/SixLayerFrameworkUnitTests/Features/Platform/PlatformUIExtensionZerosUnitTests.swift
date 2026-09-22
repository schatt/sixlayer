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

    @Test @MainActor
    func adaptiveButtonUsesNamedCompliance() {
        hostExpectingNamedCompliance("AdaptiveButton") {
            AdaptiveUIPatterns.AdaptiveButton("Save") {}
        }
    }

    @Test @MainActor
    func scanBarcodeL1Hosts() {
        #if os(iOS)
        let image = PlatformImage(uiImage: UIImage())
        #elseif os(macOS)
        let image = PlatformImage(nsImage: NSImage())
        #else
        let image = PlatformImage()
        #endif
        hostView {
            platformScanBarcode_L1(
                image: image,
                context: BarcodeContext(),
                onResult: { _ in }
            )
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
