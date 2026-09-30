# SixLayer Framework v8.6.1 Release Documentation

**Release Date**: September 30, 2026  
**Release Type**: Patch  
**Previous Release**: v8.6.0  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.6.1 is a **patch** on v8.6.0. It corrects `XCUIElement.platformTap` so the XCUI call matches what that SDK actually declares. v8.6.0 shipped a helper that repeated single clicks on macOS and documented the wrong platform mapping.

`next` since the v8.6.0 tag contains only this fix ([#510](https://github.com/schatt/sixlayer/issues/510)). Docs prep: [#537](https://github.com/schatt/sixlayer/issues/537).

This file does not claim the suite was run for a release until the release script's test gate passes.

---

## 🆕 New in this tag (since v8.6.0)

### platformTap follows XCUI availability (#510)

`tap(withNumberOfTaps:numberOfTouches:)` exists only when `(TARGET_OS_IOS || TARGET_OS_WATCH) && !TARGET_OS_MACCATALYST`. The v8.6.0 helper did the opposite on watchOS, claimed that API for tvOS and visionOS, and treated a macOS double-tap as two separate `click()` calls. `PlatformXCUITapStrategy` recorded that mapping and the unit tests only asserted the enum.

`platformTap(numberOfTaps:numberOfTouches:)` now switches on `PlatformTapCall.plan`:

- iOS and watchOS: `tap(withNumberOfTaps:numberOfTouches:)`, or `tap()` when both counts are 1.
- macOS: `click()` or `doubleClick()`. A tap count above 2, or `numberOfTouches > 1`, fails the test. Repeating `click()` is not a double-click. A single macOS activation stays `click()` (#516).
- visionOS: `tap()` or `doubleTap()`. `tapWithNumberOfTaps` is not in that SDK.
- tvOS: fails the test. `tap` is `API_UNAVAILABLE(tvos)`. Use `XCUIRemote`.

`PlatformTapCallTests` observe the plan. The iOS TestKit target typechecks `tap(withNumberOfTaps:)`. watchOS, tvOS, and visionOS are still not TestKit build targets, so those `#if` bodies are not compiled in this repo's package.

---

## ⚠️ Migration / consumer notes

### TestKit API (#510)

`XCUIElement.platformTap(numberOfTaps:numberOfTouches:)` keeps the same signature.

`PlatformXCUITapStrategy` is removed. Call sites that named that enum will not compile. Switch on `PlatformTapCall` if you need the chosen XCUI call.

`platformTap(numberOfTaps: 2)` on macOS is one `doubleClick()`, not two `click()` calls. A third tap or a multi-touch request fails the test instead of silently ignoring `numberOfTouches`.

Bump SixLayerTestKit to **8.6.1** before relying on cross-platform double-tap.

---

## ✅ Resolved GitHub issues (milestone v8.6.1)

- **[Issue #510](https://github.com/schatt/sixlayer/issues/510)** — `platformTap` matches XCUIAutomation availability. Reopened after the v8.6.0 delivery, fixed, merged to `next` as `93191da32`.
- **[Issue #537](https://github.com/schatt/sixlayer/issues/537)** — Prepare and cut this v8.6.1 patch through `release-process.sh`.
