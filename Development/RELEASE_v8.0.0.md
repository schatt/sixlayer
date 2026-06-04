# SixLayer Framework v8.0.0 Release Documentation

**Release Date**: June 4, 2026  
**Release Type**: Major  
**Previous Release**: v7.9.0  
**Status**: Release prep (`next`)

---

## 🎯 Release Summary

v8.0.0 is a **major** release focused on **Layer 4 app navigation chrome**: navigation sheet toolbar leading control with **phone / detailOnly visibility** (#323), **sidebar reveal chrome** for split detail-only layouts (#324), and the **iOS automatic vs explicit detailOnly** visibility fix (#325) that keeps reveal chrome and sheet buttons aligned with measured split presentation (#208). Also ships **`platformMenu` SwiftUI `Menu` on iOS** (#321), superseding the legacy iOS no-op from #62. Includes SD150 integration test stabilization, compliance test harness consolidation, and integration-branch agent hook protection (#322).

---

## 🆕 Confirmed in v8.0.0 (implemented)

### **Navigation sheet toolbar leading control (#323)**

- `PlatformNavigationSheetButtonVisibilityPolicy` with `.phoneOrDetailOnly` visibility (phone, CarPlay, iPad/mac `.detailOnly`, macOS always for sidebar toggle).
- `platformNavigationSheetButton` extensions and `platformAppNavigationSheetToolbarLeading`.
- Documentation on `platformAppNavigation_L4` + `showingNavigationSheet` wiring.
- Unit and ViewInspector coverage for toolbar visibility API.

### **Sidebar reveal chrome (#324)**

- `PlatformSidebarRevealChromePolicy` for split-edge sidebar reveal when `NavigationSplitView` is detail-only.
- Generic L4 helper for apps using `platformAppNavigation_L4` with a `columnVisibility` binding.
- **iOS:** leading-edge stripe + narrow swipe overlay (80pt horizontal, 50pt vertical drift) sets visibility to `.all`.
- **macOS:** visual stripe only; system resize/toolbar handles reveal.
- **L4:** auto-applies `platformSidebarSplitRevealChrome` on detail when `columnVisibility` is provided.

### **iOS automatic vs detailOnly (#325)**

- `NavigationSplitViewVisibility.isExplicitDetailOnly` uses `== .detailOnly` plus Mirror `isAutomatic` on iOS, where automatic placement compares equal to detail-only.
- Shared helper in `NavigationSplitViewVisibility+ExplicitDetailOnly.swift` (DRY across policy, sheet button, L4 sync).

### **`platformMenu` SwiftUI Menu on iOS (#321)**

- All three `platformMenu` overloads (`content`, `label`, `title`) now wrap SwiftUI `Menu` on **iOS and macOS** — replaces the legacy iOS no-op passthrough from #62.
- Toolbar overflow, action sheets, and anchored menus now behave consistently across platforms.
- ViewInspector and audit-host coverage for Menu exposure on iOS (Issue #321).

### **Test and harness stabilization**

- SD150 deep Form scroll and secure-field typing stabilization.
- Shared compliance test harness for named modifier ID lookup and persistence tests.
- ViewInspector coverage for navigation sheet toolbar API.

### **Agent / integration tooling (#322)**

- Integration-branch edit protection hooks (`scripts/integration-branches.txt`; block Write/StrReplace on `main`/`next`).

---

## ✅ Resolved GitHub issues (milestone v8.0.0)

- **[Issue #323](https://github.com/schatt/sixlayer/issues/323)** — Navigation sheet toolbar leading control (phone / detailOnly).
- **[Issue #324](https://github.com/schatt/sixlayer/issues/324)** — Sidebar reveal chrome / split-edge gesture (L4).
- **[Issue #325](https://github.com/schatt/sixlayer/issues/325)** — iOS automatic vs detailOnly for sidebar reveal and sheet visibility.

---

## 📎 Additional resolved issues (not in v8.0.0 milestone)

- **[Issue #321](https://github.com/schatt/sixlayer/issues/321)** — `platformMenu` SwiftUI `Menu` on iOS (supersedes #62 no-op).
- **[Issue #322](https://github.com/schatt/sixlayer/issues/322)** — Integration-branch agent hook protection.

---

## ⚠️ Migration / consumer notes

- **Navigation sheet button:** Use `PlatformNavigationSheetButtonVisibilityPolicy.phoneOrDetailOnly` (or custom policy) on `platformNavigationSheetButton`; place toolbar leading items via `platformAppNavigationSheetToolbarLeading` rather than baking visibility into app toolbars manually.
- **Sidebar reveal:** Pass `columnVisibility` to `platformAppNavigation_L4` to receive automatic split reveal chrome on detail; omit only if the app owns chrome entirely.
- **iOS split visibility:** Do not rely on `== .detailOnly` alone on iOS — framework uses `isExplicitDetailOnly` internally; apps should pass explicit bindings where policy matters.
- **`platformMenu` on iOS:** Menus now render via SwiftUI `Menu` (#321). Remove any iOS workarounds that assumed the #62 no-op passthrough; all three overloads participate.
- **CarManager migration** for `ContentView` toolbar/reveal wiring remains a consumer follow-up (CarManager #216).

---

## 🔗 References

- [RELEASE_v7.9.0.md](RELEASE_v7.9.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.0.0.md](AI_AGENT_v8.0.0.md) — Version-specific agent guide.
