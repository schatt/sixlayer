//
//  CoreDataEntityCreationErrorTests.swift
//  SixLayerFrameworkUnitTests
//
//  Creating a Core Data entity throws when the context cannot insert it (#606).
//  The object is an instance of the entity's class, and supplied values are stored (#608).
//  A bad property or value throws, or the blank creator returns nil, instead of raising (#613).
//  Strings the form stores for numbers, booleans, and dates are assigned as those types (#615).
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

    @Test func numericStringIsStored() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["count": "4"],
            context: context
        )
        #expect((created.value(forKey: "count") as? NSNumber)?.intValue == 4)
    }

    @Test func integralDoubleStringIsStoredAsInteger() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["count": "4.0"],
            context: context
        )
        #expect((created.value(forKey: "count") as? NSNumber)?.intValue == 4)
    }

    @Test func fractionalStringRejectedForInteger() throws {
        let context = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "count")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["count": "4.5"],
                context: context
            )
        }
    }

    @Test func doubleStringIsStored() throws {
        let context = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["amount": "4.5"],
            context: context
        )
        let stored = try #require(created.value(forKey: "amount") as? NSNumber)
        #expect(abs(stored.doubleValue - 4.5) < 0.000_001)
    }

    @Test func boolStringsAreStored() throws {
        let context = try makeProbeContext()
        let yes = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["flag": "true"],
            context: context
        )
        #expect((yes.value(forKey: "flag") as? NSNumber)?.boolValue == true)

        let no = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["flag": "false"],
            context: context
        )
        #expect((no.value(forKey: "flag") as? NSNumber)?.boolValue == false)
    }

    @Test func dateStringsAreStored() throws {
        let context = try makeProbeContext()
        let iso = "2024-06-15T14:30:00Z"
        let fromISO = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["when": iso],
            context: context
        )
        let expectedISO = try #require(DynamicFormStoredDateValue.date(fromStoredValue: iso))
        let storedISO = try #require(fromISO.value(forKey: "when") as? Date)
        #expect(abs(storedISO.timeIntervalSince1970 - expectedISO.timeIntervalSince1970) < 1)

        let medium = DateFormatter()
        medium.locale = Locale(identifier: "en_US_POSIX")
        medium.dateStyle = .medium
        medium.timeStyle = .none
        let mediumString = medium.string(from: Date(timeIntervalSince1970: 1_700_000_000))
        let fromMedium = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["when": mediumString],
            context: context
        )
        let expectedMedium = try #require(DynamicFormStoredDateValue.date(fromStoredValue: mediumString))
        let storedMedium = try #require(fromMedium.value(forKey: "when") as? Date)
        #expect(abs(storedMedium.timeIntervalSince1970 - expectedMedium.timeIntervalSince1970) < 86_400)
    }

    @Test func blankNumericStringDefaultIsStored() throws {
        let context = try makeProbeContext()
        let created = try #require(
            EntityCreationUtilities.createBlankCoreDataEntity(
                entityName: "Probe608",
                context: context,
                fields: [DataField(name: "count", type: .number, isOptional: true)],
                fieldHints: ["count": FieldDisplayHints(defaultValue: "4")]
            )
        )
        #expect((created.value(forKey: "count") as? NSNumber)?.intValue == 4)
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

        let amount = NSAttributeDescription()
        amount.name = "amount"
        amount.attributeType = .doubleAttributeType
        amount.isOptional = true

        let flag = NSAttributeDescription()
        flag.name = "flag"
        flag.attributeType = .booleanAttributeType
        flag.isOptional = true

        let when = NSAttributeDescription()
        when.name = "when"
        when.attributeType = .dateAttributeType
        when.isOptional = true

        let entity = NSEntityDescription()
        entity.name = "Probe608"
        entity.managedObjectClassName = NSStringFromClass(CoreDataCreationProbe608.self)
        entity.properties = [title, count, amount, flag, when]

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
