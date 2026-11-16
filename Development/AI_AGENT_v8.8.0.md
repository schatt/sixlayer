# AI Agent Guide - SixLayer Framework v8.8.0

**Version**: v8.8.0  
**Release Date**: November 16, 2026  
**Release type**: Minor (on v8.7.1)  
**Primary themes**: seven-segment OCR hardening, Live Photo capture/picker, platform chrome, `/2` land gate

## 🎯 What's in v8.8.0

- **OCR:** real/synthetic seven-segment regressions (glare, commas, edge chrome, crop geometry, adaptive ink). Private fixtures via `Development/scripts/fetch-private-fixtures.sh`; CI needs `SIXLAYER_FIXTURES_TOKEN`. OCR lab CLI for labeled folders (#677).
- **Camera / photos:** Live Photo–aware picker and camera paths (#668, #669). `platformCameraInterface_L4(onImageCaptured:)` exposes `onCancel` (#681).
- **Platform / forms:** `platformButton` overloads (#635); macOS NavigationStack sheet/nav alignment (#636–#639); `showsSubmitButton` (#640); Date draft honesty (#675, #676).
- **Process:** `/2` quality gate before land and in agent chat (#643, #656, #657, #663). CI destination / codesign / ViewInspector hygiene.

## Agent notes

- Do **not** skip the `/2` Quality Check before merging `wip/` into `next`. Paste the five headers in chat and on the issue.
- Do **not** vendor private fixture photos into the package. Fetch them; missing access soft-skips those tests.
- Do **not** treat pre-#672 `String(describing: Date)` form drafts as recoverable Dates.
- Prefer geometric OCR fixes over hard-coded peel thresholds; the other direction of a threshold needs a real input (#663, #664).

## References

- [RELEASE_v8.8.0.md](RELEASE_v8.8.0.md)
- [AI_AGENT_v8.7.0.md](AI_AGENT_v8.7.0.md) — prior minor baseline
- [AI_AGENT.md](AI_AGENT.md) — version index
