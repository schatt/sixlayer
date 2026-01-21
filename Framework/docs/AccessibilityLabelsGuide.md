# Accessibility Labels Guide

## Overview

SixLayerFramework automatically generates accessibility labels for VoiceOver compliance. This guide explains how labels are generated, how to provide translations, and how to discover what keys need localization.

## How Labels Are Generated

The framework uses a **parameter-based approach** (per Issue #160) where labels are passed explicitly to `automaticCompliance()`:

```swift
// Explicit label (recommended)
platformButton(label: "Save document", action: { save() })
platformTextField(label: "Email address", prompt: "Enter email", text: $email)

// Layer 1 functions automatically use field.label
platformPresentFormData_L1(field: field, hints: hints)
// field.label is automatically passed to automaticCompliance()
```

## Key Naming Convention

### Framework Keys

Framework-provided accessibility label keys follow this pattern:

```
SixLayerFramework.accessibility.{component}.{action}
```

**Examples:**
- `SixLayerFramework.accessibility.button.save`
- `SixLayerFramework.accessibility.field.email`
- `SixLayerFramework.accessibility.toggle.notifications`

### App Keys

App-specific keys should follow this pattern:

```
{AppName}.accessibility.{component}.{action}
```

**Examples:**
- `MyApp.accessibility.button.customAction`
- `MyApp.accessibility.field.customField`

### Auto-Extracted Keys

When labels are auto-extracted from view content (Phase 2), they use:

```
SixLayerFramework.accessibility.auto.{sanitizedText}
```

**Examples:**
- `Button("Save")` → `SixLayerFramework.accessibility.auto.save`
- `Text("Hello")` → `SixLayerFramework.accessibility.auto.hello`

## Discovering Missing Keys

### 1. Runtime Logging (Debug Mode)

In **debug builds**, the framework automatically logs missing localization keys to the console:

```
⚠️ Accessibility Label: Missing localization key "SixLayerFramework.accessibility.button.save" for button "save"
```

**What to do:**
1. Run your app in debug mode
2. Check the console for missing key warnings
3. Add the missing keys to your `Localizable.strings` files

### 2. Build-Time Script

A build-time script can scan your codebase and generate a report of all accessibility label keys used:

```bash
# Generate report of missing accessibility label keys
./scripts/check_accessibility_labels_completeness.py
```

This script:
- Scans for `accessibilityLabel` parameters in platform functions
- Scans for `DynamicFormField.label` usage in Layer 1 functions
- Generates a report of missing keys per language

### 3. Documentation

This guide (`AccessibilityLabelsGuide.md`) documents all framework-provided accessibility label keys.

## Providing Translations

### Step 1: Identify Missing Keys

Use one of the discovery methods above to find missing keys.

### Step 2: Add to Localizable.strings

Add the keys to your app's `Localizable.strings` files:

**English (en.lproj/Localizable.strings):**
```strings
/* Accessibility Labels */
"SixLayerFramework.accessibility.button.save" = "Save document";
"SixLayerFramework.accessibility.field.email" = "Email address";
```

**Spanish (es.lproj/Localizable.strings):**
```strings
/* Accessibility Labels */
"SixLayerFramework.accessibility.button.save" = "Guardar documento";
"SixLayerFramework.accessibility.field.email" = "Dirección de correo electrónico";
```

### Step 3: Override Framework Defaults

You can override framework defaults by providing your own translations:

```strings
/* Override framework default */
"SixLayerFramework.accessibility.button.save" = "Save your work";
```

## Framework-Provided Keys

### Button Labels

- `SixLayerFramework.accessibility.button.save` - "Save document"
- `SixLayerFramework.accessibility.button.cancel` - "Cancel"
- `SixLayerFramework.accessibility.button.delete` - "Delete"
- `SixLayerFramework.accessibility.button.edit` - "Edit"
- `SixLayerFramework.accessibility.button.done` - "Done"

### Field Labels

- `SixLayerFramework.accessibility.field.email` - "Email address"
- `SixLayerFramework.accessibility.field.password` - "Password field"
- `SixLayerFramework.accessibility.field.phone` - "Phone number"
- `SixLayerFramework.accessibility.field.name` - "Name"
- `SixLayerFramework.accessibility.field.description` - "Description"

### Toggle Labels

- `SixLayerFramework.accessibility.toggle.notifications` - "Enable notifications"
- `SixLayerFramework.accessibility.toggle.enabled` - "Enabled"

*Note: This list will be expanded as more framework components are added.*

## Fallback Behavior

When a localization key is not found:

1. **Framework checks app bundle** first (allows app to override)
2. **Framework checks framework bundle** (framework defaults)
3. **Returns the key itself** if not found in either bundle
4. **Logs warning in debug mode** (Issue #158)

**Example:**
```swift
// If "SixLayerFramework.accessibility.button.save" is not found:
// 1. Check app bundle → not found
// 2. Check framework bundle → not found
// 3. Return "SixLayerFramework.accessibility.button.save" (the key)
// 4. Log: ⚠️ Accessibility Label: Missing localization key...
```

## Label Formatting

All labels are automatically formatted according to Apple HIG guidelines:

- **Punctuation added**: Labels without punctuation get a period (`.`) appended
- **Conciseness**: Labels describe purpose, not appearance
- **No control type**: VoiceOver announces the control type automatically

**Examples:**
- `"Save"` → `"Save."` (punctuation added)
- `"Save document"` → `"Save document."` (punctuation added)
- `"Save!"` → `"Save!"` (punctuation already present)

## Localization Service

The framework uses `InternationalizationService` directly (not via environment, per Issue #160):

```swift
let i18n = InternationalizationService()
let localized = i18n.localizedString(for: "SixLayerFramework.accessibility.button.save")
```

The service checks:
1. App bundle (allows app to override framework strings)
2. Framework bundle (framework default strings)
3. Returns key itself if not found

## Parameter-Based Approach

All labels are passed as **parameters** to `automaticCompliance()` (not environment variables):

```swift
// ✅ Correct: Parameter-based
.automaticCompliance(accessibilityLabel: field.label)

// ❌ Incorrect: Environment-based (deprecated)
.environment(\.accessibilityLabelText, field.label)
```

This approach:
- Makes labels explicit and testable
- Eliminates hidden dependencies
- Works with Issue #160 architecture

## Examples

### Platform Functions

```swift
// Explicit label (localized automatically)
platformButton(label: "SixLayerFramework.accessibility.button.save") {
    save()
}

// Plain text (formatted with punctuation)
platformButton(label: "Save document") {
    save()
}
```

### Layer 1 Functions

```swift
// Field label is automatically used
let field = DynamicFormField(
    id: "email",
    contentType: .email,
    label: "Email address"  // This becomes the accessibility label
)

platformPresentFormData_L1(field: field, hints: hints)
// Automatically uses field.label for accessibility
```

### Custom Views

```swift
Text("Hello")
    .automaticCompliance(
        identifierElementType: "Text",
        accessibilityLabel: "Greeting message"
    )
```

## Related Documentation

- `LocalizationStringsInventory.md` - Complete list of all localization keys
- `InternationalizationGuide.md` - How to use InternationalizationService
- `scripts/check_accessibility_labels_completeness.py` - Build-time key discovery script

## Related Issues

- Issue #154: Automatically Generate Accessibility Labels for VoiceOver Compliance
- Issue #158: Developer Discovery & Documentation - Localization Key Discovery
- Issue #160: Remove Environment Dependencies from AutomaticCompliance (COMPLETED)
