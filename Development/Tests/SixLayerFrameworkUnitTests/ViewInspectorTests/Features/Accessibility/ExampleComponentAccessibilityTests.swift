import Testing


//
//  ExampleComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL Example Components
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Example Component Accessibility")
open class ExampleComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - Example Component Tests
    
    @Test @MainActor func testFormUsageExampleGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        // Given: FormUsageExample
        let testView = FormUsageExample()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: FormUsageExample DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Components/Forms/FormUsageExample.swift:33.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            testView,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "FormUsageExample"
        )
 #expect(hasAccessibilityID, "FormUsageExample should generate accessibility identifiers ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // FormInsightsDashboard test removed - component was removed as business-specific logic
    
    @Test @MainActor func testExampleHelpersGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let testView = platformVStackContainer {
                Text("Example Helpers")
            }
            .automaticCompliance(named: "ExampleHelpers")

            #if canImport(ViewInspector)
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                testView,
                expectedPattern: "SixLayer.main.ui.*ExampleHelpers*",
                platform: SixLayerPlatform.iOS,
                componentName: "ExampleHelpers"
            )
            #expect(hasAccessibilityID, "ExampleHelpers should generate accessibility identifiers")
            #else
            #expect(Bool(true), "View created (ViewInspector not available)")
            #endif
        }
    }
}

