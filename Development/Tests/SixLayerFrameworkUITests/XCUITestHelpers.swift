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
        // Try primary type first
        let primaryElement = descendants(matching: primaryType)[identifier]
        if primaryElement.waitForExistence(timeout: timeout) {
            return primaryElement
        }
        
        // Try secondary types
        for elementType in secondaryTypes {
            let element = descendants(matching: elementType)[identifier]
            if element.waitForExistence(timeout: 0.5) {
                return element
            }
        }
        
        return nil
    }
    
    /// Select a segment in the segmented picker (handles iOS/macOS differences)
    /// - Parameter segmentName: Name of the segment to select (e.g., "Text", "Button")
    /// - Returns: true if segment was found and selected, false otherwise
    func selectPickerSegment(_ segmentName: String) -> Bool {
        #if os(iOS)
        // On iOS, segmented picker exposes segments as buttons
        let segment = buttons[segmentName]
        if segment.waitForExistence(timeout: 1.0) {
            segment.tap()
            return true
        }
        #else
        // On macOS, try picker first, then buttons
        let picker = pickers.firstMatch
        if picker.waitForExistence(timeout: 1.0) {
            picker.tap()
            let segment = buttons[segmentName]
            if segment.waitForExistence(timeout: 1.0) {
                segment.tap()
                return true
            }
        } else {
            // Try buttons directly (segmented control on macOS)
            let segment = buttons[segmentName]
            if segment.waitForExistence(timeout: 1.0) {
                segment.tap()
                return true
            }
        }
        #endif
        return false
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
