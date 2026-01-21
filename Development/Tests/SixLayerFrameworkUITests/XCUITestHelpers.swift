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
    
    /// Wait for app to be ready before querying elements
    /// This ensures SwiftUI has finished initial render and accessibility tree is built
    /// - Parameter timeout: Maximum time to wait (default: 5.0 seconds)
    /// - Returns: true if app is ready, false if timeout
    func waitForReady(timeout: TimeInterval = 5.0) -> Bool {
        // Wait for a known element that indicates app is ready
        // "Test Content" appears when the initial view is rendered
        return staticTexts["Test Content"].waitForExistence(timeout: timeout)
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
}

// MARK: - Accessibility Identifier Helpers

extension XCUIApplication {
    /// Find an element by accessibility identifier, trying multiple query types
    /// Uses runtime detection to try different strategies and find what works
    /// - Parameters:
    ///   - identifier: The accessibility identifier to search for
    ///   - primaryType: Primary element type to try first (default: .other)
    ///   - secondaryTypes: Additional element types to try if primary fails
    ///   - timeout: Maximum time to wait for each query type
    /// - Returns: The found element, or nil if not found
    func findElement(byIdentifier identifier: String, 
                    primaryType: XCUIElement.ElementType = .other,
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
    
    /// Select a segment in the segmented picker (handles platform differences)
    /// Uses platform-specific strategies based on how segmented pickers are exposed
    /// - Parameter segmentName: Name of the segment to select (e.g., "Text", "Button")
    /// - Returns: true if segment was found and selected, false otherwise
    func selectPickerSegment(_ segmentName: String) -> Bool {
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
        // On macOS, segmented pickers don't expose individual segments as accessible elements
        // We need to use coordinate-based clicking on the segmented control
        // Try SegmentedControl first
        let segmentedControl = segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 1.0) {
            // Try to find segments as buttons first (in case they are accessible)
            let segmentButton = segmentedControl.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
            
            // Segments aren't accessible individually, use coordinate-based clicking
            // Map segment names to their approximate positions (0.0 = left, 1.0 = right)
            // For 3 segments: Text=0.17, Button=0.5, Control=0.83
            let segmentPositions: [String: Double] = [
                "Text": 0.17,    // ~1/6 of the way (first of 3 segments)
                "Button": 0.5,   // Middle (second of 3 segments)
                "Control": 0.83  // ~5/6 of the way (third of 3 segments)
            ]
            
            if let xOffset = segmentPositions[segmentName] {
                let coordinate = segmentedControl.coordinate(withNormalizedOffset: CGVector(dx: xOffset, dy: 0.5))
                coordinate.tap()
                return true
            }
        }
        
        // Fallback: Try Picker (some macOS implementations expose it as a picker)
        let picker = pickers.firstMatch
        if picker.waitForExistence(timeout: 0.5) {
            // Try buttons within the picker
            let segmentButton = picker.buttons[segmentName]
            if segmentButton.waitForExistence(timeout: 0.5) {
                segmentButton.tap()
                return true
            }
            
            // Try menu items (in case it's a dropdown picker)
            let segmentMenuItem = picker.menuItems[segmentName]
            if segmentMenuItem.waitForExistence(timeout: 0.5) {
                segmentMenuItem.tap()
                return true
            }
            
            // Coordinate-based clicking on picker as last resort
            let segmentPositions: [String: Double] = [
                "Text": 0.17,
                "Button": 0.5,
                "Control": 0.83
            ]
            
            if let xOffset = segmentPositions[segmentName] {
                let coordinate = picker.coordinate(withNormalizedOffset: CGVector(dx: xOffset, dy: 0.5))
                coordinate.tap()
                return true
            }
        }
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
