# SixLayer Framework v8.5.1 Release Documentation

**Release Date**: September 20, 2026  
**Release Type**: Patch  
**Previous Release**: v8.5.0  
**Status**: Prepared (docs); tagging is the `--release` gate

---

## 🎯 Release Summary

v8.5.1 is a **patch** on v8.5.0. It ships adaptive compact date+time stacking, form packing spacing, SPM `.xcstrings` resolution for copied catalogs, and CI/XCUI destination plus SD150 harness fixes.

1. **Adaptive compact date+time (#481, #498)** — `platformDateTimeInput` splits compact date and time into two pickers that sit side-by-side when they fit and stack when they do not; theming datetime uses the same path.
2. **IntelligentFormView packing spacing (#492)** — packed field spacing comes from `FieldLayout.formContainerSpacing` instead of a hardcoded 16.
3. **SPM catalog resolution (#500)** — `InternationalizationService` parses copied `Localizable.xcstrings` when compiled `.strings` are absent, so SPM consumers see framework strings instead of raw keys. Tests assert translated values (#501, #502).
4. **CI destinations and SD150 harness (#495–#497)** — tvOS/watchOS/visionOS and perf-doc destinations go through `ensure-ci-simulator-destination`; iOS SD150 form XCUI no longer QuickPath-types into fields.

Some v8.5.1 milestone issues were already in the **v8.5.0 tag** (DatePicker titles, form-strategy consumption, self-hosted CI iOS dest). They are listed below so the milestone is complete; they are not new in this tag.

---

## 🆕 New in this tag (since v8.5.0)

### **Adaptive compact date+time (#481)**

On iOS/macOS/visionOS, `platformDateTimeInput` (used by `DynamicDateTimeField` and packed fuel Date) hosts `ViewThatFits(in: .horizontal)`:

- Child 0: `HStack` of compact `.date` and `.hourAndMinute` pickers with `fixedSize(horizontal: true)` so a compressed row does not count as fitting.
- Child 1: `VStack` fallback (date above time).
- One shared `Binding<Date>` across both pickers.
- Empty DatePicker titles + VoiceOver label from #478 stay in place.
- tvOS/watchOS still render text (unchanged). No new public types.

### **Theming datetime stacking (#498)**

Internal `ThemedDateTimeField` delegates to `platformDateTimeInput` instead of a combined `[.date, .hourAndMinute]` compact picker. `ThemedGenericFormView` remains a commented-out deprecated path; the live renderer is the internal field.

### **IntelligentFormView packing spacing (#492)**

Packed `spacing` is `FieldLayout.formContainerSpacing` (compact 8, horizontal 12, spacious/grid 20, standard/adaptive/vertical 16). `generatePackedFieldsLayout` takes required `spacingLayout` separately from density `fieldLayout`. Packing density (`maxItemsPerRow`) remains #488 (not this tag).

### **SPM `.xcstrings` resolution (#500)**

SPM ships `Localizable.xcstrings` via `.copy`. Compiled `.strings` are absent, so `getLocalizedString` used to return the key (CarManager saw `"Camera"` / `"Library"` as raw keys).

- Parse the catalog JSON when compiled strings are missing; keep SPM `.copy` (do not switch to `.process`).
- Cache by `bundle.bundlePath` with a negative `.missing` entry so recycled `Bundle` addresses cannot serve the wrong catalog.
- Lookup: requested locale → English/source language → key. Never return an unrequested language.

No new public API. `localizedString` / `frameworkLocalizedString` / `appLocalizedString` now resolve copied catalogs.

### **Honest localization tests (#501, #502)**

- **#501** — catalog-resolution tests assert the translated value via `FrameworkCatalogFixture`, not `!result.isEmpty`. A missing catalog cannot pass by returning the key.
- **#502** — drop tautological format/comment/override tests that still passed when the loader was wrong. `FrameworkCatalogFixture.formatted` rejects non-`%@` specifiers.

### **Simulator destinations (#495, #496)**

tvOS/watchOS/visionOS `buildconfig` destinations and `TEST_PERFORMANCE_ANALYSIS.md` iOS destinations go through `ensure-ci-simulator-destination.sh` (same class as #494 for iOS).

### **SD150 platformForm XCUI harness (#497)**

`test150_platformForm_integrationMultipleControls` failed because iOS keyboard `swipeDown` was QuickPath-typing into Form fields.

- Dismiss via keyboard Done (`SD150_KeyboardDone`) or form drag — never swipe the keyboard surface.
- SecureField `typeText` requires that field `hasKeyboardFocus`.
- iOS Form Switch accessibility frames span the row; tap the trailing thumb, not center/label.

No public API changes (TestApp host + XCUI helpers).

---

## ⚠️ Migration / consumer notes

### SPM string catalogs (#500)

If you consume SixLayer via SPM and saw raw localization keys in UI (photo source labels, etc.), bump to **8.5.1**. You do not need to copy framework keys into the app catalog for those defaults. App overrides still win when the app catalog actually contains the key.

### Compact date+time layout (#481)

No API change. Compact datetime fields now split into two pickers and stack when the proposed width cannot fit both. If you depended on a single combined compact DatePicker chrome, update snapshots / XCUI queries.

### IntelligentFormView packing spacing (#492)

Call sites of `generatePackedFieldsLayout` must pass `spacingLayout` (density `fieldLayout` is separate). Internal unless you were calling the generator from tests.

### Not in this tag

- **[#499](https://github.com/schatt/sixlayer/issues/499)** — macOS CI UITests fail to open TestApp host (v8.5.2).
- **[#503](https://github.com/schatt/sixlayer/issues/503)** — accessibility-label tests still use `!isEmpty`.
- **[#467](https://github.com/schatt/sixlayer/issues/467)** — Layer4 component zeros (in progress).
- **[#488](https://github.com/schatt/sixlayer/issues/488)** — IntelligentFormView packing density.

---

## ✅ Resolved GitHub issues (milestone v8.5.1)

### New in this tag

- **[Issue #481](https://github.com/schatt/sixlayer/issues/481)** — Stack compact date+time when the proposed width cannot fit both pills.
- **[Issue #492](https://github.com/schatt/sixlayer/issues/492)** — IntelligentFormView packing hardcodes spacing 16 instead of `formContainerSpacing`.
- **[Issue #495](https://github.com/schatt/sixlayer/issues/495)** — Align tvOS/watchOS/visionOS buildconfig destinations with ensure script.
- **[Issue #496](https://github.com/schatt/sixlayer/issues/496)** — Update `TEST_PERFORMANCE_ANALYSIS.md` iOS destinations to ensure script.
- **[Issue #497](https://github.com/schatt/sixlayer/issues/497)** — Fix SD150 `platformForm` integration XCUITest failure.
- **[Issue #498](https://github.com/schatt/sixlayer/issues/498)** — Route ThemingIntegration datetime through `platformDateTimeInput` stacking.
- **[Issue #500](https://github.com/schatt/sixlayer/issues/500)** — `InternationalizationService` cannot resolve `Localizable.xcstrings` shipped via SPM `.copy`.
- **[Issue #501](https://github.com/schatt/sixlayer/issues/501)** — InternationalizationService tests still pass when the loader returns the raw key.
- **[Issue #502](https://github.com/schatt/sixlayer/issues/502)** — Localization tests still pass without observing formatting or comments.
- **[Issue #504](https://github.com/schatt/sixlayer/issues/504)** — Prepare v8.5.1 patch release (docs / `--docs`).

### Already in v8.5.0 (still on this milestone)

These landed on `next` before the v8.5.0 tag and were not listed in [RELEASE_v8.5.0.md](RELEASE_v8.5.0.md). Behavior is already in 8.5.0; this patch documents them.

- **[Issue #478](https://github.com/schatt/sixlayer/issues/478)** — `DynamicDateTimeField` shows DatePicker title; squeezes into one-letter wrap in a wide band.
- **[Issue #482](https://github.com/schatt/sixlayer/issues/482)** — `ModalFormView` ignores `PresentationHints` for form container.
- **[Issue #483](https://github.com/schatt/sixlayer/issues/483)** — `platformFormContainer_L4` ignores `FormStrategy.validation`.
- **[Issue #484](https://github.com/schatt/sixlayer/issues/484)** — `determineOptimalFormLayout_L2` ignores `presentationPreference` and complexity.
- **[Issue #493](https://github.com/schatt/sixlayer/issues/493)** — Fix self-hosted `next` CI reds (iOS dest, macOS UI tap, visionOS timeout, watchOS Vision).
- **[Issue #494](https://github.com/schatt/sixlayer/issues/494)** — Align buildconfig/release iOS destinations with `ensure-ci-simulator-destination`.

---

## 📚 References

- [RELEASE_v8.5.0.md](RELEASE_v8.5.0.md) — Previous minor.
- [RELEASES.md](RELEASES.md) — Release history index.
- [#499](https://github.com/schatt/sixlayer/issues/499) — macOS CI UITests host (v8.5.2; not in this release).
