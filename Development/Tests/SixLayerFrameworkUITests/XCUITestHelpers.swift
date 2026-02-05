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

    /// Navigate back to the launch page (e.g. after another test left the app on a subpage). Taps back/nav until "UI Test Views" appears.
    /// - Parameter timeout: Maximum time to wait for launch page (default 5.0)
    /// - Returns: true if launch page is visible (staticTexts["UI Test Views"] exists)
    func navigateBackToLaunch(timeout: TimeInterval = 5.0) -> Bool {
        if staticTexts["UI Test Views"].waitForExistence(timeout: 0.5) { return true }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if buttons["UI Test Views"].waitForExistence(timeout: 0.3) {
                buttons["UI Test Views"].tap()
                return staticTexts["UI Test Views"].waitForExistence(timeout: 2.0)
            }
            if navigationBars.buttons.firstMatch.waitForExistence(timeout: 0.3) {
                navigationBars.buttons.firstMatch.tap()
            } else if buttons["Back"].waitForExistence(timeout: 0.3) {
                buttons["Back"].tap()
            } else {
                break
            }
            if staticTexts["UI Test Views"].waitForExistence(timeout: 1.0) { return true }
        }
        return staticTexts["UI Test Views"].waitForExistence(timeout: 0.5)
    }

    /// Navigate from the launch page to a "Layer N Examples" screen by tapping the given link.
    /// Use for Layer 2, 3, 5, 6 examples (shared pattern: ensure launch → find link → tap → wait for nav bar and content).
    /// - Parameters:
    ///   - linkIdentifier: Accessibility identifier of the launch-page link (e.g. "layer2-examples-link").
    ///   - navigationBarTitle: Title of the destination navigation bar (e.g. "Layer 2 Examples").
    /// - Returns: true if navigation succeeded (nav bar and list content visible).
    func navigateToLayerExamples(linkIdentifier: String, navigationBarTitle: String) -> Bool {
        _ = navigateBackToLaunch(timeout: 5.0)
        guard waitForReady(timeout: 5.0) else { return false }
        let link = findLaunchPageEntry(identifier: linkIdentifier)
        guard link.waitForExistence(timeout: 5.0) else { return false }
        link.tap()
        guard navigationBars[navigationBarTitle].waitForExistence(timeout: 5.0) else { return false }
        return buttons.firstMatch.waitForExistence(timeout: 2.0) || staticTexts.firstMatch.waitForExistence(timeout: 2.0) || cells.firstMatch.waitForExistence(timeout: 1.0)
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
