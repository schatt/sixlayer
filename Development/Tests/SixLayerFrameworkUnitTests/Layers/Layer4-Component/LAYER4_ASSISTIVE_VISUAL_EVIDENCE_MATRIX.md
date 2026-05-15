# Layer 4 assistive-tech & visual adaptability matrix (Issue #255)

**Purpose:** Track **#255** evidence for View-returning `platform*_L4` surfaces: **VoiceOver**, **Switch Control**, **Dynamic Type**, **high contrast / differentiate without color**, and **iOS vs macOS** consistency.

**Status values:** `TBD` (not yet recorded) · `partial` (documented manual run or single-platform automation) · `UITest` (covered indirectly via `Layer4UITests` / host without explicit matrix sign-off) · `done` (explicit evidence linked in issue or PR).

| API | VoiceOver | Switch Control | Dynamic Type | High contrast | Cross-platform (iOS/macOS) | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `platformCloudKitSyncButton_L4` | partial | TBD | partial | TBD | partial | Semantic unit tests (`Layer4SemanticAccessibilityCriterionTests`); Dynamic Type id overlap (`Layer4AssistiveVisualAdaptabilityCriterionTests.testPlatformCloudKitSyncButton_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps`); full VO rotor → manual or UI test recording. |
| `platformCloudKitProgress_L4` | partial | TBD | partial | TBD | partial | Dynamic Type progress semantics (`Layer4AssistiveVisualAdaptabilityCriterionTests.testPlatformCloudKitProgress_L4_retainsProgressSemanticsAcrossDynamicTypeSteps`); VO “Adjustable” phrasing → manual. |
| `platformCloudKitSyncStatus_L4` | partial | TBD | partial | TBD | partial | Dynamic Type informative traits (`…testPlatformCloudKitSyncStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps`); color-only state → manual pass. |
| `platformCloudKitAccountStatus_L4` | partial | TBD | partial | TBD | partial | Dynamic Type iCloud informative surface (`…testPlatformCloudKitAccountStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps`); VO label copy → manual. |
| `platformCloudKitServiceStatus_L4` | partial | TBD | partial | TBD | partial | Dynamic Type SixLayer id overlap (`…testPlatformCloudKitServiceStatus_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps`); contrast of error/queue captions → manual. |
| `platformCloudKitStatusBadge_L4` | partial | TBD | partial (idle) | TBD | partial | Idle Dynamic Type informative traits (`…testPlatformCloudKitStatusBadge_L4_idle_retainsInformativeSemanticsAcrossDynamicTypeSteps`); syncing → manual or extend. |
| `platformShare_L4` / `platformPrint_L4` | partial | TBD | partial | TBD | partial | Share + print Dynamic Type button stability (`…testPlatformShare_L4_…`, `…testPlatformPrint_L4_retainsButtonSemanticsAcrossDynamicTypeSteps`). |
| Navigation / sheet / popover L4 APIs | UITest | TBD | TBD | TBD | partial | `Layer4UITests` exercises structure; macOS parity where scheme runs macOS UITests. |
| `platformVerticalSplit_L4` / `platformHorizontalSplit_L4` | partial | TBD | partial | TBD | partial | #254 hosted pane ids; #255 Dynamic Type pane stability (`Layer4AssistiveVisualAdaptabilityCriterionTests.testPlatformVerticalSplit_L4_paneMarkersSurviveLargeDynamicTypeHosting`); VO / Switch Control / high contrast still manual. |
| `platformPhotoPicker_L4` / `platformPhotoDisplay_L4` | partial | TBD | partial | TBD | partial | Picker + display Dynamic Type (`…testPlatformPhotoPicker_L4_…`, `…testPlatformPhotoDisplay_L4_retainsContractIdentifierAcrossDynamicTypeSteps`); #254 hosted semantics. |
| `platformCameraInterface_L4` / `platformCameraPreview_L4` | partial | TBD | TBD | TBD | partial | #254 named compliance on iOS hosted camera surfaces; hardware/permission flows → manual. |
| `platformMapView_L4` | partial | TBD | TBD | TBD | partial | #254 named compliance on hosted map; full VO / contrast → manual. |
| `platformRowActions_L4` / `platformContextMenu_L4` | partial | TBD | TBD | TBD | partial | #254 named compliance on hosted row/menu anchor; VO swipe/long-press → manual or UITest. |
| `platformMapViewWithCurrentLocation_L4` | partial | TBD | TBD | TBD | partial | #254 named compliance (`…testPlatformMapViewWithCurrentLocation_L4_exposesNamedComplianceOnHostedTree`); location permission flows → manual where needed. |
| `platformFormContainer_L4` / other form APIs | UITest / partial | TBD | TBD | TBD | partial | #254 inner id preservation on form container; per-field values staged. |

**How to close rows**

1. Prefer **automation** where stable: extend `Layer4UITests` or hosted unit tests with environment overrides (content size, contrast) when the host supports them without flaking.
2. Where automation is unreliable, attach **short manual checklist results** (date, OS build, device class) in **#255** comments and link here.
3. Update this table in the **same PR** as the evidence so the matrix stays authoritative.

**Related:** `LAYER4_SEMANTIC_ACCESSIBILITY_MATRIX.md` (#254), `L4_CONTRACT_INVENTORY.md` (UITest contracts), **#169** parent orchestration.
