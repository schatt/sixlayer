//
//  DefaultRuntimeCapabilityIsolationTrait.swift
//  SixLayerFrameworkUnitTests
//
//  Swift Testing suite trait: deterministic runtime capability defaults per test (GitHub #236).
//  GitHub #251 section C: use on **control** suites that call `setTest*` so phases do not leak;
//  does not replace tri-state assertions beside the control under test.
//

import Testing
@testable import SixLayerFramework

/// Resets task-local capability overrides, clears legacy `UserDefaults.standard` keys used for
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
        let overrideBag = CapabilityTestOverrideBag()
        var propagation: Error?
        try await RuntimeCapabilityHarness.$capabilityTestOverrideBag.withValue(overrideBag) {
            try await RuntimeCapabilityHarness.$macOSTouchEnabledPreference.withValue(touchHarness) {
                try await RuntimeCapabilityHarness.$macOSHapticEnabledPreference.withValue(hapticHarness) {
                    // `CapabilityOverride` still uses per-OS-thread storage — clear on main for @MainActor tests.
                    RuntimeCapabilityDetection.clearAllCapabilityOverrides()
                    await MainActor.run {
                        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
                    }
                    defer {
                        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
                    }
                    do {
                        try await function()
                    } catch {
                        propagation = error
                    }
                    await MainActor.run {
                        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
                    }
                }
            }
        }
        if let propagation {
            throw propagation
        }
    }
}
