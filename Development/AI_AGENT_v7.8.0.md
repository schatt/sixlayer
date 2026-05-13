# AI Agent Guide - SixLayer Framework v7.8.0

**Version**: v7.8.0  
**Release Date**: May 13, 2026  
**Release Type**: Minor

---

## 🎯 What's in v7.8.0

v7.8.0 ships a **presentation profiles** catalog (`PresentationProfilesCatalog`, bundled hints, profile-keyed `PresentationHints`) (**#277**), an **item collection presentation resolver** for `platformPresentItemCollection_L1` with optional **`rowVisualStyle` = `"card"`** list-row chrome (**#272**), an optional **draft storage key** separate from `DynamicFormConfiguration.id` (**#273**), **PlatformImage** EXIF read/write configuration (**#275**), and tighter **system-action** handling for `openURL` and remote notifications (**#256**, closing **#169** gaps).

### Key points for AI agents

1. **Presentation profiles**: Prefer `PresentationProfilesCatalog` / bundled `Hints/PresentationProfiles.hints` instead of duplicating defaults across model `.hints` files.
2. **Item collections**: Respect `ItemCollectionPresentationStrategyResolver` outcomes; read `README_Layer1_Semantic.md` for list vs collection semantics and the custom-list container trade-off.
3. **`rowVisualStyle`**: Treat `customPreferences["rowVisualStyle"] == "card"` as framework-provided row chrome on the **custom list** path only—hosts still own rich accessibility inside row content.
4. **Form drafts**: If multiple forms share an `id`, or drafts must be isolated, configure the **optional draft storage key** explicitly.
5. **EXIF**: Use **PlatformImage** EXIF helpers and `PlatformImageEXIFConfig` (HEIC defaults) instead of manual `Data` metadata surgery when possible.
6. **System actions**: Route **openURL** and **remote notification** flows through the updated contract surfaces; do not bypass with ad hoc `UIApplication` calls that skip framework checks.

---

## 🔗 Related docs

- [RELEASE_v7.8.0.md](RELEASE_v7.8.0.md) — Release notes  
- [AI_AGENT.md](AI_AGENT.md) — Main AI agent index  

---

**For full framework guidance, start at [AI_AGENT.md](AI_AGENT.md).**
