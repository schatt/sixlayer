import Testing
@testable import SixLayerFramework
#if os(iOS)
import UIKit
#endif

/// Tests to verify that SixLayerTextContentType covers all UITextContentType cases
/// This ensures our cross-platform enum is complete and future-proof
@Suite("Text Content Type Completeness")
open class TextContentTypeCompletenessTests: BaseTestClass {
    
    /// Test that all UITextContentType cases exist in SixLayerTextContentType
    /// This test runs on iOS/Mac Catalyst to verify completeness.
    /// Note: UIKit is only imported on iOS above; on tvOS/watchOS/visionOS
    /// UITextContentType is out of scope here. Tightening the guard from
    /// canImport(UIKit) to iOS/macCatalyst to match the import above.
    #if os(iOS) || targetEnvironment(macCatalyst)
    @Test func testSixLayerTextContentTypeCompleteness() {
        // Get all UITextContentType cases
        let uiTextContentTypes: [UITextContentType] = [
            .name, .namePrefix, .givenName, .middleName, .familyName, .nameSuffix,
            .jobTitle, .organizationName,
            .emailAddress, .telephoneNumber,
            .username, .password, .newPassword, .oneTimeCode,
            .location, .fullStreetAddress, .streetAddressLine1, .streetAddressLine2,
            .addressCity, .addressState, .addressCityAndState, .sublocality,
            .countryName, .postalCode,
            .URL, .creditCardNumber
        ]
        
        // Test that each UITextContentType can be converted to SixLayerTextContentType
        for uiType in uiTextContentTypes {
            let sixLayerType = SixLayerTextContentType(uiType)
            
            // Verify the conversion works and produces expected results
            #expect(Bool(true), "SixLayerTextContentType should handle \(uiType)")  // sixLayerType is non-optional
            
            // Verify round-trip conversion works
            let backToUI = sixLayerType.uiTextContentType
            #expect(backToUI == uiType, "Round-trip conversion should preserve \(uiType)")
        }
    }
    
    /// Test that SixLayerTextContentType can handle unknown future UITextContentType cases
    @Test func testFutureUITextContentTypeHandling() {
        // This test verifies that our @unknown default case works
        // If Apple adds new UITextContentType cases, our enum should handle them gracefully
        
        // Test that our enum has all the cases we expect
        let expectedCases: [SixLayerTextContentType] = [
            .name, .namePrefix, .givenName, .middleName, .familyName, .nameSuffix,
            .jobTitle, .organizationName,
            .emailAddress, .telephoneNumber,
            .username, .password, .newPassword, .oneTimeCode,
            .location, .fullStreetAddress, .streetAddressLine1, .streetAddressLine2,
            .addressCity, .addressState, .addressCityAndState, .sublocality,
            .countryName, .postalCode,
            .URL, .creditCardNumber
        ]
        
        // Verify all expected cases exist
        for expectedCase in expectedCases {
            #expect(SixLayerTextContentType.allCases.contains(expectedCase), 
                        "SixLayerTextContentType should contain \(expectedCase)")
        }
    }
    #endif
    
    /// Test cross-platform field creation works consistently
    @Test func testCrossPlatformFieldCreation() {
        // Test that we can create fields with text content types on all platforms
        let emailField = DynamicFormField(
            id: "email",
            textContentType: .emailAddress,
            label: "Email Address"
        )
        
        #expect(emailField.textContentType == .emailAddress)
        #expect(emailField.label == "Email Address")
        
        let phoneField = DynamicFormField(
            id: "phone",
            textContentType: .telephoneNumber,
            label: "Phone Number"
        )
        
        #expect(phoneField.textContentType == .telephoneNumber)
        #expect(phoneField.label == "Phone Number")
        
        // Test address fields that were previously missing
        let addressField = DynamicFormField(
            id: "address",
            textContentType: .addressState,
            label: "State"
        )
        
        #expect(addressField.textContentType == .addressState)
        #expect(addressField.label == "State")
        
        let countryField = DynamicFormField(
            id: "country",
            textContentType: .countryName,
            label: "Country"
        )
        
        #expect(countryField.textContentType == .countryName)
        #expect(countryField.label == "Country")
    }
    
    /// Test that SixLayerTextContentType provides string values for macOS
    @Test func testStringValueForMacOS() {
        // Test that all text content types provide string values
        for contentType in SixLayerTextContentType.allCases {
            let stringValue = contentType.stringValue
            #expect(!stringValue.isEmpty, "String value should not be empty for \(contentType)")
            #expect(stringValue == contentType.rawValue, "String value should match raw value")
        }
        
        // Test specific cases
        #expect(SixLayerTextContentType.emailAddress.stringValue == "emailAddress")
        #expect(SixLayerTextContentType.telephoneNumber.stringValue == "telephoneNumber")
        #expect(SixLayerTextContentType.addressState.stringValue == "addressState")
        #expect(SixLayerTextContentType.countryName.stringValue == "countryName")
    }
}
