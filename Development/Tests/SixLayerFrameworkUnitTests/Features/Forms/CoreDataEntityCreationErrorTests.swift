//
//  CoreDataEntityCreationErrorTests.swift
//  SixLayerFrameworkUnitTests
//
//  Creating a Core Data entity must throw when the context cannot insert it.
//  insertNewObject raises NSInvalidArgumentException, which Swift catch cannot see (#606).
//

import Testing
#if canImport(CoreData)
import CoreData
@testable import SixLayerFramework

@Suite("Core Data entity creation errors (#606)")
@MainActor
struct CoreDataEntityCreationErrorTests {

    @Test func missingCoordinatorThrows() {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        #expect(throws: EntityCreationUtilities.CoreDataCreationError.unavailable(entityName: "Missing606")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Missing606",
                values: ["title": "value"],
                context: context
            )
        }
    }

    @Test func unknownEntityNameThrows() throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        #expect(throws: EntityCreationUtilities.CoreDataCreationError.unavailable(entityName: "Missing606")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Missing606",
                values: [:],
                context: context
            )
        }
    }
}
#endif
