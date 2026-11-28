//
//  HintsDocumentsDefaultAndCacheIsolationTests.swift
//  SixLayerFrameworkTests
//
//  #715: default hints loading reads the app bundle only (Documents is opt-in via
//  injection), and the hints cache is scoped to each DataHintsRegistry.
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Hints Documents Default And Cache Isolation (#715)")
struct HintsDocumentsDefaultAndCacheIsolationTests {

    /// Creates a unique temporary `Hints/` folder. Caller removes its parent.
    private func makeHintsFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("hints-715-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func writeHintsFile(_ json: [String: Any], named name: String, in folder: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: json)
        try data.write(to: folder.appendingPathComponent("\(name).hints"), options: .atomic)
    }

    private func uniqueEntityName(_ prefix: String) -> String {
        "\(prefix)_\(UUID().uuidString.prefix(8))"
    }

    /// BUSINESS PURPOSE: Production hints come from the app bundle; Documents is opt-in (#715)
    /// TESTING SCOPE: The default loader ignores `Documents/Hints`; an explicitly injected Documents `Hints/` folder still resolves
    /// METHODOLOGY: Fake Documents folder via FileManager subclass. Positive control proves the file exists and injection works.
    @Test func defaultLoaderDoesNotReadDocumentsHints() throws {
        let documentsRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("documents-715-\(UUID().uuidString)", isDirectory: true)
        let documentsHints = documentsRoot.appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: documentsHints, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: documentsRoot) }

        let name = uniqueEntityName("Hints715Default")
        try writeHintsFile(["total": ["ocrHints": ["documents"]]], named: name, in: documentsHints)
        let fileManager = FakeDocumentsFileManager(documentsURL: documentsRoot)

        // Positive control: explicit opt-in via searchDirectories resolves the file
        let optIn = FileBasedDataHintsLoader(fileManager: fileManager, searchDirectories: [documentsHints])
        #expect(optIn.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["documents"])

        // Default loader (no opt-in) must not read Documents
        let defaultLoader = FileBasedDataHintsLoader(fileManager: fileManager)
        #expect(defaultLoader.loadHintsResult(for: name).fieldHints.isEmpty)
        #expect(defaultLoader.hasHints(for: name) == false)
    }

    /// BUSINESS PURPOSE: A registry's preloaded hints never leak into another registry with a different loader (#715)
    /// TESTING SCOPE: Registry B does not receive registry A's preloaded result for the same model name
    /// METHODOLOGY: Same model name in two folders; A preloads; B must still load from its own folder
    @Test func registryCacheIsScopedToItsLoader() async throws {
        let folderA = try makeHintsFolder()
        let folderB = try makeHintsFolder()
        defer {
            try? FileManager.default.removeItem(at: folderA.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: folderB.deletingLastPathComponent())
        }
        let name = uniqueEntityName("Hints715Cache")
        try writeHintsFile(["total": ["ocrHints": ["from-a"]]], named: name, in: folderA)
        try writeHintsFile(["total": ["ocrHints": ["from-b"]]], named: name, in: folderB)

        let registryA = DataHintsRegistry(loader: FileBasedDataHintsLoader(searchDirectories: [folderA]))
        let registryB = DataHintsRegistry(loader: FileBasedDataHintsLoader(searchDirectories: [folderB]))

        await registryA.preloadHints(for: name)

        #expect(await registryA.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["from-a"])
        #expect(await registryB.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["from-b"])
    }
}
