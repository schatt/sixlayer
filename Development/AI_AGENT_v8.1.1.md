# AI Agent Guide - SixLayer Framework v8.1.1

**Version**: v8.1.1  
**Release type**: Patch (on v8.1.0)  
**Primary issue**: [#330](https://github.com/schatt/sixlayer/issues/330)

## 🎯 What's in v8.1.1

Patch for **window / container resize**:

- **App nav:** single-sidebar width budget; `appNavigationSidebarColumnSizing` + `navigationSplitViewColumnWidth`; leave fullSplit when icon-rail + detail cannot fit.
- **Cards:** width-capped columns on mac/pad; flexible L4 frames; sparse height tracks viewport; dense scrolls.

Still use **[AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md)** for ViewInspector 0.10 / TestKit guidance. Icon-only sidebar content is **#331** (not in this release).

## Agent notes

- Do not assume `resolveAppNavigationShell` matches `resolveSettingsContainer` — app-nav is single sidebar; settings remains nested.
- Card layout decisions come from GeometryReader width **and** height; fixed card frames were removed in L4 for #330.
- Prefer documenting consumer impact in [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md).

## References

- [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md)
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — prior minor baseline
