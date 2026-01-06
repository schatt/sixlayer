# SixLayer Framework

[![Version](https://img.shields.io/badge/version-v7.0.0-blue.svg)](https://github.com/schatt/sixlayer/releases/tag/v7.0.0)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B%20%7C%20macOS%2013%2B-lightgrey.svg)](https://github.com/schatt/6layer)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)

A modern, intelligent UI framework that provides a six-layer abstraction architecture for cross-platform Swift development. This framework eliminates platform-specific UI code while maintaining native performance and user experience.

> **🤖 For AI Assistants**: This framework has a specific architecture that requires careful understanding. **Start with the [AI Agent Quick Reference](docs/AI_AGENT_QUICK_REFERENCE.md)** (~400 lines, fits in context windows) for essential guidelines. For comprehensive details, see the [full AI Agent Guide](docs/AI_AGENT_GUIDE.md) (3600+ lines). Both contain critical information about the Layer 1 Semantic Intent philosophy and common mistakes to avoid.

## 🏗️ Architecture Overview

The SixLayer Framework implements a sophisticated six-layer UI abstraction that transforms semantic intent into intelligent, platform-optimized layouts:

```
Layer 1: Semantic Intent → Layer 2: Layout Decision → Layer 3: Strategy Selection → Layer 4: Component Implementation → Layer 5: Platform Optimization → Layer 6: Platform System
```

### Layer Breakdown

- **Layer 1 (Semantic)**: Express what you want to achieve, not how
- **Layer 2 (Decision)**: Intelligent layout analysis and decision making
- **Layer 3 (Strategy)**: Optimal layout strategy selection
- **Layer 4 (Implementation)**: Platform-agnostic component implementation
- **Layer 5 (Optimization)**: Platform-specific enhancements and optimizations
- **Layer 6 (System)**: Direct platform system calls and native implementations

## 🚀 Key Features

- **Cross-Platform**: Write once, run on iOS and macOS
- **Intelligent Layout**: AI-driven layout decisions based on content and context
- **Field-Level Display Hints (v4.8.0)**: Declarative `.hints` files for data presentation
- **Automatic Data Binding (v5.8.0)**: `DataBinder` automatically created for real-time model updates
- **Layout Reasoning**: Transparent decision-making with detailed reasoning for debugging and analytics
- **Performance Optimized**: Native performance with intelligent caching
- **Accessibility First**: Built-in accessibility enhancements with automatic identifier generation
- **Enhanced Breadcrumb System**: Comprehensive UI testing with view hierarchy tracking and automatic test code generation
- **Type Safe**: Full Swift type safety with compile-time validation
- **Extensible**: Easy to extend with custom layers and strategies
- **Comprehensively Tested**: 800+ tests with platform-aware testing and mandatory TDD implementation
- **DRY Architecture**: Define hints once in files, use everywhere automatically

## 🆕 What's New in v6.4.2

### Platform Bottom-Bar Toolbar Placement Helper
- **Cross-Platform Abstraction**: Added `platformBottomBarPlacement()` function for bottom-aligned toolbar items
- **iOS Support**: Returns `.bottomBar` for full-width bottom toolbar items on iOS
- **macOS Fallback**: Returns `.automatic` on macOS and other platforms
- **Consistent API**: Follows existing `PlatformToolbarPlacement` pattern for platform-agnostic toolbar configuration
- **Resolves Issue #125**: Provides official SixLayer-level API for bottom-bar placement

See the [Release Notes](../Development/RELEASE_v6.4.2.md) for complete documentation.

---

## 🆕 What's New in v6.0.0

### Intelligent Device-Aware App Navigation
- **Complete 6-layer implementation**: Automatic navigation pattern selection based on device type, orientation, and screen size
- **Semantic intent API**: Express navigation intent without device detection code via `platformPresentAppNavigation_L1()`
- **Intelligent automation**: Framework automatically chooses between `NavigationSplitView` and detail-only navigation
- **Platform-aware**: Handles iPad, iPhone, macOS with optimal patterns for each
- **State management**: Optional bindings with automatic defaults
- **Comprehensive testing**: 22 tests across all 4 layers

See the [Release Notes](../Development/RELEASE_v6.0.0.md) for complete documentation.

### Platform Toolbar Placement Helpers
- **Cross-platform toolbar abstraction**: Four helper functions eliminate platform-specific toolbar placement code
- **Semantic placements**: iOS/watchOS/visionOS use semantic placements (`.confirmationAction`, `.cancellationAction`, `.primaryAction`, `.secondaryAction`)
- **Version handling**: iOS 16+/watchOS 9+ availability checks with fallbacks
- **All platforms supported**: Explicit handling for iOS, macOS, watchOS, tvOS, and visionOS

```swift
.toolbar {
    ToolbarItem(placement: platformConfirmationActionPlacement()) {
        Button("Save") { save() }
    }
    ToolbarItem(placement: platformCancellationActionPlacement()) {
        Button("Cancel") { cancel() }
    }
}
```

### PlatformSpacing HIG Alignment
- **8pt grid system**: All spacing values follow Apple's Human Interface Guidelines with 8pt grid
- **Platform-specific values**: macOS uses slightly tighter spacing (12, 20) while maintaining grid alignment
- **Explicit platform handling**: All platforms (iOS, macOS, watchOS, tvOS, visionOS) handled explicitly
- **Consistent API**: Single source of truth for spacing, padding, and corner radius values

```swift
VStack(spacing: PlatformSpacing.medium) {
    Text("Title")
    Text("Subtitle")
}
.padding(PlatformSpacing.padding)
.cornerRadius(PlatformSpacing.cornerRadius)
```

See the [Platform-Specific Patterns Guide](docs/platform-specific-patterns.md#platform-specific-spacing) for complete documentation.

### Platform Settings Container
- **Device-aware settings views**: `platformSettingsContainer_L4()` automatically chooses optimal presentation pattern
- **Intelligent selection**: iPad/macOS use split view, iPhone uses NavigationStack with conditional detail
- **State management**: Handles column visibility and category selection automatically

### Cross-Platform File System Utilities
- **Home directory access**: `platformHomeDirectory()` for cross-platform home directory
- **Application Support**: `platformApplicationSupportDirectory(createIfNeeded:)` with optional directory creation
- **Documents directory**: `platformDocumentsDirectory(createIfNeeded:)` for user documents
- **iCloud Drive integration**: Optional iCloud container support
- **Safe error handling**: All functions return `URL?` for graceful error handling

### Platform Navigation Extensions
- **Navigation title display mode**: `platformNavigationTitleDisplayMode()` eliminates platform conditionals
- **Cross-platform API**: iOS applies the mode, macOS is no-op

## 🆕 What's New in v5.8.0

### Cross-Platform Printing Solution
- **Unified printing API**: Single API works on both iOS and macOS via `platformPrint_L4`
- **Multiple content types**: Supports text, images, PDFs, and SwiftUI views
- **Photo-quality printing**: Automatic photo-quality printing for images (iOS)
- **PlatformImage integration**: Accepts `PlatformImage` directly (no manual conversion needed)
- **Error handling**: Graceful handling when no printer is available
- **Accessibility**: Automatic accessibility identifiers and full VoiceOver support
- **Comprehensive testing**: 12 tests covering all functionality
- **Complete documentation**: Full guide with usage examples

See the [Platform Print Layer 4 Guide](Framework/docs/PlatformPrintLayer4Guide.md) for complete documentation.

### Automatic Data Binding for IntelligentFormView
- **Automatic DataBinder creation**: `DataBinder` is automatically created when generating forms (opt-out available)
- **Real-time model updates**: Form field changes automatically update bound models via `dataBinder.updateField()`
- **Picker field integration**: Picker fields now integrate with `DataBinder` for enum field updates
- **Opt-out support**: Set `autoBind: false` to disable automatic binding for read-only forms, immutable models, or external state management
- **Backward compatible**: Existing code continues to work without changes
- **Comprehensive testing**: 10 tests covering all auto-binding functionality
- **Complete documentation**: Full guide with examples, limitations, and troubleshooting

See the [IntelligentFormView Auto-Binding Guide](Framework/docs/IntelligentFormViewAutoBindingGuide.md) for complete documentation.

### Automatic Data Binding for IntelligentFormView
- **Automatic DataBinder creation**: `DataBinder` is automatically created when generating forms (opt-out available)
- **Real-time model updates**: Form field changes automatically update bound models via `dataBinder.updateField()`
- **Picker field integration**: Picker fields now integrate with `DataBinder` for enum field updates
- **Opt-out support**: Set `autoBind: false` to disable automatic binding for read-only forms, immutable models, or external state management
- **Backward compatible**: Existing code continues to work without changes
- **Comprehensive documentation**: Full guide with examples, limitations, and troubleshooting

See the [IntelligentFormView Auto-Binding Guide](Framework/docs/IntelligentFormViewAutoBindingGuide.md) for complete documentation.

### Enum Picker Support in Hints Files
- **Picker options**: Add `inputType: "picker"` and `options` array to hints files for enum fields
- **Human-readable labels**: Display labels in UI while storing raw enum values in model
- **Cross-platform**: Works on both macOS (menu style) and iOS (menu style)
- **Backward compatible**: Existing hints files without `inputType` continue to work

See [Issue #40](https://github.com/schatt/6layer/issues/40) for details.

## 🆕 What's New in v5.7.1

### Value Range Validation for OCR Extraction
- **Value ranges in hints files**: Define acceptable numeric ranges via `expectedRange` in hints files (e.g., `{"min": 5.0, "max": 30.0}`).
- **Runtime range overrides**: Override hints file ranges at runtime using `OCRContext.fieldRanges` for dynamic contexts (e.g., different ranges for trucks vs motorcycles).
- **Automatic validation**: Out-of-range OCR values are automatically filtered during extraction.
- **Calculation group integration**: Removed out-of-range values allow calculation groups to fill in correct values.
- **Comprehensive testing**: Range validation tests cover boundaries, precedence, and edge cases.

### Previous Release: v5.7.0 – Automatic OCR Hints & Structured Extraction Intelligence
- **Configurable entity mapping**: `OCRContext` gains `entityName: String?`, letting projects dictate which `.hints` file to load (or opt out entirely).
- **Automatic hints loading**: `OCRService` now pulls `{entityName}.hints`, converts every field's `ocrHints` into regex patterns, and merges them with built-in/custom hints.
- **Calculation group evaluation**: Structured extraction automatically runs hint-defined formulas (sorted by priority) via `NSExpression` to derive missing totals/prices.

## 🧪 Comprehensive Testing Framework

### **Test Coverage Statistics**
- **Total Tests**: 800+ comprehensive tests
- **Test Success Rate**: 99.6% (3 minor failures in OCR async tests)
- **Platform Coverage**: iOS, macOS, watchOS, tvOS, visionOS
- **Device Coverage**: iPhone, iPad, Mac, Apple Watch, Apple TV, Vision Pro
- **Accessibility Tests**: 23 comprehensive tests for automatic accessibility identifiers

### **Testing Architecture**
- **Platform-Aware Testing**: Tests all platform combinations from a single test environment
- **Capability Matrix Testing**: Validates both detection and behavior of platform capabilities
- **Accessibility Testing**: Comprehensive testing of accessibility preferences and states
- **TDD Implementation**: Test-Driven Development for critical components
- **Platform Simulation**: Simulate different platform/device combinations without actual hardware

### **Test Categories**
- **Platform Matrix Tests**: Test all platform/device combinations
- **Capability Combination Tests**: Test how multiple capabilities interact (e.g., Touch + Hover on iPad)
- **Platform Behavior Tests**: Test that functions behave differently based on platform capabilities
- **Accessibility Preference Tests**: Test behavior when accessibility preferences are enabled/disabled
- **Vision Safety Tests**: Test OCR and Vision framework safety features
- **Comprehensive Integration Tests**: Cross-layer functionality testing

## 🆕 What's New in v4.8.0

### Field-Level Display Hints System
- **Declarative Data Presentation**: Create `.hints` files that describe how data should be presented
- **DRY Architecture**: Define hints once, automatically applied everywhere
- **Organized Storage**: Hints stored in `Hints/` folder by model name
- **Display Width System**: `narrow`, `medium`, `wide`, or numeric widths
- **Automatic Discovery**: 6Layer reads hints based on `modelName` parameter
- **Cached Loading**: Hints loaded once and reused for performance

```swift
// Create Hints/User.hints
{
  "username": { "displayWidth": "medium", "expectedLength": 20 },
  "email": { "displayWidth": "wide" }
}

// Use in your views
platformPresentFormData_L1(
    fields: userFields,
    hints: EnhancedPresentationHints(...),
    modelName: "User"  // 6Layer reads User.hints automatically!
)
```

**📚 Full documentation**: [Field Hints Complete Guide](docs/FieldHintsCompleteGuide.md)

## 🆕 What's New in v5.4.0

### OCR Hints, Calculation Groups, Internationalization, and OCR Overlay Sheets

- **OCR Hints in Hints Files**: Define OCR hints directly in `.hints` files for intelligent form-filling
- **Calculation Groups in Hints Files**: Declarative calculation groups for automatic field computation
- **Internationalization Support**: Language-specific OCR hints with automatic fallback
- **OCR Overlay Sheet Modifier**: Convenient `ocrOverlaySheet()` view modifier for presenting OCR results in a sheet (Issue #22)
- **100% Backward Compatible**: Existing hints files continue to work without modification

## 🆕 What's New in v5.1.0

### **PlatformImage EXIF GPS Location Extraction**
📸 **Cross-Platform EXIF Access**: New `PlatformImageEXIF` struct provides clean API for accessing EXIF metadata  
📍 **GPS Location Extraction**: `image.exif.gpsLocation` returns `CLLocation?` from image EXIF metadata  
🔧 **Platform Abstraction**: Eliminates need for platform-specific code (`UIImage` on iOS, `NSImage` on macOS)  
✅ **Comprehensive EXIF Parsing**: Supports decimal degrees and degrees/minutes/seconds coordinate formats  
🛡️ **Error Handling**: Returns `nil` gracefully for images without GPS metadata or invalid data  

**Use Cases:**
- Fuel receipt OCR: Extract location from receipt photos to identify gas stations
- Photo organization: Group photos by location
- Travel logging: Track where photos were taken
- Location-based features: Use photo location for context-aware functionality

**Example Usage:**
```swift
let image = PlatformImage(data: imageData)
if let location = image?.exif.gpsLocation {
    print("Photo taken at: \(location.coordinate.latitude), \(location.coordinate.longitude)")
}
```

**Implementation**: Implements [GitHub Issue #21](https://github.com/schatt/6layer/issues/21)

## 🆕 What's New in v5.0.0

### **Major Testing and Accessibility Release**
🎯 **Complete TDD Implementation**: Framework now follows strict TDD principles throughout development
♿ **Advanced Accessibility Overhaul**: Complete accessibility system with automatic identifier generation
🧪 **Testing Infrastructure Revolution**: Comprehensive testing with 800+ tests and full platform coverage

### **TDD (Test-Driven Development) Maturity**
- **Complete TDD Implementation**: Strict TDD principles throughout all development phases
- **Green Phase Completion**: All stub components replaced with comprehensive behavioral tests
- **Test Coverage Enhancement**: Added comprehensive TDD tests for all framework components
- **Behavior Verification**: Replaced stub-verification tests with proper behavior validation

### **Advanced Accessibility System**
- **Automatic Accessibility Identifier Generation**: Complete overhaul of accessibility ID system
- **Component Integration**: Added `.automaticAccessibilityIdentifiers()` to all framework components
- **Global Accessibility Configuration**: Unified accessibility settings across all layers
- **Pattern Standardization**: Consistent accessibility identifier patterns across platforms
- **Apple HIG Compliance**: Full compliance with Apple's Human Interface Guidelines

### **Testing Infrastructure Revolution**
- **Suite Organization**: Added `@Suite` annotations for better Xcode test navigator integration
- **Platform Test Coverage**: Complete iOS/macOS platform test branch coverage
- **Test Documentation**: Comprehensive testing commands documentation for macOS and iOS
- **Cross-Platform Testing**: Enhanced platform mocking and capability testing

### **Platform Capability Detection**
- **AssistiveTouch Detection**: Proper runtime detection for iOS AssistiveTouch functionality
- **VisionOS Capabilities**: Accurate touch/hover/haptic capability detection for visionOS
- **Touch Target Optimization**: Platform-native minTouchTarget values (0 for macOS/tvOS/visionOS)
- **Hover Delay Configuration**: Runtime capability detection for hover delay settings

---

## 🆕 What's New in v4.9.1

### **Deterministic Field Ordering for IntelligentFormView**
- **FieldOrderRules**: Explicit field ordering with lists, weights, groups, and trait overrides
- **Trait-Aware Overrides**: Different ordering for `.compact` and `.regular` size classes
- **App-Wide Provider**: Runtime configuration via `IntelligentFormView.orderRulesProvider`
- **Title/Name First Default**: Smart prioritization of important fields (no more alphabetic sorting)
- **Debug Support**: `inspectEffectiveOrder` helper for runtime analysis

### **Accessibility Improvements**
- **Stable Identifier Generation**: Consistent accessibility IDs in UI test mode
- **Disabled Mode Corrections**: Fixed regex handling and test helper fallbacks
- **Priority Clarification**: Clear guidance on mixing manual IDs with `.named`/`.exactNamed`

### **Platform Optimization (L5)**
- **macOS Touch Target**: Positive default `minTouchTarget` for macOS configuration

---

## 🆕 What's New in v3.5.0

### 🎯 Dynamic Form Grid Layout
- **NEW**: Horizontal grid layout support for form fields
- Fields with `gridColumn` metadata now render in `LazyVGrid` instead of vertical stack
- Automatic grid detection based on field metadata
- Backward compatible - existing forms continue to work unchanged

### 🏷️ Label Duplication Fix
- Fixed duplicate labels in DatePicker, ColorPicker, Toggle, and TextEditor fields
- Implemented shared self-labeling control helper for DRY compliance
- All self-labeling controls now use consistent label policy

### 🧪 Enhanced Testing
- Added comprehensive TDD tests for grid layout functionality
- Added label duplication prevention tests
- Improved test coverage for form field behavior

## 🆕 What's New in v2.8.1

### **Complex Forms Best Practices Documentation**
- **Comprehensive Guide**: New detailed guide for AI agents on handling complex forms
- **5 Better Approaches**: Composition, Protocol-Based Fields, View Modifiers, Focused Extensions, Pure SwiftUI
- **Platform Independence**: Guidelines for using 6-layer platform utilities in custom SwiftUI code
- **Anti-Patterns**: Clear guidance on what to avoid when building complex forms
- **Decision Matrix**: Help developers choose the right approach for their use case

## 🆕 What's New in v2.8.0

### **Comprehensive Callback Integrations**
- **Validation Error Display Integration**: FormStateManager errors now automatically display in UI
- **Window Detection → Layout Updates**: Automatic layout recalculation on window size changes
- **Analytics Integration**: FormAnalyticsManager now tracks all form interactions
- **Accessibility State Updates**: UI automatically updates when accessibility settings change
- **Theme Change Updates**: UI automatically updates when system theme changes
- **Input Handling Integration**: InputHandlingManager provides haptic feedback and input optimization

## 🆕 What's New in v2.7.2

### **Form Field Callback Integration**
- **Connected onValueChange callbacks**: Implemented callback connection in DefaultPlatformFieldView
- **Integrated with DataBinder**: Field changes now trigger data binding system updates
- **Added FormStateManager integration**: Field updates trigger form state changes
- **Implemented real-time validation**: Validation triggers on field value changes
- **Added change tracking**: Connected to existing change tracking infrastructure
- **Enhanced form functionality**: Forms now properly update underlying data models

## 🆕 What's New in v2.7.1

### **Generic Types Clarification**
- **Fixed AI documentation confusion**: Clarified that GenericItemCollection is a VIEW, not a type
- **Added correct usage examples**: Shows how to use business types with generic functions
- **Added warning sections**: Prevents common mistakes in type usage
- **Enhanced AI agent guidance**: Better understanding of framework architecture

## 🆕 What's New in v2.7.0

### **AI Documentation Overhaul**
- **Fixed AI_AGENT_GUIDE.md**: Corrected all incorrect API references and method signatures
- **Updated 6layerapi.txt**: Replaced outdated implementation plan with current API functions
- **Added proper API links**: Direct links to actual source files for AI agents
- **Corrected method signatures**: Fixed PerformanceBenchmarking and CrossPlatformTesting usage examples

### **Test Suite Optimization**
- **Eliminated hanging test issues**: Removed problematic OCR test files causing timeouts
- **Cleaned up test artifacts**: Removed compiled object files from git tracking
- **Improved .gitignore**: Added comprehensive build artifact patterns
- **Created test recreation tasks**: Added todo items for future test reimplementation

### **Repository Cleanup**
- **Archived historical releases**: Moved old releases to organized archive structure
- **Enhanced .gitignore**: Added patterns for compiled objects and Swift build artifacts
- **Organized release structure**: Clean separation between current and historical releases

## 🆕 What's New in v2.2.0

### **🧪 Comprehensive Testing Implementation**
- **790+ Tests**: Massive expansion from 800 to 790+ comprehensive tests
- **Platform-Aware Testing**: Test all platform combinations from a single environment
- **Capability Matrix Testing**: Test both detection and behavior of platform capabilities
- **Accessibility Testing**: Comprehensive testing of accessibility preferences and states
- **TDD Implementation**: Test-Driven Development for AccessibilityFeaturesLayer5.swift (100% coverage)
- **Platform Simulation**: Simulate different platform/device combinations without actual hardware

### **🔧 Testing Infrastructure**
- **Platform Capability Simulation**: Helper functions to simulate different platform capabilities
- **Capability Combination Testing**: Test how multiple capabilities interact (Touch + Hover on iPad)
- **Platform Behavior Testing**: Test that functions behave differently based on platform capabilities
- **Accessibility State Simulation**: Test various combinations of accessibility preferences
- **Vision Safety Testing**: Test OCR and Vision framework safety features

## 🆕 What's New in v2.1.1

### **🎨 Cross-Platform Color Aliases**
- **Simplified Color API**: Business logic can use simple names like `Color.backgroundColor` instead of `Color.platformBackground`
- **Cross-Platform Mapping**: All aliases automatically map to appropriate platform-specific colors
- **Business Logic Integration**: `Color.named()` method for resolving both system and custom color names
- **Comprehensive Coverage**: 13 new color aliases covering backgrounds, foregrounds, and UI elements
- **Test-Driven Implementation**: 25 new tests ensuring reliability and cross-platform consistency

### **🔧 Color System Enhancements**
- **Background Colors**: `backgroundColor`, `secondaryBackgroundColor`, `tertiaryBackgroundColor`, `groupedBackgroundColor`
- **Foreground Colors**: `foregroundColor`, `secondaryForegroundColor`, `tertiaryForegroundColor`, `quaternaryForegroundColor`
- **UI Elements**: `separatorColor`, `linkColor`, `placeholderForegroundColor`
- **Custom Resolution**: `Color.named()` supports both system colors and business logic color names
- **Zero Breaking Changes**: Pure feature addition that enhances existing API

## 🆕 What's New in v2.0.0

### **🔍 OCR (Optical Character Recognition) System**
- **Cross-Platform OCR**: Native iOS/macOS OCR using Apple's Vision framework with safe availability checks
- **Intelligent Text Recognition**: Smart text type detection (prices, dates, numbers)
- **Multi-Language Support**: Support for multiple languages with automatic detection
- **Document Analysis**: Intelligent document type detection (receipts, invoices, forms)
- **6-Layer OCR Architecture**: Complete OCR implementation following framework architecture
- **Safe Fallbacks**: Graceful degradation when Vision framework is unavailable
- **Platform Compatibility**: iOS 11.0+ and macOS 10.15+ with automatic detection

### **♿ Advanced Accessibility System**
- **VoiceOver Support**: Complete VoiceOver integration with announcement management
- **Keyboard Navigation**: Full keyboard navigation with focus management
- **High Contrast Mode**: Automatic high contrast support and theme adaptation
- **Dynamic Type**: Support for all accessibility text sizes
- **Accessibility Testing**: Comprehensive accessibility compliance validation
- **WCAG Compliance**: Web Content Accessibility Guidelines compliance

### **🚀 Framework Enhancements**
- **Unified OCR API**: Single API for all OCR operations across platforms
- **Accessibility Modifiers**: Easy-to-use accessibility enhancement modifiers
- **Performance Optimization**: Optimized OCR and accessibility performance
- **Comprehensive Testing**: OCR and accessibility test suites
- **Enhanced Documentation**: Complete guides for OCR and accessibility features

## 📋 Previous Release (v1.7.4)

- **Cross-Platform Color Utilities**: Comprehensive color system that eliminates platform-specific color code
- **Platform Color Extensions**: 20+ cross-platform color properties with intelligent fallbacks
- **Color Examples**: Complete usage examples for forms, lists, cards, and system colors
- **Comprehensive Testing**: 21 tests covering all color utilities and platform behaviors
- **Accessibility Support**: Colors work correctly with accessibility features and dark mode
- **Performance Optimized**: Fast color creation with consistent behavior across platforms

## 📋 Previous Release (v1.7.3)

- **Layout Decision Reasoning**: Transparent decision-making with detailed reasoning for debugging and analytics
- **Reasoning Examples**: Comprehensive examples showing debugging, analytics, and transparency usage
- **Reasoning Tests**: 11 tests verifying reasoning content and consistency
- **Documentation**: Complete documentation with practical usage examples
- **API Transparency**: Public reasoning properties for better developer experience

## 📋 Previous Release (v1.7.2)

- **Image Functionality**: Complete cross-platform image handling system
- **Photo Components**: Camera interface, photo picker, display, and editing
- **Input Handling & Interactions**: Platform-adaptive input behavior
- **Touch vs Mouse**: Intelligent interaction patterns for different input methods
- **Keyboard Shortcuts**: Platform-appropriate keyboard shortcut management
- **Haptic Feedback**: Smart haptic and sound feedback system
- **Drag & Drop**: Cross-platform drag and drop functionality
- **Gesture Recognition**: Swipe, pinch, and rotate gesture support
- **Comprehensive Testing**: 37 tests for Input Handling & Interactions
- **Photo Test Suite**: Complete test coverage for image functionality

## 📋 Previous Release (v1.7.1)

- **Licensing System**: Comprehensive tiered licensing model with honor system approach
- **Free Tier**: Personal projects, open source, educational use
- **Startup Tier**: Free for applications with < 1,000 users
- **Professional Tier**: $0.10/user/month for subscription applications
- **Enterprise Tier**: $2,500/year for internal commercial use
- **Honor System**: Trust-based compliance with clear documentation
- **Legal Framework**: Complete license terms and compliance guidelines

## 📱 Supported Platforms

- **iOS**: 16.0+
- **macOS**: 13.0+
- **Swift**: 5.9+

## 🛠️ Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/schatt/6layer.git", from: "5.0.0")
]
```

### Manual Installation

1. Clone the repository
2. Add the framework to your Xcode project
3. Link against the appropriate target for your platform

## 💻 Usage

### Basic Example

```swift
import SixLayerFramework

// Layer 1: Semantic intent
platformPresentItemCollection_L1(
    items: vehicles,
    hints: PresentationHints(
        dataType: .collection,
        presentationPreference: .cards,
        complexity: .moderate,
        context: .dashboard
    )
)
```

### Advanced Example

```swift
// Layer 1: Semantic form presentation
platformPresentFormData_L1(
    fields: formFields,
    hints: PresentationHints(
        dataType: .form,
        presentationPreference: .automatic,
        complexity: .complex,
        context: .input
    )
)
```

### Layout Decision Reasoning

The framework provides transparent decision-making with detailed reasoning for debugging and analytics:

```swift
// Get layout decision with reasoning
let decision = determineOptimalLayout_L2(
    items: items,
    hints: hints,
    screenWidth: 768.0,
    deviceType: .pad
)

// Access reasoning for debugging
print("Layout reasoning: \(decision.reasoning)")
// Output: "Layout optimized for current device and content: uniform approach with 1 columns, 8.0pt spacing, and standard performance"

// Use reasoning for analytics
analytics.track("layout_decision", properties: [
    "approach": decision.approach.rawValue,
    "reasoning": decision.reasoning
])
```

### Cross-Platform Color Utilities

Eliminate platform-specific color code with intelligent cross-platform color utilities:

```swift
// ❌ Before: Platform-specific code
#if os(iOS)
.foregroundColor(.tertiaryLabel)
#elseif os(macOS)
.foregroundColor(.secondary)
#endif

// ✅ After: Cross-platform utilities
.foregroundColor(.platformTertiaryLabel)
```

#### Available Color Utilities

```swift
// Label colors with intelligent fallbacks
Text("Primary Text")
    .foregroundColor(.platformPrimaryLabel)

Text("Secondary Text")
    .foregroundColor(.platformSecondaryLabel)

Text("Tertiary Text")
    .foregroundColor(.platformTertiaryLabel)

Text("Quaternary Text")
    .foregroundColor(.platformQuaternaryLabel)

// Text input colors
TextField("Placeholder", text: $text)
    .foregroundColor(.platformPlaceholderText)

// Separator colors
Divider()
    .background(Color.platformSeparator)

Rectangle()
    .fill(Color.platformOpaqueSeparator)
    .frame(height: 1)

// Background colors
VStack {
    // Content
}
.background(Color.platformBackground)

// System colors (consistent across platforms)
Text("Error")
    .foregroundColor(.platformDestructive)

Text("Success")
    .foregroundColor(.platformSuccess)
```

### Reasoning Examples

The framework includes comprehensive examples showing how to use reasoning properties:

- **Debugging**: Access reasoning to understand why specific layouts were chosen
- **Analytics**: Log reasoning for monitoring and optimization
- **Transparency**: Display reasoning to users for transparency
- **Testing**: Verify reasoning content in automated tests

See `PlatformUIExamples.swift` for complete working examples.

## 🔧 Extending the Framework

The SixLayer Framework is designed to be highly extensible. Developers can:

- **Create custom views** that integrate seamlessly with the framework
- **Use the hints system** to influence layout decisions and behavior
- **Leverage all six layers** for progressive enhancement
- **Maintain platform independence** while adding custom functionality

For comprehensive guidance on extending the framework, see:
- **[Developer Extension Guide](docs/DeveloperExtensionGuide.md)** - Complete guide for developers
- **[Hints System Extensibility](docs/HintsSystemExtensibility.md)** - Advanced customization
- **[Usage Examples](docs/README_UsageExamples.md)** - Practical examples and patterns

## 🏗️ Project Structure

```
6layer/
├── docs/                           # Documentation
├── src/                           # Source code
│   ├── Shared/                    # Shared components
│   │   ├── Views/                 # View implementations
│   │   │   └── Extensions/        # 6-layer extensions
│   │   ├── Models/                # Data models
│   │   ├── Services/              # Business logic
│   │   ├── Utils/                 # Utility functions
│   │   ├── Components/            # Reusable components
│   │   └── Resources/             # Assets and resources
│   ├── iOS/                       # iOS-specific implementations
│   └── macOS/                     # macOS-specific implementations
├── Tests/                         # Unit tests
├── project.yml                    # XcodeGen configuration
└── README.md                      # This file
```

## 📋 Changelog

### [v1.8.0] - 2025-01-15 (Licensing System & Legal Framework)
- **Licensing System**: Comprehensive tiered licensing model with honor system approach
- **Free Tier**: Personal projects, open source, educational use
- **Startup Tier**: Free for applications with < 1,000 users  
- **Professional Tier**: $0.10/user/month for subscription applications
- **Enterprise Tier**: $2,500/year for internal commercial use
- **Honor System**: Trust-based compliance with clear documentation
- **Legal Framework**: Complete license terms and compliance guidelines
- **Documentation**: Comprehensive licensing guide and implementation details
- **Transparency**: Clear pricing and usage guidelines for all tiers

### [v1.7.4] - 2025-09-04 (Cross-Platform Color Utilities)

#### 🎨 Cross-Platform Color System
- **Platform Color Extensions**: 20+ cross-platform color properties with intelligent fallbacks
- **Eliminates Conditional Compilation**: No more `#if os(iOS)` / `#elseif os(macOS)` for colors
- **Intelligent Fallbacks**: Automatic fallback colors for platform-specific color APIs
- **Consistent API**: Same color names work across iOS and macOS
- **Performance Optimized**: Fast color creation with consistent behavior

#### 🎯 Key Color Utilities
- **Label Colors**: `platformPrimaryLabel`, `platformSecondaryLabel`, `platformTertiaryLabel`, `platformQuaternaryLabel`
- **Text Colors**: `platformPlaceholderText` with platform-appropriate fallbacks
- **Separator Colors**: `platformSeparator`, `platformOpaqueSeparator` with intelligent mapping
- **Background Colors**: `platformBackground`, `platformSecondaryBackground`, `platformGroupedBackground`
- **System Colors**: All standard system colors with cross-platform consistency

#### 📚 Usage Examples & Documentation
- **Comprehensive Examples**: Complete usage examples for forms, lists, cards, and system colors
- **Before/After Comparison**: Clear examples showing the improvement over platform-specific code
- **Color Swatches**: Visual examples of all available colors
- **Form Examples**: Real-world usage in forms and input fields
- **List Examples**: Practical usage in list views and data display
- **Card Examples**: Usage in card-based layouts and content presentation

#### 🧪 Comprehensive Testing
- **21 Test Cases**: Complete test coverage for all color utilities
- **Platform Behavior Tests**: Verification of correct platform-specific behavior
- **Accessibility Tests**: Colors work correctly with accessibility features
- **Dark Mode Tests**: Proper behavior in both light and dark modes
- **Performance Tests**: Fast color creation and consistent behavior
- **Edge Case Tests**: Proper handling of different contexts and usage scenarios

#### 🔧 Technical Improvements
- **Type Safety**: Full Swift type safety for all color utilities
- **Documentation**: Complete inline documentation with usage examples
- **Error Handling**: Graceful error handling for all color operations
- **Backward Compatibility**: Fully backward compatible with existing code
- **Cross-Platform**: Consistent behavior across iOS and macOS platforms

### [v1.7.3] - 2025-09-04 (Layout Decision Reasoning)

#### 🧠 Layout Decision Reasoning
- **Transparent Decision-Making**: Detailed reasoning for all layout decisions
- **Debugging Support**: Access reasoning properties for debugging and troubleshooting
- **Analytics Integration**: Log reasoning for monitoring and optimization
- **User Transparency**: Display reasoning to users for transparency
- **Comprehensive Testing**: 11 tests verifying reasoning content and consistency

#### 📚 Documentation & Examples
- **Usage Examples**: Three comprehensive example views showing practical usage
- **Code Examples**: Complete working examples for debugging, analytics, and transparency
- **API Documentation**: Full documentation of reasoning properties and usage patterns
- **Developer Guide**: Clear guidance on how to use reasoning in applications

#### 🔧 Technical Improvements
- **Public API**: Reasoning properties are now documented as intentional public API features
- **Type Safety**: Full Swift type safety for reasoning properties
- **Performance**: Optimized reasoning generation with minimal overhead
- **Cross-Platform**: Reasoning works consistently across iOS and macOS

### [v1.7.2] - 2025-09-04 (Image Functionality & Input Handling)

#### 🖼️ Image Functionality
- **PlatformImage Type**: Cross-platform image handling with extensions
- **Image Manipulation**: Resizing, cropping, compression, thumbnail generation
- **Photo Components**: Camera interface, photo picker, display, and editing
- **Photo Strategy Selection**: Intelligent photo display strategy selection
- **Photo Layout Decisions**: Smart layout decisions for photo components
- **Photo Semantic Layer**: High-level photo operations and abstractions
- **Comprehensive Testing**: Complete test suite for photo functionality

#### 🎯 Input Handling & Interactions
- **Platform-Adaptive Input**: Intelligent input behavior based on platform
- **Touch vs Mouse**: Smart interaction patterns for different input methods
- **Keyboard Shortcuts**: Platform-appropriate keyboard shortcut management
- **Haptic Feedback**: Smart haptic and sound feedback system
- **Drag & Drop**: Cross-platform drag and drop functionality
- **Gesture Recognition**: Swipe, pinch, and rotate gesture support
- **Interaction Patterns**: Platform-specific interaction behavior
- **Comprehensive Testing**: 37 tests covering all input handling functionality

#### 🔧 Technical Improvements
- **Layout Decision Reasoning**: Transparent decision-making with detailed reasoning for debugging and analytics
- **Reasoning Examples**: Comprehensive examples showing debugging, analytics, and transparency usage
- **Reasoning Tests**: 11 tests verifying reasoning content and consistency
- **Cross-Platform Compatibility**: All new features work on iOS and macOS
- **Type Safety**: Full Swift type safety with compile-time validation
- **Performance**: Optimized for native performance
- **Accessibility**: Built-in accessibility enhancements
- **Documentation**: Comprehensive documentation and examples

### [v1.7.1] - 2025-01-15 (Build Quality & Framework Enhancement)
- **Build Quality Gate**: Comprehensive system for treating warnings as errors
- **Zero Warnings**: Fixed all redundant 'public' modifier warnings across codebase
- **Protocol Compliance**: Fixed all required protocol implementation methods (UIViewRepresentable, Encodable, etc.)
- **Modern APIs**: Updated deprecated NavigationLink usage to iOS 16+ standards
- **UI Consistency**: Ensured consistent behavior across iOS versions
- **CI/CD Integration**: GitHub Actions workflow for automated quality checks
- **Local Development**: Build quality check script and Makefile integration
- **Result**: Complete build quality system with zero warnings detected

### [v1.6.8] - 2024-12-19 (Ready for Release)
- **Phase 4 Week 13 Completion**: Cross-Platform Optimization Layer 6
- **Cross-Platform Optimization Manager**: Centralized management of platform-specific optimizations
- **Performance Benchmarking**: Comprehensive performance measurement and analysis tools
- **Platform UI Patterns**: Intelligent UI pattern selection based on platform capabilities
- **Memory Management**: Advanced memory strategies and performance optimization levels
- **Cross-Platform Testing**: Utilities for testing views across iOS, macOS, visionOS, and watchOS

### [v1.6.6] - 2024-12-19
- **Documentation Reorganization**: All documentation now visible in user's IDE for better discoverability
- **Professional Framework Structure**: Clean, organized framework distribution without development clutter
- **Complete Documentation**: Comprehensive guides, examples, and API references included
- **Performance & Accessibility**: Complete Phase 4 implementation with lazy loading, memory management, and accessibility features

### [v1.6.5] - 2025-01-15
- **Repository Restructuring**: Separated framework code from development files
- **Framework**: Moved to `Framework/` directory (clean package distribution)
- **Development**: Moved to `Development/` directory (maintains transparency)
- **Result**: Users get clean package view, developers see full structure

### [v1.6.4] - 2025-01-15
- **Package Distribution Cleanup**: Development files no longer included in distributed packages
- **Added**: `.swiftpmignore` to exclude internal development files
- **Result**: Users now get clean, professional framework packages
- **Maintained**: `Stubs/` directory included (contains framework functionality)

### [v1.6.3] - 2025-01-15
- **Phase 4 Completion**: Performance Optimization and Accessibility Features
- **Performance Optimization**: Lazy loading, memory management, performance profiling, caching strategies
- **Accessibility Features**: VoiceOver support, keyboard navigation, high contrast mode, accessibility testing
- **Build System**: Clean compilation for all platforms

### [v1.6.2] - 2025-01-15
- **Phase 3 Completion**: Advanced Form Types and Analytics
- **Advanced Field Types**: Rich text editor, autocomplete, file upload capabilities
- **Form Analytics**: Performance monitoring, error tracking, A/B testing, insights dashboard
- **Platform Compatibility**: iOS 16.0+ and macOS 13.0+ with proper availability checks

### [v1.6.1] - 2025-01-15
- **Phase 2 Completion**: Validation Engine and Form Management
- **Validation Engine**: Complete form validation system with custom rules and validation state management
- **Enhanced Form Types**: Complex form layouts and dynamic field generation
- **Improved Hints System**: Better layout decision making and customization

### [v1.6.0] - 2025-01-15
- **Phase 1 Completion**: Foundation and Core Architecture
- **Intelligent Layout Engine**: AI-driven layout decisions and optimization
- **Cross-Platform Components**: Unified UI components for iOS and macOS
- **Performance Optimizations**: Enhanced rendering and memory management

### [v1.3.0] - 2025-01-15
- **Public API Access**: All platform functions now have `public` access for external project integration
- **Updated Platform Support**: iOS 16.0+ and macOS 13.0+ with proper availability checks
- **Improved Build System**: Cleaner project structure and successful compilation
- **Enhanced Compatibility**: Better cross-platform support and reduced platform-specific issues

### [v1.2.0] - 2025-01-15
- **Validation Engine**: Complete form validation system with custom rules
- **Advanced Form Types**: Complex form layouts and dynamic field generation
- **Enhanced Hints System**: Improved layout decision making and customization

### [v1.1.0] - 2025-01-15
- **Intelligent Layout Engine**: AI-driven layout decisions and optimization
- **Cross-Platform Components**: Unified UI components for iOS and macOS
- **Performance Optimizations**: Enhanced rendering and memory management

### [v1.0.0] - 2025-01-15
- **Core Framework Foundation**: Basic six-layer architecture implementation
- **Platform Abstraction**: Initial cross-platform UI abstraction layer
- **Basic Components**: Fundamental UI components and extensions

## 🔧 Development

- Xcode 15.0+
- Swift 5.9+
- iOS 16.0+ / macOS 13.0+

### Building

1. Install XcodeGen: `brew install xcodegen`
2. Generate Xcode project: `xcodegen generate`
3. Open `SixLayerFramework.xcodeproj`
4. Build your target

### Testing

```bash
# Run all tests
xcodebuild test -scheme SixLayerFramework -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -scheme SixLayerFramework -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SixLayerFrameworkTests
```

## 📚 Documentation

### 🤖 **AI Agent Guide** (For AI Assistants)
- **[AI Agent Guide](docs/AI_AGENT_GUIDE.md)** - **Essential for AI assistants** working with the framework. Contains complete architecture understanding, correct usage patterns, and common mistakes to avoid.
- **NEW in v4.8.0**: [Field-Level Display Hints](docs/FieldHintsCompleteGuide.md) - Declarative data presentation system

### 📖 **Developer Documentation**
- [Six-Layer Architecture Overview](docs/six-layer-architecture-current-status.md)
- [Implementation Plan](docs/six-layer-architecture-implementation-plan.md)
- [API Reference](docs/6layerapi.txt)
- [Usage Examples](docs/README_UsageExamples.md)
- [Developer Extension Guide](docs/DeveloperExtensionGuide.md)
- [Custom Views & Business Logic Guide](docs/CustomViewsAndBusinessLogicGuide.md) - Complete guide for custom views and business logic integration
- [Function Index](docs/FunctionIndex.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

The SixLayer Framework uses a **tiered licensing model** based on usage and commercial nature:

- **Free Tier**: Personal projects, open source, educational use
- **Startup Tier**: Free for applications with < 1,000 users
- **Professional Tier**: $0.10/user/month for subscription applications
- **Enterprise Tier**: $2,500/year for internal commercial use
- **Enterprise Plus**: Custom pricing for high-volume applications

**Honor System**: No technical enforcement - we trust developers to comply with license terms.

For detailed licensing information, see:
- **[Complete License Terms](../LICENSE)** - Full license agreement
- **[Licensing Guide](docs/Licensing.md)** - Implementation and usage guide
- **[Contact Licensing](mailto:schatt+6layer@gmail.com)** - Questions and custom pricing

## 🙏 Acknowledgments

- Built on the foundation of the CarManager project
- Inspired by modern UI/UX design principles
- Community contributions and feedback

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/schatt/6layer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/schatt/6layer/discussions)
- **Documentation**: [Wiki](https://github.com/schatt/6layer/wiki)

---

**SixLayer Framework** - Intelligent UI abstraction for modern Swift development.
