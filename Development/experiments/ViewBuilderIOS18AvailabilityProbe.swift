import SwiftUI

// Xcode 27 ContentBuilder / `#available` experiment (#340).
//
// Not part of any Xcode test/framework target — kept under Development/experiments
// for local compile checks only.
//
// Finding (Xcode 27.0 / 27A5218g, iOS 17 deploy): a *real* future gate
// `#available(iOS 18.0, *)` inside `@ViewBuilder` compiles cleanly (no
// TupleContent error). Contrast: *redundant* gates (≤ package deploy) in
// framework ViewBuilders did trip TupleContent … iOS/macOS 26+.

#if os(iOS)
/// Minimal View whose `body` puts `#available(iOS 18.0, *)` inside `@ViewBuilder`
/// while the package still deploys to iOS 17.
@MainActor
struct ViewBuilderIOS18AvailabilityProbe: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            Text("iOS 18+ branch")
        } else {
            Text("iOS 17 branch")
        }
    }
}
#endif
