# Internationalization Guide

## Overview

SixLayerFramework provides comprehensive internationalization (i18n) support with a flexible bundle fallback system that allows apps to override framework strings while maintaining framework defaults.

## Bundle Fallback System

The framework uses a **three-tier fallback system** for localized strings:

1. **App Bundle** (highest priority) - Allows apps to override framework strings
2. **Framework Bundle** (fallback) - Framework default strings
3. **Key Itself** (final fallback) - Returns the key if not found in either bundle

### How It Works

```
App Request: localizedString(for: "error.title")
    ↓
1. Check App Bundle (Bundle.main)
   ├─ Found? → Return app's translation
   └─ Not Found? ↓
2. Check Framework Bundle
   ├─ Found? → Return framework's translation
   └─ Not Found? ↓
3. Return key itself: "error.title"
```

## Usage

### Basic Usage

```swift
import SixLayerFramework

// Create service (defaults to Bundle.main for app bundle)
let i18n = InternationalizationService()

// Get localized string (checks app bundle, then framework bundle)
let errorMessage = i18n.localizedString(for: "error.title")
// Returns: App's translation → Framework's translation → "error.title"
```

### With String Formatting

```swift
let i18n = InternationalizationService()

// With format arguments
let welcomeMessage = i18n.localizedString(
    for: "welcome.user",
    arguments: ["John"]
)
// If "welcome.user" = "Welcome, %@!" in strings file
// Returns: "Welcome, John!"
```

### Custom App Bundle

```swift
// Use a different bundle for app strings
let customBundle = Bundle(for: MyCustomClass.self)
let i18n = InternationalizationService(appBundle: customBundle)
```

### App-Only Strings

```swift
// Only check app bundle (no framework fallback)
let appString = i18n.appLocalizedString(for: "app.only.key")
```

### Framework-Only Strings

```swift
// Only check framework bundle (no app fallback)
let frameworkString = i18n.frameworkLocalizedString(for: "framework.only.key")
```

## Setting Up Localization Files

### Framework Strings

Framework strings are stored in a single `.xcstrings` file (String Catalog format):

```
Framework/
└── Resources/
    └── Localizable.xcstrings
```

**Note**: The framework uses the modern `.xcstrings` format which consolidates all languages into a single file. This provides:
- Better tooling support in Xcode
- Built-in pluralization and device variations
- Improved version control (single file instead of multiple)
- Metadata support (translation states, comments)

The legacy `.lproj/.strings` format is still supported by `NSLocalizedString`, but `.xcstrings` is the preferred format.

**Framework Localizable.xcstrings:**
The framework uses a JSON-based `.xcstrings` file that contains all languages. Each key includes:
- `comment`: Context for translators
- `localizations`: Translations for each language with `state` and `value`

`InternationalizationService` resolves framework defaults from that catalog. SPM ships it with `.copy` (the JSON is not compiled to `.strings`); the service reads `Localizable.xcstrings` directly when compiled `.strings` are absent. Xcode framework builds still use compiled catalogs first. **Apps do not need to duplicate framework keys.** Override only the keys you want to change; missing keys fall back to the framework catalog.

Example structure:
```json
{
  "version": "1.0",
  "sourceLanguage": "en",
  "strings": {
    "SixLayerFramework.error.title": {
      "comment": "Error dialog title",
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Error" } },
        "es": { "stringUnit": { "state": "translated", "value": "Error" } }
      }
    }
  }
}
```

### App Strings

App strings can be placed in the app bundle using either format:

**Option 1: .xcstrings (Recommended)**
```
YourApp/
└── Resources/
    └── Localizable.xcstrings
```

**Option 2: .lproj/.strings (Legacy)**
```
YourApp/
└── Resources/
    ├── en.lproj/
    │   └── Localizable.strings
    ├── es.lproj/
    │   └── Localizable.strings
    └── fr.lproj/
        └── Localizable.strings
```

Both formats work with `NSLocalizedString`, but `.xcstrings` is recommended for new projects.

**App Localizable.strings:**
```strings
/* App-specific strings */
"app.title" = "My App";
"app.welcome" = "Welcome to My App!";

/* Override framework strings */
"error.title" = "Oops!";  /* Overrides framework's "Error" */
"button.save" = "Save Changes";  /* Overrides framework's "Save" */
```

## Key Naming Conventions

### Recommended Practices

1. **Framework Keys**: Use a prefix to avoid conflicts
   ```strings
   "SixLayerFramework.error.title" = "Error";
   "SixLayerFramework.button.save" = "Save";
   ```

2. **App Keys**: Use your app's domain prefix
   ```strings
   "MyApp.welcome.title" = "Welcome";
   "MyApp.settings.title" = "Settings";
   ```

3. **Shared Keys**: Use simple names if you want apps to override
   ```strings
   /* Framework */
   "error.title" = "Error";
   
   /* App can override */
   "error.title" = "Oops!";
   ```

## Example: Complete Workflow

### 1. Framework Provides Defaults

**Framework/Resources/Localizable.xcstrings:**
Contains all framework strings in a single file with all languages.

### 2. App Overrides Some Strings

**App/Resources/Localizable.xcstrings** (or **App/Resources/en.lproj/Localizable.strings**):
```json
{
  "version": "1.0",
  "sourceLanguage": "en",
  "strings": {
    "SixLayerFramework.form.button.submit": {
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Save Form" } }
      }
    },
    "app.name": {
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "My App" } }
      }
    }
  }
}
```

### 3. Usage in Code

```swift
let i18n = InternationalizationService()

// Uses app's override: "Save Form"
let submitText = i18n.localizedString(for: "form.button.submit")

// Uses framework default: "This field is required"
let requiredError = i18n.localizedString(for: "form.error.required")

// Uses app string: "My App"
let appName = i18n.localizedString(for: "app.name")

// Returns key (not found): "unknown.key"
let unknown = i18n.localizedString(for: "unknown.key")
```

## SwiftUI Integration

Use the Layer 1 functions for SwiftUI views:

```swift
import SixLayerFramework

struct MyView: View {
    var body: some View {
        // Automatically uses app bundle → framework bundle fallback
        platformPresentLocalizedString_L1(
            key: "welcome.title",
            arguments: []
        )
    }
}
```

## Advanced: Custom Bundle Detection

The framework automatically detects its bundle using:

1. Swift Package Manager resource bundles
2. Framework bundle (for embedded frameworks)
3. Main bundle (fallback)

You typically don't need to configure this, but the framework handles:
- SPM resource bundles: `SixLayerFramework_SixLayerFramework.bundle`
- Embedded frameworks: The framework's own bundle
- App bundles: `Bundle.main` (default)

## Best Practices

1. **Use Namespaced Keys**: Prefix framework keys to avoid conflicts
2. **Document Overridable Keys**: Document which framework keys apps can override
3. **Provide Complete Translations**: Framework should provide all supported languages
4. **Test Fallback Behavior**: Verify app overrides work correctly
5. **Use Format Arguments**: Use `%@`, `%d`, etc. for dynamic content

## Troubleshooting

### Strings Not Found

If strings aren't being found:

1. **Check Bundle Resources**: Ensure `.strings` files are included in bundle resources
2. **Verify Language Codes**: Use correct language codes (e.g., `en.lproj`, not `en-US.lproj`)
3. **Check File Format**: Ensure `.strings` files are valid property list format
4. **Verify Bundle**: Use `appLocalizedString` or `frameworkLocalizedString` to test specific bundles

### App Override Not Working

If app strings aren't overriding framework strings:

1. **Check Priority**: App bundle is checked first, so app strings should override
2. **Verify Key Match**: Keys must match exactly (case-sensitive)
3. **Check Bundle**: Ensure app bundle is `Bundle.main` or correctly specified
4. **Test Directly**: Use `appLocalizedString` to verify app bundle has the string

## Testing

Comprehensive test coverage is available in `InternationalizationServiceTests.swift`:

- **Framework String Loading**: Tests verify framework bundle can load strings and all defined keys return proper values
- **App Override Functionality**: Tests verify app strings override framework strings and fallback works correctly
- **Fallback Chain**: Tests verify app → framework → key fallback order
- **Multi-Language Support**: Tests cover English, Spanish, French, German, Japanese, Korean, Simplified Chinese, and locale fallback
- **Edge Cases**: Tests handle empty strings, missing language files, invalid keys, special characters, and format placeholders

All 40 tests pass and verify the localization implementation works correctly.

## Related Documentation

- [InternationalizationService API Reference](../Sources/Core/Services/InternationalizationService.swift)
- [Layer 1 Internationalization Functions](../Sources/Layers/Layer1-Semantic/PlatformInternationalizationL1.swift)
- [Internationalization Types](../Sources/Core/Models/InternationalizationTypes.swift)
