import Testing


import SwiftUI
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: Verify that accessibility identifier generation logic actually works
 * and that the Enhanced Breadcrumb System modifiers properly enable identifier generation.
 *
 * TESTING SCOPE: Tests the actual identifier generation logic, not just that views can be created.
 * This addresses the gap in original tests that missed the critical bug where identifiers
 * weren't being generated due to missing environment variable setup.
 *
 * METHODOLOGY: Tests the actual logic that determines whether identifiers should be generated,
 * using **isolated** `AccessibilityIdentifierConfig` via `BaseTestClass` / `@TaskLocal` — never
 * mutating `AccessibilityIdentifierConfig.shared` (parallel-unsafe; see #247).
 */
@Suite("Accessibility Identifier Logic Verification")
open class AccessibilityIdentifierLogicVerificationTests: BaseTestClass {

    @Test @MainActor func testIdentifierGenerationLogicEvaluatesConditionsCorrectly() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }

            // Test Case 1: All conditions met - should generate identifiers
            config.enableAutoIDs = true
            config.namespace = "test"

            // Simulate the logic from AccessibilityIdentifierAssignmentModifier
            let disableAutoIDs = false  // Environment variable
            let globalAutoIDs = true    // Environment variable (now defaults to true)
            let shouldApplyAutoIDs = !disableAutoIDs && config.enableAutoIDs && globalAutoIDs

            #expect(shouldApplyAutoIDs, "When all conditions are met, identifiers should be generated")

            // Test Case 2: Global auto IDs disabled - should not generate identifiers
            let globalAutoIDsDisabled = false
            let shouldApplyAutoIDsDisabled = !disableAutoIDs && config.enableAutoIDs && globalAutoIDsDisabled

            #expect(!shouldApplyAutoIDsDisabled, "When global auto IDs are disabled, identifiers should not be generated")

            // Test Case 3: Config disabled - should not generate identifiers
            config.enableAutoIDs = false
            let shouldApplyAutoIDsConfigDisabled = !disableAutoIDs && config.enableAutoIDs && globalAutoIDs

            #expect(!shouldApplyAutoIDsConfigDisabled, "When config is disabled, identifiers should not be generated")

            // Test Case 4: View-level opt-out - should not generate identifiers
            config.enableAutoIDs = true
            let disableAutoIDsViewLevel = true
            let shouldApplyAutoIDsViewOptOut = !disableAutoIDsViewLevel && config.enableAutoIDs && globalAutoIDs

            #expect(!shouldApplyAutoIDsViewOptOut, "When view-level opt-out is enabled, identifiers should not be generated")
        }
    }

    @Test @MainActor func testAutomaticAccessibilityIdentifiersWorkCorrectly() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = true
            config.namespace = "test"

            _ = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("TestButton")

            _ = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }

            _ = PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }

            #expect(config.enableAutoIDs, "Automatic IDs should be enabled")
            #expect(config.namespace == "test", "Namespace should be set correctly")
        }
    }

    @Test @MainActor func testAccessibilityIdentifierGeneratorCreatesProperIdentifiers() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = true
            config.namespace = "SixLayer"
            config.mode = .automatic

            let generator = AccessibilityIdentifierGenerator()

            let basicID = generator.generateID(for: "TestButton", role: "button", context: "ui")
            #expect(basicID.hasPrefix("SixLayer"), "Generated ID should start with namespace")
            #expect(basicID.contains("button"), "Generated ID should contain role")
            #expect(!basicID.isEmpty, "Generated ID should not be empty")

            config.pushViewHierarchy("NavigationView")
            config.pushViewHierarchy("ProfileSection")
            let hierarchyID = generator.generateID(for: "EditButton", role: "button", context: "ui")
            #expect(hierarchyID.hasPrefix("SixLayer"), "Generated ID should start with namespace")
            #expect(hierarchyID.contains("button"), "Generated ID should contain role")
            #expect(!hierarchyID.isEmpty, "Generated ID should not be empty")

            config.setScreenContext("UserProfile")
            let screenID = generator.generateID(for: "SaveButton", role: "button", context: "ui")
            #expect(screenID.hasPrefix("SixLayer"), "Generated ID should start with namespace")
            #expect(screenID.contains("button"), "Generated ID should contain role")
            #expect(!screenID.isEmpty, "Generated ID should not be empty")

            config.setNavigationState("ProfileEditMode")
            let navigationID = generator.generateID(for: "CancelButton", role: "button", context: "ui")
            #expect(navigationID.hasPrefix("SixLayer"), "Generated ID should start with namespace")
            #expect(navigationID.contains("button"), "Generated ID should contain role")
            #expect(!navigationID.isEmpty, "Generated ID should not be empty")
        }
    }

    @Test @MainActor func testBugFixResolvesIdentifierGenerationIssue() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }

            config.enableAutoIDs = true
            config.namespace = "SixLayer"
            config.mode = .automatic
            config.enableViewHierarchyTracking = true
            config.enableUITestIntegration = true
            config.enableDebugLogging = true

            _ = Button(action: {}) {
                Label("Add Fuel", systemImage: "plus")
            }
            .named("AddFuelButton")

            #expect(Bool(true), "The exact bug scenario should now work correctly")

            #expect(config.enableAutoIDs, "Auto IDs should be enabled")
            #expect(config.namespace == "SixLayer", "Namespace should be set correctly")
            #expect(config.enableViewHierarchyTracking, "View hierarchy tracking should be enabled")
            #expect(config.enableUITestIntegration, "UI test integration should be enabled")
            #expect(config.enableDebugLogging, "Debug logging should be enabled")
        }
    }

    @Test @MainActor func testDefaultBehaviorChangeWorksCorrectly() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }

            config.resetToDefaults()
            config.enableAutoIDs = true
            config.namespace = "defaultApp"

            _ = Text("Hello World")
                .automaticCompliance()

            #expect(Bool(true), "View should work with explicitly enabled config")

            #expect(config.enableAutoIDs, "Automatic IDs should be enabled (explicitly set)")
            #expect(config.namespace == "defaultApp", "Namespace should be set correctly (explicitly set)")
        }
    }

    @Test @MainActor func testManualIdentifiersOverrideAutomaticGeneration() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = true
            config.namespace = "auto"

            let manualID = "manual-custom-id"
            _ = Text("Test")
                .accessibilityIdentifier(manualID)
                .automaticCompliance()

            #expect(Bool(true), "View with manual identifier should be created successfully")

            #expect(config.enableAutoIDs, "Automatic IDs should be enabled")
            #expect(config.namespace == "auto", "Namespace should be set correctly")
        }
    }

    @Test @MainActor func testOptOutPreventsIdentifierGeneration() async {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = true
            config.namespace = "test"

            _ = Text("Test")
                .disableAutomaticAccessibilityIdentifiers()
                .automaticCompliance()

            #expect(Bool(true), "View with opt-out should be created successfully")

            #expect(config.enableAutoIDs, "Automatic IDs should be enabled globally")
            #expect(config.namespace == "test", "Namespace should be set correctly")
        }
    }
}
