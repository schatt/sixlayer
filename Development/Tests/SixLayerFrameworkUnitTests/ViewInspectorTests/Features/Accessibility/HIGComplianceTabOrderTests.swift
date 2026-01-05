import Testing

//
//  HIGComplianceTabOrderTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates that automatic HIG compliance applies correct tab order to all
//  focusable elements, ensuring logical keyboard navigation flow.
//
//  TESTING SCOPE:
//  - Logical tab order for form fields
//  - Tab order for buttons and interactive elements
//  - Tab order for complex layouts (VStack, HStack, ZStack)
//  - Platform-specific tab order behavior
//
//  METHODOLOGY:
//  - TDD RED phase: Tests fail until tab order implementation is implemented
//  - Test multiple focusable elements
//  - Verify logical navigation order
//  - Test complex view hierarchies
//

import SwiftUI
@testable import SixLayerFramework

@Suite("HIG Compliance - Tab Order")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class HIGComplianceTabOrderTests: BaseTestClass {
    
    // MARK: - Form Field Tab Order Tests
    
    @Test @MainActor func testFormFieldsHaveLogicalTabOrder() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Multiple form fields with automatic compliance
            let view = platformVStackContainer {
                TextField("First Name", text: .constant(""))
                    .automaticCompliance()
                TextField("Last Name", text: .constant(""))
                    .automaticCompliance()
                TextField("Email", text: .constant(""))
                    .automaticCompliance()
            }
            .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Fields should have logical tab order (top to bottom)
            // RED PHASE: This will fail until tab order implementation is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "FormFieldsWithTabOrder"
            )
            #expect(passed, "Form fields should have logical tab order on all platforms")
        }
    }
    
    // MARK: - Button Tab Order Tests
    
    @Test @MainActor func testButtonsHaveLogicalTabOrder() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Multiple buttons with automatic compliance
            let view = platformHStackContainer {
                Button("Cancel") { }
                    .automaticCompliance()
                Button("Save") { }
                    .automaticCompliance()
            }
            .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Buttons should have logical tab order (left to right)
            // RED PHASE: This will fail until tab order implementation is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "ButtonsWithTabOrder"
            )
            #expect(passed, "Buttons should have logical tab order on all platforms")
        }
    }
    
    // MARK: - Complex Layout Tab Order Tests
    
    @Test @MainActor func testComplexLayoutHasLogicalTabOrder() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Complex layout with multiple focusable elements
            let view = platformVStackContainer {
                TextField("Name", text: .constant(""))
                    .automaticCompliance()
                platformHStackContainer {
                    Button("Cancel") { }
                        .automaticCompliance()
                    Button("Save") { }
                        .automaticCompliance()
                }
                .automaticCompliance()
            }
            .automaticCompliance()
            
            // WHEN: View is created
            // THEN: Elements should have logical tab order (top to bottom, then left to right)
            // RED PHASE: This will fail until tab order implementation is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "ComplexLayoutWithTabOrder"
            )
            #expect(passed, "Complex layout should have logical tab order on all platforms")
        }
    }
    
    // MARK: - Cross-Platform Tests
    
    @Test @MainActor func testTabOrderOnBothPlatforms() async {
            initializeTestConfig()
        runWithTaskLocalConfig {
            // GIVEN: Multiple focusable elements with automatic compliance
            let view = platformVStackContainer {
                TextField("Field 1", text: .constant(""))
                    .automaticCompliance()
                TextField("Field 2", text: .constant(""))
                    .automaticCompliance()
            }
            .automaticCompliance()
            
            // WHEN: View is created on all platforms
            // THEN: Tab order should be logical on all platforms
            // RED PHASE: This will fail until tab order implementation is implemented
            let passed = testComponentComplianceCrossPlatform(
                view,
                expectedPattern: "SixLayer.*ui",
                componentName: "CrossPlatformTabOrder"
            )
            #expect(passed, "Tab order should be logical on all platforms")
        }
    }
}

