//
//  DefaultRuntimeCapabilityIsolationTrait.swift
//  SixLayerFrameworkUnitTests
//
//  Swift Testing suite trait: deterministic runtime capability defaults per test (GitHub #236).
//

import Testing
@testable import SixLayerFramework

/// Resets thread-local capability overrides, clears legacy `UserDefaults.standard` keys used for
/// capability simulation, and pins macOS harness preferences to `false` for each test invocation.
public struct DefaultRuntimeCapabilityIsolationTrait: Sendable, TestTrait, SuiteTrait, TestScoping {
    public typealias TestScopeProvider = DefaultRuntimeCapabilityIsolationTrait

    public var isRecursive: Bool { false }

    public func scopeProvider(for test: Testing.Test, testCase: Testing.Test.Case?) -> DefaultRuntimeCapabilityIsolationTrait? {
        self
    }

    public func provideScope(
        for test: Testing.Test,
        testCase: Testing.Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // `@TaskLocal` so harness values follow the same async task as `function()` (including
        // `@MainActor` tests), unlike `Thread.current.threadDictionary` which is per-OS-thread.
        let touchHarness: Bool? = false
        let hapticHarness: Bool? = false
        try await RuntimeCapabilityHarness.$macOSTouchEnabledPreference.withValue(touchHarness) {
            try await RuntimeCapabilityHarness.$macOSHapticEnabledPreference.withValue(hapticHarness) {
                RuntimeCapabilityDetection.clearAllCapabilityOverrides()
                defer {
                    CapabilityOverride.clearThreadIsolationFromCurrentThread()
                }
                try await function()
            }
        }
    }
}
