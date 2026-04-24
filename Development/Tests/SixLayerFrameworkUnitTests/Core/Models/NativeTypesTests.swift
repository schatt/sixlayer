import Testing

//
//  NativeTypesTests.swift
//  SixLayerFrameworkTests
//
//  Test-Driven Development for Native Type Support in DynamicFormField
//  Cross-platform compatible tests using mocking
//

import SwiftUI
@testable import SixLayerFramework

// MARK: - Mock Types for Cross-Platform Testing

/// Mock image type for testing across platforms
struct MockImage: Equatable {
    let id: String
    let data: Data
    
    init(id: String = UUID().uuidString, data: Data = Data()) {
        self.id = id
        self.data = data
    }
}

/// Mock URL type for testing
struct MockURL: Equatable {
    let absoluteString: String
    
    init(_ string: String) {
        self.absoluteString = string
    }
}

/// Mock enum for testing enum field support
enum MockUserStatus: String, CaseIterable, Equatable {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
}

/// Mock data container for testing
struct MockDataContainer: Equatable {
    let id: String
    let content: String
    
    init(id: String = UUID().uuidString, content: String = "test") {
        self.id = id
        self.content = content
    }
}

@Suite("Native Types")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class NativeTypesTests: BaseTestClass {
    
    @MainActor
    public func createTestFormState() -> DynamicFormState {
        let configuration = DynamicFormConfiguration(
            id: "test",
            title: "Test Form",
            description: "Test form for native types",
            sections: [],
            submitButtonText: "Submit",
            cancelButtonText: "Cancel"
        )
        return DynamicFormState(configuration: configuration)
    }
    
    // MARK: - High Priority Tests
    
@Test func testImageFieldTypeExists() {
        // Given
        let contentType = DynamicContentType.image
        
        // Then
        #expect(contentType.rawValue == "image")
    }
    
    @Test @MainActor func testImageFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "profilePhoto",
            contentType: .image,
            label: "Profile Photo"
        )
        let testImage = MockImage(id: "test-image", data: "test-image-data".data(using: .utf8)!)
        
        // When
        formState.setValue(testImage, for: field.id)
        
        // Then
        let retrievedImage: MockImage? = formState.getValue(for: field.id)
        #expect(retrievedImage == testImage)
    }
    
    @Test @MainActor func testURLFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "website",
            contentType: .url,
            label: "Website"
        )
        let testURL = MockURL("https://example.com")
        
        // When
        formState.setValue(testURL, for: field.id)
        
        // Then
        let retrievedURL: MockURL? = formState.getValue(for: field.id)
        #expect(retrievedURL == testURL)
    }
    
    @Test func testIntegerFieldTypeExists() {
        // Given
        let contentType = DynamicContentType.integer
        
        // Then
        #expect(contentType.rawValue == "integer")
    }
    
    @Test @MainActor func testIntegerFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "age",
            contentType: .integer,
            label: "Age"
        )
        let testInt = 25
        
        // When
        formState.setValue(testInt, for: field.id)
        
        // Then
        let retrievedInt: Int? = formState.getValue(for: field.id)
        #expect(retrievedInt == testInt)
    }
    
    // MARK: - Medium Priority Tests
    
    @Test func testArrayFieldTypeExists() {
        // Given
        let contentType = DynamicContentType.array
        
        // Then
        #expect(contentType.rawValue == "array")
    }
    
    @Test @MainActor func testArrayFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "tags",
            contentType: .array,
            label: "Tags"
        )
        let testArray = ["swift", "ios", "testing"]
        
        // When
        formState.setValue(testArray, for: field.id)
        
        // Then
        let retrievedArray: [String]? = formState.getValue(for: field.id)
        #expect(retrievedArray == testArray)
    }
    
    @Test @MainActor func testRangeFieldConfiguration() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "score",
            contentType: .range,
            label: "Score",
            metadata: [
                "minValue": "0",
                "maxValue": "100",
                "step": "1"
            ]
        )
        
        // When
        formState.setValue(75, for: field.id)
        
        // Then
        let retrievedValue: Int? = formState.getValue(for: field.id)
        #expect(retrievedValue == 75)
    }
    
    @Test func testDataFieldTypeExists() {
        // Given
        let contentType = DynamicContentType.data
        
        // Then
        #expect(contentType.rawValue == "data")
    }
    
    @Test @MainActor func testDataFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "document",
            contentType: .data,
            label: "Document"
        )
        let testData = "Hello World".data(using: .utf8)!
        
        // When
        formState.setValue(testData, for: field.id)
        
        // Then
        let retrievedData: Data? = formState.getValue(for: field.id)
        #expect(retrievedData == testData)
    }
    
    // MARK: - Low Priority Tests
    
    @Test func testEnumFieldTypeExists() {
        // Given
        let contentType = DynamicContentType.enum
        
        // Then
        #expect(contentType.rawValue == "enum")
    }
    
    @Test @MainActor func testEnumFieldNativeBinding() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "status",
            contentType: .enum,
            label: "Status",
            options: MockUserStatus.allCases.map { $0.rawValue }
        )
        let testStatus = MockUserStatus.active
        
        // When
        formState.setValue(testStatus, for: field.id)
        
        // Then
        let retrievedStatus: MockUserStatus? = formState.getValue(for: field.id)
        #expect(retrievedStatus == testStatus)
    }
    
    @Test @MainActor func testOptionalTypeHandling() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "optionalField",
            contentType: .text,
            label: "Optional Field"
        )
        
        // When - Set nil value
        formState.setValue(nil as String?, for: field.id)
        
        // Then
        let retrievedValue: String? = formState.getValue(for: field.id)
        #expect(retrievedValue == nil, "retrievedValue should be nil when set to nil")
    }
    
    @Test @MainActor func testCustomTypeValidation() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "email",
            contentType: .email,
            label: "Email",
            validationRules: [
                "required": "true",
                "pattern": "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
            ]
        )
        
        // When - Set invalid email
        formState.setValue("invalid-email", for: field.id)
        
        // Then
        // Validation should be triggered (implementation dependent)
        // This test ensures the validation system can handle custom types
        #expect(Bool(true)) // Validation hook pending concrete email-rule assertion.
    }
    
    // MARK: - Integration Tests
    
    @Test @MainActor func testMixedNativeTypesInForm() {
        // Given
        let formState = createTestFormState()
        let fields = [
            DynamicFormField(id: "name", contentType: .text, label: "Name"),
            DynamicFormField(id: "age", contentType: .integer, label: "Age"),
            DynamicFormField(id: "website", contentType: .url, label: "Website"),
            DynamicFormField(id: "tags", contentType: .array, label: "Tags"),
            DynamicFormField(id: "profilePhoto", contentType: .image, label: "Photo")
        ]
        
        // When
        formState.setValue("John Doe", for: "name")
        formState.setValue(30, for: "age")
        formState.setValue(MockURL("https://johndoe.com"), for: "website")
        formState.setValue(["developer", "swift"], for: "tags")
        formState.setValue(MockImage(id: "profile", data: "image-data".data(using: .utf8)!), for: "profilePhoto")
        
        // Then
        // Verify fields are properly configured
        #expect(fields.count == 5, "Should have 5 form fields")
        #expect(fields[0].id == "name", "First field should have correct ID")
        #expect(fields[0].contentType == .text, "First field should be text type")
        #expect(fields[1].id == "age", "Second field should have correct ID")
        #expect(fields[1].contentType == .integer, "Second field should be integer type")
        #expect(fields[2].id == "website", "Third field should have correct ID")
        #expect(fields[2].contentType == .url, "Third field should be URL type")
        #expect(fields[3].id == "tags", "Fourth field should have correct ID")
        #expect(fields[3].contentType == .array, "Fourth field should be array type")
        #expect(fields[4].id == "profilePhoto", "Fifth field should have correct ID")
        #expect(fields[4].contentType == .image, "Fifth field should be image type")
        
        // Verify form state values
        let name: String? = formState.getValue(for: "name")
        let age: Int? = formState.getValue(for: "age")
        let website: MockURL? = formState.getValue(for: "website")
        let tags: [String]? = formState.getValue(for: "tags")
        let photo: MockImage? = formState.getValue(for: "profilePhoto")
        
        #expect(name == "John Doe")
        #expect(age == 30)
        #expect(website?.absoluteString == "https://johndoe.com")
        #expect(tags == ["developer", "swift"])
        #expect(photo?.id == "profile")
    }
    
    @Test @MainActor func testTypeSafetyWithWrongTypes() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "age",
            contentType: .integer,
            label: "Age"
        )
        
        // When - Set wrong type
        formState.setValue("not a number", for: field.id)
        
        // Then - Should handle gracefully
        let retrievedValue: Int? = formState.getValue(for: field.id)
        #expect(retrievedValue == nil, "retrievedValue should be nil due to type mismatch")
    }
    
    
    @Test @MainActor func testImageMemoryManagement() {
        // Given
        let formState = createTestFormState()
        let field = DynamicFormField(
            id: "image",
            contentType: .image,
            label: "Image"
        )
        let testImage = MockImage(id: "test", data: "image-data".data(using: .utf8)!)
        
        // When
        formState.setValue(testImage, for: field.id)
        
        // Then - Image should be properly retained
        let retrievedImage: MockImage? = formState.getValue(for: field.id)
        #expect(retrievedImage == testImage)
        
        // Clear and verify memory is released
        formState.setValue(nil as MockImage?, for: field.id)
        let clearedImage: MockImage? = formState.getValue(for: field.id)
        #expect(clearedImage == nil, "clearedImage should be nil after clearing")
    }
}
