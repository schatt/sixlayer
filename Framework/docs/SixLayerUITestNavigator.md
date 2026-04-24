# SixLayerUITestNavigator (`SixLayerTestKit`)

Issue [#229](https://github.com/schatt/sixlayer/issues/229) adds **narrow** XCUI helpers for consumer UI tests. They sit on top of:

- ``UITestScreenId`` / ``UITestRouteId`` / ``UITestElementId`` (#227)
- ``UITestContractElementResolver`` (#228)

## Primitives

| Method | Behavior |
|--------|----------|
| ``SixLayerUITestNavigator/findContractElement(_:under:)`` | Passthrough to ``UITestContractElementResolver/findFirstExisting`` from the app (or an explicit subtree root). |
| ``SixLayerUITestNavigator/goToScreen(_:timeout:)`` | Resolves the screen id as an accessibility identifier, waits, taps when hittable; after a tap returns `true` even if the control leaves the hierarchy (push navigation). |
| ``SixLayerUITestNavigator/openSection(_:under:timeout:)`` | Same pattern for a ``UITestRouteId`` within `under` or the app (including post-tap success when the target detaches). |
| ``SixLayerUITestNavigator/backToRoot(maxSteps:stepTimeout:)`` | Repeatedly taps the **leading** button of the **first** navigation bar until failure or `maxSteps`. |

## `backToRoot` semantics

- Each successful step taps `navigationBars.firstMatch.buttons.element(boundBy: 0)` after existence checks. This matches many iOS navigation stacks but is **not** universal (split views, custom chrome, macOS window toolbars).
- For tests or hosts that need a different policy, use the **internal** initializer on `SixLayerUITestNavigator` with `backAttemptOverride` (same-module `@testable` from a UI test bundle).

## SwiftPM unit tests vs UI tests

`XCUIApplication` is **not** usable in SwiftPM **unit** test bundles (XCTest raises *Device is not configured for UI testing*). The SPM suite for #229 covers ``SixLayerUITestNavigatorInternals/consumeBackSteps`` only (including non-positive `maxSteps`, which avoids invalid `0..<n` ranges when `n` is negative). End-to-end navigation belongs in a **UI test** target (#231).

## Consumer smoke & optional assertions (#230, #231)

- **Smoke tests:** `SixLayerUITestNavigatorConsumerSmokeUITests` in `Development/Tests/SixLayerFrameworkUITests` launches the framework TestApp with **`-OpenUITestContractSmokeHost`**, which shows ``UITestContractSmokeHostView`` (identifiers under `com.sixlayer.smoke.*` only — not Layer N demo menus).
- **Cross-platform:** the same sources run under `SixLayerFrameworkUITests_iOS` and `SixLayerFrameworkUITests_macOS`; navigation chrome differs by OS, but `NavigationStack` + leading back is the parity target.
- **Optional assertions:** [UITestContractAssertions.md](UITestContractAssertions.md) (#230).

## Non-goals

- No reliance on internal SixLayer demo app copy or fixed English labels.
- No hidden sleeps beyond resolver/navigator `timeout` parameters.
