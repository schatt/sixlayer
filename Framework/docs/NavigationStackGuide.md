# NavigationStack 6-Layer Implementation Guide

## Overview

The NavigationStack implementation in SixLayer Framework follows the complete 6-layer architecture, allowing developers to express navigation intent semantically while the framework handles all implementation details through intelligent decision-making and platform-specific optimizations.

## 🎯 Core Philosophy

**Express WHAT you want, not HOW to implement it.**

Developers use Layer 1 semantic functions to express navigation intent. The framework automatically:
- Analyzes content (Layer 2)
- Selects optimal strategies (Layer 3)
- Implements components (Layer 4)
- Applies performance optimizations (Layer 5)
- Adds platform-specific enhancements (Layer 6)

## 📋 Quick Start

### Basic Navigation Stack

```swift
import SixLayerFramework

struct MyView: View {
    var body: some View {
        platformPresentNavigationStack_L1(
            content: Text("Hello, World!"),
            title: "My View",
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .navigation,
                complexity: .simple,
                context: .navigation
            )
        )
    }
}
```

### Navigation Stack with Items

```swift
struct Item: Identifiable, Hashable {
    let id: UUID
    let title: String
}

struct MyListView: View {
    let items: [Item]
    
    var body: some View {
        platformPresentNavigationStack_L1(
            items: items,
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .navigation,
                complexity: .simple,
                context: .navigation
            )
        ) { item in
            Text(item.title)
        } destination: { item in
            ItemDetailView(item: item)
        }
    }
}
```

## 🏗️ Architecture Layers

### Layer 1: Semantic Intent

**Function:** `platformPresentNavigationStack_L1()`

Express your navigation intent without knowing implementation details.

**What it does:**
- Accepts content or items to navigate
- Takes presentation hints to guide decisions
- Returns a view that handles navigation automatically

**Example:**
```swift
platformPresentNavigationStack_L1(
    content: myContentView,
    title: "Settings",
    hints: navigationHints
)
```

### Layer 2: Decision Engine

**Function:** `determineNavigationStackStrategy_L2()`

Analyzes content and makes navigation decisions based on:
- Content complexity
- Item count
- Presentation hints preferences
- Collection characteristics

**Decision Logic:**
- Empty/Single items → NavigationStack
- Small simple collections → NavigationStack
- Large/Complex collections → Adaptive (may use SplitView)
- Respects explicit hints preferences

### Layer 3: Strategy Selection

**Function:** `selectNavigationStackStrategy_L3()`

Selects optimal implementation strategy based on:
- Layer 2 decision
- Platform (iOS, macOS, etc.)
- Platform version (iOS 16+ vs 15, etc.)

**Strategies:**
- `navigationStack` - iOS 16+ NavigationStack
- `navigationView` - iOS 15 fallback, macOS
- `splitView` - NavigationSplitView for large screens
- `modal` - Modal presentation

### Layer 4: Component Implementation

**Functions:** 
- `platformImplementNavigationStack_L4()`
- `platformImplementNavigationStackItems_L4()`

Implements the actual navigation components based on Layer 3 strategy.

**Handles:**
- iOS 16+ NavigationStack
- iOS 15 NavigationView fallback
- macOS NavigationView
- NavigationSplitView for split views
- Modal presentation

### Layer 5: Performance Optimizations

**Function:** `platformNavigationStackOptimizations_L5()`

Applies performance optimizations:
- Memory optimization (`.drawingGroup()`)
- Touch optimization (`.contentShape()`)
- Rendering optimization (`.compositingGroup()`)
- Animation optimization (transaction tuning)

**Platform-specific:**
- iOS: Touch responsiveness, smooth transitions
- macOS: Window performance, large dataset handling

### Layer 6: Platform Enhancements

**Function:** `platformNavigationStackEnhancements_L6()`

Applies platform-specific enhancements:
- iOS: Navigation bar styling, haptic feedback support, swipe gestures
- macOS: Keyboard navigation, window sizing, accessibility enhancements

## 💡 Usage Examples

### Example 1: Simple Content Navigation

```swift
struct SettingsView: View {
    var body: some View {
        platformPresentNavigationStack_L1(
            content: SettingsContent(),
            title: "Settings",
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .navigation,
                complexity: .simple,
                context: .settings
            )
        )
    }
}
```

### Example 2: List-Detail Navigation

```swift
struct ProductListView: View {
    let products: [Product]
    
    var body: some View {
        platformPresentNavigationStack_L1(
            items: products,
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .navigation,
                complexity: .moderate,
                context: .browse
            )
        ) { product in
            ProductRow(product: product)
        } destination: { product in
            ProductDetailView(product: product)
        }
    }
}
```

### Example 3: Forcing Split View

```swift
struct LargeDataSetView: View {
    let items: [Item]
    
    var body: some View {
        platformPresentNavigationStack_L1(
            items: items,
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .detail, // Forces split view
                complexity: .complex,
                context: .browse
            )
        ) { item in
            ItemRow(item: item)
        } destination: { item in
            ItemDetailView(item: item)
        }
    }
}
```

### Example 4: Modal Navigation

```swift
struct ModalNavigationView: View {
    let items: [Item]
    
    var body: some View {
        platformPresentNavigationStack_L1(
            items: items,
            hints: PresentationHints(
                dataType: .navigation,
                presentationPreference: .modal, // Forces modal
                complexity: .simple,
                context: .navigation
            )
        ) { item in
            ItemRow(item: item)
        } destination: { item in
            ItemDetailView(item: item)
        }
    }
}
```

## 🔄 Architecture Flow

```
Developer Code:
  platformPresentNavigationStack_L1(...)
           ↓
Layer 1: Semantic Intent
  - Expresses navigation intent
           ↓
Layer 2: Decision Engine
  - Analyzes content
  - Makes navigation decision
           ↓
Layer 3: Strategy Selection
  - Selects implementation strategy
  - Considers platform/version
           ↓
Layer 4: Component Implementation
  - Implements NavigationStack/NavigationView
           ↓
Layer 5: Performance Optimization
  - Applies memory/rendering optimizations
           ↓
Layer 6: Platform Enhancements
  - Adds iOS/macOS specific features
           ↓
Final View: Fully optimized, platform-enhanced navigation
```

## 🎨 Presentation Hints

NavigationStack respects presentation hints to guide decisions:

### `presentationPreference`
- `.navigation` - Prefer NavigationStack
- `.detail` - Prefer SplitView
- `.modal` - Prefer modal presentation
- `.automatic` - Let framework decide

### `complexity`
- `.simple` - Simple navigation
- `.moderate` - Moderate complexity
- `.complex` - Complex navigation needs

### `context`
- `.navigation` - General navigation
- `.browse` - Browsing content
- `.settings` - Settings navigation
- `.detail` - Detail view navigation

## 📱 Platform Behavior

### iOS
- **iOS 16+**: Uses `NavigationStack` with modern navigation
- **iOS 15**: Falls back to `NavigationView`
- **Enhancements**: Haptic feedback, swipe gestures, iOS navigation bar styling

### macOS
- Uses platform NavigationStack / NavigationSplitView as selected by L3/L4
- **L6 keyboard-first (#446):** `platformMacOSNavigationStackEnhancements_L6()` applies `focusSection()` and Escape/`onExitCommand` dismiss when the stack is presented. List ↔ detail restore is `platformMacOSNavigationListDetailFocus_L6`. View-level shortcuts are `platformMacOSNavigationKeyboardShortcuts_L6`. Scene `commands` is not applied (Scene-only API).
- Window sizing remains `platformPresentationFrame` on the L6 wrapper

### Automatic Platform Detection
The framework automatically detects the platform and applies appropriate implementations. No platform-specific code needed in your app.

## 🚀 Advanced Usage

### Custom Navigation Preferences

```swift
let hints = PresentationHints(
    dataType: .navigation,
    presentationPreference: .navigation,
    complexity: .moderate,
    context: .browse,
    customPreferences: [
        "preferSplitView": "true",
        "navigationStyle": "stack"
    ]
)
```

### Integration with Other Layer 1 Functions

NavigationStack works seamlessly with other Layer 1 functions:

```swift
struct CombinedView: View {
    var body: some View {
        platformPresentNavigationStack_L1(
            content: platformPresentItemCollection_L1(
                items: items,
                hints: collectionHints
            ),
            title: "Items",
            hints: navigationHints
        )
    }
}
```

## 🔍 Direct Layer Access (Advanced)

While Layer 1 is recommended, you can access lower layers directly if needed:

### Layer 2: Decision Making
```swift
let decision = determineNavigationStackStrategy_L2(
    items: items,
    hints: hints
)
```

### Layer 3: Strategy Selection
```swift
let strategy = selectNavigationStackStrategy_L3(
    decision: decision,
    platform: .iOS
)
```

### Layer 4: Direct Implementation
```swift
platformImplementNavigationStack_L4(
    content: content,
    title: title,
    strategy: strategy
)
```

## 📚 Related Documentation

- **[6-Layer Architecture](README_6LayerArchitecture.md)** - Complete architecture overview
- **[Layer 1 Semantic](README_Layer1_Semantic.md)** - Semantic intent layer
- **[Layer 2 Decision](README_Layer2_Decision.md)** - Decision engine
- **[Layer 3 Strategy](README_Layer3_Strategy.md)** - Strategy selection
- **[Layer 4 Implementation](README_Layer4_Implementation.md)** - Component implementation
- **[Layer 5 Performance](README_Layer5_Performance.md)** - Performance optimization
- **[Layer 6 Platform](README_Layer6_Platform.md)** - Platform enhancements

## 🎯 Best Practices

1. **Always use Layer 1** - Express intent, not implementation
2. **Provide meaningful hints** - Help the framework make better decisions
3. **Trust the framework** - Let it choose optimal strategies
4. **Test on multiple platforms** - Verify cross-platform behavior
5. **Use hints for preferences** - Don't access lower layers directly unless necessary

## ⚠️ Common Mistakes

### ❌ Don't Mix Layers
```swift
// ❌ WRONG: Mixing Layer 1 with raw SwiftUI
platformPresentNavigationStack_L1(...) {
    NavigationStack {  // ❌ Don't do this
        Text("Content")
    }
}
```

### ✅ Correct: Use Layer 1 Only
```swift
// ✅ CORRECT: Let framework handle everything
platformPresentNavigationStack_L1(
    content: Text("Content"),
    hints: hints
)
```

### ❌ Don't Access Lower Layers Directly
```swift
// ❌ WRONG: Bypassing Layer 1
let decision = determineNavigationStackStrategy_L2(...)  // Don't do this
```

### ✅ Correct: Use Layer 1
```swift
// ✅ CORRECT: Use Layer 1, let it handle lower layers
platformPresentNavigationStack_L1(...)
```

## 🔗 Migration from Layer 4 API

If you're using the old Layer 4 API directly:

### Before (Layer 4)
```swift
content.platformNavigation {
    content
}
```

### After (Layer 1)
```swift
platformPresentNavigationStack_L1(
    content: content,
    hints: hints
)
```

The Layer 4 API still works for backward compatibility, but Layer 1 is recommended for new code.

## 📊 Implementation Status

✅ **Complete 6-Layer Implementation:**
- ✅ Layer 1: Semantic Intent
- ✅ Layer 2: Decision Engine
- ✅ Layer 3: Strategy Selection
- ✅ Layer 4: Component Implementation
- ✅ Layer 5: Performance Optimizations
- ✅ Layer 6: Platform Enhancements

All layers are fully implemented, tested, and integrated.

