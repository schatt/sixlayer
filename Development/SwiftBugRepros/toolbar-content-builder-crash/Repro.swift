// Minimal reproducer for Swift compiler crash:
//
//   Failed to produce diagnostic for expression;
//   please submit a bug report (https://swift.org/contributing/#reporting-bugs)
//
// Trigger conditions (all must hold):
//
//   1. Building for a platform where `ToolbarItemPlacement.navigationBarLeading`
//      and `.navigationBarTrailing` are UNAVAILABLE (watchOS, tvOS).
//   2. Inside a `.toolbar { ... }` closure (i.e. `ToolbarContentBuilder`),
//      a bare `View` is mixed with `ToolbarItem` values.
//   3. An `if let` result-builder branch wraps the `ToolbarItem` values.
//
// Under these conditions swift-frontend fails to produce a diagnostic for the
// whole expression and emits the "please submit a bug report" line instead of
// telling the developer that `.navigationBarLeading` / `.navigationBarTrailing`
// are unavailable on this platform.
//
// Expected behaviour: a real diagnostic pointing at the unavailable enum case
// (or at the View/ToolbarContent mismatch).
//
// Observed (with Xcode 26.5 / Swift 6.3.2):
//   Repro.swift:NN:CC Failed to produce diagnostic for expression; please submit a bug report
//
// To reproduce (from this directory):
//
//     swiftc -typecheck Repro.swift \
//         -target arm64-apple-tvos17.0 \
//         -sdk "$(xcrun --sdk appletvos --show-sdk-path)"
//
//     swiftc -typecheck Repro.swift \
//         -target arm64-apple-watchos10.0 \
//         -sdk "$(xcrun --sdk watchos --show-sdk-path)"
//
// iOS and macOS targets do NOT crash (they either compile or emit a real
// diagnostic). The crash is specific to the SDKs that do not define the
// iOS-only placements.

import SwiftUI

@available(tvOS 17.0, watchOS 10.0, *)
struct ReproView<Content: View, Leading: View, Trailing: View>: View {
    @ViewBuilder var content: () -> Content
    var leadingActions: (() -> Leading)?
    var trailingActions: (() -> Trailing)?

    var body: some View {
        Text("stub").toolbar {
            if let leadingActions = leadingActions {
                ToolbarItem(placement: .navigationBarLeading) {
                    leadingActions()
                }
            }
            content()
            if let trailingActions = trailingActions {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingActions()
                }
            }
        }
    }
}
