# Platform L5/L6 coverage inventory (#450)

Generated from unit lanes with `-enableCodeCoverage YES`.
ViewInspectorTests are **excluded** from SLF-*-UnitTests (separate schemes) — 0% here can mean VI-only coverage.

## iOS
```
iOS Simulator unit coverage — platform L5/L6 filter
scheme: SLF-iOS-UnitTests  tests_passed≈2595  xcresult=/tmp/sixlayer-450/ios-cover/result.xcresult

   cov%    cov   exec  path
   0.0%      0    571  Framework/Sources/Layers/Layer5-Platform/AccessibilityFeaturesLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformInterpretationLayer5.swift
   0.0%      0     51  Framework/Sources/Layers/Layer5-Platform/PlatformKnowledgeLayer5.swift
   0.0%      0     45  Framework/Sources/Layers/Layer5-Platform/PlatformLoggingLayer5.swift
   0.0%      0     44  Framework/Sources/Layers/Layer5-Platform/PlatformMaintenanceLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformNotificationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOptimizationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOrchestrationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOrganizationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformPrivacyLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformProfilingLayer5.swift
   0.0%      0     49  Framework/Sources/Layers/Layer5-Platform/PlatformRecognitionLayer5.swift
   0.0%      0     78  Framework/Sources/Layers/Layer5-Platform/PlatformResourceLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformRoutingLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformSafetyLayer5.swift
   0.0%      0     20  Framework/Sources/Layers/Layer5-Platform/PlatformSplitViewOptimizationsLayer5.swift
   0.0%      0     40  Framework/Sources/Layers/Layer5-Platform/PlatformWisdomLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer6-Optimization/PlatformPerformanceLayer6.swift
   0.0%      0      3  Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSNavigationStackEnhancementsLayer6.swift
   2.3%      9    387  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer6.swift
   7.6%      6     79  Framework/Sources/Layers/Layer5-Platform/PlatformMessagingLayer5.swift
  28.5%    115    404  Framework/Sources/Layers/Layer6-Optimization/CrossPlatformOptimizationLayer6.swift
  45.9%    111    242  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer5.swift
  70.0%     14     20  Framework/Sources/Layers/Layer5-Platform/PlatformNavigationStackOptimizationsLayer5.swift
  71.3%    129    181  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift
  78.9%     15     19  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSNavigationStackEnhancementsLayer6.swift
 100.0%      3      3  Framework/Sources/Layers/Layer6-Optimization/PlatformNavigationStackEnhancementsLayer6.swift

files: 27
zero coverage: 19
<50% coverage: 4
```

## macOS
```
macOS unit coverage — platform L5/L6 filter
scheme: SLF-macOS-UnitTests  passed≈2577 failed=1  xcresult=/tmp/sixlayer-450/macos-cover/result.xcresult

   cov%    cov   exec  path
   0.0%      0    625  Framework/Sources/Layers/Layer5-Platform/AccessibilityFeaturesLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformInterpretationLayer5.swift
   0.0%      0     51  Framework/Sources/Layers/Layer5-Platform/PlatformKnowledgeLayer5.swift
   0.0%      0     45  Framework/Sources/Layers/Layer5-Platform/PlatformLoggingLayer5.swift
   0.0%      0     44  Framework/Sources/Layers/Layer5-Platform/PlatformMaintenanceLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformNotificationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOptimizationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOrchestrationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformOrganizationLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformPrivacyLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformProfilingLayer5.swift
   0.0%      0     49  Framework/Sources/Layers/Layer5-Platform/PlatformRecognitionLayer5.swift
   0.0%      0     77  Framework/Sources/Layers/Layer5-Platform/PlatformResourceLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformRoutingLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer5-Platform/PlatformSafetyLayer5.swift
   0.0%      0     18  Framework/Sources/Layers/Layer5-Platform/PlatformSplitViewOptimizationsLayer5.swift
   0.0%      0     40  Framework/Sources/Layers/Layer5-Platform/PlatformWisdomLayer5.swift
   0.0%      0     47  Framework/Sources/Layers/Layer6-Optimization/PlatformPerformanceLayer6.swift
   0.0%      0      3  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSNavigationStackEnhancementsLayer6.swift
   2.3%      9    391  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer6.swift
   7.6%      6     79  Framework/Sources/Layers/Layer5-Platform/PlatformMessagingLayer5.swift
  28.2%    114    404  Framework/Sources/Layers/Layer6-Optimization/CrossPlatformOptimizationLayer6.swift
  42.6%    103    242  Framework/Sources/Layers/Layer5-Platform/IntelligentCardExpansionLayer5.swift
  59.5%     50     84  Framework/Sources/Platform/iOS/Views/Extensions/PlatformIOSOptimizationsLayer5.swift
  66.7%     12     18  Framework/Sources/Layers/Layer5-Platform/PlatformNavigationStackOptimizationsLayer5.swift
 100.0%      3      3  Framework/Sources/Layers/Layer6-Optimization/PlatformNavigationStackEnhancementsLayer6.swift
 100.0%      9      9  Framework/Sources/Platform/macOS/Views/Extensions/PlatformMacOSNavigationStackEnhancementsLayer6.swift

files: 27
zero coverage: 19
```

## Notes
- macOS run: 1 unrelated failure `OCRLayer1TaskCancellationTests/testRepeatedVisualCorrectionHostTeardownKeepsResidentSizeBounded` (resident-size bound); coverage still extracted.
- Already covered / do not re-spawn: #422–#425, #444; iOS L5 optimizations file at ~71% iOS / ~60% macOS.
- Related product issues (not coverage): #446, #447, #448, #449, #451, #452.

## Spawned gap issues

| Issue | Cluster |
| --- | --- |
| **#453** | Placeholder Platform*Layer5 demo Views (0%) — implement or remove |
| **#454** | AccessibilityFeaturesLayer5 unit-lane coverage |
| **#455** | PlatformMessagingLayer5 + PlatformResourceLayer5 |
| **#456** | PlatformSplitViewOptimizationsLayer5 unit-lane |
| **#457** | IntelligentCardExpansion L5/L6 gaps |
| **#458** | CrossPlatformOptimizationLayer6 + PlatformPerformanceLayer6 |
