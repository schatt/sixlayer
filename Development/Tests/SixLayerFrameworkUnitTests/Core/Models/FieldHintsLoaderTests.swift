//
//  FieldHintsLoaderTests.swift
//  SixLayerFrameworkTests
//
//  Tests for loading hints from files
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Field Hints Loader")
struct FieldHintsLoaderTests {

    /// Write a unique `.hints` file into a temp fixture folder, run `body`, then remove the fixture.
    private func withHintsResult<T>(
        modelName: String,
        json: [String: Any],
        _ body: (DataHintsResult) throws -> T
    ) throws -> T {
        let (testFile, uniqueModelName) = try HintsTestFixtures.writeHintsFile(modelName: modelName, json: json)
        defer { HintsTestFixtures.cleanup(testFile) }
        return try body(HintsTestFixtures.loader(for: testFile).loadHintsResult(for: uniqueModelName))
    }

    // MARK: - JSON Parsing

    @Test func testParseHintsFromJSON() {
        let loader = FileBasedDataHintsLoader()
        let hints = loader.loadHints(for: "Test") // Will be empty since no file

        // Since we can't easily test file loading, we'll test the JSON structure
        // The loader should return empty dict for non-existent files
        #expect(hints.isEmpty == true) // No file exists
    }

    @Test func testHintsLoaderHasHints() {
        let loader = FileBasedDataHintsLoader()

        // Test with non-existent model
        let hasHints = loader.hasHints(for: "NonExistentModel")
        #expect(hasHints == false)
    }

    // MARK: - FieldDisplayHints from Metadata

    @Test func testDynamicFormFieldDisplayHintsFromMetadata() {
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username",
            metadata: [
                "expectedLength": "20",
                "displayWidth": "medium",
                "maxLength": "50",
                "minLength": "3",
                "showCharacterCounter": "true"
            ]
        )

        let hints = field.displayHints

        #expect(hints != nil, "displayHints should be present when metadata is set")
        #expect(hints?.expectedLength == 20)
        #expect(hints?.displayWidth == "medium")
        #expect(hints?.maxLength == 50)
        #expect(hints?.minLength == 3)
        #expect(hints?.showCharacterCounter == true)
    }

    @Test func testDynamicFormFieldDisplayHintsNoMetadata() {
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username"
        )

        let hints = field.displayHints
        #expect(hints == nil, "hints should be nil when no metadata")
    }

    @Test func testDynamicFormFieldDisplayHintsPartialMetadata() {
        let field = DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username",
            metadata: [
                "displayWidth": "wide",
                "showCharacterCounter": "false"
            ]
        )

        let hints = field.displayHints

        #expect(hints != nil, "displayHints should be present when metadata is set")
        #expect(hints?.displayWidth == "wide")
        #expect(hints?.showCharacterCounter == false)
        #expect(hints?.expectedLength == nil)
        #expect(hints?.maxLength == nil)
    }

    // MARK: - Hints File _sections Parsing Tests

    /// BUSINESS PURPOSE: Validate hints parser can parse _sections array from hints file
    /// TESTING SCOPE: Tests parsing _sections with layout groups from JSON
    /// METHODOLOGY: Create JSON with _sections array and verify parser extracts sections correctly
    @Test func testParseHintsWithSections() throws {
        let json: [String: Any] = [
            "_sections": [
                [
                    "id": "basic-info",
                    "title": "Basic Information",
                    "fields": ["name", "email", "phone"],
                    "layoutStyle": "horizontal"
                ],
                [
                    "id": "details",
                    "title": "Details",
                    "fields": ["bio", "address"],
                    "layoutStyle": "vertical"
                ]
            ],
            "username": [
                "displayWidth": "medium"
            ]
        ]

        try withHintsResult(modelName: "FieldHintsLoader_sections", json: json) { result in
            #expect(result.sectionLayouts.count == 2)
            #expect(result.sectionLayouts[0].id == "basic-info")
            #expect(result.sectionLayouts[0].title == "Basic Information")
            #expect(result.sectionLayouts[0].fieldIds == ["name", "email", "phone"])
            #expect(result.sectionLayouts[0].layoutStyle == .horizontal)
            #expect(result.sectionLayouts[1].id == "details")
            #expect(result.sectionLayouts[1].title == "Details")
            #expect(result.sectionLayouts[1].fieldIds == ["bio", "address"])
            #expect(result.sectionLayouts[1].layoutStyle == .vertical)
            #expect(result.fieldHints["username"]?.displayWidth == "medium")
        }
    }

    /// BUSINESS PURPOSE: Validate SectionBuilder handles missing fields gracefully
    /// TESTING SCOPE: Tests SectionBuilder when hints sections reference non-existent fields
    /// METHODOLOGY: Create hints sections with missing field IDs and verify SectionBuilder warns and filters
    @Test func testSectionBuilderWithMissingFields() {
        // Should warn when section references fields that don't exist
        let fields = [
            DynamicFormField(id: "name", contentType: .text, label: "Name"),
            DynamicFormField(id: "email", contentType: .email, label: "Email")
        ]

        // Create hints section that references a non-existent field
        let layouts = [
            HintsSectionLayout(
                id: "basic-info",
                title: "Basic Information",
                fieldIds: ["name", "nonexistent", "email"],
                layoutStyle: .horizontal
            )
        ]

        let builtSections = SectionBuilder.buildSections(
            from: layouts,
            matching: fields
        )

        // Should have one section with only valid fields
        #expect(builtSections.count == 1)
        #expect(builtSections[0].fields.count == 2) // name and email, not nonexistent
        #expect(builtSections[0].fields[0].id == "name")
        #expect(builtSections[0].fields[1].id == "email")
    }

    /// BUSINESS PURPOSE: Validate hints parser requires section titles
    /// TESTING SCOPE: Tests parsing _sections validates that title is required
    /// METHODOLOGY: Create JSON with section missing title and verify error handling
    @Test func testParseHintsSectionRequiresTitle() throws {
        let json: [String: Any] = [
            "_sections": [
                [
                    "id": "basic-info",
                    "fields": ["name", "email"],
                    "layoutStyle": "horizontal"
                ]
            ]
        ]

        try withHintsResult(modelName: "FieldHintsLoader_noTitle", json: json) { result in
            #expect(result.sectionLayouts.isEmpty, "Sections without title must be skipped")
        }
    }

    /// BUSINESS PURPOSE: Validate hints parser maintains field order from hints
    /// TESTING SCOPE: Tests parsing _sections preserves field order as listed in hints
    /// METHODOLOGY: Create JSON with fields in specific order and verify order is preserved
    @Test func testParseHintsPreservesFieldOrder() throws {
        let json: [String: Any] = [
            "_sections": [
                [
                    "id": "basic-info",
                    "title": "Basic Information",
                    "fields": ["name", "email", "phone"],
                    "layoutStyle": "horizontal"
                ]
            ]
        ]

        try withHintsResult(modelName: "FieldHintsLoader_order", json: json) { result in
            #expect(result.sectionLayouts.count == 1)
            #expect(result.sectionLayouts[0].fieldIds == ["name", "email", "phone"])
        }
    }

    /// BUSINESS PURPOSE: Validate hints parser handles backward compatibility
    /// TESTING SCOPE: Tests parsing hints files without _sections (existing files)
    /// METHODOLOGY: Create JSON without _sections and verify it still works
    @Test func testParseHintsBackwardCompatible() throws {
        let json: [String: Any] = [
            "username": [
                "displayWidth": "medium",
                "expectedLength": "20"
            ],
            "email": [
                "displayWidth": "wide"
            ]
        ]

        try withHintsResult(modelName: "FieldHintsLoader_compat", json: json) { result in
            #expect(result.sectionLayouts.isEmpty, "Legacy files without _sections yield no layouts")
            #expect(result.fieldHints["username"]?.displayWidth == "medium")
            #expect(result.fieldHints["username"]?.expectedLength == 20)
            #expect(result.fieldHints["email"]?.displayWidth == "wide")
        }
    }

    // MARK: - Injected search directories (#714)

    /// Creates a unique temporary `Hints/` folder. Caller removes its parent.
    private func makeTemporaryHintsFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("hints-714-\(UUID().uuidString)", isDirectory: true)
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

    /// BUSINESS PURPOSE: A library can carry its own `.hints` recipes (#714)
    /// TESTING SCOPE: `searchDirectories` is consulted, with no bundle or Documents copy present
    /// METHODOLOGY: Write `{folder}/{name}.hints` into an injected folder and load it by name
    @Test func injectedSearchDirectoryResolvesHintsFile() throws {
        let folder = try makeTemporaryHintsFolder()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        let name = uniqueEntityName("Hints714Injected")
        try writeHintsFile(["total": ["ocrHints": ["total"]]], named: name, in: folder)

        let loader = FileBasedDataHintsLoader(searchDirectories: [folder])

        #expect(loader.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["total"])
    }

    /// BUSINESS PURPOSE: Precedence is deterministic when several library folders are supplied (#714)
    /// TESTING SCOPE: Earlier entries in `searchDirectories` win over later ones
    @Test func injectedSearchDirectoriesAreCheckedInOrder() throws {
        let first = try makeTemporaryHintsFolder()
        let second = try makeTemporaryHintsFolder()
        defer {
            try? FileManager.default.removeItem(at: first.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: second.deletingLastPathComponent())
        }
        let name = uniqueEntityName("Hints714Order")
        try writeHintsFile(["total": ["ocrHints": ["first"]]], named: name, in: first)
        try writeHintsFile(["total": ["ocrHints": ["second"]]], named: name, in: second)

        let forward = FileBasedDataHintsLoader(searchDirectories: [first, second])
        let reversed = FileBasedDataHintsLoader(searchDirectories: [second, first])

        #expect(forward.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["first"])
        #expect(reversed.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["second"])
    }

    /// BUSINESS PURPOSE: Injecting a folder must not hide existing Documents hints (#714)
    /// TESTING SCOPE: A name absent from every injected folder still resolves from Documents/Hints
    /// METHODOLOGY: Empty injected folder + file in Documents/Hints; load must succeed
    @Test func missingInInjectedDirectoryFallsBackToDefaultLocations() throws {
        let empty = try makeTemporaryHintsFolder()
        defer { try? FileManager.default.removeItem(at: empty.deletingLastPathComponent()) }
        let documents = try #require(
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        )
        let documentsHints = documents.appendingPathComponent("Hints", isDirectory: true)
        try FileManager.default.createDirectory(at: documentsHints, withIntermediateDirectories: true)
        let name = uniqueEntityName("Hints714Fallback")
        try writeHintsFile(["total": ["ocrHints": ["fallback"]]], named: name, in: documentsHints)
        defer { try? FileManager.default.removeItem(at: documentsHints.appendingPathComponent("\(name).hints")) }

        let loader = FileBasedDataHintsLoader(searchDirectories: [empty])

        #expect(loader.loadHintsResult(for: name).fieldHints["total"]?.ocrHints == ["fallback"])
    }

    /// BUSINESS PURPOSE: `hasHints` must agree with `loadHintsResult` for injected folders (#714)
    @Test func hasHintsHonorsInjectedSearchDirectories() throws {
        let folder = try makeTemporaryHintsFolder()
        defer { try? FileManager.default.removeItem(at: folder.deletingLastPathComponent()) }
        let name = uniqueEntityName("Hints714Has")
        try writeHintsFile(["total": ["ocrHints": ["total"]]], named: name, in: folder)

        #expect(FileBasedDataHintsLoader(searchDirectories: [folder]).hasHints(for: name) == true)
        #expect(FileBasedDataHintsLoader().hasHints(for: name) == false)
    }

    /// BUSINESS PURPOSE: `entityName` is caller-influenced; it must not escape the search folder (#714 security note)
    /// TESTING SCOPE: `../` in a name must not resolve a `.hints` file that sits beside `Hints/`
    /// METHODOLOGY: Positive control proves the folder works; the traversal name must then yield nothing
    @Test func rejectsEntityNamesThatEscapeTheSearchDirectory() throws {
        let folder = try makeTemporaryHintsFolder()
        let root = folder.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: root) }
        let legit = uniqueEntityName("Hints714Legit")
        let escape = uniqueEntityName("Hints714Escape")
        try writeHintsFile(["total": ["ocrHints": ["legit"]]], named: legit, in: folder)
        try writeHintsFile(["total": ["ocrHints": ["escape"]]], named: escape, in: root)

        let loader = FileBasedDataHintsLoader(searchDirectories: [folder])

        // Positive control: a plain name in the injected folder resolves
        #expect(loader.loadHintsResult(for: legit).fieldHints["total"]?.ocrHints == ["legit"])
        // Traversal must not reach root/{escape}.hints
        #expect(loader.loadHintsResult(for: "../\(escape)").fieldHints.isEmpty)
        #expect(loader.hasHints(for: "../\(escape)") == false)
    }
}
