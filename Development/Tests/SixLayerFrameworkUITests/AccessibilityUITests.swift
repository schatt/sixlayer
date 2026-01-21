//
//  AccessibilityUITests.swift
//  SixLayerFrameworkUITests / SixLayerFrameworkRealUITests
//
//  XCUITest tests for accessibility identifier generation
//  These tests use XCUIApplication and XCUIElement to verify
//  that accessibility identifiers are actually usable by UI testing frameworks
//
//  This file is shared between SixLayerFrameworkUITests and SixLayerFrameworkRealUITests
//  targets. Platform-specific differences are handled via conditional branching.
//

import XCTest
@testable import SixLayerFramework

// Note: Helper extensions are defined in XCUITestHelpers.swift
// This file is shared between UITests and RealUITests targets
// Both targets include XCUITestHelpers.swift, so no duplicates needed here

/// XCUITest tests for accessibility identifier generation
/// These tests verify that identifiers are findable using XCUIElement queries,
/// which is how real UI tests would use them
@MainActor
final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Add UI interruption monitors to dismiss system dialogs quickly
        // This prevents XCUITest from waiting for Bluetooth, CPU, and other system dialogs
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { @MainActor (alert) -> Bool in
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
        
        // Launch the test app with performance optimizations
        // Use performance logging if enabled (SixLayerFrameworkUITests target sets USE_XCUITEST_PERFORMANCE)
        let usePerformanceLogging = ProcessInfo.processInfo.environment["USE_XCUITEST_PERFORMANCE"] == "1"
        
        if usePerformanceLogging {
            let (_, launchTime) = XCUITestPerformance.measure {
                app = XCUIApplication()
                app.launchWithOptimizations()
            }
            XCUITestPerformance.log("App launch", time: launchTime)
        } else {
            app = XCUIApplication()
            app.launchWithOptimizations()
        }
        
        // Wait for app to be ready before querying elements
        // This ensures SwiftUI has finished initial render and accessibility tree is built
        if usePerformanceLogging {
            let (_, readyTime) = XCUITestPerformance.measure {
                XCTAssertTrue(app.waitForReady(timeout: 5.0), "App should be ready for testing")
            }
            XCUITestPerformance.log("App readiness check", time: readyTime)
        } else {
            XCTAssertTrue(app.waitForReady(timeout: 5.0), "App should be ready for testing")
        }
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    /// CONTROL TEST: Verify that XCUITest can find a standard SwiftUI button with direct .accessibilityIdentifier()
    /// This proves the testing infrastructure works before testing our modifier
    func testControlDirectAccessibilityIdentifier() throws {
        // Given: App is launched and ready (from setUp)
        // The control button is always visible (not behind picker)
        // First verify the button exists by label (confirms app is working)
        let controlButtonByLabel = app.buttons["Control Button"]
        let exists = controlButtonByLabel.existsImmediately || controlButtonByLabel.waitForExistenceFast(timeout: 3.0)
        guard exists else {
            XCTFail("Control button should exist by label - app may not be fully loaded")
            return
        }
        
        // When: Query for element by accessibility identifier using XCUITest
        // This is a standard SwiftUI .accessibilityIdentifier() - no framework modifier
        // CRITICAL: We must find it by identifier, not by label
        let controlIdentifier = "control-test-button"
        
        // Use helper to find element by identifier (tries multiple query types)
        guard app.findElement(byIdentifier: controlIdentifier, 
                             primaryType: .button,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Control test failed: Standard SwiftUI .accessibilityIdentifier('\(controlIdentifier)') should be findable using XCUITest. This indicates an XCUITest infrastructure problem, not a framework bug.")
            return
        }
        
        // Found it by identifier! Control test passes - XCUITest infrastructure works
        // This proves XCUITest can find identifiers, so if our modifier fails, it's our bug
    }
    
    /// Test that Text view generates accessibility identifier that XCUITest can find
    func testTextAccessibilityIdentifierGenerated() throws {
        // App is already ready from setUp, so we can query elements immediately
        // Text is the default, so we can verify it's selected by checking the view exists
        
        // Wait for the view to appear (should be immediate since Text is default)
        let textView = app.staticTexts["Test Content"]
        XCTAssertTrue(textView.existsImmediately || textView.waitForExistenceFast(timeout: 0.5), 
                     "Text view should exist immediately")
        
        // Find element by accessibility identifier using helper (tries multiple query types)
        let expectedIdentifier = "SixLayer.main.ui.element.View"
        let usePerformanceLogging = ProcessInfo.processInfo.environment["USE_XCUITEST_PERFORMANCE"] == "1"
        
        let elementFound: Bool
        if usePerformanceLogging {
            let (foundElement, queryTime) = XCUITestPerformance.measure {
                app.findElement(byIdentifier: expectedIdentifier,
                               primaryType: .other,
                               secondaryTypes: [.staticText, .any])
            }
            XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
            elementFound = foundElement != nil
        } else {
            elementFound = app.findElement(byIdentifier: expectedIdentifier,
                                          primaryType: .other,
                                          secondaryTypes: [.staticText, .any]) != nil
        }
        
        guard elementFound else {
            XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest. Tried otherElements, staticTexts, and any elements.")
            return
        }
        
        // Found it! Test passes
    }
    
    /// Test that Button view generates accessibility identifier that XCUITest can find
    func testButtonAccessibilityIdentifierGenerated() throws {
        // App is already ready from setUp, so we can query elements immediately
        // Select Button view type using helper (handles iOS/macOS differences)
        XCTAssertTrue(app.selectPickerSegment("Button"), 
                     "Button segment should exist and be selectable")
        
        // Wait for the button to appear (may need slightly longer timeout after interaction)
        let testButton = app.buttons["Test Button"]
        XCTAssertTrue(testButton.waitForExistenceFast(timeout: 1.0), "Button should exist after selection")
        
        // Find element by accessibility identifier using helper (tries multiple query types)
        let expectedIdentifier = "SixLayer.main.ui.element.Button"
        let usePerformanceLogging = ProcessInfo.processInfo.environment["USE_XCUITEST_PERFORMANCE"] == "1"
        
        let elementFound: Bool
        if usePerformanceLogging {
            let (foundElement, queryTime) = XCUITestPerformance.measure {
                app.findElement(byIdentifier: expectedIdentifier,
                               primaryType: .other,
                               secondaryTypes: [.button, .any])
            }
            XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
            elementFound = foundElement != nil
        } else {
            elementFound = app.findElement(byIdentifier: expectedIdentifier,
                                          primaryType: .other,
                                          secondaryTypes: [.button, .any]) != nil
        }
        
        guard elementFound else {
            XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest. Tried otherElements, buttons, and any elements.")
            return
        }
        
        // Found it! Test passes
    }
}
