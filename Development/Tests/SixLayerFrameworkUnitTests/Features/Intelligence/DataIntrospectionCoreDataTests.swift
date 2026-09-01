import Testing
import CoreData
@testable import SixLayerFramework

/// TDD Tests for Core Data Introspection Bug
///
/// FOLLOWING PROPER TDD:
/// 1. RED: Test fails when bug exists (Mirror can't see @NSManaged properties)
/// 2. GREEN: Test passes after fix (NSEntityDescription introspection)
/// 3. REFACTOR: Clean up if needed
///
/// THE BUG: Mirror cannot see @NSManaged properties, so analysis returns empty fields
/// EXPECTED: Should detect Core Data entity properties using NSEntityDescription

@Suite("Data Introspection Core Data")
/// NOTE: Not marked @MainActor on class to allow parallel execution
struct DataIntrospectionCoreDataTests {
    
    /// Test that Core Data entities are detected and properly introspected
    @Test @MainActor func testCoreDataEntityReturnsProperAnalysis() throws {
        // GIVEN: A Core Data managed object with properties
        let model = NSManagedObjectModel()
        
        let taskEntity = NSEntityDescription()
        taskEntity.name = "Task"
        
        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = true
        
        let statusAttribute = NSAttributeDescription()
        statusAttribute.name = "status"
        statusAttribute.attributeType = .stringAttributeType
        statusAttribute.isOptional = true
        
        taskEntity.properties = [titleAttribute, statusAttribute]
        model.entities = [taskEntity]
        
        // Use isolated test container to prevent CloudKit sync and account service access
        let container = CoreDataTestUtilities.createIsolatedTestContainer(
            name: "TestModel",
            managedObjectModel: model
        )
        
        let context = container.viewContext
        let task = NSManagedObject(entity: taskEntity, insertInto: context)
        task.setValue("Test Title", forKey: "title")
        task.setValue("pending", forKey: "status")
        
        // WHEN: We analyze the Core Data entity
        let analysis = DataIntrospectionEngine.analyze(task)
        
        // THEN: Should detect all Core Data entity properties (title, status)
        let hasTitleField = analysis.fields.contains { $0.name == "title" }
        let hasStatusField = analysis.fields.contains { $0.name == "status" }
        
        #expect(hasTitleField, "Should detect 'title' field from Core Data entity")
        #expect(hasStatusField, "Should detect 'status' field from Core Data entity")
        #expect(analysis.fields.count >= 2, "Should detect at least 2 fields. Found \(analysis.fields.count)")
    }
    
    /// Test that Core Data field types are correctly inferred
    @Test @MainActor func testCoreDataFieldTypesAreCorrect() throws {
        let model = NSManagedObjectModel()
        
        let productEntity = NSEntityDescription()
        productEntity.name = "Product"
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        
        let priceAttr = NSAttributeDescription()
        priceAttr.name = "price"
        priceAttr.attributeType = .doubleAttributeType
        
        let inStockAttr = NSAttributeDescription()
        inStockAttr.name = "inStock"
        inStockAttr.attributeType = .booleanAttributeType
        
        productEntity.properties = [nameAttr, priceAttr, inStockAttr]
        model.entities = [productEntity]
        
        // Use isolated test container to prevent CloudKit sync and account service access
        let container = CoreDataTestUtilities.createIsolatedTestContainer(
            name: "TestModel",
            managedObjectModel: model
        )
        
        let product = NSManagedObject(entity: productEntity, insertInto: container.viewContext)
        
        let analysis = DataIntrospectionEngine.analyze(product)
        
        // Verify field types are correctly inferred
        let nameField = analysis.fields.first { $0.name == "name" }
        let priceField = analysis.fields.first { $0.name == "price" }
        let inStockField = analysis.fields.first { $0.name == "inStock" }
        
        #expect(nameField?.type == .string, "Name field should be .string type")
        #expect(priceField?.type == .number, "Price field should be .number type")
        #expect(inStockField?.type == .boolean, "InStock field should be .boolean type")
    }
    
    /// Test that regular (non-Core Data) objects still work with Mirror introspection
    @Test @MainActor func testRegularObjectsStillWorkWithMirror() {
        struct RegularStruct {
            let title: String
            let count: Int
            let isActive: Bool
        }
        
        let regularData = RegularStruct(title: "Test", count: 42, isActive: true)
        let analysis = DataIntrospectionEngine.analyze(regularData)
        
        // Regular structs should be detected by Mirror
        #expect(analysis.fields.count >= 3, "Should detect regular struct properties")
        #expect(analysis.fields.contains { $0.name == "title" }, "Should detect 'title' from regular struct")
    }
}

