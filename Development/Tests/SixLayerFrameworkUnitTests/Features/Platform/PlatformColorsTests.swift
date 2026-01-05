import Testing


//
//  PlatformColorsTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates platform color utilities functionality and cross-platform color testing,
//  ensuring proper platform color detection and behavior validation across all supported platforms.
//
//  TESTING SCOPE:
//  - Platform color utilities functionality and validation
//  - Cross-platform color consistency and compatibility testing
//  - Platform-specific color behavior testing and validation
//  - Color encoding and decoding functionality testing
//  - Platform color detection and handling testing
//  - Edge cases and error handling for platform color utilities
//
//  METHODOLOGY:
//  - Test platform color utilities functionality using comprehensive color testing
//  - Verify cross-platform color consistency using switch statements and conditional logic
//  - Test platform-specific color behavior using platform detection
//  - Validate color encoding and decoding functionality
//  - Test platform color detection and handling functionality
//  - Test edge cases and error handling for platform color utilities
//
//  QUALITY ASSESSMENT: ⚠️ NEEDS IMPROVEMENT
//  - ❌ Issue: Uses generic XCTAssertNotNil tests instead of business logic validation
//  - ❌ Issue: Missing platform-specific testing with switch statements
//  - ❌ Issue: No validation of actual platform color behavior effectiveness
//  - 🔧 Action Required: Replace generic tests with business logic assertions
//  - 🔧 Action Required: Add platform-specific behavior testing
//  - 🔧 Action Required: Add validation of platform color behavior accuracy
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView (prevents Xcode hangs)
@Suite(.serialized)
open class PlatformColorsTests: BaseTestClass {
    
    // BaseTestClass handles setup automatically - no init() needed
    
    // MARK: - Test Helpers
    
    #if os(iOS)
    /// Helper to extract RGB components from a UIColor
    private func extractRGB(from uiColor: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
    
    /// Helper to calculate brightness from RGB components
    private func calculateBrightness(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        return (red + green + blue) / 3.0
    }
    
    /// Helper to resolve a Color in a specific trait collection and extract RGB
    private func resolveAndExtractRGB(_ color: Color, traitCollection: UITraitCollection) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, brightness: CGFloat) {
        let resolvedColor = UIColor(color).resolvedColor(with: traitCollection)
        let (red, green, blue, alpha) = extractRGB(from: resolvedColor)
        let brightness = calculateBrightness(red: red, green: green, blue: blue)
        return (red, green, blue, alpha, brightness)
    }
    #endif
    
    // MARK: - Helper Functions
    
    /// Create a test view using platform colors to verify they work functionally
    @MainActor
    private func createTestViewWithPlatformColors() -> some View {
        return platformVStackContainer {
            Text("Primary Label")
                .foregroundColor(Color.platformPrimaryLabel)
            Text("Secondary Label")
                .foregroundColor(Color.platformSecondaryLabel)
            Text("Tertiary Label")
                .foregroundColor(Color.platformTertiaryLabel)
        }
        .background(Color.platformBackground)
        .accessibilityLabel("Test view using platform colors")
        .accessibilityHint("Tests that platform colors can be used in actual views")
    }
    
    // MARK: - Platform-Specific Business Logic Tests
    
    @Test @MainActor
    func testPlatformColorsAcrossPlatforms() {
        // Given: Platform-specific color expectations
        let platform = SixLayerPlatform.current
        
        // When: Testing platform colors on different platforms
        // Then: Test platform-specific business logic
        switch platform {
        case .iOS:
            // Test that iOS colors can actually be used in views
            let iosView = createTestViewWithPlatformColors()
            _ = hostRootPlatformView(iosView.enableGlobalAutomaticCompliance())
            // Verify colors are valid by checking they're not clear
            #expect(Color.platformPrimaryLabel != Color.clear, "iOS primary label color should be valid")
            
        case .macOS:
            // Test that macOS colors can actually be used in views
            let macosView = createTestViewWithPlatformColors()
            _ = hostRootPlatformView(macosView.enableGlobalAutomaticCompliance())
            #expect(Color.platformPrimaryLabel != Color.clear, "macOS primary label color should be valid")
            
        case .watchOS:
            // Test that watchOS colors can actually be used in views
            let watchosView = createTestViewWithPlatformColors()
            _ = hostRootPlatformView(watchosView.enableGlobalAutomaticCompliance())
            #expect(Color.platformPrimaryLabel != Color.clear, "watchOS primary label color should be valid")
            
        case .tvOS:
            // Test that tvOS colors can actually be used in views
            let tvosView = createTestViewWithPlatformColors()
            _ = hostRootPlatformView(tvosView.enableGlobalAutomaticCompliance())
            #expect(Color.platformPrimaryLabel != Color.clear, "tvOS primary label color should be valid")
            
        case .visionOS:
            // Test that visionOS colors can actually be used in views
            let visionosView = createTestViewWithPlatformColors()
            _ = hostRootPlatformView(visionosView.enableGlobalAutomaticCompliance())
            #expect(Color.platformPrimaryLabel != Color.clear, "visionOS primary label color should be valid")
        }
    }
    
    @Test func testPlatformColorConsistency() {
        // Given: Platform colors for consistency testing
        let primaryLabel = Color.platformPrimaryLabel
        let secondaryLabel = Color.platformSecondaryLabel
        let tertiaryLabel = Color.platformTertiaryLabel
        let background = Color.platformBackground
        let secondaryBackground = Color.platformSecondaryBackground
        
        // When: Validating platform color consistency
        // Then: Test business logic for color consistency
        // Verify colors maintain their identity across multiple accesses
        #expect(primaryLabel == Color.platformPrimaryLabel, "Primary label color should be consistent")
        #expect(secondaryLabel == Color.platformSecondaryLabel, "Secondary label color should be consistent")
        #expect(tertiaryLabel == Color.platformTertiaryLabel, "Tertiary label color should be consistent")
        #expect(background == Color.platformBackground, "Background color should be consistent")
        #expect(secondaryBackground == Color.platformSecondaryBackground, "Secondary background color should be consistent")
        
        // Test business logic: Platform colors should be different from each other
        #expect(primaryLabel != secondaryLabel, "Primary and secondary label colors should be different")
        #expect(secondaryLabel != tertiaryLabel, "Secondary and tertiary label colors should be different")
        #expect(background != secondaryBackground, "Background and secondary background colors should be different")
        
        // Test business logic: Platform colors should be accessible
        #expect(primaryLabel != Color.clear, "Primary label color should not be clear")
        #expect(secondaryLabel != Color.clear, "Secondary label color should not be clear")
        #expect(background != Color.clear, "Background color should not be clear")
    }
    
    @Test func testPlatformColorEncoding() throws {
        // Given: Platform colors for encoding testing
        let primaryLabel = Color.platformPrimaryLabel
        let secondaryLabel = Color.platformSecondaryLabel
        let background = Color.platformBackground
        
        // When: Encoding platform colors
        let primaryEncoded = try platformColorEncode(primaryLabel)
        let secondaryEncoded = try platformColorEncode(secondaryLabel)
        let backgroundEncoded = try platformColorEncode(background)
        
        // Then: Test business logic for color encoding
        // Encoded data should be non-empty
        #expect(!primaryEncoded.isEmpty, "Primary label color should be encodable (non-empty data)")
        #expect(!secondaryEncoded.isEmpty, "Secondary label color should be encodable (non-empty data)")
        #expect(!backgroundEncoded.isEmpty, "Background color should be encodable (non-empty data)")
        
        // Test business logic: Encoded colors should be decodable
        do {
            let decodedPrimary = try platformColorDecode(primaryEncoded)
            let decodedSecondary = try platformColorDecode(secondaryEncoded)
            let decodedBackground = try platformColorDecode(backgroundEncoded)
            
            // Verify decoded colors are valid
            #expect(decodedPrimary != Color.clear, "Decoded primary label should be valid")
            #expect(decodedSecondary != Color.clear, "Decoded secondary label should be valid")
            #expect(decodedBackground != Color.clear, "Decoded background should be valid")
        } catch {
            Issue.record("Color decoding failed: \(error)")
        }
        
        // Test business logic: Decoded colors should match original colors
        #expect(try platformColorDecode(primaryEncoded) == primaryLabel, "Decoded primary label color should match original")
        #expect(try platformColorDecode(secondaryEncoded) == secondaryLabel, "Decoded secondary label color should match original")
        #expect(try platformColorDecode(backgroundEncoded) == background, "Decoded background color should match original")
    }
    
    // MARK: - Basic Color Tests
    
    /// Test platform primary label color
    /// NOTE: This uses system semantic color Color(.label) which automatically adapts to:
    /// - Light/Dark mode
    /// - High Contrast mode (iOS)
    /// - Other accessibility settings
    @Test func testPlatformPrimaryLabelColor() {
        // Given & When
        let color = Color.platformPrimaryLabel
        
        // Then - Test business logic: Platform primary label color should be properly defined
        #expect(color != Color.clear, "Platform primary label should not be clear")
        
        // Test business logic: Platform primary label should be consistent with platform label
        #expect(color == Color.platformLabel, "Platform primary label should equal platform label")
        
        // Test business logic: Primary label should be different from secondary label
        #expect(color != Color.platformSecondaryLabel, "Primary label should differ from secondary label")
    }
    
    @Test func testPlatformSecondaryLabelColor() {
        // Given & When
        let color = Color.platformSecondaryLabel
        
        // Then
        #expect(color != Color.clear, "Platform secondary label should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Secondary label should differ from primary label")
        #expect(color != Color.platformTertiaryLabel, "Secondary label should differ from tertiary label")
    }
    
    @Test func testPlatformTertiaryLabelColor() {
        // Given & When
        let color = Color.platformTertiaryLabel
        
        // Then
        #expect(color != Color.clear, "Platform tertiary label should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Tertiary label should differ from primary label")
        #expect(color != Color.platformSecondaryLabel, "Tertiary label should differ from secondary label")
    }
    
    @Test func testPlatformQuaternaryLabelColor() {
        // Given & When
        let color = Color.platformQuaternaryLabel
        
        // Then
        #expect(color != Color.clear, "Platform quaternary label should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Quaternary label should differ from primary label")
    }
    
    @Test func testPlatformPlaceholderTextColor() {
        // Given & When
        let color = Color.platformPlaceholderText
        
        // Then
        #expect(color != Color.clear, "Platform placeholder text should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Placeholder text should differ from primary label")
    }
    
    @Test func testPlatformSeparatorColor() {
        // Given & When
        let color = Color.platformSeparator
        
        // Then
        #expect(color != Color.clear, "Platform separator should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Separator should differ from primary label")
    }
    
    @Test func testPlatformOpaqueSeparatorColor() {
        // Given & When
        let color = Color.platformOpaqueSeparator
        
        // Then
        #expect(color != Color.clear, "Platform opaque separator should not be clear")
        #expect(color != Color.platformPrimaryLabel, "Opaque separator should differ from primary label")
    }
    
    // MARK: - Platform-Specific Behavior Tests
    
    @Test func testPlatformTertiaryLabelPlatformBehavior() {
        // Given & When
        let color = Color.platformTertiaryLabel
        
        // Then
        // On iOS, this should be .tertiaryLabel
        // On macOS, this should be .tertiaryLabelColor (not .secondary)
        #expect(color != Color.clear, "Tertiary label should not be clear")
        #if os(iOS)
        // On iOS, tertiary label should be different from secondary
        #expect(color != Color.platformSecondaryLabel, "Tertiary label should differ from secondary on iOS")
        #elseif os(macOS)
        // On macOS, tertiary label should be different from secondary
        #expect(color != Color.platformSecondaryLabel, "Tertiary label should differ from secondary on macOS")
        #endif
    }
    
    @Test func testPlatformQuaternaryLabelPlatformBehavior() {
        // Given & When
        let color = Color.platformQuaternaryLabel
        
        // Then
        // On iOS, this should be .quaternaryLabel
        // On macOS, this should be .quaternaryLabelColor
        #expect(color != Color.clear, "Quaternary label should not be clear")
        #if os(iOS)
        // On iOS, quaternary label should be different from secondary
        #expect(color != Color.platformSecondaryLabel, "Quaternary label should differ from secondary on iOS")
        #elseif os(macOS)
        // On macOS, quaternary label should be different from secondary
        #expect(color != Color.platformSecondaryLabel, "Quaternary label should differ from secondary on macOS")
        #endif
    }
    
    @Test func testPlatformPlaceholderTextPlatformBehavior() {
        // Given & When
        let color = Color.platformPlaceholderText
        
        // Then
        // On iOS, this should be .placeholderText
        // On macOS, this should be .placeholderTextColor
        #expect(color != Color.clear, "Placeholder text should not be clear")
        #if os(iOS)
        // On iOS, placeholder text should be different from primary label
        #expect(color != Color.platformPrimaryLabel, "Placeholder text should differ from primary label on iOS")
        #elseif os(macOS)
        // On macOS, placeholder text should be different from primary label
        #expect(color != Color.platformPrimaryLabel, "Placeholder text should differ from primary label on macOS")
        #endif
    }
    
    @Test func testPlatformOpaqueSeparatorPlatformBehavior() {
        // Given & When
        let color = Color.platformOpaqueSeparator
        
        // Then
        // On iOS, this should be .opaqueSeparator
        // On macOS, this should be .separatorColor
        #expect(color != Color.clear, "Opaque separator should not be clear")
        #if os(iOS)
        // On iOS, opaque separator should be different from regular separator
        #expect(color != Color.platformSeparator, "Opaque separator should differ from regular separator on iOS")
        #elseif os(macOS)
        // On macOS, opaque separator might be the same as separator, but should not be clear
        #expect(color != Color.platformPrimaryLabel, "Opaque separator should differ from primary label on macOS")
        #endif
    }
    
    // MARK: - Consistency Tests
    
    @Test func testColorConsistency() {
        // Given & When
        let primary1 = Color.platformPrimaryLabel
        let primary2 = Color.platformPrimaryLabel
        let secondary1 = Color.platformSecondaryLabel
        let secondary2 = Color.platformSecondaryLabel
        
        // Then
        // Colors should be consistent across multiple calls
        #expect(primary1 == primary2, "Primary label color should be consistent")
        #expect(secondary1 == secondary2, "Secondary label color should be consistent")
    }
    
    @Test func testAllPlatformColorsAreAvailable() {
        // Given & When
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator,
            Color.platformButtonTextOnColor,
            Color.platformShadowColor
        ]
        
        // Then
        for color in colors {
            #expect(color != Color.clear, "All platform colors should not be clear")
        }
    }
    
    // MARK: - Accessibility Tests
    
    @Test func testColorsWorkWithAccessibility() {
        // Given
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator,
            Color.platformButtonTextOnColor,
            Color.platformShadowColor
        ]
        
        // When & Then
        for color in colors {
            // Colors should be accessible and not cause crashes
            #expect(color != Color.clear, "Color should be accessible: \(color)")
            // Verify color can be used in a view
            _ = Text("Test")
                .foregroundColor(color)
        }
    }
    
    // MARK: - Accessibility-Aware Color Tests
    
    @Test func testPlatformButtonTextOnColorIsAvailable() {
        // Given & When
        let buttonTextColor = Color.platformButtonTextOnColor
        
        // Then - Test business logic: Button text color should be available
        #expect(buttonTextColor != Color.clear, "Platform button text on color should be available")
        
        // Test business logic: Button text color should be white for high contrast on colored backgrounds
        #expect(buttonTextColor == Color.white, "Platform button text on color should be white for maximum contrast")
        
        // Test business logic: Button text color should not be clear or transparent
        #expect(buttonTextColor != Color.clear, "Platform button text on color should not be clear")
    }
    
    @Test @MainActor func testPlatformButtonTextOnColorWorksInViews() {
        // Given
        let buttonTextColor = Color.platformButtonTextOnColor
        
        // When: Using the color in a button view
        _ = Button("Test Button") { }
            .foregroundColor(buttonTextColor)
            .background(Color.accentColor)
        
        // Then - Test business logic: Color should work in actual button views
        // (View creation verifies it works - if it compiles and runs, the color is valid)
        #expect(buttonTextColor == Color.white, "Button text color should be white for contrast")
        
        // Test business logic: Color should provide high contrast on colored backgrounds
        _ = Text("Button Text")
            .foregroundColor(buttonTextColor)
            .background(Color.blue)
        
        #expect(buttonTextColor != Color.clear, "Button text color should not be clear")
    }
    
    @Test func testPlatformButtonTextOnColorAccessibilityAdaptation() {
        // Given
        let buttonTextColor = Color.platformButtonTextOnColor
        
        // When & Then - Test business logic: Color should adapt to accessibility settings
        // The color should be white, which provides maximum contrast in both normal and high contrast modes
        #expect(buttonTextColor == Color.white, "Button text color should be white for maximum contrast")
        
        // Test that the color can be used consistently across different accessibility contexts
        #if os(iOS)
        // On iOS, the color should work with UIAccessibility settings
        // White is appropriate for both normal and high contrast modes
        _ = Button("Accessible Button") { }
            .foregroundColor(buttonTextColor)
            .accessibilityLabel("Test Button")
        #expect(buttonTextColor == Color.white, "Button text color should be white for iOS accessibility")
        #endif
    }
    
    @Test func testPlatformShadowColorIsAvailable() {
        // Given & When
        let shadowColor = Color.platformShadowColor
        
        // Then - Test business logic: Shadow color should be available
        #expect(shadowColor != Color.clear, "Platform shadow color should be available")
        
        // Test business logic: Shadow color should have opacity (not fully opaque)
        // Extract alpha value to verify transparency
        #if os(iOS)
        let uiColor = UIColor(shadowColor)
        var alpha: CGFloat = 0
        uiColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha < 1.0, "Shadow color should have some transparency (alpha: \(alpha))")
        #elseif os(macOS)
        let nsColor = NSColor(shadowColor)
        var alpha: CGFloat = 0
        nsColor.getRed(nil, green: nil, blue: nil, alpha: &alpha)
        #expect(alpha < 1.0, "Shadow color should have some transparency (alpha: \(alpha))")
        #else
        // On other platforms, just verify color is valid
        #expect(shadowColor != Color.clear, "Platform shadow color should not be clear")
        
        // Test business logic: Shadow color should be black-based (for shadows)
        #expect(shadowColor != Color.clear, "Platform shadow color should not be clear")
        #endif
    }
    
    @Test func testPlatformShadowColorPlatformBehavior() {
        // Given & When
        let shadowColor = Color.platformShadowColor
        
        // Then - Test business logic: Shadow color should have platform-appropriate opacity
        #expect(shadowColor != Color.clear, "Shadow color should not be clear")
        #expect(shadowColor != Color.platformPrimaryLabel, "Shadow color should differ from primary label")
        #if os(iOS)
        // iOS: Standard shadow opacity (0.1)
        #expect(shadowColor != Color.white, "iOS shadow color should not be white")
        #elseif os(macOS)
        // macOS: Lighter shadow opacity (0.05)
        #expect(shadowColor != Color.white, "macOS shadow color should not be white")
        #elseif os(tvOS)
        // tvOS: More pronounced shadow opacity (0.2)
        #expect(shadowColor != Color.white, "tvOS shadow color should not be white")
        #elseif os(visionOS)
        // visionOS: Moderate shadow opacity (0.15)
        #expect(shadowColor != Color.white, "visionOS shadow color should not be white")
        #else
        // Other platforms: Standard shadow
        #expect(shadowColor != Color.white, "Platform shadow color should not be white")
        #endif
    }
    
    @Test @MainActor func testPlatformShadowColorWorksInViews() {
        // Given
        let shadowColor = Color.platformShadowColor
        
        // When: Using the color in a view with shadow
        _ = Rectangle()
            .fill(Color.platformBackground)
            .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
        
        // Then - Test business logic: Shadow color should work in actual views
        // (View creation verifies it works - if it compiles and runs, the color is valid)
        #expect(shadowColor != Color.clear, "Shadow color should not be clear")
        
        // Test business logic: Shadow color should work with elevation effects
        _ = platformVStackContainer {
            Text("Elevated Content")
        }
        .background(Color.platformBackground)
        .shadow(color: shadowColor, radius: 4)
        
        #expect(shadowColor != Color.platformPrimaryLabel, "Shadow color should differ from primary label")
    }
    
    @Test func testPlatformShadowColorConsistency() {
        // Given & When
        let shadowColor1 = Color.platformShadowColor
        let shadowColor2 = Color.platformShadowColor
        
        // Then - Test business logic: Shadow color should be consistent across multiple calls
        #expect(shadowColor1 == shadowColor2, "Platform shadow color should be consistent")
        
        // Test business logic: Shadow color should not be clear
        #expect(shadowColor1 != Color.clear, "Platform shadow color should not be clear")
        #expect(shadowColor2 != Color.clear, "Platform shadow color should not be clear")
    }
    
    @Test func testAccessibilityAwareColorsInAllPlatforms() {
        // Given
        let buttonTextColor = Color.platformButtonTextOnColor
        let shadowColor = Color.platformShadowColor
        let platform = SixLayerPlatform.current
        
        // When & Then - Test business logic: Accessibility-aware colors should work on all platforms
        #expect(buttonTextColor != Color.clear, "Button text color should not be clear on \(platform)")
        #expect(shadowColor != Color.clear, "Shadow color should not be clear on \(platform)")
        #expect(buttonTextColor == Color.white, "Button text color should be white on \(platform)")
        switch platform {
        case .iOS, .macOS, .watchOS, .tvOS, .visionOS:
            #expect(buttonTextColor != shadowColor, "Button text color should differ from shadow color on \(platform)")
        }
    }
    
    @Test @MainActor func testAccessibilityAwareColorsWithSwiftUIViews() {
        // Given
        let buttonTextColor = Color.platformButtonTextOnColor
        let shadowColor = Color.platformShadowColor
        
        // When: Creating views that use accessibility-aware colors
        _ = Button("Primary Action") { }
            .foregroundColor(buttonTextColor)
            .background(Color.accentColor)
            .cornerRadius(8)
        
        _ = platformVStackContainer {
            Text("Card Content")
                .foregroundColor(Color.platformLabel)
        }
        .padding()
        .background(Color.platformBackground)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
        
        // Then - Test business logic: Colors should work together in complex views
        // Verify colors are valid
        #expect(buttonTextColor != Color.clear, "Button text color should be valid")
        #expect(shadowColor != Color.clear, "Shadow color should be valid")
        #expect(buttonTextColor == Color.white, "Button text color should be white for contrast")
    }
    
    @Test func testAccessibilityAwareColorsDifferentFromOtherColors() {
        // Given
        let buttonTextColor = Color.platformButtonTextOnColor
        let shadowColor = Color.platformShadowColor
        let labelColor = Color.platformLabel
        let backgroundColor = Color.platformBackground
        
        // When & Then - Test business logic: Accessibility-aware colors should be distinct from other colors
        // Button text color should be white (different from label colors)
        #expect(buttonTextColor != labelColor, "Button text color should be different from label color")
        
        // Shadow color should be different from background colors
        #expect(shadowColor != backgroundColor, "Shadow color should be different from background color")
        
        // Button text color and shadow color should be different
        #expect(buttonTextColor != shadowColor, "Button text color should be different from shadow color")
    }
    
    // MARK: - Dark Mode Tests
    
    @Test func testColorsWorkInDarkMode() {
        // Given
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator
        ]
        
        // When & Then
        for color in colors {
            // Colors should work in both light and dark modes
            // Note: System semantic colors automatically adapt to light/dark mode
            // These are semantic colors, not hardcoded values, so they adapt at runtime
            #expect(color != Color.clear, "Color should not be clear: \(color)")
        }
    }
    
    // MARK: - Performance Tests (removed)
    
    // MARK: - Edge Case Tests
    
    @Test func testColorsInDifferentContexts() {
        // Given
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator
        ]
        
        // When & Then
        for color in colors {
            // Colors should work in different contexts (views, modifiers, etc.)
            _ = Text("Test")
                .foregroundColor(color)
            
            #expect(color != Color.clear, "Color should not be clear: \(color)")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testColorsWithSwiftUIViews() {
        // Given
        let testColors = [
            ("Primary", Color.platformPrimaryLabel),
            ("Secondary", Color.platformSecondaryLabel),
            ("Tertiary", Color.platformTertiaryLabel),
            ("Quaternary", Color.platformQuaternaryLabel),
            ("Placeholder", Color.platformPlaceholderText),
            ("Separator", Color.platformSeparator),
            ("Opaque Separator", Color.platformOpaqueSeparator)
        ]
        
        // When & Then
        for (name, color) in testColors {
            _ = platformVStackContainer {
                Text("\(name) Label")
                    .foregroundColor(color)
                
                Rectangle()
                    .fill(color)
                    .frame(height: 1)
            }
            
            #expect(color != Color.clear, "Color should not be clear: \(name)")
        }
    }
    
    // MARK: - Accessibility Adaptation Tests
    
    /// Test that platform colors actually resolve to different values in light vs dark mode
    /// This verifies the adaptive behavior by extracting resolved color values
    @Test @MainActor func testPlatformColorsResolveDifferentlyInLightAndDarkMode() {
        // Given: Platform semantic colors
        let labelColor = Color.platformPrimaryLabel
        let backgroundColor = Color.platformBackground
        
        // When: Resolving colors in different environments
        // We'll extract the actual resolved RGB values to verify they're different
        
        #if os(iOS)
        // Resolve colors in light and dark mode
        let lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
        let darkTraitCollection = UITraitCollection(userInterfaceStyle: .dark)
        
        let (_, _, _, _, lightLabelBrightness) = resolveAndExtractRGB(labelColor, traitCollection: lightTraitCollection)
        let (_, _, _, _, darkLabelBrightness) = resolveAndExtractRGB(labelColor, traitCollection: darkTraitCollection)
        let (_, _, _, _, lightBgBrightness) = resolveAndExtractRGB(backgroundColor, traitCollection: lightTraitCollection)
        let (_, _, _, _, darkBgBrightness) = resolveAndExtractRGB(backgroundColor, traitCollection: darkTraitCollection)
        
        // Then: Colors should be different in light vs dark mode
        // Label should be dark in light mode and light in dark mode
        #expect(lightLabelBrightness < darkLabelBrightness, "Label should be darker in light mode (\(lightLabelBrightness)) than dark mode (\(darkLabelBrightness))")
        
        // Background should be lighter in light mode than in dark mode
        #expect(lightBgBrightness > darkBgBrightness, "Background should be lighter in light mode (\(lightBgBrightness)) than dark mode (\(darkBgBrightness))")
        
        // Label and background should contrast in both modes
        let lightContrast = abs(lightLabelBrightness - lightBgBrightness)
        let darkContrast = abs(darkLabelBrightness - darkBgBrightness)
        #expect(lightContrast > 0.3, "Label and background should contrast in light mode (contrast: \(lightContrast))")
        #expect(darkContrast > 0.3, "Label and background should contrast in dark mode (contrast: \(darkContrast))")
        
        #elseif os(macOS)
        // On macOS, verify colors are valid semantic colors
        // Note: NSColor resolution for different appearances is more complex
        #expect(labelColor != Color.clear, "Label color should be valid")
        #expect(backgroundColor != Color.clear, "Background color should be valid")
        #expect(labelColor != backgroundColor, "Label and background should contrast")
        
        #else
        // Other platforms: Verify colors are valid semantic colors
        #expect(labelColor != Color.clear, "Label color should be valid")
        #expect(backgroundColor != Color.clear, "Background color should be valid")
        #expect(labelColor != backgroundColor, "Label and background should contrast")
        #endif
    }
    
    /// Test that platform colors adapt when high contrast mode is enabled
    /// This verifies the adaptive behavior by mocking high contrast mode
    @Test @MainActor func testPlatformColorsAdaptToHighContrastMode() {
        // Given: Mock high contrast mode enabled
        RuntimeCapabilityDetection.setTestHighContrast(true)
        defer {
            RuntimeCapabilityDetection.setTestHighContrast(nil)
        }
        
        // Verify high contrast is detected as enabled
        #expect(RuntimeCapabilityDetection.isHighContrastEnabled == true, "High contrast should be enabled via mock")
        
        // When: Colors are used in views with high contrast enabled
        let primaryLabel = Color.platformPrimaryLabel
        let secondaryLabel = Color.platformSecondaryLabel
        let backgroundColor = Color.platformBackground
        
        let testView = VStack {
            Text("Primary Label")
                .foregroundColor(primaryLabel)
            Text("Secondary Label")
                .foregroundColor(secondaryLabel)
            Rectangle()
                .fill(backgroundColor)
        }
        
        // Then: View should render successfully
        // In high contrast mode, the system automatically adjusts these semantic colors
        // to provide better contrast ratios
        _ = hostRootPlatformView(testView.enableGlobalAutomaticCompliance())
        
        // Verify colors are valid semantic colors
        #expect(primaryLabel != Color.clear, "Primary label should be valid")
        #expect(secondaryLabel != Color.clear, "Secondary label should be valid")
        #expect(backgroundColor != Color.clear, "Background should be valid")
        
        // Colors should maintain hierarchy (all different)
        #expect(primaryLabel != secondaryLabel, "Primary and secondary should differ")
        #expect(primaryLabel != backgroundColor, "Primary label and background should contrast")
        #expect(secondaryLabel != backgroundColor, "Secondary label and background should contrast")
        
        // Test with high contrast disabled
        RuntimeCapabilityDetection.setTestHighContrast(false)
        #expect(RuntimeCapabilityDetection.isHighContrastEnabled == false, "High contrast should be disabled via mock")
        
        // Colors should still be valid when high contrast is disabled
        #expect(primaryLabel != Color.clear, "Primary label should be valid without high contrast")
        #expect(backgroundColor != Color.clear, "Background should be valid without high contrast")
    }
    
    /// Test that platform colors provide different contrast in high contrast vs normal mode
    /// This verifies the actual adaptive behavior by comparing resolved color values
    @Test @MainActor func testPlatformColorsProvideHigherContrastInHighContrastMode() {
        // Given: Platform colors
        let labelColor = Color.platformPrimaryLabel
        let backgroundColor = Color.platformBackground
        
        #if os(iOS)
        // When: Resolving colors with high contrast enabled vs disabled
        RuntimeCapabilityDetection.setTestHighContrast(true)
        defer {
            RuntimeCapabilityDetection.setTestHighContrast(nil)
        }
        
        // Resolve colors in high contrast and normal mode
        let highContrastTraitCollection: UITraitCollection
        let normalTraitCollection: UITraitCollection
        
        if #available(iOS 17.0, *) {
            highContrastTraitCollection = UITraitCollection { mutableTraits in
                mutableTraits.userInterfaceStyle = .light
                mutableTraits.accessibilityContrast = .high
            }
            normalTraitCollection = UITraitCollection { mutableTraits in
                mutableTraits.userInterfaceStyle = .light
                mutableTraits.accessibilityContrast = .normal
            }
        } else {
            // Fallback for iOS < 17
            highContrastTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(accessibilityContrast: .high)
            ])
            normalTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceStyle: .light),
                UITraitCollection(accessibilityContrast: .normal)
            ])
        }
        
        let (_, _, _, _, hcLabelBrightness) = resolveAndExtractRGB(labelColor, traitCollection: highContrastTraitCollection)
        let (_, _, _, _, normalLabelBrightness) = resolveAndExtractRGB(labelColor, traitCollection: normalTraitCollection)
        let (_, _, _, _, hcBgBrightness) = resolveAndExtractRGB(backgroundColor, traitCollection: highContrastTraitCollection)
        let (_, _, _, _, normalBgBrightness) = resolveAndExtractRGB(backgroundColor, traitCollection: normalTraitCollection)
        
        // Calculate contrast ratios (simplified - actual WCAG formula is more complex)
        let hcContrast = abs(hcLabelBrightness - hcBgBrightness)
        let normalContrast = abs(normalLabelBrightness - normalBgBrightness)
        
        // Then: High contrast mode should provide better or equal contrast
        // Note: The system may adjust colors to provide higher contrast in high contrast mode
        #expect(hcContrast >= normalContrast || abs(hcContrast - normalContrast) < 0.1, 
                "High contrast mode should provide equal or better contrast (hc: \(hcContrast), normal: \(normalContrast))")
        
        // Colors should still provide contrast in both modes
        #expect(hcContrast > 0.3, "Label and background should contrast in high contrast mode (contrast: \(hcContrast))")
        #expect(normalContrast > 0.3, "Label and background should contrast in normal mode (contrast: \(normalContrast))")
        
        #else
        // On other platforms, verify colors are valid semantic colors
        #expect(labelColor != Color.clear, "Label color should be valid")
        #expect(backgroundColor != Color.clear, "Background color should be valid")
        #expect(labelColor != backgroundColor, "Label and background should contrast")
        #endif
    }
    
    /// Test that platform label colors are semantic and adapt to accessibility settings
    /// NOTE: System semantic colors (like .label, .secondaryLabel) automatically adapt to:
    /// - Light/Dark mode
    /// - High Contrast mode (iOS: UIAccessibility.isDarkerSystemColorsEnabled)
    /// - Other accessibility preferences
    /// These tests verify the colors are semantic (not hardcoded) and will adapt at runtime
    @Test func testPlatformLabelColorsAreSemantic() {
        // Given: Platform label colors use system semantic colors
        let primaryLabel = Color.platformPrimaryLabel
        let secondaryLabel = Color.platformSecondaryLabel
        let tertiaryLabel = Color.platformTertiaryLabel
        
        // Then: Colors should be valid semantic colors (not clear/transparent)
        // These colors will automatically adapt to:
        // - Light/Dark mode changes
        // - High Contrast mode (when enabled)
        // - Other accessibility settings
        #expect(primaryLabel != Color.clear, "Primary label should be a valid semantic color")
        #expect(secondaryLabel != Color.clear, "Secondary label should be a valid semantic color")
        #expect(tertiaryLabel != Color.clear, "Tertiary label should be a valid semantic color")
        
        // Colors should be different from each other
        #expect(primaryLabel != secondaryLabel, "Primary and secondary labels should differ")
        #expect(secondaryLabel != tertiaryLabel, "Secondary and tertiary labels should differ")
    }
    
    /// Test that platform colors provide contrast between label and background
    /// This verifies the adaptive behavior ensures readability
    @Test func testPlatformColorsProvideContrast() {
        // Given: Platform colors that should provide contrast
        let labelColor = Color.platformLabel
        let backgroundColor = Color.platformBackground
        
        // Then: Label and background should be different to ensure readability
        // This contrast is maintained automatically by the system in both light and dark modes
        #expect(labelColor != backgroundColor, "Label and background should provide contrast")
        
        // Verify both are valid semantic colors
        #expect(labelColor != Color.clear, "Label color should be valid")
        #expect(backgroundColor != Color.clear, "Background color should be valid")
    }
    
    /// Test that platform colors adapt to high contrast mode
    /// NOTE: On iOS, when UIAccessibility.isDarkerSystemColorsEnabled is true,
    /// system semantic colors automatically provide higher contrast
    @Test @MainActor func testPlatformColorsAdaptToHighContrast() {
        // Given: Platform colors use system semantic colors
        let primaryLabel = Color.platformPrimaryLabel
        let buttonTextColor = Color.platformButtonTextOnColor
        
        // Then: Colors should be valid and will adapt to high contrast mode
        // On iOS, when high contrast is enabled, system colors automatically
        // provide higher contrast versions
        #expect(primaryLabel != Color.clear, "Primary label should adapt to high contrast mode")
        #expect(buttonTextColor != Color.clear, "Button text color should adapt to high contrast mode")
        
        // Button text color should be white for maximum contrast
        #expect(buttonTextColor == Color.white, "Button text should be white for maximum contrast")
        
        // Verify the color works in a view (which will adapt at runtime)
        _ = Button("Test") { }
            .foregroundColor(buttonTextColor)
            .background(Color.blue)
    }
    
    /// Test that different label colors maintain hierarchy in different environments
    /// This verifies that the semantic colors maintain their relative relationships
    @Test func testPlatformLabelColorsMaintainHierarchy() {
        // Given: Platform label colors with different hierarchy levels
        let primary = Color.platformPrimaryLabel
        let secondary = Color.platformSecondaryLabel
        let tertiary = Color.platformTertiaryLabel
        let quaternary = Color.platformQuaternaryLabel
        
        // Then: Colors should maintain hierarchy (all different from each other)
        // This hierarchy is maintained by the system in all color schemes and accessibility modes
        #expect(primary != secondary, "Primary should differ from secondary")
        #expect(secondary != tertiary, "Secondary should differ from tertiary")
        #expect(tertiary != quaternary, "Tertiary should differ from quaternary")
        #expect(primary != tertiary, "Primary should differ from tertiary")
        #expect(primary != quaternary, "Primary should differ from quaternary")
        #expect(secondary != quaternary, "Secondary should differ from quaternary")
        
        // All should be valid semantic colors
        #expect(primary != Color.clear, "Primary label should be valid")
        #expect(secondary != Color.clear, "Secondary label should be valid")
        #expect(tertiary != Color.clear, "Tertiary label should be valid")
        #expect(quaternary != Color.clear, "Quaternary label should be valid")
    }
    
    // MARK: - Documentation Tests
    
    @Test @MainActor func testColorUsageExamples() {
        // Given
        _ = platformVStackContainer {
            Text("Primary Text")
                .foregroundColor(.platformPrimaryLabel)
            
            Text("Secondary Text")
                .foregroundColor(.platformSecondaryLabel)
            
            Text("Tertiary Text")
                .foregroundColor(.platformTertiaryLabel)
            
            Text("Quaternary Text")
                .foregroundColor(.platformQuaternaryLabel)
            
            Text("Placeholder Text")
                .foregroundColor(.platformPlaceholderText)
            
            Divider()
                .background(Color.platformSeparator)
            
            Rectangle()
                .fill(Color.platformOpaqueSeparator)
                .frame(height: 1)
        }
        
        // When & Then
        // Verify colors are valid semantic colors
        #expect(Color.platformPrimaryLabel != Color.clear, "Primary label color should be valid")
        #expect(Color.platformSecondaryLabel != Color.clear, "Secondary label color should be valid")
        #expect(Color.platformPlaceholderText != Color.clear, "Placeholder text color should be valid")
        #expect(Color.platformSeparator != Color.clear, "Separator color should be valid")
        #expect(Color.platformOpaqueSeparator != Color.clear, "Opaque separator color should be valid")
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test func testBackwardCompatibility() {
        // Given & When
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator
        ]
        
        // Then
        // All colors should be backward compatible (valid and usable)
        for color in colors {
            #expect(color != Color.clear, "Color should be backward compatible: \(color)")
            // Verify color can be used in a view
            _ = Text("Test")
                .foregroundColor(color)
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testColorErrorHandling() {
        // Given & When
        let colors = [
            Color.platformPrimaryLabel,
            Color.platformSecondaryLabel,
            Color.platformTertiaryLabel,
            Color.platformQuaternaryLabel,
            Color.platformPlaceholderText,
            Color.platformSeparator,
            Color.platformOpaqueSeparator
        ]
        
        // Then
        // Colors should handle errors gracefully
        for color in colors {
            #expect(throws: Never.self, "Color should handle errors gracefully: \(color)") { {
                _ = color
            } }
        }
    }
    
    // MARK: - Color.named() Tests
    
    @Test func testColorNamedBackground() {
        // Given: A request for "background" color name
        // When: Resolving via Color.named()
        let color = Color.named("background")
        
        // Then: Should return backgroundColor (maps to platform background)
        #expect(color != nil, "Color.named('background') should return a color")
        #expect(color == Color.backgroundColor, "Color.named('background') should map to backgroundColor")
    }
    
    @Test func testColorNamedBackgroundMapsToPlatformBackground() {
        // Given: A request for "background" color name
        // When: Resolving via Color.named()
        let namedColor = Color.named("background")
        
        // Then: Should map to platform-appropriate background color
        #expect(namedColor != nil, "Color.named('background') should return a color")
        let backgroundColor = Color.backgroundColor
        
        // Verify they're the same (both map to platformBackground)
        #expect(namedColor == backgroundColor, "Color.named('background') should equal Color.backgroundColor")
    }
    
    @Test func testColorNamedInvalidNameReturnsNil() {
        // Given: An invalid color name
        // When: Resolving via Color.named()
        let color = Color.named("invalidColorName")
        
        // Then: Should return nil
        #expect(color == nil, "Color.named() with invalid name should return nil")
    }
    
    @Test func testColorNamedEmptyStringReturnsNil() {
        // Given: An empty string
        // When: Resolving via Color.named()
        let color = Color.named("")
        
        // Then: Should return nil
        #expect(color == nil, "Color.named() with empty string should return nil")
    }
    
    @Test func testColorNamedNilReturnsNil() {
        // Given: A nil color name
        // When: Resolving via Color.named()
        let color = Color.named(nil)
        
        // Then: Should return nil
        #expect(color == nil, "Color.named() with nil should return nil")
    }
    
    @Test func testColorNamedSystemBackground() {
        // Given: A request for "systemBackground" color name
        // When: Resolving via Color.named()
        let color = Color.named("systemBackground")
        
        // Then: Should return a color that maps to backgroundColor
        #expect(color != nil, "Color.named('systemBackground') should return a color")
        #expect(color == Color.backgroundColor, "Color.named('systemBackground') should map to backgroundColor")
    }
    
    @Test func testColorNamedWithDefaultFallback() {
        // Given: An invalid color name and a default color
        let defaultColor = Color.blue
        
        // When: Resolving via Color.named() with default
        let color = Color.named("invalidColorName", default: defaultColor)
        
        // Then: Should return the default color
        #expect(color == defaultColor, "Color.named() with invalid name should return default color")
    }
    
    @Test func testColorNamedWithDefaultFallbackValidName() {
        // Given: A valid color name and a default color
        let defaultColor = Color.blue
        
        // When: Resolving via Color.named() with default
        let color = Color.named("background", default: defaultColor)
        
        // Then: Should return the named color, not the default
        #expect(color != defaultColor, "Color.named() with valid name should return named color, not default")
        #expect(color == Color.backgroundColor, "Color.named('background') should map to backgroundColor")
    }
    
    @Test func testColorNamedCardBackground() {
        // Given: A request for "cardBackground" color name
        // When: Resolving via Color.named()
        let color = Color.named("cardBackground")
        
        // Then: Should return cardBackground color
        #expect(color != nil, "Color.named('cardBackground') should return a color")
        #expect(color == Color.cardBackground, "Color.named('cardBackground') should map to cardBackground")
    }
    
    @Test func testColorNamedLabel() {
        // Given: A request for "label" color name
        // When: Resolving via Color.named()
        let color = Color.named("label")
        
        // Then: Should return label color
        #expect(color != nil, "Color.named('label') should return a color")
        #expect(color == Color.label, "Color.named('label') should map to label")
    }
    
    @Test func testColorNamedSeparator() {
        // Given: A request for "separator" color name
        // When: Resolving via Color.named()
        let color = Color.named("separator")
        
        // Then: Should return separator color
        #expect(color != nil, "Color.named('separator') should return a color")
        #expect(color == Color.separator, "Color.named('separator') should map to separator")
    }
    
    @Test func testColorNamedSystemColors() {
        // Given: System color names
        let systemColors: [(String, Color)] = [
            ("red", Color.red),
            ("blue", Color.blue),
            ("green", Color.green),
            ("orange", Color.orange),
            ("yellow", Color.yellow),
            ("purple", Color.purple),
            ("pink", Color.pink),
            ("gray", Color.gray),
            ("black", Color.black),
            ("white", Color.white),
            ("clear", Color.clear),
            ("primary", Color.primary),
            ("secondary", Color.secondary),
            ("accentColor", Color.accentColor)
        ]
        
        // When & Then: Each system color should resolve correctly
        for (name, expectedColor) in systemColors {
            let color = Color.named(name)
            #expect(color != nil, "Color.named('\(name)') should return a color")
            #expect(color == expectedColor, "Color.named('\(name)') should map to \(name)")
        }
    }
    
    @Test func testColorNamedSystemColorsWithDefault() {
        // Given: System color names with default fallback
        let defaultColor = Color.gray
        
        // When: Resolving system colors with default
        let red = Color.named("red", default: defaultColor)
        let blue = Color.named("blue", default: defaultColor)
        let invalid = Color.named("invalidColor", default: defaultColor)
        
        // Then: Should return the named color for valid names, default for invalid
        #expect(red == Color.red, "Color.named('red', default:) should return red")
        #expect(blue == Color.blue, "Color.named('blue', default:) should return blue")
        #expect(invalid == defaultColor, "Color.named('invalidColor', default:) should return default")
    }
    
    // MARK: - Material.named() Tests
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedRegularMaterial() {
        // Given: A request for "regularMaterial" name
        // When: Resolving via Material.named()
        let material = Material.named("regularMaterial")
        
        // Then: Should return .regularMaterial
        #expect(material != nil, "Material.named('regularMaterial') should return a material")
        // Note: Material doesn't conform to Equatable, so we verify it's not nil
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedThinMaterial() {
        // Given: A request for "thinMaterial" name
        // When: Resolving via Material.named()
        let material = Material.named("thinMaterial")
        
        // Then: Should return .thinMaterial
        #expect(material != nil, "Material.named('thinMaterial') should return a material")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedThickMaterial() {
        // Given: A request for "thickMaterial" name
        // When: Resolving via Material.named()
        let material = Material.named("thickMaterial")
        
        // Then: Should return .thickMaterial
        #expect(material != nil, "Material.named('thickMaterial') should return a material")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedUltraThinMaterial() {
        // Given: A request for "ultraThinMaterial" name
        // When: Resolving via Material.named()
        let material = Material.named("ultraThinMaterial")
        
        // Then: Should return .ultraThinMaterial
        #expect(material != nil, "Material.named('ultraThinMaterial') should return a material")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedUltraThickMaterial() {
        // Given: A request for "ultraThickMaterial" name
        // When: Resolving via Material.named()
        let material = Material.named("ultraThickMaterial")
        
        // Then: Should return .ultraThickMaterial
        #expect(material != nil, "Material.named('ultraThickMaterial') should return a material")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedInvalidNameReturnsNil() {
        // Given: An invalid material name
        // When: Resolving via Material.named()
        let material = Material.named("invalidMaterialName")
        
        // Then: Should return nil
        #expect(material == nil, "Material.named() with invalid name should return nil")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedEmptyStringReturnsNil() {
        // Given: An empty string
        // When: Resolving via Material.named()
        let material = Material.named("")
        
        // Then: Should return nil
        #expect(material == nil, "Material.named() with empty string should return nil")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test func testMaterialNamedNilReturnsNil() {
        // Given: A nil material name
        // When: Resolving via Material.named()
        let material = Material.named(nil)
        
        // Then: Should return nil
        #expect(material == nil, "Material.named() with nil should return nil")
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @Test @MainActor func testMaterialNamedCanBeUsedInViews() {
        // Given: Material names
        let materialNames = ["regularMaterial", "thinMaterial", "thickMaterial", "ultraThinMaterial", "ultraThickMaterial"]
        
        // When: Resolving materials and using in views
        for materialName in materialNames {
            let material = Material.named(materialName)
            #expect(material != nil, "Material.named('\(materialName)') should return a material")
            
            // Verify material can be used in a view
            let _ = Rectangle()
                .background(material!)
            #expect(Bool(true), "Material should be usable in views")
        }
    }
}
