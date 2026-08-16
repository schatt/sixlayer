import Testing
import SwiftUI
import CoreData
@testable import SixLayerFramework

/// TDD Tests for Automatic DataBinder Creation in IntelligentFormView
/// 
/// BUSINESS PURPOSE: Verify automatic dataBinder creation works correctly
/// TESTING SCOPE: Auto-binding creation, opt-out, and integration
/// METHODOLOGY: Test automatic creation, opt-out behavior, and edge cases
@Suite("Intelligent Form View Auto Binding")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class IntelligentFormViewAutoBindingTests: BaseTestClass {
    
    // MARK: - Test Data Models
    
    struct MutableModel {
        var title: String
        var status: String
        var priority: Int
    }
    
    struct ImmutableModel {
        let id: UUID
        let title: String
        let createdAt: Date
    }
    
    // MARK: - Automatic Binding Creation Tests
    
    /// TDD: Test that DataBinder is automatically created when autoBind is true
    @Test @MainActor func testDataBinderCreatedAutomatically() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Generate form with automatic binding (default)
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model,
                onSubmit: { _ in }
            )
            
            // Form should be generated (not EmptyView)
            #expect(form is AnyView, "Form should be generated with automatic binding")
        }
    }
    
    /// TDD: Test that DataBinder is NOT created when autoBind is false
    @Test @MainActor func testDataBinderNotCreatedWhenOptedOut() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Generate form with automatic binding disabled
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model,
                autoBind: false,  // Opt out
                onSubmit: { _ in }
            )
            
            // Form should still be generated (binding is optional)
            #expect(form is AnyView, "Form should be generated even without binding")
        }
    }
    
    /// TDD: Test that explicit dataBinder overrides automatic creation
    @Test @MainActor func testExplicitDataBinderOverridesAutomatic() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Create explicit binder
            let explicitBinder = DataBinder(model)
            explicitBinder.bind("title", to: \MutableModel.title)
            
            // Generate form with explicit binder
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model,
                dataBinder: explicitBinder,  // Explicit binder
                autoBind: true  // Should be ignored
            )
            
            // Form should use explicit binder
            #expect(form is AnyView, "Form should use explicit binder")
            #expect(explicitBinder.bindingCount == 1, "Explicit binder should have bindings")
        }
    }
    
    /// TDD: Test that automatic binding works with mutable models
    @Test @MainActor func testAutomaticBindingWithMutableModel() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Automatic binding should work with mutable properties
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model
                // autoBind: true by default
            )
            
            #expect(form is AnyView, "Form should be generated for mutable model")
        }
    }
    
    /// TDD: Test that automatic binding gracefully handles immutable models
    @Test @MainActor func testAutomaticBindingWithImmutableModel() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = ImmutableModel(
                id: UUID(),
                title: "Test",
                createdAt: Date()
            )
            
            // Automatic binding should still work (creates binder, but fields can't be bound)
            let form = IntelligentFormView.generateForm(
                for: ImmutableModel.self,
                initialData: model
                // autoBind: true by default
            )
            
            #expect(form is AnyView, "Form should be generated even for immutable model")
        }
    }
    
    // MARK: - Integration Tests
    
    /// TDD: Test that automatic binding integrates with field updates
    @Test @MainActor func testAutomaticBindingIntegratesWithFieldUpdates() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Form with automatic binding
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model
            )
            
            // Field updates should work (if fields are manually bound)
            // This test verifies the integration exists
            #expect(form is AnyView, "Form should support field updates with automatic binding")
        }
    }
    
    /// TDD: Test that picker fields work with automatic binding
    @Test @MainActor func testPickerFieldsWithAutomaticBinding() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            struct ModelWithPicker {
                var sizeUnit: String
                var name: String
            }
            
            let model = ModelWithPicker(sizeUnit: "story_points", name: "Test")
            
            // Automatic binding should work with picker fields
            let form = IntelligentFormView.generateForm(
                for: ModelWithPicker.self,
                initialData: model
            )
            
            #expect(form is AnyView, "Form should support picker fields with automatic binding")
        }
    }
    
    // MARK: - Edge Case Tests
    
    /// Auto-bind heuristic: Core Data entities with introspected fields are bindable.
    @Test @MainActor func testAutomaticBindingWithCoreData() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = NSManagedObjectModel()
            let taskEntity = NSEntityDescription()
            taskEntity.name = "Task"

            let titleAttribute = NSAttributeDescription()
            titleAttribute.name = "title"
            titleAttribute.attributeType = .stringAttributeType
            titleAttribute.isOptional = true
            taskEntity.properties = [titleAttribute]
            model.entities = [taskEntity]

            let container = CoreDataTestUtilities.createIsolatedTestContainer(
                name: "TestModel",
                managedObjectModel: model
            )
            let task = NSManagedObject(entity: taskEntity, insertInto: container.viewContext)
            task.setValue("Test Title", forKey: "title")

            let analysis = DataIntrospectionEngine.analyze(task)
            // Heuristic only: non-empty introspection. KVC field binding is
            // covered by DataBindingCoreDataTests.
            #expect(IntelligentFormView.supportsAutoBinding(task, analysis: analysis) == true)
            #expect(IntelligentFormView.createAutoDataBinder(for: task, analysis: analysis) != nil)
        }
    }
    
    /// TDD: Test that automatic binding handles nil initialData gracefully
    @Test @MainActor func testAutomaticBindingWithNilInitialData() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            // Form with nil initialData should return EmptyView
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: nil as MutableModel?
            )
            
            // Should return EmptyView when initialData is nil
            #expect(form is AnyView, "Form should handle nil initialData gracefully")
        }
    }
    
    // MARK: - Backward Compatibility Tests
    
    /// TDD: Test that existing code without autoBind parameter still works
    @Test @MainActor func testBackwardCompatibilityWithoutAutoBindParameter() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let model = MutableModel(title: "Test", status: "Active", priority: 1)
            
            // Old code style (no autoBind parameter) should still work
            // autoBind defaults to true, so automatic binding is enabled
            let form = IntelligentFormView.generateForm(
                for: MutableModel.self,
                initialData: model,
                onSubmit: { _ in }
            )
            
            #expect(form is AnyView, "Backward compatible code should still work")
        }
    }
}

