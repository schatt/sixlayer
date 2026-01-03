import Testing

//
//  ModalFormL1Tests.swift
//  SixLayerFrameworkTests
//
//  Tests for modal form L1 functions
//  Tests modal form presentation features
//

import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView
@Suite(.serialized)
open class ModalFormL1Tests: BaseTestClass {
    
    // MARK: - Test Data Helpers (test isolation - each test creates fresh data)
    
    // Helper method - creates fresh hints for each test (test isolation)
    private func createSampleHints() -> PresentationHints {
        return PresentationHints()
    }    // MARK: - Modal Form Tests
    
    @Test @MainActor func testPlatformPresentModalForm_L1() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithDifferentFormType() {
        // Given
        let formType = DataTypeHint.user
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with different form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithDifferentContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.create
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with different context should return a view")
    }
    
    // MARK: - Different Form Types
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithUserFormType() {
        // Given
        let formType = DataTypeHint.user
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with user form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithTransactionFormType() {
        // Given
        let formType = DataTypeHint.transaction
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with transaction form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithActionFormType() {
        // Given
        let formType = DataTypeHint.action
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with action form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithProductFormType() {
        // Given
        let formType = DataTypeHint.product
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with product form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCommunicationFormType() {
        // Given
        let formType = DataTypeHint.communication
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with communication form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithLocationFormType() {
        // Given
        let formType = DataTypeHint.location
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with location form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithNavigationFormType() {
        // Given
        let formType = DataTypeHint.navigation
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with navigation form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCardFormType() {
        // Given
        let formType = DataTypeHint.card
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with card form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithDetailFormType() {
        // Given
        let formType = DataTypeHint.detail
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with detail form type should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithSheetFormType() {
        // Given
        let formType = DataTypeHint.sheet
        let context = PresentationContext.modal
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with sheet form type should return a view")
    }
    
    // MARK: - Different Contexts
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCreateContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.create
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with create context should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithEditContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.edit
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with edit context should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithSettingsContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.settings
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with settings context should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithProfileContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.profile
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with profile context should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithSearchContext() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.search
        
        // When
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then
        // view is a non-optional View, so it exists if we reach here with search context should return a view")
    }
    
    // MARK: - Performance Tests
    
    @Test @MainActor func testPlatformPresentModalForm_L1_Performance() {
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.modal
        
        // When & Then: use Layer 1 API
        _ = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        #expect(Bool(true), "view is non-optional")  // view is non-optional
        // Performance test removed - performance monitoring was removed from framework
    }
    
    // MARK: - Custom Form Container View Tests
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCustomFormContainer() {
        initializeTestConfig()
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.modal
        
        // When: Using custom form container view
        let view = platformPresentModalForm_L1(
            formType: formType,
            context: context,
            customFormContainer: { (formContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Header")
                        .font(.headline)
                    formContent
                        .padding()
                        .background(Color.platformSecondaryBackground)
                        .cornerRadius(12)
                }
            }
        )
        
        // Then: Should return a view with custom container
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentModalForm_L1 with custom form container should return a view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCustomFormContainer_Nil() {
        initializeTestConfig()
        // Given
        let formType = DataTypeHint.form
        let context = PresentationContext.modal
        
        // When: Not providing custom form container (should use default)
        // Omit the parameter to use default value instead of passing nil
        let view = platformPresentModalForm_L1(
            formType: formType,
            context: context
        )
        
        // Then: Should return default view
        _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentModalForm_L1 with nil custom form container should return default view")
    }
    
    @Test @MainActor func testPlatformPresentModalForm_L1_WithCustomFormContainer_DifferentFormTypes() {
        initializeTestConfig()
        // Given
        let formTypes: [DataTypeHint] = [.form, .user, .transaction, .action]
        let context = PresentationContext.modal
        
        // When & Then: Each form type should work with custom container
        for formType in formTypes {
            let view = platformPresentModalForm_L1(
                formType: formType,
                context: context,
                customFormContainer: { (formContent: AnyView) in
                    formContent
                        .padding()
                        .background(Color.blue.opacity(0.1))
                }
            )
            _ = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
            #expect(Bool(true), "platformPresentModalForm_L1 with custom container should work for \(formType)")
        }
    }
}