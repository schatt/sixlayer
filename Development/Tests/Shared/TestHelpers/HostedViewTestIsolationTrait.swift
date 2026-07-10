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
/// Attach on `@Suite` roots that host SwiftUI for ViewInspector. Pairs with per-test storage caps
/// in `HostingControllerStorage` and `BaseTestClass` deinit for class-based suites.
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
        let testID = test.id
        try await function()
        await MainActor.run {
            HostingControllerStorage.releaseAll(for: testID)
        }
    }
}

extension Trait where Self == HostedViewTestIsolationTrait {
    /// Suite/test trait that releases hosted SwiftUI windows after each test invocation.
    public static var hostedViewIsolation: HostedViewTestIsolationTrait { HostedViewTestIsolationTrait() }
}
