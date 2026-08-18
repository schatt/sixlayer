import Foundation
import Testing
@testable import SixLayerFramework

/// Executing unit coverage for `MacOSOptimizationManager` / `MacOSPerformanceStrategy` (#422).
/// macOS unit lane only; types are `#if os(macOS)` in production. Do not host views.
///
/// Stub observations (`getCurrentPerformanceStrategy`, `isMacOSOptimized`, `applyMacOSOptimizations`)
/// lock **current placeholder behavior**. Changing them is a deliberate product change, not a silent test fix.
#if os(macOS)
fileprivate let expectedMacOSPerformanceStrategies: [MacOSPerformanceStrategy] = [
    .standard, .optimized, .highPerformance, .maximumPerformance
]

@Suite("MacOS Optimization Manager")
open class MacOSOptimizationManagerTests: BaseTestClass {

    @Test func testMacOSPerformanceStrategyAllCasesAreCompleteAndUnique() {
        let cases = MacOSPerformanceStrategy.allCases
        #expect(
            cases == expectedMacOSPerformanceStrategies,
            "allCases must stay complete; adding a strategy is a deliberate API change"
        )
        let raw = cases.map(\.rawValue)
        #expect(Set(raw).count == raw.count, "Raw values must be unique")
        #expect(raw.allSatisfy { !$0.isEmpty }, "Raw values must be non-empty")
    }

    @Test @MainActor func testSharedIsAStableSingleton() {
        #expect(
            MacOSOptimizationManager.shared === MacOSOptimizationManager.shared,
            "shared must be a stable singleton"
        )
    }

    @Test @MainActor func testMacOSVersionMatchesProcessInfoOnHost() {
        let manager = MacOSOptimizationManager.shared
        let processVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #expect(!manager.macOSVersion.isEmpty, "macOSVersion should be non-empty on the test host")
        #expect(
            manager.macOSVersion == processVersion,
            "macOSVersion should match ProcessInfo on this host"
        )
    }

    /// Current stub: always `.standard` (placeholder in production).
    @Test @MainActor func testCurrentPerformanceStrategyIsStandardStub() {
        #expect(
            MacOSOptimizationManager.shared.getCurrentPerformanceStrategy() == .standard,
            "Stub currently always returns .standard; a real strategy selector is a product change"
        )
    }

    /// Current stub: always `false` (TODO in production).
    @Test @MainActor func testIsMacOSOptimizedIsFalseStub() {
        #expect(
            !MacOSOptimizationManager.shared.isMacOSOptimized,
            "Stub currently always returns false; real detection is a product change"
        )
    }

    /// Current stub: `applyMacOSOptimizations` is a no-op.
    @Test @MainActor func testApplyMacOSOptimizationsIsNoOpStub() {
        let manager = MacOSOptimizationManager.shared
        manager.applyMacOSOptimizations()
        #expect(
            !manager.isMacOSOptimized,
            "applyMacOSOptimizations is currently a no-op"
        )
        #expect(
            manager.getCurrentPerformanceStrategy() == .standard,
            "applyMacOSOptimizations must not change the stub strategy"
        )
    }
}
#endif
