# Framework/Sources coverage inventory remesasure (#463)

**Tip SHA:** `d208e685e` (`next`)
**Generated (UTC):** 2026-09-08T00:15:24Z
**Schemes:** `SLF-iOS-UnitTests`, `SLF-macOS-UnitTests` with `-enableCodeCoverage YES`
**xcresult:** `/tmp/sixlayer-463/ios-cover/result.xcresult`, `/tmp/sixlayer-463/macos-cover/result.xcresult`

ViewInspectorTests remain **excluded** from unit schemes — 0% here can still mean VI-only coverage.

## Test run summary

| Lane | Result | Passed | Failed |
| --- | --- | --- | --- |
| iOS Simulator (`iPhone 17 Pro` id `2E5948F1-…`, OS 27.0) | Passed | ~2635 | 0 |
| macOS (arm64) | Failed | ~2617 | 1 (unrelated) |

macOS failure: `OCRLayer1TaskCancellationTests/testRepeatedVisualCorrectionHostTeardownKeepsResidentSizeBounded` (resident-size bound). Coverage still extracted.

## Platform L5/L6 (remesasure after #450 / #453–#458)

**Progress vs #450 snapshot:** zero-coverage L5/L6 files went from **19 → 0**. Placeholders removed; Messaging/Resource/SplitView/CrossPlatformOptimization now non-zero.

Residual L5/L6 **&lt;50%** on both lanes:
- `AccessibilityFeaturesLayer5.swift` (~14%)
- `IntelligentCardExpansionLayer6.swift` (~17%)
- `IntelligentCardExpansionLayer5.swift` (~43–46%)

### iOS

```
ios Simulator/unit coverage — platform L5/L6 filter
  14.5%     83    571  Framework/Sources/Layers/Layer5-Platform/AccessibilityFeaturesLayer5.swift
  17.3%     67    387  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer6.swift
  45.9%    111    242  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer5.swift
  53.7%    217    404  Framework/Sources/Layers/Layer6-Optimization/CrossPlatformOptimizationLayer6.swift
  71.3%    129    181  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift
  78.9%     15     19  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSNavigationStackEnhancementsLayer6.swift
  85.0%     17     20  Framework/Sources/Layers/Layer5-Platform/PlatformNavigationStackOptimizationsLayer5.swift
  85.0%     17     20  Framework/Sources/Layers/Layer5-Platform/PlatformSplitViewOptimizationsLayer5.swift
  96.2%     75     78  Framework/Sources/Layers/Layer5-Platform/PlatformResourceLayer5.swift
 100.0%     79     79  Framework/Sources/Layers/Layer5-Platform/PlatformMessagingLayer5.swift
 100.0%      3      3  Framework/Sources/Layers/Layer6-Optimization/PlatformNavigationStackEnhancementsLayer6.swift
 100.0%      3      3  Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSNavigationStackEnhancementsLayer6.swift

files: 12
zero coverage: 0
<50% coverage: 3
```

### macOS

```
macos unit coverage — platform L5/L6 filter
  13.4%     84    625  Framework/Sources/Layers/Layer5-Platform/AccessibilityFeaturesLayer5.swift
  16.6%     65    391  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer6.swift
  42.6%    103    242  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer5.swift
  53.7%    217    404  Framework/Sources/Layers/Layer6-Optimization/CrossPlatformOptimizationLayer6.swift
  59.5%     50     84  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift
  83.3%     15     18  Framework/Sources/Layers/Layer5-Platform/PlatformNavigationStackOptimizationsLayer5.swift
  83.3%     15     18  Framework/Sources/Layers/Layer5-Platform/PlatformSplitViewOptimizationsLayer5.swift
  96.1%     74     77  Framework/Sources/Layers/Layer5-Platform/PlatformResourceLayer5.swift
 100.0%     79     79  Framework/Sources/Layers/Layer5-Platform/PlatformMessagingLayer5.swift
 100.0%      3      3  Framework/Sources/Layers/Layer6-Optimization/PlatformNavigationStackEnhancementsLayer6.swift
 100.0%      3      3  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSNavigationStackEnhancementsLayer6.swift
 100.0%      9      9  Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSNavigationStackEnhancementsLayer6.swift

files: 12
zero coverage: 0
<50% coverage: 3
```

## Broader Framework/Sources (unit lane)

| Lane | Files | Zero | &lt;50% |
| --- | ---: | ---: | ---: |
| iOS | 253 | 76 | 59 |
| macOS | 251 | 76 | 59 |

**Both-lanes zero:** 74 files (~largest executable-line clusters below).

Do **not** re-spawn closed #422–#425, #444, #449, #453–#458. Do **not** duplicate open **#403** (`AdvancedFieldTypes.swift` is 0% / ~929 lines — tracked there).

### Largest both-lanes zero clusters (by exec lines)

| Cluster | ≈exec | Notes |
| --- | ---: | --- |
| `Extensions/Platform` examples + UI demo | ~4.7k | `PlatformUIExamples`, `PlatformColorExamples`, … |
| `Layers/Layer1-Semantic` | ~1.6k | DataFrame / OCR disambiguation / i18n / notification / security |
| `Layers/Layer4-Component` | ~1.4k | SplitView / Export / Lists / Styling / … |
| `Extensions/SwiftUI` | ~1.4k | Theming / LiquidGlass examples / modifiers |
| `Components/Views` | ~1.2k | Barcode overlay / ResponsiveLayout / OCR views |
| `Components/Forms` | ~1.1k | **#403** owns AdvancedFieldTypes; FormUsageExample is demo |
| `Extensions/Accessibility` | ~0.7k | `AppleHIGComplianceExamples` |
| `Components/Navigation` | ~0.5k | Sidebar / tab strip / helpers |

## Spawned gap issues

| Issue | Cluster |
| --- | --- |
| *(filled after create)* | |

## Related open (not re-spawned)

- **#403** — AdvancedFieldTypes unit / VI / XCUI
- **#445–#448**, **#451–#452** — product / secondary-platform (not pure coverage)
