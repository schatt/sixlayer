# AI Agent Guide - SixLayer Framework v8.7.0

**Version**: v8.7.0  
**Release Date**: October 21, 2026  
**Release type**: Minor (on v8.6.7)  
**Primary issues**: [#576](https://github.com/schatt/sixlayer/issues/576), [#581](https://github.com/schatt/sixlayer/issues/581), [#585](https://github.com/schatt/sixlayer/issues/585), [#563](https://github.com/schatt/sixlayer/issues/563), [#574](https://github.com/schatt/sixlayer/issues/574), [#577](https://github.com/schatt/sixlayer/issues/577)

## 🎯 What's in v8.7.0

- **Seven-segment OCR:** `OCRProcessingMode.ssocr` decodes digits and marks. `processImage` does not create a Vision text request. `processStructuredExtraction` adds one label pass unless `suppliedLabelFragments` is set. Default `processingMode` stays `.accurate` (#576).
- **Hints:** pass the unwrapped model type to `DataIntrospectionEngine.hintsModelName(for:)`. Do not look up `Optional<T>`. `DataBinder.init` and `bind` are public (#581, #585).
- **Vision:** resume through `runVisionRequest`. The first claim wins. Do not resume a Vision continuation from both the completion and `perform` (#563, #574, #578, #579).
- **Catalog:** `Localizable.xcstrings` is curated (`extractionState: manual`). Do not hand-add keys and expect a build to translate them (#577).
- **UITests:** activate macOS controls with `platformTap`, including generated snippets (#567, #575, #586, #587).

## Agent notes

- Do **not** vendor ssocr or Imlib2. The decoder is `SevenSegmentOCR.decode`.
- Do **not** put fuel-purchase field names in the segment decoder. Label binding is geometric.
- Do **not** treat `.ssocr` as a Vision recognition level. `.fast`, `.standard`, `.accurate`, and `.neural` are unchanged.
- Segment confidence is the worst segment fragment. Label confidence is ignored there. `extractionConfidence` stays the required-field ratio.
- The secondary-platform capability spine did not land in this minor. Do not document v8.7.0 as that spine.

## References

- [RELEASE_v8.7.0.md](RELEASE_v8.7.0.md)
- [AI_AGENT_v8.6.0.md](AI_AGENT_v8.6.0.md) — prior minor baseline
- [AI_AGENT.md](AI_AGENT.md) — version index
