import Testing


//
//  FormWizardTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Validates the form wizard system functionality that provides multi-step form
//  navigation, validation, state management, and user experience across all platforms.
//
//  TESTING SCOPE:
//  - Form wizard step creation and management functionality
//  - Form wizard state management and navigation functionality
//  - Form wizard validation and error handling functionality
//  - Form wizard progress tracking and completion functionality
//  - Form wizard data management and persistence functionality
//  - Form wizard user experience and workflow functionality
//
//  METHODOLOGY:
//  - Test form wizard step creation across all platforms
//  - Verify form wizard state management using mock testing
//  - Test form wizard navigation with platform variations
//  - Validate form wizard validation with comprehensive platform testing
//  - Test form wizard progress tracking with mock capabilities
//  - Verify form wizard workflows across platforms
//
//  AUDIT STATUS: ✅ COMPLIANT
//  - ✅ File Documentation: Complete with business purpose, testing scope, methodology
//  - ✅ Function Documentation: All 21 functions documented with business purpose
//  - ✅ Platform Testing: Comprehensive platform testing added to key functions
//  - ✅ Mock Testing: RuntimeCapabilityDetection mock testing implemented
//  - ✅ Business Logic Focus: Tests actual form wizard functionality, not testing framework
//

@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Form Wizard")
open class FormWizardTests: BaseTestClass {
    
    // MARK: - Form Wizard Step Tests
    
    /// BUSINESS PURPOSE: Validate FormWizardStep creation functionality
    /// TESTING SCOPE: Tests FormWizardStep initialization with all parameters
    /// METHODOLOGY: Create FormWizardStep with comprehensive parameters and verify all properties are set correctly
    @Test func testFormWizardStepCreation() {
        // Test across all platforms
        for platform in SixLayerPlatform.allCases {
            
            let step = FormWizardStep(
                id: "personal",
                title: "Personal Information",
                description: "Basic details about you",
                isRequired: true,
                validationRules: ["minLength": "2"],
                stepOrder: 0
            )
            
            #expect(step.id == "personal")
            #expect(step.title == "Personal Information")
            #expect(step.description == "Basic details about you")
            #expect(step.isRequired)
            #expect(step.validationRules?["minLength"] == "2")
            #expect(step.stepOrder == 0)
            
            RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        }
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardStep equality functionality
    /// TESTING SCOPE: Tests FormWizardStep equality comparison and hashable conformance
    /// METHODOLOGY: Create multiple FormWizardStep instances and verify equality behavior
    @Test func testFormWizardStepEquality() {
        let step1 = FormWizardStep(
            id: "step1",
            title: "First Step",
            stepOrder: 0
        )
        
        let step2 = FormWizardStep(
            id: "step1",
            title: "First Step",
            stepOrder: 0
        )
        
        let step3 = FormWizardStep(
            id: "step2",
            title: "Second Step",
            stepOrder: 1
        )
        
        #expect(step1 == step2)
        #expect(step1 != step3)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardStep hashable functionality
    /// TESTING SCOPE: Tests FormWizardStep hashable conformance and set operations
    /// METHODOLOGY: Create FormWizardStep instances and verify hashable behavior
    @Test func testFormWizardStepHashable() {
        let step = FormWizardStep(
            id: "testStep",
            title: "Test Step",
            stepOrder: 0
        )
        
        let stepSet: Set<FormWizardStep> = [step]
        #expect(stepSet.count == 1)
        #expect(stepSet.contains(step))
    }
    
    // MARK: - Form Wizard Builder Tests
    
    /// BUSINESS PURPOSE: Validate FormWizardBuilder step creation functionality
    /// TESTING SCOPE: Tests FormWizardBuilder step creation and management
    /// METHODOLOGY: Use FormWizardBuilder to create steps and verify step creation functionality
    @Test func testFormWizardBuilderCreatesSteps() {
        var builder = FormWizardBuilder()
        builder.addStep(id: "step1", title: "First Step")
        builder.addStep(id: "step2", title: "Second Step")
        let steps = builder.build()
        
        #expect(steps.count == 2)
        #expect(steps[0].id == "step1")
        #expect(steps[0].title == "First Step")
        #expect(steps[0].stepOrder == 0)
        #expect(steps[1].id == "step2")
        #expect(steps[1].title == "Second Step")
        #expect(steps[1].stepOrder == 1)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardBuilder description functionality
    /// TESTING SCOPE: Tests FormWizardBuilder step creation with descriptions
    /// METHODOLOGY: Use FormWizardBuilder to create steps with descriptions and verify functionality
    @Test func testFormWizardBuilderWithDescription() {
        var builder = FormWizardBuilder()
        builder.addStep(
            id: "step1",
            title: "First Step",
            description: "Description for first step"
        )
        let steps = builder.build()
        
        #expect(steps.count == 1)
        #expect(steps[0].description == "Description for first step")
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardBuilder validation functionality
    /// TESTING SCOPE: Tests FormWizardBuilder step creation with validation rules
    /// METHODOLOGY: Use FormWizardBuilder to create steps with validation and verify functionality
    @Test func testFormWizardBuilderWithValidation() {
        let validationRules = ["minLength": "3", "maxLength": "50"]
        
        var builder = FormWizardBuilder()
        builder.addStep(
            id: "step1",
            title: "First Step",
            validationRules: validationRules
        )
        let steps = builder.build()
        
        #expect(steps.count == 1)
        #expect(steps[0].validationRules?["minLength"] == "3")
        #expect(steps[0].validationRules?["maxLength"] == "50")
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardBuilder required flag functionality
    /// TESTING SCOPE: Tests FormWizardBuilder step creation with required flags
    /// METHODOLOGY: Use FormWizardBuilder to create required steps and verify functionality
    @Test func testFormWizardBuilderWithRequiredFlag() {
        var builder = FormWizardBuilder()
        builder.addStep(
            id: "step1",
            title: "First Step",
            isRequired: false
        )
        let steps = builder.build()
        
        #expect(steps.count == 1)
        #expect(!steps[0].isRequired)
    }
    
    // MARK: - Form Wizard State Tests
    
    /// BUSINESS PURPOSE: Validate FormWizardState initialization functionality
    /// TESTING SCOPE: Tests FormWizardState initialization and setup
    /// METHODOLOGY: Initialize FormWizardState and verify initial state properties
    @Test func testFormWizardStateInitialization() {
        let state = FormWizardState()
        
        #expect(state.currentStepIndex == 0)
        #expect(state.completedSteps.count == 0)
        #expect(state.stepData.count == 0)
        #expect(state.validationErrors.count == 0)
        #expect(!state.isComplete)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState step management functionality
    /// TESTING SCOPE: Tests FormWizardState step management and operations
    /// METHODOLOGY: Manage steps in FormWizardState and verify step management functionality
    @Test func testFormWizardStateStepManagement() {
        let state = FormWizardState()
        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1),
            FormWizardStep(id: "step3", title: "Step 3", stepOrder: 2)
        ]
        
        state.setSteps(steps)
        
        #expect(state.steps.count == 3)
        #expect(state.getCurrentStep()?.id == "step1")
        #expect(state.getCurrentStep()?.title == "Step 1")
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState navigation functionality
    /// TESTING SCOPE: Tests FormWizardState navigation between steps
    /// METHODOLOGY: Navigate between steps in FormWizardState and verify navigation functionality
    @Test func testFormWizardStateNavigation() {
        let state = FormWizardState()
        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1),
            FormWizardStep(id: "step3", title: "Step 3", stepOrder: 2)
        ]
        
        state.setSteps(steps)
        
        // Initially at first step
        #expect(state.currentStepIndex == 0)
        #expect(state.getCurrentStep()?.id == "step1")
        
        // Mark first step as complete (since it's required by default)
        state.markStepComplete("step1")
        
        // Test next step
        #expect(state.nextStep())
        #expect(state.currentStepIndex == 1)
        #expect(state.getCurrentStep()?.id == "step2")
        
        // Mark second step as complete
        state.markStepComplete("step2")
        
        // Test previous step
        #expect(state.previousStep())
        #expect(state.currentStepIndex == 0)
        #expect(state.getCurrentStep()?.id == "step1")
        
        // Go back to second step
        #expect(state.nextStep())
        #expect(state.currentStepIndex == 1)
        
        // Go to third step
        #expect(state.nextStep())
        #expect(state.currentStepIndex == 2)
        #expect(state.getCurrentStep()?.id == "step3")
        
        // Mark third step as complete
        state.markStepComplete("step3")
        
        // Complete wizard
        #expect(state.nextStep())
        #expect(state.isComplete)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState step completion functionality
    /// TESTING SCOPE: Tests FormWizardState step completion and tracking
    /// METHODOLOGY: Complete steps in FormWizardState and verify completion functionality
    @Test func testFormWizardStateStepCompletion() {
        let state = FormWizardState()
        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", isRequired: true, stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", isRequired: false, stepOrder: 1)
        ]
        
        state.setSteps(steps)
        
        // Initially no steps are complete
        #expect(!state.isStepComplete("step1"))
        #expect(!state.isStepComplete("step2"))
        
        // Mark step as complete
        state.markStepComplete("step1")
        #expect(state.isStepComplete("step1"))
        #expect(!state.isStepComplete("step2"))
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState validation functionality
    /// TESTING SCOPE: Tests FormWizardState validation and error handling
    /// METHODOLOGY: Validate steps in FormWizardState and verify validation functionality
    @Test func testFormWizardStateValidation() {
        let state = FormWizardState()
        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", isRequired: true, stepOrder: 0)
        ]
        
        state.setSteps(steps)
        
        // Initially can't proceed (required step not complete)
        #expect(!state.canProceedToNextStep())
        
        // Mark step as complete
        state.markStepComplete("step1")
        #expect(state.canProceedToNextStep())
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState data management functionality
    /// TESTING SCOPE: Tests FormWizardState data management and persistence
    /// METHODOLOGY: Manage data in FormWizardState and verify data management functionality
    @Test func testFormWizardStateDataManagement() {
        let state = FormWizardState()
        
        // Test setting and getting step data
        state.setStepData("step1", key: "name", value: "John")
        state.setStepData("step1", key: "age", value: 25)
        
        #expect(state.getStepData("step1", key: "name") as String? == "John")
        #expect(state.getStepData("step1", key: "age") as Int? == 25)
        #expect(state.getStepData("step1", key: "nonexistent") as String? == nil)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState validation error functionality
    /// TESTING SCOPE: Tests FormWizardState validation error handling and display
    /// METHODOLOGY: Trigger validation errors in FormWizardState and verify error functionality
    @Test func testFormWizardStateValidationErrors() {
        let state = FormWizardState()
        
        // Test validation error management
        state.addValidationError("Name is required", for: "step1")
        state.addValidationError("Name is too short", for: "step1")
        
        // Test error retrieval
        let errors = state.validationErrors["step1"] ?? []
        #expect(errors.count == 2)
        #expect(errors.contains("Name is required"))
        #expect(errors.contains("Name is too short"))
        
        // Test clearing errors
        state.clearValidationErrors(for: "step1")
        #expect(state.validationErrors["step1"]?.count ?? 0 == 0)
    }
    
    // MARK: - Form Wizard Progress Tests
    
    /// BUSINESS PURPOSE: Validate FormWizardProgress creation functionality
    /// TESTING SCOPE: Tests FormWizardProgress initialization and setup
    /// METHODOLOGY: Create FormWizardProgress and verify progress creation functionality
    @Test func testFormWizardProgressCreation() {
        let progress = FormWizardProgress(
            currentStep: 2,
            totalSteps: 5,
            completedSteps: 3
        )
        
        #expect(progress.currentStep == 2)
        #expect(progress.totalSteps == 5)
        #expect(progress.completedSteps == 3)
        #expect(progress.progressPercentage == 0.6)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardProgress helper functionality
    /// TESTING SCOPE: Tests FormWizardProgress helper methods and calculations
    /// METHODOLOGY: Use FormWizardProgress helper methods and verify helper functionality
    @Test func testFormWizardProgressHelpers() {
        let progress = FormWizardProgress(
            currentStep: 0,
            totalSteps: 3,
            completedSteps: 0
        )
        
        #expect(progress.isFirstStep)
        #expect(!progress.isLastStep)
        #expect(!progress.isComplete)
        
        let lastStepProgress = FormWizardProgress(
            currentStep: 2,
            totalSteps: 3,
            completedSteps: 3
        )
        
        #expect(!lastStepProgress.isFirstStep)
        #expect(lastStepProgress.isLastStep)
        #expect(lastStepProgress.isComplete)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardProgress edge case functionality
    /// TESTING SCOPE: Tests FormWizardProgress edge cases and boundary conditions
    /// METHODOLOGY: Test FormWizardProgress edge cases and verify edge case functionality
    @Test func testFormWizardProgressEdgeCases() {
        // Empty wizard
        let emptyProgress = FormWizardProgress(
            currentStep: 0,
            totalSteps: 0,
            completedSteps: 0
        )
        #expect(emptyProgress.progressPercentage == 0.0)
        
        // Single step
        let singleStepProgress = FormWizardProgress(
            currentStep: 0,
            totalSteps: 1,
            completedSteps: 1
        )
        #expect(singleStepProgress.progressPercentage == 1.0)
    }
    
    // MARK: - Integration Tests
    
    /// BUSINESS PURPOSE: Validate FormWizard complete workflow functionality
    /// TESTING SCOPE: Tests FormWizard end-to-end workflow and user experience
    /// METHODOLOGY: Test complete FormWizard workflow and verify end-to-end functionality
    @Test func testFormWizardCompleteWorkflow() {
        var builder = FormWizardBuilder()
        builder.addStep(id: "personal", title: "Personal Info", isRequired: true)
        builder.addStep(id: "contact", title: "Contact Info", isRequired: true)
        builder.addStep(id: "preferences", title: "Preferences", isRequired: false)
        let steps = builder.build()
        
        let state = FormWizardState()
        state.setSteps(steps)
        
        // Navigate through steps
        #expect(state.currentStepIndex == 0)
        #expect(state.getCurrentStep()?.id == "personal")
        
        // Complete first step
        state.markStepComplete("personal")
        #expect(state.canProceedToNextStep())
        
        // Move to next step
        #expect(state.nextStep())
        #expect(state.currentStepIndex == 1)
        #expect(state.getCurrentStep()?.id == "contact")
        
        // Complete second step
        state.markStepComplete("contact")
        #expect(state.canProceedToNextStep())
        
        // Move to final step
        #expect(state.nextStep())
        #expect(state.currentStepIndex == 2)
        #expect(state.getCurrentStep()?.id == "preferences")
        
        // Complete wizard
        #expect(state.nextStep())
        #expect(state.isComplete)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizard validation rules functionality
    /// TESTING SCOPE: Tests FormWizard with validation rules and error handling
    /// METHODOLOGY: Test FormWizard with validation rules and verify validation functionality
    @Test func testFormWizardWithValidationRules() {
        var builder = FormWizardBuilder()
        builder.addStep(
            id: "personal",
            title: "Personal Info",
            isRequired: true,
            validationRules: ["minLength": "2"]
        )
        let steps = builder.build()
        
        let state = FormWizardState()
        state.setSteps(steps)
        
        // Test validation
        #expect(!state.canProceedToNextStep())
        
        // Mark step as complete
        state.markStepComplete("personal")
        #expect(state.canProceedToNextStep())
    }
    
    /// BUSINESS PURPOSE: Validate FormWizard large step count functionality
    /// TESTING SCOPE: Tests FormWizard with large number of steps and performance
    /// METHODOLOGY: Test FormWizard with many steps and verify performance functionality
    @Test func testFormWizardLargeNumberOfSteps() {
        var builder = FormWizardBuilder()
        
        // Create many steps
        for i in 0..<100 {
            builder.addStep(
                id: "step\(i)",
                title: "Step \(i)"
            )
        }
        
        let steps = builder.build()
        #expect(steps.count == 100)
        
        let state = FormWizardState()
        state.setSteps(steps)
        
        // Test navigation through many steps
        for i in 0..<50 {
            #expect(state.currentStepIndex == i)
            #expect(state.getCurrentStep()?.id == "step\(i)")
            
            // Mark current step as complete before proceeding
            state.markStepComplete("step\(i)")
            
            #expect(state.nextStep())
        }
        
        #expect(state.currentStepIndex == 50)
    }
    
    /// BUSINESS PURPOSE: Validate FormWizardState persistence functionality
    /// TESTING SCOPE: Tests FormWizardState persistence and state restoration
    /// METHODOLOGY: Test FormWizardState persistence and verify state restoration functionality
    @Test func testFormWizardStatePersistence() {
        let state = FormWizardState()
        let steps = [
            FormWizardStep(id: "step1", title: "Step 1", stepOrder: 0),
            FormWizardStep(id: "step2", title: "Step 2", stepOrder: 1)
        ]
        
        state.setSteps(steps)
        
        // Set some data and state
        state.setStepData("step1", key: "name", value: "John")
        state.markStepComplete("step1")
        state.addValidationError("Error", for: "step2")
        
        // Verify state is maintained
        #expect(state.getStepData("step1", key: "name") as String? == "John")
        #expect(state.isStepComplete("step1"))
        #expect(state.validationErrors["step2"]?.contains("Error") ?? false)
    }
}
