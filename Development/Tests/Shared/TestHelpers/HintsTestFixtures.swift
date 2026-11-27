//
//  HintsTestFixtures.swift
//  SixLayerFrameworkTests
//
//  Temp-folder `.hints` fixtures shared by unit tests (#715).
//  Fixtures live under the system temporary directory, never under the user's Documents folder.
//

import Foundation

enum HintsTestFixtures {

    /// Writes `{modelName}_{uuid8}.hints` into a fresh `<tmp>/hints-fixture-<uuid>/Hints/` folder.
    /// Returns the file URL and the unique model name to pass to loaders.
    static func writeHintsFile(modelName: String, json: [String: Any]) throws -> (fileURL: URL, uniqueModelName: String) {
        let hintsFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("hints-fixture-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: hintsFolder, withIntermediateDirectories: true)

        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let fileURL = hintsFolder.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: fileURL, options: .atomic)
        return (fileURL, uniqueModelName)
    }

    /// Loader that searches only the fixture's own `Hints/` folder.
    static func loader(for fileURL: URL) -> FileBasedDataHintsLoader {
        FileBasedDataHintsLoader(searchDirectories: [fileURL.deletingLastPathComponent()])
    }

    /// Removes the fixture's whole temp root (`<tmp>/hints-fixture-<uuid>/`).
    static func cleanup(_ fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent().deletingLastPathComponent())
    }
}
