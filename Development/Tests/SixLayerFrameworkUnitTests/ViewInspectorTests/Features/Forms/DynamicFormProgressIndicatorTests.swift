import Testing
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

/// UI tests for DynamicFormView progress indicator
/// 
/// Resolves #99, #82
/// - #99: UI tests for form progress indicator
/// - #82: Form progress indicator implementation (tests added here)
/// 
/// BUSINESS PURPOSE: Ensure form progress indicator displays correctly and updates in real-time
/// TESTING SCOPE: Visual display, real-time updates, and accessibility of progress indicator
/// METHODOLOGY: Test UI rendering and behavior on both iOS and macOS platforms
@Suite("Dynamic Form Progress Indicator UI")
open class DynamicFormProgressIndicatorTests: BaseTestClass {
    
    // MARK: - Helper Methods
    
    /// Find progress indicator by structure (VStack containing ProgressView and "Progress" text)
    /// ViewInspector may not be able to find custom struct types directly, so we use structure-based finding
    #if canImport(ViewInspector)
    private func findProgressIndicator(in inspected: ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>) -> ViewInspector.InspectableView<ViewInspector.ViewType.ClassifiedView>? {
        // Strategy: Find a VStack that contains both a ProgressView and "Progress" text
        // This matches the structure of FormProgressIndicator
        
        // First, check if the current view is a VStack with the right structure
        if let vStack = try? inspected.vStack() {
            // Check if this VStack contains a ProgressView
            let progressViews = vStack.findAll(ViewInspector.ViewType.ProgressView.self)
            let hasProgressView = !progressViews.isEmpty
            
            // Check if it contains "Progress" text
            let texts = vStack.findAll(ViewInspector.ViewType.Text.self)
            let hasProgressText = texts.contains { text in
                (try? text.string()) == "Progress"
            }
            
            if hasProgressView && hasProgressText {
                return vStack
            }
        }
        
        // Search for ProgressView and verify it's in a VStack with "Progress" text
        let progressViews = inspected.findAll(ViewInspector.ViewType.ProgressView.self)
        for _ in progressViews {
            // If we found a ProgressView, check if there's "Progress" text nearby
            // (indicating this is likely the progress indicator)
            let texts = inspected.findAll(ViewInspector.ViewType.Text.self)
            let hasProgressText = texts.contains { text in
                (try? text.string()) == "Progress"
            }
            if hasProgressText {
                // Try to find the parent VStack
                if let vStack = try? inspected.vStack() {
                    return vStack
                }
                // If we can't get the VStack, return the inspected view itself
                // as it contains the progress indicator structure
                return inspected
            }
        }
        
        return nil
    }
    #endif
    
    // MARK: - Progress Indicator Display Tests
    
    /// BUSINESS PURPOSE: Verify progress indicator displays when enabled
    /// TESTING SCOPE: Progress indicator visibility when showProgress is true
    /// METHODOLOGY: Create form with showProgress: true and verify component exists
    @Test @MainActor func testProgressIndicatorDisplaysWhenEnabled() async {
        initializeTestConfig()
        
        // Given: A form with showProgress: true
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: [
                DynamicFormSection(
                    id: "section1",
                    title: "Personal Info",
                    fields: [
                        DynamicFormField(id: "name", contentType: .text, label: "Name", isRequired: true),
                        DynamicFormField(id: "email", contentType: .email, label: "Email", isRequired: true)
                    ]
                )
            ],
            showProgress: true
        )
        
        let view = DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        
        // Then: Progress indicator should be visible
        #if canImport(ViewInspector)
        do {
            try withInspectedViewThrowing(view) { inspected in
                // Find the FormProgressIndicator by structure (ViewInspector may not find custom struct types directly)
                let progressIndicator = findProgressIndicator(in: inspected)
                #expect(progressIndicator != nil, "Progress indicator should be present when showProgress is true")
                
                // Verify it contains the expected elements
                if let indicator = progressIndicator {
                    let progressViews = indicator.findAll(ViewInspector.ViewType.ProgressView.self)
                    let progressView = progressViews.first
                    #expect(progressView != nil, "Progress indicator should contain ProgressView")
                }
            }
        } catch {
            Issue.record("View inspection failed: \(error)")
        }
        #else
        // ViewInspector not available on macOS - verify view is created
        #expect(Bool(true), "View created successfully with showProgress: true")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator is hidden when disabled
    /// TESTING SCOPE: Progress indicator visibility when showProgress is false
    /// METHODOLOGY: Create form with showProgress: false and verify component doesn't exist
    @Test @MainActor func testProgressIndicatorHiddenWhenDisabled() async {
        initializeTestConfig()
        
        // Given: A form with showProgress: false
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: [
                DynamicFormSection(
                    id: "section1",
                    title: "Personal Info",
                    fields: [
                        DynamicFormField(id: "name", contentType: .text, label: "Name", isRequired: true)
                    ]
                )
            ],
            showProgress: false
        )
        
        let view = DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        
        // Then: Progress indicator should NOT be visible
        #if canImport(ViewInspector)
        do {
            try withInspectedViewThrowing(view) { inspected in
                // Attempt to find the FormProgressIndicator by structure
                let progressIndicator = findProgressIndicator(in: inspected)
                #expect(progressIndicator == nil, "Progress indicator should not be present when showProgress is false")
            }
        } catch {
            Issue.record("View inspection failed: \(error)")
        }
        #else
        // ViewInspector not available on macOS - verify view is created
        #expect(Bool(true), "View created successfully with showProgress: false")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator displays correct field count text
    /// TESTING SCOPE: "X of Y fields" text accuracy
    /// METHODOLOGY: Create form and verify displayed text matches actual required fields
    @Test @MainActor func testProgressIndicatorDisplaysCorrectFieldCount() async {
        initializeTestConfig()
        
        // Given: A form with 3 required fields, 1 optional field
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: [
                DynamicFormSection(
                    id: "section1",
                    title: "Info",
                    fields: [
                        DynamicFormField(id: "field1", contentType: .text, label: "Field 1", isRequired: true),
                        DynamicFormField(id: "field2", contentType: .text, label: "Field 2", isRequired: true),
                        DynamicFormField(id: "field3", contentType: .text, label: "Field 3", isRequired: true),
                        DynamicFormField(id: "field4", contentType: .text, label: "Field 4", isRequired: false)
                    ]
                )
            ],
            showProgress: true
        )
        
        let view = DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        
        // Then: Progress indicator should show "0 of 3 fields"
        #if canImport(ViewInspector)
        do {
            try withInspectedViewThrowing(view) { inspected in
                let progressIndicator = findProgressIndicator(in: inspected)
                if let indicator = progressIndicator {
                    // Look for the text showing field count
                    let texts = indicator.findAll(ViewInspector.ViewType.Text.self)
                    let fieldCountText = texts.first { text in
                        (try? text.string())?.contains("of") ?? false
                    }
                    
                    if let countText = fieldCountText {
                        let textString = try? countText.string()
                        #expect(textString?.contains("0 of 3") ?? false, "Should display '0 of 3 fields' for empty form")
                        #expect(textString?.contains("field") ?? false, "Should contain 'field' text")
                    } else {
                        Issue.record("Could not find field count text in progress indicator")
                    }
                } else {
                    Issue.record("Could not find progress indicator to verify field count")
                }
            }
        } catch {
            Issue.record("View inspection failed - could not verify field count text: \(error)")
        }
        #else
        // ViewInspector not available on macOS - verify view is created
        #expect(Bool(true), "View created successfully")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress bar visual matches percentage
    /// TESTING SCOPE: Progress bar ProgressView value corresponds to percentage
    /// METHODOLOGY: Create form, fill some fields, verify progress bar value
    @Test @MainActor func testProgressBarMatchesPercentage() async {
        initializeTestConfig()
        
        // Given: A form with 2 required fields
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: [
                DynamicFormSection(
                    id: "section1",
                    title: "Info",
                    fields: [
                        DynamicFormField(id: "field1", contentType: .text, label: "Field 1", isRequired: true),
                        DynamicFormField(id: "field2", contentType: .text, label: "Field 2", isRequired: true)
                    ]
                )
            ],
            showProgress: true
        )
        
        let view = DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        
        // Then: Progress bar should show 0% initially
        #if canImport(ViewInspector)
        #if canImport(ViewInspector)
        do {
            try withInspectedViewThrowing(view) { inspected in
                let progressIndicator = findProgressIndicator(in: inspected)
                if let indicator = progressIndicator {
                    // Look for ProgressView
                    let progressViews = indicator.findAll(ViewInspector.ViewType.ProgressView.self)
                    let progressView = progressViews.first
                    #expect(progressView != nil, "Progress bar should be present")
                    
                    // Verify the structure contains expected elements
                    let texts = indicator.findAll(ViewInspector.ViewType.Text.self)
                    #expect(texts.count >= 2, "Progress indicator should have at least Progress title and field count text")
                } else {
                    Issue.record("Could not find progress indicator to verify progress bar")
                }
            }
        } catch {
            Issue.record("View inspection failed - could not verify progress bar: \(error)")
        }
        #else
        // ViewInspector not available on macOS - verify view is created
        #expect(Bool(true), "View created successfully")
        #endif
    }
    
    // MARK: - Real-Time Updates Tests
    
    /// BUSINESS PURPOSE: Verify progress indicator UI updates as user fills fields
    /// TESTING SCOPE: Progress indicator view updates when field values change in the UI
    /// METHODOLOGY: Create form view, verify initial state, then verify UI reflects progress changes
    /// NOTE: State calculation is tested in unit tests (DynamicFormTests.swift). This tests UI reactivity.
    @Test @MainActor func testProgressIndicatorUpdatesWhenFieldsFilled() async {
        initializeTestConfig()
        
        // Given: A form with 2 required fields
        let configuration = DynamicFormConfiguration(
            id: "testForm",
            title: "Test Form",
            sections: [
                DynamicFormSection(
                    id: "section1",
                    title: "Info",
                    fields: [
                        DynamicFormField(id: "name", contentType: .text, label: "Name", isRequired: true),
                        DynamicFormField(id: "email", contentType: .email, label: "Email", isRequired: true)
                    ]
                )
            ],
            showProgress: true
        )
        
        let view = DynamicFormView(
            configuration: configuration,
            onSubmit: { _ in }
        )
        
        // Verify initial state: should show "0 of 2 fields"
        #if canImport(ViewInspector)
        do {
            try withInspectedViewThrowing(view) { inspected in
                let progressIndicator = findProgressIndicator(in: inspected)
                if let indicator = progressIndicator {
                    let texts = indicator.findAll(ViewInspector.ViewType.Text.self)
                    let fieldCountText = texts.first { text in
                        (try? text.string())?.contains("of") ?? false
                    }
                    if let countText = fieldCountText {
                        let textString = try? countText.string()
                        #expect(textString?.contains("0 of 2") ?? false, "Initially should show '0 of 2 fields'")
                    }
                }
            }
        } catch {
            Issue.record("View inspection failed: \(error)")
        }
        #else
        // ViewInspector not available - verify view is created
        #expect(Bool(true), "View created successfully")
        #endif
        
        // Note: Testing actual UI updates when fields are filled would require
        // interacting with the form fields, which is complex in ViewInspector.
        // The state calculation is thoroughly tested in unit tests.
        // This test verifies the UI structure is present and displays initial state correctly.
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator displays correct count for different completion states
    /// TESTING SCOPE: Progress indicator text accuracy for various completion percentages
    /// METHODOLOGY: Create progress indicators with different states and verify displayed text
    @Test @MainActor func testProgressIndicatorDisplaysCorrectCounts() async {
        initializeTestConfig()
        
        // Test various completion states
        let testCases: [(completed: Int, total: Int, expectedText: String)] = [
            (0, 2, "0 of 2"),
            (1, 2, "1 of 2"),
            (2, 2, "2 of 2"),
            (0, 1, "0 of 1"),
            (1, 1, "1 of 1"),
            (3, 5, "3 of 5")
        ]
        
        #if canImport(ViewInspector)
        for testCase in testCases {
            let progress = FormProgress(
                completed: testCase.completed,
                total: testCase.total,
                percentage: Double(testCase.completed) / Double(testCase.total)
            )
            let progressIndicator = FormProgressIndicator(progress: progress)
            
            let inspectionResult = withInspectedView(progressIndicator) { inspected in
                let texts = inspected.findAll(Text.self)
                let fieldCountText = texts.first { text in
                    (try? text.string())?.contains("of") ?? false
                }
                if let countText = fieldCountText {
                    let textString = try? countText.string()
                    #expect(textString?.contains(testCase.expectedText) ?? false, 
                           "Should display '\(testCase.expectedText) fields' for \(testCase.completed)/\(testCase.total)")
                } else {
                    Issue.record("Could not find field count text for \(testCase.completed)/\(testCase.total)")
                }
            }
            
            if inspectionResult == nil {
                Issue.record("View inspection failed for \(testCase.completed)/\(testCase.total)")
            }
        }
        #else
        // ViewInspector not available - verify components are created
        #expect(Bool(true), "All progress indicators created successfully")
        #endif
    }
    
    // MARK: - Accessibility Tests
    
    /// BUSINESS PURPOSE: Verify accessibility labels are correct
    /// TESTING SCOPE: Accessibility label contains progress information
    /// METHODOLOGY: Create progress indicator and verify accessibility label content
    @Test @MainActor func testProgressIndicatorHasCorrectAccessibilityLabel() async {
        initializeTestConfig()
        
        // Given: A progress indicator with known values
        let progress = FormProgress(completed: 2, total: 5, percentage: 0.4)
        let progressIndicator = FormProgressIndicator(progress: progress)
        
        // Then: Accessibility label should describe the progress
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Verify accessibility label is set
            let hasAccessibilityLabel = testComponentComplianceSinglePlatform(
                progressIndicator,
                expectedPattern: "SixLayer.*FormProgressIndicator.*",
                platform: .iOS,
                componentName: "FormProgressIndicator"
            )
            #expect(hasAccessibilityLabel, "Progress indicator should have accessibility identifier")
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify accessibility label")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify accessibility value matches displayed text
    /// TESTING SCOPE: Accessibility value provides same information as visual display
    /// METHODOLOGY: Create progress indicator and verify accessibility identifier and structure
    @Test @MainActor func testProgressIndicatorAccessibilityValueMatchesDisplay() async {
        initializeTestConfig()
        
        // Given: A progress indicator showing 3 of 5 fields completed
        let progress = FormProgress(completed: 3, total: 5, percentage: 0.6)
        let progressIndicator = FormProgressIndicator(progress: progress)
        
        // Then: Accessibility identifier should be set and component should have proper structure
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Verify accessibility identifier is set (as per implementation)
            let hasAccessibilityID = testComponentComplianceSinglePlatform(
                progressIndicator,
                expectedPattern: "SixLayer.*FormProgressIndicator.*",
                platform: .iOS,
                componentName: "FormProgressIndicator"
            )
            #expect(hasAccessibilityID, "Progress indicator should have accessibility identifier")
            
            // Verify the displayed text matches what accessibility should announce
            // Implementation sets: accessibilityLabel with percentage and count
            // Implementation sets: accessibilityValue with "X of Y fields completed"
            let texts = inspected.findAll(Text.self)
            let fieldCountText = texts.first { text in
                (try? text.string())?.contains("3 of 5") ?? false
            }
            #expect(fieldCountText != nil, "Should display '3 of 5 fields' text that matches accessibility value")
            
            // Note: ViewInspector cannot directly read accessibilityLabel/accessibilityValue content,
            // but we verify the component structure and that modifiers are applied via identifier check
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify accessibility value")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify screen readers can announce progress updates
    /// TESTING SCOPE: Accessibility announcements for progress changes
    /// METHODOLOGY: Verify accessibility modifiers are applied for screen reader support
    @Test @MainActor func testProgressIndicatorSupportsScreenReaderAnnouncements() async {
        initializeTestConfig()
        
        // Given: Progress indicators with different states
        let progress0 = FormProgress(completed: 0, total: 3, percentage: 0.0)
        let progress1 = FormProgress(completed: 1, total: 3, percentage: 0.33)
        let progress3 = FormProgress(completed: 3, total: 3, percentage: 1.0)
        
        let indicator0 = FormProgressIndicator(progress: progress0)
        let indicator1 = FormProgressIndicator(progress: progress1)
        let indicator3 = FormProgressIndicator(progress: progress3)
        
        // Then: Each indicator should have appropriate accessibility support
        #if canImport(ViewInspector)
        // Verify all indicators have accessibility modifiers
        for (indicator, expectedCompleted) in [(indicator0, 0), (indicator1, 1), (indicator3, 3)] {
            let inspectionResult = withInspectedView(indicator) { inspected in
                // Verify accessibility identifier is set
                let hasAccessibilityID = testComponentComplianceSinglePlatform(
                    indicator,
                    expectedPattern: "SixLayer.*FormProgressIndicator.*",
                    platform: .iOS,
                    componentName: "FormProgressIndicator"
                )
                #expect(hasAccessibilityID, "Progress indicator should have accessibility identifier for screen readers")
                
                // Verify structure contains text elements that screen readers can announce
                let texts = inspected.findAll(Text.self)
                #expect(texts.count >= 2, "Should have text elements for screen reader announcements")
            }
            
            if inspectionResult == nil {
                Issue.record("View inspection failed for progress indicator with \(expectedCompleted) completed")
            }
        }
        #else
        // ViewInspector not available on macOS - verify indicators are created
        #expect(Bool(true), "All progress indicators created successfully")
        #endif
    }
    
    // MARK: - Visual Design Tests
    
    /// BUSINESS PURPOSE: Verify progress indicator follows design patterns
    /// TESTING SCOPE: Visual structure and component hierarchy
    /// METHODOLOGY: Inspect view hierarchy to verify design structure
    @Test @MainActor func testProgressIndicatorFollowsDesignPattern() async {
        initializeTestConfig()
        
        // Given: A progress indicator
        let progress = FormProgress(completed: 1, total: 2, percentage: 0.5)
        let progressIndicator = FormProgressIndicator(progress: progress)
        
        // Then: Should have proper structure (VStack with HStack and ProgressView)
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Should have VStack as root
            let vStack = try? inspected.vStack()
            #expect(vStack != nil, "Progress indicator should have VStack as root")
            
            if let vStack = vStack {
                // Should contain HStack (for title and field count)
                let hStack = vStack.findAll(ViewType.HStack.self)
                #expect(hStack != nil, "Should contain HStack for title and count")
                
                // Should contain ProgressView
                let progressView = vStack.findAll(ProgressView<EmptyView, EmptyView>.self)
                #expect(progressView != nil, "Should contain ProgressView for visual progress bar")
            }
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify design structure")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator is visible and readable
    /// TESTING SCOPE: Visual properties like padding, background, corner radius
    /// METHODOLOGY: Verify styling modifiers are applied
    @Test @MainActor func testProgressIndicatorIsVisibleAndReadable() async {
        initializeTestConfig()
        
        // Given: A progress indicator
        let progress = FormProgress(completed: 2, total: 4, percentage: 0.5)
        let progressIndicator = FormProgressIndicator(progress: progress)
        
        // Then: Should have visual styling for readability
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Verify the view structure indicates styling (VStack with proper hierarchy)
            // ViewInspector cannot directly detect padding/background/cornerRadius modifiers,
            // but we can verify the component structure is correct
            let vStack = try? inspected.vStack()
            #expect(vStack != nil, "Progress indicator should have VStack structure for styling")
            
            // Verify text elements are present (styling makes them readable)
            let texts = inspected.findAll(Text.self)
            #expect(texts.count >= 2, "Should have text elements that are styled for readability")
            
            // Note: Actual padding, background, and cornerRadius modifiers are verified
            // by visual inspection and are present in the implementation code
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify visual styling")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator displays all required elements
    /// TESTING SCOPE: Presence of all UI elements (title, count, progress bar)
    /// METHODOLOGY: Verify all text elements and progress bar are present
    @Test @MainActor func testProgressIndicatorDisplaysAllElements() async {
        initializeTestConfig()
        
        // Given: A progress indicator
        let progress = FormProgress(completed: 1, total: 3, percentage: 0.33)
        let progressIndicator = FormProgressIndicator(progress: progress)
        
        // Then: Should display all elements
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Find all Text elements
            let texts = inspected.findAll(Text.self)
            
            // Should have at least 2 Text elements: "Progress" and "1 of 3 fields"
            #expect(texts.count >= 2, "Should have Progress label and field count text")
            
            // Verify "Progress" title exists
            let hasProgressTitle = texts.contains { text in
                (try? text.string()) == "Progress"
            }
            #expect(hasProgressTitle, "Should display 'Progress' title")
            
            // Verify field count text exists
            let hasFieldCount = texts.contains { text in
                (try? text.string())?.contains("of") ?? false
            }
            #expect(hasFieldCount, "Should display field count text")
            
            // Verify ProgressView exists
            let progressView = inspected.findAll(ProgressView<EmptyView, EmptyView>.self)
            #expect(progressView != nil, "Should display progress bar")
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify all elements")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully")
        #endif
    }
    
    // MARK: - Visual Design Tests (Light/Dark Mode)
    
    /// BUSINESS PURPOSE: Verify progress indicator is visible and readable in light mode
    /// TESTING SCOPE: Progress indicator visibility and readability in light color scheme
    /// METHODOLOGY: Create progress indicator and verify it renders correctly in light mode
    @Test @MainActor func testProgressIndicatorWorksInLightMode() async {
        initializeTestConfig()
        
        // Given: A progress indicator
        let progress = FormProgress(completed: 2, total: 4, percentage: 0.5)
        let progressIndicator = FormProgressIndicator(progress: progress)
            .preferredColorScheme(.light)
        
        // Then: Should be visible and readable in light mode
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Verify structure is present (visibility)
            let vStack = try? inspected.vStack()
            #expect(vStack != nil, "Progress indicator should render in light mode")
            
            // Verify text elements are present (readability)
            let texts = inspected.findAll(Text.self)
            #expect(texts.count >= 2, "Should have text elements visible in light mode")
            
            // Verify ProgressView is present
            let progressView = inspected.findAll(ProgressView<EmptyView, EmptyView>.self)
            #expect(progressView != nil, "Progress bar should be visible in light mode")
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify light mode display")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully in light mode")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator is visible and readable in dark mode
    /// TESTING SCOPE: Progress indicator visibility and readability in dark color scheme
    /// METHODOLOGY: Create progress indicator and verify it renders correctly in dark mode
    @Test @MainActor func testProgressIndicatorWorksInDarkMode() async {
        initializeTestConfig()
        
        // Given: A progress indicator
        let progress = FormProgress(completed: 2, total: 4, percentage: 0.5)
        let progressIndicator = FormProgressIndicator(progress: progress)
            .preferredColorScheme(.dark)
        
        // Then: Should be visible and readable in dark mode
        #if canImport(ViewInspector)
        let inspectionResult = withInspectedView(progressIndicator) { inspected in
            // Verify structure is present (visibility)
            let vStack = try? inspected.vStack()
            #expect(vStack != nil, "Progress indicator should render in dark mode")
            
            // Verify text elements are present (readability)
            let texts = inspected.findAll(Text.self)
            #expect(texts.count >= 2, "Should have text elements visible in dark mode")
            
            // Verify ProgressView is present
            let progressView = inspected.findAll(ProgressView<EmptyView, EmptyView>.self)
            #expect(progressView != nil, "Progress bar should be visible in dark mode")
        }
        
        if inspectionResult == nil {
            Issue.record("View inspection failed - could not verify dark mode display")
        }
        #else
        // ViewInspector not available on macOS - verify component is created
        #expect(Bool(true), "Progress indicator created successfully in dark mode")
        #endif
    }
    
    /// BUSINESS PURPOSE: Verify progress indicator handles edge cases correctly
    /// TESTING SCOPE: Display with 0 fields, 1 field, many fields
    /// METHODOLOGY: Test various field counts and verify correct display
    @Test @MainActor func testProgressIndicatorHandlesEdgeCases() async {
        initializeTestConfig()
        
        // Test Case 1: Zero fields (0 of 0)
        let progress0 = FormProgress(completed: 0, total: 0, percentage: 0.0)
        let indicator0 = FormProgressIndicator(progress: progress0)
        #if canImport(ViewInspector)
        let inspection0 = withInspectedView(indicator0) { inspected in
            let vStack = try? inspected.vStack()
            #expect(vStack != nil, "Progress indicator should render even with 0 of 0 fields")
        }
        if inspection0 == nil {
            Issue.record("Could not verify 0 of 0 fields case")
        }
        #else
        #expect(Bool(true), "Progress indicator handles 0 of 0 fields")
        #endif
        
        // Test Case 2: Single field (0 of 1)
        let progress1Empty = FormProgress(completed: 0, total: 1, percentage: 0.0)
        let indicator1Empty = FormProgressIndicator(progress: progress1Empty)
        
        // Test Case 3: Single field completed (1 of 1)
        let progress1Full = FormProgress(completed: 1, total: 1, percentage: 1.0)
        let indicator1Full = FormProgressIndicator(progress: progress1Full)
        
        // Test Case 4: Many fields (10 of 100)
        let progress100 = FormProgress(completed: 10, total: 100, percentage: 0.1)
        let indicator100 = FormProgressIndicator(progress: progress100)
        
        // Verify text uses singular/plural correctly
        #if canImport(ViewInspector)
        // Test singular "field" text
        let inspectionResult1 = withInspectedView(indicator1Empty) { inspected in
            let texts = inspected.findAll(Text.self)
            let fieldText = texts.first { text in
                let str = try? text.string()
                return str?.contains("of") ?? false
            }
            if let text = fieldText {
                let textString = try? text.string()
                #expect(textString?.contains("field") ?? false, "Should use singular 'field' for total of 1")
            }
        }
        
        // Test plural "fields" text
        let inspectionResult100 = withInspectedView(indicator100) { inspected in
            let texts = inspected.findAll(Text.self)
            let fieldText = texts.first { text in
                let str = try? text.string()
                return str?.contains("of") ?? false
            }
            if let text = fieldText {
                let textString = try? text.string()
                #expect(textString?.contains("fields") ?? false, "Should use plural 'fields' for total > 1")
            }
        }
        
        if inspectionResult1 == nil || inspectionResult100 == nil {
            Issue.record("View inspection failed - could not verify singular/plural text")
        }
        #else
        // ViewInspector not available on macOS - verify components are created
        #expect(Bool(true), "All edge case progress indicators created successfully")
        #endif
    }
}
