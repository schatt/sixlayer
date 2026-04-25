# Layer 4 assistive-tech & visual adaptability matrix (Issue #255)

**Purpose:** Track **#255** evidence for View-returning `platform*_L4` surfaces: **VoiceOver**, **Switch Control**, **Dynamic Type**, **high contrast / differentiate without color**, and **iOS vs macOS** consistency.

**Status values:** `TBD` (not yet recorded) · `partial` (documented manual run or single-platform automation) · `UITest` (covered indirectly via `Layer4UITests` / host without explicit matrix sign-off) · `done` (explicit evidence linked in issue or PR).

| API | VoiceOver | Switch Control | Dynamic Type | High contrast | Cross-platform (iOS/macOS) | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `platformCloudKitSyncButton_L4` | partial | TBD | TBD | TBD | partial | Semantic unit tests on hosted UIKit (`Layer4SemanticAccessibilityCriterionTests`); full VO rotor → manual or UI test recording. |
| `platformCloudKitProgress_L4` | partial | TBD | TBD | TBD | partial | Progress/value exposure under automation; VO “Adjustable” phrasing → manual. |
| `platformCloudKitSyncStatus_L4` | partial | TBD | TBD | TBD | partial | Combined `Label` + contract identifier; color-only state should not be sole cue (verify in manual pass). |
| `platformCloudKitAccountStatus_L4` | partial | TBD | TBD | TBD | partial | Hosted semantic surface (`Layer4SemanticAccessibilityCriterionTests`); VO label copy → manual #255. |
| `platformCloudKitServiceStatus_L4` | partial | TBD | TBD | TBD | partial | Composite host + identifier sweep; contrast of error/queue captions → manual. |
| `platformCloudKitStatusBadge_L4` | partial | TBD | TBD | TBD | partial | Idle vs syncing hosted trait checks; Dynamic Type scaling → manual or snapshot policy. |
| Navigation / sheet / popover L4 APIs | UITest | TBD | TBD | TBD | partial | `Layer4UITests` exercises structure; macOS parity where scheme runs macOS UITests. |
| Photo / map / split / form L4 APIs | UITest / TBD | TBD | TBD | TBD | TBD | Staged: align with `PHYSICAL_DEVICE_TEST_REGISTRY.md` where hardware matters. |

**How to close rows**

1. Prefer **automation** where stable: extend `Layer4UITests` or hosted unit tests with environment overrides (content size, contrast) when the host supports them without flaking.
2. Where automation is unreliable, attach **short manual checklist results** (date, OS build, device class) in **#255** comments and link here.
3. Update this table in the **same PR** as the evidence so the matrix stays authoritative.

**Related:** `LAYER4_SEMANTIC_ACCESSIBILITY_MATRIX.md` (#254), `L4_CONTRACT_INVENTORY.md` (UITest contracts), **#169** parent orchestration.
