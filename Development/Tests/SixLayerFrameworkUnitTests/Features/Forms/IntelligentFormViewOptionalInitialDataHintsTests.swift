//
//  IntelligentFormViewOptionalInitialDataHintsTests.swift
//  SixLayerFramework
//
//  generateForm(for:initialData:) must look up hints by the model type, not Optional<T>.
//

import Foundation
import SwiftUI
import Testing
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

@testable import SixLayerFramework

/// Model whose hints file is named for the unwrapped type (`OptionalHintsProbe581.hints`).
private struct OptionalHintsProbe581 {
    var title: String
}

@Suite("Optional initialData hints lookup (#581)", HostedViewTestIsolationTrait())
open class IntelligentFormViewOptionalInitialDataHintsTests: BaseTestClass {

    @Test @MainActor func typeBasedFormWithInitialDataRendersHintedTextField() throws {
        initializeTestConfig()
        let modelName = String(describing: OptionalHintsProbe581.self)
            .components(separatedBy: ".").last ?? String(describing: OptionalHintsProbe581.self)
        let hintsFile = try writeHintsFile(modelName: modelName)
        defer { try? FileManager.default.removeItem(at: hintsFile) }

        let loaded = FileBasedDataHintsLoader().loadHintsResult(for: modelName)
        #expect(loaded.fieldHints["title"]?.fieldType == "string")

        let item = OptionalHintsProbe581(title: "Edit me")
        try runWithTaskLocalConfig {
            let instanceForm = IntelligentFormView.generateForm(
                for: item,
                onUpdate: { _ in }
            )
            let typeForm = IntelligentFormView.generateForm(
                for: OptionalHintsProbe581.self,
                initialData: item,
                onSubmit: { _ in }
            )

            #if os(iOS) || os(macOS)
            let instanceText = try hostedTextFieldText(instanceForm)
            let typeText = try hostedTextFieldText(typeForm)
            #expect(instanceText == "Edit me", "Instance overload should bind the hinted title field")
            #expect(
                typeText == "Edit me",
                "generateForm(for:initialData:) looked up hints as Optional<\(modelName)> and rendered no text field"
            )
            #else
            _ = instanceForm
            _ = typeForm
            #endif
        }
    }

    private func writeHintsFile(modelName: String) throws -> URL {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not find documents directory"
            ])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let testFile = hintsDir.appendingPathComponent("\(modelName).hints")
        let json: [String: Any] = [
            "title": [
                "fieldType": "string",
                "isOptional": false
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        return testFile
    }

    #if os(iOS) || os(macOS)
    @MainActor
    private func hostedTextFieldText<V: View>(_ view: V) throws -> String? {
        guard let root = TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true
        ) else {
            throw NSError(domain: "TestError", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Hosting root was nil"
            ])
        }
        #if os(iOS)
        guard let uiView = root as? UIView else { return nil }
        return firstTextFieldText(in: uiView)
        #elseif os(macOS)
        guard let nsView = root as? NSView else { return nil }
        return firstTextFieldText(in: nsView)
        #endif
    }
    #endif

    #if os(iOS)
    @MainActor
    private func firstTextFieldText(in view: UIView) -> String? {
        if let field = view as? UITextField {
            return field.text ?? ""
        }
        for child in view.subviews {
            if let text = firstTextFieldText(in: child) {
                return text
            }
        }
        return nil
    }
    #endif

    #if os(macOS)
    @MainActor
    private func firstTextFieldText(in view: NSView) -> String? {
        if let field = view as? NSTextField {
            return field.stringValue
        }
        for child in view.subviews {
            if let text = firstTextFieldText(in: child) {
                return text
            }
        }
        return nil
    }
    #endif
}
