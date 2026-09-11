# Layer 6: Platform Optimization

## Overview

Layer 6 focuses on applying platform-specific enhancements and conventions. These functions provide platform-specific features that enhance the user experience on each platform.

## 📁 File Organization

Layer 6 is organized into platform-specific directories:

### **iOS Optimizations**
*`iOS/PlatformIOSOptimizationsLayer5.swift`*

### **macOS Optimizations**
*`macOS/PlatformMacOSOptimizationsLayer5.swift`*

## 🎯 Purpose

Apply platform-specific optimizations and features that enhance the user experience on each platform while maintaining the core functionality.

## 🔧 Implementation Details

**Content:** All Layer 6 files contain `extension View` blocks and are located in their respective platform directories

## 📋 Available Functions

### **iOS Optimizations**

#### **Navigation Bar Styling**
- `platformIOSNavigationBar(title:displayMode:)` - iOS-specific navigation bar styling

#### **Toolbar Styling**
- `platformIOSToolbar(content:)` - iOS-specific toolbar styling

#### **Swipe Gestures**
- `platformIOSSwipeGestures(onSwipeLeft:onSwipeRight:onSwipeUp:onSwipeDown:)` - iOS-specific swipe gestures

#### **Haptic Feedback**
- App-facing: `platformHapticFeedback(_:)` / `PlatformHapticFeedback` (not Layer 6). L5 `platformIOSHapticFeedback` is deprecated (#445).

### **macOS Optimizations**

#### **Navigation Styling**
- `platformMacOSNavigation(title:subtitle:)` - macOS-specific navigation styling

#### **Toolbar Styling**
- `platformMacOSToolbar(content:)` - macOS-specific toolbar styling

#### **Window Resizing**
- `platformMacOSWindowResizing(resizable:)` - macOS-specific window resizing behavior

#### **Window Sizing**
- `platformMacOSWindowSizing(minWidth:minHeight:idealWidth:idealHeight:)` - macOS-specific window sizing constraints

#### **NavigationStack keyboard-first (#446)**
File: `Platform/macOS/Views/Extensions/PlatformMacOSNavigationStackEnhancementsLayer6.swift`

- `platformMacOSNavigationStackEnhancements_L6()` — macOS: `focusSection()` + `onExitCommand` dismiss when presented + `platformPresentationFrame(sizes: [.small])`. Does **not** duplicate L5 `.focusable()` and does **not** apply blanket `.isHeader`. Identity on other platforms.
- `platformMacOSNavigationListDetailFocus_L6(_:list:detail:isDetailPresented:)` — macOS `defaultFocus` for list ↔ detail restore. Identity elsewhere.
- `platformMacOSNavigationKeyboardShortcuts_L6(onBack:onSelect:onDismiss:)` — View-level `keyboardShortcut` (Cmd+`[`, Return, Escape). **Not** Scene `commands` (that API cannot be a View modifier).
- Decisions: `platformMacOSNavigationStackKeyboardChrome(for:)`, `platformMacOSNavigationDefaultFocusPane(isDetailPresented:)`, `platformMacOSNavigationShouldDismissOnExit(isPresented:)`, `platformMacOSNavigationKeyboardShortcutKind(for:)`.

## 💡 Usage Examples

### **iOS Navigation Bar**
```swift
#if os(iOS)
.platformIOSNavigationBar(
    title: "Item Details",
    displayMode: .large
)
#endif
```

### **Haptic Feedback**
```swift
.platformHapticFeedback(.medium)
```

### **macOS Window Sizing**
```swift
#if os(macOS)
.platformMacOSWindowSizing(
    minWidth: 800,
    minHeight: 600,
    idealWidth: 1200,
    idealHeight: 800
)
#endif
```

### **macOS Toolbar**
```swift
#if os(macOS)
.platformMacOSToolbar {
    // Toolbar content
}
#endif
```

## 🔄 Integration with Other Layers

### **Layer 4 → Layer 6**
Layer 4 components can be enhanced with Layer 6 platform-specific features.

Sidebar-sheet and compact overlay chrome live here (#447). Pure decisions stay in
`platformSidebarSheetChrome(for:)` / `platformOverlayDetailChrome(for:)`; L6 apply uses
compile-time `#if os` mirroring those tables so host Mirror subject types stay
platform-truthful (a ViewBuilder runtime switch encoded unused `NavigationStack` branches):

- `platformSidebarSheetChrome_L6()` — `NavigationStack` on iOS, small `platformPresentationFrame` on macOS, identity elsewhere
- `platformOverlayDetailChrome_L6()` — `NavigationStack` on iOS and macOS, identity elsewhere

`PlatformSidebarSheetChromeTests` gates both directions: `.current` decisions must match
compile-time OS, and host Mirror subject types must match each decision (including overlay).

Compact collapse and column visibility stay in `NavigationLayoutResolver` / L5 split helpers.

### **Layer 5 → Layer 6**
Layer 5 optimizations can be enhanced with Layer 6 platform-specific performance features.

## 🎨 Design Principles

1. **Platform-Native:** Follow platform design guidelines and conventions
2. **Enhancement-Focused:** Add value without changing core functionality
3. **Consistent API:** Similar function patterns across platforms
4. **Performance-Aware:** Consider platform-specific performance characteristics
5. **User Experience:** Enhance the native feel of each platform

## 🔧 Platform-Specific Features

### **iOS Features**
- **Haptic Feedback:** Tactile response for user interactions
- **Swipe Gestures:** Native iOS gesture support
- **Navigation Bar:** iOS-specific navigation styling
- **Toolbar:** iOS-specific toolbar behavior
- **Safe Area:** Automatic safe area handling
- **Dynamic Type:** Automatic text scaling

### **macOS Features**
- **Window Management:** macOS-specific window behavior
- **Toolbar:** macOS-specific toolbar styling
- **Menu Bar:** Menu bar integration
- **Multi-Display:** Multi-display support
- **Keyboard Shortcuts:** Native keyboard shortcuts
- **Drag & Drop:** Native drag and drop support

## 📱 Platform Conventions

### **iOS Conventions**
- **Touch-First:** Optimized for touch interactions
- **Gesture-Based:** Swipe, pinch, and tap gestures
- **Modal Presentation:** Sheet and full-screen modals
- **Navigation:** Stack-based navigation
- **Tab Bars:** Bottom tab bar navigation

### **macOS Conventions**
- **Mouse & Keyboard:** Optimized for pointer and keyboard
- **Window-Based:** Multiple window support
- **Menu-Driven:** Menu bar and contextual menus
- **Sidebar Navigation:** Sidebar-based navigation
- **Toolbar Actions:** Toolbar-based actions

## 🚀 Future Enhancements

### **iOS Enhancements**
- **ARKit Integration:** Augmented reality features
- **Core ML:** Machine learning integration
- **Siri Shortcuts:** Voice command integration
- **Widgets:** Home screen widget support
- **App Clips:** Lightweight app experiences

### **macOS Enhancements**
- **Catalyst Integration:** iOS app compatibility
- **Metal Performance:** Graphics optimization
- **Core Data:** Advanced data management
- **CloudKit:** Cloud synchronization
- **Automation:** AppleScript and automation support

## 🔍 Platform Detection

### **Compile-Time Detection**
```swift
#if os(iOS)
// iOS-specific code
#elseif os(macOS)
// macOS-specific code
#endif
```

### **Runtime Detection**
```swift
#if targetEnvironment(macCatalyst)
// Catalyst-specific code
#endif
```

## 📊 Platform Considerations

### **Performance Differences**
- **iOS:** Battery life, thermal management, memory pressure
- **macOS:** Multi-tasking, background processing, system resources

### **User Expectations**
- **iOS:** Touch-first, gesture-based, modal interactions
- **macOS:** Mouse-first, keyboard shortcuts, window management

### **Development Considerations**
- **iOS:** App Store guidelines, device compatibility
- **macOS:** Mac App Store, system requirements

## 📚 Related Documentation

- **Architecture Overview:** [README_6LayerArchitecture.md](README_6LayerArchitecture.md)
- **Layer 4:** [README_Layer4_Implementation.md](README_Layer4_Implementation.md)
- **Layer 5:** [README_Layer5_Performance.md](README_Layer5_Performance.md)
- **Usage Examples:** [README_UsageExamples.md](README_UsageExamples.md)

## 🎯 Best Practices

1. **Platform-Native:** Always follow platform design guidelines
2. **Conditional Compilation:** Use `#if os()` for platform-specific code
3. **Feature Detection:** Check for feature availability at runtime
4. **Consistent API:** Maintain similar function patterns across platforms
5. **User Testing:** Test on actual devices for each platform
6. **Documentation:** Document platform-specific behavior clearly
