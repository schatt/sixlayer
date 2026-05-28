# Changelog

## v7.8.9 - Accessibility: Reduce Motion + Increase Contrast (May 28, 2026)

### ✨ Added
- **`PlatformReduceMotionPreference`** and **`withPlatformAnimation`**: framework-owned reduce-motion policy for animation APIs (#298).
- **`PlatformContrastAccessibility.readableSecondary(contrast:)`**: maps `.secondary` → `.primary` when `colorSchemeContrast` is increased (#299).
- **`View.platformForegroundReadableSecondary()`**: view-scoped modifier for caption/subtitle text under **Increase Contrast** (#299).
- **`PlatformReduceMotionPreferenceTests`**, **`PlatformAnimationReduceMotionTests`**, **`PlatformContrastAccessibilityTests`**: unit/ViewInspector coverage with effective on/off assertions (#298, #299).

### 🧩 Changed
- **`platformAnimation`**, **`higAnimationCategory`**, and **`AutomaticHIGMotionPreferenceModifier`** respect reduce motion (environment + system APIs) (#298).
- **`AccessibilitySystemState`** and **`AccessibilityManager.isReduceMotionEnabled()`** read live system state instead of stubs (#298).
- **`RuntimeCapabilityDetection.isHighContrastEnabled`**: documented as **Darker System Colors**, not Increase Contrast (#299).

### 📚 Documentation
- CarManager: pin **`7.8.9`** after tag — reduce-motion via framework APIs (#438); replace `foregroundColorReadableSecondary()` with `platformForegroundReadableSecondary()` (#403).
- Full notes: [`Development/RELEASE_v7.8.9.md`](Development/RELEASE_v7.8.9.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.7 - PlatformTabStrip public initializer (May 25, 2026)

### ✨ Added
- **`PlatformTabStrip`**: `public init(selection: Binding<Int>, items: [PlatformTabItem])` for app-target consumers (#292).
- **`ExternalModuleIntegrationTests`**: `testPlatformTabStripAccessible` guards public API visibility (non-`@testable` import).

### 📚 Documentation
- CarManager and other external apps can replace duplicated report-type tab strips with `PlatformTabStrip` directly.
- Full notes: [`Development/RELEASE_v7.8.7.md`](Development/RELEASE_v7.8.7.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.6 - OCR overlay Vision bounding boxes (May 24, 2026)

### ✨ Added
- **`OCRBoundingBoxLayout`**: Vision normalized → image pixel → aspect-fit container geometry (#291).
- **`OCROverlayView`**: yellow discovery bounding boxes over aspect-fit OCR preview images (#291).
- **`OCROverlayConfiguration.showBoundingBoxes`** and **`highlightColor`** (default yellow).
- **`OCRBoundingBoxLayoutTests`**: SPM unit tests for layout helpers.

### 🧩 Changed
- **`convertBoundingBoxToImageCoordinates`** / tap detection use Vision bottom-left Y-flip (#291).
- Empty `boundingBoxes` shows **"No text regions detected"** when box display is enabled.

### 📚 Documentation
- Full notes: [`Development/RELEASE_v7.8.6.md`](Development/RELEASE_v7.8.6.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.5 - Numeric form field display coercion and test stabilization (May 21, 2026)

### ✨ Added
- **`DynamicFormStoredNumericDisplay`**: formats `Int`, `Double`, and `NSNumber` stored in `DynamicFormState` for numeric text fields (#289).
- **`DynamicFormField.numericTextBinding(in:)`**: read/write binding with numeric read coercion and `String` write.

### 🧩 Changed
- **`DynamicNumberField`** / **`DynamicIntegerField`**: use stored-value display helper; document draft key vs value typing in `FormAutoSaveGuide.md`.
- **Tests**: SD150 / L4 XCUITest scroll, keyboard, and integration-toggle stabilization; Layer 4 high-contrast hosting via `traitOverrides`.

### 🐛 Fixed
- Number/integer fields no longer render blank when hosts prefill `fieldValues` with numeric types (#289).

### 🔧 Build hygiene
- Deprecated `onChange(of:perform:)` in date/time pickers; `setOverrideTraitCollection` replaced in assistive adaptability tests; tautological `#expect(true)` removed from Layer 1 presentation tests.

### 📚 Documentation
- Full notes: [`Development/RELEASE_v7.8.5.md`](Development/RELEASE_v7.8.5.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.4 - Configurable Vision minimumTextHeight for pump LCD OCR (May 20, 2026)

### ✨ Added
- **`OCRVisionDefaults.minimumTextHeight`**: shared framework default (`0.003`) for Vision text recognition.
- **`OCRContext.visionMinimumTextHeight`**: per-request override (e.g. `0.01` for receipt-style documents) (#288).
- **`OCRVisionMinimumTextHeight288Tests`**: unit tests for default and custom threshold.

### 🧩 Changed
- **`OCRService`**, **`SafeVisionOCRView`**, and Layer2 OCR context copies apply `context.visionMinimumTextHeight` to `VNRecognizeTextRequest`.

### 🐛 Fixed
- Pump LCD digits no longer dropped on full-resolution iPhone photos when only printed labels were recognized (Vision size filter at `0.01` fraction of image height).

### 📚 Documentation
- Full notes: [`Development/RELEASE_v7.8.4.md`](Development/RELEASE_v7.8.4.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.3 - Pump label-anchored OCR and joint decimal correction (May 19, 2026)

### ✨ Added
- **`OCRLabelAnchoredExtraction`**: bidirectional hint regex binding with Vision line layout preference (#282, #285).
- **`OCRJointDecimalCorrection`**: calculation-group-driven joint decimal placement, printed PPG scoring, fail-closed ambiguous pairs, locale decimal parsing (#283–#287).

### 🧩 Changed
- **`OCRService`**: structured extraction and decimal correction delegate to dedicated OCR modules.

### 🐛 Fixed
- Split-arm regex extraction prevents pump LCD digit mis-binding (e.g. sale vs gallons on IMG5145).
- macOS capability runner: AssistiveTouch-vs-touch assertion only on platforms that ship AssistiveTouch.

### 📚 Documentation
- Full notes: [`Development/RELEASE_v7.8.3.md`](Development/RELEASE_v7.8.3.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.2 - L4 assistive adaptability, map a11y, UITest stabilization (May 17, 2026)

### ✨ Added
- **Layer 4 assistive visual adaptability** matrix tests and hosted helpers for VoiceOver, Switch Control, and increased contrast (#255).
- **Layer 4 semantic** hosted criterion tests and matrix evidence for split views, maps, forms, CloudKit, camera, photo, and related APIs (#254).

### 🧩 Changed
- **`platformMapView_L4`**: contract `accessibilityIdentifier`, container semantics, minimum frame, and `Group` wrapper for reliable UIKit a11y hosting.
- **XCUITest**: shared L4 System scroll helpers, CloudKit/photo query stabilization, SD150 secure-field and Form scroll budgets.

### 🐛 Fixed
- Duplicate **CloudKit sync status** accessibility identifier in L4 examples.

### 📚 Documentation
- Integration-branch pre-commit hook merge allowance; assistive/semantic test matrices updated.
- Full notes: [`Development/RELEASE_v7.8.2.md`](Development/RELEASE_v7.8.2.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.1 - OCR inclusive defaults, EXIF date/orientation writers, L4 a11y/UITest (May 14, 2026)

### ✨ Added
- **PlatformImage.exif** writers for **capture date** and **orientation** (extends #275): `with(captureDate:)`, `with(orientation:)`, and format-explicit overloads; tests in `PlatformImageEXIFTests`.
- **Structured OCR** inclusive extraction, uncategorized handling, and Layer 2 forwarding (#279); unit coverage for inclusive defaults.

### 🧩 Changed
- **Layer 4** accessibility identifiers for CloudKit, photo picker, and contract surfaces; **XCUITest** helper hardening (scroll, Form, keyboard, queries).
- **`platformPrint_L4`** isolated in view modifiers; Layer 4 compile hygiene in photo/scanner paths.

### 📚 Documentation
- Agent workflow: issue-linked **`wip/`** worktree checklist (#280).
- Full notes: [`Development/RELEASE_v7.8.1.md`](Development/RELEASE_v7.8.1.md), index [`Development/RELEASES.md`](Development/RELEASES.md).

---

## v7.8.0 - Presentation profiles, collections, EXIF, system actions (May 13, 2026)

### ✨ Added
- **Presentation profiles** catalog (#277): `PresentationProfilesCatalog`, bundled `PresentationProfiles.hints`, profile-keyed `PresentationHints`.
- **Item collection** presentation strategy resolver (#272); optional `rowVisualStyle` card chrome on custom list collections.
- Optional **DynamicForm** draft storage key separate from configuration id (#273).
- **PlatformImage** EXIF lossless read from original bytes (#274) and **EXIF writers** / stripping with `PlatformImageEXIFConfig` HEIC default (#275).
- **System-action** contract gaps closed for `openURL` and remote notifications (#256 / #169).

### 🧩 Changed
- **Platform color** token hygiene to reduce UIKit/AppKit drift (#276).

### 📚 Documentation
- Full notes: [`Development/RELEASE_v7.8.0.md`](Development/RELEASE_v7.8.0.md).

---

## v7.7.0 - VisionKit live scanner path (in preparation)

### ✨ Added
- New Layer 4 live scanner APIs (Issue #252):
  - `platformDataScannerContent_L4(...)`
  - `platformDataScannerInterface_L4(...)`
  - `platformDataScannerInterface_L4AsSheet(...)`
  - `platformDataScannerInterface_L4AsFullScreenCover(...)`
- New scanner configuration/types:
  - `PlatformDataScannerConfiguration`
  - recognized data kind filtering for text/barcodes
  - quality/highlighting/guidance/zoom/high-frame-rate/ROI/presentation options
- New scanner session lifecycle surface:
  - `startScanning()`, `stopScanning()`, `capturePhoto()`
- New test coverage and test app example for scanner flows.

### 🧩 Changed
- Added VisionKit-backed scanner hosting path alongside existing camera/photo picker path (additive, non-breaking).
- Layer 4 scanner presentation supports both sheet and full-screen semantics with helper methods.

### 📚 Documentation
- Added release draft: `Development/RELEASE_v7.7.0.md`.
- Updated release history pointer in `Development/RELEASES.md` for v7.7.0 in-preparation status.

## v7.6.0 - Managed settings migration documentation

### 📚 Documentation
- Added release-facing managed settings migration notes for adopters moving from manual `selectedCategory` state.
- Linked managed top-level flow guidance: `Framework/docs/ManagedPlatformSettingsFlowGuide.md`.
- Added compile-checked example reference: `Development/Tests/SixLayerFrameworkUnitTests/Features/Navigation/ManagedPlatformSettingsFlowGuideExampleTests.swift`.

## v5.5.0 - SwiftUI Map Support

### 🎉 Major Features

#### SwiftUI Map Support (Issue #25)
- **NEW**: Cross-platform SwiftUI Map components with modern API support
- **Modern API**: Uses `Annotation` with `MapContentBuilder` (not deprecated `MapAnnotation`)
- **Cross-Platform**: Unified API works identically on iOS and macOS
- **LocationService Integration**: Built-in integration with existing `LocationService` for current location
- **Platform Support**: iOS 17+, macOS 14+ (full support), tvOS/watchOS (fallback UI)
- **Accessibility**: All map components include automatic accessibility support

#### New APIs
- `PlatformMapComponentsLayer4` - Layer 4 map component enum
- `MapAnnotationData` - Cross-platform annotation data type
- `platformMapView_L4()` - Basic map view with MapContentBuilder
- `platformMapViewWithCurrentLocation_L4()` - LocationService-integrated map view

### 📚 Documentation
- New: [Map API Usage Guide](Framework/docs/MapAPIUsage.md)
- Updated: [Deprecated APIs Audit](Framework/docs/DeprecatedAPIsAudit.md)
- Examples: `Framework/Examples/MapUsageExample.swift`

### 🧪 Testing
- 12 comprehensive tests covering all map functionality
- TDD approach: Tests written first, then implementation
- All tests passing: 100% test success rate

### ✅ Backward Compatibility
- 100% backward compatible: No breaking changes
- Opt-in feature: Map support is new functionality

## v5.0.1 - Bug Fixes and Priority Order Improvements

### 🐛 Bug Fixes

#### CardDisplayHelper Priority Order Fix
- **Fixed**: Corrected priority order for content extraction: Hints → Reflection → CardDisplayable → nil
- **Impact**: Improves automatic content discovery by trying reflection before CardDisplayable protocol
- **Migration**: No code changes required. May see different results for items with both reflection-discoverable properties and CardDisplayable conformance

#### Hints Default Values Implementation Fix
- **Fixed**: Default values now properly work when properties are `nil`, empty strings, or have invalid types
- **Fixed**: Default values now correctly apply when hint properties don't exist
- **Impact**: Default values now work as documented in all scenarios

### 🧪 Testing Improvements
- Enhanced callback testing approach in unit tests
- Tests now directly verify callback functions work correctly
- Improved test reliability and coverage

### 📚 Documentation
- Updated priority order documentation
- Clarified default values behavior in edge cases

## v5.0.0 - Major Testing and Accessibility Release

### 🎯 **TDD (Test-Driven Development) Maturity**
- **Complete TDD Implementation**: Framework now follows strict TDD principles throughout development
- **Green Phase Completion**: All stub components replaced with comprehensive behavioral tests
- **Test Coverage Enhancement**: Added comprehensive TDD tests for all framework components
- **Behavior Verification**: Replaced stub-verification tests with proper behavior validation

### ♿ **Advanced Accessibility System Overhaul**
- **Automatic Accessibility Identifier Generation**: Complete overhaul of accessibility ID system
- **Component Integration**: Added `.automaticAccessibilityIdentifiers()` to all framework components
- **Global Accessibility Configuration**: Unified accessibility settings across all layers
- **Pattern Standardization**: Consistent accessibility identifier patterns across platforms
- **Apple HIG Compliance**: Full compliance with Apple's Human Interface Guidelines
- **Label Text Inclusion**: All components with String labels/titles now automatically include label text in accessibility identifiers
- **Label Sanitization**: Automatic sanitization of label text (lowercase, hyphenated, alphanumeric) for identifier compatibility
- **Environment-Based Label Passing**: Components pass label text via `accessibilityIdentifierLabel` environment key for automatic inclusion

### 🤖 **Advanced OCR Form-Filling Intelligence**
- **Calculation Groups**: Fields can belong to multiple calculation groups with priority-based conflict resolution
- **Intelligent OCR Processing**: System calculates missing form values from partial OCR data using mathematical relationships
- **OCR Field Hints**: Keyword arrays improve OCR recognition accuracy for field identification
- **Data Quality Assurance**: Conflicting calculations marked as "very low confidence" to prevent silent data corruption
- **Flexible Relationships**: Support for any mathematical relationships (A = B * C, D = E * F, etc.)

### 🧪 **Testing Infrastructure Revolution**
- **Suite Organization**: Added `@Suite` annotations for better Xcode test navigator integration
- **Platform Test Coverage**: Complete iOS/macOS platform test branch coverage
- **Test Documentation**: Comprehensive testing commands documentation for macOS and iOS
- **Cross-Platform Testing**: Enhanced platform mocking and capability testing

### 🔧 **Platform Capability Detection Fixes**
- **AssistiveTouch Detection**: Proper runtime detection for iOS AssistiveTouch functionality
- **VisionOS Capabilities**: Accurate touch/hover/haptic capability detection for visionOS
- **Touch Target Optimization**: Platform-native minTouchTarget values (0 for macOS/tvOS/visionOS)
- **Hover Delay Configuration**: Runtime capability detection for hover delay settings

### 🏗️ **Component Architecture Improvements**
- **Accessibility Integration**: All components now support automatic accessibility identifier generation
- **Card Expansion Components**: Enhanced with automatic accessibility identifiers
- **Form Field Components**: Complete accessibility integration for all form types
- **Dynamic Form Components**: Accessibility support for complex form structures
- **platformListRow API Refactoring**: New title-based API that automatically extracts label text for accessibility identifiers
  - **New API**: `EmptyView().platformListRow(title: "Item Title") { trailingContent }`
  - **Automatic Label Extraction**: Title parameter is automatically used for accessibility identifier generation
  - **Legacy Support**: Maintains backward-compatible overload for custom content scenarios
  - **Migration Tools**: Provided migration script and test suite for automated API updates

### 🐛 **Critical Bug Fixes**
- **Accessibility Pattern Matching**: Fixed component name verification in accessibility identifiers
- **OCR Overlay Accessibility**: Corrected accessibility identifier generation for OCR components
- **Platform Image Properties**: Clarified platform-specific PlatformImage behavior
- **Compilation Errors**: Resolved all accessibility-related compilation issues
- **Test Helper Behavior**: Fixed automatic accessibility identifier application in tests

### 📚 **Documentation and Developer Experience**
- **[Calculation Groups Guide](Framework/docs/CalculationGroupsGuide.md)**: Comprehensive guide for implementing intelligent form calculations
- **[OCR Field Hints Guide](Framework/docs/OCRFieldHintsGuide.md)**: Documentation for improving OCR recognition with keyword hints
- **[AI Agent Guide Updates](Framework/docs/AI_AGENT_GUIDE.md)**: Added OCR intelligence features for AI assistant usage
- **Testing Commands**: Complete documentation for iOS and macOS testing workflows
- **Platform Testing Guide**: Instructions for testing iOS paths on macOS
- **Code Quality Standards**: Added "commit early and often" development practice
- **Test Organization**: Improved test suite structure and naming conventions
- **API Migration Tools**: Migration scripts for platformListRow API updates with comprehensive test coverage

### 🔄 **Internal Architecture Refactoring**
- **Namespace Management**: Improved accessibility identifier namespace handling
- **Configuration Management**: Better separation of accessibility configuration logic
- **Test Infrastructure**: Enhanced BaseTestClass and test configuration management
- **Platform Detection**: More robust platform capability detection and testing

### 📊 **Quality Assurance**
- **Test Suite Expansion**: 800+ comprehensive tests with improved coverage
- **Accessibility Compliance**: Verified compliance with WCAG and Apple HIG standards
- **Cross-Platform Validation**: Enhanced testing across iOS, macOS, and visionOS
- **Performance Optimization**: Maintained native performance with accessibility enhancements

## v4.9.1
- Feature: Deterministic field ordering for IntelligentFormView via FieldOrderRules (explicit lists, per-field weights, groups, trait overrides)
- Integration: IntelligentFormView consumes FieldOrderRules with title/name-first default (no alphabetic-by-type)
- Debug: Added inspectEffectiveOrder helper; example demonstrating runtime provider
- Accessibility: Fixed disabled-mode regex handling and helper fallbacks; clarified that mixing manual accessibilityIdentifier with .named/.exactNamed is undefined priority
- Platform (L5): Positive default minTouchTarget for macOS config
- Tests: Removed tests asserting overriding manually-set accessibilityIdentifier (undefined behavior); added resolver tests
- Docs: Added warning note about mixing manual IDs with .named/.exactNamed; updated guidance

All notable changes to SixLayerFramework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.9.0] - 2025-10-30

### Added
- **IntelligentDetailView Edit Button**: Optional edit button feature with seamless form integration
- **Swift 6 Actor Isolation**: Complete compatibility with Swift 6 strict concurrency checking
- **AccessibilityManager ObservableObject**: Enhanced service class with proper state management
- **InternationalizationService Language Management**: Complete language switching and locale management
- **AccessibilityTestingSuite API**: Comprehensive accessibility testing methods and configuration

### Changed
- **IntelligentDetailView API**: Added `showEditButton` and `onEdit` parameters (backward compatible)
- **macOSLocationService**: Full actor isolation with `@MainActor` and safe delegate bridging
- **Service Architecture**: Enhanced all service classes with complete API implementations
- **Test Infrastructure**: Fixed compilation issues and improved test coverage

### Fixed
- **Issue #3**: IntelligentDetailView edit button and proper data display
- **Issue #4**: Swift 6 actor isolation conflicts in macOSLocationService
- **Compilation Errors**: Resolved all fatal compilation issues across platforms
- **Service Dependencies**: Fixed missing imports and method implementations

### Technical Details
- Actor isolation implemented using `@MainActor` and `nonisolated` delegate methods
- Edit button integration with `IntelligentFormView` for consistent UX
- Enhanced service classes with complete ObservableObject conformance
- Cross-platform compatibility verified (macOS confirmed, iOS compatible)

## [4.8.0] - 2025-01-30

### Added
- **Field-Level Display Hints**: Declarative `.hints` files to describe how data models should be presented
- **Hints/ Folder Support**: Organized storage for all hints files
- **Automatic Hint Loading**: 6Layer reads hints automatically based on model name
- **Hint Caching**: Hints loaded once and reused everywhere (DRY)
- **Display Width System**: `narrow`, `medium`, `wide`, or numeric values
- **Character Counter Support**: Optional character count overlay
- **FieldDisplayHints Structure**: Type-safe hint properties
- **DataHintsLoader**: File-based hint loading system
- **FieldHintsRegistry**: Registry pattern for hint management
- **Integration Tests**: Comprehensive test coverage for hint system

### Changed
- **Enhanced platformPresentFormData_L1**: Added `modelName` parameter for automatic hint loading
- **PresentationHints**: Added `fieldHints` property for field-level configuration
- **EnhancedPresentationHints**: Added field hints support
- **DynamicFormField**: Added `displayHints` computed property to discover hints from metadata

### Documentation
- Complete field hints usage guide
- DRY architecture documentation
- File structure guide
- Migration guide
- Test coverage summary
- Release notes

### Files Added
- `Framework/Sources/Core/Models/DataHintsLoader.swift`
- `Framework/Sources/Core/Models/FieldHintsRegistry.swift`
- `Framework/Sources/Extensions/SwiftUI/FieldHintsModifiers.swift`
- `Framework/docs/FieldHintsGuide.md`
- `Framework/docs/HintsDRYArchitecture.md`
- `Framework/docs/HintsFolderStructure.md`
- `Framework/Examples/AutoLoadHintsExample.swift`
- `Development/Tests/SixLayerFrameworkTests/Core/Models/FieldDisplayHintsTests.swift`
- `Development/Tests/SixLayerFrameworkTests/Core/Models/FieldHintsLoaderTests.swift`
- `Development/Tests/SixLayerFrameworkTests/Core/Models/FieldHintsDRYTests.swift`
- `Development/Tests/SixLayerFrameworkTests/Core/Models/FieldHintsIntegrationTests.swift`

### Technical Details
- Hints describe the DATA, not the view
- Declarative approach: define once, use everywhere
- Backward compatible: existing code continues to work
- Opt-in feature: no changes required for existing apps
- Type-safe: strongly typed FieldDisplayHints structure
- Performance optimized: cached loading for efficiency

---

## [4.5.0] - 2025-01-27

### Added
- **CardDisplayHelper Hint System**: Configurable property mapping for meaningful content display
- **Dependency Injection**: `GeometryProvider` protocol for testable `UnifiedWindowDetection`
- **Parameterized Testing**: Cross-platform component testing with `ViewInspector`
- **Intelligent Fallback System**: 4-priority property discovery for generic data types
- **Robust Reflection Heuristics**: Automatic discovery of title, subtitle, icon, and color properties

### Changed
- **Enhanced CardDisplayHelper**: Added `hints` parameter to all extraction methods
- **Refactored Platform Layer 5**: Components now return UI components instead of Views
- **Updated Layer 1 Components**: Fixed method calls to use correct Layer 4 APIs
- **Improved Test Organization**: Separated accessibility tests from functional tests

### Fixed
- **634+ Compilation Errors**: Fixed across test files
- **Generic Placeholder Issue**: Eliminated "⭐ Item" displays in `GenericItemCollectionView`
- **Nil Comparison Warnings**: Fixed for value types
- **Scope and Import Issues**: Resolved across test files
- **Component Instantiation**: Fixed method calls across the framework

### Removed
- **Tests for Non-existent Components**: Following DTRT principle
- **Inappropriate Accessibility Tests**: Removed for non-UI services

### Technical Details
- **Zero Configuration**: Works out of the box for standard data types
- **Backward Compatible**: All existing code continues to work
- **Performance Optimized**: Efficient reflection with smart caching
- **TDD Red-Phase Compliant**: Tests written first for non-existent functionality

### Known Issues
- **Test Suite Status**: 719 passing, 1,886 failing (accessibility identifier generation issues)
- **Fatal Errors**: DataPresentationIntelligenceTests.swift and EyeTrackingTests.swift
- **TDD Red-Phase**: Some accessibility identifier persistence tests failing

---

## [4.3.1] - 2025-10-09

### Fixed
- **Critical Metal Rendering Crash**: Fixed on macOS 14.0+ with Apple Silicon devices
- **Performance Layer Removal**: Eliminated `.drawingGroup()` and `.compositingGroup()` modifiers
- **Framework Simplification**: Removed entire performance layer for better compatibility

### Removed
- **PlatformOptimizationExtensions.swift**: Performance optimization modifiers
- **Performance Testing Assertions**: Related test infrastructure

### Impact
- ✅ Metal crash completely eliminated
- ✅ Framework simplified and more maintainable  
- ✅ Better compatibility across macOS versions
- ✅ No functional changes to UI behavior

---

*For earlier releases, see Development/RELEASES.md*
