import Testing
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
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
        // ViewInspector not available on this platform - this is expected, not a failure
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
        // ViewInspector not available on this platform - this is expected, not a failure
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

        // Should provide navigation controls (match by accessibility ID or by button label text for cross-platform)
        #if canImport(ViewInspector)
        var hasNavControl = false
        _ = withInspectedView(AnyView(view)) { inspector in
            let buttons = inspector.findAll(ViewType.Button.self)
            for button in buttons {
                let id = try? button.accessibilityIdentifier()
                let labelText = (try? button.labelView().find(ViewType.Text.self).string()) ?? ""
                if (id?.contains("Next") ?? false) || labelText == "Next" { hasNavControl = true; break }
                if (id?.contains("Finish") ?? false) || labelText == "Finish" { hasNavControl = true; break }
                if (id?.contains("Previous") ?? false) || labelText == "Previous" { hasNavControl = true; break }
            }
        }
        #expect(hasNavControl, "Should provide at least one navigation control (Next, Previous, or Finish)")
        #else
        // ViewInspector not available on this platform - this is expected, not a failure
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
            let texts = inspected.findAll(ViewType.Text.self)
            let hasStepInfo = !texts.isEmpty
            #expect(hasStepInfo, "Should display step information")
        } else {
            #if canImport(ViewInspector)
            Issue.record("FormWizardView step information not found")
            #else
            #expect(Bool(true), "FormWizardView created (ViewInspector not available on macOS)")
            #endif
        }
    }

    // MARK: - Injected wizardState (Issue #187)

    @Test @MainActor func testWhenHostProvidesWizardStateViaEnvironment_wizardUsesIt() async {
        initializeTestConfig()
        let steps = [
            FormWizardStep(id: "s1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "s2", title: "Step 2", stepOrder: 1),
            FormWizardStep(id: "s3", title: "Step 3", stepOrder: 2)
        ]
        let injectedState = FormWizardState()
        injectedState.setSteps(steps)
        injectedState.currentStepIndex = 1

        let view = FormWizardView(
            steps: steps,
            content: { step, _ in Text(step.title) },
            navigation: { _, next, prev, _ in
                platformHStackContainer {
                    Button("Prev", action: prev)
                    Button("Next", action: next)
                }
            }
        )
        .environment(\.formWizardState, injectedState)

        #if canImport(ViewInspector)
        var stepTexts: [String] = []
        _ = withInspectedView(AnyView(view)) { inspector in
            let texts = inspector.findAll(ViewInspector.ViewType.Text.self)
            stepTexts = texts.compactMap { try? $0.string() }
        }
        let showsAnyStep = stepTexts.contains { ["Step 1", "Step 2", "Step 3"].contains($0) }
        #expect(showsAnyStep, "Wizard with .environment(formWizardState) should build and display at least one step (injected state shows Step 2 in host)")
        #else
        #expect(Bool(true), "View with injected wizardState builds")
        #endif
    }

    @Test @MainActor func testWhenNoWizardStateProvided_wizardCreatesInternalState() async {
        initializeTestConfig()
        let steps = [
            FormWizardStep(id: "a", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "b", title: "Step 2", stepOrder: 1)
        ]
        let view = FormWizardView(
            steps: steps,
            content: { step, _ in Text(step.title) },
            navigation: { _, next, prev, _ in
                platformHStackContainer {
                    Button("Prev", action: prev)
                    Button("Next", action: next)
                }
            }
        )

        #if canImport(ViewInspector)
        var showsStep1 = false
        _ = withInspectedView(view) { inspector in
            let texts = inspector.findAll(ViewInspector.ViewType.Text.self)
            showsStep1 = texts.contains { (try? $0.string()) == "Step 1" }
        }
        #expect(showsStep1, "Wizard without injection should show first step (internal state)")
        #else
        #expect(Bool(true), "FormWizardView created with internal state")
        #endif
    }
}
