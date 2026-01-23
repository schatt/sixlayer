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
    /// BUSINESS PURPOSE: Verify basic compliance applies identifiers that UI tests can find
    /// TESTING SCOPE: General View extension method identifier detection
    /// METHODOLOGY: Use XCUITest to find element by identifier (moved from ViewInspector tests)
    @MainActor
    func testBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element by basic compliance identifier using XCUITest
        // Then: Should be findable
        // Identifier format: SixLayer.main.ui.testView.View (with enableUITestIntegration=true and includeElementTypes=true)
        let testIdentifier = "SixLayer.main.ui.testView.View"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .staticText,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Basic compliance identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
    
    /// Test that .basicAutomaticCompliance() label is readable via XCUITest
    /// BUSINESS PURPOSE: Verify basic compliance applies labels that VoiceOver can read
    /// TESTING SCOPE: General View extension method label detection
    /// METHODOLOGY: Use XCUITest to find element by label (moved from ViewInspector tests)
    @MainActor
    func testBasicAutomaticCompliance_LabelIsReadable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element by basic compliance label using XCUITest
        // Then: Should be readable
        // Label should be formatted with punctuation: "Test label" -> "Test label."
        let testLabel = "Test label."
        
        let element = app.staticTexts[testLabel]
        guard element.existsImmediately || element.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Basic compliance label '\(testLabel)' should be readable via XCUITest")
            return
        }
    }
    
    /// Test that Text with .basicAutomaticCompliance() identifier is findable
    /// BUSINESS PURPOSE: Verify Text.basicAutomaticCompliance() applies identifiers
    /// TESTING SCOPE: Text extension method identifier detection
    /// METHODOLOGY: Use XCUITest to find Text element by identifier (moved from ViewInspector tests)
    @MainActor
    func testTextBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for Text element by basic compliance identifier using XCUITest
        // Then: Should be findable
        // Identifier format: SixLayer.main.ui.helloText.View (with enableUITestIntegration=true and includeElementTypes=true)
        let testIdentifier = "SixLayer.main.ui.helloText.View"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .staticText,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Text.basicAutomaticCompliance() identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
    
    /// Test that Text with .basicAutomaticCompliance() label is readable
    /// BUSINESS PURPOSE: Verify Text.basicAutomaticCompliance() applies labels
    /// TESTING SCOPE: Text extension method label detection
    /// METHODOLOGY: Use XCUITest to find Text element by label (moved from ViewInspector tests)
    @MainActor
    func testTextBasicAutomaticCompliance_LabelIsReadable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for Text element by basic compliance label using XCUITest
        // Then: Should be readable
        // Note: This test requires the test view to include a Text with label
        // Label should be formatted with punctuation: "Hello text" -> "Hello text."
        let testLabel = "Hello text."
        
        let element = app.staticTexts[testLabel]
        guard element.existsImmediately || element.waitForExistenceFast(timeout: 3.0) else {
            XCTFail("Text.basicAutomaticCompliance() label '\(testLabel)' should be readable via XCUITest")
            return
        }
    }
    
    /// Test that identifier sanitization works (spaces and uppercase)
    /// BUSINESS PURPOSE: Verify identifier sanitization removes spaces and lowercases text
    /// TESTING SCOPE: Identifier sanitization logic verification
    /// METHODOLOGY: Use XCUITest to find identifier with sanitized label (moved from ViewInspector tests)
    @MainActor
    func testIdentifierSanitization_SpacesAndUppercase() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element with sanitized identifier
        // Then: Should be findable with sanitized label
        // Label "Save File" should be sanitized to "save-file" in identifier
        // Identifier format: SixLayer.main.ui.TestButton.save-file.View (with enableUITestIntegration=true and includeElementTypes=true)
        let testIdentifier = "SixLayer.main.ui.TestButton.save-file.View"
        
        // Try to find with sanitized identifier (may also be just "save" if sanitization is different)
        let found = app.findElement(byIdentifier: testIdentifier,
                                   primaryType: .staticText,
                                   secondaryTypes: [.other]) != nil ||
                   app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save.View",
                                  primaryType: .staticText,
                                  secondaryTypes: [.other]) != nil
        
        guard found else {
            XCTFail("Identifier with sanitized label should be findable via XCUITest. Expected '\(testIdentifier)' or similar")
            return
        }
    }
    
    /// Test that identifier sanitization removes special characters
    /// BUSINESS PURPOSE: Verify identifier sanitization removes special characters
    /// TESTING SCOPE: Identifier sanitization logic verification
    /// METHODOLOGY: Use XCUITest to find identifier with sanitized special characters (moved from ViewInspector tests)
    @MainActor
    func testIdentifierSanitization_SpecialCharacters() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for element with sanitized identifier (special characters removed)
        // Then: Should be findable without special characters
        // Label "Save & Load!" should have "&" and "!" removed
        // Identifier format: SixLayer.main.ui.TestButton.save-load.View (with enableUITestIntegration=true and includeElementTypes=true)
        let testIdentifier = "SixLayer.main.ui.TestButton.save-load.View"
        
        guard app.findElement(byIdentifier: testIdentifier,
                             primaryType: .staticText,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Identifier with sanitized special characters should be findable via XCUITest. Expected '\(testIdentifier)' or similar")
            return
        }
        
        // Verify special characters are NOT in the identifier
        // Try to find with special characters - should NOT exist
        let withAmpersand = app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save-&-load.View",
                                           primaryType: .staticText,
                                           secondaryTypes: [.other])
        XCTAssertNil(withAmpersand, "Identifier should not contain '&' character")
        
        let withExclamation = app.findElement(byIdentifier: "SixLayer.main.ui.TestButton.save-load!.View",
                                            primaryType: .staticText,
                                            secondaryTypes: [.other])
        XCTAssertNil(withExclamation, "Identifier should not contain '!' character")
    }
    
    /// Test that Image with .basicAutomaticCompliance() identifier is findable
    /// BUSINESS PURPOSE: Verify Image.basicAutomaticCompliance() applies identifiers
    /// TESTING SCOPE: Image extension method identifier detection
    /// METHODOLOGY: Use XCUITest to find Image element by identifier
    @MainActor
    func testImageBasicAutomaticCompliance_IdentifierIsFindable() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Basic Compliance Test view
        let basicComplianceButton = app.buttons["test-view-Basic Compliance Test"]
        XCTAssertTrue(basicComplianceButton.waitForExistenceFast(timeout: 3.0), "Basic Compliance Test button should exist")
        basicComplianceButton.tap()
        
        // When: Query for Image element by basic compliance identifier using XCUITest
        // Then: Should be findable
        // Identifier format: SixLayer.main.ui.starImage.Image (with enableUITestIntegration=true and includeElementTypes=true)
        let testIdentifier = "SixLayer.main.ui.starImage.Image"
        
        guard app.findElement(byIdentifier: testIdentifier, 
                             primaryType: .image,
                             secondaryTypes: [.other]) != nil else {
            XCTFail("Image.basicAutomaticCompliance() identifier '\(testIdentifier)' should be findable via XCUITest")
            return
        }
    }
}
