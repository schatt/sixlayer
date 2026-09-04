import Testing
import Foundation
import SwiftUI
@testable import SixLayerFramework

//
//  Layer5ComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Tests Layer 5 platform components for accessibility - these are classes with methods that return Views
//

@Suite("Layer Component Accessibility", HostedViewTestIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class Layer5ComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - Layer 5 Platform Component Tests
    
    @Test @MainActor func testPlatformMessagingLayer5GeneratesAccessibilityIdentifiers() async {
        // Given: Layer 5 messaging component
        let messagingLayer = PlatformMessagingLayer5()
        
        // When: Creating alert button view
        let alertButtonView = messagingLayer.createAlertButton(
            title: "Test Alert",
            style: .default,
            action: {}
        )
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            alertButtonView,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformMessagingLayer5"
        )
        #expect(hasAccessibilityID, "PlatformMessagingLayer5 should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformMessagingLayer5ToastGeneratesAccessibilityIdentifiers() async {
        // Given: Layer 5 messaging component
        let messagingLayer = PlatformMessagingLayer5()
        
        // When: Creating toast notification view
        let toastView = messagingLayer.createToastNotification(
            message: "Test Toast",
            type: .info
        )
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            toastView,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformMessagingLayer5Toast"
        )
        #expect(hasAccessibilityID, "PlatformMessagingLayer5 toast should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformResourceLayer5GeneratesAccessibilityIdentifiers() async {
        // Given: Layer 5 resource component
        let resourceLayer = PlatformResourceLayer5()
        
        // When: Creating resource button view
        let resourceButtonView = resourceLayer.createResourceButton(
            title: "Test Resource",
            action: {}
        )
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            resourceButtonView,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformResourceLayer5"
        )
        #expect(hasAccessibilityID, "PlatformResourceLayer5 should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformResourceLayer5ImageGeneratesAccessibilityIdentifiers() async {
        // Given: Layer 5 resource component
        let resourceLayer = PlatformResourceLayer5()
        
        // When: Creating image view
        let imageView = resourceLayer.createImageView(
            image: nil,
            placeholder: "Test Image"
        )
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            imageView,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformResourceLayer5Image"
        )
        #expect(hasAccessibilityID, "PlatformResourceLayer5 image should generate accessibility identifiers ")
    }
}