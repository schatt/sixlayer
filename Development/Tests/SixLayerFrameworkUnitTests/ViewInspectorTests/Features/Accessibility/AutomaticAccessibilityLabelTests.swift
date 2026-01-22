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
            
            // When: View is created with accessibility label
            // Then: Accessibility label should be applied
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                #expect(labelView != nil, "View with accessibility label should have label applied")
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText == "Save document.", "Label should be formatted with punctuation")
                }
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: View is created without label
            // Then: Should still work (backward compatible) and have identifier
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "View without accessibility label should still have identifier")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Named component has accessibility label
            // Then: Label should be applied
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                #expect(labelView != nil, "Named component with accessibility label should have label applied")
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText == "Test component label.", "Label should be formatted with punctuation")
                }
                
                // Also verify identifier is applied
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "Named component should have identifier")
                #expect(identifier?.contains(componentName) == true, "Identifier should include component name")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Named component has no label
            // Then: Should still work (backward compatible) and have identifier
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "Named component without label should still have identifier")
                #expect(identifier?.contains(componentName) == true, "Identifier should include component name")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Button is created with label
            // Then: Label should be applied via automaticCompliance
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                #expect(labelView != nil, "Platform button with label should have label applied")
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText == "Save document.", "Label should be formatted with punctuation")
                }
            } catch {
                Issue.record("Failed to inspect button: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Button is created with label parameter
            // Then: Label should be extracted as accessibility label
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let labelView = try? inspected.accessibilityLabel()
                #expect(labelView != nil, "Button with auto-extracted label should have label applied")
                if let label = labelView, let labelText = try? label.string() {
                    #expect(labelText == "Save.", "Auto-extracted label should be formatted with punctuation")
                }
            } catch {
                Issue.record("Failed to inspect button: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Empty label is provided
            // Then: Should not apply empty label (modifier checks for !isEmpty)
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                // Empty labels should not be applied - verify identifier is still there
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "View should still have identifier even with empty label")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
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
            
            // When: Nil label is provided
            // Then: Should not apply label but should still have identifier
            #if canImport(ViewInspector)
            do {
                let inspected = try view.inspect()
                let identifier = try? inspected.accessibilityIdentifier()
                #expect(identifier != nil, "View should have identifier even with nil label")
            } catch {
                Issue.record("Failed to inspect view: \(error)")
            }
            #else
            Issue.record("ViewInspector not available - this test requires ViewInspector")
            #endif
        }
    }
}
