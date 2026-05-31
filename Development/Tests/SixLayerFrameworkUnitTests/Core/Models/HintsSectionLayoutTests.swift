//
//  HintsSectionLayoutTests.swift
//  SixLayerFrameworkTests
//
//  Issue #310: Sendable hints section layouts vs runtime DynamicFormSection
//

import Testing
import Foundation
@testable import SixLayerFramework

@Suite("Hints Section Layout")
struct HintsSectionLayoutTests {

    private func assertSendable<T: Sendable>(_ value: T) {}

    @Test func testHintsSectionLayoutIsSendable() {
        let layout = HintsSectionLayout(
            id: "account",
            title: "Account",
            description: "Login details",
            fieldIds: ["username", "email"],
            layoutStyle: .vertical,
            isCollapsible: true,
            isCollapsed: false,
            metadata: nil
        )
        assertSendable(layout)
        #expect(layout.fieldIds == ["username", "email"])
    }

    @Test func testDataHintsResultIsSendable() {
        let result = DataHintsResult()
        assertSendable(result)
    }

    @Test func testParseHintsResultProducesSectionLayouts() throws {
        let modelName = "SectionLayouts_testParseHintsResultProducesSectionLayouts"
        let hintsJSON: [String: Any] = [
            "username": ["displayWidth": "medium"],
            "_sections": [
                [
                    "id": "basic-info",
                    "title": "Basic Information",
                    "description": "Your account details",
                    "fields": ["username", "email"],
                    "layoutStyle": "horizontal",
                    "isCollapsible": true,
                    "isCollapsed": false
                ]
            ]
        ]

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        defer { try? fileManager.removeItem(at: testFile) }

        let data = try JSONSerialization.data(withJSONObject: hintsJSON, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)

        let result = FileBasedDataHintsLoader().loadHintsResult(for: uniqueModelName)

        #expect(result.sectionLayouts.count == 1)
        let layout = result.sectionLayouts[0]
        #expect(layout.id == "basic-info")
        #expect(layout.title == "Basic Information")
        #expect(layout.description == "Your account details")
        #expect(layout.fieldIds == ["username", "email"])
        #expect(layout.layoutStyle == .horizontal)
        #expect(layout.isCollapsible == true)
        #expect(layout.isCollapsed == false)
    }

    @Test func testSectionBuilderBuildsFromSectionLayouts() {
        let fields = [
            DynamicFormField(id: "name", contentType: .text, label: "Name"),
            DynamicFormField(id: "email", contentType: .email, label: "Email")
        ]

        let layouts = [
            HintsSectionLayout(
                id: "basic-info",
                title: "Basic Information",
                fieldIds: ["name", "nonexistent", "email"],
                layoutStyle: .horizontal
            )
        ]

        let builtSections = SectionBuilder.buildSections(from: layouts, matching: fields)

        #expect(builtSections.count == 1)
        #expect(builtSections[0].fields.count == 2)
        #expect(builtSections[0].fields[0].id == "name")
        #expect(builtSections[0].fields[1].id == "email")
        #expect(builtSections[0].layoutStyle == .horizontal)
    }
}
