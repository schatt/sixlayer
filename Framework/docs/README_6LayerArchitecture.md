# 6-Layer Architecture for Platform Extensions

## Overview

Our platform extensions follow a 6-layer architecture for clean separation of concerns and progressive enhancement capabilities.

## 🏗️ Architecture Layers

### **Layer 1: Semantic Intent**
Express WHAT you want to achieve without worrying about implementation details.

**Purpose:** Define the user's intent in platform-agnostic terms
**Location:** `PlatformSemanticLayer1.swift`
**Content:** `extension View` blocks for semantic functions

### **Layer 2: Layout Decision Engine**
Decide HOW to achieve the desired layout based on content analysis and constraints.

**Purpose:** Analyze content and make intelligent layout decisions
**Location:** `PlatformLayoutDecisionLayer2.swift`
**Content:** Top-level functions, not extensions

### **Layer 3: Strategy Selection**
Choose the optimal implementation strategy based on current conditions.

**Purpose:** Select the best approach for the current context
**Location:** `PlatformStrategySelectionLayer3.swift`
**Content:** Top-level functions, not extensions

### **Layer 4: Component Implementation**
Build specific UI components with platform-adaptive behavior.

**Purpose:** Create the actual UI components
**Location:** Various Layer 4 files (Navigation, Buttons, Forms, etc.)
**Content:** `extension View` blocks

### **Layer 5: Technical Implementation**
Platform-aware technical behavior (iOS chrome/gestures/haptics, split-view and navigation-stack tuning, card-expansion performance config).

**Purpose:** Apply platform technical enhancements (not generic memory/render modifier names)
**Location:** `PlatformIOSOptimizationsLayer5.swift` and `Framework/Sources/Layers/Layer5-Platform/`
**Content:** `extension View` blocks and L5 platform types/views — see [README_Layer5_Performance.md](README_Layer5_Performance.md)
**Note:** There is no `PlatformPerformanceExtensionsLayer5.swift`; documented phantom modifiers were removed (#425).

### **Layer 6: Platform Optimization**
Apply platform-specific enhancements and conventions.

**Purpose:** Platform-specific optimizations and features
**Location:** `iOS/` and `macOS/` directories
**Content:** `extension View` blocks

## 🔄 Data Flow Through Layers

```
Layer 1 (Semantic) → Layer 2 (Decision) → Layer 3 (Strategy) → Layer 4 (Implementation) → Layer 5 (Performance) → Layer 6 (Platform)
     ↓                      ↓                      ↓                      ↓                      ↓                      ↓
"What do I want?" → "How should I do it?" → "Which strategy?" → "Build the component" → "Optimize it" → "Platform enhance it"
```

## 🎯 Benefits

1. **Clear Separation of Concerns:** Each layer has a specific responsibility
2. **Progressive Enhancement:** Can use any layer independently or in combination
3. **Platform Independence:** Core logic separated from platform specifics
4. **Maintainability:** Functions organized by purpose and layer
5. **Scalability:** Easy to add new functions to appropriate layers
6. **Testing:** Can test each layer independently
7. **Performance:** Strategy selection can optimize for current conditions

## 🔧 Naming Convention

**Files with "Extensions" in the name:**
- Contain `extension View` blocks
- Layers 1, 4, 5, and 6

**Files without "Extensions" in the name:**
- Contain top-level functions only
- Layers 2 and 3

**Platform-specific files:**
- Located in their respective `iOS/` and `macOS/` directories
- Not in `Shared/Views/Extensions/`

## 📚 Related Documentation

- **Layer 1:** [README_Layer1_Semantic.md](README_Layer1_Semantic.md)
- **Layer 2:** [README_Layer2_Decision.md](README_Layer2_Decision.md)
- **Layer 3:** [README_Layer3_Strategy.md](README_Layer3_Strategy.md)
- **Layer 4:** [README_Layer4_Implementation.md](README_Layer4_Implementation.md)
- **Layer 5:** [README_Layer5_Performance.md](README_Layer5_Performance.md)
- **Layer 6:** [README_Layer6_Platform.md](README_Layer6_Platform.md)
- **Usage Examples:** [README_UsageExamples.md](README_UsageExamples.md)

## 🚀 Future Development

- **Layer 2:** Implement intelligent content analysis and decision-making
- **Layer 3:** Expand strategy selection based on runtime conditions
- **Layer 4:** Add more specialized UI components
- **Layer 5:** Implement performance monitoring and adaptive optimization
- **Layer 6:** Expand platform-specific features and conventions
