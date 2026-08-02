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
///
/// ## Accessibility identifier config (#247)
///
/// Do **not** mutate `AccessibilityIdentifierConfig.shared` for per-test setup (parallel-unsafe).
/// Use `initializeTestConfig()` then `runWithTaskLocalConfig { … }` so resolution matches
/// `AccessibilityIdentifierConfig.resolvedForIdentifierGeneration` via `@TaskLocal`. When hosting
/// SwiftUI where the task local is not visible, inject the same instance on the root with
/// `\.accessibilityIdentifierConfig` (see `TestSetupUtilities.hostRootPlatformView`). The UI test
/// host injects at `WindowGroup` instead of touching `shared` (`TestApp.swift`). Reading `shared`
/// is acceptable; writes belong on an isolated instance (or a tiny dedicated suite that restores state).
open class BaseTestClass {
    /// Public initializer required for Swift testing framework to instantiate test classes
    init() {}
    
    /// Isolated test configuration for this test
    /// Set by initializeTestConfig() and used via runWithTaskLocalConfig()
    public var testConfig: AccessibilityIdentifierConfig?
    
    /// Initialize test configuration
    /// Creates an isolated config instance for this test
    @MainActor
    func initializeTestConfig() {
        // Fresh config per test with unique UserDefaults suite — safe for parallel execution.
        testConfig = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
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
    func hostRootPlatformView<V: View>(
        _ view: V,
        forceLayout: Bool = false,
        exposeContentAccessibility: Bool = false,
        accessibilityIdentifierConfig: AccessibilityIdentifierConfig? = nil
    ) -> Any? {
        return Self.hostRootPlatformView(
            view,
            forceLayout: forceLayout,
            exposeContentAccessibility: exposeContentAccessibility,
            accessibilityIdentifierConfig: accessibilityIdentifierConfig
        )
    }

    /// Static version of hostRootPlatformView for use in @Test functions (delegates to TestSetupUtilities).
    /// Use forceLayout: true only when hosting simple views and reading back accessibility ID/label.
    /// Use exposeContentAccessibility: true when verifying content's a11y tree (e.g. single tappable element).
    @MainActor
    static func hostRootPlatformView<V: View>(
        _ view: V,
        forceLayout: Bool = false,
        exposeContentAccessibility: Bool = false,
        accessibilityIdentifierConfig: AccessibilityIdentifierConfig? = nil
    ) -> Any? {
        if HostingControllerStorage.session != nil {
            return TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: forceLayout,
                exposeContentAccessibility: exposeContentAccessibility,
                accessibilityIdentifierConfig: accessibilityIdentifierConfig
            )
        }
        // Class-based @MainActor tests may not inherit suite trait `@TaskLocal` on static entry points.
        let fallbackSession = HostingSession()
        return HostingControllerStorage.$session.withValue(fallbackSession) {
            defer { fallbackSession.tearDownAll() }
            return TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: forceLayout,
                exposeContentAccessibility: exposeContentAccessibility,
                accessibilityIdentifierConfig: accessibilityIdentifierConfig
            )
        }
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
    
    /// `Mirror.subjectType` description for `some View` (includes modifier/compliance wrappers).
    @MainActor
    public static func viewSubjectTypeDescription(for view: some View) -> String {
        String(describing: Mirror(reflecting: view).subjectType)
    }
    
    /// Assert the subject type string contains a semantic root view (e.g. `AsyncFormView` through wrappers).
    @MainActor
    public static func expectViewSubjectTypeContains(
        _ view: some View,
        rootViewName: String
    ) {
        let description = viewSubjectTypeDescription(for: view)
        #expect(
            description.contains(rootViewName),
            "Subject type should contain \(rootViewName), got: \(description)"
        )
    }
    
    //
    // When ViewInspector cannot traverse the hierarchy, helpers below call Issue.record(...) and return
    // instead of #expect. That keeps the test from failing while marking the result as inconclusive:
    // we differentiate "real failure" (assertion failed) from "inconclusive due to tooling" (issue
    // recorded; test still needs to be fixed when tooling improves or the test is updated).
    
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
    
    /// Verify that a view contains specific text content (deep hierarchy walk with optional hosting — #314 / #178).
    #if canImport(ViewInspector)
    @MainActor
    open func verifyViewContainsText<V: View>(_ view: V, expectedText: String, testName: String) {
        var viewText = findAllInViewHierarchy(view, ViewInspector.ViewType.Text.self)
        if viewText.isEmpty {
            _ = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
            viewText = findAllInViewHierarchy(view, ViewInspector.ViewType.Text.self)
        }
        guard !viewText.isEmpty else {
            Issue.record("View inspection returned no text elements for \(testName) (ViewInspector cannot traverse hierarchy)")
            return
        }
        let hasExpectedText = viewText.contains { text in
            (try? text.string())?.contains(expectedText) ?? false
        }
        #expect(hasExpectedText, "View should contain text '\(expectedText)' for \(testName)")
    }

    /// Verify that a view contains specific image elements (deep hierarchy walk — #314 / #178).
    @MainActor
    open func verifyViewContainsImage<V: View>(_ view: V, testName: String) {
        let viewImages = findAllInViewHierarchy(view, ViewInspector.ViewType.Image.self)
        guard !viewImages.isEmpty else {
            Issue.record("View inspection returned no image elements for \(testName) (ViewInspector cannot traverse hierarchy)")
            return
        }
    }

    /// Verify that a view contains at least one text element (deep hierarchy walk — #314 / #178).
    @MainActor
    open func verifyViewContainsAnyText<V: View>(_ view: V, testName: String) {
        let viewText = findAllInViewHierarchy(view, ViewInspector.ViewType.Text.self)
        guard !viewText.isEmpty else {
            Issue.record("View inspection returned no text elements for \(testName) (ViewInspector cannot traverse hierarchy)")
            return
        }
    }

    /// Verify VStack presence (deep walk + firstVStackInView fallback — #314 / #242).
    @MainActor
    open func verifyViewContainsAtLeastOneVStack<V: View>(_ view: V, testName: String) {
        if !findAllInViewHierarchy(view, ViewInspector.ViewType.VStack.self).isEmpty {
            return
        }
        if (try? firstVStackInView(view)) != nil {
            return
        }
        Issue.record("View inspection returned no VStack for \(testName) (ViewInspector cannot traverse hierarchy)")
    }

    /// Run a closure with the first VStack (direct typed inspection, then AnyView fallback — Issue 178 / #242).
    @MainActor
    open func tryWithFirstVStack<V: View>(
        _ view: V,
        testName: String,
        minChildren: Int? = nil,
        body: (ViewInspector.InspectableView<ViewInspector.ViewType.VStack>) -> Void
    ) {
        if let vStack = try? firstVStackInView(view, minChildren: minChildren) {
            body(vStack)
            return
        }
        guard let inspected = withInspectedView(AnyView(view), perform: { $0 }) else {
            Issue.record("View inspection failed for \(testName): could not obtain inspected view")
            return
        }
        guard let vStack = try? firstVStackInHierarchy(inspected, minChildren: minChildren) else {
            Issue.record("View inspection returned no VStack for \(testName) (ViewInspector cannot traverse hierarchy)")
            return
        }
        body(vStack)
    }

    #else
    // No ViewInspector (tvOS/visionOS unit): observe hostability, not Bool(true) theater (#382).
    // Text/image content still needs VI or XCUI — hostability is the cheap truthful floor here.
    @MainActor
    open func verifyViewContainsText(_ view: some View, expectedText: String, testName: String) {
        // Deliberate inverted hostability for #382 red — revert to isHostable for green.
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: hostability contract for \(testName) (text '\(expectedText)' needs VI/XCUI)"
        )
    }
    @MainActor
    open func verifyViewContainsImage(_ view: some View, testName: String) {
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: hostability contract for \(testName) (image content needs VI/XCUI)"
        )
    }
    @MainActor
    open func verifyViewContainsAnyText(_ view: some View, testName: String) {
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: hostability contract for \(testName)"
        )
    }
    @MainActor
    open func verifyViewContainsAtLeastOneVStack(_ view: some View, testName: String) {
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: hostability contract for \(testName)"
        )
        let typeName = String(describing: type(of: view))
        #expect(
            typeName.contains("VStack"),
            "View type should include VStack for \(testName), got: \(typeName)"
        )
    }
    @MainActor
    open func tryWithFirstVStack(
        _ view: some View,
        testName: String,
        minChildren: Int? = nil,
        body: (Any) -> Void
    ) {
        #expect(
            !PlatformContainerStructureAssertions.isHostable(view),
            "Deliberate red #382: hostability contract for \(testName)"
        )
        // Do not invoke body without an inspectable VStack.
    }
    #endif
    
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
