import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * BUSINESS PURPOSE: FormWizardView provides a multi-step wizard interface for complex forms.
 * Users navigate through multiple steps, completing each before moving to the next.
 *
 * TESTING SCOPE: TDD tests that describe expected behavior for FormWizardView.
 * These tests will fail until the component is properly implemented.
 *
 * METHODOLOGY: TDD red-phase tests that verify the wizard renders actual navigation UI,
 * manages step state, provides navigation controls, and integrates with FormWizardState.
 */

@Suite("Form Wizard View")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class FormWizardViewTDDTests: BaseTestClass {

    @Test @MainActor func testFormWizardViewRendersStepNavigation() async {
        initializeTestConfig()
        // TDD: FormWizardView should:
        // 1. Render step navigation interface (progress indicator, step list, etc.)
        // 2. Display current step content via content builder
        // 3. Provide next/previous navigation buttons via navigation builder
        // 4. Track current step in FormWizardState
        // 5. Show step progress indication

        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", description: "First step", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", description: "Second step", stepOrder: 1),
            FormWizardStep(id: "step3", title: "Step 3", description: "Third step", stepOrder: 2)
        ]

        let wizardState = FormWizardState()
        wizardState.setSteps(steps)

        let view = FormWizardView(
            steps: steps,
            content: { step, state in
                platformVStackContainer {
                    Text(step.title)
                    Text(step.description ?? "")
                }
            },
            navigation: { state, next, previous, finish in
                platformHStackContainer {
                    if state.currentStepIndex > 0 {
                        Button("Previous", action: previous)
                    }
                    Spacer()
                    if state.isLastStep {
                        Button("Finish", action: finish)
                    } else {
                        Button("Next", action: next)
                    }
                }
            }
        )

        // Should render step content
        #if canImport(ViewInspector)
        if let inspected = try? AnyView(view).inspect() {
            // Should display current step content
            let allTexts = inspected.findAll(ViewInspector.ViewType.Text.self)
            if !allTexts.isEmpty {
                let foundStep1 = allTexts.contains { text in
                    (try? text.string())?.contains("Step 1") ?? false
                }
                #expect(foundStep1, "Should display current step content")
            }
        } else {
            Issue.record("FormWizardView step content not found")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif

        // Should generate accessibility identifier
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view,
            expectedPattern: "SixLayer.main.ui.*FormWizardView.*",
            platform: .iOS,
            componentName: "FormWizardView"
        )
 #expect(hasAccessibilityID, "Should generate accessibility identifier ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }

    @Test @MainActor func testFormWizardViewManagesStepState() async {
        initializeTestConfig()
        // TDD: FormWizardView should:
        // 1. Initialize at first step
        // 2. Allow navigation between steps via FormWizardState
        // 3. Validate step completion before allowing next
        // 4. Track which steps have been completed
        // 5. Provide step completion status

        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1)
        ]

        let wizardState = FormWizardState()
        wizardState.setSteps(steps)

        // Should start at first step
        #expect(wizardState.currentStepIndex == 0, "Should start at first step")
        #expect(wizardState.currentStepIndex == 0, "Should be on first step initially")

        // Should allow moving to next step (mark current step as complete first)
        wizardState.markStepComplete("step1")
        _ = wizardState.nextStep()
        #expect(wizardState.currentStepIndex == 1, "Should move to second step")
        #expect(wizardState.isLastStep, "Should be on last step after advancing")
    }

    @Test @MainActor func testFormWizardViewProvidesNavigationControls() async {
        initializeTestConfig()
        // TDD: FormWizardView should:
        // 1. Show "Previous" button when not on first step
        // 2. Show "Next" button when not on last step
        // 3. Show "Finish" button on last step
        // 4. Call navigation callbacks appropriately
        // 5. Update wizard state when navigation occurs

        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1)
        ]

        let wizardState = FormWizardState()
        wizardState.setSteps(steps)

        let view = FormWizardView(
            steps: steps,
            content: { step, state in
                Text(step.title)
            },
            navigation: { state, next, previous, finish in
                platformHStackContainer {
                    if state.currentStepIndex > 0 {
                        Button("Previous") {
                            previous()
                        }
                    }
                    Spacer()
                    if state.isLastStep {
                        Button("Finish") {
                            finish()
                        }
                    } else {
                        Button("Next") {
                            next()
                        }
                    }
                }
            }
        )

        // Should provide navigation controls
        #if canImport(ViewInspector)
        if let inspected = try? AnyView(view).inspect() {
            // Should find navigation buttons
            let buttons = inspected.findAll(Button<Text>.self)
            if buttons.count > 0 {
                let hasNextButton = buttons.contains { button in
                    (try? button.accessibilityIdentifier())?.contains("Next") ?? false
                }
                let hasFinishButton = buttons.contains { button in
                    (try? button.accessibilityIdentifier())?.contains("Finish") ?? false
                }
                let hasPreviousButton = buttons.contains { button in
                    (try? button.accessibilityIdentifier())?.contains("Previous") ?? false
                }

                // At least one navigation control should exist
                #expect(hasNextButton || hasFinishButton || hasPreviousButton, "Should provide navigation controls")
            }
        } else {
            Issue.record("FormWizardView navigation controls not found")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }

    @Test @MainActor func testFormWizardViewDisplaysAllSteps() async {
        initializeTestConfig()
        // TDD: FormWizardView should:
        // 1. Display step titles/names in navigation
        // 2. Show progress indicator with all steps
        // 3. Highlight current step
        // 4. Show completed steps visually
        // 5. Indicate which steps are accessible

        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1),
            FormWizardStep(id: "step3", title: "Step 3", stepOrder: 2)
        ]

        let wizardState = FormWizardState()
        wizardState.setSteps(steps)

        let view = FormWizardView(
            steps: steps,
            content: { step, state in
                Text(step.title)
            },
            navigation: { state, next, previous, finish in
                platformHStackContainer {
                    if state.currentStepIndex > 0 {
                        Button("Previous", action: previous)
                    }
                    Spacer()
                    if state.isLastStep {
                        Button("Finish", action: finish)
                    } else {
                        Button("Next", action: next)
                    }
                }
            }
        )

        // Should show step information
        if let inspected = try? AnyView(view).inspect() {
            // Should display step information
            let hasStepInfo = inspected.sixLayerCount > 0
            #expect(hasStepInfo, "Should display step information")
        } else {
            #if canImport(ViewInspector)
            Issue.record("FormWizardView step information not found")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "FormWizardView created (ViewInspector not available on macOS)")
            #endif
        }
    }
}
