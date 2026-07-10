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
/// Installs a per-invocation `HostingSession` in `@TaskLocal` and on the main actor so `@MainActor`
/// hosting always resolves the correct session under parallel Swift Testing.
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
        let hostingSession = await MainActor.run { HostingSession() }
        await MainActor.run {
            MainActorHostingContext.currentSession = hostingSession
        }
        var propagation: Error?
        try await HostingControllerStorage.$session.withValue(hostingSession) {
            try await HostingControllerStorage.$scopeTestID.withValue(testID) {
                do {
                    try await function()
                } catch {
                    propagation = error
                }
            }
        }
        await MainActor.run {
            hostingSession.tearDownAll()
            if MainActorHostingContext.currentSession === hostingSession {
                MainActorHostingContext.currentSession = nil
            }
        }
        if let propagation {
            throw propagation
        }
    }
}

extension Trait where Self == HostedViewTestIsolationTrait {
    /// Suite/test trait that releases hosted SwiftUI windows after each test invocation.
    public static var hostedViewIsolation: HostedViewTestIsolationTrait { HostedViewTestIsolationTrait() }
}
