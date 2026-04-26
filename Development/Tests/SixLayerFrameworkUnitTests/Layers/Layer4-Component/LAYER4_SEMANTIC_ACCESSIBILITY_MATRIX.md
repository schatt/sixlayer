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
| `platformCloudKitAccountStatus_L4` | Y (informative + iCloud label) | N/A | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitAccountStatus_L4_exposesInformativeSemanticSurface` |
| `platformCloudKitServiceStatus_L4` | Y (composite informative) | N/A (default idle host); Y when syncing subtree | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitServiceStatus_L4_hostedEmitsIdentifiersAndInformativeSurface` |
| `platformCloudKitStatusBadge_L4` | Y (image / progress-like) | N/A | N/A | `PlatformCloudKitComponentsLayer4ComponentAccessibilityTests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformCloudKitStatusBadge_L4_idle_exposesImageOrInformativeSemanticSurface`, `…_syncing_exposesProgressOrImageSemanticSurface` |
| `platformNavigationTitle_L4` | Y (`.header` or readable navigation chrome) | N/A | Partial (title order) | `Layer4UITests` + navigation tests | `Layer4SemanticAccessibilityCriterionTests.testPlatformNavigationTitle_L4_exposesHeaderTraitWithSixLayerIdentifier` |
| `platformNavigationTitleDisplayMode_L4` | Y (inherits header surface on iOS when chained) | N/A | N/A | `Layer4UITests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformNavigationTitleDisplayModeInline_preservesHeaderSemantics` (iOS) |
| `platformNavigationBarTitleDisplayMode_L4` | TBD (alias of title display mode on bar API) | N/A | N/A | `Layer4UITests` | Same hosted pattern as `platformNavigationTitleDisplayMode_L4`; add row-level test when distinct surface is required. |
| `platformNavigationLink_L4` (binding + `navigationDestination`) | Y (`.link`) | N/A | N/A | `Layer4UITests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformNavigationLink_L4_bindingStyle_exposesLinkSemanticsWithSixLayerIdentifier` |
| `platformNavigationButton_L4` | Y (`.button` + hint on iOS bar item host) | N/A | N/A | `Layer4UITests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformNavigationButton_L4_exposesButtonTraitHintsAndSixLayerIdentifier` (iOS) |
| `platformSheet_L4` / `platformPopover_L4` | TBD | N/A | N/A | `Layer4UITests` | UITest presentation contracts. |
| `platformImplementNavigationStack_L4` | Y (navigation chrome / header or titled surface) | N/A | N/A | `Layer4UITests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformImplementNavigationStack_L4_exposesHostedSemanticSurface` |
| `platformImplementNavigationStackItems_L4` | TBD | N/A | Partial (list order) | TBD | List read order → coordinate with #255 VoiceOver. |
| `platformRowActions_L4` / `platformContextMenu_L4` | TBD | N/A | N/A | `Layer4UITests` / row-action hosts | UITest + future hosted trait pass. |
| `platformPhotoPicker_L4` / `platformPhotoDisplay_L4` / camera APIs | TBD | TBD | N/A | `Layer4UITests`, `PlatformPhotoComponentsLayer4*` | Media controls often `.button` / `.image`; add per-surface. |
| `platformMapView_L4` / `platformMapViewWithCurrentLocation_L4` | TBD | TBD | N/A | `PlatformMapComponentsLayer4*` | MapKit hosting; semantic pass when CI map host stable. |
| `platformShare_L4` / `platformPrint_L4` | Y (`.button` on trigger host) | N/A | N/A | `PlatformSharePrintLayer4ComponentAccessibilityTests`, `Layer4UITests` | `Layer4SemanticAccessibilityCriterionTests.testPlatformShare_L4_exposesButtonTraitWithSixLayerIdentifier`, `…testPlatformPrint_L4_exposesButtonTraitWithSixLayerIdentifier` |
| `platformCopyToClipboard_L4` | N/A (non-View function) | N/A | N/A | `Layer4UITests` (`L4ContractCopy`) | Covered as behavioral non-View action; keep outside view-semantic trait scope. |
| `platformVerticalSplit_L4` / `platformHorizontalSplit_L4` | TBD | N/A | Partial | `PlatformSplitViewLayer4Tests` | Split pane read order → #255. |
| `platformStyledContainer_L4` | TBD | N/A | N/A | styling / card tests | Containers often N/A for standalone traits. |
| `platformFormContainer_L4` / form field APIs | TBD | TBD | Partial | `Layer4UITests`, form ViewInspector suites | Values on controls (pickers, toggles) → extend hosted checks. |
| `platformAppNavigation_L4` / `platformSettingsContainer_L4` | TBD | N/A | Partial | UITest / navigation hosts | Large surface; staged. |

**Maintenance:** When adding a hosted semantic test, flip the row from **TBD** to **Y** with the test symbol name. Keep **Sort / read order** honest: unit tests rarely prove rotor order—**#255** owns assistive-tech verification.
