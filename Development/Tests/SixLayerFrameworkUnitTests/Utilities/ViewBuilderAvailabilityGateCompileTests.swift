import Testing
import SwiftUI
@testable import SixLayerFramework

/// Xcode 27 ContentBuilder / `#available` experiment (#340).
///
/// Question: with deployment target iOS 17, does a *real* (non-redundant)
/// `#available(iOS 18, *)` inside `@ViewBuilder` trip the same
/// `TupleContent` / limited-availability failure as dead ≤17 gates?
///
/// This file intentionally uses the inline `#available` form in a ViewBuilder
/// so a build under Xcode 27 exercises that path.
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
        // Deliberate: availability gate nested in the ViewBuilder (not extracted).
        if #available(iOS 18.0, *) {
            Text("iOS 18+ branch")
        } else {
            Text("iOS 17 branch")
        }
    }
}
#endif
