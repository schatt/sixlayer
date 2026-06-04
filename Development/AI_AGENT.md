# AI Agent Guide for SixLayer Framework

This document provides guidance for AI assistants working with the SixLayer Framework. **Always read the appropriate version-specific guide first** before attempting to help with this framework.

## 🎯 Quick Start

1. **Identify the current framework version** from the project's Package.swift or release tags
2. **Read the corresponding AI_AGENT_vX.X.X.md file** for that version
3. **Follow the version-specific guidelines** for architecture, patterns, and best practices

## 📚 Version-Specific Guides

### Latest Versions (Recommended)
- **v8.0.0** — Major release: app navigation chrome — navigation sheet toolbar visibility (#323), sidebar reveal chrome (#324), iOS automatic vs detailOnly (#325), `platformMenu` SwiftUI Menu on iOS (#321) (see [RELEASE_v8.0.0.md](RELEASE_v8.0.0.md))
- **[AI_AGENT_v8.0.0.md](AI_AGENT_v8.0.0.md)** - v8.0.x architecture guide (major): navigation sheet visibility policy, sidebar reveal chrome, iOS explicit detailOnly, platformMenu Menu on iOS
- **v7.9.0** — Minor release: HIG automatic compliance (#302–#303), intelligent card viewport/layout (#306–#309), capability override test hygiene (#251, #311–#313), Sendable policy (#310) (see [RELEASE_v7.9.0.md](RELEASE_v7.9.0.md))
- **[AI_AGENT_v7.9.0.md](AI_AGENT_v7.9.0.md)** - v7.9.x architecture guide (minor): HIG compliance, card viewport hints, capability override flows, Sendable policy
- **v7.8.9** — Patch release: Reduce Motion animation policy (#298) and Increase Contrast readable secondary (#299) (see [RELEASE_v7.8.9.md](RELEASE_v7.8.9.md))
- **v7.8.8** — Patch release: Dynamic Type typography — `DynamicFontResolver` (#295), token scaling (#294), scalable `platformSystem` / `platformDecorativeIconFont` (#296) (see [RELEASE_v7.8.8.md](RELEASE_v7.8.8.md))
- **v7.8.7** — Patch release: `PlatformTabStrip` public initializer (#292) (see [RELEASE_v7.8.7.md](RELEASE_v7.8.7.md))
- **v7.8.6** — Patch release: OCR overlay Vision bounding boxes (#291) (see [RELEASE_v7.8.6.md](RELEASE_v7.8.6.md))
- **v7.8.5** — Patch release: numeric form field display coercion (#289), UITest/L4 stabilization, build hygiene (see [RELEASE_v7.8.5.md](RELEASE_v7.8.5.md))
- **v7.8.4** — Patch release: configurable Vision `minimumTextHeight` for pump LCD OCR (#288) (see [RELEASE_v7.8.4.md](RELEASE_v7.8.4.md))
- **v7.8.3** — Patch release: pump label-anchored OCR (#282), joint decimal correction (#283–#287) (see [RELEASE_v7.8.3.md](RELEASE_v7.8.3.md))
- **v7.8.2** — Patch release: Layer 4 assistive adaptability (#255), semantic matrix evidence (#254), map a11y and UITest stabilization (#261) (see [RELEASE_v7.8.2.md](RELEASE_v7.8.2.md))
- **v7.8.1** — Patch release: structured OCR (#279), EXIF capture date/orientation writers (#275), Layer 4 accessibility identifiers and UITest hardening, agent `wip/` checklist (#280) (see [RELEASE_v7.8.1.md](RELEASE_v7.8.1.md))
- **[AI_AGENT_v7.8.0.md](AI_AGENT_v7.8.0.md)** - v7.8.x architecture guide (minor baseline): presentation profiles catalog (#277), item collection resolver / card row style (#272), DynamicForm draft key (#273), PlatformImage EXIF (#275), system actions (#256 / #169) (see [RELEASE_v7.8.0.md](RELEASE_v7.8.0.md))
- **v7.7.2** - Patch release: LocationService threading fix (#258), DynamicImageField image/photo state integration (#265), Layer 1 preview docs (#267), release metadata consistency (#270; see [RELEASE_v7.7.2.md](RELEASE_v7.7.2.md))
- **v7.7.1** - Patch release: explicit list accessibility identifier runtime contract restoration for UI-test consumers (Issue #257; see [RELEASE_v7.7.1.md](RELEASE_v7.7.1.md))
- **[AI_AGENT_v7.7.0.md](AI_AGENT_v7.7.0.md)** - Minor release: VisionKit live scanner path (#252), runtime capability namespaces completed (#253), release-process updates (#246, #247) (see [RELEASE_v7.7.0.md](RELEASE_v7.7.0.md))
- **[AI_AGENT_v7.6.2.md](AI_AGENT_v7.6.2.md)** - Viewport-aware card layout (#249, #250); MainActor capability test isolation; tvOS AllTests (#237); internal test harness (#247, #248) (see [RELEASE_v7.6.2.md](RELEASE_v7.6.2.md))
- **[AI_AGENT_v7.6.1.md](AI_AGENT_v7.6.1.md)** - Layer 1 automaticCompliance parity with #243 (Issue #245; see [RELEASE_v7.6.1.md](RELEASE_v7.6.1.md))
- **[AI_AGENT_v7.6.0.md](AI_AGENT_v7.6.0.md)** - Managed settings migration documentation (Issue #215; see [RELEASE_v7.6.0.md](RELEASE_v7.6.0.md))
- **v7.5.13** - Patch release (see [RELEASE_v7.5.13.md](RELEASE_v7.5.13.md))
- **v7.5.12** - Patch release (see [RELEASE_v7.5.12.md](RELEASE_v7.5.12.md))
- **v7.5.11** - Patch release (see [RELEASE_v7.5.11.md](RELEASE_v7.5.11.md))
- **v7.5.10** - Patch release (see [RELEASE_v7.5.10.md](RELEASE_v7.5.10.md))
- **v7.5.9** - Patch release (see [RELEASE_v7.5.9.md](RELEASE_v7.5.9.md))
- **v7.5.8** - Patch release (see [RELEASE_v7.5.8.md](RELEASE_v7.5.8.md))
- **v7.5.7** - Patch release (see [RELEASE_v7.5.7.md](RELEASE_v7.5.7.md))
- **v7.5.6** - Patch release (see [RELEASE_v7.5.6.md](RELEASE_v7.5.6.md))
- **v7.5.5** - Patch release (see [RELEASE_v7.5.5.md](RELEASE_v7.5.5.md))
- **v7.5.4** - Injected state, drop-in, test stability (patch — see [RELEASE_v7.5.4.md](RELEASE_v7.5.4.md))
- **v7.5.3** - Modifier debug logs gated (patch — see [RELEASE_v7.5.3.md](RELEASE_v7.5.3.md))
- **v7.5.2** - verboseMinClamping debug flag (patch — see [RELEASE_v7.5.2.md](RELEASE_v7.5.2.md))
- **v7.5.1** - platformFrame min clamping fix (patch — see [RELEASE_v7.5.1.md](RELEASE_v7.5.1.md))
- **[AI_AGENT_v7.5.0.md](AI_AGENT_v7.5.0.md)** - Minor Release
- **[AI_AGENT_v7.4.2.md](AI_AGENT_v7.4.2.md)** - @MainActor Concurrency Fix for platformFrame
- **[AI_AGENT_v7.4.1.md](AI_AGENT_v7.4.1.md)** - idealWidth and idealHeight Support for platformFrame
- **[AI_AGENT_v7.4.0.md](AI_AGENT_v7.4.0.md)** - PhotoPurpose Refactoring (Breaking Change)
- **[AI_AGENT_v7.3.0.md](AI_AGENT_v7.3.0.md)** - Convenience Aliases and Code Quality Improvements
- **[AI_AGENT_v7.2.0.md](AI_AGENT_v7.2.0.md)** - Configurable Photo Sources for OCR Scanner
- **[AI_AGENT_v7.1.0.md](AI_AGENT_v7.1.0.md)** - Color Resolution System from Hints Files
- **[AI_AGENT_v7.0.2.md](AI_AGENT_v7.0.2.md)** - Hints File Presentation Properties Support
- **[AI_AGENT_v7.0.1.md](AI_AGENT_v7.0.1.md)** - Hints File Color Configuration Support
- **[AI_AGENT_v7.0.0.md](AI_AGENT_v7.0.0.md)** - Breaking Changes - Card Color Configuration
- **[AI_AGENT_v6.8.0.md](AI_AGENT_v6.8.0.md)** - DRY Improvements - Platform Switch Consolidation
- **[AI_AGENT_v6.7.0.md](AI_AGENT_v6.7.0.md)** - Test Fixes & Count-Based Presentation
- **[AI_AGENT_v6.6.3.md](AI_AGENT_v6.6.3.md)** - ScrollView Wrapper Fixes (patch release - use v6.6.0 guide)
- **[AI_AGENT_v6.6.2.md](AI_AGENT_v6.6.2.md)** - Swift 6 Compilation Fixes (patch release - use v6.6.0 guide)
- **[AI_AGENT_v6.6.1.md](AI_AGENT_v6.6.1.md)** - SPM Bundle Name Fix (patch release - use v6.6.0 guide)
- **[AI_AGENT_v6.6.0.md](AI_AGENT_v6.6.0.md)** - Platform Capability Detection Fixes
- **[AI_AGENT_v6.5.0.md](AI_AGENT_v6.5.0.md)** - Swift 6 Compilation Fixes & Test Infrastructure
- **[AI_AGENT_v6.4.2.md](AI_AGENT_v6.4.2.md)** - Platform Bottom-Bar Toolbar Placement Helper (minor release - use v6.4.0 guide)
- **[AI_AGENT_v6.4.1.md](AI_AGENT_v6.4.1.md)** - NotificationService Bug Fix (patch release - use v6.4.0 guide)
- **[AI_AGENT_v6.4.0.md](AI_AGENT_v6.4.0.md)** - Design System Bridge
- **[AI_AGENT_v6.3.0.md](AI_AGENT_v6.3.0.md)** - Services & localization
- **[AI_AGENT_v6.2.0.md](AI_AGENT_v6.2.0.md)** - Form enhancements & advanced field types
- **v6.1.1** - Color.named() Extensions (patch release - use v6.1.0 guide)
- **[AI_AGENT_v6.1.0.md](AI_AGENT_v6.1.0.md)** - Form UX enhancements & platform extensions
- **[AI_AGENT_v6.0.3.md](AI_AGENT_v6.0.3.md)** - Critical bug fix: Additional infinite recursion fixes in accessibility identifiers
- **[AI_AGENT_v6.0.2.md](AI_AGENT_v6.0.2.md)** - Critical bug fix: Infinite recursion crash in accessibility identifiers
- **[AI_AGENT_v6.0.1.md](AI_AGENT_v6.0.1.md)** - Critical bug fix: Infinite recursion crash (Issue #91)
- **[AI_AGENT_v6.0.0.md](AI_AGENT_v6.0.0.md)** - Intelligent device-aware navigation & cross-platform utilities
- **[AI_AGENT_v5.8.0.md](AI_AGENT_v5.8.0.md)** - Cross-platform printing & automatic data binding
- **[AI_AGENT_v5.7.0.md](AI_AGENT_v5.7.0.md)** - Automatic OCR hints loading & calculation groups
- **[AI_AGENT_v5.6.0.md](AI_AGENT_v5.6.0.md)** - Enhanced Layer 1 functions & keyboard extensions
- **[AI_AGENT_v5.5.0.md](AI_AGENT_v5.5.0.md)** - Swift 6 compatibility & test infrastructure overhaul
- **[AI_AGENT_v5.4.0.md](AI_AGENT_v5.4.0.md)** - OCR hints & calculation groups in hints files
- **[AI_AGENT_v4.8.0.md](AI_AGENT_v4.8.0.md)** - Field-Level Display Hints System
- **[AI_AGENT_v4.5.0.md](AI_AGENT_v4.5.0.md)** - CardDisplayHelper Hint System
- **[AI_AGENT_v4.1.1.md](AI_AGENT_v4.1.1.md)** - Critical Bug Fix Release
- **[AI_AGENT_v4.0.1.md](AI_AGENT_v4.0.1.md)** - Automatic Accessibility Identifiers with Debugging
- **[AI_AGENT_v3.5.0.md](AI_AGENT_v3.5.0.md)** - Dynamic Form Grid Layout

### Historical Versions
- **[AI_AGENT_v3.4.4.md](AI_AGENT_v3.4.4.md)** - DynamicFormView Label Duplication Fix
- **[AI_AGENT_v3.4.3.md](AI_AGENT_v3.4.3.md)** - Critical Text Content Type Bug Fix
- **[AI_AGENT_v3.4.0.md](AI_AGENT_v3.4.0.md)** - Cross-Platform Text Content Type System
- **[AI_AGENT_v3.2.3.md](AI_AGENT_v3.2.3.md)** - macOS Image Picker Layout Fix
- **[AI_AGENT_v3.2.2.md](AI_AGENT_v3.2.2.md)** - Custom View Support for Layer 1 Functions
- **[AI_AGENT_v3.1.0.md](AI_AGENT_v3.1.0.md)** - Automatic Compliance and Configuration
- **[AI_AGENT_v3.0.0.md](AI_AGENT_v3.0.0.md)** - Major Architecture Overhaul

## 🏗️ Framework Architecture Overview

The SixLayer Framework follows a **layered architecture** where each layer builds upon the previous:

1. **Layer 1**: Basic UI Components (Buttons, TextFields, etc.)
2. **Layer 2**: Composite Components (Forms, Lists, etc.)
3. **Layer 3**: Layout Systems (Grids, Stacks, etc.)
4. **Layer 4**: Navigation Patterns (Tabs, Sheets, etc.)
5. **Layer 5**: Accessibility Features (VoiceOver, Switch Control, etc.)
6. **Layer 6**: Advanced Capabilities (OCR, ML, etc.)

## ⚠️ Critical Guidelines

### Always Follow These Rules:
- **Read the version-specific guide first** - Architecture and patterns evolve between versions
- **Use functional programming patterns** - Avoid mutable state where possible
- **Write security-conscious code** - Validate inputs, handle errors gracefully
- **Write cross-platform code** - Support iOS, macOS, and visionOS
- **Follow TDD principles** - Write tests before implementing features
- **Maintain 100% test coverage** - All new code must be tested

### v4.8.0 Field Hints System:
- **Hints describe the DATA** - Define hints once in `.hints` files, use everywhere
- **DRY Architecture** - Hints are cached, loaded once per model
- **Organized Storage** - Store hints in `Hints/` folder
- **Automatic Discovery** - 6Layer reads hints based on `modelName` parameter

### Testing Requirements:
- **Run the full xcodebuild test suite before any release** via `dbs-build --target test` - This is mandatory per project rules
- **All tests must pass** - No exceptions for releases
- **Use runtime capability detection** - Don't rely on compile-time platform checks
- **Test accessibility features** - Ensure VoiceOver, Switch Control, etc. work correctly
- **Respect capability isolation harness** (GitHub #236) - When editing tests that touch `RuntimeCapabilityDetection`, `CapabilityOverride`, or `getCardExpansionPlatformConfig` / `minTouchTarget`, use `DefaultRuntimeCapabilityIsolationTrait()` (or mirror its behavior) and *never* rely on process-global `UserDefaults.standard` state for correctness.

## 🔧 Common Patterns

### Stable Extension Surface (Public vs Internal)

- **Treat the following as the *stable* extension surface for apps:**
  - Layer 1 semantic functions documented in `Framework/docs/README_Layer1_Semantic.md`
  - Extension guides in `Framework/docs/DeveloperExtensionGuide.md` and `ExtensionQuickReference.md`
  - Public services and their documented delegates/configuration types
    - e.g. `CloudKitService` + `CloudKitServiceDelegate`, `InternationalizationService`, `NotificationService`, `SecurityService`
  - Public form APIs: `DynamicFormView`, `DynamicFormField`, `DynamicFormState` and their documented enums
  - Public SwiftUI components/modifiers under the `platform*` / `Platform*` naming

- **Treat everything else as internal unless explicitly documented:**
  - Internal engines, decision/strategy types, and low-level helpers (e.g. `HintProcessingEngine`)
  - Non-public types or members
  - Types called out as deprecated, internal, or implementation details in docs

When helping with extensions, prefer **hints, Layer 1 functions, and service delegates** over reaching into internal classes. If you find yourself depending on a type that is not mentioned in the extension docs above, treat that as a potential design smell.

### Runtime Capability Detection
```swift
// ✅ Good - Runtime detection
if RuntimeCapabilityDetection.shared.supportsTouch {
    // Touch-specific UI
}

// ❌ Bad - Compile-time detection
#if os(iOS)
    // Touch-specific UI
#endif
```

### Accessibility Integration
```swift
// ✅ Good - Automatic accessibility identifiers
Text("Hello")
    .automaticAccessibilityIdentifiers()

// ✅ Good - Manual override when needed
Text("Hello")
    .accessibilityIdentifier("custom-hello")
```

### Cross-Platform Compatibility
```swift
// ✅ Good - Cross-platform text content type
TextField("Email", text: $email)
    .textContentType(.emailAddress) // Uses SixLayerTextContentType

// ❌ Bad - Platform-specific
#if os(iOS)
TextField("Email", text: $email)
    .textContentType(.emailAddress)
#endif
```

## 🔄 Framework Upgrades and Migrations

### Migration Tooling (v6.4.0+)

Starting in v6.4.0, the framework provides migration tooling to help detect deprecated API usage and suggest replacements.

#### When Helping with Upgrades

1. **Always suggest running the migration tool** before upgrading:
   ```bash
   swift run scripts/migration_tool.swift YourApp/Sources/
   ```

2. **Review migration reports** and help developers understand:
   - What APIs are deprecated
   - What to replace them with
   - Why the change is needed

3. **Follow the recommended upgrade workflow**:
   - Run migration tool
   - Fix flagged issues
   - Run test suite
   - Update framework version

4. **Point to documentation**:
   - [Migration Guide](../Framework/docs/MigrationGuide.md) - Complete migration documentation
   - [Deprecated APIs Audit](../Framework/docs/DeprecatedAPIsAudit.md) - List of deprecated APIs

#### Common Migrations

- **Accessibility APIs**: `.automaticAccessibilityIdentifiers()` → `.automaticCompliance()`
- **Navigation APIs**: `platformNavigationContainer_L4()` → `platformNavigation_L4()`

For complete migration details, see the [Migration Guide](../Framework/docs/MigrationGuide.md).

## 📖 Additional Resources

- **[Framework README](../Framework/README.md)** - Complete framework documentation
- **[Migration Guide](../Framework/docs/MigrationGuide.md)** - **NEW v6.4.0!** Framework upgrade guide
- **[Project Status](PROJECT_STATUS.md)** - Current development status
- **[Release Notes](RELEASES.md)** - Complete release history
- **[Examples](../Framework/Examples/)** - Code examples and usage patterns

## 🤝 Contributing Guidelines

When helping with this framework:

1. **Understand the layered architecture** - Don't mix concerns between layers
2. **Follow existing patterns** - Consistency is crucial for maintainability
3. **Write comprehensive tests** - Test coverage is mandatory
4. **Document changes** - Update AI_AGENT files for significant changes
5. **Consider accessibility** - All features must work with assistive technologies

---

**Remember**: This framework prioritizes **automatic compliance**, **cross-platform compatibility**, and **accessibility**. Always consider these principles when making suggestions or implementing features.
