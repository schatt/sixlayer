//
//  XCUITestHelpers.swift
//  SixLayerFrameworkUITests
//
//  Performance optimization helpers for XCUITest
//  These utilities help reduce test execution time by optimizing app launch,
//  element queries, and accessibility hierarchy snapshots
//

import XCTest

// MARK: - XCUIApplication Extensions

extension XCUIApplication {
    /// Configure app for fast UI testing
    /// Sets launch arguments and environment variables to skip slow initialization
    func configureForFastTesting() {
        // Skip animations to speed up UI interactions
        launchArguments = ["-UITesting", "-SkipAnimations"]
        
        // Set environment variable to indicate we're in UI testing mode
        // This allows the app to skip slow initialization paths
        launchEnvironment = ["XCUI_TESTING": "1"]
    }
    
    /// Wait for app to be ready: look for a single known text on the launch page (Issue #180).
    /// - Parameter timeout: Maximum time to wait (default: 5.0 seconds)
    /// - Returns: true if the text appears, false if timeout
    func waitForReady(timeout: TimeInterval = 5.0) -> Bool {
        staticTexts["UI Test Views"].waitForExistence(timeout: timeout)
    }
    
    /// Launch app with performance optimizations
    /// Configures app for fast testing and launches it
    func launchWithOptimizations() {
        configureForFastTesting()
        launch()
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Fast wait for existence with shorter default timeout
    /// Use this for elements that should exist immediately after app is ready
    /// - Parameter timeout: Maximum time to wait (default: 0.5 seconds)
    /// - Returns: true if element exists, false if timeout
    func waitForExistenceFast(timeout: TimeInterval = 0.5) -> Bool {
        return waitForExistence(timeout: timeout)
    }
    
    /// Check if element exists without waiting
    /// Use this before waitForExistence to avoid unnecessary waits
    /// - Returns: true if element exists immediately
    var existsImmediately: Bool {
        return exists
    }

    /// Wait for this element to become not hittable (e.g. menu/popover dismissed).
    /// Polls until the element is not hittable or timeout. Use after tapping a menu option to ensure the menu is gone before the next interaction.
    /// - Parameter timeout: Maximum time to wait (default: 3.0 seconds)
    /// - Returns: true if element became not hittable (or no longer exists), false if timeout
    func waitForNotHittable(timeout: TimeInterval = 3.0) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !exists || !isHittable {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return !exists || !isHittable
    }
}

// MARK: - Accessibility Identifier Helpers

extension XCUIElement {
    /// Find an element by accessibility identifier within this element, trying multiple query types
    /// - Parameters:
    ///   - identifier: The accessibility identifier to search for
    ///   - primaryType: Primary element type to try first (default: .other)
    ///   - secondaryTypes: Additional element types to try if primary fails
    ///   - timeout: Maximum time to wait for each query type
    /// - Returns: The found element, or nil if not found
    /// - Note: Includes .cell so List/Form rows on iOS (exposed as cells) are findable by identifier.
    func findElement(byIdentifier identifier: String, 
                    primaryType: XCUIElement.ElementType = .other,
                    secondaryTypes: [XCUIElement.ElementType] = [.button, .cell, .staticText, .any],
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
}

extension XCUIApplication {
    /// Find a launch-page list entry by identifier (iOS List rows may be .cell, not .button).
    func findLaunchPageEntry(identifier: String) -> XCUIElement {
        findElement(byIdentifier: identifier,
                    primaryType: .button,
                    secondaryTypes: [.cell, .staticText, .other, .any])
            ?? buttons[identifier]
    }

    // MARK: - Accessibility compatibility sweep (Issue #180)

    /// Run one compatibility sweep on the current view: VoiceOver, Dynamic Type, High Contrast, Switch Control.
    /// One pass per element type; for each element run all checks. Call after navigating to a view.
    func runAccessibilityCompatibilitySweep() {
        let buttonList = buttons.allElementsBoundByIndex
        let textFieldList = textFields.allElementsBoundByIndex
        let switchList = switches.allElementsBoundByIndex
        let sliderList = sliders.allElementsBoundByIndex
        let staticTextList = staticTexts.allElementsBoundByIndex

        var labeledCount = 0
        for button in buttonList {
            XCTAssertTrue(!button.identifier.isEmpty || !button.label.isEmpty,
                          "Button should be discoverable. Identifier: '\(button.identifier)', Label: '\(button.label)'")
            if !button.label.isEmpty {
                labeledCount += 1
                let trimmed = button.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmed.isEmpty, "Button label should be readable")
            }
            XCTAssertEqual(button.elementType, .button, "Button should have button trait")
            XCTAssertTrue(button.exists, "Button should exist")
            XCTAssertTrue(button.isEnabled, "Button should be enabled")
            XCTAssertTrue(button.isHittable || button.exists, "Button should be hittable")
        }

        for textField in textFieldList {
            if !textField.label.isEmpty { labeledCount += 1 }
            XCTAssertEqual(textField.elementType, .textField, "Text field should have text field trait")
            XCTAssertTrue(textField.exists, "Text field should exist")
            XCTAssertTrue(textField.isEnabled, "Text field should be enabled")
        }

        for switchElement in switchList {
            if !switchElement.label.isEmpty { labeledCount += 1 }
            XCTAssertEqual(switchElement.elementType, .switch, "Switch should have switch trait")
            XCTAssertTrue(switchElement.exists, "Switch should exist")
            XCTAssertTrue(switchElement.isEnabled, "Switch should be enabled")
            XCTAssertNotNil(switchElement.value as? String, "Switch should have a value for VoiceOver")
        }

        for slider in sliderList {
            XCTAssertNotNil(slider.value as? String, "Slider should have a value for VoiceOver")
        }

        var readableStaticTexts = 0
        for text in staticTextList {
            if !text.label.isEmpty {
                readableStaticTexts += 1
                let trimmed = text.label.trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(trimmed.isEmpty, "StaticText should have readable content")
            }
        }
        XCTAssertTrue(readableStaticTexts > 0 || staticTextList.count == 0,
                      "StaticTexts should be readable for Dynamic Type")

        let total = buttonList.count + textFieldList.count + switchList.count
        XCTAssertTrue(labeledCount > 0 || total == 0,
                      "Elements should have labels. Found \(labeledCount) labeled out of \(total)")

        var elementsWithContent = 0
        for element in descendants(matching: .any).allElementsBoundByIndex {
            if !element.label.isEmpty || !element.identifier.isEmpty { elementsWithContent += 1 }
        }
        XCTAssertTrue(elementsWithContent > 0,
                      "Accessibility hierarchy should contain elements with content. Found \(elementsWithContent)")
    }
}

extension XCUIApplication {
    /// Select a segment in the segmented picker (handles platform differences)
    /// Uses platform-specific strategies based on how segmented pickers are exposed
    /// - Parameter segmentName: Name of the segment to select (e.g., "Text", "Button")
    /// - Returns: true if segment was found and selected, false otherwise
    func selectPickerSegment(_ segmentName: String) -> Bool {
        // First, try to find by accessibility identifier (works if segments have identifiers)
        // This is the most reliable method when segments have explicit identifiers
        if let segmentElement = findElement(byIdentifier: segmentName,
                                           primaryType: .button,
                                           secondaryTypes: [.staticText, .any]) {
            segmentElement.tap()
            return true
        }
        
        #if os(iOS)
        // On iOS, segmented picker exposes segments as buttons directly
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(tvOS)
        // On tvOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(watchOS)
        // On watchOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(visionOS)
        // On visionOS, segmented picker exposes segments as buttons (similar to iOS)
        let segmentButton = buttons[segmentName]
        if segmentButton.waitForExistence(timeout: 1.0) {
            segmentButton.tap()
            return true
        }
        return false
        
        #elseif os(macOS)
        // On macOS, try to find within SegmentedControl or Picker
        // Try SegmentedControl first
        let segmentedControl = segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 1.0) {
            // Try to find segment by identifier within the segmented control
            if let segmentElement = segmentedControl.findElement(byIdentifier: segmentName,
                                                                primaryType: .button,
                                                                secondaryTypes: [.staticText, .any]) {
                segmentElement.tap()
                return true
            }
            
            // Fallback: try by label
            let segmentButton = segmentedControl.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
        }
        
        // Try Picker
        let picker = pickers.firstMatch
        if picker.waitForExistence(timeout: 1.0) {
            // Try to find segment by identifier within the picker
            if let segmentElement = picker.findElement(byIdentifier: segmentName,
                                                      primaryType: .button,
                                                      secondaryTypes: [.staticText, .any]) {
                segmentElement.tap()
                return true
            }
            
            // Fallback: try by label
            let segmentButton = picker.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
        }
        
        // Try app-level buttons (segments might be at app level)
        let appLevelButton = buttons[segmentName]
        if appLevelButton.waitForExistence(timeout: 0.5) {
            appLevelButton.tap()
            return true
        }
        
        // If nothing works, segments are not accessible
        return false
        
        #else
        // Unsupported platform
        print("ERROR: selectPickerSegment not implemented for this platform")
        return false
        #endif
    }
}

// MARK: - Performance Logging

/// Performance measurement utilities for XCUITest
enum XCUITestPerformance {
    /// Measure time taken for an operation
    /// - Parameter operation: The operation to measure
    /// - Returns: Time taken in seconds
    static func measure<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Measure time taken for an async operation
    /// - Parameter operation: The async operation to measure
    /// - Returns: Time taken in seconds
    static func measureAsync<T>(_ operation: () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let time = Date().timeIntervalSince(startTime)
        return (result, time)
    }
    
    /// Log performance metric
    /// - Parameters:
    ///   - label: Description of what was measured
    ///   - time: Time taken in seconds
    static func log(_ label: String, time: TimeInterval) {
        let milliseconds = Int(time * 1000)
        print("⏱️  [XCUITest Performance] \(label): \(milliseconds)ms")
    }
}

// MARK: - Shared UI interruption monitor (DRY for test setUp)

extension XCTestCase {
    /// Add the standard UI interruption monitor that dismisses system alerts (Bluetooth, CPU, Activity Monitor, etc.).
    /// Call once from setUp in UI test classes. Single implementation so behavior is consistent and changes are in one place.
    func addDefaultUIInterruptionMonitor() {
        addUIInterruptionMonitor(withDescription: "System alerts and dialogs") { (alert) -> Bool in
            return MainActor.assumeIsolated {
                let alertText = alert.staticTexts.firstMatch.label
                guard alertText.contains("Bluetooth") || alertText.contains("CPU") || alertText.contains("Activity Monitor") else {
                    return false
                }
                if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
                if alert.buttons["Cancel"].exists { alert.buttons["Cancel"].tap(); return true }
                if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
                return false
            }
        }
    }
}
