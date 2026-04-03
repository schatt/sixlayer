import Testing


import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

// Using ViewInspectorWrapper for cross-platform compatibility
/// Edge case tests for accessibility identifier generation bug fix
/// These tests ensure our fix handles all edge cases properly
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Accessibility Identifier Edge Case")
open class AccessibilityIdentifierEdgeCaseTests: BaseTestClass {
    /// Hosting can evaluate modifiers outside the test task, leaving isolated debug logs empty; ViewInspector reads the SwiftUI modifier chain.
    @MainActor
    private func accessibilityIdentifierForButtonViaViewInspector<V: View>(_ view: V) -> String? {
        #if canImport(ViewInspector)
        guard let inspected = try? AnyView(view).inspect() else { return nil }
        if let id = try? inspected.button().accessibilityIdentifier(), !id.isEmpty {
            return id
        }
        for button in inspected.findAll(ViewInspector.ViewType.Button.self) {
            if let id = try? button.accessibilityIdentifier(), !id.isEmpty {
                return id
            }
        }
        #endif
        return nil
    }
    
    // MARK: - Edge Case 1: Empty String Parameters
    
    @Test @MainActor func testEmptyStringParameters() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test") {
                Text("Test")
            }
            .named("")  // ← Empty string
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID even with empty parameters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
        }
    }
    
    // MARK: - Edge Case 2: Special Characters in Names
    
    @Test @MainActor func testSpecialCharactersInNames() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are special characters handled in names?
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "ButtonSpecials") {
                Text("Test")
            }
            .named("Button@#$%^&*()")  // ← Special characters
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with special characters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
                #expect(id.contains("Button") || id.contains("@#$%^&*()"), "Should contain name or special characters")
            }
        }
    }
    
    // MARK: - Edge Case 3: Very Long Names
    
    @Test @MainActor func testVeryLongNames() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does it handle extremely long names gracefully?
            let longName = String(repeating: "VeryLongName", count: 50)  // 600+ chars
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "LongName") {
                Text("Test")
            }
            .named(longName)
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with very long names")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
            
            // Warn if extremely long (but don't fail the test)
            if let id = buttonID, id.count > 200 {
                print("⚠️ WARNING: Generated extremely long accessibility ID (\(id.count) chars)")
                print("   Consider using shorter, more semantic names for better debugging experience")
                print("   ID: '\(id)'")
            }
        }
    }
    
    // MARK: - Edge Case 4: Manual ID Override
    
    @Test @MainActor func testManualIDOverride() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Manual accessibilityIdentifier on a hosted control (no inner automaticCompliance).
            // UIView traversal often misses plain Button ids here; ViewInspector matches other accessibility tests in this target.
            let view = Button("Test") { }
                .accessibilityIdentifier("manual-override")
            
            _ = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            #if canImport(ViewInspector)
            let id = accessibilityIdentifierForButtonViaViewInspector(view)
            guard id == "manual-override" else {
                Issue.record("Inspection unavailable: expected manual-override, got \(String(describing: id))")
                return
            }
            #expect(id == "manual-override")
            #else
            Issue.record("ViewInspector required for manual Button accessibilityIdentifier assertion")
            #endif
        }
    }
    
    // MARK: - Edge Case 5: Disable/Enable Mid-Hierarchy
    
    @Test @MainActor func testDisableEnableMidHierarchy() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does disable work mid-hierarchy?
            let view = platformVStackContainer {
                Button("Auto") { }
                    .named("AutoButton")
                    .enableGlobalAutomaticCompliance()
                
                Button("Manual") { }
                    .named("ManualButton")
                    .disableAutomaticAccessibilityIdentifiers()  // ← Disable mid-hierarchy
            }
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let anyID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            if anyID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = anyID {
                #expect(!id.isEmpty, "Auto-enabled button should produce an accessibility identifier")
            }
        }
    }
    
    // MARK: - Edge Case 6: Multiple Screen Contexts
    
    @Test @MainActor func testMultipleScreenContexts() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            let view = platformVStackContainer {
                Text("Content")
            }
            .named("TestView")
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let vStackID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if vStackID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = vStackID {
                #expect(!id.isEmpty, "Should generate ID with multiple contexts")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
        }
    }
    
    // MARK: - Edge Case 7: Exact Named Behavior (Red Phase Tests)
    
    @Test @MainActor func testExactNamedBehavior() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: Does exactNamed() use exact names without hierarchy?
            let view1 = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test1") {
                Text("Test1")
            }
            .exactNamed("SameName")
            .enableGlobalAutomaticCompliance()
            
            let view2 = PlatformInteractionButton(style: .primary, action: {}, identifierName: "Test2") {
                Text("Test2")
            }
            .exactNamed("SameName")  // ← Same exact name
            .enableGlobalAutomaticCompliance()
            
            _ = Self.hostRootPlatformView(view1, forceLayout: true, exposeContentAccessibility: true)
            let id1 = accessibilityIdentifierForButtonViaViewInspector(view1)
            _ = Self.hostRootPlatformView(view2, forceLayout: true, exposeContentAccessibility: true)
            let id2 = accessibilityIdentifierForButtonViaViewInspector(view2)
            
            #if canImport(ViewInspector)
            if id1 == nil || id2 == nil {
                Issue.record("Inspection unavailable: could not read exactNamed identifier via ViewInspector")
            }
            if let i1 = id1 { #expect(i1 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(i1)'") }
            if let i2 = id2 { #expect(i2 == "SameName", "exactNamed() should produce exact identifier 'SameName', got '\(i2)'") }
            #else
            Issue.record("ViewInspector required for exactNamed PlatformInteractionButton assertion")
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedVsNamedDifference() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should produce different identifiers than named()
            let exactView = Button("Test") { }
                .exactNamed("TestButton")
                .enableGlobalAutomaticCompliance()
            
            let namedView = Button("Test") { }
                .named("TestButton")
                .enableGlobalAutomaticCompliance()
            
            _ = Self.hostRootPlatformView(exactView, forceLayout: true, exposeContentAccessibility: true)
            let exactID = accessibilityIdentifierForButtonViaViewInspector(exactView)
            _ = Self.hostRootPlatformView(namedView, forceLayout: true, exposeContentAccessibility: true)
            let namedID = accessibilityIdentifierForButtonViaViewInspector(namedView)
            
            #if canImport(ViewInspector)
            if exactID == nil || namedID == nil {
                Issue.record("Inspection unavailable: could not read identifiers via ViewInspector")
            }
            if let e = exactID, let n = namedID {
                #expect(e != n, "exactNamed() should produce different identifiers than named()")
                #expect(e.contains("TestButton") || e == "TestButton", "exactNamed() should contain the exact name")
                #expect(n.contains("TestButton"), "named() should contain the name")
                #expect(e == "TestButton", "exactNamed() should produce exact identifier 'TestButton', got '\(e)'")
            }
            #else
            Issue.record("ViewInspector required for exactNamed vs named comparison")
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedIgnoresHierarchy() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should ignore view hierarchy context
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.pushViewHierarchy("NavigationView")
            config.pushViewHierarchy("ProfileSection")
            config.setScreenContext("UserProfile")
            
            let exactView = Button("Test") { }
                .exactNamed("SaveButton")
                .enableGlobalAutomaticCompliance()
            
            _ = Self.hostRootPlatformView(exactView, forceLayout: true, exposeContentAccessibility: true)
            let exactID = accessibilityIdentifierForButtonViaViewInspector(exactView)
            
            #if canImport(ViewInspector)
            if exactID == nil {
                Issue.record("Inspection unavailable: could not read exactNamed identifier via ViewInspector")
            }
            if let id = exactID {
                #expect(id == "SaveButton", "exactNamed() should produce exact identifier 'SaveButton', got '\(id)'")
            }
            #else
            Issue.record("ViewInspector required for exactNamed hierarchy assertion")
            #endif
        }
    }
    
    @Test @MainActor func testExactNamedMinimalIdentifier() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: exactNamed() should produce minimal identifiers
            let exactView = Button("Test") { }
                .exactNamed("MinimalButton")
                .enableGlobalAutomaticCompliance()
            
            _ = Self.hostRootPlatformView(exactView, forceLayout: true, exposeContentAccessibility: true)
            let exactID = accessibilityIdentifierForButtonViaViewInspector(exactView)
            
            #if canImport(ViewInspector)
            if exactID == nil {
                Issue.record("Inspection unavailable: could not read exactNamed identifier via ViewInspector")
            }
            let expectedMinimalPattern = "MinimalButton"
            if let id = exactID {
                #expect(id == expectedMinimalPattern, "exactNamed() should produce exact identifier '\(expectedMinimalPattern)', got '\(id)'")
            }
            #else
            Issue.record("ViewInspector required for exactNamed minimal identifier assertion")
            #endif
        }
    }
    
    // MARK: - Edge Case 8: Configuration Changes Mid-Test
    
    @Test @MainActor func testConfigurationChangesMidTest() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: What happens if configuration changes during view creation?
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "TestButton") {
                Text("Test")
            }
            .named("TestButton")
            .enableGlobalAutomaticCompliance()
            
            // Change configuration after view creation
            config.namespace = "ChangedNamespace"
            config.mode = .semantic
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with changed config")
            }
        }
    }
    
    // MARK: - Edge Case 9: Nested .named() Calls
    
    @Test @MainActor func testNestedNamedCalls() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: What happens with deeply nested .named() calls?
            let view = platformVStackContainer {
                platformHStackContainer {
                    Button("Content") { }
                        .named("DeepNested")
                        .enableGlobalAutomaticCompliance()
                }
                .named("Nested")
            }
            .named("Outer")
            .named("VeryOuter")  // ← Multiple .named() calls
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with nested .named() calls")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
        }
    }
    
    // MARK: - Edge Case 10: Unicode Characters
    
    @Test @MainActor func testUnicodeCharacters() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            setupTestEnvironment()
            
            // Test: How are Unicode characters handled?
            let view = PlatformInteractionButton(style: .primary, action: {}, identifierName: "UnicodeButton") {
                Text("Test")
            }
            .named("按钮")  // ← Chinese characters
            .enableGlobalAutomaticCompliance()
            
            let root = Self.hostRootPlatformView(view, forceLayout: true, exposeContentAccessibility: true)
            let buttonID = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            
            if buttonID == nil {
                Issue.record("Inspection unavailable: could not obtain accessibility identifier")
            }
            if let id = buttonID {
                #expect(!id.isEmpty, "Should generate ID with Unicode characters")
                #expect(id.contains("SixLayer"), "Should contain namespace")
            }
        }
    }
}
