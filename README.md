# SixLayer Framework Repository

This repository contains the SixLayer Framework, a comprehensive SwiftUI framework implementing a six-layer architecture for cross-platform development.

## 📁 Repository Structure

```
6layer/
├── Framework/                 ← **This is the Swift Package**
│   ├── Sources/              ← Framework source code
│   ├── Package.swift         ← Package definition
│   ├── README.md             ← Framework documentation
│   └── Stubs/                ← Framework stubs
└── Development/               ← Development files (not in package)
    ├── todo.md                ← Project roadmap
    ├── PROJECT_STATUS.md      ← Current status
    ├── Tests/                 ← Test suite
    ├── docs/                  ← Technical documentation
    └── Examples/              ← Usage examples
```

## 🚀 Getting Started

### **For Users (Consuming the Framework):**
Navigate to the `Framework/` directory and use it as a Swift Package:

```swift
// In your Package.swift
dependencies: [
    .package(url: "https://github.com/schatt/sixlayer.git", from: "6.6.3")
]
```

### **For Developers (Contributing):**
- **Framework Code**: `Framework/Sources/`
- **Documentation**: `Framework/docs/`
- **Project Status**: `Development/todo.md`
- **Tests**: `Development/Tests/`

## 📦 Swift Package

The framework is distributed as a Swift Package from the `Framework/` directory. This ensures that only the essential framework code is included when other projects consume it.

## 🆕 Latest Release: v6.6.3

### **ScrollView Wrapper Fixes**
🔧 **Collection View Scrolling**: Fixed missing ScrollView wrappers in all collection views. GridCollectionView, ListCollectionView, ExpandableCardCollectionView, and MasonryCollectionView now properly scroll when content exceeds view bounds, maintaining the framework's abstraction layer.

### **Previous Release: v6.6.2 - Swift 6 Compilation Fixes**
🔧 **Swift 6 Compatibility**: Fixed Swift 6 compilation errors and deprecation warnings. Includes main actor isolation fixes, iOS 17+ API updates, switch exhaustiveness fixes, and removal of unnecessary availability checks.

### **Previous Release: v6.6.1 - SPM Bundle Name Fix**
🔧 **Bundle Resource Access**: Fixed Swift Package Manager bundle name issue. Updated to use `Bundle.module` for Swift Package builds with proper fallback for Xcode framework builds. Fixed `CFBundleName` in Info.plist.

### **Previous Release: v6.6.0 - Platform Capability Detection Fixes**
🔧 **Apple HIG Compliance**: Fixed platform capability detection to align with Apple Human Interface Guidelines. `minTouchTarget` is now platform-based (44.0 for iOS/watchOS, 0.0 for others), `supportsAssistiveTouch` correctly checks platform availability, and tests use runtime platform detection for better accuracy.

### **Previous Release: v6.5.0 - Swift 6 Compilation Fixes & Test Infrastructure**
🔧 **Swift 6 Compatibility**: Fixed all compilation errors and actor isolation issues for full Swift 6 compatibility. Includes fixes for CloudKitService, test kit examples, and design system tests. Test infrastructure improved with proper async setup/teardown and actor isolation.

### **Previous Release: v6.4.2 - Platform Bottom-Bar Toolbar Placement Helper**
🔧 **Cross-Platform Toolbar Placement**: Added `platformBottomBarPlacement()` function for bottom-aligned toolbar items. Returns `.bottomBar` on iOS and `.automatic` on macOS/other platforms. Resolves Issue #125.

### **Previous Release: v6.4.1 - NotificationService Bug Fix**
🐛 **Compilation Fix**: Fixed optional Bool unwrapping in `NotificationService.checkIOSDoNotDisturbStatusAsync()` (Issue #124). Function now properly handles nil Focus status values with conservative default.

### **Previous Release: v6.4.0 - Design System Bridge & Developer Experience**
🎨 **Design System Bridge**: Framework-level abstraction for mapping external design tokens to SixLayer components with theme injection.  
🧪 **SixLayerTestKit**: Comprehensive testing utilities for framework consumers with service mocks and test helpers.  
📚 **Sample Applications**: Canonical TaskManager sample app demonstrating proper SixLayer architecture patterns.  
🌐 **Localization Improvements**: .xcstrings support and localization completeness checking.  
🔧 **Developer Experience**: Stable extension surface and migration tooling.

### **Previous Release: v6.1.1 - Color.named() Extensions**
🎨 **Color API improvements**: Extended `Color.named()` to support `systemBackground` and other commonly used color names (`cardBackground`, `label`, `secondaryLabel`, `tertiaryLabel`, `separator`).  
🔧 **Convenience method**: Added `Color.named(_:default:)` that returns a non-optional `Color` with a fallback, preventing compiler type-checking issues.  
🐛 **Bug fixes**: Resolved compiler type-checking timeouts when chaining multiple optionals with `Color.named()`.

### **Previous Release: v6.1.0 - Form UX Enhancements & Platform Extensions**
📝 **Form improvements**: Collapsible sections, required field indicators, character counters, validation summary, Stepper field type, and Link component for URLs.  
🔍 **OCR enhancements**: Batch OCR workflow for filling multiple fields from single scan, declarative field hints with Mirror fallback.  
🎨 **UI enhancements**: Semantic background colors via `Color.named()`, barcode scanning support.  
🛠️ **Platform extensions**: Sidebar pull indicator, container extensions, list toolbar extension, animation system extensions, string sanitization function.

### **Previous Release: v6.0.0 - Intelligent Device-Aware Navigation & Cross-Platform Utilities**
🧭 **Intelligent navigation**: Device-aware app navigation with automatic pattern selection (NavigationSplitView vs detail-only).  
🖨️ **Cross-platform printing**: Unified printing API supporting text, images, PDFs, and SwiftUI views.  
📁 **File system utilities**: Comprehensive file system utilities with iCloud Drive support.  
🔧 **Toolbar placement**: Platform-specific toolbar placement helpers for cross-platform apps.  
📏 **HIG-compliant spacing**: Refactored spacing system aligned with macOS HIG 8pt grid guidelines.  
♿ **Accessibility**: Automatic accessibility identifiers and full VoiceOver support.  
🧪 **Comprehensive testing**: Full test coverage for all new features.  
📚 **Complete documentation**: Full guides with usage examples and best practices.

### **Previous Release: v5.7.2 – Intelligent Decimal Correction & Enhanced Range Validation**
🔧 **Intelligent decimal correction**: Automatically corrects missing decimal points using expected ranges and calculation groups as heuristics.  
📊 **Range inference**: Infers ranges from calculation groups for fields without explicit ranges.  
⚠️ **Field adjustment tracking**: `OCRResult.adjustedFields` tracks which fields were adjusted or calculated for user verification.  
📈 **Enhanced range validation**: Expected ranges are now guidelines (not hard requirements) - out-of-range values are kept but flagged.  
📊 **Field averages**: Apps can provide typical/average values to flag unusual values even within range.  
🔄 **Bidirectional pattern matching**: Handles both "Gallons 9.022" and "9.022 Gallons" patterns.  
🧪 **Comprehensive testing**: Range validation tests cover boundaries, precedence, and edge cases.

### **Previous Release: v5.7.0 – Automatic OCR Hints & Structured Extraction Intelligence**
📄 **Configurable entity mapping**: `OCRContext` now accepts `entityName` so projects choose which `.hints` file to load.  
🤖 **Automatic hints loading**: `OCRService` loads `{entityName}.hints`, converts `ocrHints` to regex patterns, and merges them with built-in/custom hints.  
🧮 **Calculation group evaluation**: Structured extraction automatically derives missing values (e.g., price-per-gallon) using hint-defined formulas.

### **Previous Release: v5.6.0 – Enhanced Layer 1 Functions & KeyboardType Extensions**
🎨 **Custom View Support**: Layer 1 functions gained optional custom view wrappers while preserving framework benefits.  
⌨️ **KeyboardType Extensions**: Cross-platform View extension for all 11 keyboard types with proper platform mappings.  
🧪 **Comprehensive Testing**: 32+ new tests covering custom view usage and keyboard behaviors.

**Highlights:**
- ✅ **Complete TDD Implementation** - Strict Test-Driven Development throughout
- ✅ **Advanced Accessibility System** - Automatic identifier generation for all components
- ✅ **800+ Comprehensive Tests** - Full platform coverage with behavioral verification
- ✅ **Apple HIG Compliance** - Complete compliance with Human Interface Guidelines
- ✅ **Platform Capability Detection** - Accurate runtime detection for all platforms
- ✅ **Component Architecture** - All components support automatic accessibility
- ✅ **Testing Infrastructure** - Suite organization with Xcode test navigator integration
- ✅ **Cross-Platform Validation** - Enhanced testing across iOS, macOS, visionOS

**See [Field Hints Complete Guide](Framework/docs/FieldHintsCompleteGuide.md) for full documentation**

**Example:**
```swift
platformPresentItemCollection_L1(
    items: products,
    hints: hints,
    customItemView: { product in
        MyCustomProductView(product: product)
    }
)
```

## 🔗 Quick Links

- **[Framework README](Framework/README.md)** - Complete framework documentation
- **[Project Status](Development/PROJECT_STATUS.md)** - Current development status
- **[Roadmap](Development/todo.md)** - Development phases and progress
- **[Documentation](Framework/docs/)** - Technical implementation details
- **[Release Notes v4.1.3](Development/RELEASE_v4.1.3.md)** - Fix Critical Automatic Accessibility Identifier Bug
- **[OCR Overlay Guide](Framework/docs/OCROverlayGuide.md)** - Interactive visual text correction

## 🤖 For AI Assistants

This framework has a specific architecture that requires careful understanding. **Please read the AI Agent Guide first** before attempting to help with this framework:

- **[AI_AGENT Guide](Development/AI_AGENT.md)** - Complete guide with version-specific links
- **[Latest Features](Development/AI_AGENT_v4.1.2.md)** - Automatic Accessibility Identifiers Fix for Layers 2-6
- **[All AI Agent Files](Development/)** - Complete history of version-specific guides

These guides contain critical information about the Layer 1 Semantic Intent philosophy, correct usage patterns, and common mistakes to avoid.

## 📋 Current Status

**Version**: v6.6.3 (ScrollView Wrapper Fixes)
**Phase**: Patch Release
**Next**: Continue framework development and stability improvements

## 🤝 Contributing

Please read the development documentation in the `Development/` directory before contributing. The framework follows a strict six-layer architecture pattern.

---

**Note**: This repository structure separates framework code from development files, ensuring clean package distribution while maintaining development transparency.
