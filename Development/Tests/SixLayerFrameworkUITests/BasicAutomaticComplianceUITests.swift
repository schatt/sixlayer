//
//  BasicAutomaticComplianceUITests.swift
//  SixLayerFrameworkUITests
//
//  XCUITest tests for basic automatic compliance
//  Implements Issue #172: Lightweight Compliance for Basic SwiftUI Types
//
//  These tests use XCUIApplication and XCUIElement to verify
//  that basic compliance identifiers/labels are actually usable by UI testing frameworks
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift

/// XCUITest tests for basic automatic compliance
/// These tests verify that basic compliance identifiers/labels are findable using XCUIElement queries
@MainActor
final class BasicAutomaticComplianceUITests: XCTestCase {
    var app: XCUIApplication!
    
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Add UI interruption monitors to dismiss system dialogs quickly
        // This prevents XCUITest from waiting for Bluetooth, CPU, and other system dialogs
        // Note: Closure must be nonisolated because addUIInterruptionMonitor doesn't accept @MainActor closures
        // XCUITest runs on the main thread, so accessing main actor-isolated properties is safe
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { (alert) -> Bool in
            // XCUITest interruption monitors are called on the main thread
            // Use MainActor.assumeIsolated to access main actor-isolated properties
            return MainActor.assumeIsolated {
                // Dismiss any system alerts that might appear
                let alertText = alert.staticTexts.firstMatch.label
                if alertText.contains("Bluetooth") || alertText.contains("CPU") || alertText.contains("Activity Monitor") {
                    // Try to dismiss by clicking "OK", "Cancel", or "Don't Allow" buttons
                    if alert.buttons["OK"].exists {
                        alert.buttons["OK"].tap()
                        return true
                    }
                    if alert.buttons["Cancel"].exists {
                        alert.buttons["Cancel"].tap()
                        return true
                    }
                    if alert.buttons["Don't Allow"].exists {
                        alert.buttons["Don't Allow"].tap()
                        return true
                    }
                }
                return false
            }
        }
        
        // Launch the test app with performance optimizations
        // Use performance logging if enabled (SixLayerFrameworkUITests target sets USE_XCUITEST_PERFORMANCE)
        // Note: setUpWithError() is nonisolated (inherited from XCTestCase), so we need to use MainActor.assumeIsolated
        // to access main actor-isolated properties like 'app'
        let usePerformanceLogging = ProcessInfo.processInfo.environment["USE_XCUITEST_PERFORMANCE"] == "1"
        
        // Use nonisolated(unsafe) since we know we're on MainActor (class is @MainActor and assumeIsolated confirms it)
        nonisolated(unsafe) let instance = self
        try MainActor.assumeIsolated {
            // Use local variable to avoid capturing self in closures
            var localApp: XCUIApplication!
            
            if usePerformanceLogging {
                let (_, launchTime) = XCUITestPerformance.measure {
                    localApp = XCUIApplication()
                    localApp.launchWithOptimizations()
                }
                // Access app property via unsafe reference - safe because we're on MainActor
                instance.app = localApp
                XCUITestPerformance.log("App launch", time: launchTime)
            } else {
                localApp = XCUIApplication()
                localApp.launchWithOptimizations()
                instance.app = localApp
            }
            
            // Wait for app to be ready before querying elements
            // This ensures SwiftUI has finished initial render and accessibility tree is built
            if usePerformanceLogging {
                let (_, readyTime) = XCUITestPerformance.measure {
                    XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
                }
                XCUITestPerformance.log("App readiness check", time: readyTime)
            } else {
                XCTAssertTrue(localApp.waitForReady(timeout: 5.0), "App should be ready for testing")
            }
        }
    }
    
    nonisolated override func tearDownWithError() throws {
        // Note: tearDownWithError() is nonisolated (inherited from XCTestCase), so we need to use MainActor.assumeIsolated
        // to access main actor-isolated properties like 'app'
        // Use nonisolated(unsafe) since we know we're on MainActor (class is @MainActor and assumeIsolated confirms it)
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
            // Access app property via unsafe reference - safe because we're on MainActor
            instance.app = nil
        }
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Compliance Identifier Tests
    
    /// Test that .basicAutomaticCompliance() identifier is findable via XCUITest
    @MainActor
    func testBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element by basic compliance identifier using XCUITest
        // Then: Should be findable
        
        // TDD RED PHASE: This test will fail because basic compliance doesn't apply identifiers yet
        // The test compiles, but the identifier won't be found (Red phase)
        let testIdentifier = "SixLayer.main.ui.testView"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .staticText,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Basic compliance identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
    
    /// Test that .basicAutomaticCompliance() label is readable via XCUITest
    @MainActor
    func testBasicAutomaticCompliance_LabelIsReadable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element by basic compliance label using XCUITest
        // Then: Should be readable
        
        // TDD RED PHASE: This test will fail because basic compliance doesn't apply labels yet
        let testLabel = "Test label"
        
        let element = app.staticTexts[testLabel]
        guard element.existsImmediately || element.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Basic compliance label '\(testLabel)' should be readable via XCUITest")
            return
        }
    }
    
    /// Test that Text with .basicAutomaticCompliance() identifier is findable
    @MainActor
    func testTextBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for Text element by basic compliance identifier using XCUITest
        // Then: Should be findable
        
        // TDD RED PHASE: This test will fail because Text.basicAutomaticCompliance() doesn't apply identifiers yet
        let testIdentifier = "SixLayer.main.ui.helloText"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .staticText,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Text.basicAutomaticCompliance() identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
    
    /// Test that Image with .basicAutomaticCompliance() identifier is findable
    @MainActor
    func testImageBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for Image element by basic compliance identifier using XCUITest
        // Then: Should be findable
        
        // TDD RED PHASE: This test will fail because Image.basicAutomaticCompliance() doesn't apply identifiers yet
        let testIdentifier = "SixLayer.main.ui.starImage"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .image,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Image.basicAutomaticCompliance() identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
}
