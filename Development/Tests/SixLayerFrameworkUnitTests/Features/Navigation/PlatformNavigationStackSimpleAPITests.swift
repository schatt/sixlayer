import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  PlatformNavigationStackSimpleAPITests.swift
//  SixLayerFrameworkTests
//
//  TDD for free-function platformNavigationStack (no L3 strategy) — #637
//

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Platform Navigation Stack Simple API")
open class PlatformNavigationStackSimpleAPITests: BaseTestClass {

    /// BUSINESS PURPOSE: Drop-in root/host NavigationStack without L1→L3 strategy.
    /// TESTING SCOPE: API accepts ViewBuilder content and returns a View.
    @Test @MainActor func testPlatformNavigationStack_APISignature() {
        let _ = platformNavigationStack {
            Text("HostRoot637")
        }
    }

    /// BUSINESS PURPOSE: Root hosts get a real stack plus L5/L6 stack modifiers.
    /// TESTING SCOPE: Subject type includes platform stack chrome and L5 transaction modifier.
    /// METHODOLOGY: Mirror subject type — no strategy arg required at call site.
    @Test @MainActor func testPlatformNavigationStack_WrapsContentInStackWithLayerModifiers() {
        let view = platformNavigationStack {
            Text("HostRoot637")
        }
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)

        #if os(iOS)
        #expect(
            description.contains("NavigationStack"),
            "iOS host stack should wrap content in NavigationStack, got: \(description)"
        )
        #elseif os(macOS)
        #expect(
            description.contains("NavigationView"),
            "macOS host stack should wrap content in NavigationView, got: \(description)"
        )
        #endif

        #if os(iOS) || os(macOS)
        #expect(
            description.contains("_TransactionModifier"),
            "Simple platformNavigationStack should apply L5 stack optimizations, got: \(description)"
        )
        #endif
    }
}
