# AI Agent Guide for SixLayer Framework v4.8.0

This document provides guidance for AI assistants working with the SixLayer Framework v4.8.0. **Always read this version-specific guide first** before attempting to help with this framework.

## 🎯 Quick Start

1. **Identify the current framework version** from the project's Package.swift or release tags
2. **Read this AI_AGENT_v4.8.0.md file** for version-specific guidance
3. **Follow the guidelines** for architecture, patterns, and best practices

## 🆕 What's New in v4.8.0

### Field-Level Display Hints System - Major Enhancement

The most significant improvement in v4.8.0 is the introduction of **field-level display hints** that allow apps to declaratively describe how their data should be presented.

#### Problem Solved

Previously, field display properties (widths, lengths, etc.) had to be configured manually in code for each view. This created duplication and made it difficult to maintain consistent presentation across the app.

#### Solution: Declarative .hints Files

Apps now create `.hints` files that describe their data models:

```
YourApp/
├── Models/
│   └── User.swift
├── Hints/
│   └── User.hints         ← 6Layer reads this automatically
└── Views/
    ├── CreateUserView.swift
    └── EditUserView.swift
```

## 🏗️ Framework Architecture Overview

The SixLayer Framework follows a **layered architecture** where each layer builds upon the previous:

1. **Layer 1**: Semantic Intent - Express WHAT you want, not HOW
2. **Layer 2**: Layout Decision - Intelligent layout analysis
3. **Layer 3**: Strategy Selection - Platform-specific strategies
4. **Layer 4**: Component Implementation - Platform-agnostic components
5. **Layer 5**: Platform Optimization - Performance and accessibility
6. **Layer 6**: Platform System - Native platform features

## 🎯 Field Hints Usage Patterns

### Creating .hints Files

Apps create hint files that describe their data:

**Hints/User.hints**:
```json
{
  "username": {
    "displayWidth": "medium",
    "expectedLength": 20,
    "maxLength": 50,
    "minLength": 3
  },
  "email": {
    "displayWidth": "wide",
    "maxLength": 255
  },
  "bio": {
    "displayWidth": "wide",
    "showCharacterCounter": true,
    "maxLength": 1000
  }
}
```

### Using Hints in Views

Hints are automatically loaded when presenting data:

```swift
platformPresentFormData_L1(
    fields: createUserFields(),
    hints: EnhancedPresentationHints(
        dataType: .form,
        context: .create
    ),
    modelName: "User"  // 6Layer reads User.hints automatically!
)
```

### DRY Principle

- **Define once**: Create `User.hints` file once
- **Use everywhere**: All User views automatically use same hints
- **Cached**: Hints loaded once per model, reused for performance
- **Consistent**: Same presentation rules across all views

## 🔑 Key Principles

### Hints Describe the DATA

```swift
// ❌ WRONG: Hints passed in manually
let hints = PresentationHints(fieldHints: ["username": FieldDisplayHints(...)])

// ✅ CORRECT: Hints discovered from data
// Hints stored in Hints/User.hints, loaded automatically
platformPresentFormData_L1(..., modelName: "User")
```

### Storage Location

- **Primary**: `Hints/User.hints` in app bundle
- **Fallback**: `~/Documents/Hints/User.hints` at runtime
- **Backward Compat**: `User.hints` at root level

### Properties Available

- `displayWidth`: `"narrow"`, `"medium"`, `"wide"`, or numeric
- `expectedLength`: Expected field length for display sizing
- `maxLength`: Maximum allowed length (validation)
- `minLength`: Minimum allowed length (validation)
- `showCharacterCounter`: Boolean for character count overlay

## 📚 Common Patterns

### Multiple Data Models

```swift
// Each model has its own .hints file
platformPresentFormData_L1(..., modelName: "User")     // Reads User.hints
platformPresentFormData_L1(..., modelName: "Product") // Reads Product.hints
platformPresentFormData_L1(..., modelName: "Order")   // Reads Order.hints
```

### Field Hints Discovery

Hints can be discovered from field metadata OR from .hints files:

```swift
// Option 1: From .hints file (recommended)
DynamicFormField(
    id: "username",
    contentType: .text,
    label: "Username"
)
// 6Layer reads from User.hints automatically

// Option 2: From field metadata
DynamicFormField(
    id: "username",
    contentType: .text,
    label: "Username",
    metadata: [
        "displayWidth": "medium",
        "expectedLength": "20"
    ]
)
```

### Display Width Guidelines

- **narrow** (~150pt): Postal codes, codes, short fields
- **medium** (~200pt): Usernames, standard fields
- **wide** (~400pt): Names, emails, addresses, descriptions
- **numeric**: Exact width in points (e.g., `"250"`)

## ⚠️ Critical Guidelines

### Always Follow These Rules:

- **Hints describe the DATA** - Not manually passed in
- **Define once, use everywhere** - Store in `.hints` files
- **Use `modelName` parameter** - Triggers automatic hint loading
- **Organize in Hints/ folder** - Keeps hints together
- **Don't pass hints manually** - Let 6Layer discover them

### Testing Requirements:

- **Run the full xcodebuild test suite before any release** via `dbs-build --target test` - Mandatory
- **All tests must pass** - No exceptions
- **Test hint loading** - Verify .hints files are read correctly
- **Test caching behavior** - Hints should be cached

## 🧪 Testing Field Hints

Tests are available in:
- `FieldDisplayHintsTests.swift` - Basic functionality
- `FieldHintsLoaderTests.swift` - File loading
- `FieldHintsDRYTests.swift` - Caching behavior
- `FieldHintsIntegrationTests.swift` - End-to-end workflow

```bash
swift test --filter FieldDisplayHintsTests
swift test --filter FieldHintsLoaderTests
swift test --filter FieldHintsDRYTests
swift test --filter FieldHintsIntegrationTests
```

## 📖 Additional Resources

- **[Field Hints Complete Guide](../Framework/docs/FieldHintsCompleteGuide.md)** - Comprehensive documentation
- **[Field Hints Guide](../Framework/docs/FieldHintsGuide.md)** - Quick start guide
- **[Hints DRY Architecture](../Framework/docs/HintsDRYArchitecture.md)** - DRY principles
- **[Release Notes v4.8.0](RELEASE_v4.8.0.md)** - Complete release details

## 🤝 Contributing Guidelines

When helping with this framework:

1. **Understand field hints are declarative** - Not imperative
2. **Follow DRY principle** - Define hints once, use everywhere
3. **Test hint loading** - Verify .hints files work correctly
4. **Use modelName parameter** - Enables automatic discovery
5. **Organize in Hints/ folder** - Follow file structure

---

**Remember**: In v4.8.0, field hints are **discovered from data**, not passed in manually. This is a major architectural improvement that makes UI generation more declarative and maintainable.


