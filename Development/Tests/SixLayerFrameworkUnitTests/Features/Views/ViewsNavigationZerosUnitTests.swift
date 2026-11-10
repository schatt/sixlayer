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
        // ToolbarItemPlacement is not Equatable on watchOS/tvOS; `.automatic` also
        // binds to WindowLevel there, so name the type and compare its description.
        #expect(
            String(describing: placement)
                == "ToolbarItemPlacement(role: SwiftUI.ToolbarItemPlacement.Role.automatic)"
        )
        #endif
    }

    @Test func platformTabItem_idMatchesTitle() {
        let item = PlatformTabItem(title: "Home", systemImage: "house")
        #expect(item.id == "Home")
        #expect(item.title == "Home")
        #expect(item.systemImage == "house")
    }

    @Test func appNavigationTopLevelState_phoneStartsWithNoSelection() {
        enum Pane: String, Hashable, Sendable, CaseIterable {
            case home
            case settings
        }
        let state = PlatformAppNavigationTopLevelState<Pane>(deviceType: .phone)
        #expect(state.selectedPane == nil)
    }
}

@Suite("Views + Navigation zeros hosts (#469)", HostedViewTestIsolationTrait())
struct ViewsNavigationZerosHostUnitTests {

    @Test @MainActor
    func crossPlatformOptimizationUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("CrossPlatformOptimization") {
            CrossPlatformOptimization()
        }
    }

    @Test @MainActor
    func runtimeCapabilityDetectionUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("RuntimeCapabilityDetectionView") {
            RuntimeCapabilityDetectionView()
        }
    }

    @Test @MainActor
    func platformPrivacyUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("PlatformPrivacy") {
            PlatformPrivacy()
        }
    }

    @Test @MainActor
    func platformSafetyUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("PlatformSafety") {
            PlatformSafety()
        }
    }

    @Test @MainActor
    func platformSecurityUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("PlatformSecurity") {
            PlatformSecurity()
        }
    }

    @Test @MainActor
    func visionSafetyUsesNamedCompliance() {
        TestSetupUtilities.hostExpectingNamedCompliance("VisionSafety") {
            VisionSafety()
        }
    }

    @Test @MainActor
    func responsiveContainerHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            ResponsiveContainer { horizontal, vertical in
                Text("h=\(horizontal ? "yes" : "no") v=\(vertical ? "yes" : "no")")
            }
        }
    }

    @Test @MainActor
    func barcodeOverlayViewHostsEmptyResult() {
        let result = BarcodeResult(barcodes: [], confidence: 0, processingTime: 0)
        TestSetupUtilities.hostExpectingNamedCompliance("BarcodeOverlayView") {
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
        TestSetupUtilities.hostExpectingNamedCompliance("OCRDisambiguationView") {
            OCRDisambiguationView(result: result, onSelection: { _ in })
        }
    }

    @Test @MainActor
    func platformTabStripHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
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
        TestSetupUtilities.hostExpectingPlatformRoot {
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

    @Test @MainActor
    func entityAutoSaveWrapperHosts() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            IntelligentFormView.withEntityAutoSave(
                content: Text("Form"),
                entity: "draft-entity",
                autoSaveInterval: 3600,
                isDraft: true,
                onEntitySaved: { _ in }
            )
        }
    }

    @Test @MainActor
    func managedAppNavigationHosts() {
        enum Pane: String, Hashable, Sendable, CaseIterable {
            case home
            case settings
        }
        let descriptors: [AppNavigationPaneDescriptor<Pane>] = [
            .init(id: .home, titleKey: "Home", systemImage: "house"),
            .init(id: .settings, titleKey: "Settings", systemImage: "gear")
        ]
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("Root")
                .platformManagedAppNavigation_L4(
                    state: .constant(PlatformAppNavigationTopLevelState(deviceType: .phone)),
                    descriptors: descriptors
                ) { pane in
                    Text(pane?.rawValue ?? "nil")
                }
        }
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

}
