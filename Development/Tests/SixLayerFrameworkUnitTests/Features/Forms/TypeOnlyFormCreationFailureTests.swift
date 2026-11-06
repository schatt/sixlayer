//
//  TypeOnlyFormCreationFailureTests.swift
//  SixLayerFrameworkUnitTests
//
//  A type-only form whose entity cannot be created must show that failure.
//  It must not stay on "Creating form..." after onAppear (#601).
//

import Foundation
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import SixLayerFramework

private struct TypeOnlyCreationProbe601 {
    var title: String
}

@Suite("Type-only form creation failure (#601)", .hostedViewIsolation)
struct TypeOnlyFormCreationFailureTests {

    #if !os(visionOS) && !os(watchOS)
    @Test @MainActor func failedCreationShowsErrorInsteadOfSpinner() throws {
        let modelName = DataIntrospectionEngine.hintsModelName(for: TypeOnlyCreationProbe601.self)
        let hintsURL = try writeFullyDeclarativeHints(modelName: modelName)
        defer { try? FileManager.default.removeItem(at: hintsURL) }

        let analysis = DataIntrospectionEngine.analyzeFromType(TypeOnlyCreationProbe601.self)
        #expect(analysis != nil, "Probe must take the type-only form path")

        let view = IntelligentFormView.generateForm(for: TypeOnlyCreationProbe601.self)
        #expect(
            viewTreeContainsTypeName(view, fragment: "TypeOnlyFormWrapper"),
            "Type-only generation did not build TypeOnlyFormWrapper"
        )

        let hosted = TestSetupUtilities.hostRootPlatformView(
            view,
            forceLayout: true,
            exposeContentAccessibility: true
        )
        let rendered = hostedRenderedText(hosted)
        #expect(
            !rendered.contains("UIActivityIndicatorView") && rendered.contains(modelName),
            "Type-only creation failure stayed on the spinner. rendered=\(rendered.prefix(800))"
        )
    }
    #endif
}

@MainActor
private func writeFullyDeclarativeHints(modelName: String) throws -> URL {
    let fileManager = FileManager.default
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        throw NSError(
            domain: "TypeOnlyFormCreationFailureTests",
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

@MainActor
private func hostedRenderedText(_ hosted: Any?) -> String {
    #if canImport(UIKit)
    guard let view = hosted as? UIView else { return "" }
    var parts: [String] = []
    let selector = NSSelectorFromString("recursiveDescription")
    if view.responds(to: selector),
       let unmanaged = view.perform(selector),
       let description = unmanaged.takeUnretainedValue() as? String {
        parts.append(description)
    }
    appendUILabelText(view, into: &parts)
    return parts.joined(separator: "\n")
    #elseif canImport(AppKit)
    guard let view = hosted as? NSView else { return "" }
    return String(describing: view)
    #else
    return ""
    #endif
}

#if canImport(UIKit)
@MainActor
private func appendUILabelText(_ view: UIView, into parts: inout [String]) {
    if let label = view as? UILabel, let text = label.text {
        parts.append(text)
    }
    for subview in view.subviews {
        appendUILabelText(subview, into: &parts)
    }
}
#endif
