//
//  FormModelContextEnvironmentTests.swift
//  SixLayerFrameworkUnitTests
//
//  Form views must not store `@Environment(\.modelContext)`. SwiftUI resolves that
//  key during view update, and the getter `try!`s an empty default store when the
//  host never installed a ModelContainer (#589).
//

import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

private struct FormModelContextProbe589 {
    var title: String
}

@Suite("Form modelContext environment (#589)")
struct FormModelContextEnvironmentTests {

    @Test @MainActor func dynamicFormDoesNotStoreModelContext() {
        let configuration = DynamicFormConfiguration(id: "589-probe", title: "Probe")
        let formState = DynamicFormState(configuration: configuration)
        let view = DynamicFormViewInner(
            formState: formState,
            configuration: configuration,
            onSubmit: { _ in },
            onEntityCreated: nil,
            onError: nil,
            entityType: nil,
            showImagePicker: .constant(false),
            isProcessingOCR: .constant(false),
            ocrError: .constant(nil),
            batchOCRRequest: .constant(nil)
        )

        #expect(
            !viewTreeStoresAppleModelContext(view),
            "DynamicFormViewInner stores \\.modelContext"
        )
    }

    @Test @MainActor func entityAutoSaveDoesNotStoreModelContext() {
        let view = IntelligentFormView.withEntityAutoSave(
            content: Text("Form"),
            entity: "core-data-record",
            autoSaveInterval: 3600,
            isDraft: false,
            onEntitySaved: { _ in }
        )

        #expect(
            !viewTreeStoresAppleModelContext(view),
            "EntityAutoSaveWrapper stores \\.modelContext"
        )
    }

    @Test @MainActor func typeOnlyFormDoesNotStoreModelContext() throws {
        let modelName = DataIntrospectionEngine.hintsModelName(for: FormModelContextProbe589.self)
        let hintsURL = try writeFullyDeclarativeHints(modelName: modelName)
        defer { try? FileManager.default.removeItem(at: hintsURL) }

        let analysis = DataIntrospectionEngine.analyzeFromType(FormModelContextProbe589.self)
        #expect(analysis != nil, "Probe must take the type-only form path")

        let view = IntelligentFormView.generateForm(for: FormModelContextProbe589.self)
        #expect(
            viewTreeContainsTypeName(view, fragment: "TypeOnlyFormWrapper"),
            "Type-only generation did not build TypeOnlyFormWrapper"
        )
        #expect(
            !viewTreeStoresAppleModelContext(view),
            "TypeOnlyFormWrapper stores \\.modelContext"
        )
    }
}

@MainActor
private func writeFullyDeclarativeHints(modelName: String) throws -> URL {
    let fileManager = FileManager.default
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        throw NSError(
            domain: "FormModelContextEnvironmentTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Documents directory unavailable"]
        )
    }
    let hintsDir = documentsURL.appendingPathComponent("Hints", isDirectory: true)
    try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
    let url = hintsDir.appendingPathComponent("\(modelName).hints")
    let json: [String: Any] = [
        "title": [
            "fieldType": "string",
            "isOptional": false
        ]
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
    try data.write(to: url, options: .atomic)
    return url
}

/// True when a stored `@Environment(\.modelContext)` is in the view value.
/// Declaring that property is enough for SwiftUI to resolve it on update (#589).
private func viewTreeStoresAppleModelContext(_ value: Any, depth: Int = 0) -> Bool {
    if depth > 14 { return false }
    if String(describing: type(of: value)) == "Environment<ModelContext>" {
        return true
    }
    let mirror = Mirror(reflecting: value)
    var count = 0
    for child in mirror.children {
        if count > 80 { break }
        count += 1
        if viewTreeStoresAppleModelContext(child.value, depth: depth + 1) {
            return true
        }
    }
    return false
}

private func viewTreeContainsTypeName(_ value: Any, fragment: String, depth: Int = 0) -> Bool {
    if depth > 14 { return false }
    if String(describing: type(of: value)).contains(fragment) {
        return true
    }
    let mirror = Mirror(reflecting: value)
    var count = 0
    for child in mirror.children {
        if count > 80 { break }
        count += 1
        if viewTreeContainsTypeName(child.value, fragment: fragment, depth: depth + 1) {
            return true
        }
    }
    return false
}
