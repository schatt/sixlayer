# Design System Integration Guide

This guide explains how to integrate external design tokens (Figma, design system JSON, etc.) with SixLayer components using the new Design System Bridge.

## Overview

SixLayer now includes a **Design System Bridge** that allows you to map your existing design tokens to SixLayer components in a single, cohesive abstraction. This eliminates the need to wire design tokens ad-hoc throughout your app.

## Key Concepts

### DesignSystem Protocol

The `DesignSystem` protocol defines the interface for design system implementations:

```swift
public protocol DesignSystem: Sendable {
    var name: String { get }
    func colors(for theme: Theme) -> DesignTokens.Colors
    func typography(for theme: Theme) -> DesignTokens.Typography
    func spacing() -> DesignTokens.Spacing
    func componentStates() -> DesignTokens.ComponentStates
}
```

### Design Tokens

SixLayer provides structured token types for different aspects of your design system:

- **Colors**: Semantic colors, surface colors, text colors, interactive states
- **Typography**: Font styles for different text hierarchies
- **Spacing**: Consistent spacing scale
- **Component States**: Corner radius, border width, shadows, opacity values

## Quick Start

### 1. Create Your Design System

```swift
struct MyBrandDesignSystem: DesignSystem {
    let name = "My Brand"

    func colors(for theme: Theme) -> DesignTokens.Colors {
        // Map your brand colors to SixLayer tokens
        return DesignTokens.Colors(
            primary: Color(hex: "#FF6B35"),      // Your brand primary
            secondary: Color(hex: "#F7931E"),    // Your brand secondary
            accent: Color(hex: "#00B4D8"),       // Your accent color
            // ... map other colors
            background: theme == .dark ? Color.black : Color.white,
            surface: theme == .dark ? Color(hex: "#1F2937") : Color(hex: "#F9FAFB"),
            // ... continue mapping
        )
    }

    func typography(for theme: Theme) -> DesignTokens.Typography {
        // Map your typography scale
        return DesignTokens.Typography(
            largeTitle: Font.custom("YourFont-Bold", size: 34),
            title1: Font.custom("YourFont-Bold", size: 28),
            // ... map other text styles
        )
    }

    func spacing() -> DesignTokens.Spacing {
        // Your spacing scale
        return DesignTokens.Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
    }

    func componentStates() -> DesignTokens.ComponentStates {
        // Your component styling
        return DesignTokens.ComponentStates(
            cornerRadius: DesignTokens.ComponentCornerRadius(
                none: 0, sm: 4, md: 8, lg: 12, xl: 16, full: 999
            ),
            // ... other component states
        )
    }
}
```

### 2. Apply Your Design System

```swift
struct MyApp: App {
    @StateObject private var designSystem = VisualDesignSystem.shared

    init() {
        // Switch to your custom design system
        VisualDesignSystem.shared.switchDesignSystem(MyBrandDesignSystem())
    }

    var body: some Scene {
        WindowGroup {
            ThemedFrameworkView {
                // Your app content
                ContentView()
            }
        }
    }
}
```

### 3. Use Themed Components

```swift
struct MyView: View {
    @Environment(\.designTokens) private var colors
    @Environment(\.spacingTokens) private var spacing

    var body: some View {
        VStack(spacing: spacing.md) {
            Text("Hello World")
                .foregroundColor(colors.text)

            TextField("Enter text", text: .constant(""))
                .themedTextField()

            Button("Primary Action") {
                // Action
            }
            .padding()
            .background(colors.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(spacing.lg)
        .themedCard()
    }
}
```

`ThemedFrameworkView` writes theme values into SwiftUI Environment. **Hosted app views** can read `@Environment(\.designTokens)` (and the other theme keys).

**Framework modifiers** that ViewInspector `inspect()` will evaluate must not declare those `@Environment` properties on the inspect path (`inspect()` never installs Environment). They use `UnhostedInspection.withThemeTokens`: hosted still reads Environment so `.environment(\.colorSystem, …)` works; unhosted uses `ThemePreference` (task-local then `VisualDesignSystem.shared`).

## Mapping External Design Tokens

### From Figma

If you export design tokens from Figma:

```swift
struct FigmaDesignSystem: DesignSystem {
    let figmaTokens: [String: Any] // Your Figma export

    func colors(for theme: Theme) -> DesignTokens.Colors {
        let themeKey = theme == .dark ? "dark" : "light"
        let themeColors = figmaTokens["colors"]?[themeKey] as? [String: String] ?? [:]

        return DesignTokens.Colors(
            primary: Color(hex: themeColors["brand/primary"] ?? "#007AFF"),
            secondary: Color(hex: themeColors["brand/secondary"] ?? "#6B7280"),
            // Map other Figma tokens...
        )
    }
}
```

### From JSON Design System

```swift
struct JSONDesignSystem: DesignSystem {
    let jsonTokens: [String: Any]

    static func fromJSON(_ jsonData: Data) throws -> JSONDesignSystem {
        let tokens = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        return JSONDesignSystem(jsonTokens: tokens)
    }

    func colors(for theme: Theme) -> DesignTokens.Colors {
        let colors = jsonTokens["colors"] as? [String: Any] ?? [:]
        let themeColors = colors[theme.rawValue] as? [String: Any] ?? [:]

        return DesignTokens.Colors(
            primary: Color(hex: themeColors["primary"] as? String ?? "#007AFF"),
            // Map other JSON tokens...
        )
    }
}
```

### From CSS Custom Properties

```swift
struct CSSDesignSystem: DesignSystem {
    let cssVariables: [String: String] // CSS custom properties

    func colors(for theme: Theme) -> DesignTokens.Colors {
        return DesignTokens.Colors(
            primary: Color(css: cssVariables["--color-primary"] ?? "#007AFF"),
            // Map CSS variables...
        )
    }
}
```

## Built-in Design Systems

SixLayer provides several built-in design systems:

### SixLayerDesignSystem (Default)
The default design system that adapts to platform conventions.

### HighContrastDesignSystem
Optimized for accessibility with high contrast ratios.

```swift
VisualDesignSystem.shared.switchDesignSystem(HighContrastDesignSystem())
```

## Runtime Theme Switching

You can switch design systems at runtime:

```swift
class ThemeManager {
    func switchToHighContrast() {
        VisualDesignSystem.shared.switchDesignSystem(HighContrastDesignSystem())
    }

    func switchToBrandTheme() {
        VisualDesignSystem.shared.switchDesignSystem(MyBrandDesignSystem())
    }

    func switchToDefault() {
        VisualDesignSystem.shared.switchDesignSystem(SixLayerDesignSystem())
    }
}
```

## Component Integration

### Automatic Theming

All themed components automatically use your design system:

```swift
// These components automatically adapt to your design system
TextField("Input", text: .constant(""))
    .themedTextField()

VStack {
    Text("Card content")
}
.themedCard()

ThemedProgressBar(progress: 0.5, variant: .primary)
```

### Manual Theming

For custom components, access design tokens via environment:

```swift
struct CustomButton: View {
    @Environment(\.designTokens) private var colors
    @Environment(\.componentStates) private var states

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: states.cornerRadius.md)
                .fill(colors.primary)

            RoundedRectangle(cornerRadius: states.cornerRadius.md)
                .stroke(colors.borderFocus, lineWidth: states.borderWidth.sm)

            Text("Button")
                .foregroundColor(.white)
        }
    }
}
```

## Testing Design Systems

Create test helpers to verify design system integration:

```swift
class DesignSystemTests: XCTestCase {
    func testBrandDesignSystemColors() {
        let designSystem = MyBrandDesignSystem()
        let colors = designSystem.colors(for: .light)

        XCTAssertEqual(colors.primary, Color(hex: "#FF6B35"))
        XCTAssertEqual(colors.background, Color.white)
    }

    func testDesignSystemSwitching() {
        let designSystem = VisualDesignSystem.shared

        designSystem.switchDesignSystem(HighContrastDesignSystem())
        XCTAssertEqual(designSystem.designSystem.name, "HighContrast")

        designSystem.switchDesignSystem(MyBrandDesignSystem())
        XCTAssertEqual(designSystem.designSystem.name, "My Brand")
    }
}
```

## Best Practices

### 1. Semantic Mapping
Map your design tokens to semantic SixLayer tokens:

```swift
// ✅ Good: Semantic mapping
primary: Color(hex: "#FF6B35"),     // Brand primary
destructive: Color.red,            // Keep standard red for errors

// ❌ Avoid: Direct color mapping without semantics
color1: Color(hex: "#FF6B35"),      // What does color1 mean?
```

### 2. Theme Consistency
Ensure dark/light themes work together:

```swift
func colors(for theme: Theme) -> DesignTokens.Colors {
    let isDark = theme == .dark

    return DesignTokens.Colors(
        // Ensure sufficient contrast in both themes
        background: isDark ? Color.black : Color.white,
        text: isDark ? Color.white : Color.black,
        // ...
    )
}
```

### 3. Spacing Scale
Use a consistent spacing scale:

```swift
func spacing() -> DesignTokens.Spacing {
    return DesignTokens.Spacing(
        xs: 4,   // Small gaps
        sm: 8,   // Component padding
        md: 16,  // Section spacing
        lg: 24,  // Layout spacing
        xl: 32,  // Large gaps
        xxl: 48  // Page margins
    )
}
```

### 4. Component States
Define component states consistently:

```swift
func componentStates() -> DesignTokens.ComponentStates {
    return DesignTokens.ComponentStates(
        cornerRadius: DesignTokens.ComponentCornerRadius(
            sm: 4,   // Small buttons/cards
            md: 8,   // Standard cards
            lg: 12,  // Large surfaces
            // ...
        ),
        // ...
    )
}
```

## Migration Guide

### From Hardcoded Colors

Before:
```swift
Text("Hello")
    .foregroundColor(Color.blue)

Button(action: {}) {
    Text("Tap me")
}
.background(Color.blue)
```

After:
```swift
@Environment(\.designTokens) private var colors

Text("Hello")
    .foregroundColor(colors.text)

Button(action: {}) {
    Text("Tap me")
}
.background(colors.primary)
```

### From Custom Styling

Before:
```swift
struct CustomCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}
```

After:
```swift
struct CustomCard: ViewModifier {
    func body(content: Content) -> some View {
        UnhostedInspection.withThemeTokens { tokens in
            content
                .background(tokens.designTokens.surface)
                .cornerRadius(tokens.componentStates.cornerRadius.md)
        }
    }
}
```

Do not put `@Environment(\.designTokens)` on a modifier `body` that `inspect()` evaluates — that floods xcresult diagnostics. Hosted app views (not inspect-evaluated modifiers) can still use Environment.

## Troubleshooting

### Components Not Updating
If components don't reflect design system changes:

1. Ensure `ThemedFrameworkView` wraps your content
2. Check that environment values are accessed correctly
3. Verify design system is set before view rendering

### Color Contrast Issues
For accessibility compliance:

1. Use `HighContrastDesignSystem` for testing
2. Verify contrast ratios meet WCAG guidelines
3. Test with different color blindness simulations

### Performance Considerations
- Design systems are `Sendable`, so they're safe for concurrent access
- Token resolution is cached in environment values
- Avoid creating new design systems frequently

## Examples

See the included examples:
- `DesignSystemBridgeExample.swift` - Interactive design system switcher
- `ExternalDesignTokensExample.swift` - Loading tokens from external sources

## Related Documentation

- [Component Styling Guide](ComponentStylingGuide.md)
- [Accessibility Integration](AccessibilityIntegration.md)
- [Theming Best Practices](ThemingBestPractices.md)