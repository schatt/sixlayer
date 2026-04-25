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
}

#endif
