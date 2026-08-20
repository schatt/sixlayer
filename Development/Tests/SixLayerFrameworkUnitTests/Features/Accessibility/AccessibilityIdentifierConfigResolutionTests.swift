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

    @Test @MainActor
    func resolvedForIdentifierGenerationUsesTaskLocalWhenSet() {
        let taskLocal = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()

        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(taskLocal) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration()
            #expect(resolved === taskLocal)
        }
    }

    @Test @MainActor
    func resolvedForIdentifierGenerationUsesSharedWhenTaskLocalMissing() {
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration()
            #expect(resolved === AccessibilityIdentifierConfig.shared)
        }
    }
}
