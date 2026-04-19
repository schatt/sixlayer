# Swift compiler: "failed to produce diagnostic" for bare View mixed with ToolbarItem inside `.toolbar { }`

**Filed upstream as [swiftlang/swift#88533](https://github.com/swiftlang/swift/issues/88533).**

## Summary

Under Xcode 26.5 / Swift 6.3.2, a `.toolbar { ... }` closure that contains both a bare `View` value and a `ToolbarItem` value (in either order) causes swift-frontend to abort with:

```
error: failed to produce diagnostic for expression;
please submit a bug report (https://swift.org/contributing/#reporting-bugs)
```

Expected behaviour: a real diagnostic such as "ambiguous use of `toolbar(_:)`" or "expected `ToolbarContent`, found `some View`".

The crash is independent of the deployment platform: it reproduces on iOS, watchOS, and tvOS SDKs with the same source. `if let` / other control flow is **not** required; generics, opaque types, and platform-unavailable placements are not required.

## Environment

- Xcode 26.5 (Build 17F5022i)
- `swift --version`: Apple Swift version 6.3.2 (swiftlang-6.3.2.1.103 clang-2100.1.1.101)
- Host: macOS 26.x, arm64
- Reproduces with SDKs: iphoneos, watchos, appletvos

## Minimal reproducer (10 lines of body)

```swift
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
```

Compile with:

```sh
swiftc -typecheck ReproMinimal.swift \
    -target arm64-apple-ios17.0 \
    -sdk "$(xcrun --sdk iphoneos --show-sdk-path)"
```

Output:

```
ReproMinimal.swift:<line>:<col>: error: failed to produce diagnostic for expression;
please submit a bug report (https://swift.org/contributing/#reporting-bugs)
```

## Bisecting the trigger

Two builders are in play: `toolbar(@ViewBuilder _:)` and `toolbar(@ToolbarContentBuilder content:)`. The crash fires when the closure contains **both** kinds of elements.

| Closure contents                        | Result                    |
| --------------------------------------- | ------------------------- |
| Two bare `View`s                        | Compiles (ViewBuilder overload) |
| Two `ToolbarItem`s                      | Compiles (ToolbarContentBuilder overload) |
| One `View` then one `ToolbarItem`       | **Crash** (failed to produce diagnostic) |
| One `ToolbarItem` then one `View`       | **Crash** |
| One `ToolbarItem` wrapped in `if let`, no bare `View` | Compiles |

So: the overlap between the two overloads, not `if let` and not a platform-unavailable enum case, is the root cause.

## Expected diagnostic

Something like one of:

```
error: ambiguous use of 'toolbar'
note: found this candidate (ViewBuilder)
note: found this candidate (ToolbarContentBuilder)
```

or

```
error: type 'Text' does not conform to 'ToolbarContent'
```

## Related (but not duplicate) issues

- #58372 — `Spacer()` misplaced before `ToolbarItemGroup` (different expression, same class)
- #87240 — assignment-as-View inside a second `ToolbarItem` (different expression, same class)

Both are still open and are tagged `failed to produce diagnostic` / `type checker`. This repro is the cleanest minimal case I've found for the same family: the only non-trivial thing in the closure is **two values of different ToolbarContentBuilder-vs-ViewBuilder categories, side-by-side**.

## Workaround

Wrap every element in `ToolbarItem { ... }` so the closure is unambiguously `ToolbarContent`, or alternatively wrap everything in a single `HStack { ... }` so the closure is unambiguously a `View`. Either form compiles and gives the documented behaviour.
