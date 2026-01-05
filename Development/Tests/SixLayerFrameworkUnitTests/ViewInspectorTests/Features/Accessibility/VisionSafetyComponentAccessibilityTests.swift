import Testing


//
//  VisionSafetyComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL Vision Safety Components
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Vision Safety Component Accessibility")
open class VisionSafetyComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - Vision Safety Component Tests
    
    @Test @MainActor func testVisionSafetyGeneratesAccessibilityIdentifiers() async {
        initializeTestConfig()
        // Given: VisionSafety
        let testView = VisionSafety()
        
        // Then: Should generate accessibility identifiers
        // VERIFIED: VisionSafety DOES have .automaticCompliance() 
        // modifier applied in Framework/Sources/Components/Views/VisionSafety.swift:15.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            testView,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "VisionSafety"
        )
        #expect(hasAccessibilityID, "VisionSafety should generate accessibility identifiers")
    }
}