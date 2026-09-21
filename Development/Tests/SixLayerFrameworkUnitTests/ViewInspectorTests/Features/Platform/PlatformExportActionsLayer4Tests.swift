import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  PlatformExportActionsLayer4Tests.swift
//  SixLayerFrameworkUnitTests
//
//  ViewInspector / hosted a11y for platformExportActions_L4 modifier.
//  Pure resolution + imperative fast paths live in Features/Platform/
//  PlatformExportActionsLayer4UnitTests (#467).
//

@Suite("Platform Export Actions Layer 4", HostedViewTestIsolationTrait())
open class PlatformExportActionsLayer4Tests: BaseTestClass {

    @Test @MainActor func testPlatformExportActionsModifier_generatesAccessibilityIdentifiers() {
        let view = Text("Export")
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
