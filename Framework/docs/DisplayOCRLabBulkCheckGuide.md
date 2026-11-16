# Display OCR Lab Bulk Pass/Fail (#677)

Apple-only evaluation of a Display OCR training library against the **same SixLayer OCR entry points** an app uses (`OCRService` / `.ssocr`).

## What is scored

| Axis | When | Pass rule |
|---|---|---|
| **Structured** | `label.json` has `expectedStructuredFields` | Field ids match within production numeric tolerance (`0.01`); formula consistency when expected values themselves satisfy A×B≈C |
| **Localization** | OCR returns `chosenPanelRect` | IoU vs labeled `panel` ≥ `0.5` (configurable) |

Overall pass = all **scored** axes pass. Missing expectations or missing `chosenPanelRect` → skip that axis (not a fail).

## `label.json` additions

Backward-compatible with schema v1:

- `exampleId` — stable join key (assigned on write if missing)
- `additionalImageFileNames` — multi-image capable; primary remains `imageFileName`
- `expectedStructuredFields` — map of field id → expected string
- `entityName`, `fieldAverages`, `fieldAverageMaxPercentDeviation`, `fieldFractionDigits` — per-example `OCRContext` priors (not pass/fail targets)

`fieldAverages` are **external regional-at-that-time magnitudes**, distinct from `#678` fraction-digit format priors and `#679` deviation threshold.

## CLI

Scheme: `SLF-macOS-DisplayOCRLabBulkCheck`  
Product: `DisplayOCRLabBulkCheck`

```bash
DisplayOCRLabBulkCheck /path/to/display-ocr-training \
  --summary-out /tmp/ocr-summary.json \
  --baseline /tmp/prior-summary.json
```

| Exit | Meaning |
|---|---|
| `0` | All scored axes passed (and baseline clean if requested) |
| `1` | Scored failure or baseline regression |
| `2` | Usage / IO / unreadable invocation |

## Shared core (CLI + lab app)

- `DisplayOCRLabBulkCheck.runLibrary(at:)` — load library, app-mode OCR, summary
- `DisplayOCRLabBulkCheck.evaluate(...)` — score precomputed results
- `DisplayOCRLabBulkCheck.runAppMode(...)` — inject OCR for tests/spies
- `DisplayOCRLabEvaluation.score(...)` — dual-axis score for one example
- `OCRResult.chosenPanelRect` — original-image normalized panel used for decode

## Authoring assist

`DisplayOCRLabEvaluation.seedExpectedFields(fromConfirmedRows:)` returns an **editable draft** map.  
`authoringAssistAutoCommitsGroundTruth == false` — never silent ground truth.
