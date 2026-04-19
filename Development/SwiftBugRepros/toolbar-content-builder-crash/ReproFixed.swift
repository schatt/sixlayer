// Control case: the fixed form compiles cleanly on the same platform.
// Uses HStack inside `.toolbar { }` (implicit ToolbarItem with .automatic
// placement) instead of mixing bare Views with ToolbarItem values and
// instead of referring to the iOS-only `.navigationBarLeading` /
// `.navigationBarTrailing` placements.
//
// Compile with:
//
//     swiftc -typecheck ReproFixed.swift \
//         -target arm64-apple-tvos17.0 \
//         -sdk "$(xcrun --sdk appletvos --show-sdk-path)"

import SwiftUI

@available(tvOS 17.0, watchOS 10.0, *)
struct ReproFixedView<Content: View, Leading: View, Trailing: View>: View {
    @ViewBuilder var content: () -> Content
    var leadingActions: (() -> Leading)?
    var trailingActions: (() -> Trailing)?

    var body: some View {
        Text("stub").toolbar {
            HStack {
                if let leadingActions = leadingActions {
                    leadingActions()
                }
                content()
                if let trailingActions = trailingActions {
                    trailingActions()
                }
            }
        }
    }
}
