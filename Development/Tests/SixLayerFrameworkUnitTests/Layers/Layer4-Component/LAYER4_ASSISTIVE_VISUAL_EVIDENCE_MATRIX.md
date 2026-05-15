# Layer 4 assistive-tech & visual adaptability matrix (Issue #255)

**Purpose:** Track **#255** evidence for View-returning `platform*_L4` surfaces: **VoiceOver**, **Switch Control**, **Dynamic Type**, **high contrast / differentiate without color**, and **iOS vs macOS** consistency.

**Status values:** `TBD` (not yet recorded) · `partial` (documented manual run or single-platform automation) · `UITest` (covered indirectly via `Layer4UITests` / host without explicit matrix sign-off) · `done` (explicit evidence linked in issue or PR).

**Hosted automation (#255):** `Layer4AssistiveVisualAdaptabilityCriterionTests` — per-API Dynamic Type tests plus matrix sweeps (`testLayer4CloudKitFamily_…`, `testLayer4InteractionAndMediaSurfaces_…`, `testLayer4NavigationAndPresentation_…`, `testLayer4StructuralSurfaces_…`). Helpers in `AccessibilityTestUtilities.swift`: `hostedTreeHasVoiceOverDiscoverableNode`, `hostedTreeHasSwitchControlActivationCandidate`, `hostedTreesRetainOverlappingSixLayerAccessibilityKeys` (high contrast via UIKit `accessibilityContrast: .high` on hosting controller). **Not a substitute** for device VoiceOver rotor / real Switch Control sessions — see Notes column.

| API | VoiceOver | Switch Control | Dynamic Type | High contrast | Cross-platform (iOS/macOS) | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `platformCloudKitSyncButton_L4` | done | done | done | done | partial | Sweep + `…testPlatformCloudKitSyncButton_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps`. Rotor ordering → manual if needed. |
| `platformCloudKitProgress_L4` | done | done | done | done | partial | Sweep + `…testPlatformCloudKitProgress_L4_retainsProgressSemanticsAcrossDynamicTypeSteps`. |
| `platformCloudKitSyncStatus_L4` | done | done | done | done | partial | Sweep + `…testPlatformCloudKitSyncStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps`. |
| `platformCloudKitAccountStatus_L4` | done | done | done | done | partial | Sweep + `…testPlatformCloudKitAccountStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps`. |
| `platformCloudKitServiceStatus_L4` | done | done | done | done | partial | Sweep + `…testPlatformCloudKitServiceStatus_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps`. |
| `platformCloudKitStatusBadge_L4` | done | done | done | done | partial | Sweep + idle/syncing Dynamic Type tests. |
| `platformShare_L4` / `platformPrint_L4` | done | done | done | done | partial | Sweep + share/print Dynamic Type tests. |
| Navigation / sheet / popover L4 APIs | done | done | done | done | partial | `testLayer4NavigationAndPresentation_retainAssistiveTraversalUnderVisualAdaptabilityOverrides` + #254 semantic tests; `Layer4UITests` for live-app structure. macOS UITest lane when scheme runs. |
| `platformVerticalSplit_L4` / `platformHorizontalSplit_L4` | done | done | done | done | partial | Sweep (vertical + horizontal) + `…testPlatformVerticalSplit_L4_paneMarkersSurviveLargeDynamicTypeHosting`. |
| `platformPhotoPicker_L4` / `platformPhotoDisplay_L4` | done | done | done | done | partial | Sweep + picker/display Dynamic Type tests; #254 hosted semantics. |
| `platformCameraInterface_L4` / `platformCameraPreview_L4` | done | done | TBD | done | partial | Sweep (iOS hosted); permission/hardware flows → manual. No Dynamic Type criterion test yet. |
| `platformMapView_L4` | done | done | TBD | done | partial | Sweep uses MKMapView-under-contrast fallback (#254); full VO rotor → manual optional. |
| `platformRowActions_L4` / `platformContextMenu_L4` | done | done | TBD | done | partial | Structural sweep + #254 semantic tests; VO swipe/long-press → `Layer4UITests` when added. |
| `platformMapViewWithCurrentLocation_L4` | done | done | TBD | done | partial | Structural sweep + #254 named compliance; location permission → manual where needed. |
| `platformFormContainer_L4` | done | done | TBD | done | partial | Structural sweep + #254 form container semantic test. |
| `platformFormField` / `platformFormFieldGroup` | done | done | done (field) | done | partial | Field: sweep + Dynamic Type test; group: sweep + #254 semantic test. |
| `platformAppNavigation_L4` / `platformSettingsContainer_L4` | done | done | TBD | done | partial | Structural sweep + #254 sidebar/detail markers; split/stack VO behavior → UITest/manual as needed. |

**How to close rows**

1. Prefer **automation** where stable: extend `Layer4UITests` or hosted unit tests with environment overrides (content size, contrast) when the host supports them without flaking.
2. Where automation is unreliable, attach **short manual checklist results** (date, OS build, device class) in **#255** comments and link here.
3. Update this table in the **same PR** as the evidence so the matrix stays authoritative.

**Related:** `LAYER4_SEMANTIC_ACCESSIBILITY_MATRIX.md` (#254), `L4_CONTRACT_INVENTORY.md` (UITest contracts), **#169** parent orchestration.
