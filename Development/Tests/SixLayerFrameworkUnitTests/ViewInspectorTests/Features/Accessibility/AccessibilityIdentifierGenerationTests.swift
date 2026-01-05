import Testing
import SwiftUI
@testable import SixLayerFramework
/// TDD Tests for Accessibility Identifier Generation
/// Following proper TDD: Test drives design, write best code to make tests pass
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Identifier Generation")
open class AccessibilityIdentifierGenerationTests: BaseTestClass {
    
    // MARK: - TDD Red Phase: Write Failing Tests for Desired Behavior
    
    @Test @MainActor func testAccessibilityIdentifiersAreReasonableLength() {
            initializeTestConfig()
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Define the behavior I want - short, clean IDs
        let view = PlatformInteractionButton(style: .primary, action: {}) {
            platformPresentContent_L1(content: "Add Fuel", hints: PresentationHints())
        }
            .named("AddFuelButton")
            .enableGlobalAutomaticCompliance()
        
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let inspectedView = view.tryInspect(),
           let buttonID = try? inspectedView.accessibilityIdentifier() {
            // This test SHOULD FAIL initially - IDs are currently 400+ chars
            #expect(buttonID.count < 80, "Accessibility ID should be reasonable length")
            #expect(buttonID.contains("SixLayer"), "Should contain namespace")
            #expect(buttonID.contains("AddFuelButton"), "Should contain view name")
            
        } else {
            Issue.record("Failed to inspect view")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test @MainActor func testAccessibilityIdentifiersDontDuplicateHierarchy() {
            initializeTestConfig()
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Define the behavior I want - no hierarchy duplication
        let view = platformVStackContainer {
            PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Test", hints: PresentationHints())
            }
            .named("TestButton")
        }
        .named("Container")
        .named("OuterContainer") // Multiple .named() calls
        .enableGlobalAutomaticCompliance()
        
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let inspectedView = view.tryInspect(),
           let vStackID = try? inspectedView.accessibilityIdentifier() {
            // This test SHOULD FAIL initially - contains duplicates like "container-container"
            #expect(!vStackID.contains("container-container"), "Should not contain duplicated hierarchy")
            #expect(!vStackID.contains("outercontainer-outercontainer"), "Should not contain duplicated hierarchy")
            #expect(vStackID.count < 80, "Should be reasonable length even with multiple .named() calls")
            
        } else {
            Issue.record("Failed to inspect view")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test @MainActor func testAccessibilityIdentifiersAreSemantic() {
            initializeTestConfig()
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Define the behavior I want - semantic, meaningful IDs
        let view = platformVStackContainer {
            platformPresentContent_L1(content: "User Profile", hints: PresentationHints())
                .named("ProfileTitle")
            PlatformInteractionButton(style: .primary, action: {}) {
                platformPresentContent_L1(content: "Edit", hints: PresentationHints())
            }
                .named("EditButton")
        }
        .named("UserProfile")
        .named("ProfileView")
        .enableGlobalAutomaticCompliance()
        
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let inspectedView = view.tryInspect(),
           let vStackID = try? inspectedView.accessibilityIdentifier() {
            // This test SHOULD FAIL initially - IDs are not semantic
            #expect(vStackID.contains("UserProfile"), "Should contain screen context")
            #expect(vStackID.contains("ProfileView") || vStackID.contains("UserProfile"), "Should contain view name")
            #expect(vStackID.count < 80, "Should be concise and semantic")
            
        } else {
            Issue.record("Failed to inspect view")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test @MainActor func testAccessibilityIdentifiersWorkInComplexHierarchy() {
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Define the behavior I want - works in complex nested views
        let view = platformVStackContainer {
            platformHStackContainer {
                Text("Title")
                    .named("TitleText")
                Button("Action") { }
                    .named("ActionButton")
            }
            .named("HeaderRow")
            
            platformVStackContainer {
                ForEach(0..<3) { index in
                    Text("Item \(index)")
                        .named("Item\(index)")
                }
            }
            .named("ItemList")
        }
        .named("ComplexView")
        .named("ComplexContainer")
        .enableGlobalAutomaticCompliance()
        
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        if let inspectedView = view.tryInspect(),
           let vStackID = try? inspectedView.accessibilityIdentifier() {
            // This test SHOULD FAIL initially - complex hierarchies create massive IDs
            #expect(vStackID.count < 100, "Should handle complex hierarchies gracefully")
            #expect(vStackID.contains("ComplexView"), "Should contain screen context")
            #expect(vStackID.contains("ComplexContainer") || vStackID.contains("ComplexView"), "Should contain container name")
            #expect(!vStackID.contains("item0-item1-item2"), "Should not contain all nested item names")
            
        } else {
            Issue.record("Failed to inspect view")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    // MARK: - TDD Red Phase: Label Text in Identifiers
    
    @Test @MainActor func testAccessibilityIdentifiersIncludeLabelTextForStringLabels() {
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Define the behavior I want - labels from String parameters should be in identifiers
        // This test SHOULD FAIL initially - labels are not included in identifiers
        let submitButton = AdaptiveUIPatterns.AdaptiveButton("Submit", action: { })
            .enableGlobalAutomaticCompliance()
        
        let cancelButton = AdaptiveUIPatterns.AdaptiveButton("Cancel", action: { })
            .enableGlobalAutomaticCompliance()
        
        #if canImport(ViewInspector)
        if let submitInspected = submitButton.tryInspect(),
           let cancelInspected = cancelButton.tryInspect() {
            let submitID = try? submitInspected.accessibilityIdentifier()
            let cancelID = try? cancelInspected.accessibilityIdentifier()
            
            // TDD RED: These should FAIL - labels not currently included
            #expect((submitID?.contains("Submit") ?? false), "Submit button identifier should include 'Submit' label")
            #expect((cancelID?.contains("Cancel") ?? false), "Cancel button identifier should include 'Cancel' label")
            #expect(submitID != cancelID, "Buttons with different labels should have different identifiers")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
    
    @Test @MainActor func testAccessibilityIdentifiersSanitizeLabelText() {
        // Setup test environment
        setupTestEnvironment()
        
        // TDD: Labels should be sanitized (lowercase, spaces to hyphens, etc.)
        let button = AdaptiveUIPatterns.AdaptiveButton("Add New Item", action: { })
            .enableGlobalAutomaticCompliance()
        
        #if canImport(ViewInspector)
        if let inspected = button.tryInspect() {
            let buttonID = try? inspected.accessibilityIdentifier()
            
            // TDD RED: Should FAIL - labels not sanitized
            // Should contain sanitized version: "add-new-item" or similar
            #expect((buttonID?.contains("add") ?? false) || (buttonID?.contains("new") ?? false) || (buttonID?.contains("item") ?? false), 
                   "Identifier should include sanitized label text")
            #expect(!(buttonID?.contains("Add New Item") ?? false), 
                   "Identifier should not contain raw label with spaces")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // Cleanup
        cleanupTestEnvironment()
    }
}
