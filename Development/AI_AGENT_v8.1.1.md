# AI Agent Guide - SixLayer Framework v8.1.1

**Version**: v8.1.1  
**Release type**: Patch (on v8.1.0)  
**Primary issues**: [#330](https://github.com/schatt/sixlayer/issues/330), [#331](https://github.com/schatt/sixlayer/issues/331)

## 🎯 What's in v8.1.1

Patch for **window / container resize** and **adaptive app-nav sidebar content**:

- **App nav column (#330):** single-sidebar width budget; `appNavigationSidebarColumnSizing` + `navigationSplitViewColumnWidth`; leave fullSplit when icon-rail + detail cannot fit.
- **App nav content (#331):** prefer `platformPresentManagedAppNavigation_L1` / `platformManagedAppNavigation_L4` with `AppNavigationPaneDescriptor`; `ManagedAppNavigationPaneList` steps labeled → compact → icon-only from `activeSidebarRenderingProfile` / `\.navigationSidebarRenderingProfile`. ViewBuilder L1/L4 remains the escape hatch.
- **Cards (#330):** width-capped columns on mac/pad; flexible L4 frames; sparse height tracks viewport; dense scrolls.

Still use **[AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md)** for ViewInspector 0.10 / TestKit guidance.

## Agent notes

- Do not assume `resolveAppNavigationShell` matches `resolveSettingsContainer` — app-nav is single sidebar; settings remains nested.
- For labeled app-nav lists, default to the managed descriptor path (#331); do not invent custom icon-rail chrome when descriptors suffice.
- Card layout decisions come from GeometryReader width **and** height; fixed card frames were removed in L4 for #330.
- Prefer documenting consumer impact in [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md).

## References

- [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md)
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — prior minor baseline
- [README_Layer1_Semantic.md](../Framework/docs/README_Layer1_Semantic.md) — managed vs ViewBuilder examples
