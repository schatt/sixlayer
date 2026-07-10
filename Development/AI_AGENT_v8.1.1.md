# AI Agent Guide - SixLayer Framework v8.1.1

**Version**: v8.1.1  
**Release type**: Patch (on v8.1.0)  
**Primary issues**: [#330](https://github.com/schatt/sixlayer/issues/330), [#315](https://github.com/schatt/sixlayer/issues/315)

## 🎯 What's in v8.1.1

Patch for **window / container resize** and **macOS ViewInspector parallel-test reliability**:

- **App nav:** single-sidebar width budget; `appNavigationSidebarColumnSizing` + `navigationSplitViewColumnWidth`; leave fullSplit when icon-rail + detail cannot fit.
- **Cards:** width-capped columns on mac/pad; flexible L4 frames; sparse height tracks viewport; dense scrolls.
- **Capability test hooks (#315):** `CapabilityTestOverrideBag` + `DefaultRuntimeCapabilityIsolationTrait` — `setTest*` overrides are task-local; parallel `@MainActor` tests must not use `Thread.current.threadDictionary` for capability simulation.
- **UITest Layer 4:** contract UI (photo picker, print/export stubs) belongs in the **test host** under `-UITesting`, not in framework production paths.

Still use **[AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md)** for ViewInspector 0.10 / TestKit guidance. Icon-only sidebar content is **#331** (landed on `next` after v8.1.1 prep; not in this release tag scope unless re-cut).

## Agent notes

- Do not assume `resolveAppNavigationShell` matches `resolveSettingsContainer` — app-nav is single sidebar; settings remains nested.
- Card layout decisions come from GeometryReader width **and** height; fixed card frames were removed in L4 for #330.
- **`setTest*` under parallel Swift Testing:** apply `DefaultRuntimeCapabilityIsolationTrait()` on suites that call capability overrides; only hard wall-clock limits are acceptable failures under contention — assertion/timeouts from stale overrides indicate a harness bug.
- Do not slim ViewInspector tests to avoid parallel load; fix isolation at the harness/framework layer.
- Prefer documenting consumer impact in [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md).

## References

- [RELEASE_v8.1.1.md](RELEASE_v8.1.1.md)
- [AI_AGENT_v8.1.0.md](AI_AGENT_v8.1.0.md) — prior minor baseline
- [RuntimeCapabilityDetectionGuide.md](../Framework/docs/RuntimeCapabilityDetectionGuide.md) — harness / `setTest*` isolation
