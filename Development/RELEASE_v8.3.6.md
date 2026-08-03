# SixLayer Framework v8.3.6 Release Documentation

**Release Date**: TBD  
**Release Type**: Patch (planned)  
**Previous Release**: v8.3.5  
**Status**: Draft — accumulate notes while landing milestone work; finalize at release prep.

---

## 🎯 Release Summary

v8.3.6 is a **patch** release. Entries below are seeded as issues land; expand before tagging.

---

## ⚠️ Migration / consumer notes

### ResponsiveGrid accessibility identifier shape (#395)

`ResponsiveGrid` now applies `.automaticCompliance(named: "ResponsiveGrid")` instead of anonymous `.automaticCompliance()`.

- **Why:** Anonymous compliance on `LazyVGrid` often yields no observable ID when cells are not materialized (secondary unit lanes / incomplete layout).
- **Consumer impact:** Generated accessibility identifiers for `ResponsiveGrid` now include the `ResponsiveGrid` name segment (e.g. `…ResponsiveGrid…`) instead of relying solely on child content IDs.
- **Action:** If UI tests or tooling matched anonymous / `main.ui.element`-style IDs for grid shells, update queries to the named form.

Commit: `663eb97c` on `wip/395-relocate-vi-preferring-suites` (lands with #395).

---

## ✅ Resolved GitHub issues (v8.3.6)

- **[Issue #395](https://github.com/schatt/sixlayer/issues/395)** — Relocate VI-preferring / ComponentAccessibility suites after secondary-lane observation; `ResponsiveGrid` named compliance for observable IDs. *(close when LRC complete)*

*(Add further closed milestone issues here as they land.)*

---

## 📚 References

- [RELEASE_v8.3.5.md](RELEASE_v8.3.5.md) — Previous patch.
- [RELEASES.md](RELEASES.md) — Release history index.
