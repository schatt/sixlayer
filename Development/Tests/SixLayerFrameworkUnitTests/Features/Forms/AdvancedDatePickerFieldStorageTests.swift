import CoreData
import Foundation
import Testing

@testable import SixLayerFramework

/// #618: advanced date/time pickers must persist `Date`, not device-locale medium/short strings.
@Suite("AdvancedDatePickerFieldStorage")
@MainActor
struct AdvancedDatePickerFieldStorageTests {

    private func makeFormState() -> DynamicFormState {
        let configuration = DynamicFormConfiguration(id: "618", title: "618", sections: [])
        return DynamicFormState(configuration: configuration)
    }

    @Test func persist_storesDateNotLocaleMediumString() {
        let state = makeFormState()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        let de = Locale(identifier: "de_DE")

        AdvancedDatePickerFieldStorage.persist(ref, into: state, for: "when")

        let stored = state.fieldValues["when"]
        #expect(stored is Date, "pickers must store Date so Core Data does not depend on locale (#618)")
        #expect(stored as? Date == ref)

        let medium = DateFormatter()
        medium.locale = de
        medium.dateStyle = .medium
        medium.timeStyle = .none
        #expect(stored as? String != medium.string(from: ref))
    }

    @Test func load_readsDateAndLegacyLocaleString() {
        let state = makeFormState()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)

        state.setValue(ref, for: "asDate")
        #expect(AdvancedDatePickerFieldStorage.load(from: state, fieldID: "asDate") == ref)

        let de = Locale(identifier: "de_DE")
        let medium = DateFormatter()
        medium.locale = de
        medium.dateStyle = .medium
        medium.timeStyle = .none
        let legacy = medium.string(from: ref)
        state.setValue(legacy, for: "legacy")
        let loaded = AdvancedDatePickerFieldStorage.load(from: state, fieldID: "legacy")
        let expected = DynamicFormStoredDateValue.date(fromStoredValue: legacy, locale: de)
        #expect(loaded == expected)
    }

    @Test func persistedDate_storesOnCoreDataDateAttribute_underNonUSLocale() throws {
        let state = makeFormState()
        let ref = Date(timeIntervalSince1970: 1_700_000_000)
        AdvancedDatePickerFieldStorage.persist(ref, into: state, for: "when")

        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "Probe618"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        let when = NSAttributeDescription()
        when.name = "when"
        when.attributeType = .dateAttributeType
        when.isOptional = true
        entity.properties = [when]
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

        let created = try EntityCreationUtilities.createCoreDataEntity(
            entityName: "Probe618",
            values: state.fieldValues,
            context: context,
            locale: Locale(identifier: "de_DE")
        )
        let stored = try #require(created.value(forKey: "when") as? Date)
        #expect(abs(stored.timeIntervalSince1970 - ref.timeIntervalSince1970) < 1)
    }
}
