// Minimal reproducer for:
//
//   error: failed to produce diagnostic for expression;
//   please submit a bug report (https://swift.org/contributing/#reporting-bugs)
//
// Environment (verified):
//   Xcode 26.5 (Build 17F5022i)
//   Apple Swift version 6.3.2 (swiftlang-6.3.2.1.103 clang-2100.1.1.101)
//   iOS, watchOS, tvOS SDKs (crash reproduces on all three)
//
// Trigger: inside a `.toolbar { ... }` closure (ToolbarContentBuilder),
// mix a bare `View` value with a `ToolbarItem` (ToolbarContent) value.
// The type checker fails to reconcile the two overloads of `toolbar` — the
// one taking `@ViewBuilder` and the one taking `@ToolbarContentBuilder` —
// and crashes instead of emitting a real diagnostic.
//
// Not required for the crash:
//   - `if let` or any other result-builder control flow
//   - Platform-unavailable placements (`.navigationBarLeading` etc.)
//   - Generics, protocols, or opaque types
//
// Required for the crash:
//   - At least one bare `View` value AND at least one `ToolbarItem` value
//     in the same `.toolbar { }` closure (in either order).
//
// Negative controls that COMPILE on the same compiler:
//   - Two bare `View` values (no `ToolbarItem`s)           — the ViewBuilder overload wins
//   - Two `ToolbarItem` values (no bare `View`s)           — the ToolbarContentBuilder overload wins
//
// Expected behaviour: a diagnostic that tells the developer the types in the
// closure are not `ToolbarContent`, or that the overload is ambiguous.
// Observed behaviour: compiler abort with "failed to produce diagnostic".
//
// Reproduce:
//
//     swiftc -typecheck ReproMinimal.swift \
//         -target arm64-apple-ios17.0 \
//         -sdk "$(xcrun --sdk iphoneos --show-sdk-path)"

import SwiftUI

@available(iOS 17.0, *)
struct ReproMinimalView: View {
    var body: some View {
        Text("body").toolbar {
            Text("bare view in toolbar")
            ToolbarItem(placement: .principal) { Text("x") }
        }
    }
}
