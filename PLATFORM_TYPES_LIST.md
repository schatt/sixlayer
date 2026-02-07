# Platform* Types Reference

Complete list of all `Platform*` types in the SixLayer Framework codebase, organized by category.

**Total: 87 distinct types**

---

## Core Platform Types

1. **`PlatformDeviceCapabilities`** (struct) - Device capability information
2. **`PlatformAdaptation`** (enum) - Platform adaptations for different devices
3. **`PlatformSize`** (struct) - Cross-platform size type
4. **`PlatformImage`** (struct) - Cross-platform image type
5. **`PlatformImageEXIF`** (struct) - Image EXIF metadata
6. **`PlatformRect`** (struct) - Cross-platform rectangle type
7. **`PlatformFileSystemError`** (enum) - File system error type

---

## Layer 1 - Semantic Layer

8. **`PlatformSemanticLayer1`** (functions, not a type, but referenced in tests)

---

## Layer 4 - Component Layer

9. **`PlatformPhotoComponentsLayer4`** (enum)
10. **`PlatformCameraPreviewView`** (struct, View)
11. **`PlatformMapComponentsLayer4`** (enum)
12. **`PlatformSplitViewStyle`** (enum)
13. **`PlatformSplitViewDividerStyle`** (enum)
14. **`PlatformSplitViewDivider`** (struct)
15. **`PlatformSplitViewShadow`** (struct)
16. **`PlatformSplitViewAppearance`** (struct)
17. **`PlatformSplitViewPaneSizing`** (struct)
18. **`PlatformSplitViewSizing`** (struct)
19. **`PlatformSplitViewAnimationConfiguration`** (struct)
20. **`PlatformSplitViewKeyboardAction`** (enum)
21. **`PlatformSplitViewKeyboardShortcut`** (struct)
22. **`PlatformSplitViewState`** (class, ObservableObject)
23. **`PlatformTabStrip`** (struct, View)
24. **`PlatformRowActionButton`** (struct, View)
25. **`PlatformDestructiveRowActionButton`** (struct, View)
26. **`PlatformClipboard`** (enum)

---

## Layer 5 - Platform Layer

27. **`PlatformResourceLayer5`** (class)
28. **`PlatformMessagingLayer5`** (class)
29. **`PlatformKnowledgeLayer5`** (struct, View)
30. **`PlatformWisdomLayer5`** (struct, View)
31. **`PlatformNotificationLayer5`** (struct, View)
32. **`PlatformSafetyLayer5`** (struct, View)
33. **`PlatformOrganizationLayer5`** (struct, View)
34. **`PlatformPrivacyLayer5`** (struct, View)
35. **`PlatformLoggingLayer5`** (struct, View)
36. **`PlatformMaintenanceLayer5`** (struct, View)
37. **`PlatformRoutingLayer5`** (struct, View)
38. **`PlatformOrchestrationLayer5`** (struct, View)
39. **`PlatformRecognitionLayer5`** (struct, View)
40. **`PlatformProfilingLayer5`** (struct, View)
41. **`PlatformOptimizationLayer5`** (struct, View)
42. **`PlatformInterpretationLayer5`** (struct, View)

---

## Layer 6 - Optimization Layer

43. **`PlatformPerformanceLayer6`** (struct, View)
44. **`PlatformOptimizationSettings`** (struct)
45. **`PlatformSpecificMetrics`** (struct)
46. **`PlatformUIPatterns`** (struct)
47. **`PlatformOptimizationModifier`** (struct, ViewModifier)
48. **`PlatformKey`** (struct, EnvironmentKey)
49. **`PlatformAwareExpandableCardView`** (struct, View)

---

## UI & Extensions

50. **`PlatformUIExamples`** (struct)
51. **`PlatformUIExampleApp`** (struct, View)
52. **`PlatformUITypes`** (file with types)
53. **`PlatformTitleDisplayMode`** (enum)
54. **`PlatformPresentationDetent`** (enum)
55. **`PlatformTabItem`** (struct)
56. **`PlatformFrameHelpers`** (enum)
57. **`PlatformUIIntegration`** (struct)
58. **`PlatformSpacing`** (struct)
59. **`PlatformColorExamples`** (struct, View)
60. **`PlatformColorFormExamples`** (struct, View)
61. **`PlatformColorListExamples`** (struct, View)
62. **`PlatformColorCardExamples`** (struct, View)
63. **`PlatformAnyShapeStyle`** (struct, ShapeStyle)
64. **`PlatformAnimation`** (enum)
65. **`PlatformToolbarPlacement`** (enum)

---

## Input & Interaction

66. **`PlatformKeyboardType`** (enum)
67. **`PlatformTextFieldStyle`** (enum)
68. **`PlatformLocationAuthorizationStatus`** (enum)
69. **`PlatformHapticFeedback`** (enum)
70. **`PlatformHapticFeedbackTapModifier`** (struct, ViewModifier, private)
71. **`PlatformHapticFeedbackWithActionModifier`** (struct, ViewModifier, private)
72. **`PlatformInteractionButton`** (struct, View)

---

## Accessibility & Design System

73. **`PlatformDesignSystem`** (struct)
74. **`PlatformPatternModifier`** (struct, ViewModifier)
75. **`PlatformNavigationModifier`** (struct, ViewModifier)
76. **`PlatformStylingModifier`** (struct, ViewModifier)
77. **`PlatformIconModifier`** (struct, ViewModifier)
78. **`PlatformInteractionModifier`** (struct, ViewModifier)
79. **`PlatformSpecificCategoryModifier`** (struct, ViewModifier)
80. **`PlatformStyle`** (enum)
81. **`PlatformStyleEnvironmentKey`** (struct, EnvironmentKey, private)

---

## Strategy & Configuration

82. **`PlatformStrategy`** (struct)
83. **`PlatformNavigationHelpers`** (struct)

---

## Security & Privacy Views

84. **`PlatformSecurity`** (struct, View)
85. **`PlatformSafety`** (struct, View)
86. **`PlatformPrivacy`** (struct, View)

---

## Additional Types

87. **`PlatformListDetailSelection`** (class, ObservableObject) - macOS specific

---

## Summary by Type Category

- **Structs**: 60
- **Enums**: 18
- **Classes**: 4
- **ViewModifiers**: 7 (including private ones)
- **EnvironmentKeys**: 2 (including private ones)
- **ShapeStyles**: 1

## Summary by Layer

- **Core Types**: 7
- **Layer 1 (Semantic)**: 1 (functions, not types)
- **Layer 4 (Component)**: 18
- **Layer 5 (Platform)**: 16
- **Layer 6 (Optimization)**: 7
- **UI & Extensions**: 16
- **Input & Interaction**: 7
- **Accessibility & Design System**: 9
- **Strategy & Configuration**: 2
- **Security & Privacy**: 3
- **Additional**: 1

---

*Generated from codebase analysis*
*Last updated: 2025-01-27*
