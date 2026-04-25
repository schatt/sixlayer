# Layer 4 semantic accessibility matrix (Issue #254)

**Purpose:** Map **View-returning** `platform*_L4` (and closely related Layer 4 contract surfaces) to **#254** criteria: accessibility **traits**, **values**, and **sort / read-order** applicability, with pointers to automated evidence.

**Legend**

- **Traits:** UIKit-hosted checks for `UIAccessibilityTraits` (or documented N/A when not meaningful on hosted subtree).
- **Value:** Non-empty `accessibilityValue` where state/progress matters.
- **Sort / read order:** `sortPriority` / VoiceOver rotor order — usually **N/A** in unit tests; defer explicit rotor ordering evidence to **#255** unless a test asserts `accessibilitySortPriority` / equivalent.
- **Identifier:** Existing identifier-generation tests (`testComponentComplianceSinglePlatform`, `Layer4UITests`, etc.).

**Non-View / out of scope for this matrix:** `platformOpenURL_L4`, `platformRegisterForRemoteNotifications_L4` → closed under **#256**.

| API | Traits | Value | Sort / read order | Identifier evidence | Semantic evidence (#254) |
| --- | --- | --- | --- | --- | --- |
| `platformCloudKitSyncButton_L4` | Y (`.button`) | N/A | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitSyncButton_L4_exposesButtonTraitWithSixLayerIdentifier` |
| `platformCloudKitProgress_L4` | Y (progress-like) | Y (when surfaced) | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitProgress_L4_exposesProgressSemanticsWithSixLayerIdentifier` |
| `platformCloudKitSyncStatus_L4` | Y (informative) | N/A | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitSyncStatus_L4_exposesInformativeTraitsWithContractIdentifier` |
| `platformCloudKitAccountStatus_L4` | TBD | TBD | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | Extend hosted semantic checks (same pattern as sync status). |
| `platformCloudKitServiceStatus_L4` | TBD | TBD | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | Extend hosted semantic checks. |
| `platformCloudKitStatusBadge_L4` | TBD | TBD | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | Extend hosted semantic checks. |
| `platformNavigationTitle_L4` / `platformNavigationBarTitleDisplayMode_L4` | TBD | N/A | Partial (title order) | `Layer4UITests` + navigation tests | Prefer UITest for bar chrome; sort order N/A unless custom `sortPriority`. |
| `platformNavigationLink_L4` | TBD | N/A | N/A | `Layer4UITests` | UITest navigation + identifier; traits follow `NavigationLink`. |
| `platformSheet_L4` / `platformPopover_L4` | TBD | N/A | N/A | `Layer4UITests` | UITest presentation contracts. |
| `platformImplementNavigationStack_L4` | TBD | N/A | N/A | `Layer4UITests` | UITest stack chrome. |
| `platformImplementNavigationStackItems_L4` | TBD | N/A | Partial (list order) | TBD | List read order → coordinate with #255 VoiceOver. |
| `platformRowActions_L4` / `platformContextMenu_L4` | TBD | N/A | N/A | `Layer4UITests` / row-action hosts | UITest + future hosted trait pass. |
| `platformPhotoPicker_L4` / `platformPhotoDisplay_L4` / camera APIs | TBD | TBD | N/A | `Layer4UITests`, `PlatformPhotoComponentsLayer4*` | Media controls often `.button` / `.image`; add per-surface. |
| `platformMapView_L4` / `platformMapViewWithCurrentLocation_L4` | TBD | TBD | N/A | `PlatformMapComponentsLayer4*` | MapKit hosting; semantic pass when CI map host stable. |
| `platformCopyToClipboard_L4` / `platformShare_L4` / `platformPrint_L4` | TBD | N/A | N/A | `PlatformSharePrintLayer4ComponentAccessibilityTests`, `Layer4UITests` | Buttons: add `.button` hosted checks mirroring CloudKit suite. |
| `platformVerticalSplit_L4` / `platformHorizontalSplit_L4` | TBD | N/A | Partial | `PlatformSplitViewLayer4Tests` | Split pane read order → #255. |
| `platformStyledContainer_L4` | TBD | N/A | N/A | styling / card tests | Containers often N/A for standalone traits. |
| `platformFormContainer_L4` / form field APIs | TBD | TBD | Partial | `Layer4UITests`, form ViewInspector suites | Values on controls (pickers, toggles) → extend hosted checks. |
| `platformAppNavigation_L4` / `platformSettingsContainer_L4` | TBD | N/A | Partial | UITest / navigation hosts | Large surface; staged. |

**Maintenance:** When adding a hosted semantic test, flip the row from **TBD** to **Y** with the test symbol name. Keep **Sort / read order** honest: unit tests rarely prove rotor order—**#255** owns assistive-tech verification.
