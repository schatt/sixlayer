# AI Agent Guide - SixLayer Framework v8.6.0

**Version**: v8.6.0  
**Release Date**: September 28, 2026  
**Release type**: Minor (on v8.5.1)  
**Primary issues**: [#403](https://github.com/schatt/sixlayer/issues/403), [#486](https://github.com/schatt/sixlayer/issues/486), [#507](https://github.com/schatt/sixlayer/issues/507), [#508](https://github.com/schatt/sixlayer/issues/508), [#522](https://github.com/schatt/sixlayer/issues/522)–[#525](https://github.com/schatt/sixlayer/issues/525), plus primary-lane coverage clusters (#452, #468–#470, #490, #491, #499, #503, #510–#521)

## 🎯 What's in v8.6.0

- **File upload:** use `FileUploadValidation` for type/size gates; drop load identifiers follow `allowedTypes`; browse opens `platformFileImporter` (#403, #522, #525).
- **Rich text:** `RichTextFormatting.apply` + `RichTextToolbar(text:selectedText:)` for bold/italic/underline/lists (#523). Do not treat format buttons as placeholders.
- **Forms:** `GenericFormView` packing honors `FormStrategy.fieldLayout` (#486).
- **Modals:** `platformAlert` / `platformConfirmationDialog` take `isPresented` and actually present (#507). Migrate off the old `Alert.Button` signature.
- **Settings window:** `platformDismissWindowSettings` must not close the macOS key window on apply; dismiss from Done / `onClose` (#508).
- **TestKit:** prefer `XCUIElement.platformTap` for cross-platform multi-tap (#510).
- **Honesty:** a11y label tests assert resolved catalog values, not `!isEmpty` (#503). SPM logic-lane tests stay free of `BaseTestClass` (#512).

## Agent notes

- Do **not** reintroduce `selectFiles` stubs or drop paths that ignore `allowedTypes`.
- Do **not** document `platformAlert` as presentable while wiring `.constant(false)`.
- Do **not** soft-skip hosted interaction tests when a control is missing (#524).
- Example Sources live under `Framework/Examples/` (#465, #490) — do not put demo shells back in Framework Sources.
- Epic #426 / secondary-platform host apps stay on later milestones (v8.7.0 / Full Tests).

## References

- [RELEASE_v8.6.0.md](RELEASE_v8.6.0.md)
- [AI_AGENT_v8.5.0.md](AI_AGENT_v8.5.0.md) — prior minor baseline
- [AI_AGENT.md](AI_AGENT.md) — version index
