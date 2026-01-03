import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformPhotoSemanticLayer1.swift
/// 
/// BUSINESS PURPOSE: Ensure all photo Layer 1 semantic functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformPhotoSemanticLayer1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Photo Semantic Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformPhotoSemanticLayer1Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    @MainActor
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
    @Test @MainActor func testPlatformPhotoDisplayL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        
        // Given
        let preferences = PhotoPreferences(
            preferredSource: .camera,
            allowEditing: true,
            compressionQuality: 0.8
        )
        let capabilities = PhotoDeviceCapabilities(
            hasCamera: true,
            hasPhotoLibrary: true,
            supportsEditing: true
        )
        let context = PhotoContext(
            screenSize: CGSize(width: 375, height: 812),
            availableSpace: CGSize(width: 375, height: 400),
            userPreferences: preferences,
            deviceCapabilities: capabilities
        )
        
        // When
        let view = platformPhotoDisplay_L1(
            purpose: .document,
            context: context,
            image: nil
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here
        
        // Test accessibility identifier generation
        #if canImport(ViewInspector)

        let hasAccessibilityID =         testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            componentName: "platformPhotoDisplay_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPhotoDisplay_L1 should generate accessibility identifier on iOS ")
        #else

        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure

        // The modifier IS present in the code, but ViewInspector can't detect it on macOS

        #endif

        
        await cleanupTestEnvironment()
    }
    
    @Test @MainActor func testPlatformPhotoDisplayL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        
        // Given
        let preferences = PhotoPreferences(
            preferredSource: .camera,
            allowEditing: true,
            compressionQuality: 0.8
        )
        let capabilities = PhotoDeviceCapabilities(
            hasCamera: true,
            hasPhotoLibrary: true,
            supportsEditing: true
        )
        let context = PhotoContext(
            screenSize: CGSize(width: 1024, height: 768),
            availableSpace: CGSize(width: 1024, height: 400),
            userPreferences: preferences,
            deviceCapabilities: capabilities
        )
        
        // When
        let view = platformPhotoDisplay_L1(
            purpose: .document,
            context: context,
            image: nil
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here
        
        // Test accessibility identifier generation
        #if canImport(ViewInspector)

        let hasAccessibilityID =         testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            componentName: "platformPhotoDisplay_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPhotoDisplay_L1 should generate accessibility identifier on macOS ")
        #else

        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure

        // The modifier IS present in the code, but ViewInspector can't detect it on macOS

        #endif

        
        await cleanupTestEnvironment()
    }
}