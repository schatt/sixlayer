# `toolbar-content-builder-crash`

Standalone reproducer for a swift-frontend crash (`failed to produce diagnostic for expression`) that was originally surfaced inside `Framework/Sources/Extensions/Platform/PlatformSpecificViewExtensions.swift` (the `#else` branch of `platformToolbar(content:leadingActions:trailingActions:)`).

**Filed upstream as [swiftlang/swift#88533](https://github.com/swiftlang/swift/issues/88533).**

The production-side fix is committed separately on this branch. The files here exist to:

1. Confirm the crash is a compiler bug, not a bug in this project.
2. Give whoever files the Swift issue a minimal, self-contained reproducer.

## Files

- `Repro.swift` — generic, closer in shape to the original production code. Crashes.
- `ReproMinimal.swift` — smallest variant that still crashes. **Use this one for the bug report.**
- `ReproFixed.swift` — control case; compiles cleanly on the same compiler.
- `BUG_REPORT.md` — drafted issue body for `swiftlang/swift`, with bisected trigger and environment details.

## Reproducing locally

```sh
cd Development/SwiftBugRepros/toolbar-content-builder-crash

# Crashes:
swiftc -typecheck ReproMinimal.swift \
    -target arm64-apple-ios17.0 \
    -sdk "$(xcrun --sdk iphoneos --show-sdk-path)"

# Compiles cleanly:
swiftc -typecheck ReproFixed.swift \
    -target arm64-apple-tvos17.0 \
    -sdk "$(xcrun --sdk appletvos --show-sdk-path)"
```

Verified under Xcode 26.5 / Swift 6.3.2.
