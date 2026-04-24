# SixLayer Framework v7.6.2 Release Documentation

**Release Date**: April 23, 2026  
**Release Type**: Patch  
**Previous Release**: v7.6.1  
**Status**: Released

---

## 🎯 Release Summary

Patch release improving **viewport-aware card layout** (GitHub **#249**, **#250**); fixing **Swift Testing isolation** for runtime capability overrides on the main actor (release gate / `supportsTouchWithOverride`); **tvOS** compile path for **`SLF-tvOS-AllTests`** and availability (**#237**); and **internal test harness** updates (**#247**, **#248**).

---

## 🆕 What's New

### **Layout (Issues #249, #250)**

- **#249** — `determineIntelligentCardLayout_L2` accepts optional `viewportHeight`; on **phone** with at most **two** grid rows, card height is capped from vertical budget. `ExpandableCardCollectionView` / `GridCollectionView` resolve height via `PlatformFrameHelpers.finiteViewportHeight(for:)` when geometry is non-finite.
- **#250** — `determineOptimalCardLayout_L2` accepts optional `viewportHeight`; `CardLayoutDecision` carries `viewportHeight` and **`cardRowHeight`** (default 120). Column count can widen when a finite height budget improves per-row height. **`ResponsiveCardsView`** passes resolved geometry into L2; **`ResponsiveCardView`** uses `rowHeight` from the layout decision (default 120 for other call sites).

### **Tests**

- **`DefaultRuntimeCapabilityIsolationTrait`** — Clears `RuntimeCapabilityDetection` / `CapabilityOverride` thread state on **MainActor** as well as the trait’s executor thread, so `@MainActor` tests do not inherit stale `testTouchSupport` from the main thread (fixes `RuntimeCapabilityDetectionTDDTests.testOverrideClearing` and similar release-suite flakes).
- **#247** — *Internal:* stop mutating `AccessibilityIdentifierConfig.shared` in tests; use task-local configs and environment overrides so parallel and host-driven suites stay isolated.
- **#248** — *Internal:* reduce mac/iOS test drift with shared cases and explicit platform branches where UI or capability behavior differs.

### **Platforms**

- **#237** — tvOS: `SixLayerFramework` builds for the **`SLF-tvOS-AllTests`** scheme (availability and call-site guards as needed).

---

## ✅ Resolved GitHub issues

- **Issue #249** — Intelligent expandable card collections: height considers viewport / display fallback, not width-only aspect ratio alone.
- **Issue #250** — Optimal responsive card layout + demo view: explicit height in Layer 2 and tests; `ResponsiveCardsView` wired to geometry.
- **Issue #237** — tvOS compile / test-target path for `SLF-tvOS-AllTests` (availability-aligned).
- **Issue #247** — *Internal:* accessibility identifier config isolation in tests (no shared global mutation).
- **Issue #248** — *Internal:* mac vs iOS test alignment (shared tests, explicit platform branches).

---

## ⚠️ Migration / consumer notes

- **`CardLayoutDecision`** gains optional fields with defaults; existing initializers remain source-compatible.
- **`determineOptimalCardLayout_L2`** gains trailing `viewportHeight: CGFloat? = nil`; omit for legacy width-only behavior.
- **Swift Package** consumers: bump `from: "7.6.2"` (or exact revision) after tagging.

---

## 🔗 References

- [RELEASE_v7.6.1.md](RELEASE_v7.6.1.md) — Previous patch (Layer 1 automaticCompliance / #245).
