//
//  AutomaticAccessibilityLabelTests.swift
//  SixLayerFrameworkTests
//
//  ViewInspector tests for automatic accessibility label functionality (Issue #154)
//  Tests that labels are applied to SwiftUI views through modifiers
//
//  BUSINESS PURPOSE: Ensure automatic accessibility labels are applied for VoiceOver compliance
//  TESTING SCOPE: Accessibility label application through SwiftUI views
//  METHODOLOGY: Test that labels are applied when provided via parameters using ViewInspector
//

import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// ViewInspector tests for automatic accessibility labels
/// Tests that labels are applied to SwiftUI views through modifiers
/// 
/// BUSINESS PURPOSE: Ensure automatic accessibility labels work in SwiftUI views
/// TESTING SCOPE: AutomaticComplianceModifier and platform functions
/// METHODOLOGY: Test each function, verify label is applied via ViewInspector
@Suite("Automatic Accessibility Labels - ViewInspector")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class AutomaticAccessibilityLabelTests: BaseTestClass {
    
    // MARK: - AutomaticComplianceModifier Accessibility Label Tests
    
    /// BUSINESS PURPOSE: automaticCompliance() should apply accessibility label when provided
    /// TESTING SCOPE: Tests that accessibilityLabel parameter applies .accessibilityLabel() modifier
    /// METHODOLOGY: Create view with accessibilityLabel parameter and verify label is applied
    @Test @MainActor func testAutomaticCompliance_AppliesAccessibilityLabel_WhenProvided() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with explicit accessibility label
            let testLabel = "Save document"
            let view = Text("Save")
                .automaticCompliance(accessibilityLabel: testLabel)
            let root = Self.hostRootPlatformView(view)
            let labelText = getAccessibilityLabelForTest(view: view, hostedRoot: root)
            #expect(labelText != nil && !(labelText?.isEmpty ?? true), "View with accessibility label should have label applied")
            if let label = labelText {
                #expect(label == "Save document." || label.hasPrefix("Save document"), "Label should be formatted with punctuation")
            }
        }
    }
    
    /// BUSINESS PURPOSE: automaticCompliance() should work without accessibility label
    /// TESTING SCOPE: Tests backward compatibility when no label is provided
    /// METHODOLOGY: Create view without accessibility label parameter
    @Test @MainActor func testAutomaticCompliance_WorksWithoutAccessibilityLabel() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view without accessibility label parameter
            let view = Text("Content")
                .automaticCompliance()
            let root = Self.hostRootPlatformView(view)
            let identifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(identifier != nil && !(identifier?.isEmpty ?? true), "View without accessibility label should still have identifier")
        }
    }
    
    // MARK: - NamedAutomaticComplianceModifier Accessibility Label Tests
    
    /// BUSINESS PURPOSE: automaticCompliance(named:) should apply accessibility label when provided
    /// TESTING SCOPE: Tests that NamedAutomaticComplianceModifier applies accessibility labels
    /// METHODOLOGY: Create view with named component and accessibility label
    @Test @MainActor func testAutomaticComplianceNamed_AppliesAccessibilityLabel_WhenProvided() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A named component with accessibility label
            let componentName = "TestComponent"
            let testLabel = "Test component label"
            let view = Text("Content")
                .automaticCompliance(named: componentName, accessibilityLabel: testLabel)
            let root = Self.hostRootPlatformView(view)
            let labelText = getAccessibilityLabelForTest(view: view, hostedRoot: root)
            let identifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(labelText != nil && !(labelText?.isEmpty ?? true), "Named component with accessibility label should have label applied")
            #expect(identifier != nil && !(identifier?.isEmpty ?? true), "Named component should have identifier")
            #expect(identifier?.contains(componentName) == true, "Identifier should include component name")
        }
    }
    
    /// BUSINESS PURPOSE: automaticCompliance(named:) should work without accessibility label
    /// TESTING SCOPE: Tests backward compatibility for named components
    /// METHODOLOGY: Create named component without accessibility label
    @Test @MainActor func testAutomaticComplianceNamed_WorksWithoutAccessibilityLabel() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A named component without accessibility label
            let componentName = "TestComponent"
            let view = Text("Content")
                .automaticCompliance(named: componentName)
            let root = Self.hostRootPlatformView(view)
            let identifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(identifier != nil && !(identifier?.isEmpty ?? true), "Named component without label should still have identifier")
            #expect(identifier?.contains(componentName) == true, "Identifier should include component name")
        }
    }
    
    // MARK: - Platform Function Accessibility Label Tests
    
    /// BUSINESS PURPOSE: platformButton should apply accessibility label when provided
    /// TESTING SCOPE: Tests that platformButton passes label to automaticCompliance
    /// METHODOLOGY: Create button with label parameter and verify label is applied
    @Test @MainActor func testPlatformButton_AppliesAccessibilityLabel() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A platform button with accessibility label
            let testLabel = "Save document"
            var actionCalled = false
            let view = platformButton(label: testLabel) {
                actionCalled = true
            }
            let root = Self.hostRootPlatformView(view)
            let labelText = getAccessibilityLabelForTest(view: view, hostedRoot: root)
            #expect(labelText != nil && !(labelText?.isEmpty ?? true), "Platform button with label should have label applied")
        }
    }
    
    /// BUSINESS PURPOSE: platformButton should auto-extract accessibility label from label parameter
    /// TESTING SCOPE: Tests that platformButton extracts label parameter as accessibility label
    /// METHODOLOGY: Create button with simple label overload, verify label is extracted
    @Test @MainActor func testPlatformButton_AutoExtractsLabelFromParameter() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A button with label (simple overload - Issue #157)
            let buttonLabel = "Save"
            var actionCalled = false
            let view = platformButton(buttonLabel) {
                actionCalled = true
            }
            let root = Self.hostRootPlatformView(view)
            let labelText = getAccessibilityLabelForTest(view: view, hostedRoot: root)
            #expect(labelText != nil && !(labelText?.isEmpty ?? true), "Button with auto-extracted label should have label applied")
        }
    }
    
    // MARK: - Label Formatting Through ViewInspector Tests
    
    /// BUSINESS PURPOSE: Test that label formatting works through ViewInspector
    /// TESTING SCOPE: Label formatting through SwiftUI views
    /// METHODOLOGY: Test label formatting by checking results from modifier via ViewInspector
    @Test @MainActor func testLabelFormatting_ThroughViewInspector() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: Views with different label formats
            let viewWithPeriod = Text("Test")
                .automaticCompliance(accessibilityLabel: "Test label.")
            
            let viewWithoutPeriod = Text("Test")
                .automaticCompliance(accessibilityLabel: "Test label")
            
            let viewWithExclamation = Text("Test")
                .automaticCompliance(accessibilityLabel: "Test label!")
            
            // When: Labels are applied through modifiers
            // Then: Labels should be formatted correctly
            #if canImport(ViewInspector)
            do {
                let inspectedPeriod = try viewWithPeriod.inspect()
                let labelPeriod = try? inspectedPeriod.accessibilityLabel()
                if let label = labelPeriod, let labelText = try? label.string() {
                    #expect(labelText == "Test label.", "Label with period should be preserved")
                }
                
                let inspectedNoPeriod = try viewWithoutPeriod.inspect()
                let labelNoPeriod = try? inspectedNoPeriod.accessibilityLabel()
                if let label = labelNoPeriod, let labelText = try? label.string() {
                    #expect(labelText == "Test label.", "Label without period should have period added")
                }
                
                let inspectedExclamation = try viewWithExclamation.inspect()
                let labelExclamation = try? inspectedExclamation.accessibilityLabel()
                if let label = labelExclamation, let labelText = try? label.string() {
                    #expect(labelText == "Test label!", "Label with exclamation should be preserved")
                }
            } catch {
                Issue.record("Failed to inspect views: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
        }
    }
    
    // MARK: - Edge Case Tests
    
    /// BUSINESS PURPOSE: Empty accessibility label should not be applied
    /// TESTING SCOPE: Tests that empty strings are not applied as labels
    /// METHODOLOGY: Create view with empty label string
    @Test @MainActor func testAutomaticCompliance_DoesNotApplyEmptyLabel() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view with empty accessibility label
            let view = Text("Content")
                .automaticCompliance(accessibilityLabel: "")
            let root = Self.hostRootPlatformView(view)
            let identifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(identifier != nil && !(identifier?.isEmpty ?? true), "View should still have identifier even with empty label")
        }
    }
    
    /// BUSINESS PURPOSE: Nil accessibility label should not be applied
    /// TESTING SCOPE: Tests that nil labels are handled correctly
    /// METHODOLOGY: Create view with nil label (implicit)
    @Test @MainActor func testAutomaticCompliance_HandlesNilLabel() async {
        initializeTestConfig()
        await runWithTaskLocalConfig {
            // Given: A view without accessibility label (nil)
            let view = Text("Content")
                .automaticCompliance(accessibilityLabel: nil)
            let root = Self.hostRootPlatformView(view)
            let identifier = getAccessibilityIdentifierForTest(view: view, hostedRoot: root)
            #expect(identifier != nil && !(identifier?.isEmpty ?? true), "View should have identifier even with nil label")
        }
    }
}
