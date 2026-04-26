# SixLayer Framework v7.7.1 Release Documentation

**Release Date**: April 26, 2026  
**Release Type**: Patch  
**Previous Release**: v7.7.0  
**Status**: Released

---

## 🎯 Release Summary

v7.7.1 restores an accessibility runtime contract regression for consumer apps: explicit list container identifiers must remain discoverable in UI tests when composed with named accessibility modifiers (Issue #257). This patch also includes release-lane test stability adjustments uncovered while validating the fix.

---

## 🆕 Confirmed in v7.7.1 (implemented)

### **Issue #257 runtime contract verification**

- Added/validated runtime repro coverage for explicit list identifiers in UI-test paths.
- Confirmed `v7.7.0` regression behavior and validated green contract on `b7/b7.7.1` head.
- Preserved deterministic UI-test query contract for explicit list identifiers used by consumer apps.

### **Release-lane test stabilization**

- Relaxed host-specific negatives in platform capability matrix checks for non-touch lanes where host/runtime capabilities can vary by SDK/hardware.
- Hardened Layer 4 semantic accessibility criteria tests to gate trait assertions on hosted semantic tree availability.

---

## ✅ Resolved GitHub issues

- **Issue #257** — Explicit list accessibility identifier runtime contract regression addressed and release-validated.

---

## 🔗 References

- [RELEASE_v7.7.0.md](RELEASE_v7.7.0.md) — Previous minor release.
- [RELEASES.md](RELEASES.md) — Release history index.
