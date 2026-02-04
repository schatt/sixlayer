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
    
    /// Static helper to set up app without capturing self
    @MainActor
    private static func setupApp(for instance: AccessibilityUITests, usePerformanceLogging: Bool) {
        // Use local variable to avoid capturing self in closures
        var localApp: XCUIApplication!
        
        if usePerformanceLogging {
            let (_, launchTime) = XCUITestPerformance.measure {
                localApp = XCUIApplication()
                localApp.launchWithOptimizations()
            }
            // Assign to app property - we're on MainActor
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
    
    /// Static helper to clean up app without capturing self
    @MainActor
    private static func cleanupApp(for instance: AccessibilityUITests) {
        instance.app = nil
    }
    
    nonisolated override func setUpWithError() throws {
        continueAfterFailure = false
        
        addDefaultUIInterruptionMonitor()

        // Launch the test app with performance optimizations
        // Use performance logging if enabled (SixLayerFrameworkUITests target sets USE_XCUITEST_PERFORMANCE)
        // Note: setUpWithError() is nonisolated (inherited from XCTestCase), so we need to use MainActor.assumeIsolated
        // to access main actor-isolated properties like 'app'
        let usePerformanceLogging = ProcessInfo.processInfo.environment["USE_XCUITEST_PERFORMANCE"] == "1"
        
        // Use nonisolated(unsafe) since we know we're on MainActor (class is @MainActor and assumeIsolated confirms it)
        nonisolated(unsafe) let instance = self
        MainActor.assumeIsolated {
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
    }
    
    /// CONTROL TEST: Verify that XCUITest can find a standard SwiftUI button with direct .accessibilityIdentifier()
    /// This proves the testing infrastructure works before testing our modifier
    @MainActor
    func testControlDirectAccessibilityIdentifier() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Control Test view
        let controlTestButton = app.findLaunchPageEntry(identifier: "test-view-Control Test")
        XCTAssertTrue(controlTestButton.waitForExistenceFast(timeout: 3.0), "Control Test button should exist")
        controlTestButton.tap()
        
        // Wait for the control button to appear
        let controlButtonByLabel = app.buttons["Control Button"]
        let exists = controlButtonByLabel.waitForExistenceFast(timeout: 3.0)
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
    @MainActor
    func testTextAccessibilityIdentifierGenerated() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Text Test view
        let textTestButton = app.findLaunchPageEntry(identifier: "test-view-Text Test")
        XCTAssertTrue(textTestButton.waitForExistenceFast(timeout: 3.0), "Text Test button should exist")
        textTestButton.tap()
        
        // Wait for the view to appear
        let textView = app.staticTexts["Test Content"]
        XCTAssertTrue(textView.waitForExistenceFast(timeout: 3.0), 
                     "Text view should exist after navigation")
        
        // Find element by accessibility identifier using helper (tries multiple query types)
        // Updated: TextTestView now provides identifierName "testText"
        let expectedIdentifier = "SixLayer.main.ui.testText.View"
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
    @MainActor
    func testButtonAccessibilityIdentifierGenerated() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Button Test view
        let buttonTestButton = app.findLaunchPageEntry(identifier: "test-view-Button Test")
        XCTAssertTrue(buttonTestButton.waitForExistenceFast(timeout: 3.0), "Button Test button should exist")
        buttonTestButton.tap()
        
        // Wait for Button Test view to appear (element we need must exist)
        let expectedIdentifier = "SixLayer.main.ui.testButton.Button"
        let viewReady = app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", expectedIdentifier)).firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(viewReady, "Button Test view should become ready (identifier '\(expectedIdentifier)')")
        
        // Find element by accessibility identifier using helper (tries multiple query types)
        // ButtonTestView uses platformButton(label: "Test Button", id: "testButton")
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
    
    /// TDD Test: Verify that platformPicker automatically applies accessibility identifiers
    /// to both the picker and its segments (Issue #163)
    /// This test verifies the fix for Issue #163 where picker segments weren't accessible
    @MainActor
    func testPlatformPickerAccessibilityIdentifiers() throws {
        // Given: App is launched and ready (from setUp)
        // Navigate to Platform Picker Test view
        let pickerTestButton = app.findLaunchPageEntry(identifier: "test-view-Platform Picker Test")
        XCTAssertTrue(pickerTestButton.waitForExistenceFast(timeout: 3.0), "Platform Picker Test button should exist")
        pickerTestButton.tap()
        
        // Wait for Platform Picker view to appear (picker or segment with identifier)
        let pickerReady = app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS %@", "PlatformPickerTest")).firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(pickerReady, "Platform Picker Test view should become ready")
        
        // Note: On macOS, segmented pickers may not expose a container element,
        // so we test by verifying segments have identifiers instead of the picker container
        
        // When: Query for the picker by its accessibility identifier (if container is accessible)
        // The picker should have an identifier generated by automaticCompliance(named: "PlatformPickerTest")
        // Format: {namespace}.{screenContext}.{viewHierarchyPath}.{componentName}.{elementType}
        // With includeElementTypes=true: SixLayer.main.ui.PlatformPickerTest.View
        let pickerIdentifier = "SixLayer.main.ui.PlatformPickerTest.View"
        #if os(macOS)
        // On macOS, segmented pickers may not expose container, so try to find it but don't fail if not found
        // The important test is that segments have identifiers
        let pickerFound = app.findElement(byIdentifier: pickerIdentifier,
                                         primaryType: .segmentedControl,
                                         secondaryTypes: [.picker, .other, .any]) != nil
        // On macOS, if picker container isn't found, that's okay - segments are what matter
        // We'll verify segments have identifiers below
        #else
        // On iOS, segmented pickers appear as SegmentedControl
        let pickerFound = app.findElement(byIdentifier: pickerIdentifier,
                                         primaryType: .segmentedControl,
                                         secondaryTypes: [.picker, .other, .any]) != nil
        
        guard pickerFound else {
            XCTFail("Platform picker should have accessibility identifier '\(pickerIdentifier)'. This verifies automaticCompliance(named:) is applied to the picker.")
            return
        }
        #endif
        
        // Then: Verify that segments have accessibility identifiers
        // Segments should have identifiers generated by automaticCompliance(identifierName: option)
        // Format: {namespace}.{screenContext}.{viewHierarchyPath}.{componentName}.{elementType}
        // With includeComponentNames=true and includeElementTypes=true:
        // Auto-detection: identifierName is the name of the thing being identified (the option itself)
        // Since options are "Option1", "Option2", "Option3", sanitized to "option1", "option2", "option3":
        // SixLayer.main.ui.{sanitizedOption}.View
        // Note: sanitizeLabelText converts to lowercase and replaces spaces, so "Option1" becomes "option1"
        let segmentOptions = ["Option1", "Option2", "Option3"]
        var allSegmentsFound = true
        var missingSegments: [String] = []
        
        for option in segmentOptions {
            // sanitizeLabelText converts to lowercase, so "Option1" -> "option1"
            let sanitizedOption = option.lowercased()
            // Auto-detection: identifierName is the option itself (the thing being identified)
            let segmentIdentifier = "SixLayer.main.ui.\(sanitizedOption).View"
            let segmentFound = app.findElement(byIdentifier: segmentIdentifier,
                                             primaryType: .button,
                                             secondaryTypes: [.staticText, .any]) != nil
            
            if !segmentFound {
                allSegmentsFound = false
                missingSegments.append(option)
            }
        }
        
        guard allSegmentsFound else {
            XCTFail("Platform picker segments should have accessibility identifiers. Missing segments: \(missingSegments.joined(separator: ", ")). This verifies automaticCompliance(identifierLabel:) is applied to each segment (Issue #163).")
            return
        }
        
        // Verify we can interact with segments by their identifiers
        // This proves the identifiers are actually usable by XCUITest
        // selectPickerSegment tries identifiers first, then falls back to labels
        XCTAssertTrue(app.selectPickerSegment("Option2"),
                      "Should be able to select segment by identifier or label (Issue #163)")
        
        // Found picker and all segments! Test passes
    }
}
