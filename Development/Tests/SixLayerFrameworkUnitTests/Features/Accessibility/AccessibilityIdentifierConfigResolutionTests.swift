//
//  AccessibilityIdentifierConfigResolutionTests.swift
//  SixLayerFrameworkTests
//
//  Identifier generation must resolve config from @TaskLocal then .shared,
//  never from SwiftUI Environment (inspect() cannot install Environment; #435).
//

import Testing
@testable import SixLayerFramework

@Suite("AccessibilityIdentifierConfig resolution")
struct AccessibilityIdentifierConfigResolutionTests {

    /// Environment was a test-only second channel. Generation must ignore it when task-local is set.
    @Test @MainActor
    func resolvedForIdentifierGenerationPrefersTaskLocalOverEnvironmentInstance() {
        let taskLocal = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        taskLocal.namespace = "task-local-ns"
        let environment = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        environment.namespace = "environment-ns"

        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(taskLocal) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration(
                environment: environment
            )
            #expect(resolved === taskLocal)
            #expect(resolved.namespace == "task-local-ns")
        }
    }

    /// With no task-local, generation uses .shared even if an Environment instance is passed.
    @Test @MainActor
    func resolvedForIdentifierGenerationUsesSharedWhenTaskLocalMissingEvenIfEnvironmentProvided() {
        let environment = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        environment.namespace = "environment-ns"

        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration(
                environment: environment
            )
            #expect(resolved === AccessibilityIdentifierConfig.shared)
        }
    }

    @Test @MainActor
    func resolvedForIdentifierGenerationUsesTaskLocalWhenEnvironmentNil() {
        let taskLocal = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()

        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(taskLocal) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration(
                environment: nil
            )
            #expect(resolved === taskLocal)
        }
    }
}
