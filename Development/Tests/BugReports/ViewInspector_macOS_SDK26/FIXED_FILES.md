# Files Updated to Handle ViewInspector macOS Issue

This document lists test files that were updated to use `ViewInspectorWrapper` while investigating the ViewInspector macOS compilation concern (GitHub Issue #405).

## Summary
- **Total files updated**: 38 test files + 1 wrapper file (historical count)
- **Approach**: Centralized wrapper; tests gate ViewInspector usage with `#if canImport(ViewInspector)` (no separate macOS compile flag)
- **Current build**: The legacy `VIEW_INSPECTOR_MAC_FIXED` Swift active compilation condition was removed from Xcode test targets (`project.yml`); do not reintroduce it unless you have a new migration reason.

## Core Infrastructure

### ViewInspectorWrapper.swift
- **Location**: `Development/Tests/SixLayerFrameworkTests/Utilities/TestHelpers/ViewInspectorWrapper.swift`
- **Purpose**: Centralized wrapper for ViewInspector APIs
- **Features**:
  - `tryInspect()` extension on `View`
  - `inspectView()` extension on `View`
  - `withInspectedView()` helper function
  - `withInspectedViewThrowing()` helper function
  - Optional ViewInspector usage guarded with `#if canImport(ViewInspector)` in test sources

### Package.swift
- **Location**: `Package.swift` (SwiftPM); Xcode development uses `project.yml` / `SixLayerFramework.xcodeproj`
- **Note**: Any historical `.define("VIEW_INSPECTOR_MAC_FIXED")` idea is obsolete; macOS ViewInspector is wired via normal target dependencies.

## Updated Test Files

### Components (2 files)
1. `Development/Tests/SixLayerFrameworkTests/Components/FormCallbackFunctionalTests.swift`
2. `Development/Tests/SixLayerFrameworkTests/Components/Views/AdaptiveDetailViewRenderingTests.swift`

### Core Architecture (5 files)
3. `Development/Tests/SixLayerFrameworkTests/Core/Architecture/FrameworkComponentGlobalConfigTests.swift`
4. `Development/Tests/SixLayerFrameworkTests/Core/Architecture/GlobalDisableLocalEnableTests.swift`
5. `Development/Tests/SixLayerFrameworkTests/Core/Architecture/MetalRenderingCrashTests.swift`
6. `Development/Tests/SixLayerFrameworkTests/Core/Architecture/TestPatterns.swift`
7. `Development/Tests/SixLayerFrameworkTests/Core/Views/ViewGenerationIntegrationTests.swift`

### Core Views (3 files)
8. `Development/Tests/SixLayerFrameworkTests/Core/Views/ViewGenerationTests.swift`
9. `Development/Tests/SixLayerFrameworkTests/Core/Views/ViewGenerationVerificationTests.swift`
10. `Development/Tests/SixLayerFrameworkTests/Core/Views/ViewGenerationIntegrationTests.swift`

### Accessibility (10 files)
11. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityGlobalLocalConfigTests.swift`
12. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityIdentifierDisabledTests.swift`
13. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityIdentifierEdgeCaseTests.swift`
14. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityIdentifierGenerationTests.swift`
15. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityIdentifierGenerationVerificationTests.swift`
16. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AccessibilityIdentifierPersistenceTests.swift`
17. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/AutomaticAccessibilityIdentifierTests.swift`
18. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/ComponentLabelTextAccessibilityTests.swift`
19. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/DynamicFormViewComponentAccessibilityTests.swift`
20. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/PlatformPhotoComponentsLayer4AccessibilityTests.swift`
21. `Development/Tests/SixLayerFrameworkTests/Features/Accessibility/SimpleAccessibilityTests.swift`

### Collections (2 files)
22. `Development/Tests/SixLayerFrameworkTests/Features/Collections/CollectionViewCallbackTests.swift`
23. `Development/Tests/SixLayerFrameworkTests/Features/Collections/IntelligentCardExpansionLayer6Tests.swift`

### Forms (3 files)
24. `Development/Tests/SixLayerFrameworkTests/Features/Forms/DynamicFieldComponentsTests.swift`
25. `Development/Tests/SixLayerFrameworkTests/Features/Forms/DynamicFormViewTests.swift`
26. `Development/Tests/SixLayerFrameworkTests/Features/Forms/FormWizardViewTDDTests.swift`

### Images (1 file)
27. `Development/Tests/SixLayerFrameworkTests/Features/Images/PhotoComponentsLayer4Tests.swift`

### Intelligence (1 file)
28. `Development/Tests/SixLayerFrameworkTests/Features/Intelligence/IntelligentDetailViewSheetTests.swift`

### Navigation (1 file)
29. `Development/Tests/SixLayerFrameworkTests/Features/Navigation/NavigationLayer4Tests.swift`

### OCR (2 files)
30. `Development/Tests/SixLayerFrameworkTests/Features/OCR/OCRComponentsTDDTests.swift`
31. `Development/Tests/SixLayerFrameworkTests/Features/OCR/OCRDisambiguationTests.swift`

### Platform (1 file)
32. `Development/Tests/SixLayerFrameworkTests/Features/Platform/PlatformPresentContentL1Tests.swift`

### Integration (1 file)
33. `Development/Tests/SixLayerFrameworkTests/Integration/CrossPlatform/CrossPlatformOptimizationLayer6Tests.swift`

### Layers (4 files)
34. `Development/Tests/SixLayerFrameworkTests/Layers/Layer1CallbackFunctionalTests.swift`
35. `Development/Tests/SixLayerFrameworkTests/Layers/Layer4FormContainerTests.swift`
36. `Development/Tests/SixLayerFrameworkTests/Layers/Layer5-Platform/Layer5PlatformComponentTDDTests.swift`
37. `Development/Tests/SixLayerFrameworkTests/Layers/LocalEnableOverrideTests.swift`

### Utilities (1 file)
38. `Development/Tests/SixLayerFrameworkTests/Utilities/Debug/EnvironmentVariableDebugTests.swift`

## Implementation Pattern

All files now use one of these patterns:

### Pattern 1: Using `withInspectedView()` wrapper
```swift
#if canImport(ViewInspector)
let inspectionResult = withInspectedView(view) { inspected in
    // ViewInspector-specific code here
    let button = try inspected.button()
    return try button.accessibilityIdentifier()
}
#else
Issue.record("ViewInspector not available on this platform")
#endif
```

### Pattern 2: Using `tryInspect()` extension
```swift
#if canImport(ViewInspector)
if let inspectedView = view.tryInspect(),
   let buttonID = try? inspectedView.accessibilityIdentifier() {
    // Test assertions here
}
#else
Issue.record("ViewInspector not available on this platform")
#endif
```

## Benefits

1. **Centralized logic**: ViewInspector entry points live in the wrapper helpers
2. **Explicit opt-in**: `#if canImport(ViewInspector)` keeps non-ViewInspector targets compiling
3. **Type safety**: Wrapper functions handle `Any` vs `InspectableView` type differences

## Related Files

- **ViewInspector Issue**: https://github.com/nalexn/ViewInspector/issues/405
- **Wrapper implementation**: see `Development/Tests/Shared/TestHelpers/` (current tree; paths in lists above are historical)
- **Xcode configuration**: `project.yml` (ViewInspector package + test targets)


