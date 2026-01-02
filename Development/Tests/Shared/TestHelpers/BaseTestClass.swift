import Testing
import SwiftUI
@testable import SixLayerFramework

/// Base class for all tests following DRY principle
/// Provides common setup and teardown functionality for all test classes
/// NOTE: Not marked @MainActor to allow test parallelization. Individual test functions
/// that need UI access should be marked @MainActor.
open class BaseTestClass {
    
    // MARK: - Test Config (Isolated Instance)
    
    /// Isolated config instance for this test (per-test isolation via @TaskLocal)
    /// Automatically set as task-local in setupTestEnvironment() so framework code picks it up automatically
    /// Each test runs in its own task, so @TaskLocal provides isolation even when all tasks run on MainActor
    /// Tests can use `runWithTaskLocalConfig()` to wrap test execution for automatic isolation
    public var testConfig: AccessibilityIdentifierConfig!
    
    // MARK: - Test Setup
    
    // NOTE: Hints preloading is handled by DataHintsRegistry.preloadAllHintsSync
    // which has its own synchronization. We don't need separate flags/locks here
    // to avoid deadlock scenarios.
    
    public init() {
        // BaseTestClass handles all setup automatically
        // NOTE: Subclasses should NOT override init() - use helper methods to create test data instead
        // (Cannot be final because class is open, but subclasses should not override)
        
        // NOTE: Hints are loaded lazily when first accessed by AsyncFormView
        // This avoids memory issues from preloading in every test's init()
        // The DataHintsRegistry cache ensures hints are only loaded once from disk
        
        setupTestEnvironment()
    }
    
    /// Preload hints once at test suite startup (called from first test's init)
    /// This ensures hints are loaded once from disk, not reloaded by every test
    /// After preload, cache is read-only, so no synchronization needed for reads
    /// NOTE: This delegates to DataHintsRegistry.preloadAllHintsSync which has its own synchronization
    /// We don't need our own lock here - DataHintsRegistry handles it
    private static func preloadHintsOnce() {
        // Preload hints for common models used in tests
        // Add model names here as they're identified in test usage
        let commonModels: [String] = [
            "User",
            "UserWithSections"
            // Add more model names as needed
        ]
        
        // Delegate to DataHintsRegistry which has its own synchronization
        // This avoids deadlock by using a single lock (in DataHintsRegistry)
        DataHintsRegistry.preloadAllHintsSync(modelNames: commonModels)
    }
    
    /// Preload hints once at test suite startup (MainActor version)
    /// This can be called from @MainActor test classes that need to ensure hints are loaded
    /// This ensures hints are loaded once from disk, not reloaded by every test
    /// After preload, cache is read-only, so no synchronization needed for reads
    @MainActor
    public static func preloadHintsOnceMainActor() {
        // Delegate to DataHintsRegistry which has its own synchronization
        // This avoids deadlock by using a single lock (in DataHintsRegistry)
        let commonModels: [String] = [
            "User",
            "UserWithSections"
            // Add more model names as needed
        ]
        
        DataHintsRegistry.preloadAllHintsSync(modelNames: commonModels)
    }
    
    open func setupTestEnvironment() {
        // NOTE: No need to clear capability overrides - each test runs in its own thread
        // Thread-local storage (Thread.current.threadDictionary) is already empty per thread
        
        // CRITICAL: Config initialization is deferred until test execution
        // Tests that need config should be marked @MainActor and will initialize it lazily
        // This allows non-UI tests to run in parallel without MainActor contention
        // Framework code automatically uses task-local config via AccessibilityIdentifierConfig.currentTaskLocalConfig
        // Config will be created on MainActor when first accessed by a test
    }
    
    /// Initialize test config on MainActor (call from @MainActor test functions)
    @MainActor
    open func initializeTestConfig() {
        if testConfig == nil {
        testConfig = AccessibilityIdentifierConfig()
        guard let config = testConfig else {
            Issue.record("testConfig is nil")
            return
        }

        config.enableAutoIDs = true
        config.namespace = "SixLayer"
        config.globalPrefix = ""  // Explicitly empty - tests don't set prefix unless testing it
        config.mode = .automatic
        config.enableDebugLogging = false
        }
        
        // Task-local config will be set via runWithTaskLocalConfig() when tests wrap their execution
        // Framework code checks: taskLocalConfig ?? injectedConfig ?? shared
        // This ensures parallel tests get isolated configs automatically
    }
    
    open func cleanupTestEnvironment() {
        // Task-local config is automatically cleared when test task completes
        // No explicit cleanup needed - @TaskLocal is scoped to the task
    }
    
    /// Run a test function with task-local config automatically set
    /// This ensures framework code automatically picks up the test's isolated config
    /// Tests should wrap their test body with this for automatic isolation
    /// NOTE: If the operation needs MainActor, mark the calling test function with @MainActor
    /// This will automatically initialize testConfig if needed (on MainActor when called)
    public func runWithTaskLocalConfig<T>(_ operation: () async throws -> T) async rethrows -> T {
        // Initialize config if needed (lazy initialization - will be on MainActor if test is @MainActor)
        if testConfig == nil {
            let config = await MainActor.run {
                let tempConfig = AccessibilityIdentifierConfig()
                tempConfig.enableAutoIDs = true
                tempConfig.namespace = "SixLayer"
                tempConfig.globalPrefix = ""
                tempConfig.mode = .automatic
                tempConfig.enableDebugLogging = false
                return tempConfig
            }
            testConfig = config
        }
        return try await AccessibilityIdentifierConfig.$taskLocalConfig.withValue(testConfig) {
            try await operation()
        }
    }
    
    /// Synchronous version for non-async tests
    /// NOTE: Tests that need config should be marked @MainActor and call initializeTestConfig() first
    /// This version assumes config is already initialized (tests should call initializeTestConfig() explicitly)
    @MainActor
    public func runWithTaskLocalConfig<T>(_ operation: () throws -> T) rethrows -> T {
        // Config should already be initialized by test calling initializeTestConfig()
        // If not, initialize it now (we're on MainActor)
        if testConfig == nil {
            initializeTestConfig()
        }
        return try AccessibilityIdentifierConfig.$taskLocalConfig.withValue(testConfig) {
            try operation()
        }
    }
    
    // MARK: - Config Injection Helper (REMOVED)
    
    /// REMOVED: Use `runWithTaskLocalConfig` instead
    /// Task-local config is automatically available to framework code
    /// Tests should wrap their test body with `runWithTaskLocalConfig { ... }` 
    /// instead of wrapping individual views with `withTestConfig`
    /// 
    /// This method was removed because it was problematic - it wrapped views unnecessarily
    /// and caused issues with accessibility identifier detection.
    /// 
    /// Migration: Replace `let view = withTestConfig(myView)` with:
    /// ```
    /// runWithTaskLocalConfig {
    ///     let view = myView
    ///     // ... rest of test
    /// }
    /// ```
    /*
    @MainActor
    public func withTestConfig<V: SwiftUI.View>(_ view: V) -> some View {
        // Just return the view - task-local config is automatic
        // Wrapping was unnecessary and caused issues with accessibility identifiers
        return view
    }
    */
    
    // MARK: - Common Test Data Creation
    
    /// Creates generic sample data for testing
    /// Override this method in subclasses to provide specific test data
    open func createSampleData() -> [Any] {
        return [
            "Sample Item 1",
            "Sample Item 2", 
            "Sample Item 3"
        ]
    }
    
    /// Creates test hints for presentation components
    /// Each test should call this to create fresh hints (test isolation)
    /// Parameters allow customization while maintaining sensible defaults
    open func createTestHints(
        dataType: DataTypeHint = .generic,
        presentationPreference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        context: PresentationContext = .dashboard,
        customPreferences: [String: String] = [:]
    ) -> PresentationHints {
        return PresentationHints(
            dataType: dataType,
            presentationPreference: presentationPreference,
            complexity: complexity,
            context: context,
            customPreferences: customPreferences
        )
    }
    
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
    
    // MARK: - Common Test Data Item Creation
    
    /// Creates a test data item for testing using TestPatterns
    /// Each test should call this to create fresh data (test isolation)
    /// NOTE: This is @MainActor because TestPatterns is @MainActor
    @MainActor
    open func createTestDataItem(
        title: String = "Item 1",
        subtitle: String? = "Subtitle 1",
        description: String? = "Description 1",
        value: Int = 42,
        isActive: Bool = true
    ) -> TestPatterns.TestDataItem {
        return TestPatterns.createTestItem(
            title: title,
            subtitle: subtitle,
            description: description,
            value: value,
            isActive: isActive
        )
    }
    
    /// Creates multiple test data items
    /// Each test should call this to create fresh data (test isolation)
    /// NOTE: This is @MainActor because it calls createTestDataItem which is @MainActor
    @MainActor
    open func createTestDataItems() -> [TestPatterns.TestDataItem] {
        return [
            createTestDataItem(title: "Item 1", subtitle: "Subtitle 1", description: "Description 1", value: 42, isActive: true),
            createTestDataItem(title: "Item 2", subtitle: nil, description: "Description 2", value: 84, isActive: false),
            createTestDataItem(title: "Item 3", subtitle: "Subtitle 3", description: nil, value: 126, isActive: true)
        ]
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
    
    /// Creates an OCRContext for testing
    /// Each test should call this to create fresh context (test isolation)
    open func createOCRContext() -> OCRContext {
        return OCRContext()
    }
    
    /// Creates PresentationHints for testing
    /// Each test should call this to create fresh hints (test isolation)
    open func createPresentationHints() -> PresentationHints {
        return PresentationHints()
    }
    
}

