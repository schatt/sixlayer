//
//  PlatformCloudKitComponentsLayer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Accessibility tests for Layer 4 CloudKit platform*_L4 components.
//  Issue #169: Complete accessibility for Layer 4 platform* methods.
//

import Testing
import SwiftUI
import CloudKit
@testable import SixLayerFramework

#if canImport(UIKit) || canImport(AppKit)
@MainActor
private func hostedRootForIssue169CloudKitContract<V: View>(_ view: V) -> Any? {
    let config = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
    config.enableDebugLogging = true
    config.clearDebugLog()
    return AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
        TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true,
            accessibilityIdentifierConfig: config
        )
    }
}
#endif

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform CloudKit Components Layer 4 Accessibility")
open class PlatformCloudKitComponentsLayer4ComponentAccessibilityTests: BaseTestClass {

    // MARK: - platformCloudKitSyncStatus_L4

    @Test @MainActor func testPlatformCloudKitSyncStatusL4GeneratesAccessibilityIdentifiers() async {
        let view = platformCloudKitSyncStatus_L4(status: .idle)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitSyncStatus_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitSyncStatus_L4 should generate accessibility identifiers")
    }

    // MARK: - platformCloudKitProgress_L4

    @Test @MainActor func testPlatformCloudKitProgressL4GeneratesAccessibilityIdentifiers() async {
        let view = platformCloudKitProgress_L4(progress: 0.5)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitProgress_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitProgress_L4 should generate accessibility identifiers")
    }

    // MARK: - platformCloudKitAccountStatus_L4

    @Test @MainActor func testPlatformCloudKitAccountStatusL4GeneratesAccessibilityIdentifiers() async {
        let view = platformCloudKitAccountStatus_L4(status: .available)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitAccountStatus_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitAccountStatus_L4 should generate accessibility identifiers")
    }

    // MARK: - platformCloudKitServiceStatus_L4, platformCloudKitSyncButton_L4, platformCloudKitStatusBadge_L4

    @Test @MainActor func testPlatformCloudKitServiceStatusL4GeneratesAccessibilityIdentifiers() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitServiceStatus_L4(service: service)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitServiceStatus_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitServiceStatus_L4 should generate accessibility identifiers")
    }

    @Test @MainActor func testPlatformCloudKitSyncButtonL4GeneratesAccessibilityIdentifiers() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitSyncButton_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitSyncButton_L4 should generate accessibility identifiers")
    }

    @Test @MainActor func testPlatformCloudKitStatusBadgeL4GeneratesAccessibilityIdentifiers() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitStatusBadge_L4(service: service)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCloudKitStatusBadge_L4"
        )
        #expect(hasAccessibilityID, "platformCloudKitStatusBadge_L4 should generate accessibility identifiers")
    }

    // MARK: - Issue #169: VoiceOver label + hint on named compliance roots (hosted)

    #if canImport(UIKit) || canImport(AppKit)

    @Test @MainActor func testPlatformCloudKitSyncStatusL4NamedElementHasVoiceOverLabel() async {
        let view = platformCloudKitSyncStatus_L4(status: .idle)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitSyncStatus_L4",
                labelSubstring: "CloudKit"
            ),
            "platformCloudKitSyncStatus_L4 must surface a generated id and CloudKit-related VoiceOver label text (Issue #169)"
        )
    }

    @Test @MainActor func testPlatformCloudKitProgressL4NamedElementHasVoiceOverLabel() async {
        let view = platformCloudKitProgress_L4(progress: 0.5)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitProgress_L4",
                labelSubstring: "percent"
            ),
            "platformCloudKitProgress_L4 must surface a generated id and progress label text (Issue #169)"
        )
    }

    @Test @MainActor func testPlatformCloudKitAccountStatusL4NamedElementHasVoiceOverLabel() async {
        let view = platformCloudKitAccountStatus_L4(status: .available)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitAccountStatus_L4",
                labelSubstring: "iCloud"
            ),
            "platformCloudKitAccountStatus_L4 must surface a generated id and iCloud account label text (Issue #169)"
        )
    }

    @Test @MainActor func testPlatformCloudKitServiceStatusL4NamedElementHasVoiceOverLabel() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitServiceStatus_L4(service: service)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitServiceStatus_L4",
                labelSubstring: "CloudKit"
            ),
            "platformCloudKitServiceStatus_L4 must surface a generated id and CloudKit-related label text (Issue #169)"
        )
    }

    @Test @MainActor func testPlatformCloudKitSyncButtonL4NamedElementHasVoiceOverLabelAndHint() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitSyncButton_L4(service: service)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitSyncButton_L4",
                labelSubstring: "Sync"
            ),
            "platformCloudKitSyncButton_L4 must surface a generated id and button label text (Issue #169)"
        )
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsHintText(
                root: root,
                identifierSubstring: "platformCloudKitSyncButton_L4",
                hintSubstring: "Starts"
            ),
            "platformCloudKitSyncButton_L4 must surface a generated id and a sync hint (Issue #169)"
        )
    }

    @Test @MainActor func testPlatformCloudKitStatusBadgeL4NamedElementHasVoiceOverLabel() async {
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        let view = platformCloudKitStatusBadge_L4(service: service)
        let root = hostedRootForIssue169CloudKitContract(view)
        #expect(
            hostedPlatformViewExposesIdentifierAndContainsLabelText(
                root: root,
                identifierSubstring: "platformCloudKitStatusBadge_L4",
                labelSubstring: "CloudKit"
            ),
            "platformCloudKitStatusBadge_L4 must surface a generated id and CloudKit status label text (Issue #169)"
        )
    }

    #endif
}
