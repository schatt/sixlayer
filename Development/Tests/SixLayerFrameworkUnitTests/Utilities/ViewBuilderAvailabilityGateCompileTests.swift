import Testing
import SwiftUI
@testable import SixLayerFramework

/// Xcode 27 ContentBuilder / `#available` experiment (#340).
///
/// **Finding (Xcode 27.0 / 27A5218g, iOS 17 deploy):** a *real* future gate
/// `#available(iOS 18.0, *)` inside `@ViewBuilder` **compiles cleanly** (no
/// `TupleContent` error, no `buildLimitedAvailability` warning).
///
/// Contrast: *redundant* gates (`#available(iOS 16/macOS 13, …)` when deploy is
/// already iOS 17 / macOS 15) *did* trip `TupleContent … only available in
/// iOS/macOS 26+` in framework sources. So the landmine is the always-true /
/// dead availability path, not every `#available` in a ViewBuilder.
///
/// This probe stays in-tree as a compile regression: if Xcode starts rejecting
/// legitimate future-OS gates in ViewBuilders the same way, this file goes red.
@Suite("ViewBuilder availability gate (Xcode 27 / #340)")
struct ViewBuilderAvailabilityGateCompileTests {

    /// Forces the experimental view type into the test binary.
    @Test @MainActor
    func viewBuilderWithFutureOSAvailabilityGate_compilesAndInstantiates() {
        #if os(iOS)
        let view = ViewBuilderIOS18AvailabilityProbe()
        let _ = view.body
        #expect(Bool(true))
        #else
        // iOS-only probe; other platforms skip.
        #expect(Bool(true))
        #endif
    }
}

#if os(iOS)
/// Minimal View whose `body` puts `#available(iOS 18.0, *)` *inside* `@ViewBuilder`
/// while the package / target still deploys to iOS 17.
@MainActor
private struct ViewBuilderIOS18AvailabilityProbe: View {
    var body: some View {
        // Legitimate future-OS gate nested in the ViewBuilder (not redundant).
        if #available(iOS 18.0, *) {
            Text("iOS 18+ branch")
        } else {
            Text("iOS 17 branch")
        }
    }
}
#endif
