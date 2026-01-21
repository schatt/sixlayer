# Automatic Accessibility Identifiers

SixLayer framework automatically generates accessibility identifiers for views, making UI testing easier without requiring manual identifier assignment.

## Overview

The automatic accessibility identifier system provides:

- **Deterministic ID generation** based on object identity and context
- **Global configuration** with namespace and generation mode options
- **Manual override support** - explicit identifiers always take precedence
- **View-level opt-out** for specific views that shouldn't have automatic IDs
- **Collision detection** in DEBUG builds to identify potential conflicts
- **Debug logging** for inspecting generated IDs during development
- **View hierarchy tracking** for complete breadcrumb trails
- **Screen context awareness** for organized UI testing
- **UI test code generation** from breadcrumb data
- **Integration with HIG compliance** - automatic IDs are included in `.appleHIGCompliant()`

## Quick Start

### ✅ Automatic Identifiers Now Work by Default!

As of SixLayerFramework 4.3.0, automatic accessibility identifiers are **enabled by default** and work automatically. **No setup required!**

### Framework Components vs Custom Views

**Framework Components (L1-L6) automatically get accessibility identifiers:**
```swift
// ✅ These automatically get accessibility identifiers (no setup needed!)
platformPresentContent_L1(content: Button("Add Fuel") { })
platformFormContainer_L4(content: VStack { })
platformNavigationLink_L4_BasicDestination(destination: Text("Next"))
```

**Custom Views need explicit enablement:**
```swift
// ❌ Plain SwiftUI views don't get automatic IDs
Button("Custom Button") { }
    .named("CustomButton")  // ← Only tracks hierarchy

// ✅ Enable automatic IDs for custom views
Button("Custom Button") { }
    .named("CustomButton")
    .enableGlobalAutomaticAccessibilityIdentifiers()  // ← Gets automatic ID
```

### Global Configuration (Optional)

```swift
// Configure global settings (optional - defaults are already good)
AccessibilityIdentifierConfig.shared.enableAutoIDs = true  // ✅ Already true by default
AccessibilityIdentifierConfig.shared.namespace = "myapp"   // ✅ Default is "app"
AccessibilityIdentifierConfig.shared.mode = .automatic     // ✅ Already automatic by default
```

**That's it!** Framework components automatically get accessibility identifiers without any additional code.

### UserDefaults Persistence

Configuration settings can be persisted to UserDefaults so they survive app restarts:

```swift
// Configure settings
let config = AccessibilityIdentifierConfig.shared
config.enableAutoIDs = true
config.namespace = "myapp"
config.globalPrefix = "feature"
config.enableUITestIntegration = true

// Save to UserDefaults (persists across app launches)
config.saveToUserDefaults()
```

**Load on app startup:**

```swift
// In your app initialization (e.g., App.swift or SceneDelegate)
@main
struct MyApp: App {
    init() {
        // Load saved configuration from UserDefaults
        AccessibilityIdentifierConfig.shared.loadFromUserDefaults()
        
        // Optionally override with custom settings
        AccessibilityIdentifierConfig.shared.enableDebugLogging = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Benefits:**
- ✅ User preferences persist across app launches
- ✅ Developers can save/load configuration programmatically
- ✅ Follows the same pattern as `PerformanceConfiguration`
- ✅ Only loads values if they exist in UserDefaults (respects defaults)

**Note:** The `loadFromUserDefaults()` method only loads values if they exist in UserDefaults. If a key doesn't exist, the default value is preserved. This ensures that new app installations start with sensible defaults.

### ⚠️ Important: GlobalAutomaticAccessibilityIdentifierModifier is Unnecessary

**For Framework Components:** The `GlobalAutomaticAccessibilityIdentifierModifier` is **not needed** because framework components automatically check the global configuration and apply accessibility identifiers when appropriate.

**For Custom Views:** You still need `.enableGlobalAutomaticAccessibilityIdentifiers()` to enable automatic IDs for plain SwiftUI views.

### Use with Layer 1 Functions

```swift
// Layer 1 functions automatically include accessibility identifiers
let view = platformPresentItemCollection_L1(
    items: users,
    hints: PresentationHints(...)
)
// Each user item gets an ID like: "myapp.list.item.user-1"
```

### Manual Override

**Manual accessibility identifiers always override automatic ones:**

```swift
// ✅ Correct usage - manual ID overrides automatic
Button("Save") { }
    .named("SaveButton")
    .accessibilityIdentifier("custom-save-button")  // ← Manual ID wins

// ❌ Incorrect usage - automatic ID overwrites manual
Button("Save") { }
    .accessibilityIdentifier("custom-save-button")  // ← Gets overwritten
    .named("SaveButton")
```

**Important:** Apply `.accessibilityIdentifier()` AFTER framework modifiers to ensure manual IDs take precedence.

### Warning: Mixing Manual IDs with .named/.exactNamed

- If you apply both a manual `.accessibilityIdentifier(...)` and SixLayer’s `.named(...)` or `.exactNamed(...)` to the same view, the final identifier may be framework- and order-dependent.
- There is no guaranteed priority between two manually-specified identifiers (they are both explicit).
- Recommendation: avoid mixing. Pick one approach per view. If you must combine them, document the intended order locally and verify via tests.

### Enabling Automatic IDs for Custom Views

**For complex custom views, enable automatic IDs:**

```swift
// Custom view with automatic IDs
struct CustomFuelView: View {
    var body: some View {
        VStack {
            Button("Add Fuel") { }
                .named("AddFuelButton")
            
            Button("Remove Fuel") { }
                .named("RemoveFuelButton")
        }
        .named("FuelManagement")
        .enableGlobalAutomaticAccessibilityIdentifiers()  // ← Enables automatic IDs
    }
}
```

### Disabling Accessibility Identifiers

If your app uses SixLayer framework methods but doesn't want accessibility identifiers, you can disable them either globally or on individual calls.

#### Global Disable

Disable accessibility identifiers for your entire app:

```swift
// In your app initialization (e.g., App.swift or SceneDelegate)
@main
struct MyApp: App {
    init() {
        // Disable automatic accessibility identifiers globally
        AccessibilityIdentifierConfig.shared.enableAutoIDs = false
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Note:** This disables automatic identifier generation for all framework components and custom views throughout your app.

#### Per-View Disable

Disable accessibility identifiers for specific views:

```swift
// Disable for a specific view
Button("Decorative") { }
    .disableAutomaticAccessibilityIdentifiers()

// Disable for a container and all its children
VStack {
    Text("Content")
    Button("Action") { }
}
.disableAutomaticAccessibilityIdentifiers()
```

#### Per-Call Disable (Framework Methods)

Disable accessibility identifiers for individual framework method calls:

```swift
// Disable for a specific framework method call
platformNavigationButton_L4(
    title: "Settings",
    systemImage: "gear",
    accessibilityLabel: "Settings",
    accessibilityHint: "Open settings",
    action: { }
)
.disableAutomaticAccessibilityIdentifiers()

// Disable for Layer 1 functions
platformPresentContent_L1(content: myContent)
    .disableAutomaticAccessibilityIdentifiers()
```

#### When to Disable

Consider disabling accessibility identifiers when:
- ✅ Your app doesn't use UI testing
- ✅ You have performance concerns (though overhead is minimal)
- ✅ You prefer manual identifier management
- ✅ You're building a prototype and don't need identifiers yet
- ✅ Specific views are purely decorative and don't need testing

#### Re-enabling After Global Disable

If you've disabled globally but want identifiers for specific views:

```swift
// Global disable
AccessibilityIdentifierConfig.shared.enableAutoIDs = false

// Re-enable for specific views by temporarily enabling the global setting
// Note: This affects all views in the app, so use with caution
let wasEnabled = AccessibilityIdentifierConfig.shared.enableAutoIDs
AccessibilityIdentifierConfig.shared.enableAutoIDs = true

Button("Important") { }
    .automaticCompliance()

// Restore previous setting if needed
AccessibilityIdentifierConfig.shared.enableAutoIDs = wasEnabled
```

**Important:** Framework components (L1-L6 methods) respect the global `enableAutoIDs` setting. If you disable globally, framework components won't generate identifiers. To enable for specific views, you'll need to either:
- Temporarily enable the global setting (affects all views)
- Use manual `.accessibilityIdentifier()` calls instead

## Configuration Options

### Global Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enableAutoIDs` | `Bool` | `true` | Whether to generate automatic identifiers |
| `namespace` | `String` | `"app"` | Global namespace for all generated IDs |
| `mode` | `AccessibilityIdentifierMode` | `.automatic` | ID generation strategy |
| `enableCollisionDetection` | `Bool` | `true` | DEBUG collision detection |
| `enableDebugLogging` | `Bool` | `false` | DEBUG logging of generated IDs |
| `enableViewHierarchyTracking` | `Bool` | `false` | Track view hierarchy for breadcrumbs |
| `enableUITestIntegration` | `Bool` | `false` | Enable UI test code generation |
| `globalAutomaticAccessibilityIdentifiers` | `Bool` | `true` | ✅ **NEW**: Environment variable now defaults to true |

### Generation Modes

#### Automatic Mode (Default)
```
namespace.context.role.objectID
Example: "myapp.list.item.user-1"
```

#### Semantic Mode
```
namespace.role.objectID
Example: "myapp.item.user-1"
```

#### Minimal Mode
```
objectID
Example: "user-1"
```

## ID Generation Rules

### For Identifiable Objects
- Uses `object.id` as the object identifier
- Stable across reordering and data changes
- Example: `User(id: "user-1", ...)` → `"myapp.list.item.user-1"`

### For Non-Identifiable Objects
- Extracts meaningful identifier from content
- Falls back to type name and hash for complex objects
- Example: `"Hello World"` → `"myapp.display.text.hello-world"`

### ID Sanitization
- Spaces → hyphens
- Special characters → hyphens
- Converted to lowercase
- Example: `"User Profile"` → `"user-profile"`

## Integration Points

### Apple HIG Compliance
```swift
// Automatic identifiers are included in HIG compliance
Text("Hello")
    .appleHIGCompliant()
// Gets automatic identifier: "app.ui.element.view"
```

### Layer 1 Functions
All Layer 1 functions automatically include accessibility identifiers:
- `platformPresentItemCollection_L1`
- `platformPresentFormData_L1`
- `platformPresentMediaData_L1`
- And others...

## Best Practices

### When to Use Automatic IDs
- ✅ Repetitive UI elements (lists, forms, cards)
- ✅ Generated content from data models
- ✅ Rapid prototyping and development
- ✅ UI testing scenarios

### When to Use Manual IDs
- ✅ Critical test targets that need specific names
- ✅ Performance-sensitive views (to avoid generation overhead)
- ✅ Views with complex accessibility requirements
- ✅ Public APIs where ID names are part of the contract

### When to Opt Out
- ✅ Purely decorative elements
- ✅ Views that don't need testing
- ✅ Performance-critical rendering paths

## Enhanced Breadcrumb System (v4.1.0)

### View Hierarchy Tracking

Track the complete hierarchy of views for comprehensive breadcrumb trails:

```swift
// Enable view hierarchy tracking
AccessibilityIdentifierConfig.shared.enableViewHierarchyTracking = true

// Track views in your hierarchy
NavigationView {
    VStack {
        Button("Save") { }
            .named("SaveButton")
    }
    .named("MainContent")
}
.named("NavigationView")
```

### Screen Context Awareness

Set screen context for organized UI testing:

```swift
// Enable UI test integration
AccessibilityIdentifierConfig.shared.enableUITestIntegration = true

// Set screen context
VStack {
    // Your content
}
.screenContext("UserProfile")
.navigationState("ProfileEditMode")
```

### Enhanced Debug Output

With enhanced features enabled, debug output includes:

```
🔍 Accessibility ID Generated: 'app.profile.save-button' for ViewModifier
   📍 View Hierarchy: NavigationView → MainContent → SaveButton
   📱 Screen: UserProfile
   🧭 Navigation: ProfileEditMode
```

### UI Test Code Generation

Generate XCTest code automatically from breadcrumb data:

```swift
// Generate UI test code
let testCode = AccessibilityIdentifierConfig.shared.generateUITestCode()
print(testCode)
```

**Save to File:**
```swift
// Generate and save to autoGeneratedTests folder
do {
    let filePath = try AccessibilityIdentifierConfig.shared.generateUITestCodeToFile()
    print("✅ UI test code saved to: \(filePath)")
} catch {
    print("❌ Failed to save: \(error)")
}
```

**Copy to Clipboard:**
```swift
// Copy to clipboard for easy pasting
AccessibilityIdentifierConfig.shared.generateUITestCodeToClipboard()
```

**File Location:**
- Files are saved to: `~/Documents/autoGeneratedTests/`
- Filename format: `GeneratedUITests_{PID}_{timestamp}.swift`
- Example: `GeneratedUITests_12345_1704123456.swift`

Generated output:
```swift
// Generated UI Test Code
// Generated at: 2025-01-15 10:30:45

// Screen: UserProfile
func test_app_profile_save_button() {
    let element = app.otherElements["app.profile.save-button"]
    XCTAssertTrue(element.exists, "Element 'app.profile.save-button' should exist") // Hierarchy: NavigationView → MainContent → SaveButton
}
```

### Breadcrumb Trail Generation

Generate comprehensive breadcrumb trails:

```swift
// Generate breadcrumb trail
let breadcrumb = AccessibilityIdentifierConfig.shared.generateBreadcrumbTrail()
print(breadcrumb)
```

Generated output:
```
🍞 Accessibility ID Breadcrumb Trail:

📱 Screen: UserProfile
  10:30:45.123 - app.profile.save-button
    📍 Path: NavigationView → MainContent → SaveButton
    🧭 Navigation: ProfileEditMode
```

### UI Test Helpers

Generate common UI test actions:

```swift
// Generate tap action
let tapCode = AccessibilityIdentifierConfig.shared.generateTapAction("app.profile.save-button")

// Generate text input action
let inputCode = AccessibilityIdentifierConfig.shared.generateTextInputAction("app.profile.email-field", text: "test@example.com")
```

## Debugging and Inspection

### Debug Logging

Enable debug logging to inspect generated accessibility identifiers during development:

```swift
// Enable debug logging
AccessibilityIdentifierConfig.shared.enableDebugLogging = true

// Generate some IDs (will be logged automatically)
let view = platformPresentItemCollection_L1(items: users, hints: hints)

// Inspect the generated IDs
let log = AccessibilityIdentifierConfig.shared.getDebugLog()
print(log)

// Or print directly to console
AccessibilityIdentifierConfig.shared.printDebugLog()

// Clear the log when done
AccessibilityIdentifierConfig.shared.clearDebugLog()
```

### Console Output

When debug logging is enabled, generated IDs are logged to the console with timestamps:

```
🔍 Accessibility ID Generated: 'app.list.item.user-1' for Identifiable(user-1)
🔍 Accessibility ID Generated: 'app.ui.button.save' for Any(String)
🔍 Accessibility ID Generated: 'app.form.field.email' for ViewModifier
```

### Debug Methods

| Method | Description |
|--------|-------------|
| `getDebugLog()` | Returns formatted string with all generated IDs and timestamps |
| `printDebugLog()` | Prints debug log directly to console |
| `clearDebugLog()` | Clears the debug log history |
| `logGeneratedID(_:context:)` | Manually log an ID with context |

### Debug Log Format

The debug log includes:
- **Timestamp** (HH:mm:ss.SSS format)
- **Generated ID** (the actual accessibility identifier)
- **Context** (source of the ID generation)

Example output:
```
Generated Accessibility Identifiers:
10:30:45.123 - app.list.item.user-1 (Identifiable(user-1))
10:30:45.124 - app.ui.button.save (Any(String))
10:30:45.125 - app.form.field.email (ViewModifier)
```

## Collision Detection

In DEBUG builds, the system tracks generated IDs to detect potential conflicts:

```swift
let generator = AccessibilityIdentifierGenerator()
let id = generator.generateID(for: user, role: "item", context: "list")
let hasCollision = generator.checkForCollision(id)
```

## Performance Considerations

- **Manual IDs**: Zero overhead - just stores the provided string
- **Automatic IDs**: Small overhead for ID generation and collision tracking
- **Disabled**: Zero overhead - skips all ID generation

## Migration Guide

### From Manual to Automatic
1. Enable automatic IDs globally
2. Remove manual `.platformAccessibilityIdentifier()` calls for repetitive elements
3. Keep manual IDs for critical test targets
4. Test thoroughly to ensure IDs are stable

### From Automatic to Manual
1. Disable automatic IDs globally
2. Add manual `.platformAccessibilityIdentifier()` calls as needed
3. No breaking changes - manual IDs always override automatic ones

## Examples

See the following example files for comprehensive usage:

### `AutomaticAccessibilityIdentifiersExample.swift`
Basic usage examples including:
- Basic automatic identifier usage
- Layer 1 function integration
- Manual override patterns
- Opt-out scenarios
- Global configuration management

### `AccessibilityIdentifierDebuggingExample.swift`
Debugging and inspection examples including:
- Debug logging controls
- Real-time ID inspection
- Console output examples
- Advanced debugging scenarios
- Collision detection testing

### `EnhancedBreadcrumbExample.swift` (v4.1.0)
Enhanced breadcrumb system examples including:
- View hierarchy tracking
- Screen context management
- UI test code generation
- Breadcrumb trail generation
- UI test helper methods

## Version History

- **v4.3.0**: **BREAKING CHANGE** - Framework components now automatically respect global configuration. `GlobalAutomaticAccessibilityIdentifierModifier` is no longer needed for framework components. Added deterministic ID generation for persistence across app launches.
- **v4.1.0**: Enhanced breadcrumb system with view hierarchy tracking, screen context awareness, and UI test code generation
- **v4.0.1**: Added debugging capabilities for inspecting generated IDs
- **v4.0.0**: Initial implementation with automatic identifiers enabled by default

## Architectural Changes (v4.3.0)

### Framework Components Now Respect Global Config

**Before v4.3.0:**
```swift
// Framework components always generated IDs regardless of global config
platformPresentContent_L1(content: Button("Test") { })
// Always generated ID, even if global config was disabled
```

**After v4.3.0:**
```swift
// Framework components check global config automatically
AccessibilityIdentifierConfig.shared.enableAutoIDs = false
platformPresentContent_L1(content: Button("Test") { })
// No ID generated - respects global config

AccessibilityIdentifierConfig.shared.enableAutoIDs = true
platformPresentContent_L1(content: Button("Test") { })
// ID generated - respects global config
```

### GlobalAutomaticAccessibilityIdentifierModifier is Unnecessary

**For Framework Components:**
- ✅ **No longer needed** - framework components automatically check global config
- ✅ **Cleaner API** - no redundant modifier calls required
- ✅ **Better separation** - framework vs custom view behavior is clear

**For Custom Views:**
- ⚠️ **Still required** - plain SwiftUI views need explicit enabling
- ✅ **Explicit control** - developers choose when to enable automatic IDs

### Migration Guide

**If you were using `.enableGlobalAutomaticAccessibilityIdentifiers()` with framework components:**

```swift
// ❌ Before v4.3.0 (redundant)
platformPresentContent_L1(content: Button("Test") { })
    .enableGlobalAutomaticAccessibilityIdentifiers()

// ✅ After v4.3.0 (automatic)
platformPresentContent_L1(content: Button("Test") { })
// No modifier needed - framework components handle this automatically
```

**If you were using `.enableGlobalAutomaticAccessibilityIdentifiers()` with custom views:**

```swift
// ✅ Still needed for custom views
Button("Custom") { }
    .named("CustomButton")
    .enableGlobalAutomaticAccessibilityIdentifiers()
```

## Related Documentation

- [Apple HIG Compliance](AppleHIGCompliance.md)
- [Layer 1 Functions](Layer1Functions.md)
- [Platform Accessibility Extensions](PlatformAccessibilityExtensions.md)
