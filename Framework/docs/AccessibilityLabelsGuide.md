# Accessibility Labels Guide

## Overview

SixLayerFramework automatically generates accessibility labels for VoiceOver compliance. This guide explains how labels are generated, how to provide translations, and how to discover what keys need localization.

**Important:** Developers use their own app's localization keys (e.g., `MyApp.accessibility.*`), not framework keys. The framework supports any key format you choose.

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

### App Keys (Primary)

**Developers use their own app's keys** following this pattern:

```
{AppName}.accessibility.{component}.{action}
```

**Examples:**
- `MyApp.accessibility.button.save`
- `MyApp.accessibility.field.email`
- `MyApp.accessibility.toggle.notifications`
- `MyApp.accessibility.button.customAction`

**How to determine your app name:**
- Use your app's bundle identifier (e.g., `com.example.MyApp` → `MyApp`)
- Or use a consistent prefix for your app's localization keys

### Framework Keys (Internal)

Framework-provided accessibility label keys (used internally by the framework):

```
SixLayerFramework.accessibility.{component}.{action}
```

**Note:** These are framework-internal keys. Developers should use their own app keys instead.

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
⚠️ Accessibility Label: Missing localization key "MyApp.accessibility.button.save" for button "save"
```

**What to do:**
1. Run your app in debug mode
2. Check the console for missing key warnings
3. Add the missing keys to your app's `Localizable.strings` files using your app's key prefix

### 2. Build-Time Script

A build-time script can scan your codebase and generate a report of all accessibility label keys used:

```bash
# Generate report of missing accessibility label keys
./scripts/check_accessibility_labels_completeness.py

# Specify custom directories
./scripts/check_accessibility_labels_completeness.py --codebase-dir ./Framework/Sources --base-dir ./Framework/Resources

# Check specific languages only
./scripts/check_accessibility_labels_completeness.py --languages es fr de

# Custom report location
./scripts/check_accessibility_labels_completeness.py --report ./reports/missing_keys.txt
```

This script:
- Scans for `accessibilityLabel` parameters in platform functions
- Scans for `.automaticCompliance(accessibilityLabel:)` calls
- Scans for `DynamicFormField.label` usage in Layer 1 functions (which become accessibility labels)
- Scans for explicit localization keys in string literals
- Generates a report of missing keys per language
- Accounts for parameter-based labels (not environment-based, per Issue #160)

### 3. Documentation

This guide (`AccessibilityLabelsGuide.md`) documents all framework-provided accessibility label keys.

## Providing Translations

### Step 1: Identify Missing Keys

Use one of the discovery methods above to find missing keys.

### Step 2: Add to Localizable.strings

Add the keys to your app's `Localizable.strings` files using your app's key prefix:

**English (en.lproj/Localizable.strings):**
```strings
/* Accessibility Labels */
"MyApp.accessibility.button.save" = "Save document";
"MyApp.accessibility.field.email" = "Email address";
```

**Spanish (es.lproj/Localizable.strings):**
```strings
/* Accessibility Labels */
"MyApp.accessibility.button.save" = "Guardar documento";
"MyApp.accessibility.field.email" = "Dirección de correo electrónico";
```

**Important:** Use your app's key prefix (e.g., `MyApp.accessibility.*`), not `SixLayerFramework.accessibility.*`

## Example App Keys

When creating your app's accessibility labels, use your app's key prefix. Here are examples:

### Button Labels

- `MyApp.accessibility.button.save` - "Save document"
- `MyApp.accessibility.button.cancel` - "Cancel"
- `MyApp.accessibility.button.delete` - "Delete"
- `MyApp.accessibility.button.edit` - "Edit"
- `MyApp.accessibility.button.done` - "Done"

### Field Labels

- `MyApp.accessibility.field.email` - "Email address"
- `MyApp.accessibility.field.password` - "Password field"
- `MyApp.accessibility.field.phone` - "Phone number"
- `MyApp.accessibility.field.name` - "Name"
- `MyApp.accessibility.field.description` - "Description"

### Toggle Labels

- `MyApp.accessibility.toggle.notifications` - "Enable notifications"
- `MyApp.accessibility.toggle.enabled` - "Enabled"

**Remember:** Replace `MyApp` with your actual app name or bundle identifier prefix.

## Fallback Behavior

When a localization key is not found, the framework follows this fallback chain:

1. **Framework checks app bundle** first (allows app to override framework defaults)
2. **Framework checks framework bundle** (framework default strings)
3. **Returns the key itself** if not found in either bundle (formatted with punctuation)
4. **Logs warning in debug mode** (Issue #158) - helps developers discover missing keys

**Example Fallback Chain:**
```swift
// Developer code:
platformButton(label: "MyApp.accessibility.button.save") {
    save()
}

// Framework behavior:
// 1. Check app bundle (Bundle.main) for "MyApp.accessibility.button.save"
//    → Not found
// 2. Check framework bundle for "MyApp.accessibility.button.save"
//    → Not found (framework doesn't provide app-specific keys)
// 3. Return "MyApp.accessibility.button.save" (the key itself, formatted)
// 4. Log in debug mode:
//    ⚠️ Accessibility Label: Missing localization key "MyApp.accessibility.button.save" for button "MyApp.accessibility.button.save"
```

**Developer Workflow:**
1. Run app in debug mode
2. See console warning about missing key
3. Add key to app's `Localizable.strings` file:
   ```strings
   "MyApp.accessibility.button.save" = "Save document";
   ```
4. Re-run app - warning disappears, localized text is used

**Direct Service Access:**
The framework uses `InternationalizationService` directly (not via environment, per Issue #160):

```swift
// In localizeAccessibilityLabel function:
let i18n = InternationalizationService()  // Direct instantiation
let localized = i18n.localizedString(for: label)  // Direct method call
```

This approach:
- Eliminates environment dependencies
- Makes localization explicit and testable
- Simplifies debugging and logging

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
let localized = i18n.localizedString(for: "MyApp.accessibility.button.save")
```

The service checks:
1. App bundle (your app's `Localizable.strings` files)
2. Framework bundle (framework default strings - typically not used for app keys)
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
// Explicit label using app key (localized automatically)
platformButton(label: "MyApp.accessibility.button.save") {
    save()
}

// Plain text (formatted with punctuation, not localized)
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
