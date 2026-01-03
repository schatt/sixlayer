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
@testable import SixLayerFramework

/// Base class for all test classes
/// Provides isolated test configuration and setup utilities
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class BaseTestClass {
    /// Isolated test configuration for this test
    /// Set by initializeTestConfig() and used via runWithTaskLocalConfig()
    public var testConfig: AccessibilityIdentifierConfig?
    
    /// Initialize test configuration
    /// Creates an isolated config instance for this test
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
}
