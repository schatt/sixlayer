# Layer 2: Layout Decision Engine

## Overview

Layer 2 focuses on deciding HOW to achieve the desired layout based on content analysis and constraints. These functions analyze form content and make intelligent layout decisions.

## 📁 File Location

*`Shared/Views/Extensions/PlatformLayoutDecisionLayer2.swift`*

## 🎯 Purpose

Analyze content and make intelligent layout decisions based on current conditions, device type, and screen size.

## 🔧 Implementation Details

**Content:** Contains top-level functions, not extensions

## 📋 Available Functions

### **Form Layout Analysis**
- `determineOptimalFormLayout_L2(hints:)` - Derives `GenericFormLayoutDecision` from `HintsDrivenFormStrategy` (#484). `preferredContainer` maps form→structured, scrollView→flexible, otherwise adaptive. `fieldLayout` and `validation` come from the strategy; `spacing` from `fieldLayout` (compact / spacious / comfortable). `contentComplexity` is `hints.complexity` (not a field-count heuristic).
- `determineOptimalFormLayout(fieldCount:complexity:deviceType:screenSize:)` - Analyze and decide form layout
- `analyzeFormContent(fields:deviceType:screenSize:)` - Analyze form content for optimal layout
- `decideFormLayout(recommendation:constraints:)` - Make final form layout decision

### **Card Layout Analysis**
- `analyzeCardContent(cards:deviceType:screenSize:)` - Analyze card content for responsive layout

## 📊 Data Types

### **LayoutRecommendation**
- `layoutApproach` - Recommended layout approach
- `columns` - Number of columns to use
- `spacing` - Recommended spacing between elements
- `performance` - Performance considerations

### **FormLayoutDecision**
- `layout` - Chosen layout strategy
- `validation` - Validation approach
- `accessibility` - Accessibility considerations
- `performance` - Performance strategy

### **CardLayoutDecision**
- `strategy` - Layout strategy to use
- `columns` - Number of columns
- `spacing` - Spacing between cards
- `responsive` - Responsive behavior
- `performance` - Performance considerations

### **PerformanceStrategy**
- `optimized` - Performance-optimized approach
- `balanced` - Balanced performance and features
- `featureRich` - Feature-rich approach

### **LayoutApproach**
- `grid` - Grid-based layout
- `masonry` - Masonry/pinterest-style layout
- `list` - List-based layout
- `adaptive` - Adaptive layout
- `custom` - Custom layout approach

## 💡 Usage Examples

### **Form Layout Decision**
```swift
let recommendation = analyzeFormContent(
    fields: formFields,
    deviceType: .macOS,
    screenSize: CGSize(width: 1200, height: 800)
)

let decision = decideFormLayout(
    recommendation: recommendation,
    constraints: layoutConstraints
)
```

### **Card Layout Analysis**
```swift
let cardDecision = analyzeCardContent(
    cards: dashboardCards,
    deviceType: .iOS,
    screenSize: CGSize(width: 390, height: 844)
)
```

## 🔄 Integration with Other Layers

### **Layer 1 → Layer 2**
Layer 1 semantic functions call Layer 2 decision functions to determine how to implement the intent.

### **Layer 2 → Layer 3**
Layer 2 decision functions provide input to Layer 3 strategy selection functions.

### **Layer 2 → Layer 4**
Layer 2 decisions guide Layer 4 implementation choices.

## 🎨 Design Principles

1. **Data-Driven:** Decisions based on actual content and constraints
2. **Performance-Aware:** Consider performance implications of layout choices
3. **Accessibility-First:** Prioritize accessibility in layout decisions
4. **Responsive:** Adapt to different screen sizes and device types
5. **Predictable:** Consistent decision-making for similar inputs

## 🔍 Decision Factors

### **Content Analysis**
- Number of fields or cards
- Complexity of content
- Required interactions
- Accessibility requirements

### **Device Context**
- Device type (iOS, macOS)
- Screen size and orientation
- Available memory and performance
- Platform conventions

### **User Preferences**
- Accessibility settings
- Performance preferences
- Layout preferences
- Customization options

## 🚀 Future Enhancements

- **Machine Learning:** Use ML to improve layout decisions
- **User Behavior Analysis:** Learn from user interaction patterns
- **Real-time Optimization:** Adjust layouts based on current performance
- **Custom Layout Rules:** User-defined layout preferences

## 📚 Related Documentation

- **Architecture Overview:** [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- **Layer 1:** [README_Layer1_Semantic.md](README_Layer1_Semantic.md)
- **Layer 3:** [README_Layer3_Strategy.md](README_Layer3_Strategy.md)
- **Layer 4:** [README_Layer4_Implementation.md](README_Layer4_Implementation.md)
- **Usage Examples:** [README_UsageExamples.md](README_UsageExamples.md)
