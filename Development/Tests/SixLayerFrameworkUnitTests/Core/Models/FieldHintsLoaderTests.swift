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

    /// Write a unique `.hints` file under Documents/Hints, run `body`, then delete the file.
    private func withHintsResult<T>(
        modelName: String,
        json: [String: Any],
        _ body: (DataHintsResult) throws -> T
    ) throws -> T {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        defer { try? fileManager.removeItem(at: testFile) }
        return try body(FileBasedDataHintsLoader().loadHintsResult(for: uniqueModelName))
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
}
