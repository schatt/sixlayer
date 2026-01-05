import Testing


//
//  PlatformPhotoComponentsLayer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL Platform Photo Components Layer 4
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Photo Components Layer Component Accessibility")
open class PlatformPhotoComponentsLayer4ComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - Platform Photo Components Layer 4 Tests
    
    @Test @MainActor func testPlatformPhotoComponentsLayer4GeneratesAccessibilityIdentifiers() async {
        // Given: PlatformPhotoComponentsLayer4
        
        
        // When: Get a view from the component
        let testView = PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: { _ in })
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            testView,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformPhotoComponentsLayer4"
        )
        #expect(hasAccessibilityID, "PlatformPhotoComponentsLayer4 should generate accessibility identifiers ")
    }
}

