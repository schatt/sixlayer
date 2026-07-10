# SixLayer Framework v8.1.1 Release Documentation

**Release Date**: TBD (prep on `next`)  
**Release Type**: Patch  
**Previous Release**: v8.1.0  
**Status**: Release prep (`next`)

---

## 🎯 Release Summary

v8.1.1 is a **patch** release focused on **window / container resize** for app navigation and intelligent card collections (**#330**). On macOS and iPad, shrinking the available width no longer crushes the app-nav sidebar into an unusable strip or parks a sticky minimum offscreen, and card collections reflow with the detail pane on **both axes** (columns and card size track the viewport; sparse content can grow; dense content scrolls).

Icon-only sidebar **content** (framework-owned adaptive rows) remains tracked separately as **#331**.

---

## 🆕 Confirmed in v8.1.1 (implemented)

### **App navigation sidebar column sizing (#330)**

- `platformAppNavigation_L4` / nested split host uses a **single-sidebar** width budget (`textSidebar` + minimum detail), distinct from nested settings (two sidebars + detail).
- Progressive `NavigationSplitColumnSizing` via `NavigationLayoutResolver.appNavigationSidebarColumnSizing(...)`: ideal shrinks with available width; min is the icon-rail floor so the column can shrink; returns `nil` when even icon-rail + detail cannot fit → leave `.fullSplit` (overlay / detail-only).
- Layer 4 applies SwiftUI `navigationSplitViewColumnWidth(min:ideal:max:)` on the sidebar column.
- New APIs: `NavigationSplitColumnSizing`, `layer4AppNavigationCompactPresentation(forAvailableWidth:)`, `layer4AppNavigationCompactPresentationForTransition(...)`.

### **Intelligent card collection resize (#330)**

- Layer 2 caps columns by available width on **mac** and **pad** (floor **1**); card width is a share of remaining space and may fall below the legacy 200pt preferred minimum when the pane is narrower.
- Sparse mac/pad grids grow or shrink card **height** with viewport share (up to a default max); dense grids keep intrinsic height and **scroll** instead of force-fitting all rows.
- Layer 4 expandable cards use flexible frames (`maxWidth: .infinity` + decision height) so `LazyVGrid` cells track the pane.

### **Tests**

- `IntelligentCardResize330Tests` — width-capped columns, sub-200 width, sparse/tall vs dense/short height, vertical-only resize, phone non-regression.
- `NavigationLayoutResolverAppNavigation330Tests` — single-sidebar vs nested settings budget, progressive column sizing, leave-fullSplit when budget fails.

---

## ✅ Resolved GitHub issues (milestone v8.1.1)

- **[Issue #330](https://github.com/schatt/sixlayer/issues/330)** — macOS/iPad resize: app nav sidebar crush; card collections ignore window/container resize (width + height).
- **[Issue #332](https://github.com/schatt/sixlayer/issues/332)** — Document v8.1.1 release notes (this documentation).

---

## ⚠️ Migration / consumer notes

- **App nav:** No host API change required for `platformAppNavigation_L4` ViewBuilder sidebars. Column width and compact presentation are framework-driven from container width.
- **Settings shells:** Nested settings budget is unchanged; only app-nav uses the single-sidebar resolver path.
- **Cards:** Hosts using `platformPresentItemCollection_L1` / intelligent card expansion get reflow automatically; no CarManager-local patches needed for column or card sizing.
- **Icon-only sidebar chrome:** Not in this release — see **#331** for a framework-owned adaptive sidebar API.
- **No intentional breaking public API changes** — patch release; additive resolver/sizing APIs and layout behavior fixes.

---

## 🔗 References

- [RELEASE_v8.1.0.md](RELEASE_v8.1.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v8.1.1.md](AI_AGENT_v8.1.1.md) — Version-specific agent guide (patch on v8.1.0).
- [Issue #331](https://github.com/schatt/sixlayer/issues/331) — Owned adaptive sidebar (icon-rail content).
