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
        runWithTaskLocalConfig {
            setupTestEnvironment()
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "AddFuelButton") {
                platformPresentContent_L1(content: "Add Fuel", hints: PresentationHints())
            }
            .named("AddFuelButton")
            .enableGlobalAutomaticCompliance()
            let root = Self.hostRootPlatformView(view)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(buttonID != nil && !(buttonID?.isEmpty ?? true), "Should have an accessibility identifier")
            if let id = buttonID {
                #expect(id.count < 120, "Accessibility ID should be reasonable length")
                #expect(id.contains("SixLayer") || id.contains("addfuelbutton") || id.contains("AddFuelButton"), "Should contain namespace or view name")
            }
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testAccessibilityIdentifiersDontDuplicateHierarchy() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            let view = platformVStackContainer {
                PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                    platformPresentContent_L1(content: "Test", hints: PresentationHints())
                }
                .named("TestButton")
            }
            .named("Container")
            .named("OuterContainer")
            .enableGlobalAutomaticCompliance()
            let root = Self.hostRootPlatformView(view)
            let vStackID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(vStackID != nil && !(vStackID?.isEmpty ?? true), "Should have an identifier")
            if let id = vStackID {
                #expect(id.count < 120, "Should be reasonable length even with multiple .named() calls")
            }
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testAccessibilityIdentifiersAreSemantic() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            let view = platformVStackContainer {
                platformPresentContent_L1(content: "User Profile", hints: PresentationHints())
                    .named("ProfileTitle")
                PlatformInteractionButton(style: .primary, action: {}, identifierName: "EditButton") {
                    platformPresentContent_L1(content: "Edit", hints: PresentationHints())
                }
                .named("EditButton")
            }
            .named("UserProfile")
            .named("ProfileView")
            .enableGlobalAutomaticCompliance()
            let root = Self.hostRootPlatformView(view)
            let vStackID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(vStackID != nil && !(vStackID?.isEmpty ?? true), "Should have an identifier")
            if let id = vStackID {
                #expect(id.contains("UserProfile") || id.contains("ProfileView") || id.contains("editbutton") || id.contains("EditButton"), "Should contain semantic context")
                #expect(id.count < 120, "Should be concise and semantic")
            }
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testAccessibilityIdentifiersWorkInComplexHierarchy() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
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
            let root = Self.hostRootPlatformView(view)
            let vStackID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(vStackID != nil && !(vStackID?.isEmpty ?? true), "Should have an identifier")
            if let id = vStackID {
                #expect(id.count < 150, "Should handle complex hierarchies gracefully")
            }
            cleanupTestEnvironment()
        }
    }
    
    // MARK: - TDD Red Phase: Label Text in Identifiers
    
    @Test @MainActor func testAccessibilityIdentifiersIncludeLabelTextForStringLabels() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            // Labels from String parameters should be in identifiers (Issue #175)
            let submitButton = AdaptiveUIPatterns.AdaptiveButton("Submit", action: { })
                .enableGlobalAutomaticCompliance()
            let cancelButton = AdaptiveUIPatterns.AdaptiveButton("Cancel", action: { })
                .enableGlobalAutomaticCompliance()
            let submitRoot = Self.hostRootPlatformView(submitButton)
            let cancelRoot = Self.hostRootPlatformView(cancelButton)
            let submitID = getAccessibilityIdentifierForTest(view: submitButton, hostedRoot: submitRoot)
            let cancelID = getAccessibilityIdentifierForTest(view: cancelButton, hostedRoot: cancelRoot)
            #expect((submitID?.contains("submit") ?? false) || (submitID?.contains("Submit") ?? false), "Submit button identifier should include 'Submit' label")
            #expect((cancelID?.contains("cancel") ?? false) || (cancelID?.contains("Cancel") ?? false), "Cancel button identifier should include 'Cancel' label")
            #expect(submitID != cancelID, "Buttons with different labels should have different identifiers")
            cleanupTestEnvironment()
        }
    }
    
    @Test @MainActor func testAccessibilityIdentifiersSanitizeLabelText() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            // Labels should be sanitized (lowercase, spaces to hyphens) in identifier
            let button = AdaptiveUIPatterns.AdaptiveButton("Add New Item", action: { })
                .enableGlobalAutomaticCompliance()
            let root = Self.hostRootPlatformView(button)
            let buttonID = getAccessibilityIdentifierForTest(view: button, hostedRoot: root)
            #expect((buttonID?.contains("add") ?? false) || (buttonID?.contains("new") ?? false) || (buttonID?.contains("item") ?? false),
                   "Identifier should include sanitized label text")
            #expect(!(buttonID?.contains("Add New Item") ?? false),
                   "Identifier should not contain raw label with spaces")
            cleanupTestEnvironment()
        }
    }
}
