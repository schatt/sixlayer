import XCTest
@testable import SixLayerFramework

/// Test ButtonStyle compatibility across different deployment targets
final class ButtonStyleCompatibilityTests: XCTestCase {
    
    @MainActor
    func testAlertButtonCreation() {
        let messagingLayer = PlatformMessagingLayer5()
        
        // Test that we can create alert buttons without compilation errors
        let button = messagingLayer.createAlertButton(
            title: "Test Button",
            style: .default
        ) {
            // Test action
        }
        
        // Verify the button was created (basic smoke test)
        XCTAssertNotNil(button)
    }
    
    @MainActor
    func testDestructiveAlertButtonCreation() {
        let messagingLayer = PlatformMessagingLayer5()
        
        // Test destructive button style
        let destructiveButton = messagingLayer.createAlertButton(
            title: "Delete",
            style: .destructive
        ) {
            // Test action
        }
        
        // Verify the button was created (basic smoke test)
        XCTAssertNotNil(destructiveButton)
    }
}