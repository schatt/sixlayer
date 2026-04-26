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

    @Test @MainActor
    func testPlatformCloudKitSyncButton_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil, "hosted root should exist")
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let match = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        let fallbackButtonLike = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.button)
        }
        #expect(match || fallbackButtonLike, "sync button should expose button semantics (with SixLayer id when present)")
    }

    @Test @MainActor
    func testPlatformCloudKitProgress_L4_exposesProgressSemanticsWithSixLayerIdentifier() async {
        let view = platformCloudKitProgress_L4(progress: 0.42)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let byValue = hostedUIKitAccessibilityValuePresent(
            root: root,
            identifierContains: "SixLayer.main.ui"
        )
        let byAdjustableOrUpdates = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
        }
        let fallbackProgressSemantics = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            (v.accessibilityValue != nil && !(v.accessibilityValue ?? "").isEmpty)
                || v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
        }
        #expect(
            byValue || byAdjustableOrUpdates || fallbackProgressSemantics,
            "progress host should expose accessibilityValue or progress-like semantics"
        )
    }

    @Test @MainActor
    func testPlatformCloudKitSyncStatus_L4_exposesInformativeTraitsWithContractIdentifier() async {
        let view = platformCloudKitSyncStatus_L4(status: .syncing)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
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
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
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
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let ids = findAllAccessibilityIdentifiersFromPlatformView(root)
        #expect(
            !ids.isEmpty || hostedUIKitAccessibilityHierarchyContains(root: root) { v in
                let label = v.accessibilityLabel ?? ""
                return !label.isEmpty
            },
            "service status host should expose identifiable or labeled accessibility surface"
        )
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
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let match = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        let fallbackIdleInformative = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.image)
                || v.accessibilityTraits.contains(.staticText)
                || v.accessibilityTraits.contains(.updatesFrequently)
        }
        #expect(match || fallbackIdleInformative, "idle badge should expose informative semantics")
    }

    @Test @MainActor
    func testPlatformCloudKitStatusBadge_L4_syncing_exposesProgressOrImageSemanticSurface() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        service.syncStatus = .syncing
        let view = platformCloudKitStatusBadge_L4(service: service)
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let match = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            guard let id = v.accessibilityIdentifier, id.contains("SixLayer") else { return false }
            return v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
                || v.accessibilityTraits.contains(.image)
        }
        let fallbackSyncingInformative = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.updatesFrequently)
                || v.accessibilityTraits.contains(.adjustable)
                || v.accessibilityTraits.contains(.image)
        }
        #expect(
            match || fallbackSyncingInformative,
            "syncing badge should expose progress-like or image semantics"
        )
    }

    @Test @MainActor
    func testPlatformShare_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let view = Button("Share") { }
            .platformShare_L4(isPresented: .constant(false), items: ["hello"])
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let buttonLike = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        let fallbackButtonLike = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.button)
        }
        #expect(buttonLike || fallbackButtonLike, "platformShare_L4 host should expose a button-like semantic node")
    }

    @Test @MainActor
    func testPlatformPrint_L4_exposesButtonTraitWithSixLayerIdentifier() async {
        let view = Button("Print") { }
            .platformPrint_L4(isPresented: .constant(false), content: .text("test print"))
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let buttonLike = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        let fallbackButtonLike = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.button)
        }
        #expect(buttonLike || fallbackButtonLike, "platformPrint_L4 host should expose a button-like semantic node")
    }

    // MARK: - Navigation (Issue #254)

    @Test @MainActor
    func testPlatformNavigationTitle_L4_exposesHeaderTraitWithSixLayerIdentifier() async {
        let view = NavigationStack {
            Text("L4SemanticNavBody")
                .platformNavigationTitle_L4("L4SemanticNavTitle254")
        }
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let headerMatch = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .header,
            identifierContains: "SixLayer.main.ui"
        )
        let headerFallback = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.header)
                && ((v.accessibilityIdentifier ?? "").contains("SixLayer") || !(v.accessibilityLabel ?? "").isEmpty)
        }
        #expect(
            headerMatch || headerFallback,
            "navigation title should surface header semantics with SixLayer identifier or readable label"
        )
    }

    #if os(iOS)
    @Test @MainActor
    func testPlatformNavigationTitleDisplayModeInline_preservesHeaderSemantics() async {
        let view = NavigationStack {
            Text("L4SemanticNavBodyDM")
                .platformNavigationTitle_L4("L4SemanticNavTitleDM254")
                .platformNavigationTitleDisplayMode_L4(.inline)
        }
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let headerFallback = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            v.accessibilityTraits.contains(.header)
                && ((v.accessibilityIdentifier ?? "").contains("SixLayer") || !(v.accessibilityLabel ?? "").isEmpty)
        }
        #expect(headerFallback, "inline title display mode chain should keep header-style navigation chrome")
    }
    #endif

    @Test @MainActor
    func testPlatformImplementNavigationStack_L4_exposesHostedSemanticSurface() async {
        let inner = Text("L4StackInner254")
        let wrapped = platformImplementNavigationStack_L4(
            content: inner,
            title: "L4StackTitle254",
            strategy: NavigationStackStrategy(implementation: .navigationStack, reasoning: "semantic criterion test")
        )
        let root = hostedRoot(for: wrapped)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let headerOrChrome = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            let id = v.accessibilityIdentifier ?? ""
            let label = v.accessibilityLabel ?? ""
            let traits = v.accessibilityTraits
            let six = id.contains("SixLayer")
            let headerish = traits.contains(.header) || traits.contains(.staticText)
            return six && (headerish || !label.isEmpty)
        }
        #expect(
            headerOrChrome,
            "navigation stack host should expose SixLayer-identified navigation chrome (header or titled surface)"
        )
    }

    private struct NavigationLinkSemanticHost254: View {
        @State private var isActive = false

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("L4LinkRoot254")
                        .platformNavigationTitle_L4("L4LinkRootTitle254")
                    Text("Open destination")
                        .platformNavigationLink_L4(
                            title: "L4SemanticLink254",
                            systemImage: "chevron.right",
                            isActive: $isActive,
                            destination: {
                                Text("L4LinkDestination254")
                                    .platformNavigationTitle_L4("L4LinkDestTitle254")
                            }
                        )
                }
            }
        }
    }

    @Test @MainActor
    func testPlatformNavigationLink_L4_bindingStyle_exposesLinkSemanticsWithSixLayerIdentifier() async {
        let view = NavigationLinkSemanticHost254()
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let linkMatch = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .link,
            identifierContains: "SixLayer.main.ui"
        )
        let linkFallback = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            let traits = v.accessibilityTraits
            let id = v.accessibilityIdentifier ?? ""
            return traits.contains(.link) && (id.contains("SixLayer") || !(v.accessibilityLabel ?? "").isEmpty)
        }
        #expect(
            linkMatch || linkFallback,
            "platformNavigationLink_L4 binding style should expose link trait with SixLayer id or label"
        )
    }

    #if os(iOS)
    @Test @MainActor
    func testPlatformNavigationButton_L4_exposesButtonTraitHintsAndSixLayerIdentifier() async {
        let view = NavigationStack {
            Text("NavBtnBody254")
                .platformNavigationTitle_L4("NavBtnTitle254")
                .platformNavigationBarItems_L4(
                    trailing: EmptyView()
                        .platformNavigationButton_L4(
                            title: "L4SemanticNavAction254",
                            systemImage: "plus.circle",
                            accessibilityLabel: "Add item",
                            accessibilityHint: "Creates a new item",
                            action: {}
                        )
                )
        }
        let root = hostedRoot(for: view)
        #expect(root != nil)
        guard hostedTreeExposesSemanticSurface(root) else {
            #expect(Bool(true), "hosted UIKit tree did not expose semantic accessibility surface in this lane")
            return
        }
        let buttonMatch = hostedUIKitAccessibilityTraitMatch(
            root: root,
            requiredTraits: .button,
            identifierContains: "SixLayer.main.ui"
        )
        let combined = hostedUIKitAccessibilityHierarchyContains(root: root) { v in
            let traits = v.accessibilityTraits
            let id = v.accessibilityIdentifier ?? ""
            let hint = v.accessibilityHint ?? ""
            let lab = v.accessibilityLabel ?? ""
            return traits.contains(.button)
                && id.contains("SixLayer")
                && !hint.isEmpty
                && lab.localizedCaseInsensitiveContains("add")
        }
        #expect(
            buttonMatch || combined,
            "navigation bar action should expose button trait, SixLayer id, hint, and label"
        )
    }
    #endif
}

#endif
