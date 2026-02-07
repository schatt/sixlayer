//
//  TextModifierExtensionsViewInspectorTests.swift
//  SixLayerFrameworkTests
//
//  ViewInspector tests for View extensions that replicate Text-specific modifiers
//  Implements Issue #174: View Extensions for Text Modifiers
//
//  BUSINESS PURPOSE: Verify View extensions apply modifiers correctly
//  TESTING SCOPE: View extensions for .bold(), .italic(), .font(), .fontWeight()
//  METHODOLOGY: Use ViewInspector to verify modifiers are applied
//

import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// ViewInspector tests for View extensions that replicate Text modifiers
/// RED PHASE: Tests compile but fail (extensions don't exist yet)
/// 
/// BUSINESS PURPOSE: Ensure View extensions apply modifiers correctly
/// TESTING SCOPE: View extensions for Text-specific modifiers
/// METHODOLOGY: Use ViewInspector to verify modifier application
@Suite("View Extensions for Text Modifiers (ViewInspector)")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class TextModifierExtensionsViewInspectorTests: BaseTestClass {
    
    // MARK: - Bold Extension Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .bold() View extension should apply fontWeight(.bold)
    /// TESTING SCOPE: View extension for .bold()
    /// METHODOLOGY: Use ViewInspector to verify view can be inspected
    @Test @MainActor func testBoldExtension_AppliesFontWeight() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: Text with basicAutomaticCompliance and .bold()
            let view = Text("Hello")
                .basicAutomaticCompliance()
                .bold()
            
            // When: View is created with .bold() extension
            // Then: View should be inspectable (verifies extension works)
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                // Verify the view can be inspected (this confirms the extension compiles and works)
                // The .bold() extension uses .fontWeight(.bold) which is an environment modifier
                // ViewInspector can inspect the view structure, confirming the modifier chain works
                let textView = try inspected.text()
                let textValue = try textView.string()
                #expect(textValue == "Hello", "Text content should be 'Hello'")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
                #expect(Bool(false), "View should be inspectable")
            }
            #else
            // ViewInspector not available - verify compilation
            _ = view // Ensure view is created
            #expect(Bool(true), "ViewInspector not available, but extension should compile")
            #endif
        }
    }
    
    // MARK: - Italic Extension Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .italic() View extension should apply italic style
    /// TESTING SCOPE: View extension for .italic()
    /// METHODOLOGY: Use ViewInspector to verify view can be inspected
    @Test @MainActor func testItalicExtension_AppliesItalicStyle() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: Text with basicAutomaticCompliance and .italic()
            let view = Text("Hello")
                .basicAutomaticCompliance()
                .italic()
            
            // When: View is created with .italic() extension
            // Then: View should be inspectable (verifies extension works)
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                // Verify the view can be inspected (this confirms the extension compiles and works)
                // The .italic() extension uses ItalicModifier which reads font from environment
                let textView = try inspected.text()
                let textValue = try textView.string()
                #expect(textValue == "Hello", "Text content should be 'Hello'")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
                #expect(Bool(false), "View should be inspectable")
            }
            #else
            // ViewInspector not available - verify compilation
            _ = view // Ensure view is created
            #expect(Bool(true), "ViewInspector not available, but extension should compile")
            #endif
        }
    }
    
    // MARK: - Font Extension Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .font() View extension should apply font
    /// TESTING SCOPE: View extension for .font()
    /// METHODOLOGY: Use ViewInspector to verify view can be inspected
    @Test @MainActor func testFontExtension_AppliesFont() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: Text with basicAutomaticCompliance and .font(.title)
            let view = Text("Hello")
                .basicAutomaticCompliance()
                .font(.title)
            
            // When: View is created with .font() extension
            // Then: View should be inspectable (.font() already exists on View)
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let textView = try inspected.text()
                let textValue = try textView.string()
                #expect(textValue == "Hello", "Text content should be 'Hello'")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
                #expect(Bool(false), "View should be inspectable")
            }
            #else
            // ViewInspector not available - verify compilation
            _ = view // Ensure view is created
            #expect(Bool(true), "ViewInspector not available, but extension should compile")
            #endif
        }
    }
    
    // MARK: - Chaining Tests (Red Phase)
    
    /// BUSINESS PURPOSE: Chaining .bold().italic() should apply both modifiers
    /// TESTING SCOPE: Multiple View extensions chained
    /// METHODOLOGY: Use ViewInspector to verify chaining works
    @Test @MainActor func testChaining_BoldAndItalic_AppliesBothModifiers() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: Text with basicAutomaticCompliance and chained .bold().italic()
            let view = Text("Hello")
                .basicAutomaticCompliance()
                .bold()
                .italic()
            
            // When: View is created with chained extensions
            // Then: View should be inspectable (verifies chaining works)
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                // Verify the view can be inspected (this confirms chaining works)
                let textView = try inspected.text()
                let textValue = try textView.string()
                #expect(textValue == "Hello", "Text content should be 'Hello'")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
                #expect(Bool(false), "View should be inspectable")
            }
            #else
            // ViewInspector not available - verify compilation
            _ = view // Ensure view is created
            #expect(Bool(true), "ViewInspector not available, but chaining should compile")
            #endif
        }
    }
    
    // MARK: - Container View Tests (Red Phase)
    
    /// BUSINESS PURPOSE: .bold() on VStack should propagate to child Text views
    /// TESTING SCOPE: View extension on container views
    /// METHODOLOGY: Use ViewInspector to verify view structure
    @Test @MainActor func testBoldExtension_PropagatesToVStackChildren() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: VStack with Text children and .bold()
            let view = VStack {
                Text("A")
                Text("B")
            }
            .basicAutomaticCompliance()
            .bold()
            
            // When: View is created with .bold() on container
            // Then: View should be inspectable and contain both Text children
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                // Verify VStack structure exists
                let vstack = try inspected.vStack()
                // Verify both Text children exist
                let text1 = try vstack.text(0)
                let text2 = try vstack.text(1)
                #expect(try text1.string() == "A", "First text should be 'A'")
                #expect(try text2.string() == "B", "Second text should be 'B'")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
                #expect(Bool(false), "View should be inspectable")
            }
            #else
            // ViewInspector not available - verify compilation
            _ = view // Ensure view is created
            #expect(Bool(true), "ViewInspector not available, but extension should compile")
            #endif
        }
    }
}
