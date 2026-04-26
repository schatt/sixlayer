//
//  Layer4SemanticAccessibilityCriterionTests.swift
//  SixLayerFrameworkUnitTests
//
//  Semantic accessibility criteria for View-returning Layer 4 `platform*_L4` APIs (Issue #254):
//  traits and accessibilityValue on hosted UIKit trees, complementing identifier-only tests.
//

import CloudKit
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import SixLayerFramework

#if canImport(UIKit) && !os(watchOS)

@Suite("Layer 4 semantic accessibility criteria (#254)")
open class Layer4SemanticAccessibilityCriterionTests: BaseTestClass {

    @MainActor
    private func hostedRoot<V: View>(for view: V) -> Any? {
        let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        config.resetToDefaults()
        config.namespace = "SixLayer"
        config.mode = .automatic
        config.enableAutoIDs = true
        config.globalAutomaticAccessibilityIdentifiers = true
        config.includeComponentNames = true
        config.includeElementTypes = true
        config.enableUITestIntegration = true
        config.enableDebugLogging = false
        return AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            Self.hostRootPlatformView(
                view.environment(\.accessibilityIdentifierConfig, config),
                forceLayout: true,
                exposeContentAccessibility: true,
                accessibilityIdentifierConfig: config
            )
        }
    }

    @Test @MainActor
    func testPlatformCloudKitSyncButton_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil, "hosted root should exist")
        let match = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        #expect(match, "sync button should expose UIAccessibilityTraits.button with SixLayer identifier")
    }

    @Test @MainActor
    func testPlatformCloudKitProgress_L4_exposesProgressSemanticsWithSixLayerIdentifier() async {
        let view = platformCloudKitProgress_L4(progress: 0.42)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let byValue = hostedUIKitAccessibilityValuePresent(
            root: root,
            identifierContains: "SixLayer.main.ui"
        )
        let byAdjustableOrUpdates = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
        }
        #expect(
            byValue || byAdjustableOrUpdates,
            "progress host should expose accessibilityValue or progress-like traits on a SixLayer-identified node"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitSyncStatus_L4_exposesInformativeTraitsWithContractIdentifier() async {
        let view = platformCloudKitSyncStatus_L4(status: .syncing)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let informative = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("platformCloudKitSyncStatus") else { return false }
            return v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        #expect(
            informative,
            "combined sync status should surface as static text, image, or updatesFrequently for assistive tech"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitAccountStatus_L4_exposesInformativeSemanticSurface() async {
        let view = platformCloudKitAccountStatus_L4(status: .available)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let informative = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            guard let label = v.accessibilityLabel, label.localizedCaseInsensitiveContains("icloud") else { return false }
            return v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        #expect(
            informative,
            "account status should expose iCloud-related label with informative traits and SixLayer identifier"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitServiceStatus_L4_hostedEmitsIdentifiersAndInformativeSurface() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitServiceStatus_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
        #expect(!ids.isEmpty, "service status host should emit at least one accessibility identifier")
        let informative = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        #expect(
            informative,
            "service status stack should include at least one informative SixLayer-identified a11y node"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitStatusBadge_L4_idle_exposesImageOrInformativeSemanticSurface() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .idle
        let view = platformCloudKitStatusBadge_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let match = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        #expect(match, "idle badge should expose image or informative traits with SixLayer identifier")
    }

    @Test @MainActor
    func testPlatformCloudKitStatusBadge_L4_syncing_exposesProgressOrImageSemanticSurface() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .syncing
        let view = platformCloudKitStatusBadge_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let match = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
                || v.accessibilityTraits.contains(.image)
        }
        #expect(
            match,
            "syncing badge should expose progress-like or image traits with SixLayer identifier"
        )
    }

    @Test @MainActor
    func testPlatformShare_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let view = Button("Share") { }
            .platformShare_L4(isPresented: .constant(false), items: ["hello"])
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let buttonLike = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        #expect(buttonLike, "platformShare_L4 host should expose a button-like semantic node")
    }

    @Test @MainActor
    func testPlatformPrint_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let view = Button("Print") { }
            .platformPrint_L4(isPresented: .constant(false), content: .text("test print"))
        let root = hostedRoot(for: view)
        #expect(root != nil)
        let buttonLike = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        #expect(buttonLike, "platformPrint_L4 host should expose a button-like semantic node")
    }
}

#endif
