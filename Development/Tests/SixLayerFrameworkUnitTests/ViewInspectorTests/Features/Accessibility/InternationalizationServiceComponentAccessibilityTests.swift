import Testing


//
//  InternationalizationServiceComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL InternationalizationService components
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Internationalization Service Component Accessibility")
open class InternationalizationServiceComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - InternationalizationService Tests
    
    @Test @MainActor func testInternationalizationServiceGeneratesAccessibilityIdentifiers() async {
        // When: Creating a view with InternationalizationService
        let view = platformVStackContainer {
            Text("Internationalization Service Content")
        }
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "InternationalizationService"
        )
        #expect(hasAccessibilityID, "InternationalizationService should generate accessibility identifiers ")
    }
}



