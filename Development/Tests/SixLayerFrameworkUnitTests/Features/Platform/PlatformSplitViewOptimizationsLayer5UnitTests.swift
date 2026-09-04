import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformSplitViewOptimizationsLayer5 (#456).
 * VI suite under ViewInspectorTests/ is excluded from SLF-*-UnitTests.
 * Opposite-lane stubs already covered by PlatformElseStubIdentityTests (#449).
 */

@Suite("Platform Split View Optimizations Layer5 Unit")
struct PlatformSplitViewOptimizationsLayer5UnitTests {

    @Test @MainActor
    func platformSplitViewOptimizations_L5_AppliesTransactionOnHostPlatform() {
        let view = Text("split-root").platformSplitViewOptimizations_L5()
        expectSplitViewL5OptimizationApplied(view)
    }

    #if os(iOS)
    @Test @MainActor
    func platformIOSSplitViewOptimizations_L5_AppliesTransactionOnIOS() {
        let view = Text("split-root").platformIOSSplitViewOptimizations_L5()
        // Deliberate red for #456: wrong modifier name until locked.
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_NotATransactionModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }
    #endif

    #if os(macOS)
    @Test @MainActor
    func platformMacOSSplitViewOptimizations_L5_AppliesTransactionOnMacOS() {
        let view = Text("split-root").platformMacOSSplitViewOptimizations_L5()
        expectSplitViewL5OptimizationApplied(view)
    }
    #endif

    @MainActor
    private func expectSplitViewL5OptimizationApplied(_ view: some View) {
        #if os(iOS) || os(macOS)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_TransactionModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        #else
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #expect(
            !description.contains("_TransactionModifier"),
            "L5 split-view opts are pass-through off iOS/macOS, got: \(description)"
        )
        #endif
    }
}
