# AI Agent Guide for SixLayer Framework

This document provides guidance for AI assistants working with the SixLayer Framework. **Always read the appropriate version-specific guide first** before attempting to help with this framework.

## 🎯 Quick Start

1. **Identify the current framework version** from the project's Package.swift or release tags
2. **Read the corresponding AI_AGENT_vX.X.X.md file** for that version
3. **Follow the version-specific guidelines** for architecture, patterns, and best practices

## 📚 Version-Specific Guides

### Latest Versions (Recommended)
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
