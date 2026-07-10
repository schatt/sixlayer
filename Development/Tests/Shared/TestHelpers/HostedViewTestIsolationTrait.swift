//
//  HostedViewTestIsolationTrait.swift
//  SixLayerFrameworkUnitTests
//
//  Swift Testing suite trait: tear down UIHostingController/NSHostingController windows
//  after each test so ViewInspector hosted suites do not accumulate unbounded memory (GitHub #315).
//

import Testing

/// Releases all views hosted via `TestSetupUtilities.hostRootPlatformView` when each test finishes.
///
/// Prefer attaching this trait on `@Suite` roots that call `hostRootPlatformView`. Cross-test cleanup
/// also runs automatically when `Test.current` changes at the next `hostRootPlatformView` call.
public struct HostedViewTestIsolationTrait: Sendable, TestTrait, SuiteTrait, TestScoping {
    public typealias TestScopeProvider = HostedViewTestIsolationTrait

    public var isRecursive: Bool { true }

    public func scopeProvider(for test: Testing.Test, testCase: Testing.Test.Case?) -> HostedViewTestIsolationTrait? {
        self
    }

    public func provideScope(
        for test: Testing.Test,
        testCase: Testing.Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        defer {
            Task { @MainActor in
                HostingControllerStorage.releaseAll()
            }
        }
        try await function()
    }
}

extension Trait where Self == HostedViewTestIsolationTrait {
    /// Suite/test trait that releases hosted SwiftUI windows after each test invocation.
    public static var hostedViewIsolation: HostedViewTestIsolationTrait { HostedViewTestIsolationTrait() }
}
