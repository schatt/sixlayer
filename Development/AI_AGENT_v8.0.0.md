# AI Agent Guide - SixLayer Framework v8.0.0

**Version**: v8.0.0  
**Release Date**: June 4, 2026  
**Release Type**: Major

---

## 🎯 What's in v8.0.0

v8.0.0 ships **Layer 4 app navigation chrome**: navigation sheet toolbar leading control with **phone / detailOnly visibility** (#323), **sidebar reveal chrome** for split detail-only layouts (#324), and **iOS automatic vs explicit detailOnly** handling (#325) shared across reveal policy, sheet button visibility, and L4 split presentation sync. Also ships **`platformMenu` SwiftUI `Menu` on iOS** (#321), replacing the legacy iOS no-op from #62.

### Key points for AI agents

1. **Navigation sheet visibility:** Use `PlatformNavigationSheetButtonVisibilityPolicy` on `platformNavigationSheetButton` — prefer `.phoneOrDetailOnly` for standard phone/CarPlay/detailOnly behavior. Apps keep toolbar placement; framework owns visibility via pure `shouldShow` policy (#323).
2. **Toolbar leading helper:** Use `platformAppNavigationSheetToolbarLeading` for the navigation sheet / sidebar toggle in app navigation toolbars; wire `showingNavigationSheet` per `platformAppNavigation_L4` docs.
3. **Sidebar reveal chrome:** When using `platformAppNavigation_L4` with a `columnVisibility` binding, L4 auto-applies `platformSidebarSplitRevealChrome` on detail (#324). iOS adds stripe + swipe overlay; macOS adds stripe only.
4. **iOS detailOnly detection:** Never compare `NavigationSplitViewVisibility == .detailOnly` alone on iOS — use framework helpers that honor `isExplicitDetailOnly` (automatic compares equal to detail-only on iOS) (#325).
5. **`platformMenu` on iOS:** All three overloads wrap SwiftUI `Menu` on iOS and macOS (#321). Do not assume the #62 iOS no-op; menus render for toolbar overflow and anchored actions.
6. **Out of scope here:** CarManager `ContentView` migration and UITest id preservation — consumer follow-up (CarManager #216).

---

## 🔗 Related docs

- [RELEASE_v8.0.0.md](RELEASE_v8.0.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
