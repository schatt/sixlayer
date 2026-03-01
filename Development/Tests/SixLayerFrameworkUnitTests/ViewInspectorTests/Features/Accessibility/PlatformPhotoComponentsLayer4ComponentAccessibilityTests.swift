import Testing


//
//  PlatformPhotoComponentsLayer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Comprehensive accessibility tests for ALL Platform Photo Components Layer 4.
//  Issue #169: Complete accessibility for Layer 4 platform* methods.
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Photo Components Layer Component Accessibility")
open class PlatformPhotoComponentsLayer4ComponentAccessibilityTests: BaseTestClass {

    // MARK: - platformPhotoPicker_L4

    @Test @MainActor func testPlatformPhotoPickerL4GeneratesAccessibilityIdentifiers() async {
        let view = PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: { _ in })
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformPhotoPicker_L4"
        )
        #expect(hasAccessibilityID, "platformPhotoPicker_L4 should generate accessibility identifiers")
    }

    // MARK: - platformCameraInterface_L4

    @Test @MainActor func testPlatformCameraInterfaceL4GeneratesAccessibilityIdentifiers() async {
        let view = PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: { _ in })
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*",
            platform: SixLayerPlatform.iOS,
            componentName: "platformCameraInterface_L4"
        )
        #expect(hasAccessibilityID, "platformCameraInterface_L4 should generate accessibility identifiers")
    }
}

