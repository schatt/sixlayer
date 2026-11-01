//
//  CoreDataEntityCreationErrorTests.swift
//  SixLayerFrameworkUnitTests
//
//  Creating a Core Data entity throws when the context cannot insert it (#606).
//  The object is an instance of the entity's class, and supplied values are stored (#608).
//  A bad property or value throws, or the blank creator returns nil, instead of raising (#613).
//

import Testing
#if canImport(CoreData)
import CoreData
@testable import SixLayerFramework

@objc(CoreDataCreationProbe608)
private final class CoreDataCreationProbe608: NSManagedObject {}

@Suite("Core Data entity creation (#606, #608, #613)")
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

    @Test func unknownPropertyThrows() throws {
        let context = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.unknownProperty(entityName: "Probe608", key: "missing")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["missing": "x"],
                context: context
            )
        }
        #expect(context.insertedObjects.isEmpty)
    }

    @Test func incompatibleValueThrows() throws {
        let context = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "count")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["count": "nope"],
                context: context
            )
        }
        #expect(context.insertedObjects.isEmpty)
    }

    @Test func integerValueIsStored() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["count": 4],
            context: context
        )
        #expect((created.value(forKey: "count") as? NSNumber)?.intValue == 4)
    }

    @Test func hiddenUnknownPropertyIsSkipped() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["title": "kept", "secret": "x"],
            context: context,
            fieldHints: ["secret": FieldDisplayHints(isHidden: true)]
        )
        #expect(created.value(forKey: "title") as? String == "kept")
    }

    @Test func blankUnknownPropertyReturnsNil() throws {
        let context = try makeProbeContext()
        let created = EntityCreationUtilities.createBlankCoreDataEntity(
            entityName: "Probe608",
            context: context,
            fields: [DataField(name: "missing", type: .string)],
            fieldHints: ["missing": FieldDisplayHints(defaultValue: "x")]
        )
        #expect(created == nil)
        #expect(context.insertedObjects.isEmpty)
    }

    @Test func blankIncompatibleValueReturnsNil() throws {
        let context = try makeProbeContext()
        let created = EntityCreationUtilities.createBlankCoreDataEntity(
            entityName: "Probe608",
            context: context,
            fields: [DataField(name: "count", type: .number, isOptional: false)],
            fieldHints: ["count": FieldDisplayHints(defaultValue: "nope")]
        )
        #expect(created == nil)
        #expect(context.insertedObjects.isEmpty)
    }

    @Test func blankRelationshipDefaultReturnsNil() throws {
        let context = try makeRelationshipContext()
        let created = EntityCreationUtilities.createBlankCoreDataEntity(
            entityName: "Probe608",
            context: context,
            fields: [DataField(name: "owner", type: .relationship, isOptional: false)],
            fieldHints: ["owner": FieldDisplayHints()]
        )
        #expect(created == nil)
        #expect(context.insertedObjects.isEmpty)
    }

    private func makeProbeContext() throws -> NSManagedObjectContext {
        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = true

        let count = NSAttributeDescription()
        count.name = "count"
        count.attributeType = .integer64AttributeType
        count.isOptional = true

        let entity = NSEntityDescription()
        entity.name = "Probe608"
        entity.managedObjectClassName = NSStringFromClass(CoreDataCreationProbe608.self)
        entity.properties = [title, count]

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

    private func makeRelationshipContext() throws -> NSManagedObjectContext {
        let destination = NSEntityDescription()
        destination.name = "Dest613"
        destination.managedObjectClassName = "NSManagedObject"

        let owner = NSRelationshipDescription()
        owner.name = "owner"
        owner.destinationEntity = destination
        owner.minCount = 0
        owner.maxCount = 1
        owner.isOptional = true
        owner.deleteRule = .nullifyDeleteRule

        let entity = NSEntityDescription()
        entity.name = "Probe608"
        entity.managedObjectClassName = NSStringFromClass(CoreDataCreationProbe608.self)
        entity.properties = [owner]

        let model = NSManagedObjectModel()
        model.entities = [entity, destination]
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
