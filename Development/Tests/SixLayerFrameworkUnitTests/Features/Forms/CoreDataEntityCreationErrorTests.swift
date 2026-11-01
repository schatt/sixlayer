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

@objc(CoreDataCreationProbe608)
private final class CoreDataCreationProbe608: NSManagedObject {}

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

    @Test func throwingCreatorUsesEntityClass() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["title": "kept"],
            context: context
        )
        #expect(type(of: created) == CoreDataCreationProbe608.self)
        #expect(created.value(forKey: "title") as? String == "kept")
    }

    @Test func blankCreatorUsesEntityClass() throws {
        let context = try makeProbeContext()
        let created = try #require(
            EntityCreationUtilities.createBlankCoreDataEntity(
                entityName: "Probe608",
                context: context,
                fields: [],
                fieldHints: [:]
            )
        )
        #expect(type(of: created) == CoreDataCreationProbe608.self)
    }

    private func makeProbeContext() throws -> NSManagedObjectContext {
        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = true

        let entity = NSEntityDescription()
        entity.name = "Probe608"
        entity.managedObjectClassName = NSStringFromClass(CoreDataCreationProbe608.self)
        entity.properties = [title]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
}
#endif
