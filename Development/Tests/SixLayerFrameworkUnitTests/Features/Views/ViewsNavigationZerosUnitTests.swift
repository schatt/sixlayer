//
//  ViewsNavigationZerosUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for Components/Views + Navigation zeros (#469).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Views + Navigation zeros (#469)")
struct ViewsNavigationZerosLogicUnitTests {

    @Test func platformBottomBarPlacement_isPlatformSpecific() {
        let placement = platformBottomBarPlacement()
        #if os(iOS)
        #expect(placement == .bottomBar)
        #else
        #expect(placement == .automatic)
        #endif
    }

    @Test func platformTabItem_idMatchesTitle() {
        let item = PlatformTabItem(title: "Home", systemImage: "house")
        #expect(item.id == "Home")
        #expect(item.title == "Home")
        #expect(item.systemImage == "house")
    }
}

@Suite("Views + Navigation zeros hosts (#469)", HostedViewTestIsolationTrait())
struct ViewsNavigationZerosHostUnitTests {

    @Test @MainActor
    func crossPlatformOptimizationUsesNamedCompliance() {
        hostExpectingNamedCompliance("CrossPlatformOptimization") {
            CrossPlatformOptimization()
        }
    }

    @Test @MainActor
    func runtimeCapabilityDetectionUsesNamedCompliance() {
        hostExpectingNamedCompliance("RuntimeCapabilityDetectionView") {
            RuntimeCapabilityDetectionView()
        }
    }

    @Test @MainActor
    func platformPrivacyUsesNamedCompliance() {
        hostExpectingNamedCompliance("PlatformPrivacy") {
            PlatformPrivacy()
        }
    }

    @Test @MainActor
    func platformSafetyUsesNamedCompliance() {
        hostExpectingNamedCompliance("PlatformSafety") {
            PlatformSafety()
        }
    }

    @Test @MainActor
    func platformSecurityUsesNamedCompliance() {
        hostExpectingNamedCompliance("PlatformSecurity") {
            PlatformSecurity()
        }
    }

    @Test @MainActor
    func visionSafetyUsesNamedCompliance() {
        hostExpectingNamedCompliance("VisionSafety") {
            VisionSafety()
        }
    }

    @Test @MainActor
    func responsiveContainerHosts() {
        hostView {
            ResponsiveContainer { horizontal, vertical in
                Text("h=\(horizontal ? "yes" : "no") v=\(vertical ? "yes" : "no")")
            }
        }
    }

    @Test @MainActor
    func barcodeOverlayViewHostsEmptyResult() {
        let result = BarcodeResult(barcodes: [], confidence: 0, processingTime: 0)
        hostExpectingNamedCompliance("BarcodeOverlayView") {
            BarcodeOverlayView(image: emptyPlatformImage(), result: result)
        }
    }

    @Test @MainActor
    func ocrDisambiguationViewHosts() {
        let result = OCRDisambiguationResult(
            candidates: [],
            confidence: 0,
            requiresUserSelection: false
        )
        hostExpectingNamedCompliance("OCRDisambiguationView") {
            OCRDisambiguationView(result: result, onSelection: { _ in })
        }
    }

    @Test @MainActor
    func platformTabStripHosts() {
        hostView {
            PlatformTabStrip(
                selection: .constant(0),
                items: [
                    PlatformTabItem(title: "A", systemImage: "a.circle"),
                    PlatformTabItem(title: "B", systemImage: "b.circle")
                ]
            )
        }
    }

    @Test @MainActor
    func platformNavigationSplitViewHosts() {
        hostView {
            platformNavigationSplitView {
                Text("Content")
            } detail: {
                Text("Detail")
            }
        }
    }

    @Test @MainActor
    func confirmationActionPlacementCallable() {
        let _ = Text("Root").platformConfirmationActionPlacement()
        let _ = Text("Root").platformCancellationActionPlacement()
        let _ = Text("Root").platformPrimaryActionPlacement()
        let _ = Text("Root").platformSecondaryActionPlacement()
    }

    @MainActor
    private func emptyPlatformImage() -> PlatformImage {
        #if os(iOS)
        PlatformImage(uiImage: UIImage())
        #elseif os(macOS)
        PlatformImage(nsImage: NSImage())
        #else
        PlatformImage()
        #endif
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
