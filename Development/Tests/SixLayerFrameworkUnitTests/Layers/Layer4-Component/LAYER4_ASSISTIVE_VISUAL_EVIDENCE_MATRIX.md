# Layer 4 assistive-tech & visual adaptability matrix (Issue #255)

**Purpose:** Track **#255** evidence for View-returning `platform*_L4` surfaces: **VoiceOver**, **Switch Control**, **Dynamic Type**, **high contrast / differentiate without color**, and **iOS vs macOS** consistency.

**Status values:** `TBD` (not yet recorded) · `partial` (documented manual run or single-platform automation) · `UITest` (covered indirectly via `Layer4UITests` / host without explicit matrix sign-off) · `done` (explicit evidence linked in issue or PR).

**Hosted automation (#255):** `Layer4AssistiveVisualAdaptabilityCriterionTests` — per-API Dynamic Type tests plus matrix sweeps (`testLayer4CloudKitFamily_…`, `testLayer4InteractionAndMediaSurfaces_…`, `testLayer4NavigationAndPresentation_…`, `testLayer4StructuralSurfaces_…`). Helpers in `AccessibilityTestUtilities.swift`: `hostedTreeHasVoiceOverDiscoverableNode`, `hostedTreeHasSwitchControlActivationCandidate`, `hostedTreesRetainOverlappingSixLayerAccessibilityKeys` (high contrast via UIKit `accessibilityContrast: .high` on hosting controller). **Not a substitute** for device VoiceOver rotor / real Switch Control sessions — see Notes column.

| API | VoiceOver | Switch Control | Dynamic Type | High contrast | Cross-platform (iOS/macOS) | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `platformCloudKitSyncButton_L4` | done | done | done | done | partial | `…testPlatformCloudKitSyncButton_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps` + sweep. Rotor ordering → manual if needed. |
| `platformCloudKitProgress_L4` | done | done | done | done | partial | `…testPlatformCloudKitProgress_L4_retainsProgressSemanticsAcrossDynamicTypeSteps` + sweep. |
| `platformCloudKitSyncStatus_L4` | done | done | done | done | partial | `…testPlatformCloudKitSyncStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps` + sweep. |
| `platformCloudKitAccountStatus_L4` | done | done | done | done | partial | `…testPlatformCloudKitAccountStatus_L4_retainsInformativeSemanticsAcrossDynamicTypeSteps` + sweep. |
| `platformCloudKitServiceStatus_L4` | done | done | done | done | partial | `…testPlatformCloudKitServiceStatus_L4_retainsSixLayerIdentifiersAcrossDynamicTypeSteps` + sweep. |
| `platformCloudKitStatusBadge_L4` | done | done | done | done | partial | Idle/syncing Dynamic Type tests + sweep. |
| `platformShare_L4` / `platformPrint_L4` | done | done | done | done | partial | Share/print Dynamic Type tests + sweep. |
| Navigation / sheet / popover L4 APIs | done | done | done | done | partial | Navigation sweep + nav-title Dynamic Type in `testLayer4NavigationAndPresentation_…`; #254 semantic tests; `Layer4UITests` for live-app structure. |
| `platformVerticalSplit_L4` / `platformHorizontalSplit_L4` | done | done | done | done | partial | `…testPlatformVerticalSplit_L4_paneMarkersSurviveLargeDynamicTypeHosting` + sweep (both orientations). |
| `platformPhotoPicker_L4` / `platformPhotoDisplay_L4` | done | done | done | done | partial | Picker/display Dynamic Type tests + sweep; #254 hosted semantics. |
| `platformCameraInterface_L4` / `platformCameraPreview_L4` | done | done | done | done | partial | `…testPlatformCameraInterface_L4_retainsSemanticsAcrossDynamicTypeSteps`, `…testPlatformCameraPreview_L4_retainsNamedComplianceAcrossDynamicTypeSteps` + sweep (iOS). Permission/hardware → manual. |
| `platformMapView_L4` | done | done | done | done | partial | `…testPlatformMapView_L4_retainsMapSubtreeAcrossDynamicTypeSteps` (MKMapView fallback) + sweep. Rotor → manual optional. |
| `platformRowActions_L4` / `platformContextMenu_L4` | done | done | done | done | partial | `…testPlatformRowActions_L4_retainsNamedComplianceAcrossDynamicTypeSteps`, `…testPlatformContextMenu_L4_retainsNamedComplianceAcrossDynamicTypeSteps` + sweep. |
| `platformMapViewWithCurrentLocation_L4` | done | done | done | done | partial | `…testPlatformMapViewWithCurrentLocation_L4_retainsNamedComplianceAcrossDynamicTypeSteps` + sweep; location permission → manual where needed. |
| `platformFormContainer_L4` | done | done | done | done | partial | `…testPlatformFormContainer_L4_retainsInnerIdentifiersAcrossDynamicTypeSteps` + sweep + #254 semantic test. |
| `platformFormField` / `platformFormFieldGroup` | done | done | done | done | partial | Field + group Dynamic Type tests + sweep + #254 semantic tests. |
| `platformAppNavigation_L4` / `platformSettingsContainer_L4` | done | done | done | done | partial | `…testPlatformAppNavigation_L4_retainsSidebarDetailMarkersAcrossDynamicTypeSteps`, `…testPlatformSettingsContainer_L4_retainsSidebarDetailMarkersAcrossDynamicTypeSteps` + sweep. |

**Matrix status (iOS hosted lane):** All criterion columns **done** for canonical inventory; **cross-platform** remains **partial** until macOS hosted/UITest parity is recorded.

**How to close rows**

1. Prefer **automation** where stable: extend `Layer4UITests` or hosted unit tests with environment overrides (content size, contrast) when the host supports them without flaking.
2. Where automation is unreliable, attach **short manual checklist results** (date, OS build, device class) in **#255** comments and link here.
3. Update this table in the **same PR** as the evidence so the matrix stays authoritative.

**Related:** `LAYER4_SEMANTIC_ACCESSIBILITY_MATRIX.md` (#254), `L4_CONTRACT_INVENTORY.md` (UITest contracts), **#169** parent orchestration.
