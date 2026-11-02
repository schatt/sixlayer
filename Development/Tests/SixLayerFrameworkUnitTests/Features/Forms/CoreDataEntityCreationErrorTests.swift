//
//  CoreDataEntityCreationErrorTests.swift
//  SixLayerFrameworkUnitTests
//
//  Creating a Core Data entity throws when the context cannot insert it (#606).
//  The object is an instance of the entity's class, and supplied values are stored (#608).
//  A bad property or value throws, or the blank creator returns nil, instead of raising (#613).
//  Strings the form stores for numbers, booleans, and dates are assigned as those types (#615).
//  A string that does not fit an integer16, integer32, or float attribute is rejected (#619).
//  A partial decimal and an integer past Int.max are rejected without trapping.
//  A current-locale decimal or medium date is stored; other text is rejected (#621).
//

import Testing
#if canImport(CoreData)
import CoreData
@testable import SixLayerFramework

@objc(CoreDataCreationProbe608)
private final class CoreDataCreationProbe608: NSManagedObject {}

@Suite("Core Data entity creation (#606, #608, #613, #615, #621)")
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

    /// `-9223372036854775809` is not an `Int`. `Double` rounds it to `Int.min`,
    /// so a converter that trusts that double stores the wrong number.
    @Test func inexactIntegerStringIsRejected() throws {
        let context = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "count")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["count": "-9223372036854775809"],
                context: context
            )
        }
        #expect(context.insertedObjects.isEmpty)
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

    /// Decimal pad text and `DatePickerField`'s medium string use the locale, not POSIX (#621).
    @Test func localeNumberAndMediumDateAreStored() throws {
        let locale = Locale(identifier: "de_DE")
        let context = try makeProbeContext()
        let medium = DateFormatter()
        medium.locale = locale
        medium.dateStyle = .medium
        medium.timeStyle = .none
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        let mediumString = medium.string(from: ref)

        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["price": "4,5", "amount": "-4,5", "when": mediumString],
            context: context,
            locale: locale
        )

        let price = try #require(created.value(forKey: "price") as? NSNumber)
        #expect(price.decimalValue == Decimal(string: "4.5", locale: Locale(identifier: "en_US_POSIX")))
        let amount = try #require(created.value(forKey: "amount") as? NSNumber)
        #expect(abs(amount.doubleValue - (-4.5)) < 0.000_001)
        let storedDate = try #require(created.value(forKey: "when") as? Date)
        let expectedDate = try #require(medium.date(from: mediumString))
        #expect(abs(storedDate.timeIntervalSince1970 - expectedDate.timeIntervalSince1970) < 1)
    }

    /// POSIX text still stores when the form locale uses a comma and a different date style (#621).
    @Test func posixDecimalAndMediumDateStoreWhenLocaleUsesComma() throws {
        let locale = Locale(identifier: "de_DE")
        let medium = DateFormatter()
        medium.locale = Locale(identifier: "en_US_POSIX")
        medium.dateStyle = .medium
        medium.timeStyle = .none
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        let mediumString = medium.string(from: ref)

        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["price": "4.5", "when": mediumString],
            context: try makeProbeContext(),
            locale: locale
        )

        let price = try #require(created.value(forKey: "price") as? NSNumber)
        #expect(price.decimalValue == Decimal(string: "4.5", locale: Locale(identifier: "en_US_POSIX")))
        let storedDate = try #require(created.value(forKey: "when") as? Date)
        let expectedDate = try #require(medium.date(from: mediumString))
        #expect(abs(storedDate.timeIntervalSince1970 - expectedDate.timeIntervalSince1970) < 1)
    }

    /// A locale string that is not a complete number or date stays a string and is rejected.
    @Test func localeNumberAndDateThatDoNotParseAreRejected() throws {
        let locale = Locale(identifier: "de_DE")
        let priceContext = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "price")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["price": "4,5abc"],
                context: priceContext,
                locale: locale
            )
        }
        #expect(priceContext.insertedObjects.isEmpty)

        let posixContext = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "price")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["price": "4,5"],
                context: posixContext,
                locale: Locale(identifier: "en_US_POSIX")
            )
        }
        #expect(posixContext.insertedObjects.isEmpty)

        let dateContext = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "when")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["when": "not-a-date"],
                context: dateContext,
                locale: locale
            )
        }
        #expect(dateContext.insertedObjects.isEmpty)
    }

    @Test func blankLocaleDecimalDefaultIsStored() throws {
        let context = try makeProbeContext()
        let created = try #require(
            EntityCreationUtilities.createBlankCoreDataEntity(
                entityName: "Probe608",
                context: context,
                fields: [DataField(name: "price", type: .number, isOptional: true)],
                fieldHints: ["price": FieldDisplayHints(defaultValue: "4,5")],
                locale: Locale(identifier: "de_DE")
            )
        )
        let stored = try #require(created.value(forKey: "price") as? NSNumber)
        #expect(stored.decimalValue == Decimal(string: "4.5", locale: Locale(identifier: "en_US_POSIX")))
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

    @Test func decimalStringIsStoredAndPartialIsRejected() throws {
        let storedContext = try makeProbeContext()
        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["price": "4.5"],
            context: storedContext
        )
        let stored = try #require(created.value(forKey: "price") as? NSNumber)
        #expect(stored.decimalValue == Decimal(string: "4.5", locale: Locale(identifier: "en_US_POSIX")))

        let rejectedContext = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "price")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["price": "4abc"],
                context: rejectedContext
            )
        }
        #expect(rejectedContext.insertedObjects.isEmpty)
    }

    @Test func integerStringBeyondIntMaxIsRejected() throws {
        let context = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "count")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["count": "9223372036854775808"],
                context: context
            )
        }
        #expect(context.insertedObjects.isEmpty)
    }

    /// `setValue` wraps a too-wide integer instead of raising. A form string must not
    /// become that wrapped number.
    @Test func narrowIntegerStringsOutOfRangeAreRejected() throws {
        let tooWide16 = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "small")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["small": "32768"],
                context: tooWide16
            )
        }
        #expect(tooWide16.insertedObjects.isEmpty)

        let tooWide32 = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "mid")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["mid": "3000000000"],
                context: tooWide32
            )
        }
        #expect(tooWide32.insertedObjects.isEmpty)

        let stored16 = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["small": "32767"],
            context: try makeProbeContext()
        )
        #expect((stored16.value(forKey: "small") as? NSNumber)?.int16Value == 32767)

        let stored32 = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["mid": "2147483647"],
            context: try makeProbeContext()
        )
        #expect((stored32.value(forKey: "mid") as? NSNumber)?.int32Value == 2_147_483_647)
    }

    @Test func blankNarrowIntegerStringReturnsNil() throws {
        let context = try makeProbeContext()
        let created = EntityCreationUtilities.createBlankCoreDataEntity(
            entityName: "Probe608",
            context: context,
            fields: [DataField(name: "small", type: .number, isOptional: false)],
            fieldHints: ["small": FieldDisplayHints(defaultValue: "32768")]
        )
        #expect(created == nil)
        #expect(context.insertedObjects.isEmpty)
    }

    /// A finite `Double` past the float range is stored as infinity.
    @Test func floatOverflowStringIsRejected() throws {
        let rejected = try makeProbeContext()
        #expect(throws: EntityCreationUtilities.CoreDataCreationError.incompatibleValue(entityName: "Probe608", key: "ratio")) {
            try EntityCreationUtilities.createCoreDataEntity(
                entityName: "Probe608",
                values: ["ratio": "1e39"],
                context: rejected
            )
        }
        #expect(rejected.insertedObjects.isEmpty)

        let stored = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe608",
            values: ["ratio": "1.5"],
            context: try makeProbeContext()
        )
        let number = try #require(stored.value(forKey: "ratio") as? NSNumber)
        #expect(abs(number.floatValue - 1.5) < 0.000_001)
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

        let price = NSAttributeDescription()
        price.name = "price"
        price.attributeType = .decimalAttributeType
        price.isOptional = true

        let small = NSAttributeDescription()
        small.name = "small"
        small.attributeType = .integer16AttributeType
        small.isOptional = true

        let mid = NSAttributeDescription()
        mid.name = "mid"
        mid.attributeType = .integer32AttributeType
        mid.isOptional = true

        let ratio = NSAttributeDescription()
        ratio.name = "ratio"
        ratio.attributeType = .floatAttributeType
        ratio.isOptional = true

        let entity = NSEntityDescription()
        entity.name = "Probe608"
        entity.managedObjectClassName = NSStringFromClass(CoreDataCreationProbe608.self)
        entity.properties = [title, count, amount, flag, when, price, small, mid, ratio]

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
