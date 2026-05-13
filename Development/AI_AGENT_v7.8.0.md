# AI Agent Guide - SixLayer Framework v7.8.0

**Version**: v7.8.0  
**Release Date**: May 13, 2026  
**Release Type**: Minor

---

## 🎯 What's in v7.8.0

v7.8.0 extends **presentation profiles** and **collection** behavior (Issue **#277**), adds **list** layout for card-style item collections with an explicit contract (**#272**), introduces an optional **draft storage key** separate from `DynamicFormConfiguration.id` (**#273**), expands **PlatformImage** EXIF read/write configuration (**#275**), and tightens **system-action** handling for `openURL` and remote notifications (**#256**, closing **#169** gaps).

### Key points for AI agents

1. **Presentation profiles**: Prefer `PresentationProfilesCatalog` / bundled `Hints/PresentationProfiles.hints` over duplicating profile defaults in app code.
2. **Sparse grids**: Respect hint-driven **card height** and **content alignment** when tuning collection layouts.
3. **List vs cards**: When the API offers a list-style path for card-like items, read the presentation contract and tests before forcing a legacy layout.
4. **Form drafts**: If multiple forms share an `id`, or drafts must be isolated, configure the **optional draft storage key** explicitly.
5. **EXIF**: Use **PlatformImage** EXIF helpers and `PlatformImageEXIFConfig` (HEIC defaults) instead of manual `Data` metadata surgery when possible.
6. **System actions**: Route **openURL** and **remote notification** flows through the updated contract surfaces; do not bypass with ad hoc `UIApplication` calls that skip framework checks.

---

## 🔗 Related docs

- [RELEASE_v7.8.0.md](RELEASE_v7.8.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
