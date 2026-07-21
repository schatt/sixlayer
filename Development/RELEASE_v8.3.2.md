# SixLayer Framework v8.3.2 Release Documentation

**Release Date**: July 21, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.0  
**Status**: Released

> **Note:** Milestone **8.3.1** held release-script tag-guard work only (#356, #357) and was **not** tagged. Those tooling changes ship here with the product fixes below.

---

## 🎯 Release Summary

v8.3.2 is a **patch** release focused on:

1. **Empty-state accessibility identifiers** that survive collection wrappers and destination hosts ([#359](https://github.com/schatt/sixlayer/issues/359), [#360](https://github.com/schatt/sixlayer/issues/360)) — required for CarManager All Vehicles / empty-state UITests ([CarManager #757](https://github.com/schatt/CarManager/issues/757)).
2. **Cross-platform destination presentation** via `platformPresentDestination_L4` so callers are not stuck with `platformNavigationDestination_L4`’s silent macOS no-op ([#358](https://github.com/schatt/sixlayer/issues/358)).

---

## 🆕 Confirmed in v8.3.2 (implemented)

### **Empty-state hint a11y ids (#359 / #360)**

- Empty `platformPresentItemCollection_L1` with presentation-hint `createButtonAccessibilityIdentifier` / `emptyStateTitleAccessibilityIdentifier` keeps those ids queryable in XCUITest (skip named collection wrapper when empty + hint ids present).
- Container `accessibilityIdentifier` on destination wrappers (`.named`, Header / nav title, outer scroll hosts) was overwriting nested EmptyState* child ids.
- **Fix:** host-sentinel pattern — `.named` and Header `automaticCompliance` attach via background sentinel; new public `View.accessibilityHostIdentifier(_:)` for app scroll hosts and similar wrappers.
- Hint ids hardened as leaf accessibility elements; prefer-hints path still skips empty-state anonymous compliance.

### **platformPresentDestination_L4 (#358)**

- New L4 APIs: `platformPresentDestination_L4(isPresented:…)` and `platformPresentDestination_L4(item:…)`.
- Strategy: **iOS** → `navigationDestination` (push); **macOS / tvOS / watchOS / visionOS** → `platformSheet_L4`.
- `platformNavigationDestination_L4` remains the explicit push-only helper (macOS still no-op for that name by design).

### **Also on `next` since v8.3.0 (supporting)**

- Release tag existence guard as Step 1 of `release-process.sh` (#356, #357) — never shipped as a standalone **v8.3.1** tag.
- Omit empty tvOS / watchOS UITest targets from AllTests schemes (#353, #354; epic leftovers continue on **v8.4.0**).

---

## ✅ Resolved GitHub issues (milestone v8.3.2)

- **[Issue #360](https://github.com/schatt/sixlayer/issues/360)** — Bisect empty-state hint ids under destination wrappers; host-sentinel fix + `accessibilityHostIdentifier`.
- **[Issue #359](https://github.com/schatt/sixlayer/issues/359)** — Empty-state create/title hint ids lost under `platformPresentItemCollection_L1` wrapper.
- **[Issue #358](https://github.com/schatt/sixlayer/issues/358)** — `platformPresentDestination_L4` for cross-platform presentation (iOS push / others sheet).
- **[Issue #362](https://github.com/schatt/sixlayer/issues/362)** — Prepare v8.3.2 release (docs / `--docs`).

---

## ⚠️ Migration / consumer notes

- Prefer **`accessibilityHostIdentifier`** (or `.named`, which now uses the same sentinel) on destination roots and scroll hosts instead of raw `accessibilityIdentifier` when nested EmptyState* / row contract ids must stay queryable.
- Prefer **`platformPresentDestination_L4`** when one call site should present on both iOS and macOS; keep `platformNavigationDestination_L4` only when you intentionally want push-only (and accept macOS no-op).
- **SPM consumers** (e.g. CarManager) should bump to **v8.3.2** and switch scrollHost / similar wrappers to `accessibilityHostIdentifier` where they previously used container `accessibilityIdentifier` as a workaround.

---

## 📚 References

- [RELEASE_v8.3.0.md](RELEASE_v8.3.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.3.0.md](AI_AGENT_v8.3.0.md) — Prior minor agent baseline.
- CarManager [#757](https://github.com/schatt/CarManager/issues/757), [#740](https://github.com/schatt/CarManager/issues/740)
