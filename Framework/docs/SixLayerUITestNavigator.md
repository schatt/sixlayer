# SixLayerUITestNavigator (`SixLayerTestKit`)

Issue [#229](https://github.com/schatt/sixlayer/issues/229) adds **narrow** XCUI helpers for consumer UI tests. They sit on top of:

- ``UITestScreenId`` / ``UITestRouteId`` / ``UITestElementId`` (#227)
- ``UITestContractElementResolver`` (#228)

## Primitives

| Method | Behavior |
|--------|----------|
| ``SixLayerUITestNavigator/findContractElement(_:under:)`` | Passthrough to ``UITestContractElementResolver/findFirstExisting`` from the app (or an explicit subtree root). |
| ``SixLayerUITestNavigator/goToScreen(_:timeout:)`` | Resolves the screen id as an accessibility identifier, waits, taps when hittable. |
| ``SixLayerUITestNavigator/openSection(_:under:timeout:)`` | Same pattern for a ``UITestRouteId`` within `under` or the app. |
| ``SixLayerUITestNavigator/backToRoot(maxSteps:stepTimeout:)`` | Repeatedly taps the **leading** button of the **first** navigation bar until failure or `maxSteps`. |

## `backToRoot` semantics

- Each successful step taps `navigationBars.firstMatch.buttons.element(boundBy: 0)` after existence checks. This matches many iOS navigation stacks but is **not** universal (split views, custom chrome, macOS window toolbars).
- For tests or hosts that need a different policy, use the **internal** initializer on `SixLayerUITestNavigator` with `backAttemptOverride` (same-module `@testable` from a UI test bundle).

## SwiftPM unit tests vs UI tests

`XCUIApplication` is **not** usable in SwiftPM **unit** test bundles (XCTest raises *Device is not configured for UI testing*). The SPM suite for #229 covers ``SixLayerUITestNavigatorInternals/consumeBackSteps`` only. End-to-end navigation belongs in a **UI test** target (#231).

## Non-goals

- No reliance on internal SixLayer demo app copy or fixed English labels.
- No hidden sleeps beyond resolver/navigator `timeout` parameters.
