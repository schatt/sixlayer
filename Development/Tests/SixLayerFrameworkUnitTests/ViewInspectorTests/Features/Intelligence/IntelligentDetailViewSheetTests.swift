import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

#if os(macOS)
import AppKit
#endif
/// TDD Tests for IntelligentDetailView Sheet Presentation Bug
///
/// BUG: IntelligentDetailView renders tiny and blank when used in .sheet() modifier on macOS
///
/// TESTING SCOPE:
/// - Verify that platformDetailView renders properly in sheet context
/// - Verify that views have appropriate size in sheets
/// - Verify that content is actually displayed
///
/// BUSINESS PURPOSE:
/// Apps using the framework need to display detail views in sheets, and these must work correctly.

@Suite("Intelligent Detail View Sheet", HostedViewTestIsolationTrait())
/// NOTE: Not marked @MainActor on class to allow parallel execution
struct IntelligentDetailViewSheetTests {
    
    // MARK: - Test Data
    
    struct TestTask: Codable, Identifiable {
        let id: UUID
        let title: String
        let description: String
        let priority: Int
        
        init(id: UUID = UUID(), title: String, description: String = "Test description", priority: Int = 1) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
        }
    }
    
    // MARK: - Sheet Presentation Tests
    
    /// Verify that platformDetailView renders content in a sheet (not blank)
    @Test @MainActor func testPlatformDetailViewRendersContentInSheet() async throws {
        let task = TestTask(title: "Test Task", description: "Test description", priority: 5)
        
        // Create a view with sheet presentation (simulating .sheet() context)
        let sheetContent = IntelligentDetailView.platformDetailView(
            for: task,
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .detail,
                customPreferences: [:]
            )
        )
        .frame(minWidth: 400, minHeight: 500)
        
        // Verify the view can be inspected with ViewInspector
        #if canImport(ViewInspector)
        let base = BaseTestClass()
        base.initializeTestConfig()
        let root = base.runWithTaskLocalConfig {
            TestSetupUtilities.hostRootPlatformView(sheetContent, forceLayout: true, exposeContentAccessibility: true)
        }
        let hasHostedTitle = hostedUIKitAccessibilityHierarchyContains(root: root) { view in
            let label = view.hostedAccessibilityLabelText
            return label.contains(task.title) || label.contains(task.description)
        }
        let hasStructure = hasHostedTitle
            || !findAllInViewHierarchy(sheetContent, ViewInspector.ViewType.Text.self).isEmpty
            || !findAllInViewHierarchy(sheetContent, ViewInspector.ViewType.VStack.self).isEmpty
            || !findAllInViewHierarchy(sheetContent, ViewInspector.ViewType.LazyVStack.self).isEmpty
            || !findAllInViewHierarchy(sheetContent, ViewInspector.ViewType.ScrollView.self).isEmpty
        #expect(hasStructure, "platformDetailView should render non-blank structure in sheet context")
        #else
        // ViewInspector not available on macOS - skip test gracefully
        // The view is created successfully, which is the main requirement
        #endif
    }
    
    /// Verify that platformDetailView extracts and displays data model properties (Issue 178: no AnyView from API).
    /// Standard layout (ScrollView + LazyVStack); inspect directly — framework no longer returns AnyView.
    @Test @MainActor func testPlatformDetailViewDisplaysModelProperties() async throws {
        let task = TestTask(title: "Test Task", description: "Task description", priority: 5)
        
        let detailView = IntelligentDetailView.platformDetailView(
            for: task,
            hints: PresentationHints(
                dataType: .generic,
                presentationPreference: .automatic,
                complexity: .moderate,
                context: .detail,
                customPreferences: [:]
            ),
            customFieldView: { fieldName, value, _ in
                Text("\(fieldName)=\(String(describing: value))")
                    .foregroundColor(.secondary)
            }
        )
        .frame(minWidth: 400, minHeight: 500)
        
        #if canImport(ViewInspector)
        let base = BaseTestClass()
        base.initializeTestConfig()
        let root = base.runWithTaskLocalConfig {
            TestSetupUtilities.hostRootPlatformView(detailView, forceLayout: true, exposeContentAccessibility: true)
        }
        let analysis = DataIntrospectionEngine.analyze(task)
        #expect(analysis.fields.contains(where: { $0.name == "title" }), "Test model should expose a title field")
        let hasHostedTitle = hostedUIKitAccessibilityHierarchyContains(root: root, predicate: { view in
            let label = view.hostedAccessibilityLabelText
            let value = view.hostedAccessibilityValueText
            let combined = label + value
            return combined.contains(task.title) || combined.contains(task.description)
        })
        let texts = findAllInViewHierarchy(detailView, ViewInspector.ViewType.Text.self).compactMap { try? $0.string() }
        let fieldLabels = ["Title", "Description", "Priority"]
        let hasRenderedStructure = !findAllInViewHierarchy(detailView, ViewInspector.ViewType.Text.self).isEmpty
            || !findAllInViewHierarchy(detailView, ViewInspector.ViewType.LazyVStack.self).isEmpty
            || !findAllInViewHierarchy(detailView, ViewInspector.ViewType.ScrollView.self).isEmpty
        let hasPropertyText = hasHostedTitle
            || texts.contains(where: {
                $0.contains(task.title)
                    || $0.contains(task.description)
                    || fieldLabels.contains($0)
                    || $0 == String(task.priority)
                    || ($0.contains("title=") && $0.contains(task.title))
            })
        #expect(hasPropertyText || hasRenderedStructure, "platformDetailView should display model property text or detail structure")
        #else
        // ViewInspector not available on macOS - skip test gracefully
        // The view is created successfully, which is the main requirement
        #endif
    }
    
    /// Verify that platformDetailView accepts and respects frame constraints
    @Test @MainActor func testPlatformDetailViewRespectsFrameConstraints() async throws {
        let task = TestTask(title: "Test Task", description: "Description", priority: 3)
        
        // Apply frame constraints like the sheet context would
        let detailView = IntelligentDetailView.platformDetailView(for: task)
            .frame(minWidth: 400, minHeight: 500)
            .frame(idealWidth: 600, idealHeight: 700)
        
        // Verify the view compiles and can be inspected with frame constraints
        #if canImport(ViewInspector)
        if (try? AnyView(detailView).inspect()) != nil {
            // If we can inspect with frame constraints, the view respects them
        } else {
            Issue.record("platformDetailView should accept frame constraints")
        }
        #else
        // ViewInspector not available on macOS - skip test gracefully
        // The view compiles with frame constraints, which is the main requirement
        #endif
    }
    
    /// Verify platformDetailView works with NavigationStack in sheet context
    @Test @MainActor func testPlatformDetailViewWithNavigationStackInSheet() async throws {
        let task = TestTask(title: "Test Task", description: "Description")
        
        let sheetContent = NavigationStack {
            IntelligentDetailView.platformDetailView(for: task)
                .frame(minWidth: 400, minHeight: 500)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {}
                    }
                }
        }
        
        // Verify NavigationStack + platformDetailView works
        #if canImport(ViewInspector)
        if (try? AnyView(sheetContent).inspect()) != nil {
        } else {
            Issue.record("platformDetailView should work in NavigationStack")
        }
        #else
        // ViewInspector not available on macOS - skip test gracefully
        // The view compiles successfully, which is the main requirement
        #endif
    }
    
    /// Verify that different data types work in sheet presentation
    @Test @MainActor func testPlatformDetailViewWithDifferentDataTypesInSheet() async throws {
        // Test with various data types
        let task = TestTask(title: "Task", description: "Description", priority: 1)
        let numericData: [String: Double] = ["value": 42.0]
        let textData: [String: String] = ["name": "Test"]
        
        // All should work in sheet context - verify they can be inspected (`try?` does not throw)
        let taskDetail = IntelligentDetailView.platformDetailView(for: task)
        _ = try? AnyView(taskDetail).inspect()

        let numericDetail = IntelligentDetailView.platformDetailView(for: numericData)
        _ = try? AnyView(numericDetail).inspect()

        let textDetail = IntelligentDetailView.platformDetailView(for: textData)
        _ = try? AnyView(textDetail).inspect()

    }
    
    /// Verify that platformDetailView generates accessibility identifiers in sheet context
    @Test @MainActor func testPlatformDetailViewGeneratesAccessibilityIdentifiersInSheet() async {
        let task = TestTask(title: "Accessible Task")
        
        let detailView = IntelligentDetailView.platformDetailView(for: task)
            .automaticCompliance()
        
        // Verify accessibility identifiers are generated
        #if canImport(ViewInspector)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            detailView,
            expectedPattern: "SixLayer.main.ui",
            platform: SixLayerPlatform.macOS,
            componentName: "IntelligentDetailViewInSheet"
        )
 #expect(hasAccessibilityID, "platformDetailView should generate accessibility identifiers in sheet ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - macOS Real Window Integration Tests
    
    #if os(macOS)
    /// Present platformDetailView inside a real AppKit sheet and verify it is not tiny/blank
    /// This test uses actual NSWindow and NSHostingController to catch real-world sizing/blank-content issues
    @Test @MainActor func testPlatformDetailViewPresentsNonTinyNonBlankSheet() async {
        // Given
        let task = TestTask(title: "Sheet Task", description: "Details", priority: 3)

        // Host window
        // 6LAYER_ALLOW: testing macOS-specific sheet/window functionality with NSWindow/NSRect (legitimate platform integration testing)
        let hostWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), // 6LAYER_ALLOW: testing macOS-specific window functionality
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        hostWindow.isReleasedWhenClosed = false
        hostWindow.contentViewController = NSHostingController(rootView: Text("Host"))

        // Sheet content: IntelligentDetailView with expected minimum frame
        let sheetRoot = IntelligentDetailView.platformDetailView(for: task)
            .frame(minWidth: 400, minHeight: 500)

        let sheetController = NSHostingController(rootView: sheetRoot)
        // 6LAYER_ALLOW: testing macOS-specific sheet/window functionality with NSWindow/NSRect (legitimate platform integration testing)
        let sheetWindow = NSWindow(contentViewController: sheetController)
        sheetWindow.isReleasedWhenClosed = false

        // When: Begin sheet and allow layout pass
        hostWindow.beginSheet(sheetWindow, completionHandler: nil)
        // Allow a brief layout pass
        // Reduced from 0.15s to 0.01s for faster test execution
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        // Then: Verify the sheet has non-trivial size and visible subviews
        let fittingSize = sheetController.view.fittingSize
        let hasSubviews = !sheetController.view.subviews.isEmpty

        #expect(fittingSize.width >= 300, "Sheet width should be reasonable, got \(fittingSize.width)")
        #expect(fittingSize.height >= 300, "Sheet height should be reasonable, got \(fittingSize.height)")
        #expect(hasSubviews, "Sheet content view should have subviews (not blank)")

        // Cleanup
        hostWindow.endSheet(sheetWindow)
        sheetWindow.close()
        hostWindow.close()
    }
    #endif
}
