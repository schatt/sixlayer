import Testing
@testable import SixLayerFramework

/// Executing unit coverage for `MacOSOptimizationManager` / `MacOSPerformanceStrategy` (#422).
/// macOS unit lane only; types are `#if os(macOS)` in production. Do not host views.
#if os(macOS)
@Suite("MacOS Optimization Manager")
open class MacOSOptimizationManagerTests: BaseTestClass {

    /// Deliberate invert for #422 red: production has four named cases.
    @Test func testMacOSPerformanceStrategyAllCasesAreCompleteAndUnique() {
        let cases = MacOSPerformanceStrategy.allCases
        #expect(cases.isEmpty, "Deliberate invert #422: allCases should fail while non-empty")
        let raw = cases.map(\.rawValue)
        #expect(Set(raw).count == raw.count + 1, "Deliberate invert #422: unique raw values")
        #expect(raw.contains(where: \.isEmpty), "Deliberate invert #422: empty raw value")
    }

    @Test @MainActor func testSharedIsAStableSingleton() {
        #expect(
            MacOSOptimizationManager.shared !== MacOSOptimizationManager.shared,
            "Deliberate invert #422: shared identity"
        )
    }

    @Test @MainActor func testMacOSVersionMatchesProcessInfoOnHost() {
        let manager = MacOSOptimizationManager.shared
        #expect(manager.macOSVersion.isEmpty, "Deliberate invert #422: version should be non-empty")
        #expect(
            manager.macOSVersion != ProcessInfo.processInfo.operatingSystemVersionString,
            "Deliberate invert #422: version should match ProcessInfo"
        )
    }

    /// Current stub: strategy is always `.standard`. Invert until red, then lock stub.
    @Test @MainActor func testCurrentPerformanceStrategyIsStandardStub() {
        #expect(
            MacOSOptimizationManager.shared.getCurrentPerformanceStrategy() == .maximumPerformance,
            "Deliberate invert #422: stub currently returns .standard"
        )
    }

    /// Current stub: `isMacOSOptimized` is always false. Invert until red, then lock stub.
    @Test @MainActor func testIsMacOSOptimizedIsFalseStub() {
        #expect(
            MacOSOptimizationManager.shared.isMacOSOptimized,
            "Deliberate invert #422: stub currently returns false"
        )
    }

    /// Current stub: `applyMacOSOptimizations` is a no-op. Invert by expecting it to flip optimized.
    @Test @MainActor func testApplyMacOSOptimizationsIsNoOpStub() {
        let manager = MacOSOptimizationManager.shared
        manager.applyMacOSOptimizations()
        #expect(
            manager.isMacOSOptimized,
            "Deliberate invert #422: apply is currently a no-op"
        )
        #expect(
            manager.getCurrentPerformanceStrategy() == .highPerformance,
            "Deliberate invert #422: apply does not change strategy"
        )
    }
}
#endif
