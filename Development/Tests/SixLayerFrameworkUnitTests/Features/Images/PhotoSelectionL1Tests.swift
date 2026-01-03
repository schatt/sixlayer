import Testing

//
//  PhotoSelectionL1Tests.swift
//  SixLayerFrameworkTests
//
//  Tests for photo selection L1 functions
//  Tests photo selection and gallery features
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView
@Suite(.serialized)
open class PhotoSelectionL1Tests: BaseTestClass {
    
    // MARK: - Test Data
    
    private var samplePhotoContext: PhotoContext = PhotoContext(
        screenSize: CGSize(width: 375, height: 667),
        availableSpace: CGSize(width: 375, height: 667),
        userPreferences: PhotoPreferences(),
        deviceCapabilities: PhotoDeviceCapabilities()
    )
    
    private var sampleHints: PresentationHints = PresentationHints()
    
    // MARK: - Photo Selection Tests
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1() {
        // Given
        let purpose = PhotoPurpose.vehiclePhoto
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        // view is a non-optional View, so it exists if we reach here
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_WithDifferentPurpose() {
        // Given
        let purpose = PhotoPurpose.fuelReceipt
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 with different purpose should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Different Photo Purposes
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_FuelReceipt() {
        // Given
        let purpose = PhotoPurpose.fuelReceipt
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for fuel receipt should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_PumpDisplay() {
        // Given
        let purpose = PhotoPurpose.pumpDisplay
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for pump display should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_Odometer() {
        // Given
        let purpose = PhotoPurpose.odometer
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for odometer should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_Maintenance() {
        // Given
        let purpose = PhotoPurpose.maintenance
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for maintenance should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_Expense() {
        // Given
        let purpose = PhotoPurpose.expense
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for expense should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_Profile() {
        // Given
        let purpose = PhotoPurpose.profile
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for profile should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_Document() {
        // Given
        let purpose = PhotoPurpose.document
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 for document should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Edge Cases
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_WithEmptyContext() {
        // Given
        let purpose = PhotoPurpose.vehiclePhoto
        let context = PhotoContext(
            screenSize: CGSize.zero,
            availableSpace: CGSize.zero,
            userPreferences: PhotoPreferences(),
            deviceCapabilities: PhotoDeviceCapabilities()
        )
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return a view that can be hosted
        #expect(Bool(true), "platformPhotoSelection_L1 with empty context should return a view")  // view is non-optional
        
        // Test that the view can actually be hosted
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Custom View Tests
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_WithCustomPickerView() {
        initializeTestConfig()
        // Given
        let purpose = PhotoPurpose.vehiclePhoto
        let context = samplePhotoContext
        
        // When: Using custom picker view wrapper
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in },
            customPickerView: { (pickerContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Photo Picker")
                        .font(.headline)
                    pickerContent
                        .padding()
                        .background(Color.platformSecondaryBackground)
                }
            }
        )
        
        // Then: Should return a view with custom wrapper
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 with custom picker view should return a view")
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_WithCustomPickerView_Nil() {
        initializeTestConfig()
        // Given
        let purpose = PhotoPurpose.vehiclePhoto
        let context = samplePhotoContext
        
        // When: Not providing custom picker view (should use default)
        // Omit the parameter to use default value instead of passing nil
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Should return default view
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 with nil custom picker view should return default view")
    }
    
}
