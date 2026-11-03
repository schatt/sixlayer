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
        TestSetupUtilities.hostExpectingNamedCompliance("platformNavigationSheetButton") {
            Text("Root").platformNavigationSheetButton(action: {})
        }
    }

    @Test @MainActor
    func listStyleHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Row").platformListStyle()
        }
    }

    @Test @MainActor
    func sidebarListStyleHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Row").platformSidebarListStyle()
        }
    }

    @Test @MainActor
    func advancedContainersHost() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Grid").platformLazyVGridContainer()
        }
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Scroll").platformScrollContainer()
        }
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("List").platformListContainer()
        }
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Form").platformFormContainer()
        }
    }

    @Test @MainActor
    func contextMenuHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Item").platformContextMenu {
                Button("Edit") {}
            }
        }
    }

    @Test @MainActor
    func menuHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Menu").platformMenu {
                Button("One") {}
            }
        }
    }

    @Test @MainActor
    func dragDropHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Drop").platformOnDropText { _ in true }
        }
    }

    @Test @MainActor
    func adaptiveButtonUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("AdaptiveButton") {
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
        TestSetupUtilities.hostExpectingPlatformRoot {
            platformScanBarcode_L1(
                image: image,
                context: BarcodeContext(),
                onResult: { _ in }
            )
        }
    }

}
