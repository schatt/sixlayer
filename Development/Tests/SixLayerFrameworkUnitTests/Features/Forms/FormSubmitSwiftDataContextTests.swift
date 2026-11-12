//
//  FormSubmitSwiftDataContextTests.swift
//  SixLayerFrameworkUnitTests
//
//  Form submit must save SwiftData models through an installed container, and
//  refuse the empty default store when none is installed (#603).
//

import Foundation
import SwiftUI
import Testing
#if canImport(SwiftData)
import SwiftData
#endif
@testable import SixLayerFramework

#if canImport(SwiftData)
@available(macOS 14.0, iOS 17.0, *)
@Model
final class FormSubmitSwiftDataProbe603 {
    var title: String

    init(title: String) {
        self.title = title
    }
}
#endif

@Suite("Form submit SwiftData context (#603)")
struct FormSubmitSwiftDataContextTests {

    #if canImport(SwiftData)
    @available(macOS 14.0, iOS 17.0, *)
    @Test @MainActor
    func submitSavesThroughInstalledContainer() throws {
        let schema = Schema([FormSubmitSwiftDataProbe603.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let probe = FormSubmitSwiftDataProbe603(title: "before")
        context.insert(probe)
        try context.save()

        probe.title = "after"
        #expect(context.hasChanges, "Unsaved edit should dirty the installed context")

        var onSubmitCalled = false
        IntelligentFormView.handleSubmit(
            initialData: probe,
            modelContext: nil,
            onSubmit: { _ in onSubmitCalled = true }
        )

        let stillDirty = context.hasChanges
        #expect(onSubmitCalled, "onSubmit should still run after auto-save")
        #expect(!stillDirty, "Submit should save through the model's installed context")
        #expect(probe.title == "after")
    }

    @available(macOS 14.0, iOS 17.0, *)
    @Test @MainActor
    func submitWithExplicitContextSaves() throws {
        let schema = Schema([FormSubmitSwiftDataProbe603.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let probe = FormSubmitSwiftDataProbe603(title: "before")
        context.insert(probe)
        try context.save()

        probe.title = "explicit"
        #expect(context.hasChanges)

        IntelligentFormView.handleSubmit(
            initialData: probe,
            modelContext: context,
            onSubmit: { _ in }
        )

        #expect(!context.hasChanges, "Explicit ModelContext should be used to save")
    }

    @available(macOS 14.0, iOS 17.0, *)
    @Test @MainActor
    func submitWithoutInstalledContextRefusesDefaultStore() throws {
        // Unregistered model: no modelContext, and no explicit context parameter.
        let probe = FormSubmitSwiftDataProbe603(title: "orphan")
        #expect(probe.modelContext == nil)

        var onSubmitCalled = false
        IntelligentFormView.handleSubmit(
            initialData: probe,
            modelContext: nil,
            onSubmit: { _ in onSubmitCalled = true }
        )

        #expect(onSubmitCalled, "onSubmit still runs; save is skipped")
        #expect(
            probe.modelContext == nil,
            "Refuse path must not open the empty default store / attach a context"
        )
    }

    @Test @MainActor
    func formActionsDoNotStoreAppleModelContext() {
        let view = IntelligentFormView.generateForm(
            for: FormModelContextProbe603(title: "actions"),
            onUpdate: { _ in },
            onCancel: {}
        )

        #expect(
            !formSubmitViewTreeStoresAppleModelContext(view),
            "Form actions must use EnvironmentValues.self + SwiftDataContextAccess, not \\.modelContext"
        )
    }
    #endif
}

private struct FormModelContextProbe603 {
    var title: String
}

@MainActor
private func formSubmitViewTreeStoresAppleModelContext(_ value: Any, depth: Int = 0) -> Bool {
    if depth > 14 { return false }
    if String(describing: type(of: value)) == "Environment<ModelContext>" {
        return true
    }
    let mirror = Mirror(reflecting: value)
    var count = 0
    for child in mirror.children {
        if count > 80 { break }
        count += 1
        if formSubmitViewTreeStoresAppleModelContext(child.value, depth: depth + 1) {
            return true
        }
    }
    return false
}
