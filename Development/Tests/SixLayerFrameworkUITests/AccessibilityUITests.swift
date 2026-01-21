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

// Extend XCUIApplication with helpers
// These are defined in XCUITestHelpers.swift for UITests target
// For RealUITests target, we define them here as extensions (duplicated for DRY)
extension XCUIApplication {
    /// Wait for app to be ready before querying elements
    func waitForReady(timeout: TimeInterval = 5.0) -> Bool {
        return staticTexts["Test Content"].waitForExistence(timeout: timeout)
    }
    
    /// Launch app with performance optimizations
    func launchWithOptimizations() {
        launchArguments = ["-UITesting", "-SkipAnimations"]
        launchEnvironment = ["XCUI_TESTING": "1"]
        launch()
    }
    
    /// Find an element by accessibility identifier, trying multiple query types
    /// Uses runtime detection to try different strategies and find what works
    /// - Parameters:
    ///   - identifier: The accessibility identifier to search for
    ///   - primaryType: Primary element type to try first (default: .otherElements)
    ///   - secondaryTypes: Additional element types to try if primary fails
    ///   - timeout: Maximum time to wait for each query type
    /// - Returns: The found element, or nil if not found
    func findElement(byIdentifier identifier: String, 
                    primaryType: XCUIElement.ElementType = .otherElements,
                    secondaryTypes: [XCUIElement.ElementType] = [.staticText, .button, .any],
                    timeout: TimeInterval = 1.0) -> XCUIElement? {
        // Strategy 1: Try primary type first (most common case)
        let primaryElement = descendants(matching: primaryType)[identifier]
        if primaryElement.waitForExistence(timeout: timeout) {
            return primaryElement
        }
        
        // Strategy 2: Try secondary types (adapts to platform differences)
        for elementType in secondaryTypes {
            let element = descendants(matching: elementType)[identifier]
            if element.waitForExistence(timeout: 0.5) {
                return element
            }
        }
        
        // Strategy 3: Try any element as last resort (catches edge cases)
        let anyElement = descendants(matching: .any)[identifier]
        if anyElement.waitForExistence(timeout: 0.3) {
            return anyElement
        }
        
        return nil
    }
    
    /// Select a segment in the segmented picker (handles iOS/macOS differences)
    /// Uses runtime detection to try different strategies and adapt to what works
    /// - Parameter segmentName: Name of the segment to select (e.g., "Text", "Button")
    /// - Returns: true if segment was found and selected, false otherwise
    func selectPickerSegment(_ segmentName: String) -> Bool {
        // Strategy 1: Try buttons directly (works on iOS and some macOS segmented controls)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 0.5) {
            segmentButton.tap()
            return true
        }
        
        // Strategy 2: Try picker first, then buttons (works on macOS pickers)
        let picker = pickers.firstMatch
        if picker.waitForExistence(timeout: 0.5) {
            picker.tap()
            // After tapping picker, segment might be exposed as button
            let segmentAfterPicker = buttons[segmentName]
            if segmentAfterPicker.waitForExistence(timeout: 0.5) {
                segmentAfterPicker.tap()
                return true
            }
        }
        
        // Strategy 3: Try segmented controls directly
        let segmentedControl = segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 0.5) {
            let segmentInControl = segmentedControl.buttons[segmentName]
            if segmentInControl.waitForExistence(timeout: 0.5) {
                segmentInControl.tap()
                return true
            }
        }
        
        return false
    }
}

extension XCUIElement {
    /// Fast wait for existence with shorter default timeout
    func waitForExistenceFast(timeout: TimeInterval = 0.5) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    /// Check if element exists without waiting
    var existsImmediately: Bool {
        return exists
    }
}

// XCUITestPerformance - defined here for RealUITests, or used from XCUITestHelpers.swift for UITests
// If both are included, Swift will use the one from XCUITestHelpers.swift (more complete)
enum XCUITestPerformance {
    static func measure<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    static func log(_ label: String, time: TimeInterval) {
        let milliseconds = Int(time * 1000)
        print("⏱️  [XCUITest Performance] \(label): \(milliseconds)ms")
    }
}

/// XCUITest tests for accessibility identifier generation
/// These tests verify that identifiers are findable using XCUIElement queries,
/// which is how real UI tests would use them
final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
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
            let (isReady, readyTime) = XCUITestPerformance.measure {
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
        guard let element = app.findElement(byIdentifier: controlIdentifier, 
                                           primaryType: .button,
                                           secondaryTypes: [.otherElements]) else {
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
        
        let element: XCUIElement?
        if usePerformanceLogging {
            let (foundElement, queryTime) = XCUITestPerformance.measure {
                app.findElement(byIdentifier: expectedIdentifier,
                               primaryType: .otherElements,
                               secondaryTypes: [.staticText, .any])
            }
            XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
            element = foundElement
        } else {
            element = app.findElement(byIdentifier: expectedIdentifier,
                                     primaryType: .otherElements,
                                     secondaryTypes: [.staticText, .any])
        }
        
        guard let element = element else {
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
        
        let element: XCUIElement?
        if usePerformanceLogging {
            let (foundElement, queryTime) = XCUITestPerformance.measure {
                app.findElement(byIdentifier: expectedIdentifier,
                               primaryType: .otherElements,
                               secondaryTypes: [.button, .any])
            }
            XCUITestPerformance.log("Element query for '\(expectedIdentifier)'", time: queryTime)
            element = foundElement
        } else {
            element = app.findElement(byIdentifier: expectedIdentifier,
                                     primaryType: .otherElements,
                                     secondaryTypes: [.button, .any])
        }
        
        guard let element = element else {
            XCTFail("Accessibility identifier '\(expectedIdentifier)' should be findable by XCUITest. Tried otherElements, buttons, and any elements.")
            return
        }
        
        // Found it! Test passes
    }
}
