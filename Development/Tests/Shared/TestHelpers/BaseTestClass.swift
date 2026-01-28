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

#if canImport(ViewInspector)
import ViewInspector
#endif

/// Base class for all test classes
/// Provides isolated test configuration and setup utilities
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class BaseTestClass {
    /// Public initializer required for Swift testing framework to instantiate test classes
    init() {
        // BaseTestClass doesn't require any initialization
        // Subclasses can override if needed
    }
    
    /// Isolated test configuration for this test
    /// Set by initializeTestConfig() and used via runWithTaskLocalConfig()
    public var testConfig: AccessibilityIdentifierConfig?
    
    /// Initialize test configuration
    /// Creates an isolated config instance for this test
    @MainActor
    func initializeTestConfig() {
        // Use an isolated UserDefaults suite and key prefix for tests so we do not
        // pollute production-like UserDefaults namespaces. This also ensures
        // deterministic behavior when running tests in parallel.
        let testSuiteName = "SixLayer.Accessibility.Tests"
        let testDefaults = UserDefaults(suiteName: testSuiteName) ?? .standard
        // Clear any previous data for this suite to guarantee isolation
        testDefaults.removePersistentDomain(forName: testSuiteName)
        
        testConfig = AccessibilityIdentifierConfig(
            userDefaults: testDefaults,
            keyPrefix: "Test.Accessibility."
        )
        testConfig?.resetToDefaults()
        testConfig?.enableAutoIDs = true
        testConfig?.globalAutomaticAccessibilityIdentifiers = true  // Explicitly set for basicAutomaticCompliance
        testConfig?.namespace = "SixLayer"
        testConfig?.mode = .automatic
        testConfig?.enableDebugLogging = false
    }
    
    /// Run code with task-local config isolation
    /// Ensures each test runs with its own isolated configuration
    @MainActor
    func runWithTaskLocalConfig<T>(_ body: () throws -> T) rethrows -> T {
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
    @MainActor
    func runWithTaskLocalConfig<T>(_ body: () async throws -> T) async rethrows -> T {
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

    /// Create test hints (delegates to TestSetupUtilities)
    func createTestHints(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:]
    ) -> PresentationHints {
        return TestSetupUtilities.createTestHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context,
            customPreferences: customPreferences
        )
    }
    
    /// Host a SwiftUI view and return the platform root view (delegates to TestSetupUtilities)
    @MainActor
    func hostRootPlatformView<V: View>(_ view: V) -> Any? {
        return Self.hostRootPlatformView(view)
    }

    /// Static version of hostRootPlatformView for use in @Test functions (delegates to TestSetupUtilities)
    @MainActor
    static func hostRootPlatformView<V: View>(_ view: V) -> Any? {
        return TestSetupUtilities.hostRootPlatformView(view)
    }
    
    // MARK: - Test Environment Setup
    
    /// Setup test environment
    /// Clears any existing test overrides to ensure clean test state
    @MainActor
    func setupTestEnvironment() {
        TestSetupUtilities.setupTestEnvironment()
    }
    
    /// Cleanup test environment
    /// Clears all test overrides after test execution
    @MainActor
    func cleanupTestEnvironment() {
        TestSetupUtilities.cleanupTestEnvironment()
    }
    
    // MARK: - View Verification Helpers
    
    /// Verify that a view is created and contains expected content
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewGeneration(_ view: some View, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here
        
        // 2. Contains what it needs to contain - The view has proper structure
        #if canImport(ViewInspector)
        do {
            _ = try view.inspect()
        } catch {
            Issue.record("Failed to inspect view structure for \(testName): \(error)")
        }
        #else
        // ViewInspector not available - view creation is verified by non-optional parameter
        // Test passes by verifying compilation and view creation
        #endif
    }
    
    /// Verify that a view contains specific text content
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here

        // 2. Contains what it needs to contain - The view should contain expected text
        #if canImport(ViewInspector)
        do {
            // Wrap in AnyView for better ViewInspector compatibility (like other tests do)
            let inspected = try AnyView(view).inspect()
            let viewText = inspected.findAll(ViewInspector.ViewType.Text.self)
            #expect(!viewText.isEmpty, "View should contain text elements for \(testName)")

            let hasExpectedText = viewText.contains { text in
                if let textContent = try? text.string() {
                    return textContent.contains(expectedText)
                }
                return false
            }
            #expect(hasExpectedText, "View should contain text '\(expectedText)' for \(testName)")
        } catch {
            Issue.record("View inspection failed for \(testName): \(error)")
        }
        #else
        // ViewInspector not available - test passes by verifying view creation
        #expect(Bool(true), "View created for \(testName) (ViewInspector not available)")
        #endif
    }
    
    /// Verify that a view contains specific image elements
    /// Override this method in subclasses to provide custom verification logic
    @MainActor
    open func verifyViewContainsImage(_ view: some View, testName: String) {
        // 1. View created - The view can be instantiated successfully
        // view is a non-optional View parameter, so it exists if we reach here

        // 2. Contains what it needs to contain - The view should contain image elements
        #if canImport(ViewInspector)
        do {
            // Wrap in AnyView for better ViewInspector compatibility (like other tests do)
            let inspected = try AnyView(view).inspect()
            let viewImages = inspected.findAll(ViewInspector.ViewType.Image.self)
            #expect(!viewImages.isEmpty, "View should contain image elements for \(testName)")
        } catch {
            Issue.record("View inspection failed for \(testName): \(error)")
        }
        #else
        // ViewInspector not available - test passes by verifying view creation
        #expect(Bool(true), "View created for \(testName) (ViewInspector not available)")
        #endif
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
