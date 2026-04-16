# AI Agent Guide - SixLayer Framework v7.6.0

**Version**: v7.6.0  
**Release Date**: April 16, 2026  
**Release Type**: Minor

---

## 🎯 What's in v7.6.0

Minor release with release-facing documentation for managed settings adoption (Issue #215). This release adds explicit migration guidance for teams moving from manual `selectedCategory` routing to managed top-level flow APIs.

### **Key Points for AI Agents**

1. **No breaking changes to the public API for this release** — v7.6.0 remains backward compatible with v7.5.x for typical consumers; migration guidance targets composition patterns (managed top-level state vs manual optional selection).
2. **Same architecture** — Layer 1–6 patterns, PhotoPurpose, `platformFrame`, and hints file behavior are unchanged unless a project was relying on undocumented routing shortcuts.
3. **Managed settings path** — Prefer `PlatformManagedSettingsTopLevelState` and `platformManagedSettingsTopLevel_L4` when adopting the managed shell. Combine with Layer 1 sidebar callbacks by mapping keys to typed pane IDs and routing through `PlatformManagedSettingsFlowLogic.selectTopLevelPane` so selection and detail-depth reset stay synchronized.
4. **When in doubt** — Read [`Framework/docs/ManagedPlatformSettingsFlowGuide.md`](../Framework/docs/ManagedPlatformSettingsFlowGuide.md) and the compile-checked example in `Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation/ManagedPlatformSettingsFlowGuideExampleTests.swift`. For unrelated topics, use the main [AI_AGENT.md](AI_AGENT.md) index and [AI_AGENT_v7.5.0.md](AI_AGENT_v7.5.0.md) for the v7.5 minor baseline, plus patch release notes linked from that index.

---

## 🔗 Related Documentation

- [RELEASE_v7.6.0.md](RELEASE_v7.6.0.md) — Release notes and migration summary  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index

---

**For complete framework documentation, see [AI_AGENT.md](AI_AGENT.md)**
