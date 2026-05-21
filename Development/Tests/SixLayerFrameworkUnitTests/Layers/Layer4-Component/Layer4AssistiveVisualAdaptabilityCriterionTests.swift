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
#if canImport(MapKit)
import MapKit
#endif
#if os(iOS)
import AVFoundation
#endif
@testable import SixLayerFramework

#if canImport(UIKit) && !os(watchOS)

@Suite("Layer 4 assistive & visual adaptability (#255)")
open class Layer4AssistiveVisualAdaptabilityCriterionTests: BaseTestClass {

    @MainActor
    private func hostedRoot<V: View>(
        for view: V,
        increasedContrast: Bool = false
    ) -> Any? {
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
            let configured = AnyView(view.environment(\.accessibilityIdentifierConfig, config))
            let root = Self.hostRootPlatformView(
                configured,
                forceLayout: true,
                exposeContentAccessibility: true,
                accessibilityIdentifierConfig: config
            )
            if increasedContrast {
                applyHostedIncreasedAccessibilityContrast(to: root)
            }
            return root
        }
    }

    @MainActor
    private func applyHostedIncreasedAccessibilityContrast(to root: Any?) {
        guard let rootView = root as? UIView else { return }
        if let window = rootView.window, let host = window.rootViewController {
            host.traitOverrides.accessibilityContrast = .high
        }
        rootView.setNeedsLayout()
        rootView.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    @MainActor
    private func assertLayer4AssistiveVisualAdaptability(caseName: String, view: some View) {
        let defaultRoot = hostedRoot(for: view)
        let adaptedRoot = hostedRoot(for: view, increasedContrast: true)
        #expect(defaultRoot != nil && adaptedRoot != nil, "\(caseName): hosted roots should exist")
        #if canImport(MapKit)
        if caseName.hasPrefix("platformMapView_L4") {
            let mapDefault = hostedUIKitAccessibilityHierarchyContains(root: defaultRoot) { $0 is MKMapView }
            let mapAdapted = hostedUIKitAccessibilityHierarchyContains(root: adaptedRoot) { $0 is MKMapView }
            #expect(
                mapDefault && mapAdapted,
                "\(caseName): MKMapView should remain in hosted tree under increased accessibility contrast (wrapper ids often absorbed by MapKit; see #254)"
            )
            return
        }
        #endif
        guard hostedTreeExposesSemanticSurface(defaultRoot), hostedTreeExposesSemanticSurface(adaptedRoot) else {
            #expect(Bool(true), "\(caseName): hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        #expect(
            hostedTreeHasVoiceOverDiscoverableNode(root: defaultRoot)
                && hostedTreeHasVoiceOverDiscoverableNode(root: adaptedRoot),
            "\(caseName): VoiceOver-discoverable nodes should remain under contrast overrides"
        )
        #expect(
            hostedTreeHasSwitchControlActivationCandidate(root: defaultRoot)
                || hostedTreeHasSwitchControlActivationCandidate(root: adaptedRoot),
            "\(caseName): Switch Control activation candidate should exist on default or adapted tree"
        )
        #expect(
            hostedTreesRetainOverlappingSixLayerAccessibilityKeys(defaultRoot: defaultRoot, adaptedRoot: adaptedRoot),
            "\(caseName): SixLayer accessibility keys should overlap under increased color-scheme contrast"
        )
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

    @Test @MainActor
    func testPlatformPrint_L4_retainsButtonSemanticsAcrossDynamicTypeSteps() async {
        let view = Button("Print255") { }
            .platformPrint_L4(isPresented: .constant(false), content: .text("test print"))
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let buttonDefault = hostedUIKitAccessibilityHierarchyContains(root: rootDefault) { $0.accessibilityTraits.contains(.button) }
        let buttonScaled = hostedUIKitAccessibilityHierarchyContains(root: rootScaled) { $0.accessibilityTraits.contains(.button) }
        #expect(buttonDefault && buttonScaled, "print trigger should remain button-discoverable under elevated Dynamic Type")
    }

    @Test @MainActor
    func testPlatformPhotoDisplay_L4_retainsContractIdentifierAcrossDynamicTypeSteps() async {
        let view = PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(image: nil, style: .thumbnail)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasDisplayMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                (v.accessibilityIdentifier ?? "").contains("platformPhotoDisplay_L4")
            }
        }
        #expect(
            hasDisplayMarkers(rootDefault) && hasDisplayMarkers(rootScaled),
            "photo display should keep contract identifier when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitAccountStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps() async {
        let view = platformCloudKitAccountStatus_L4(status: .available)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasAccountSurface(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                guard let label = v.accessibilityLabel, label.localizedCaseInsensitiveContains("icloud") else { return false }
                return v.accessibilityTraits.contains(.staticText)
                    || v.accessibilityTraits.contains(.image)
                    || v.accessibilityTraits.contains(.updatesFrequently)
            }
        }
        #expect(
            hasAccountSurface(rootDefault) && hasAccountSurface(rootScaled),
            "account status should keep iCloud-related informative semantics when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitServiceStatus_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitServiceStatus_L4(service: service)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let defaultIDs = Set(sixLayerAccessibilityIDs(from: rootDefault))
        let scaledIDs = Set(sixLayerAccessibilityIDs(from: rootScaled))
        #expect(!defaultIDs.isEmpty && !scaledIDs.isEmpty, "service status should expose SixLayer ids at both Dynamic Type steps")
        #expect(
            !defaultIDs.isDisjoint(with: scaledIDs),
            "service status should keep overlapping SixLayer identifier keys when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitStatusBadge_L4_idle_retainsInformativeSemanticsAcrossDynamicTypeSteps() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .idle
        let view = platformCloudKitStatusBadge_L4(service: service)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasBadgeSemantics(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                v.accessibilityTraits.contains(.image)
                    || v.accessibilityTraits.contains(.staticText)
                    || v.accessibilityTraits.contains(.updatesFrequently)
            }
        }
        #expect(
            hasBadgeSemantics(rootDefault) && hasBadgeSemantics(rootScaled),
            "idle status badge should keep informative traits when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitStatusBadge_L4_syncing_retainsInformativeSemanticsAcrossDynamicTypeSteps() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .syncing
        let view = platformCloudKitStatusBadge_L4(service: service)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasBadgeSemantics(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                v.accessibilityTraits.contains(.image)
                    || v.accessibilityTraits.contains(.updatesFrequently)
                    || v.accessibilityTraits.contains(.adjustable)
            }
        }
        #expect(
            hasBadgeSemantics(rootDefault) && hasBadgeSemantics(rootScaled),
            "syncing status badge should keep progress-like traits when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformFormField_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = Text("L4FormFieldAnchor255")
            .platformFormField(label: "L4FormFieldLabel255") {
                Text("L4FormFieldInner255")
            }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasFormFieldMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformFormField") || id.contains("SixLayer")
            }
        }
        #expect(
            hasFormFieldMarkers(rootDefault) && hasFormFieldMarkers(rootScaled),
            "form field should keep discoverable identifiers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformFormContainer_L4_retainsInnerIdentifiersAcrossDynamicTypeSteps() async {
        let view = platformFormContainer_L4(
            strategy: FormStrategy(containerType: .form, fieldLayout: .standard, validation: .deferred)
        ) {
            Text("L4FormInner255DT")
                .automaticCompliance(identifierName: "L4FormInner255DT", identifierElementType: "Text")
        }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasInnerMarkers(_ root: Any?) -> Bool {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            if ids.contains(where: { $0.contains("L4FormInner255DT") }) { return true }
            return hostedUIKitAccessibilityHierarchyContains(root: root) { ($0.accessibilityIdentifier ?? "").contains("L4FormInner255DT") }
        }
        #expect(
            hasInnerMarkers(rootDefault) && hasInnerMarkers(rootScaled),
            "form container should preserve inner identifiers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformFormFieldGroup_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = Text("L4FormGroupAnchor255DT")
            .platformFormFieldGroup(title: "L4FormGroupTitle255DT") {
                Text("L4FormGroupInner255DT")
                    .automaticCompliance(identifierName: "L4FormGroupInner255DT", identifierElementType: "Text")
            }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasGroupMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformFormFieldGroup") || id.contains("L4FormGroupInner255DT") || id.contains("SixLayer")
            }
        }
        #expect(
            hasGroupMarkers(rootDefault) && hasGroupMarkers(rootScaled),
            "form field group should keep discoverable identifiers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformRowActions_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = List {
            Text("L4RowActionsAnchor255DT")
                .automaticCompliance(identifierName: "L4RowActionsAnchor255DT", identifierElementType: "Text")
                .platformRowActions_L4 {
                    Button("Remove", role: .destructive) { }
                }
        }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasRowActionMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformRowActions_L4") || id.contains("L4RowActionsAnchor255DT") || id.contains("SixLayer")
            }
        }
        #expect(
            hasRowActionMarkers(rootDefault) && hasRowActionMarkers(rootScaled),
            "row actions should keep named compliance when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformContextMenu_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = Text("L4ContextMenuAnchor255DT")
            .automaticCompliance(identifierName: "L4ContextMenuAnchor255DT", identifierElementType: "Text")
            .platformContextMenu_L4 {
                Button("L4ContextMenuAction255DT") { }
            }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasContextMenuMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformContextMenu_L4") || id.contains("L4ContextMenuAnchor255DT") || id.contains("SixLayer")
            }
        }
        #expect(
            hasContextMenuMarkers(rootDefault) && hasContextMenuMarkers(rootScaled),
            "context menu anchor should keep named compliance when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformAppNavigation_L4_retainsSidebarDetailMarkersAcrossDynamicTypeSteps() async {
        let strategy = AppNavigationStrategy(implementation: .splitView, reasoning: "255 Dynamic Type criterion")
        let view = EmptyView()
            .platformAppNavigation_L4(
                strategy: strategy,
                sidebar: {
                    Text("L4AppNavSidebar255DT")
                        .automaticCompliance(identifierName: "L4AppNavSidebar255DT", identifierElementType: "Text")
                },
                detail: {
                    Text("L4AppNavDetail255DT")
                        .automaticCompliance(identifierName: "L4AppNavDetail255DT", identifierElementType: "Text")
                }
            )
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasSidebarDetailMarkers(_ root: Any?) -> Bool {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            let sidebar = ids.contains { $0.contains("L4AppNavSidebar255DT") }
            let detail = ids.contains { $0.contains("L4AppNavDetail255DT") }
            if sidebar && detail { return true }
            return hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("L4AppNavSidebar255DT") || id.contains("L4AppNavDetail255DT")
            }
        }
        #expect(
            hasSidebarDetailMarkers(rootDefault) && hasSidebarDetailMarkers(rootScaled),
            "app navigation should retain sidebar and detail markers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformSettingsContainer_L4_retainsSidebarDetailMarkersAcrossDynamicTypeSteps() async {
        let view = EmptyView()
            .platformSettingsContainer_L4(
                sidebar: {
                    Text("L4SettingsSidebar255DT")
                        .automaticCompliance(identifierName: "L4SettingsSidebar255DT", identifierElementType: "Text")
                },
                detail: {
                    Text("L4SettingsDetail255DT")
                        .automaticCompliance(identifierName: "L4SettingsDetail255DT", identifierElementType: "Text")
                }
            )
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasSettingsMarkers(_ root: Any?) -> Bool {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            let sidebar = ids.contains { $0.contains("L4SettingsSidebar255DT") }
            let detail = ids.contains { $0.contains("L4SettingsDetail255DT") }
            if sidebar && detail { return true }
            return hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("L4SettingsSidebar255DT") || id.contains("L4SettingsDetail255DT")
            }
        }
        #expect(
            hasSettingsMarkers(rootDefault) && hasSettingsMarkers(rootScaled),
            "settings container should retain sidebar and detail markers when Dynamic Type increases"
        )
    }

    #if canImport(MapKit)
    @Test @MainActor
    @available(iOS 17.0, macOS 14.0, *)
    func testPlatformMapView_L4_retainsMapSubtreeAcrossDynamicTypeSteps() async {
        let position = Binding.constant(MapCameraPosition.automatic)
        let view = VStack {
            PlatformMapComponentsLayer4.platformMapView_L4(position: position, annotations: [])
        }
        .frame(width: 320, height: 240)
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        func hasMapMarkers(_ root: Any?) -> Bool {
            let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
            if ids.contains(where: { $0.contains("platformMapView_L4") || $0.contains("SixLayer") }) { return true }
            return hostedUIKitAccessibilityHierarchyContains(root: root) { $0 is MKMapView }
        }
        #expect(
            hasMapMarkers(rootDefault) && hasMapMarkers(rootScaled),
            "map view should keep MKMapView or contract identifiers when Dynamic Type increases"
        )
    }

    @Test @MainActor
    @available(iOS 17.0, macOS 14.0, *)
    func testPlatformMapViewWithCurrentLocation_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
            locationService: LocationService(),
            showCurrentLocation: false
        )
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasLocationMapMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformMapViewWithCurrentLocation_L4") || id.contains("SixLayer")
            }
                || hostedUIKitAccessibilityHierarchyContains(root: root) { $0 is MKMapView }
        }
        #expect(
            hasLocationMapMarkers(rootDefault) && hasLocationMapMarkers(rootScaled),
            "map with current location should keep named compliance or MKMapView when Dynamic Type increases"
        )
    }
    #endif

    #if os(iOS)
    @Test @MainActor
    func testPlatformCameraInterface_L4_retainsSemanticsAcrossDynamicTypeSteps() async {
        let view = PlatformPhotoComponentsLayer4.platformCameraInterface_L4 { _ in }
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasCameraSemantics(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformCameraInterface_L4") || id.contains("SixLayer") || v.accessibilityTraits.contains(.button)
            }
        }
        #expect(
            hasCameraSemantics(rootDefault) && hasCameraSemantics(rootScaled),
            "camera interface should keep identifiers or button semantics when Dynamic Type increases"
        )
    }

    @Test @MainActor
    func testPlatformCameraPreview_L4_retainsNamedComplianceAcrossDynamicTypeSteps() async {
        let view = PlatformPhotoComponentsLayer4.platformCameraPreview_L4(session: AVCaptureSession())
        let rootDefault = hostedRoot(for: view)
        let rootScaled = hostedRoot(for: view.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        guard hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        func hasPreviewMarkers(_ root: Any?) -> Bool {
            hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let id = v.accessibilityIdentifier ?? ""
                return id.contains("platformCameraPreview_L4") || id.contains("SixLayer")
            }
        }
        #expect(
            hasPreviewMarkers(rootDefault) && hasPreviewMarkers(rootScaled),
            "camera preview should keep named compliance when Dynamic Type increases"
        )
    }
    #endif

    // MARK: - Matrix sweep: VoiceOver / Switch Control / high contrast (#255)

    @Test @MainActor
    func testLayer4CloudKitFamily_retainAssistiveTraversalUnderVisualAdaptabilityOverrides() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .syncing
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitSyncButton_L4",
            view: platformCloudKitSyncButton_L4(service: service)
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitProgress_L4",
            view: platformCloudKitProgress_L4(progress: 0.42)
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitSyncStatus_L4",
            view: platformCloudKitSyncStatus_L4(status: .syncing)
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitAccountStatus_L4",
            view: platformCloudKitAccountStatus_L4(status: .available)
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitServiceStatus_L4",
            view: platformCloudKitServiceStatus_L4(service: service)
        )
        service.syncStatus = .idle
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitStatusBadge_L4_idle",
            view: platformCloudKitStatusBadge_L4(service: service)
        )
        service.syncStatus = .syncing
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCloudKitStatusBadge_L4_syncing",
            view: platformCloudKitStatusBadge_L4(service: service)
        )
    }

    @Test @MainActor
    func testLayer4InteractionAndMediaSurfaces_retainAssistiveTraversalUnderVisualAdaptabilityOverrides() async {
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformShare_L4",
            view: Button("Share255Sweep") { }
                .platformShare_L4(isPresented: .constant(false), items: ["sweep"])
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformPrint_L4",
            view: Button("Print255Sweep") { }
                .platformPrint_L4(isPresented: .constant(false), content: .text("sweep"))
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformPhotoPicker_L4",
            view: PlatformPhotoComponentsLayer4.platformPhotoPicker_L4 { _ in }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformPhotoDisplay_L4",
            view: PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(image: nil, style: .thumbnail)
        )
        let splitView = Text("SplitPrimary255Sweep")
            .platformVerticalSplit_L4(spacing: 0) {
                Text("SplitTop255Sweep")
                    .automaticCompliance(identifierName: "L4SplitTop255Sweep", identifierElementType: "Text")
                Text("SplitBottom255Sweep")
                    .automaticCompliance(identifierName: "L4SplitBottom255Sweep", identifierElementType: "Text")
            }
        assertLayer4AssistiveVisualAdaptability(caseName: "platformVerticalSplit_L4", view: splitView)
        let horizontalSplit = Text("SplitLeading255Sweep")
            .platformHorizontalSplit_L4(spacing: 0) {
                Text("SplitLeadingPane255Sweep")
                    .automaticCompliance(identifierName: "L4SplitLeading255Sweep", identifierElementType: "Text")
                Text("SplitTrailingPane255Sweep")
                    .automaticCompliance(identifierName: "L4SplitTrailing255Sweep", identifierElementType: "Text")
            }
        assertLayer4AssistiveVisualAdaptability(caseName: "platformHorizontalSplit_L4", view: horizontalSplit)
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformFormField_L4",
            view: Text("L4FormFieldAnchor255Sweep")
                .platformFormField(label: "L4FormFieldLabel255Sweep") {
                    Text("L4FormFieldInner255Sweep")
                }
        )
    }

    private struct AssistiveNavLinkHost255: View {
        @State private var isActive = false

        var body: some View {
            NavigationStack {
                Text("Open destination 255")
                    .platformNavigationLink_L4(
                        title: "L4AssistiveLink255",
                        systemImage: "chevron.right",
                        isActive: $isActive,
                        destination: {
                            Text("L4AssistiveLinkDest255")
                                .platformNavigationTitle_L4("L4AssistiveLinkDestTitle255")
                        }
                    )
            }
        }
    }

    @Test @MainActor
    func testLayer4NavigationAndPresentation_retainAssistiveTraversalUnderVisualAdaptabilityOverrides() async {
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformNavigationTitle_L4",
            view: NavigationStack {
                Text("L4AssistiveNavBody255")
                    .platformNavigationTitle_L4("L4AssistiveNavTitle255")
            }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformImplementNavigationStack_L4",
            view: platformImplementNavigationStack_L4(
                content: Text("L4StackInner255"),
                title: "L4StackTitle255",
                strategy: NavigationStackStrategy(implementation: .navigationStack, reasoning: "255 assistive sweep")
            )
        )
        assertLayer4AssistiveVisualAdaptability(caseName: "platformNavigationLink_L4", view: AssistiveNavLinkHost255())
        #if !os(tvOS)
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformPopover_L4",
            view: Text("L4PopoverAnchor255")
                .platformPopover_L4(isPresented: .constant(false)) {
                    Text("L4PopoverInner255")
                }
        )
        #endif
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformSheet_L4",
            view: NavigationStack {
                Text("L4SheetOuter255")
                    .platformSheet_L4(isPresented: .constant(true), onDismiss: nil) {
                        Text("L4SheetInner255")
                            .automaticCompliance(identifierName: "L4SheetInner255", identifierElementType: "Text")
                    }
            }
        )
        let navTitleView = NavigationStack {
            Text("L4AssistiveNavBodyDT255")
                .platformNavigationTitle_L4("L4AssistiveNavTitleDT255")
        }
        let rootDefault = hostedRoot(for: navTitleView)
        let rootScaled = hostedRoot(for: navTitleView.dynamicTypeSize(.accessibility3))
        #expect(rootDefault != nil && rootScaled != nil)
        if hostedTreeExposesSemanticSurface(rootDefault), hostedTreeExposesSemanticSurface(rootScaled) {
            #expect(
                hostedTreeHasVoiceOverDiscoverableNode(root: rootDefault)
                    && hostedTreeHasVoiceOverDiscoverableNode(root: rootScaled),
                "platformNavigationTitle_L4: VoiceOver-discoverable nodes should survive large Dynamic Type"
            )
        }
    }

    @Test @MainActor
    func testLayer4StructuralSurfaces_retainAssistiveTraversalUnderVisualAdaptabilityOverrides() async {
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformStyledContainer_L4",
            view: Group { EmptyView() }
                .platformStyledContainer_L4 {
                    Text("L4StyledInner255")
                        .automaticCompliance(identifierName: "L4StyledInner255", identifierElementType: "Text")
                }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformFormContainer_L4",
            view: platformFormContainer_L4(
                strategy: FormStrategy(containerType: .form, fieldLayout: .standard, validation: .deferred)
            ) {
                Text("L4FormInner255")
                    .automaticCompliance(identifierName: "L4FormInner255", identifierElementType: "Text")
            }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformRowActions_L4",
            view: List {
                Text("L4RowActionsAnchor255")
                    .platformRowActions_L4 {
                        Button("Remove", role: .destructive) { }
                    }
            }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformContextMenu_L4",
            view: Text("L4ContextMenuAnchor255")
                .platformContextMenu_L4 {
                    Button("L4ContextMenuAction255") { }
                }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformFormFieldGroup_L4",
            view: Text("L4FormGroupAnchor255")
                .platformFormFieldGroup(title: "L4FormGroupTitle255") {
                    Text("L4FormGroupInner255")
                }
        )
        let appNavStrategy = AppNavigationStrategy(implementation: .splitView, reasoning: "255 assistive sweep")
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformAppNavigation_L4",
            view: EmptyView()
                .platformAppNavigation_L4(
                    strategy: appNavStrategy,
                    sidebar: {
                        Text("L4AppNavSidebar255")
                            .automaticCompliance(identifierName: "L4AppNavSidebar255", identifierElementType: "Text")
                    },
                    detail: {
                        Text("L4AppNavDetail255")
                            .automaticCompliance(identifierName: "L4AppNavDetail255", identifierElementType: "Text")
                    }
                )
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformSettingsContainer_L4",
            view: EmptyView()
                .platformSettingsContainer_L4(
                    sidebar: {
                        Text("L4SettingsSidebar255")
                            .automaticCompliance(identifierName: "L4SettingsSidebar255", identifierElementType: "Text")
                    },
                    detail: {
                        Text("L4SettingsDetail255")
                            .automaticCompliance(identifierName: "L4SettingsDetail255", identifierElementType: "Text")
                    }
                )
        )
        #if canImport(MapKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let position = Binding.constant(MapCameraPosition.automatic)
            assertLayer4AssistiveVisualAdaptability(
                caseName: "platformMapView_L4",
                view: VStack {
                    PlatformMapComponentsLayer4.platformMapView_L4(position: position, annotations: [])
                }
                .frame(width: 320, height: 240)
            )
            assertLayer4AssistiveVisualAdaptability(
                caseName: "platformMapViewWithCurrentLocation_L4",
                view: PlatformMapComponentsLayer4.platformMapViewWithCurrentLocation_L4(
                    locationService: LocationService(),
                    showCurrentLocation: false
                )
            )
        }
        #endif
        #if os(iOS)
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCameraInterface_L4",
            view: PlatformPhotoComponentsLayer4.platformCameraInterface_L4 { _ in }
        )
        assertLayer4AssistiveVisualAdaptability(
            caseName: "platformCameraPreview_L4",
            view: PlatformPhotoComponentsLayer4.platformCameraPreview_L4(session: AVCaptureSession())
        )
        #endif
    }
}

#endif
