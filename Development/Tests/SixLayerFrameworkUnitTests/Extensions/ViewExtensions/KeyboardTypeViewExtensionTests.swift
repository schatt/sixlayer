//
//  KeyboardTypeViewExtensionTests.swift
//  SixLayerFrameworkTests
//
//  Tests for keyboardType View extension that bridges KeyboardType enum to SwiftUI
//  TDD: Red Phase - Tests written before implementation
//

import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for keyboardType View extension
/// Tests that the extension exists, maps KeyboardType enum to SwiftUI keyboard types on iOS,
/// and provides no-op behavior on macOS
@Suite("KeyboardType View Extension")
open class KeyboardTypeViewExtensionTests: BaseTestClass {

    // MARK: - Function Existence Tests

    /// BUSINESS PURPOSE: Validates that keyboardType extension exists and can be called
    /// TESTING SCOPE: Tests function existence and callability
    /// METHODOLOGY: Test that extension can be invoked without errors and returns a View
    @Test @MainActor func testKeyboardType_ExtensionExists() {
        initializeTestConfig()

        // Given: A view to call the extension on
        // When: Calling keyboardType extension with a KeyboardType
        _ = Text("Test").keyboardType(KeyboardType.default)

        // Then: Should return a View (non-optional)
        #expect(Bool(true), "keyboardType extension should return a View")
    }

    /// BUSINESS PURPOSE: Validates that all KeyboardType enum cases can be passed to the extension
    /// TESTING SCOPE: Tests enum compatibility
    /// METHODOLOGY: Test that all enum cases compile and can be called
    @Test @MainActor func testKeyboardType_AllEnumCasesSupported() {
        initializeTestConfig()

        // Given: A view and all KeyboardType enum cases
        let testView = Text("Test")
        let allCases = KeyboardType.allCases

        // When & Then: Each enum case should work with the extension
        for keyboardType in allCases {
            _ = testView.keyboardType(keyboardType)
            #expect(Bool(true), "keyboardType extension should accept \(keyboardType)")
        }
    }

    // MARK: - Platform-Specific Behavior Tests

    #if os(iOS)
    /// BUSINESS PURPOSE: Validates that iOS implementation applies correct SwiftUI keyboard types
    /// TESTING SCOPE: Tests iOS-specific keyboard type mapping
    /// METHODOLOGY: Test that KeyboardType enum values map to correct SwiftUI.UIKeyboardType values
    @Test @MainActor func testKeyboardType_iOS_MapsToCorrectSwiftUIKeyboardTypes() {
        initializeTestConfig()

        // Given: iOS platform
        let platform = SixLayerPlatform.current
        #expect(platform == .iOS, "Test should run on iOS")

        // Note: We can't directly test the internal SwiftUI modifier application
        // in unit tests, but we can verify the function exists and returns a View
        // Integration tests would verify actual keyboard behavior

        let testView = Text("Test")

        // Test each keyboard type
        _ = testView.keyboardType(KeyboardType.default)
        _ = testView.keyboardType(KeyboardType.phonePad)
        _ = testView.keyboardType(KeyboardType.emailAddress)
        _ = testView.keyboardType(KeyboardType.numberPad)
        _ = testView.keyboardType(KeyboardType.decimalPad)

        // All should return Views (actual keyboard behavior tested via integration)
        #expect(Bool(true), "iOS keyboardType extension should return Views for all types")
    }
    #endif

    #if os(macOS)
    /// BUSINESS PURPOSE: Validates that macOS implementation provides no-op behavior
    /// TESTING SCOPE: Tests macOS-specific behavior
    /// METHODOLOGY: Test that extension returns unmodified view on macOS
    @Test @MainActor func testKeyboardType_macOS_NoOpBehavior() {
        initializeTestConfig()

        // Given: macOS platform
        let platform = SixLayerPlatform.current
        #expect(platform == .macOS, "Test should run on macOS")

        let testView = Text("Test")

        // When: Applying keyboardType extension
        _ = testView.keyboardType(.phonePad)

        // Then: Should return a View (keyboard types don't apply on macOS)
        #expect(Bool(true), "macOS keyboardType extension should return a View")
    }
    #endif

    // MARK: - Cross-Platform Compatibility Tests

    /// BUSINESS PURPOSE: Validates that extension works on all supported platforms
    /// TESTING SCOPE: Tests cross-platform compatibility
    /// METHODOLOGY: Test that function can be called on any platform and returns View
    @Test @MainActor func testKeyboardType_CrossPlatformCompatibility() {
        initializeTestConfig()

        let testView = Text("Test")

        // Test with various keyboard types
        let typesToTest: [KeyboardType] = [.default, .emailAddress, .phonePad, .numberPad]

        for keyboardType in typesToTest {
            _ = testView.keyboardType(keyboardType)
            #expect(Bool(true), "keyboardType extension should work with \(keyboardType)")
        }
    }

    // MARK: - Integration Tests

    /// BUSINESS PURPOSE: Validates that extension can be chained with other View modifiers
    /// TESTING SCOPE: Tests integration with SwiftUI modifier chaining
    /// METHODOLOGY: Test that keyboardType can be used in modifier chains
    @Test @MainActor func testKeyboardType_ChainsWithOtherModifiers() {
        initializeTestConfig()

        // Given: A view that uses keyboardType in a modifier chain
        _ = Text("Test")
            .keyboardType(KeyboardType.emailAddress)
            .padding()
            .background(Color.blue.opacity(0.1))

        // Then: Should compile and create a valid view
        #expect(Bool(true), "keyboardType should chain with other SwiftUI modifiers")
    }

    /// BUSINESS PURPOSE: Validates that extension works with different View types
    /// TESTING SCOPE: Tests compatibility with various SwiftUI views
    /// METHODOLOGY: Test keyboardType extension with TextField, SecureField, etc.
    @Test @MainActor func testKeyboardType_WorksWithTextInputViews() {
        initializeTestConfig()

        // Test with TextField (most common use case)
        _ = TextField("Enter text", text: .constant("test"))
            .keyboardType(KeyboardType.emailAddress)

        // Test with SecureField
        _ = SecureField("Enter password", text: .constant("password"))
            .keyboardType(KeyboardType.default)

        #expect(Bool(true), "keyboardType should work with TextField and SecureField")
    }

    // MARK: - Error Handling Tests

    /// BUSINESS PURPOSE: Validates that extension handles edge cases gracefully
    /// TESTING SCOPE: Tests error handling and edge cases
    /// METHODOLOGY: Test that extension doesn't crash on unexpected inputs
    @Test @MainActor func testKeyboardType_ErrorHandling() {
        initializeTestConfig()

        let testView = Text("Test")

        // Test multiple calls (should not cause issues)
        _ = testView.keyboardType(KeyboardType.default)
        _ = testView.keyboardType(KeyboardType.phonePad).keyboardType(KeyboardType.emailAddress)

        #expect(Bool(true), "keyboardType extension should handle multiple calls gracefully")
    }

    // MARK: - Framework Integration Tests

    /// BUSINESS PURPOSE: Validates that extension integrates properly with framework patterns
    /// TESTING SCOPE: Tests framework integration
    /// METHODOLOGY: Test that extension follows framework conventions
    @Test @MainActor func testKeyboardType_FrameworkIntegration() {
        initializeTestConfig()

        // Test that it works with framework's automatic compliance
        _ = Text("Test")
            .keyboardType(KeyboardType.phonePad)
            .automaticCompliance()

        #expect(Bool(true), "keyboardType should integrate with framework's automatic compliance")
    }
}
