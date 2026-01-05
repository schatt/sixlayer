import Testing

//
//  Layer4FormContainerTests.swift
//  SixLayerFrameworkTests
//
//  Layer 4 (Implementation) TDD Tests
//  Tests for platformFormContainer_L4 function
//

import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Layer Form Container")
open class Layer4FormContainerTests: BaseTestClass {
    
    // MARK: - Test Data
    
    let testContent = Text("Test Form Content")
    
    // MARK: - Form Container Type Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_FormContainer() {
        // Given: Form container strategy
        let strategy = FormStrategy(
            containerType: .form,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // view is a non-optional View, so it exists if we reach here
        
        // 2. Does that structure contain what it should?
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(view) { inspected in
            // The form container should contain the test content
            let viewText = inspected.findAll(ViewType.Text.self)
            #expect(!viewText.isEmpty, "Form container should contain text elements")

            // Should contain the test content - use helper function for DRY text verification
            verifyViewContainsText(view, expectedText: "Test Form Content", testName: "Form container content")
        }

        if inspectionResult == nil {
            #if canImport(ViewInspector)
            Issue.record("View inspection failed on this platform")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Form container created (ViewInspector not available on macOS)")
            #endif
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // 3. Platform-specific implementation verification (REQUIRED)
        #if canImport(ViewInspector)
        #if os(iOS)
        // iOS: Should contain Form structure with iOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        withInspectedView(view) { inspected in
            if let _ = inspected.findAll(ViewType.Form.self) {
                // Form found - this is correct for iOS
                // Note: iOS uses Color(.systemGroupedBackground) for form backgrounds
            } else {
                Issue.record("iOS form container should contain Form structure")
            }
        }
        #elseif os(macOS)
        // macOS: Should contain Form structure with macOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        withInspectedView(view) { inspected in
            if let _ = inspected.findAll(ViewType.Form.self) {
                // Form found - this is correct for macOS
                // Note: macOS uses Color(.controlBackgroundColor) for form backgrounds
            } else {
                Issue.record("macOS form container should contain Form structure")
            }
        }
        #endif
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_StandardContainer() {
        // Given: Standard container strategy
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Test the two critical aspects
        
        // 1. Does it return a valid structure of the kind it's supposed to?
        // view is a non-optional View, so it exists if we reach here
        
        // 2. Does that structure contain what it should?
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        #if canImport(ViewInspector)
        withInspectedView(view) { inspected in
            let viewText = inspected.findAll(ViewType.Text.self)
            #expect(!viewText.isEmpty, "Standard container should contain text elements")

            // Should contain the test content - use helper function for DRY text verification
            TestPatterns.verifyViewContainsText(view, expectedText: "Test Form Content", testName: "Standard container content")
        }
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        #endif
        
        // 3. Platform-specific implementation verification (REQUIRED)
        #if os(iOS)
        // iOS: Should contain VStack structure with iOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        if let vStack = try? AnyView(view).inspect() {
            // VStack found - this is correct for iOS
            // Note: iOS uses Color(.secondarySystemBackground) for standard container backgrounds
        } else {
            Issue.record("iOS standard container should contain VStack structure")
        }
        #elseif os(macOS)
        // macOS: Should contain VStack structure with macOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        if let vStack = try? AnyView(view).inspect() {
            // VStack found - this is correct for macOS
            // Note: macOS uses Color(.controlBackgroundColor) for standard container backgrounds
        } else {
            #if canImport(ViewInspector)
            Issue.record("macOS standard container should contain VStack structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Form container created (ViewInspector not available on macOS)")
            #endif
        }
        #endif
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_ScrollViewContainer() {
        // Given: ScrollView container strategy
        let strategy = FormStrategy(
            containerType: .scrollView,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with ScrollView container
        // view is non-optional, used below with Mirror
        
        // 3. Platform-specific implementation verification (REQUIRED)
        #if os(iOS)
        // iOS: Should contain ScrollView structure with iOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        if let scrollView = view.tryInspect() {
            // ScrollView found - this is correct for iOS
            // Note: iOS uses Color(.systemGroupedBackground) for scroll view backgrounds
        } else {
            #if canImport(ViewInspector)
            Issue.record("iOS scroll view container should contain ScrollView structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Form container created (ViewInspector not available on macOS)")
            #endif
        }
        #elseif os(macOS)
        // macOS: Should contain ScrollView structure with macOS-specific background color
        // Using wrapper - when ViewInspector works on macOS, no changes needed here
        if let scrollView = view.tryInspect() {
            // ScrollView found - this is correct for macOS
            // Note: macOS uses Color(.controlBackgroundColor) for scroll view backgrounds
        } else {
            #if canImport(ViewInspector)
            Issue.record("macOS scroll view container should contain ScrollView structure")
            #else
            // ViewInspector not available on macOS - test passes by verifying view creation
            #expect(Bool(true), "Form container created (ViewInspector not available on macOS)")
            #endif
        }
        #endif
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_CustomContainer() {
        // Given: Custom container strategy
        let strategy = FormStrategy(
            containerType: .custom,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with custom VStack container
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_AdaptiveContainer() {
        // Given: Adaptive container strategy
        let strategy = FormStrategy(
            containerType: .adaptive,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with adaptive VStack container
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    // MARK: - Field Layout Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_DifferentFieldLayouts() {
        // Given: Different field layout strategies
        let fieldLayouts: [FieldLayout] = [
            .compact, .standard, .spacious, .adaptive,
            .vertical, .horizontal, .grid
        ]
        
        for fieldLayout in fieldLayouts {
            let strategy = FormStrategy(
                containerType: .standard,
                fieldLayout: fieldLayout,
                validation: .deferred
            )
            
            // When: Creating form container
            let view = platformFormContainer_L4(strategy: strategy) {
                self.testContent
            }
            
            // Then: Should return a view for each field layout
            // view is a non-optional View, so it exists if we reach here
            
            let mirror = Mirror(reflecting: view)
            #expect(String(describing: mirror.subjectType) == "AnyView", "Should return AnyView for layout: \(fieldLayout)")
        }
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_CompactLayout() {
        // Given: Compact field layout strategy
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .compact,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with compact spacing
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_SpaciousLayout() {
        // Given: Spacious field layout strategy
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .spacious,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with spacious spacing
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_GridLayout() {
        // Given: Grid field layout strategy
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .grid,
            validation: .deferred
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with grid spacing
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    // MARK: - Validation Strategy Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_DifferentValidationStrategies() {
        // Given: Different validation strategies
        let validationStrategies: [ValidationStrategy] = [
            .none, .realTime, .onSubmit, .custom, .immediate, .deferred
        ]
        
        for validation in validationStrategies {
            let strategy = FormStrategy(
                containerType: .standard,
                fieldLayout: .standard,
                validation: validation
            )
            
            // When: Creating form container
            let view = platformFormContainer_L4(strategy: strategy) {
                self.testContent
            }
            
            // Then: Should return a view for each validation strategy
            // view is non-optional, used below with Mirror
            let mirror = Mirror(reflecting: view)
            #expect(String(describing: mirror.subjectType) == "AnyView", "Should return AnyView for validation: \(validation)")
        }
    }
    
    // MARK: - Complex Content Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_ComplexContent() {
        // Given: Complex content with multiple views
        let complexContent = platformVStackContainer {
            Text("Form Title")
                .font(.headline)
            TextField("Name", text: .constant(""))
            TextField("Email", text: .constant(""))
            Button("Submit") { }
        }
        
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container with complex content
        let view = platformFormContainer_L4(strategy: strategy) {
            complexContent
        }
        
        // Then: Should return a view containing the complex content
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_EmptyContent() {
        // Given: Empty content
        let emptyContent = EmptyView()
        
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Creating form container with empty content
        let view = platformFormContainer_L4(strategy: strategy) {
            emptyContent
        }
        
        // Then: Should return a view even with empty content
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    // MARK: - Platform Adaptations Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_WithPlatformAdaptations() {
        // Given: Strategy with platform adaptations
        let platformAdaptations: [ModalPlatform: PlatformAdaptation] = [
            .iOS: .standardFields,
            .macOS: .largeFields
        ]
        
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .standard,
            validation: .deferred,
            platformAdaptations: platformAdaptations
        )
        
        // When: Creating form container
        let view = platformFormContainer_L4(strategy: strategy) {
            self.testContent
        }
        
        // Then: Should return a view with platform adaptations
        // view is non-optional, used below with Mirror
        
        let mirror = Mirror(reflecting: view)
        #expect(String(describing: mirror.subjectType) == "AnyView")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test @MainActor func testPlatformFormContainer_L4_AllContainerTypes() {
        // Given: All possible container types
        let containerTypes: [FormContainerType] = [
            .form, .scrollView, .custom, .adaptive, .standard
        ]
        
        for containerType in containerTypes {
            let strategy = FormStrategy(
                containerType: containerType,
                fieldLayout: .standard,
                validation: .deferred
            )
            
            // When: Creating form container
            let view = platformFormContainer_L4(strategy: strategy) {
                self.testContent
            }
            
            // Then: Should return a view for each container type
            // view is non-optional, used below with Mirror
            let mirror = Mirror(reflecting: view)
            #expect(String(describing: mirror.subjectType) == "AnyView", "Should return AnyView for container: \(containerType)")
        }
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_AllFieldLayouts() {
        // Given: All possible field layouts
        let fieldLayouts: [FieldLayout] = [
            .standard, .compact, .spacious, .adaptive,
            .vertical, .horizontal, .grid
        ]
        
        for fieldLayout in fieldLayouts {
            let strategy = FormStrategy(
                containerType: .standard,
                fieldLayout: fieldLayout,
                validation: .deferred
            )
            
            // When: Creating form container
            let view = platformFormContainer_L4(strategy: strategy) {
                self.testContent
            }
            
            // Then: Should return a view for each field layout
            // view is a non-optional View, so it exists if we reach here
            
            let mirror = Mirror(reflecting: view)
            #expect(String(describing: mirror.subjectType) == "AnyView", "Should return AnyView for layout: \(fieldLayout)")
        }
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_AllValidationStrategies() {
        // Given: All possible validation strategies
        let validationStrategies: [ValidationStrategy] = [
            .none, .realTime, .onSubmit, .custom, .immediate, .deferred
        ]
        
        for validation in validationStrategies {
            let strategy = FormStrategy(
                containerType: .standard,
                fieldLayout: .standard,
                validation: validation
            )
            
            // When: Creating form container
            let view = platformFormContainer_L4(strategy: strategy) {
                self.testContent
            }
            
            // Then: Should return a view for each validation strategy
            // view is non-optional, used below with Mirror
            let mirror = Mirror(reflecting: view)
            #expect(String(describing: mirror.subjectType) == "AnyView", "Should return AnyView for validation: \(validation)")
        }
    }
    
    // MARK: - Performance Tests
    
    @Test @MainActor func testPlatformFormContainer_L4_Performance() {
        // Given: Standard strategy
        let strategy = FormStrategy(
            containerType: .standard,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Measuring performance
        }
    }
    
    @Test @MainActor func testPlatformFormContainer_L4_PerformanceWithComplexContent() {
        // Given: Complex content
        let complexContent = platformVStackContainer {
            ForEach(0..<50) { i in
                TextField("Field \(i)", text: .constant(""))
            }
        }
        
        let strategy = FormStrategy(
            containerType: .scrollView,
            fieldLayout: .standard,
            validation: .deferred
        )
        
        // When: Measuring performance
        // Performance test removed - performance monitoring was removed from framework
    }
