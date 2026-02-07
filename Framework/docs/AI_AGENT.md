# AI Agent Guide for SixLayer Framework

This document provides guidance for AI assistants working with the SixLayer Framework. **Always read the appropriate version-specific guide first** before attempting to help with this framework.

## 🎯 Quick Start

1. **Identify the current framework version** from the project's Package.swift or release tags
2. **Read the corresponding AI_AGENT_vX.X.X.md file** for that version
3. **Follow the version-specific guidelines** for architecture, patterns, and best practices

## 📚 Version-Specific Guides

### Latest Versions (Recommended)
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

## 📖 Additional Resources

- **[Framework README](../Framework/README.md)** - Complete framework documentation
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
