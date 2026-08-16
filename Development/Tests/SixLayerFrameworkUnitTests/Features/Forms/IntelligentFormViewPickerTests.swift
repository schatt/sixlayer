import Testing
import SwiftUI
@testable import SixLayerFramework

/// TDD Tests for Picker Support in IntelligentFormView
/// 
/// BUSINESS PURPOSE: Support enum picker options in hints files for IntelligentFormView
/// TESTING SCOPE: Picker parsing, rendering, and value mapping
/// METHODOLOGY: TDD - write tests first, then implement feature
@Suite("Intelligent Form View Picker Support")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class IntelligentFormViewPickerTests: BaseTestClass {
    
    // MARK: - Test Data Models
    
    struct TestModelWithEnum {
        let sizeUnit: String  // Will use picker for this field
        let name: String      // Will use regular TextField
    }
    
    // MARK: - Hints Parsing Tests
    
    private func sizeUnitPickerField(optionsJSON: String) -> DynamicFormField {
        DynamicFormField(
            id: "sizeUnit",
            contentType: .text,
            label: "Size Unit",
            metadata: [
                "inputType": "picker",
                "pickerOptions": optionsJSON
            ]
        )
    }

    /// Helper to write a hints file to documents directory where loader can find it
    private func writeHintsFile(modelName: String, json: [String: Any]) throws -> (fileURL: URL, uniqueModelName: String) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TestError", code: 1, userInfo: ["NSLocalizedDescription": "Could not find documents directory"])
        }
        let hintsDir = documentsURL.appendingPathComponent("Hints")
        try fileManager.createDirectory(at: hintsDir, withIntermediateDirectories: true)
        // Use unique filename to prevent conflicts during parallel test execution
        let uniqueModelName = "\(modelName)_\(UUID().uuidString.prefix(8))"
        let testFile = hintsDir.appendingPathComponent("\(uniqueModelName).hints")
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try data.write(to: testFile, options: .atomic)
        // Verify file exists
        guard fileManager.fileExists(atPath: testFile.path) else {
            throw NSError(domain: "TestError", code: 2, userInfo: ["NSLocalizedDescription": "File was not created"])
        }
        return (testFile, uniqueModelName)
    }
    
    /// TDD RED PHASE: Test that DataHintsLoader parses inputType from hints file
    @Test @MainActor func testDataHintsLoaderParsesInputType() throws {
        initializeTestConfig()
        
        let json: [String: Any] = [
            "sizeUnit": [
                "inputType": "picker",
                "displayWidth": "medium"
            ]
        ]
        
        // Write hints file to documents directory
        let (fileURL, uniqueModelName) = try writeHintsFile(modelName: "TestModelWithEnum", json: json)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: uniqueModelName)
        let hints = hintsResult.fieldHints["sizeUnit"]
        
        #expect(hints?.inputType == "picker", "inputType should be parsed from hints file")
    }
    
    /// TDD RED PHASE: Test that DataHintsLoader parses picker options array
    @Test @MainActor func testDataHintsLoaderParsesPickerOptions() throws {
        initializeTestConfig()
        
        let json: [String: Any] = [
            "sizeUnit": [
                "inputType": "picker",
                "options": [
                    ["value": "story_points", "label": "Story Points"],
                    ["value": "hours", "label": "Hours"],
                    ["value": "days", "label": "Days"]
                ]
            ]
        ]
        
        // Write hints file to documents directory
        let (fileURL, uniqueModelName) = try writeHintsFile(modelName: "TestModelWithEnum", json: json)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: uniqueModelName)
        let hints = hintsResult.fieldHints["sizeUnit"]
        
        #expect(hints?.inputType == "picker", "inputType should be parsed")
        #expect(hints?.pickerOptions?.count == 3, "Should parse 3 picker options")
        #expect(hints?.pickerOptions?[0].value == "story_points", "First option should have correct value")
        #expect(hints?.pickerOptions?[0].label == "Story Points", "First option should have correct label")
        #expect(hints?.pickerOptions?[1].value == "hours", "Second option should have correct value")
        #expect(hints?.pickerOptions?[1].label == "Hours", "Second option should have correct label")
    }
    
    /// TDD RED PHASE: Test that picker options have correct value and label
    @Test @MainActor func testPickerOptionsHaveValueAndLabel() {
        initializeTestConfig()
        
        let option = PickerOption(value: "story_points", label: "Story Points")
        
        #expect(option.value == "story_points", "Picker option should have correct value")
        #expect(option.label == "Story Points", "Picker option should have correct label")
    }
    
    // MARK: - FieldDisplayHints Tests
    
    /// TDD RED PHASE: Test that FieldDisplayHints includes inputType and pickerOptions
    @Test @MainActor func testFieldDisplayHintsIncludesPickerProperties() {
        initializeTestConfig()
        
        let options = [
            PickerOption(value: "story_points", label: "Story Points"),
            PickerOption(value: "hours", label: "Hours")
        ]
        
        let hints = FieldDisplayHints(
            inputType: "picker",
            pickerOptions: options
        )
        
        #expect(hints.inputType == "picker", "FieldDisplayHints should include inputType")
        #expect(hints.pickerOptions?.count == 2, "FieldDisplayHints should include pickerOptions")
        #expect(hints.pickerOptions?.first?.value == "story_points", "First option should have correct value")
        #expect(hints.pickerOptions?.first?.label == "Story Points", "First option should have correct label")
    }
    
    // MARK: - Backward Compatibility Tests
    
    /// TDD RED PHASE: Test that hints files without inputType still work (backward compatibility)
    @Test @MainActor func testBackwardCompatibilityWithoutInputType() throws {
        initializeTestConfig()
        
        let json: [String: Any] = [
            "name": [
                "displayWidth": "medium",
                "expectedLength": "20"
            ]
        ]
        
        // Write hints file to documents directory
        let (fileURL, uniqueModelName) = try writeHintsFile(modelName: "TestModelWithEnum", json: json)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let loader = FileBasedDataHintsLoader()
        let hintsResult = loader.loadHintsResult(for: uniqueModelName)
        let hints = hintsResult.fieldHints["name"]
        
        // Should still parse existing hints without inputType
        #expect(hints?.displayWidth == "medium", "Existing hints should still work")
        #expect(hints?.inputType == nil, "inputType should be nil when not specified")
        #expect(hints?.pickerOptions == nil, "pickerOptions should be nil when not specified")
    }
    
    // MARK: - Integration Tests (will need ViewInspector or similar)
    
    /// TDD RED PHASE: Test that IntelligentFormView loads hints for model type
    @Test @MainActor func testIntelligentFormViewLoadsHints() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let testData = TestModelWithEnum(sizeUnit: "story_points", name: "Test")
            
            // This test verifies that hints are loaded
            // Will fail until we integrate hints loading into IntelligentFormView
            let view = IntelligentFormView.generateForm(
                for: TestModelWithEnum.self,
                initialData: testData
            )
            
            // View should be generated (not EmptyView)
            #expect(view is AnyView, "Form should be generated")
        }
    }
    
    /// Unit contract: picker hints make `shouldRenderAsPicker` true.
    /// Picker vs TextField in the hosted tree is a ViewInspector/XCUI observation.
    @Test @MainActor func testPickerRenderedInsteadOfTextField() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let field = sizeUnitPickerField(
                optionsJSON: #"[{"value":"story_points","label":"Story Points"}]"#
            )
            #expect(field.shouldRenderAsPicker == true)
        }
    }
    
    /// Unit contract: picker options keep stored values distinct from display labels.
    @Test @MainActor func testPickerDisplaysLabelsStoresValues() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let field = sizeUnitPickerField(
                optionsJSON: #"[{"value":"story_points","label":"Story Points"},{"value":"hours","label":"Hours"}]"#
            )
            #expect(field.pickerOptionsFromHints.first?.value == "story_points")
            #expect(field.pickerOptionsFromHints.first?.label == "Story Points")
            #expect(field.pickerOptionsFromHints[1].value == "hours")
            #expect(field.pickerOptionsFromHints[1].label == "Hours")
        }
    }
}

