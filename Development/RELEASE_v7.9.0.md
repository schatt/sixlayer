# SixLayer Framework v7.9.0 Release Documentation

**Release Date**: May 31, 2026  
**Release Type**: Minor  
**Previous Release**: v7.8.9  
**Status**: Release prep (`b7/b7.9.0`)

---

## 🎯 Release Summary

v7.9.0 is a **minor** release focused on **HIG automatic compliance** (typography floors and system zoom), **intelligent card viewport/layout** (host hints, navigation chrome subtraction, content-aware height floor), **capability override test hygiene** (tri-state on controls, platform-aware precursors, matrix trim), **Sendable policy** completion, and **Epic #233** cross-platform compile/test stabilization. Patch slices from the v7.8.x line (#291–#299 and related) are included on the integration branch.

---

## 🆕 Confirmed in v7.9.0 (implemented)

### **HIG automatic compliance (#302, #303, #260)**

- Minimum typography floors with real `HIGComplianceTypographyTests`.
- System zoom API and real `HIGComplianceZoomTests`.
- Reduce Motion (#298) and Increase Contrast readable secondary (#299) remain on the branch from v7.8.9 work.

### **Intelligent card viewport and layout (#306–#309)**

- Card viewport **host hints**: chrome inset, max height, `preferFitInViewport`.
- Subtract navigation chrome from card collection viewport (#307, #308).
- **Content-aware floor** for intelligent card height when viewport clamp is not binding (#309).

### **Capability override testing (#251, #311, #312, #313)**

- Tri-state (current / disabled / enabled) capability testing on **controls** (#251).
- Platform-aware **precursor cascades** in public `setTest*` hooks (#311).
- Trim redundant platform matrix meta-tests; keep HIG consumer law only.
- `ConsolidatedAccessibilityTests` capability-override cleanup (#312).
- macOS card expansion touch ignores polluted `UserDefaults` when harness pins off (#313).

### **Sendable policy (#310)**

- Document and complete Sendable policy for framework types.

### **Layer 1 and presentation (#304, #272 area)**

- Fix Layer 1 presentation tests for compliance-wrapped view types (#304).

### **Accessibility and Layer 4 (#169, #254, #255, #290)**

- Semantic accessibility gaps for Layer 4 methods (#254).
- Assistive-tech and visual adaptability coverage (#255).
- Interactive element labels (#290).

### **Epic #233 compile / test stabilization (#234–#242, #271, #293)**

- Platform compile hygiene, availability gates, tvOS/watchOS/visionOS unblockers.
- iOS a11y identifier harness improvements (#242).
- Self-hosted CI compile fixes (#293).

### **Other milestone items**

- Cross-platform test parity — shared tests, explicit platform branches (#248).
- `PlatformTabStrip` public initializer (#292).
- OCR overlay Vision bounding boxes (#291).
- Dynamic Type typography APIs (#294, #295).
- Layer 4 export actions compose share + print (#300).
- Agent wip worktree checklist (#301, #280).
- Platform color hygiene (#276).

---

## ✅ Resolved GitHub issues (milestone v7.9.0)

- **[Issue #169](https://github.com/schatt/sixlayer/issues/169)** — Layer 4 platform accessibility completion (with #254, #255).
- **[Issue #234](https://github.com/schatt/sixlayer/issues/234)** — Epic #233 test matrix enumeration.
- **[Issue #237](https://github.com/schatt/sixlayer/issues/237)** — tvOS compile for AllTests.
- **[Issue #238](https://github.com/schatt/sixlayer/issues/238)** — watchOS navigation columns availability.
- **[Issue #239](https://github.com/schatt/sixlayer/issues/239)** — visionOS UIScreen availability.
- **[Issue #240](https://github.com/schatt/sixlayer/issues/240)** — Platform compile hygiene.
- **[Issue #241](https://github.com/schatt/sixlayer/issues/241)** — Availability gates in L4/L5 primitives.
- **[Issue #242](https://github.com/schatt/sixlayer/issues/242)** — iOS a11y identifier harness.
- **[Issue #248](https://github.com/schatt/sixlayer/issues/248)** — Shared tests, explicit platform branches.
- **[Issue #251](https://github.com/schatt/sixlayer/issues/251)** — Tri-state capability testing on controls.
- **[Issue #254](https://github.com/schatt/sixlayer/issues/254)** — Layer 4 semantic accessibility gaps.
- **[Issue #255](https://github.com/schatt/sixlayer/issues/255)** — Assistive-tech / visual adaptability coverage.
- **[Issue #259](https://github.com/schatt/sixlayer/issues/259)** — Layer4UITests expand affordance overlay contract.
- **[Issue #260](https://github.com/schatt/sixlayer/issues/260)** — HIGComplianceTypography/Zoom test failures fixed.
- **[Issue #271](https://github.com/schatt/sixlayer/issues/271)** — watchOS OCR/camera compile blockers.
- **[Issue #276](https://github.com/schatt/sixlayer/issues/276)** — Platform color hygiene.
- **[Issue #280](https://github.com/schatt/sixlayer/issues/280)** — Agent wip worktree checklist.
- **[Issue #290](https://github.com/schatt/sixlayer/issues/290)** — Labels on interactive elements.
- **[Issue #291](https://github.com/schatt/sixlayer/issues/291)** — OCR overlay Vision bounding boxes.
- **[Issue #292](https://github.com/schatt/sixlayer/issues/292)** — PlatformTabStrip public initializer.
- **[Issue #293](https://github.com/schatt/sixlayer/issues/293)** — Self-hosted CI compile fixes.
- **[Issue #294](https://github.com/schatt/sixlayer/issues/294)** — typographyScaleFactor / Font.scale tokens.
- **[Issue #295](https://github.com/schatt/sixlayer/issues/295)** — DynamicFont resolver API.
- **[Issue #298](https://github.com/schatt/sixlayer/issues/298)** — Reduce Motion for animation APIs.
- **[Issue #299](https://github.com/schatt/sixlayer/issues/299)** — Increase Contrast readable secondary.
- **[Issue #300](https://github.com/schatt/sixlayer/issues/300)** — platformExportActions_L4 share + print.
- **[Issue #301](https://github.com/schatt/sixlayer/issues/301)** — Git hook wip worktree dirt ignore.
- **[Issue #302](https://github.com/schatt/sixlayer/issues/302)** — HIG minimum typography floors.
- **[Issue #303](https://github.com/schatt/sixlayer/issues/303)** — HIG system zoom API.
- **[Issue #304](https://github.com/schatt/sixlayer/issues/304)** — Layer 1 compliance-wrapped view tests.
- **[Issue #306](https://github.com/schatt/sixlayer/issues/306)** — Card viewport host hints.
- **[Issue #307](https://github.com/schatt/sixlayer/issues/307)** — Subtract nav chrome from card viewport.
- **[Issue #308](https://github.com/schatt/sixlayer/issues/308)** — Subtract nav chrome from card viewport.
- **[Issue #309](https://github.com/schatt/sixlayer/issues/309)** — Content-aware intelligent card height floor.
- **[Issue #310](https://github.com/schatt/sixlayer/issues/310)** — Sendable policy.
- **[Issue #311](https://github.com/schatt/sixlayer/issues/311)** — Capability override precursors / matrix trim.
- **[Issue #312](https://github.com/schatt/sixlayer/issues/312)** — ConsolidatedAccessibilityTests cleanup.

---

## 📎 Additional resolved issues (not in v7.9.0 milestone)

- **[Issue #313](https://github.com/schatt/sixlayer/issues/313)** — macOS card config ignores polluted `UserDefaults` touch simulation when harness pins off.

---

## ⚠️ Migration / consumer notes

- **Capability tests:** Use tri-state assertions beside **controls** under test; trust platform detection for native capability reads (see `.cursor/rules/capability-override-test-flows.mdc`).
- **Card layout:** Host apps may pass viewport hints for intelligent card collections; content-aware height applies when viewport clamp is not binding.
- **Sendable:** Review new Sendable annotations if you wrap framework types in `@Sendable` closures across actors.
- **No intentional breaking public API changes** — minor release; review card viewport hint keys if you customize collection chrome.

---

## 🔗 References

- [RELEASE_v7.8.9.md](RELEASE_v7.8.9.md) — Previous patch release.
- [RELEASES.md](RELEASES.md) — Release history index.
- [AI_AGENT_v7.9.0.md](AI_AGENT_v7.9.0.md) — Version-specific agent guide.
