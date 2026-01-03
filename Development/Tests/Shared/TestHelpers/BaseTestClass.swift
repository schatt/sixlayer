//
//  BaseTestClass.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Base class for all test classes that provides isolated test configuration
//  and setup utilities to ensure parallel test execution safety
//
//  FEATURES:
//  - Isolated test configuration per test via @TaskLocal
//  - Automatic setup and cleanup
//  - Helper methods for test isolation
//

import Testing
import SwiftUI
@testable import SixLayerFramework

/// Base class for all test classes
/// Provides isolated test configuration and setup utilities
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class BaseTestClass {
    /// Public initializer required for Swift testing framework to instantiate test classes
    public init() {
        // BaseTestClass doesn't require any initialization
        // Subclasses can override if needed
    }
    
    /// Isolated test configuration for this test
    /// Set by initializeTestConfig() and used via runWithTaskLocalConfig()
    public var testConfig: AccessibilityIdentifierConfig?
    
    /// Initialize test configuration
    /// Creates an isolated config instance for this test
    @MainActor
    public func initializeTestConfig() {
        testConfig = AccessibilityIdentifierConfig()
        testConfig?.resetToDefaults()
        testConfig?.enableAutoIDs = true
        testConfig?.namespace = "SixLayer"
        testConfig?.mode = .automatic
        testConfig?.enableDebugLogging = false
    }
    
    /// Run code with task-local config isolation
    /// Ensures each test runs with its own isolated configuration
    public func runWithTaskLocalConfig<T>(_ body: () throws -> T) rethrows -> T {
        guard let config = testConfig else {
            // If testConfig is nil, initialize it
            initializeTestConfig()
            guard let config = testConfig else {
                fatalError("Failed to initialize testConfig")
            }
            return try AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
                try body()
            }
        }
        return try AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            try body()
        }
    }
    
    /// Run async code with task-local config isolation
    /// Ensures each test runs with its own isolated configuration
    public func runWithTaskLocalConfig<T>(_ body: () async throws -> T) async rethrows -> T {
        guard let config = testConfig else {
            // If testConfig is nil, initialize it
            initializeTestConfig()
            guard let config = testConfig else {
                fatalError("Failed to initialize testConfig")
            }
            return try await AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
                try await body()
            }
        }
        return try await AccessibilityIdentifierConfig.$taskLocalConfig.withValue(config) {
            try await body()
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Set capabilities for a specific platform (delegates to TestSetupUtilities)
    public func setCapabilitiesForPlatform(_ platform: SixLayerPlatform) {
        TestSetupUtilities.setCapabilitiesForPlatform(platform)
    }
    
    /// Create test hints (delegates to TestSetupUtilities)
    public func createTestHints(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard
    ) -> PresentationHints {
        return TestSetupUtilities.createTestHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context
        )
    }
    
    /// Host a SwiftUI view and return the platform root view (delegates to TestSetupUtilities)
    @MainActor
    public func hostRootPlatformView<V: View>(_ view: V) -> Any? {
        return TestSetupUtilities.hostRootPlatformView(view)
    }
    
    // MARK: - Test Environment Setup
    
    /// Setup test environment
    /// Clears any existing test overrides to ensure clean test state
    @MainActor
    public func setupTestEnvironment() {
        TestSetupUtilities.setupTestEnvironment()
    }
    
    /// Cleanup test environment
    /// Clears all test overrides after test execution
    @MainActor
    public func cleanupTestEnvironment() {
        TestSetupUtilities.cleanupTestEnvironment()
    }
    
    // MARK: - View Verification Helpers
    
    /// Verify that a view is created and contains expected content
    /// Delegates to TestPatterns for implementation
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewGeneration(_ view: some View, testName: String) {
        TestPatterns.verifyViewGeneration(view, testName: testName)
    }
    
    /// Verify that a view contains specific text content
    /// Delegates to TestPatterns for implementation
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        TestPatterns.verifyViewContainsText(view, expectedText: expectedText, testName: testName)
    }
    
    /// Verify that a view contains specific image elements
    /// Delegates to TestPatterns for implementation
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewContainsImage(_ view: some View, testName: String) {
        TestPatterns.verifyViewContainsImage(view, testName: testName)
    }
    
    // MARK: - Common Test Data Creation
    
    /// Creates a default layout decision for testing
    /// Override this method in subclasses to provide specific layout decisions
    open func createLayoutDecision() -> IntelligentCardLayoutDecision {
        return IntelligentCardLayoutDecision(
            columns: 2,
            spacing: 16,
            cardWidth: 200,
            cardHeight: 150,
            padding: 16
        )
    }
    
    // MARK: - Common Context Creation
    
    /// Creates a PhotoContext for testing
    /// Each test should call this to create fresh context (test isolation)
    open func createPhotoContext(
        screenSize: CGSize = CGSize(width: 375, height: 667),
        availableSpace: CGSize? = nil,
        userPreferences: PhotoPreferences = PhotoPreferences(),
        deviceCapabilities: PhotoDeviceCapabilities = PhotoDeviceCapabilities()
    ) -> PhotoContext {
        return PhotoContext(
            screenSize: screenSize,
            availableSpace: availableSpace ?? screenSize,
            userPreferences: userPreferences,
            deviceCapabilities: deviceCapabilities
        )
    }
}
