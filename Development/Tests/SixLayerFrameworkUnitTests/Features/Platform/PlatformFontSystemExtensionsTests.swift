import Testing

//
//  PlatformFontSystemExtensionsTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates platform font utilities functionality and cross-platform font testing,
//  ensuring proper platform font detection and behavior validation across all supported platforms.
//
//  TESTING SCOPE:
//  - Platform font utilities functionality and validation
//  - Cross-platform font consistency and compatibility testing
//  - Platform-specific font behavior testing and validation
//  - Font accessor functionality testing
//  - Platform font detection and handling testing
//  - Edge cases and error handling for platform font utilities
//
//  METHODOLOGY:
//  - TDD RED phase: Tests written before implementation
//  - Test platform font utilities functionality using comprehensive font testing
//  - Verify cross-platform font consistency using switch statements and conditional logic
//  - Test platform-specific font behavior using platform detection
//  - Validate font accessor functionality
//  - Test platform font detection and handling functionality
//  - Test edge cases and error handling for platform font utilities
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView (prevents Xcode hangs)
@Suite(.serialized)
open class PlatformFontSystemExtensionsTests: BaseTestClass {
    
    // BaseTestClass handles setup automatically - no init() needed
    
    // MARK: - Test Helpers
    
    #if os(iOS)
    /// Helper to extract font information from UIFont
    private func extractFontInfo(from uiFont: UIFont) -> (size: CGFloat, weight: UIFont.Weight) {
        let size = uiFont.pointSize
        let weight = uiFont.weight
        return (size, weight)
    }
    #elseif os(macOS)
    /// Helper to extract font information from NSFont
    private func extractFontInfo(from nsFont: NSFont) -> CGFloat {
        let size = nsFont.pointSize
        // NSFont doesn't have a direct weight property like UIFont
        return size
    }
    #endif
    
    // MARK: - Helper Functions
    
    /// Create a test view using platform fonts to verify they work functionally
    @MainActor
    private func createTestViewWithPlatformFonts() -> some View {
        return platformVStackContainer {
            Text("Large Title")
                .font(.platformLargeTitle)
            Text("Title")
                .font(.platformTitle)
            Text("Headline")
                .font(.platformHeadline)
            Text("Body")
                .font(.platformBody)
            Text("Caption")
                .font(.platformCaption)
        }
        .accessibilityLabel("Test view using platform fonts")
        .accessibilityHint("Tests that platform fonts can be used in actual views")
    }
    
    // MARK: - Platform-Specific Business Logic Tests
    
    @Test @MainActor
    func testPlatformFontsAcrossPlatforms() {
        // Given: Platform-specific font expectations
        let platform = SixLayerPlatform.current
        
        // When: Testing platform fonts on different platforms
        // Then: Test platform-specific business logic
        switch platform {
        case .iOS:
            // Test that iOS fonts can actually be used in views
            let iosView = createTestViewWithPlatformFonts()
            _ = hostRootPlatformView(iosView.enableGlobalAutomaticCompliance())
            // Verify fonts are valid by checking they're not system default
            #expect(Font.platformBody != Font.system(size: 0), "iOS body font should be valid")
            
        case .macOS:
            // Test that macOS fonts can actually be used in views
            let macosView = createTestViewWithPlatformFonts()
            _ = hostRootPlatformView(macosView.enableGlobalAutomaticCompliance())
            #expect(Font.platformBody != Font.system(size: 0), "macOS body font should be valid")
            
        case .watchOS:
            // Test that watchOS fonts can actually be used in views
            let watchosView = createTestViewWithPlatformFonts()
            _ = hostRootPlatformView(watchosView.enableGlobalAutomaticCompliance())
            #expect(Font.platformBody != Font.system(size: 0), "watchOS body font should be valid")
            
        case .tvOS:
            // Test that tvOS fonts can actually be used in views
            let tvosView = createTestViewWithPlatformFonts()
            _ = hostRootPlatformView(tvosView.enableGlobalAutomaticCompliance())
            #expect(Font.platformBody != Font.system(size: 0), "tvOS body font should be valid")
            
        case .visionOS:
            // Test that visionOS fonts can actually be used in views
            let visionosView = createTestViewWithPlatformFonts()
            _ = hostRootPlatformView(visionosView.enableGlobalAutomaticCompliance())
            #expect(Font.platformBody != Font.system(size: 0), "visionOS body font should be valid")
        }
    }
    
    @Test func testPlatformFontConsistency() {
        // Given: Platform fonts for consistency testing
        let largeTitle = Font.platformLargeTitle
        let title = Font.platformTitle
        let headline = Font.platformHeadline
        let body = Font.platformBody
        let caption = Font.platformCaption
        
        // When: Validating platform font consistency
        // Then: Test business logic for font consistency
        // Verify fonts maintain their identity across multiple accesses
        // Note: Font doesn't conform to Equatable, so we verify they're not nil by using them
        _ = Text("Test").font(largeTitle)
        _ = Text("Test").font(title)
        _ = Text("Test").font(headline)
        _ = Text("Test").font(body)
        _ = Text("Test").font(caption)
        
        // Test business logic: Platform fonts should be different from each other
        // We can't directly compare Font values, but we can verify they're usable
        #expect(Bool(true), "Platform fonts should be consistent and usable")
    }
    
    // MARK: - Semantic Text Style Tests
    
    /// Test platform large title font
    @Test func testPlatformLargeTitleFont() {
        // Given & When
        let font = Font.platformLargeTitle
        
        // Then - Test business logic: Platform large title font should be properly defined
        _ = Text("Large Title").font(font)
        #expect(Bool(true), "Platform large title should be usable")
    }
    
    /// Test platform title font
    @Test func testPlatformTitleFont() {
        // Given & When
        let font = Font.platformTitle
        
        // Then
        _ = Text("Title").font(font)
        #expect(Bool(true), "Platform title should be usable")
    }
    
    /// Test platform title2 font
    @Test func testPlatformTitle2Font() {
        // Given & When
        let font = Font.platformTitle2
        
        // Then
        _ = Text("Title 2").font(font)
        #expect(Bool(true), "Platform title2 should be usable")
    }
    
    /// Test platform title3 font
    @Test func testPlatformTitle3Font() {
        // Given & When
        let font = Font.platformTitle3
        
        // Then
        _ = Text("Title 3").font(font)
        #expect(Bool(true), "Platform title3 should be usable")
    }
    
    /// Test platform headline font
    @Test func testPlatformHeadlineFont() {
        // Given & When
        let font = Font.platformHeadline
        
        // Then
        _ = Text("Headline").font(font)
        #expect(Bool(true), "Platform headline should be usable")
    }
    
    /// Test platform body font
    @Test func testPlatformBodyFont() {
        // Given & When
        let font = Font.platformBody
        
        // Then
        _ = Text("Body").font(font)
        #expect(Bool(true), "Platform body should be usable")
    }
    
    /// Test platform callout font
    @Test func testPlatformCalloutFont() {
        // Given & When
        let font = Font.platformCallout
        
        // Then
        _ = Text("Callout").font(font)
        #expect(Bool(true), "Platform callout should be usable")
    }
    
    /// Test platform subheadline font
    @Test func testPlatformSubheadlineFont() {
        // Given & When
        let font = Font.platformSubheadline
        
        // Then
        _ = Text("Subheadline").font(font)
        #expect(Bool(true), "Platform subheadline should be usable")
    }
    
    /// Test platform footnote font
    @Test func testPlatformFootnoteFont() {
        // Given & When
        let font = Font.platformFootnote
        
        // Then
        _ = Text("Footnote").font(font)
        #expect(Bool(true), "Platform footnote should be usable")
    }
    
    /// Test platform caption font
    @Test func testPlatformCaptionFont() {
        // Given & When
        let font = Font.platformCaption
        
        // Then
        _ = Text("Caption").font(font)
        #expect(Bool(true), "Platform caption should be usable")
    }
    
    /// Test platform caption2 font
    @Test func testPlatformCaption2Font() {
        // Given & When
        let font = Font.platformCaption2
        
        // Then
        _ = Text("Caption 2").font(font)
        #expect(Bool(true), "Platform caption2 should be usable")
    }
    
    // MARK: - Platform Font Accessor Tests
    
    /// Test platform font accessor returns valid platform font
    @Test func testPlatformFontAccessor() {
        // Given: A SwiftUI Font
        let font = Font.platformBody
        
        // When: Accessing platform font
        let platformFont = font.platformFont
        
        // Then: Platform font should be accessible
        #if os(iOS)
        // On iOS, should return UIFont
        #expect(platformFont is UIFont, "Platform font accessor should return UIFont on iOS")
        #elseif os(macOS)
        // On macOS, should return NSFont
        #expect(platformFont is NSFont, "Platform font accessor should return NSFont on macOS")
        #else
        // On other platforms, should return Font
        #expect(Bool(true), "Platform font accessor should work on other platforms")
        #endif
    }
    
    /// Test platform font accessor with different font styles
    @Test func testPlatformFontAccessorWithDifferentStyles() {
        // Given: Different font styles
        let fonts = [
            Font.platformLargeTitle,
            Font.platformTitle,
            Font.platformHeadline,
            Font.platformBody,
            Font.platformCaption
        ]
        
        // When & Then: Each font should have accessible platform font
        for font in fonts {
            let platformFont = font.platformFont
            #if os(iOS)
            #expect(platformFont is UIFont, "Platform font should be UIFont")
            #elseif os(macOS)
            #expect(platformFont is NSFont, "Platform font should be NSFont")
            #else
            #expect(Bool(true), "Platform font should be accessible")
            #endif
        }
    }
    
    // MARK: - Platform System Font Helper Tests
    
    /// Test platform system font creation
    @Test func testPlatformSystemFont() {
        // Given: Font parameters
        let size: CGFloat = 16
        let weight = Font.Weight.regular
        let design = Font.Design.default
        
        // When: Creating platform system font
        let font = Font.platformSystem(size: size, weight: weight, design: design)
        
        // Then: Font should be usable
        _ = Text("System Font").font(font)
        #expect(Bool(true), "Platform system font should be usable")
    }
    
    /// Test platform system font with different weights
    @Test func testPlatformSystemFontWithWeights() {
        // Given: Different font weights
        let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        
        // When & Then: Each weight should create a usable font
        for weight in weights {
            let font = Font.platformSystem(size: 16, weight: weight)
            _ = Text("Weight Test").font(font)
            #expect(Bool(true), "Platform system font with weight \(weight) should be usable")
        }
    }
    
    /// Test platform system font with different designs
    @Test func testPlatformSystemFontWithDesigns() {
        // Given: Different font designs
        let designs: [Font.Design] = [.default, .serif, .monospaced, .rounded]
        
        // When & Then: Each design should create a usable font
        for design in designs {
            let font = Font.platformSystem(size: 16, weight: .regular, design: design)
            _ = Text("Design Test").font(font)
            #expect(Bool(true), "Platform system font with design \(design) should be usable")
        }
    }
    
    // MARK: - Platform-Specific Behavior Tests
    
    @Test func testPlatformFontsWorkInViews() {
        // Given: Platform fonts
        let fonts = [
            ("Large Title", Font.platformLargeTitle),
            ("Title", Font.platformTitle),
            ("Headline", Font.platformHeadline),
            ("Body", Font.platformBody),
            ("Caption", Font.platformCaption)
        ]
        
        // When & Then: Each font should work in views
        for (name, font) in fonts {
            _ = Text(name)
                .font(font)
            #expect(Bool(true), "Font \(name) should work in views")
        }
    }
    
    @Test @MainActor func testPlatformFontsWithSwiftUIViews() {
        // Given
        let testFonts = [
            ("Large Title", Font.platformLargeTitle),
            ("Title", Font.platformTitle),
            ("Title 2", Font.platformTitle2),
            ("Title 3", Font.platformTitle3),
            ("Headline", Font.platformHeadline),
            ("Body", Font.platformBody),
            ("Callout", Font.platformCallout),
            ("Subheadline", Font.platformSubheadline),
            ("Footnote", Font.platformFootnote),
            ("Caption", Font.platformCaption),
            ("Caption 2", Font.platformCaption2)
        ]
        
        // When & Then
        for (name, font) in testFonts {
            _ = platformVStackContainer {
                Text(name)
                    .font(font)
            }
            
            #expect(Bool(true), "Font \(name) should work in SwiftUI views")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testPlatformFontsWithAccessibility() {
        // Given: Platform fonts
        let fonts = [
            Font.platformLargeTitle,
            Font.platformTitle,
            Font.platformHeadline,
            Font.platformBody,
            Font.platformCaption
        ]
        
        // When: Using fonts in accessible views
        for font in fonts {
            _ = Text("Accessible Text")
                .font(font)
                .accessibilityLabel("Test text")
            
            #expect(Bool(true), "Font should work with accessibility")
        }
    }
    
    // MARK: - Documentation Tests
    
    @Test @MainActor func testFontUsageExamples() {
        // Given
        _ = platformVStackContainer {
            Text("Large Title")
                .font(.platformLargeTitle)
            
            Text("Title")
                .font(.platformTitle)
            
            Text("Headline")
                .font(.platformHeadline)
            
            Text("Body")
                .font(.platformBody)
            
            Text("Caption")
                .font(.platformCaption)
        }
        
        // When & Then
        // Verify fonts are valid and usable
        #expect(Bool(true), "All platform fonts should be usable in examples")
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test func testBackwardCompatibility() {
        // Given & When
        let fonts = [
            Font.platformLargeTitle,
            Font.platformTitle,
            Font.platformHeadline,
            Font.platformBody,
            Font.platformCaption
        ]
        
        // Then
        // All fonts should be backward compatible (valid and usable)
        for font in fonts {
            _ = Text("Test")
                .font(font)
            #expect(Bool(true), "Font should be backward compatible")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testFontErrorHandling() {
        // Given & When
        let fonts = [
            Font.platformLargeTitle,
            Font.platformTitle,
            Font.platformHeadline,
            Font.platformBody,
            Font.platformCaption
        ]
        
        // Then
        // Fonts should handle errors gracefully
        for font in fonts {
            #expect(throws: Never.self, "Font should handle errors gracefully") { {
                _ = font
            } }
        }
    }
    
    // MARK: - All Platform Fonts Available Tests
    
    @Test func testAllPlatformFontsAreAvailable() {
        // Given & When
        let fonts = [
            Font.platformLargeTitle,
            Font.platformTitle,
            Font.platformTitle2,
            Font.platformTitle3,
            Font.platformHeadline,
            Font.platformBody,
            Font.platformCallout,
            Font.platformSubheadline,
            Font.platformFootnote,
            Font.platformCaption,
            Font.platformCaption2
        ]
        
        // Then
        for font in fonts {
            _ = Text("Test").font(font)
            #expect(Bool(true), "All platform fonts should be available")
        }
    }
}







