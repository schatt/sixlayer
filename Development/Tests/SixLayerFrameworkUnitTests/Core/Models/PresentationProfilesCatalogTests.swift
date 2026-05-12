//
//  PresentationProfilesCatalogTests.swift
//  SixLayerFrameworkUnitTests
//
//  Tests for Hints/PresentationProfiles.hints loading (GitHub #277).
//

import Foundation
import Testing
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import SixLayerFramework

@Suite("Presentation profiles catalog")
struct PresentationProfilesCatalogTests {

    private func tempBundleWithProfiles(_ json: [String: Any]) throws -> (bundle: Bundle, tearDown: () -> Void) {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PresentationProfilesCatalogTests_\(UUID().uuidString)", isDirectory: true)
        let hintsDir = root.appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let fileURL = hintsDir.appendingPathComponent("PresentationProfiles.hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        try data.write(to: fileURL, options: .atomic)
        guard let bundle = Bundle(path: root.path) else {
            throw NSError(domain: "PresentationProfilesCatalogTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Bundle(path:) failed"
            ])
        }
        let tearDown = {
            try? FileManager.default.removeItem(at: root)
        }
        return (bundle, tearDown)
    }

    @Test func loadsKnownProfile() throws {
        let json: [String: Any] = [
            "profiles": [
                "vehicleCards": [
                    "_dataType": "collection",
                    "_presentationPreference": "cards",
                    "_complexity": "moderate",
                    "_context": "browse",
                    "_customPreferences": ["k": "v"]
                ] as [String: Any]
            ] as [String: Any]
        ]
        let (bundle, tearDown) = try tempBundleWithProfiles(json)
        defer { tearDown() }

        let catalog = PresentationProfilesCatalog()
        let hints = catalog.presentationHints(forProfileID: "vehicleCards", bundle: bundle)

        #expect(hints.dataType == .collection)
        #expect(hints.presentationPreference == .cards)
        #expect(hints.complexity == .moderate)
        #expect(hints.context == .browse)
        #expect(hints.customPreferences["k"] == "v")
        #expect(hints.fieldHints.isEmpty)
    }

    @Test func unknownProfileReturnsDefaults() throws {
        let json: [String: Any] = [
            "profiles": [
                "onlyProfile": [
                    "_presentationPreference": "list"
                ] as [String: Any]
            ] as [String: Any]
        ]
        let (bundle, tearDown) = try tempBundleWithProfiles(json)
        defer { tearDown() }

        let catalog = PresentationProfilesCatalog()
        let hints = catalog.presentationHints(forProfileID: "doesNotExist", bundle: bundle)

        #expect(hints.presentationPreference == .automatic)
        #expect(hints.dataType == .generic)
    }

    @Test func presentationHintsInitUsesCatalog() throws {
        let json: [String: Any] = [
            "profiles": [
                "p": [
                    "_presentationPreference": "grid",
                    "_complexity": "veryComplex"
                ] as [String: Any]
            ] as [String: Any]
        ]
        let (bundle, tearDown) = try tempBundleWithProfiles(json)
        defer { tearDown() }

        let catalog = PresentationProfilesCatalog()
        let hints = PresentationHints(presentationProfileID: "p", bundle: bundle, catalog: catalog)
        #expect(hints.presentationPreference == .grid)
        #expect(hints.complexity == .veryComplex)
    }

    @Test func missingProfilesKeyYieldsEmptyCatalog() throws {
        let json: [String: Any] = ["notProfiles": [:] as [String: Any]]
        let (bundle, tearDown) = try tempBundleWithProfiles(json)
        defer { tearDown() }

        let catalog = PresentationProfilesCatalog()
        let hints = catalog.presentationHints(forProfileID: "any", bundle: bundle)
        #expect(hints.presentationPreference == .automatic)
    }

    @Test func resetCacheAllowsReload() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PresentationProfilesCatalogTests_reload_\(UUID().uuidString)", isDirectory: true)
        let hintsDir = root.appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let fileURL = hintsDir.appendingPathComponent("PresentationProfiles.hints")
        defer { try? FileManager.default.removeItem(at: root) }

        let json1: [String: Any] = [
            "profiles": ["a": ["_presentationPreference": "list"] as [String: Any]] as [String: Any]
        ]
        try JSONSerialization.data(withJSONObject: json1).write(to: fileURL)
        guard let bundle = Bundle(path: root.path) else {
            Issue.record("Bundle(path:) failed")
            return
        }

        let catalog = PresentationProfilesCatalog()
        #expect(catalog.presentationHints(forProfileID: "a", bundle: bundle).presentationPreference == .list)

        let json2: [String: Any] = [
            "profiles": ["a": ["_presentationPreference": "cards"] as [String: Any]] as [String: Any]
        ]
        try JSONSerialization.data(withJSONObject: json2).write(to: fileURL)
        catalog.resetCache(bundle: bundle)
        #expect(catalog.presentationHints(forProfileID: "a", bundle: bundle).presentationPreference == .cards)
    }
}
