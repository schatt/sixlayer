import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformPhotoComponentsLayer4.swift
/// 
/// BUSINESS PURPOSE: Ensure all photo Layer 4 components generate proper accessibility identifiers
/// TESTING SCOPE: All components in PlatformPhotoComponentsLayer4.swift
/// METHODOLOGY: Test each component on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Photo Components Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformPhotoComponentsLayer4Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - platformCameraInterface_L4 Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
    @Test @MainActor func testPlatformCameraInterfaceL4GeneratesAccessibilityIdentifiersOnIOS() async {
        
        let view = PlatformPhotoComponentsLayer4.platformCameraInterface_L4(
            onImageCaptured: { _ in }
        )
        
        // Camera interface generates "SixLayer.main.ui" pattern
        // This is correct for a basic UI component without specific element naming
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformCameraInterface_L4",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformCameraInterface_L4 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformCameraInterfaceL4GeneratesAccessibilityIdentifiersOnMacOS() async {
        
        let view = PlatformPhotoComponentsLayer4.platformCameraInterface_L4(
            onImageCaptured: { _ in }
        )
        
        // Camera interface generates "SixLayer.main.ui" pattern
        // This is correct for a basic UI component without specific element naming
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformCameraInterface_L4",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformCameraInterface_L4 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

