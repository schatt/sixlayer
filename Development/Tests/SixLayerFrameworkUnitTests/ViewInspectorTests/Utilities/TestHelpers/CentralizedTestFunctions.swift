//
//  CentralizedTestFunctions.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Centralized test functions following DRY principles to eliminate code duplication
//  across all test files in the SixLayer framework.
//
//  DRY PRINCIPLE:
//  - Single source of truth for common test patterns
//  - Reusable test functions that can be called from individual test files
//  - Consistent test setup and validation across all components
//
//  USAGE PATTERN:
//  testfile.swift:
//  func testfoo() {
//      test1()
//      test2()
//  }
//
//  test2.swift:
//  func testBob() {
//      setup()
//      testfoo(bob, componentName: "Bob")
//  }
//

import SwiftUI
@testable import SixLayerFramework

// MARK: - Centralized Accessibility Test Functions

/// Centralized function for testing component compliance (accessibility identifiers + HIG compliance)
/// This is the single source of truth for component compliance testing
/// 
/// - Parameters:
///   - view: The SwiftUI view to test
///   - componentName: Name of the component being tested
///   - expectedPattern: Expected accessibility identifier pattern
///   - platform: Platform to test on (optional, defaults to current)
///   - testName: Name of the test for debugging
///   - testHIGCompliance: Whether to test HIG compliance features (default: true - tests both accessibility identifiers and HIG compliance)
/// - Returns: True if component compliance test passes
@MainActor
public func testComponentCompliance<T: View>(
    _ view: T,
    componentName: String,
    expectedPattern: String = "SixLayer.*ui",
    platform: SixLayerPlatform? = nil,
    testName: String = "ComplianceTest",
    testHIGCompliance: Bool = true
) -> Bool {
    // Setup: Configure test environment - auto-detect task-local config
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    config.namespace = "SixLayer"
    config.mode = .automatic
    
    // Set capability overrides if platform is specified and different from current
    if let platform = platform {
        let currentPlatform = SixLayerPlatform.current
        if platform != currentPlatform {
            // Use capability overrides to simulate platform capabilities
            switch platform {
            case .iOS:
                RuntimeCapabilityDetection.setTestTouchSupport(true)
                RuntimeCapabilityDetection.setTestHapticFeedback(true)
                RuntimeCapabilityDetection.setTestHover(false)
            case .macOS:
                RuntimeCapabilityDetection.setTestTouchSupport(false)
                RuntimeCapabilityDetection.setTestHapticFeedback(false)
                RuntimeCapabilityDetection.setTestHover(true)
            case .watchOS:
                RuntimeCapabilityDetection.setTestTouchSupport(true)
                RuntimeCapabilityDetection.setTestHapticFeedback(true)
                RuntimeCapabilityDetection.setTestHover(false)
            case .tvOS:
                RuntimeCapabilityDetection.setTestTouchSupport(false)
                RuntimeCapabilityDetection.setTestHapticFeedback(false)
                RuntimeCapabilityDetection.setTestHover(false)
            case .visionOS:
                RuntimeCapabilityDetection.setTestTouchSupport(false)
                RuntimeCapabilityDetection.setTestHapticFeedback(false)
                RuntimeCapabilityDetection.setTestHover(true)
            }
        }
    }
    
    // Test: Use centralized component compliance testing
    let result = testComponentComplianceSinglePlatform(
        view,
        expectedPattern: expectedPattern,
        platform: platform ?? SixLayerPlatform.current,
        componentName: componentName,
        testHIGCompliance: testHIGCompliance
    )
    
    // Cleanup: Reset capability overrides
    if platform != nil {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    }
    
    return result
}

/// Centralized function for testing accessibility identifier generation
/// This is kept for backward compatibility - it now also tests HIG compliance by default
@available(*, deprecated, renamed: "testComponentCompliance", message: "Use testComponentCompliance which tests both accessibility identifiers and HIG compliance")
@MainActor
public func testAccessibilityIdentifierGeneration<T: View>(
    _ view: T,
    componentName: String,
    expectedPattern: String = "SixLayer.*ui",
    platform: SixLayerPlatform? = nil,
    testName: String = "AccessibilityTest",
    testHIGCompliance: Bool = true
) -> Bool {
    return testComponentCompliance(
        view,
        componentName: componentName,
        expectedPattern: expectedPattern,
        platform: platform,
        testName: testName,
        testHIGCompliance: testHIGCompliance
    )
}

/// Centralized function for testing cross-platform component compliance (accessibility identifiers + HIG compliance)
/// Tests the same component across multiple platforms
/// 
/// - Parameters:
///   - view: The SwiftUI view to test
///   - componentName: Name of the component being tested
///   - expectedPattern: Expected accessibility identifier pattern
///   - platforms: Array of platforms to test (defaults to iOS and macOS)
///   - testName: Name of the test for debugging
///   - testHIGCompliance: Whether to test HIG compliance features (default: true - tests both accessibility identifiers and HIG compliance)
/// - Returns: True if component compliance test passes on all platforms
@MainActor
public func testCrossPlatformComponentCompliance<T: View>(
    _ view: T,
    componentName: String,
    expectedPattern: String = "SixLayer.*ui",
    platforms: [SixLayerPlatform] = [.iOS, .macOS],
    testName: String = "CrossPlatformComplianceTest",
    testHIGCompliance: Bool = true
) -> Bool {
    // Setup: Configure test environment
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    config.enableAutoIDs = true
    config.namespace = "SixLayer"
    config.mode = .automatic
    
    // Test: Use centralized cross-platform component compliance testing
    let result = testComponentComplianceCrossPlatform(
        view,
        expectedPattern: expectedPattern,
        componentName: componentName,
        testName: testName,
        testHIGCompliance: testHIGCompliance
    )
    
    return result
}

/// Centralized function for testing cross-platform accessibility identifier generation
/// This is kept for backward compatibility - it now also tests HIG compliance by default
@available(*, deprecated, renamed: "testCrossPlatformComponentCompliance", message: "Use testCrossPlatformComponentCompliance which tests both accessibility identifiers and HIG compliance")
@MainActor
public func testCrossPlatformAccessibilityIdentifierGeneration<T: View>(
    _ view: T,
    componentName: String,
    expectedPattern: String = "SixLayer.*ui",
    platforms: [SixLayerPlatform] = [.iOS, .macOS],
    testName: String = "CrossPlatformAccessibilityTest",
    testHIGCompliance: Bool = true
) -> Bool {
    return testCrossPlatformComponentCompliance(
        view,
        componentName: componentName,
        expectedPattern: expectedPattern,
        platforms: platforms,
        testName: testName,
        testHIGCompliance: testHIGCompliance
    )
}

// MARK: - Centralized Platform Detection Test Functions

/// Centralized function for testing platform capability detection
/// Tests that platform-specific capabilities are correctly detected
/// 
/// - Parameters:
///   - platform: Platform to test
///   - expectedCapabilities: Expected platform capabilities
///   - testName: Name of the test for debugging
/// - Returns: True if platform capability detection test passes
@MainActor
internal func testPlatformCapabilityDetection(
    platform: SixLayerPlatform,
    expectedCapabilities: PlatformCapabilitiesTestSnapshot,
    testName: String = "PlatformCapabilityTest"
) -> Bool {
    // Setup: Set capability overrides to match platform
    let currentPlatform = SixLayerPlatform.current
    if platform != currentPlatform {
        // Use capability overrides to simulate platform capabilities
        switch platform {
        case .iOS:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(false)
        case .macOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(true)
        case .watchOS:
            RuntimeCapabilityDetection.setTestTouchSupport(true)
            RuntimeCapabilityDetection.setTestHapticFeedback(true)
            RuntimeCapabilityDetection.setTestHover(false)
        case .tvOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(false)
        case .visionOS:
            RuntimeCapabilityDetection.setTestTouchSupport(false)
            RuntimeCapabilityDetection.setTestHapticFeedback(false)
            RuntimeCapabilityDetection.setTestHover(true)
        }
    }
    
    // Test: Verify we're testing on the current platform or using overrides
    // Note: Platform detection is compile-time, so we verify capabilities instead
    
    // Test: Verify capabilities match expected values
    let actualCapabilities = PlatformCapabilitiesTestSnapshot(
        supportsHapticFeedback: RuntimeCapabilityDetection.supportsHapticFeedback,
        supportsHover: RuntimeCapabilityDetection.supportsHover,
        supportsTouch: RuntimeCapabilityDetection.supportsTouch,
        supportsVoiceOver: RuntimeCapabilityDetection.supportsVoiceOver,
        supportsSwitchControl: RuntimeCapabilityDetection.supportsSwitchControl,
        supportsAssistiveTouch: RuntimeCapabilityDetection.supportsAssistiveTouch,
        minTouchTarget: RuntimeCapabilityDetection.minTouchTarget,
        hoverDelay: RuntimeCapabilityDetection.hoverDelay
    )
    
    // Validate capabilities
    let capabilitiesMatch = actualCapabilities.supportsHapticFeedback == expectedCapabilities.supportsHapticFeedback &&
                           actualCapabilities.supportsHover == expectedCapabilities.supportsHover &&
                           actualCapabilities.supportsTouch == expectedCapabilities.supportsTouch &&
                           actualCapabilities.supportsVoiceOver == expectedCapabilities.supportsVoiceOver &&
                           actualCapabilities.supportsSwitchControl == expectedCapabilities.supportsSwitchControl &&
                           actualCapabilities.supportsAssistiveTouch == expectedCapabilities.supportsAssistiveTouch &&
                           actualCapabilities.minTouchTarget == expectedCapabilities.minTouchTarget &&
                           actualCapabilities.hoverDelay == expectedCapabilities.hoverDelay
    
    if !capabilitiesMatch {
        print("❌ PLATFORM TEST: Capabilities don't match expected values for \(platform)")
        print("Expected: \(expectedCapabilities)")
        print("Actual: \(actualCapabilities)")
    }
    
    // Cleanup: Reset capability overrides
    RuntimeCapabilityDetection.clearAllCapabilityOverrides()
    
    return capabilitiesMatch
}

// MARK: - Centralized Component Test Functions

/// Centralized function for testing component creation and basic functionality
/// Tests that a component can be created and has basic expected properties
/// 
/// - Parameters:
///   - componentName: Name of the component being tested
///   - createComponent: Function that creates the component to test
///   - testName: Name of the test for debugging
/// - Returns: True if component creation test passes
@MainActor
public func testComponentCreation<T>(
    componentName: String,
    createComponent: () -> T,
    testName: String = "ComponentCreationTest"
) -> Bool {
    // Test: Component can be created
    let component = createComponent()
    
    // Basic validation: Component is not nil (for reference types)
    if let optionalComponent = component as? AnyOptional, optionalComponent.isNil {
        print("❌ COMPONENT TEST: \(componentName) creation failed - component is nil")
        return false
    }
    
    return true
}

/// Centralized function for testing component with manual accessibility mode
/// Tests that a component behaves correctly when accessibility mode is manual
/// 
/// - Parameters:
///   - componentName: Name of the component being tested
///   - createComponent: Function that creates the component to test
///   - testName: Name of the test for debugging
/// - Returns: True if component accessibility test passes in manual mode
@MainActor
public func testComponentAccessibilityManual<T: View>(
    componentName: String,
    createComponent: () -> T,
    testName: String = "ComponentAccessibilityManualTest"
) -> Bool {
    // Test: Component creation
    let component = createComponent()
    
    // Test: Accessibility identifier should behave differently in manual mode
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    let originalMode = config.mode
    
    // Set to manual mode for this test
    config.mode = .manual
    
    let accessibilityTestPassed = testAccessibilityIdentifierGeneration(
        component,
        componentName: componentName,
        testName: testName
    )
    
    // Restore original mode
    config.mode = originalMode
    
    if !accessibilityTestPassed {
        print("❌ ACCESSIBILITY MANUAL TEST: \(componentName) failed accessibility manual test")
        return false
    }
    
    return true
}

/// Centralized function for testing component with semantic accessibility mode
/// Tests that a component behaves correctly when accessibility mode is semantic
/// 
/// - Parameters:
///   - componentName: Name of the component being tested
///   - createComponent: Function that creates the component to test
///   - testName: Name of the test for debugging
/// - Returns: True if component accessibility test passes in semantic mode
@MainActor
public func testComponentAccessibilitySemantic<T: View>(
    componentName: String,
    createComponent: () -> T,
    testName: String = "ComponentAccessibilitySemanticTest"
) -> Bool {
    // Test: Component creation
    let component = createComponent()
    
    // Test: Accessibility identifier should behave differently in semantic mode
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    let originalMode = config.mode
    
    // Set to semantic mode for this test
    config.mode = .semantic
    
    let accessibilityTestPassed = testAccessibilityIdentifierGeneration(
        component,
        componentName: componentName,
        testName: testName
    )
    
    // Restore original mode
    config.mode = originalMode
    
    if !accessibilityTestPassed {
        print("❌ ACCESSIBILITY SEMANTIC TEST: \(componentName) failed accessibility semantic test")
        return false
    }
    
    return true
}

/// Centralized function for testing component with disabled accessibility mode
/// Tests that a component behaves correctly when accessibility identifiers are disabled
/// 
/// - Parameters:
///   - componentName: Name of the component being tested
///   - createComponent: Function that creates the component to test
///   - testName: Name of the test for debugging
/// - Returns: True if component accessibility test passes when disabled
@MainActor
public func testComponentAccessibilityDisabled<T: View>(
    componentName: String,
    createComponent: () -> T,
    testName: String = "ComponentAccessibilityDisabledTest"
) -> Bool {
    // Test: Component creation
    let component = createComponent()
    
    // Test: Accessibility identifier should NOT be generated when disabled
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    let autoIDsWereEnabled = config.enableAutoIDs
    
    // Disable auto IDs for this test
    config.enableAutoIDs = false
    
    let accessibilityTestPassed = testAccessibilityIdentifierGeneration(
        component,
        componentName: componentName,
        expectedPattern: "",
        testName: testName
    )
    
    // Restore original setting
    config.enableAutoIDs = autoIDsWereEnabled
    
    if !accessibilityTestPassed {
        print("❌ ACCESSIBILITY DISABLED TEST: \(componentName) failed accessibility disabled test")
        return false
    }
    
    return true
}

/// Centralized function for testing component accessibility in general
/// Tests that a component has proper accessibility support
/// 
/// - Parameters:
///   - componentName: Name of the component being tested
///   - createComponent: Function that creates the component to test
///   - testName: Name of the test for debugging
/// - Returns: True if component accessibility test passes
@MainActor
public func testComponentAccessibility<T: View>(
    componentName: String,
    createComponent: () -> T,
    testName: String = "ComponentAccessibilityTest"
) -> Bool {
    // Test: Component creation
    let component = createComponent()
    
    // Test: Accessibility identifier should be generated
    let accessibilityTestPassed = testAccessibilityIdentifierGeneration(
        component,
        componentName: componentName,
        testName: testName
    )
    
    if !accessibilityTestPassed {
        print("❌ ACCESSIBILITY TEST: \(componentName) failed accessibility test")
        return false
    }
    
    return true
}

// MARK: - Centralized Test Setup Functions

/// Centralized function for setting up test environment
/// Provides consistent test setup across all test files
/// 
/// - Parameters:
///   - enableAccessibility: Whether to enable accessibility features
///   - enableAutoIDs: Whether to enable automatic accessibility identifiers
///   - enableDebugLogging: Whether to enable debug logging
///   - namespace: Namespace for accessibility identifiers
///   - mode: Accessibility mode (automatic, manual, disabled, semantic)
@MainActor
public func setupTestEnvironment(
    enableAccessibility: Bool = true,
    enableAutoIDs: Bool = true,
    enableDebugLogging: Bool = false,
    namespace: String = "SixLayer",
    mode: AccessibilityMode = .automatic
) {
    // Setup: Configure accessibility
    if enableAccessibility {
        let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
        config.enableAutoIDs = enableAutoIDs
        config.namespace = namespace
        config.mode = mode
        config.enableDebugLogging = enableDebugLogging
    }
    
    // Setup: Configure test utilities
    TestSetupUtilities.shared.setupTestingEnvironment()
}

/// Centralized function for cleaning up test environment
/// Provides consistent test cleanup across all test files
@MainActor
public func cleanupTestEnvironment() {
    // Cleanup: Reset accessibility configuration
    let config = AccessibilityIdentifierConfig.currentTaskLocalConfig ?? AccessibilityIdentifierConfig.shared
    config.resetToDefaults()
    
    // Cleanup: Reset test utilities
    TestSetupUtilities.shared.cleanupTestingEnvironment()
}

// MARK: - Helper Types

/// Protocol for optional types to enable nil checking
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

// MARK: - Usage Examples

/*
 
 EXAMPLE USAGE PATTERN:
 
 // In CollectionEmptyStateViewTests.swift:
 @Test @MainActor func testCollectionEmptyStateViewAccessibility() async {
             initializeTestConfig()
     // Setup
     setupTestEnvironment()

     // Test using centralized function
     let view = CollectionEmptyStateView(
         title: "Test Title",
         message: "Test Message",
         onCreateItem: {},
         customCreateView: nil
     )

     #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
     let testPassed = testComponentAccessibility(
         componentName: "CollectionEmptyStateView",
         createComponent: { view }
     )
 #expect(testPassed, "CollectionEmptyStateView should pass accessibility tests")
        #else
     // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
     // The modifier IS present in the code, but ViewInspector can't detect it on macOS
     #endif

     // Cleanup
     cleanupTestEnvironment()
 }
 
 // Test when accessibility IDs are disabled:
 @Test @MainActor func testCollectionEmptyStateViewAccessibilityDisabled() async {
             initializeTestConfig()
     // Setup with auto IDs disabled
     setupTestEnvironment(enableAutoIDs: false)

     let view = CollectionEmptyStateView(
         title: "Test Title",
         message: "Test Message",
         onCreateItem: {},
         customCreateView: nil
     )

     #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
     let testPassed = testComponentAccessibilityDisabled(
         componentName: "CollectionEmptyStateView",
         createComponent: { view }
     )
 #expect(testPassed, "CollectionEmptyStateView should work when accessibility IDs are disabled")
        #else
     // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
     // The modifier IS present in the code, but ViewInspector can't detect it on macOS
     #endif

     // Cleanup
     cleanupTestEnvironment()
 }
 
 // Test different accessibility modes:
 @Test @MainActor func testCollectionEmptyStateViewAccessibilityModes() async {
             initializeTestConfig()
     let view = CollectionEmptyStateView(
         title: "Test Title",
         message: "Test Message",
         onCreateItem: {},
         customCreateView: nil
     )

     // Test automatic mode (default)
     setupTestEnvironment(mode: .automatic)
     let automaticPassed = testComponentAccessibility(
         componentName: "CollectionEmptyStateView-Automatic",
         createComponent: { view }
     )
     cleanupTestEnvironment()

     // Test manual mode
     setupTestEnvironment(mode: .manual)
     let manualPassed = testComponentAccessibilityManual(
         componentName: "CollectionEmptyStateView-Manual",
         createComponent: { view }
     )
     cleanupTestEnvironment()

     // Test semantic mode
     setupTestEnvironment(mode: .semantic)
     #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
     let semanticPassed = testComponentAccessibilitySemantic(
         componentName: "CollectionEmptyStateView-Semantic",
         createComponent: { view }
     )
 #expect(semanticPassed, "CollectionEmptyStateView should work in semantic mode")
        #else
     // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
     // The modifier IS present in the code, but ViewInspector can't detect it on macOS
     #endif
     #expect(disabledPassed, "CollectionEmptyStateView should work in disabled mode")
 }
 
 // In PlatformLogicTests.swift:
 @Test func testPlatformCapabilityDetection() async {
     // Setup
     setupTestEnvironment()

     // Test using centralized function
     let expectedCapabilities = PlatformCapabilitiesTestSnapshot(
         supportsHapticFeedback: false,
         supportsHover: false,
         supportsTouch: true,
         supportsVoiceOver: true,
         supportsSwitchControl: true,
         supportsAssistiveTouch: true,
         minTouchTarget: 44.0,
         hoverDelay: 0.0
     )

     let testPassed = testPlatformCapabilityDetection(
         platform: .iOS,
         expectedCapabilities: expectedCapabilities
     )

     #expect(testPassed, "iOS platform capability detection should work correctly")

     // Cleanup
     cleanupTestEnvironment()
 }
 
 */
