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
        // Clear all capability overrides and harness state, including thread-local test hooks,
        // before each test so we never depend on leaked state from previous invocations.
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        RuntimeCapabilityHarness.macOSTouchEnabledPreference = false
        RuntimeCapabilityHarness.macOSHapticEnabledPreference = false
        defer {
            RuntimeCapabilityHarness.removeHarnessPreferenceKeysFromCurrentThread()
            CapabilityOverride.clearThreadIsolationFromCurrentThread()
        }
        try await function()
    }
}
