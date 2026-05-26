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
    ├── ROADMAP.md              ← Project roadmap
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
    .package(url: "https://github.com/schatt/sixlayer.git", from: "7.8.8")
]
```

### **For Developers (Contributing):**
- **Framework Code**: `Framework/Sources/`
- **Documentation**: `Framework/docs/`
- **Project Status**: `Development/ROADMAP.md`
- **Tests**: `Development/Tests/`

## 📦 Swift Package

The framework is distributed as a Swift Package from the `Framework/` directory. This ensures that only the essential framework code is included when other projects consume it.

## 🆕 Latest Release: v7.8.8

### **Patch release**
🔧 **Patch**: Dynamic Type typography — `DynamicFontResolver` (#295), design-token scaling (#294), scalable `platformSystem` and `platformDecorativeIconFont` (#296). See [RELEASE_v7.8.8.md](Development/RELEASE_v7.8.8.md).

### **Previous Release: v7.8.7 - Patch release**
🔧 **Patch**: `PlatformTabStrip` public initializer for app-target consumers (#292). See [RELEASE_v7.8.7.md](Development/RELEASE_v7.8.7.md).

### **Previous Release: v7.8.6 - Patch release**
🔧 **Patch**: Vision OCR text-discovery bounding boxes in `OCROverlayView` with `OCRBoundingBoxLayout` geometry helpers (#291). See [RELEASE_v7.8.6.md](Development/RELEASE_v7.8.6.md).

### **Previous Release: v7.8.5 - Patch release**
🔧 **Patch**: Configurable Vision `minimumTextHeight` with pump-friendly default **0.003** for full-resolution pump LCD OCR (#288). See [RELEASE_v7.8.4.md](Development/RELEASE_v7.8.4.md).

### **Previous Release: v7.8.3 - Patch release**
🔧 **Patch**: Pump LCD label-anchored structured OCR (#282); calculation-group joint decimal correction (#283); printed price-per-gallon joint scoring (#284); Vision line layout anchoring (#285); fail-closed joint failure (#286); locale decimal parsing (#287). See [RELEASE_v7.8.3.md](Development/RELEASE_v7.8.3.md).

### **Previous Release: v7.8.2 - Patch release**
🔧 **Patch**: Layer 4 assistive visual adaptability matrix (#255) and semantic criterion evidence (#254); `platformMapView_L4` map contract accessibility and UIKit hosting; XCUITest scroll/query stabilization for L4 System and SD150 integration flows; duplicate CloudKit sync status accessibility identifier fix. See [RELEASE_v7.8.2.md](Development/RELEASE_v7.8.2.md).

### **Previous Release: v7.8.1 - Patch release**
🔧 **Patch**: Structured OCR inclusive extraction and Layer 2 forwarding (#279); `PlatformImage` EXIF capture date and orientation writers (#275); Layer 4 accessibility identifiers for CloudKit, photo picker, and UITest contract surfaces; agent `wip/` worktree checklist (#280); assorted UITest harness hardening and Layer 4 compile/`platformPrint_L4` isolation fixes. See [RELEASE_v7.8.1.md](Development/RELEASE_v7.8.1.md).

### **Previous Release: v7.8.0 - Minor release**
📋 **Minor**: `PresentationProfilesCatalog` and bundled profile hints (#277); `ItemCollectionPresentationStrategyResolver` with optional `"card"` row style on custom list collections (#272); optional `DynamicForm` draft storage key (#273); `PlatformImage` EXIF configuration (#275); system-action contract updates for `openURL` and remote notifications (#256 / #169). See [RELEASE_v7.8.0.md](Development/RELEASE_v7.8.0.md).

### **Previous Release: v7.7.2 - Patch release**
🔧 **Patch**: Fixes the `LocationService` main-thread services-enabled check (#258), wires `DynamicImageField` into image/photo selection and form state (#265), clarifies Layer 1 dynamic field preview docs (#267), and refreshes release metadata (#270). See [RELEASE_v7.7.2.md](Development/RELEASE_v7.7.2.md).

### **Previous Release: v7.7.1 - Patch release**
🔧 **Patch**: Restores explicit list accessibility identifier runtime contract discoverability for UI-test consumers (Issue #257), with release-lane test stabilization updates. See [RELEASE_v7.7.1.md](Development/RELEASE_v7.7.1.md).

### **Previous Release: v7.7.0 - Minor release**
📋 **Minor**: VisionKit live data scanner Layer 4 path (#252) and runtime capability namespacing/co-ship completion (#253), including new namespaced probes (`Network`, `Media`, `Pasteboard`, `Accessibility`) with test overrides and teardown. Also includes release-process support updates from issues #246 and #247. See [RELEASE_v7.7.0.md](Development/RELEASE_v7.7.0.md).

### **Previous Release: v7.6.2 - Patch release**
🔧 **Patch**: Viewport-aware intelligent and optimal card layout (#249, #250); runtime capability test isolation on MainActor in `DefaultRuntimeCapabilityIsolationTrait`; tvOS `SLF-tvOS-AllTests` compile (#237); internal test harness (#247 — no `AccessibilityIdentifierConfig.shared` mutation in tests; #248 — mac/iOS drift). See [RELEASE_v7.6.2.md](Development/RELEASE_v7.6.2.md).

### **Previous Release: v7.6.1 - Patch release**
🔧 **Patch**: Layer 1 `automaticCompliance` audit (#245 / gh-243 parity with #243): `identifierName:` presentation roots and anonymous shells where appropriate. See [RELEASE_v7.6.1.md](Development/RELEASE_v7.6.1.md).

### **Previous Release: v7.6.0 - Minor release**
📋 **Minor**: Managed settings migration documentation and consumer migration guidance (Issue #215). See [RELEASE_v7.6.0.md](Development/RELEASE_v7.6.0.md).

### **Previous Release: v7.5.13 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.13.md](Development/RELEASE_v7.5.13.md).

### **Previous Release: v7.5.12 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.12.md](Development/RELEASE_v7.5.12.md).

### **Previous Release: v7.5.11 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.11.md](Development/RELEASE_v7.5.11.md).

### **Previous Release: v7.5.10 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.10.md](Development/RELEASE_v7.5.10.md).

### **Previous Release: v7.5.9 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.9.md](Development/RELEASE_v7.5.9.md).

### **Previous Release: v7.5.8 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.8.md](Development/RELEASE_v7.5.8.md).

### **Previous Release: v7.5.7 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.7.md](Development/RELEASE_v7.5.7.md).

### **Previous Release: v7.5.6 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.6.md](Development/RELEASE_v7.5.6.md).

### **Previous Release: v7.5.5 - Patch release**
🔧 **Patch**: See [RELEASE_v7.5.5.md](Development/RELEASE_v7.5.5.md).

### **Previous Release: v7.5.4 - Injected state, drop-in, test stability**
🔧 **Patch**: Optional injected FormWizardView/DynamicFormView state (#187, #186, #185), platformTextEditor(text:) strict drop-in (#164), test and build stability fixes.

### **Previous Release: v7.5.3 - Modifier debug logs gated**
🔧 **Patch**: All accessibility modifier debug logs only print when `AccessibilityIdentifierConfig.shared.enableDebugLogging` is true.

### **Previous Release: v7.5.2 - verboseMinClamping debug flag**
🔧 **Patch**: Optional `PlatformFrameHelpers.verboseMinClamping` flag; when `true`, logs when platformFrame clamps min width/height to fit available space. Resolves #183.

### **Previous Release: v7.5.1 - platformFrame Min Clamping Fix**
🔧 **Bugfix**: Clamp minWidth/minHeight on iOS and watchOS/tvOS/visionOS to 90% of available space when they exceed screen size, preventing overflow. Matches macOS behavior. Fixes #182.

### **Previous Release: v7.5.0 - Minor Release**
📋 **Documentation & quality**: Release notes, AI agent guide, and version consistency updates. Resolved 20 issues from milestone v7.5.0. Fully backward compatible.

### **Previous Release: v7.4.2 - @MainActor Concurrency Fix for platformFrame**
🔧 **Concurrency Correctness**: Added `@MainActor` annotation to `platformFrame()` functions to ensure correct Swift concurrency behavior. Makes concurrency requirements explicit and allows functions to be called from non-isolated contexts with `await`. Aligns with Swift 6 strict concurrency requirements.

### **Previous Release: v7.4.1 - idealWidth and idealHeight Support for platformFrame**
🆕 **Complete Frame API**: Added `idealWidth` and `idealHeight` parameter support to `platformFrame()` to match SwiftUI's native `.frame()` modifier API. Ideal sizes are automatically clamped to screen/window bounds on all platforms. Implementation simplified for better maintainability.

### **Previous Release: v7.4.0 - PhotoPurpose Refactoring (⚠️ Breaking Change)**
⚠️ **BREAKING CHANGE**: `PhotoPurpose` converted from enum to struct. Vehicle-specific cases (`vehiclePhoto`, `fuelReceipt`, etc.) removed and replaced with generic purposes (`.general`, `.document`, `.profile`, `.reference`, `.thumbnail`, `.preview`). Projects can maintain backward compatibility using extension aliases. See migration guide in release notes.

### **Previous Release: v7.3.0 - Convenience Aliases and Code Quality Improvements**
🆕 **Platform Container Stack Aliases**: Added shorter convenience aliases `platformVStack`, `platformHStack`, and `platformZStack` for more intuitive API names. Refactored iCloud availability checks for improved code clarity.

### **Previous Release: v7.2.0 - Configurable Photo Sources for OCR Scanner**
🆕 **FieldActionOCRScanner Enhancement**: Added configurable photo source options. Developers can now choose whether to offer camera, photo library, or both options to end users, with automatic device capability detection and graceful fallbacks.

### **Previous Release: v7.1.0 - Color Resolution System from Hints Files**
🆕 **ItemBadge and ItemIcon Components**: New components that automatically resolve colors from hints files. Supports colorName and fileExtension provider types. Card components now support optional badge content.

### **Previous Release: v7.0.2 - Hints File Presentation Properties Support**
🆕 **Presentation Properties in Hints Files**: Added support for `_dataType`, `_complexity`, `_context`, `_customPreferences`, and `_presentationPreference` in `.hints` files. All PresentationHints properties can now be configured declaratively in hints files, matching code-based functionality.

### **Previous Release: v7.0.1 - Hints File Color Configuration Support**
🆕 **Color Configuration in Hints Files**: Added support for `_defaultColor` and `_colorMapping` in `.hints` files. Color configuration can now be stored in hints files and automatically loaded when creating `PresentationHints` from model names.

### **Previous Release: v7.0.0 - Breaking Changes**
⚠️ **BREAKING CHANGE**: `CardDisplayable` protocol no longer includes `cardColor` property. Color configuration is now done via `PresentationHints` at the presentation layer. Models are now SwiftUI-free and can be used in Intent extensions.

🆕 **PresentationHints Color Configuration**: Added type-based color mapping, per-item color provider, and default color support. Color decisions are now made at the presentation layer, following 6-layer architecture principles.

### **Previous Release: v6.8.0 - DRY Improvements - Platform Switch Consolidation**
🔧 **PlatformStrategy Module**: Consolidated 19 platform switch statements into a centralized `PlatformStrategy` module. Eliminated 4 duplicate functions. Total: 23 code duplications eliminated. Single source of truth for platform-specific simple values.

🔄 **Runtime Check Pattern Consistency**: Established consistent pattern for runtime capability checks in `PlatformStrategy`. Ensures platform-specific values are only returned when capabilities are actually available.

### **Previous Release: v6.7.0 - Test Fixes & Count-Based Presentation**
🆕 **Count-Based Automatic Presentation**: Added intelligent count-aware presentation strategy selection. `.automatic` presentation preference now considers item count for generic/collection content, with platform-aware thresholds. Added `.countBased(lowCount:highCount:threshold:)` enum case for explicit control.

🔧 **Touch Target Test Fixes**: Fixed touch target minimum tests to correctly validate Apple HIG compliance. Tests now correctly expect 44.0 minimum touch target when touch is enabled, with tolerance-based floating point comparison.

🧪 **Test Infrastructure Improvements**: Added frame size safety checks, fixed resource warnings in Swift Package Manager builds, removed platform mocking code from tests, and cleaned up test warnings.

### **Previous Release: v6.6.3 - ScrollView Wrapper Fixes**
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
- **[Roadmap](Development/ROADMAP.md)** - Development phases and progress
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

**Version**: v7.8.8 (Patch)
**Phase**: Patch release
**Next**: TBD

## 🤝 Contributing

Please read the development documentation in the `Development/` directory before contributing. The framework follows a strict six-layer architecture pattern.

---

**Note**: This repository structure separates framework code from development files, ensuring clean package distribution while maintaining development transparency.
