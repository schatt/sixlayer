# SixLayer Framework v8.3.3 Release Documentation

**Release Date**: July 21, 2026  
**Release Type**: Patch  
**Previous Release**: v8.3.2  
**Status**: Released

---

## 🎯 Release Summary

v8.3.3 is a **patch** release focused on:

1. **`.exactNamed` host-sentinel parity** with `.named` ([#364](https://github.com/schatt/sixlayer/issues/364)) — container `.exactNamed` no longer overwrites nested EmptyState* / row contract accessibility identifiers (same overwrite class fixed for `.named` in [#360](https://github.com/schatt/sixlayer/issues/360)).

---

## 🆕 Confirmed in v8.3.3 (implemented)

### **ExactNamedModifier host-sentinel (#364)**

- `ExactNamedModifier` previously applied bare `accessibilityIdentifier` on content.
- When `.exactNamed` wrapped a collection / empty-state surface, nested hint ids (EmptyStateTitle, EmptyStateCreateButton, etc.) were lost under XCUI query — same failure mode as `.named` before #360.
- **Fix:** attach via `accessibilityHostIdentifier` (background sentinel), matching `NamedModifier`.
- UITest: `emptyWrapExact1` deep-link section mirrors emptyWrap1 with `.exactNamed` on the container; nested hint ids remain queryable.
- Leaf `.exactNamed` contract ids remain queryable via XCUI descendants (Layer5 leaf regression covered during #364).

---

## ✅ Resolved GitHub issues (milestone v8.3.3)

- **[Issue #364](https://github.com/schatt/sixlayer/issues/364)** — `ExactNamedModifier` should use host-sentinel like `.named` (#360).
- **[Issue #365](https://github.com/schatt/sixlayer/issues/365)** — Prepare v8.3.3 release (docs / `--docs`).

---

## ⚠️ Migration / consumer notes

- Prefer **`.exactNamed`**, **`.named`**, or **`accessibilityHostIdentifier`** on destination roots and scroll hosts instead of raw `accessibilityIdentifier` when nested EmptyState* / row contract ids must stay queryable.
- Identifier **string** from `.exactNamed` is unchanged (exact name only); only the attachment site moved to the host sentinel.
- **SPM consumers** (e.g. CarManager) should bump to **v8.3.3** if they apply `.exactNamed` on containers that must keep nested contract ids.

---

## 📚 References

- [RELEASE_v8.3.2.md](RELEASE_v8.3.2.md) — Previous patch (empty-state host-sentinel + present destination).
- [RELEASES.md](RELEASES.md) — Release history index.
- CarManager [#757](https://github.com/schatt/CarManager/issues/757)
