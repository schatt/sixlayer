//
//  PlatformSharePrintLayer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkUnitTests
//
//  Accessibility tests for Layer 4 Share and Print platform*_L4 components.
//  Issue #169: Complete accessibility for Layer 4 platform* methods.
//

import Testing
import SwiftUI
@testable import SixLayerFramework

@Suite("Platform Share and Print Layer 4 Accessibility")
open class PlatformSharePrintLayer4ComponentAccessibilityTests: BaseTestClass {

    // MARK: - platformShare_L4

    @Test @MainActor func testPlatformShareL4GeneratesAccessibilityIdentifiers() async {
        let view = Text("Share trigger")
            .platformShare_L4(isPresented: .constant(false), items: [])
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformShare_L4"
        )
        #expect(hasAccessibilityID, "platformShare_L4 should generate accessibility identifiers")
    }

    @Test @MainActor func testPlatformShareL4ItemsOverloadGeneratesAccessibilityIdentifiers() async {
        let view = Text("Share")
            .platformShare_L4(items: [], from: nil)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformShare_L4"
        )
        #expect(hasAccessibilityID, "platformShare_L4(items:from:) should generate accessibility identifiers")
    }

    // MARK: - platformPrint_L4

    @Test @MainActor func testPlatformPrintL4GeneratesAccessibilityIdentifiers() async {
        let view = Text("Print trigger")
            .platformPrint_L4(
                isPresented: .constant(false),
                content: .text("Test"),
                onComplete: nil
            )
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformPrint_L4"
        )
        #expect(hasAccessibilityID, "platformPrint_L4 should generate accessibility identifiers")
    }

    // MARK: - platformExportActions_L4

    @Test @MainActor func testPlatformExportActionsL4GeneratesAccessibilityIdentifiers() async {
        let view = Text("Export trigger")
            .platformExportActions_L4(
                isPresented: .constant(false),
                payload: nil,
                options: .init(),
                onComplete: nil
            )
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformExportActions_L4"
        )
        #expect(hasAccessibilityID, "platformExportActions_L4 should generate accessibility identifiers")
    }
}
