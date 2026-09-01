# SixLayer Framework v8.3.7 Release Documentation

**Release Date**: September 1, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.6  
**Status**: Released

---

## 🎯 Release Summary

v8.3.7 is a **patch** release focused on:

1. **SPM `from:` pins** — ViewInspector is a versioned dependency on `schatt/ViewInspector` 0.10.4 so consumers can pin SixLayer with `from:` instead of a revision ([#438](https://github.com/schatt/sixlayer/issues/438)). Switch back to nalexn when they tag a GeometryProxy-safe release ([#439](https://github.com/schatt/sixlayer/issues/439)).
2. **Inspect-safe identifier and theme resolution** — identifier generation and HIG/theme tokens no longer read SwiftUI `Environment` in unhosted inspect bodies, which was flooding xcresults with Environment warnings ([#435](https://github.com/schatt/sixlayer/issues/435)).
3. **OCR hint regex** — currency symbols, capture groups, reverse separators, and glued currency no longer break colon/equals matches; extraction is locked against concurrent hint compiles ([#420](https://github.com/schatt/sixlayer/issues/420), [#430](https://github.com/schatt/sixlayer/issues/430)).
4. **Test and CI hygiene** — tautological expects removed ([#382](https://github.com/schatt/sixlayer/issues/382)); secondary-platform AllTests and CI destination/disk/bootstrap fixes ([#398](https://github.com/schatt/sixlayer/issues/398), [#416](https://github.com/schatt/sixlayer/issues/416)–[#417](https://github.com/schatt/sixlayer/issues/417), [#429](https://github.com/schatt/sixlayer/issues/429)–[#432](https://github.com/schatt/sixlayer/issues/432)).

---

## 🆕 Confirmed in v8.3.7 (implemented)

### **SPM version pins / ViewInspector fork (#438)**

ViewInspector was a **branch** dependency (`nalexn` `0.10.4`), so SwiftPM refused stable→unstable edges: consumers could not use `.package(..., from:)` on SixLayer and had to pin by revision.

- Temporary pin: `schatt/ViewInspector` `from: "0.10.4"` (tag at `f110d97`, same GeometryProxy-safe line as nalexn PR 421).
- Do **not** use nalexn tagged **0.10.3** (iOS 27 GeometryProxy SIGTRAP, #408).
- Do **not** use nalexn **branch** `0.10.4` (stable→unstable SPM rule).
- Switch back when nalexn publishes a GeometryProxy-safe semver tag (#439).

### **Identifier config and theme without Environment (#435)**

ViewInspector `inspect()` evaluates modifier/view bodies unhosted. Reading `@Environment` there flooded xcresults with “Accessing Environment… outside of being installed on a View”.

- `AccessibilityIdentifierConfig.resolvedForIdentifierGeneration()` uses task-local then `.shared`; modifiers no longer read `@Environment(\.accessibilityIdentifierConfig)`.
- HIG reduce-motion / system-zoom preferences resolve without Environment in inspect paths.
- `UnhostedInspection` selects inspect vs hosted branches; `ThemePreference` / `ThemeTokens` snapshot theme for inspect-safe reads. Hosted path still writes Environment via `ThemedFrameworkView`.
- Parallel tests isolate theme via `ThemePreference.withTestOverride` (not suite serialization).

### **OCR hint regex (#420, #430)**

Currency symbols in `ocrHints` were interpolated into regex character classes and blocked colon/equals label matches. Follow-up: capture groups, reverse separators, glued currency, and an extract lock so hint compiles do not race.

### **Mac Catalyst DataScanner (#415) and scanner session errors (#418)**

VisionKit `DataScanner` (and document camera) are gated off Mac Catalyst. Session scanner errors report `scannerNotAttached` only; capability stays on `RuntimeCapabilityDetection`.

### **Capability matrix vs this-host runtime (#428)**

The capability matrix must not treat “platform can have touch” as “this host has touch at runtime”. Tests and production detection use this-host runtime, not a static platform possibility bit.

### **Tautological expects and VI suite relocation (#382, #398, #401, #421, #427)**

`#expect(Bool(true))` / `#expect(Bool(false))` (and equivalent XCTest tautologies) are gone; assertions observe real values. Remaining VI-gated Accessibility suites moved after #395. iOS unit tests that #382 had locked to macOS-only observations were restored. `EnvironmentVariableDebugTests` inspect failures on iOS 27 are fixed. ViewInspector CI residual tracking after #396 is closed for this milestone.

### **CI / secondary platforms (#410, #416, #417, #429, #431, #432)**

- #410 explored split `build-for-testing` / `test-without-building` on Xcode 27; v8.3.6 already kept a single `xcodebuild test` (#411). Documented here because the issue closed on this milestone.
- Self-hosted Mini CI reclaims derived data, xcresults, and simulator **clones** before disk-full exit 73 (#416) without `simctl delete` of clone simulators (#417).
- `xcodebuild destination name=` was forcing `OS:latest` and missing 26.5 tvOS/watchOS/visionOS sims (#429); remaining secondary AllTests failures after that fix (#431).
- Framework CI: xctest bootstrap retry plus Gitea artifact CA trust (#432).

### **iOS ViewInspector compile (#419)**

`SLFiOSViewInspectorTests` SwiftCompile failure on `next` is fixed.

---

## ⚠️ Migration / consumer notes

### SPM `from:` (#438)

Consumers can pin SixLayer with a version requirement again:

```swift
.package(url: "https://github.com/schatt/sixlayer.git", from: "8.3.7")
```

Do not pin SixLayer by revision solely because of ViewInspector. Transitive ViewInspector is `schatt/ViewInspector` 0.10.4 until #439.

### Identifier / theme Environment (#435)

Inspect-evaluated code must not instantiate `@Environment` / `@StateObject` for identifier config or theme. Use `resolvedForIdentifierGeneration()`, `ThemePreference.current`, or `UnhostedInspection`. Public EnvironmentKeys remain for ABI; dummy `resolved*(environmentValue:)` wrappers that discarded args were removed.

### OCR hints with currency symbols (#420, #430)

Hints that include `$` / other currency glyphs no longer poison label `:` / `=` matching. If you relied on the old broken match behavior, re-check extraction for fields whose hints mix currency and separators.

### Mac Catalyst (#415)

Do not expect VisionKit DataScanner or document camera on Mac Catalyst; those paths are gated off.

---

## ✅ Resolved GitHub issues (milestone v8.3.7)

- **[Issue #438](https://github.com/schatt/sixlayer/issues/438)** — SPM: version pins fail while ViewInspector is a branch dependency; pin `schatt/ViewInspector` 0.10.4.
- **[Issue #435](https://github.com/schatt/sixlayer/issues/435)** — Stop reading `AccessibilityIdentifierConfig` (and related HIG/theme) from SwiftUI Environment during identifier generation / unhosted inspect.
- **[Issue #432](https://github.com/schatt/sixlayer/issues/432)** — Harden self-hosted Framework CI: xctest bootstrap retry + Gitea artifact CA.
- **[Issue #431](https://github.com/schatt/sixlayer/issues/431)** — Remaining tvOS/visionOS/watchOS AllTests failures after #429.
- **[Issue #430](https://github.com/schatt/sixlayer/issues/430)** — OCR hint regex: capture groups, reverse separators, glued currency, extract lock.
- **[Issue #429](https://github.com/schatt/sixlayer/issues/429)** — CI `xcodebuild destination name=` forces OS:latest; misses 26.5 secondary sims.
- **[Issue #428](https://github.com/schatt/sixlayer/issues/428)** — Capability matrix must not equate platform touch-possible with this-host runtime.
- **[Issue #427](https://github.com/schatt/sixlayer/issues/427)** — `EnvironmentVariableDebugTests` ViewInspector inspect failures on iOS 27.
- **[Issue #421](https://github.com/schatt/sixlayer/issues/421)** — Restore iOS unit tests that #382 locked from macOS-only observations.
- **[Issue #420](https://github.com/schatt/sixlayer/issues/420)** — OCR hint regex: currency symbol in `ocrHints` blocks colon/equals matches.
- **[Issue #419](https://github.com/schatt/sixlayer/issues/419)** — iOS ViewInspectorTests SwiftCompile failure on `next`.
- **[Issue #418](https://github.com/schatt/sixlayer/issues/418)** — Session scanner errors: `scannerNotAttached` only; capability via RCD.
- **[Issue #417](https://github.com/schatt/sixlayer/issues/417)** — Do not `simctl`-delete clone simulators in sixlayer CI reclaim.
- **[Issue #416](https://github.com/schatt/sixlayer/issues/416)** — Self-hosted CI (Mini): reclaim derived data, xcresults, and simulator clones before disk-full exit 73.
- **[Issue #415](https://github.com/schatt/sixlayer/issues/415)** — Gate VisionKit DataScanner (and document camera) off Mac Catalyst.
- **[Issue #410](https://github.com/schatt/sixlayer/issues/410)** — Release gate: explore build-for-testing then test-without-building on Xcode 27 (superseded for invoke by #411 in v8.3.6).
- **[Issue #401](https://github.com/schatt/sixlayer/issues/401)** — ViewInspector CI: confirm green after #396; residual VI target breakage.
- **[Issue #398](https://github.com/schatt/sixlayer/issues/398)** — Relocate remaining VI-gated / tautological Accessibility suites after #395.
- **[Issue #382](https://github.com/schatt/sixlayer/issues/382)** — Eliminate tautological `Bool(true)` / `Bool(false)` test expects.
- **[Issue #440](https://github.com/schatt/sixlayer/issues/440)** — Prepare v8.3.7 release (docs / `--docs`).

### Also landed on `next` (not on this milestone)

- **#436** OCR L1 task cancellation / host-teardown resident-size logging.
- **#434** stall-drain EAGAIN; **#433** macOS ViewInspector CI stall seconds.
- **#422** macOS optimization manager tests (real tests, not stubs).
- **#402** wire or remove layered-testing suite.

**Not in this release:** [#437](https://github.com/schatt/sixlayer/issues/437) (required iOS/macOS tests green after #435) remains open on **v8.3.8**.

---

## 📚 References

- [RELEASE_v8.3.6.md](RELEASE_v8.3.6.md) — Previous patch.
- [RELEASES.md](RELEASES.md) — Release history index.
- [#439](https://github.com/schatt/sixlayer/issues/439) — Switch ViewInspector pin back to nalexn when they tag.
