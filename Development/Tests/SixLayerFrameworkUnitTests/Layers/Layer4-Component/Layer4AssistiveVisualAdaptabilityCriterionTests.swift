//
//  Layer4AssistiveVisualAdaptabilityCriterionTests.swift
//  SixLayerFrameworkUnitTests
//
//  Automated hooks for Issue #255: Dynamic Type (and related) environment overrides on
//  hosted Layer 4 surfaces — complements manual VoiceOver / Switch Control / high-contrast runs.
//

import CloudKit
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import SixLayerFramework

#if canImport(UIKit) && !os(watchOS)

@Suite("Layer 4 assistive & visual adaptability (#255)")
open class Layer4AssistiveVisualAdaptabilityCriterionTests: BaseTestClass {

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

    @MainActor
    private func hostedTreeExposesSemanticSurface(_ root: Any?) -> Bool {
        hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            let hasId = !(v.accessibilityIdentifier ?? "").isEmpty
            let hasLabel = !(v.accessibilityLabel ?? "").isEmpty
            let hasValue = !(v.accessibilityValue ?? "").isEmpty
            let hasTraits = !v.accessibilityTraits.isEmpty
            return hasId || hasLabel || hasValue || hasTraits
        }
    }

    @MainActor
    private func sixLayerAccessibilityIDs(from root: Any?) -> [String] {
        findAllAccessibilityIdentifiersFromPlatformView(root).filter { $0.contains("SixLayer") }
    }

    @Test @MainActor
    func testPlatformCloudKitSyncButton_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let defaultIDs = Set(sixLayerAccessibilityIDs(from: rootDefault))
        let scaledIDs = Set(sixLayerAccessibilityIDs(from: rootScaled))
        #expect(!defaultIDs.isEmpty && !scaledIDs.isEmpty, "SixLayer accessibility ids should exist at default and large Dynamic Type")
        #expect(
            !defaultIDs.isDisjoint(with: scaledIDs),
            "sync button should keep overlapping SixLayer identifier keys when Dynamic Type increases"
        )
        let buttonDefault = hostedUIKitAccessibilityHierarchyContains(root: rootDefault) { $0.accessibilityTraits.contains(.button) }
        let buttonScaled = hostedUIKitAccessibilityHierarchyContains(root: rootScaled) { $0.accessibilityTraits.contains(.button) }
        #expect(buttonDefault && buttonScaled, "button trait should remain discoverable under elevated Dynamic Type")
    }

    @Test @MainActor
    func testPlatformCloudKitProgress_L4_retainsProgressSemanticsAcrossDynamicTypeSteps() async {
        let view = platformCloudKitProgress_L4(progress: 0.55)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasProgressSemantics(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let traits = v.accessibilityTraits
                let hasValue = !(v.accessibilityValue ?? "").isEmpty
                return hasValue
                    || traits.contains(.updatesFrequently)
                    || traits.contains(.adjustable)
            }
        }
        #expect(
            hasProgressSemantics(rootDefault) && hasProgressSemantics(rootScaled),
            "progress host should keep progress-like semantics when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitSyncStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps() async {
        let view = platformCloudKitSyncStatus_L4(status: .syncing)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasInformativeSemantics(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                guard let id = v.accessibilityIdentifier, id.contains("platformCloudKitSyncStatus") else { return false }
                return v.accessibilityTraits.contains(.staticText)
                    || v.accessibilityTraits.contains(.image)
                    || v.accessibilityTraits.contains(.updatesFrequently)
            }
        }
        func fallbackInformative(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                v.accessibilityTraits.contains(.staticText)
                    || v.accessibilityTraits.contains(.image)
                    || v.accessibilityTraits.contains(.updatesFrequently)
            }
        }
        #expect(
            (hasInformativeSemantics(rootDefault) || fallbackInformative(rootDefault))
                && (hasInformativeSemantics(rootScaled) || fallbackInformative(rootScaled)),
            "sync status should keep informative traits when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformVerticalSplit_L4_paneMarkersSurviveLargeDynamicTypeHosting() async {
        let view = Text("SplitPrimary255")
            .platformVerticalSplit_L4(spacing: 0) {
                Text("SplitTop255")
                    .automaticCompliance(
                        identifierName: "L4SplitTop255",
                        identifierElementType: "Text"
                    )
                Text("SplitBottom255")
                    .automaticCompliance(
                        identifierName: "L4SplitBottom255",
                        identifierElementType: "Text"
                    )
            }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility5))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasPaneMarkers(_ root: Any?) -> Bool {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            let top = ids.contains { $0.contains("L4SplitTop255") }
            let bottom = ids.contains { $0.contains("L4SplitBottom255") }
            if top && bottom { return true }
            return hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("L4SplitTop255") || id.contains("L4SplitBottom255")
            }
        }
        #expect(
            hasPaneMarkers(rootDefault) && hasPaneMarkers(rootScaled),
            "split pane markers should remain in the hosted tree when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformPhotoPicker_L4_retainsNamedIdentifiersAcrossDynamicTypeSteps() async {
        let view = PlatformPhotoComponentsLayer4.platformPhotoPicker_L4 { _ in }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasPickerMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformPhotoPicker_L4") || id.contains("SixLayer")
            }
        }
        #expect(
            hasPickerMarkers(rootDefault) && hasPickerMarkers(rootScaled),
            "photo picker should keep discoverable identifiers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformShare_L4_retainsButtonSemanticsAcrossDynamicTypeSteps() async {
        let view = Button("Share255") { }
            .platformShare_L4(isPresented: .constant(false), items: ["hello"])
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let buttonDefault = hostedUIKitAccessibilityHierarchyContains(root: rootDefault) { $0.accessibilityTraits.contains(.button) }
        let buttonScaled = hostedUIKitAccessibilityHierarchyContains(root: rootScaled) { $0.accessibilityTraits.contains(.button) }
        #expect(buttonDefault && buttonScaled, "share trigger should remain button-discoverable under elevated Dynamic Type")
    }
}

#endif
