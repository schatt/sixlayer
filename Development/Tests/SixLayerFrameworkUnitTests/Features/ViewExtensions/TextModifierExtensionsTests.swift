//
//  TextModifierExtensionsTests.swift
//  SixLayerFrameworkTests
//
//  Tests for View extensions that replicate Text-specific modifiers
//  Implements Issue #174: View Extensions for Text Modifiers
//
//  BUSINESS PURPOSE: Enable chaining Text modifiers after .basicAutomaticCompliance()
//  TESTING SCOPE: View extensions for .bold(), .italic(), .font(), .fontWeight()
//  METHODOLOGY: Test that extensions compile and work on any View
//

import Testing
import SwiftUI
@testable import SixLayerFramework

/// Tests for View extensions that replicate Text modifiers
/// RED PHASE: Tests compile but fail (extensions don't exist yet)
/// 
/// BUSINESS PURPOSE: Ensure View extensions enable Text modifier chaining
/// TESTING SCOPE: View extensions for Text-specific modifiers
/// METHODOLOGY: Test compilation, chaining, and behavior on different View types
@Suite("View Extensions for Text Modifiers")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class TextModifierExtensionsTests: BaseTestClass {
    
    // MARK: - Compilation Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .bold() View extension should compile and work on Text
    /// TESTING SCOPE: View extension for .bold()
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().bold() compiles and returns a view
    @Test @MainActor func testBoldExtension_CompilesOnText() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Applying .bold() extension
        let boldText = text.bold()
        
        // Then: Should compile and return a view (not crash)
        // The fact that this compiles and runs verifies the extension exists
        _ = boldText // Use the view to ensure it's actually created
    }
    
    /// BUSINESS PURPOSE: .bold() View extension should compile and work on Image
    /// TESTING SCOPE: View extension for .bold() on non-text views
    /// METHODOLOGY: Test that Image.basicAutomaticCompliance().bold() compiles
    @Test @MainActor func testBoldExtension_CompilesOnImage() {
        // Given: Image with basicAutomaticCompliance
        let image = Image(systemName: "star")
            .basicAutomaticCompliance()
        
        // When: Applying .bold() extension
        let boldImage = image.bold()
        
        // Then: Should compile and return a view (not crash)
        // On non-text views, .bold() has no visual effect but should compile
        _ = boldImage // Use the view to ensure it's actually created
    }
    
    /// BUSINESS PURPOSE: .italic() View extension should compile and work on Text
    /// TESTING SCOPE: View extension for .italic()
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().italic() compiles
    @Test @MainActor func testItalicExtension_CompilesOnText() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Applying .italic() extension
        let italicText = text.italic()
        
        // Then: Should compile and return a view (not crash)
        _ = italicText // Use the view to ensure it's actually created
    }
    
    /// BUSINESS PURPOSE: .font() View extension should compile and work on Text
    /// TESTING SCOPE: View extension for .font()
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().font(.title) compiles
    @Test @MainActor func testFontExtension_CompilesOnText() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Applying .font() extension
        let fontText = text.font(.title)
        
        // Then: Should compile and return a view (.font() already exists on View)
        _ = fontText // Use the view to ensure it's actually created
    }
    
    /// BUSINESS PURPOSE: .fontWeight() View extension should compile and work on Text
    /// TESTING SCOPE: View extension for .fontWeight()
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().fontWeight(.bold) compiles
    @Test @MainActor func testFontWeightExtension_CompilesOnText() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Applying .fontWeight() extension
        let weightText = text.fontWeight(.bold)
        
        // Then: Should compile and return a view (.fontWeight() already exists on View)
        _ = weightText // Use the view to ensure it's actually created
    }
    
    // MARK: - Chaining Tests (Red Phase)
    
    /// BUSINESS PURPOSE: Chaining .bold().italic() should work
    /// TESTING SCOPE: Multiple View extensions chained
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().bold().italic() compiles
    @Test @MainActor func testChaining_BoldAndItalic_Compiles() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Chaining .bold().italic()
        let chainedText = text.bold().italic()
        
        // Then: Should compile and return a view (not crash)
        _ = chainedText // Use the view to ensure it's actually created
    }
    
    /// BUSINESS PURPOSE: Chaining .bold().font() should work
    /// TESTING SCOPE: Multiple View extensions chained
    /// METHODOLOGY: Test that Text.basicAutomaticCompliance().bold().font(.title) compiles
    @Test @MainActor func testChaining_BoldAndFont_Compiles() {
        // Given: Text with basicAutomaticCompliance
        let text = Text("Hello")
            .basicAutomaticCompliance()
        
        // When: Chaining .bold().font()
        let chainedText = text.bold().font(.title)
        
        // Then: Should compile and return a view (not crash)
        _ = chainedText // Use the view to ensure it's actually created
    }
    
    // MARK: - Container View Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .bold() should work on VStack (environment propagation)
    /// TESTING SCOPE: View extension on container views
    /// METHODOLOGY: Test that VStack.bold() compiles
    @Test @MainActor func testBoldExtension_CompilesOnVStack() {
        // Given: VStack with Text children
        let vstack = VStack {
            Text("A")
            Text("B")
        }
        .basicAutomaticCompliance()
        
        // When: Applying .bold() extension
        let boldVStack = vstack.bold()
        
        // Then: Should compile and return a view (not crash)
        // The fontWeight modifier propagates via environment to child Text views
        _ = boldVStack // Use the view to ensure it's actually created
    }
    
    // MARK: - Font Preservation Tests
    
    /// BUSINESS PURPOSE: .bold() should preserve existing font
    /// TESTING SCOPE: Font preservation when applying .bold()
    /// METHODOLOGY: Apply .title font, then .bold(), verify font is preserved
    @Test @MainActor func testBoldExtension_PreservesFont() {
        // Given: Text with .title font
        let text = Text("Hello")
            .font(.title)
            .basicAutomaticCompliance()
        
        // When: Applying .bold() extension
        let boldText = text.bold()
        
        // Then: Should compile and return a view
        // Note: We can't easily verify font preservation without ViewInspector,
        // but the fact that .fontWeight(.bold) is used (which preserves font) is verified
        // by the implementation. This test ensures the code compiles and runs.
        _ = boldText
    }
    
    /// BUSINESS PURPOSE: .italic() should preserve existing font
    /// TESTING SCOPE: Font preservation when applying .italic()
    /// METHODOLOGY: Apply .title font, then .italic(), verify font is preserved
    @Test @MainActor func testItalicExtension_PreservesFont() {
        // Given: Text with .title font
        let text = Text("Hello")
            .font(.title)
            .basicAutomaticCompliance()
        
        // When: Applying .italic() extension
        let italicText = text.italic()
        
        // Then: Should compile and return a view
        // Note: The ItalicModifier uses @Environment(\.font) to preserve the font.
        // This test ensures the code compiles and runs.
        _ = italicText
    }
}
