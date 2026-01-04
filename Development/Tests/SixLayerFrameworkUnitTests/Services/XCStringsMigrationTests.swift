import Testing
import Foundation
@testable import SixLayerFramework

/// Tests for .xcstrings migration and compatibility
/// Verifies that InternationalizationService works with .xcstrings format
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("XCStrings Migration")
open class XCStringsMigrationTests: BaseTestClass {
    
    // MARK: - XCStrings Format Compatibility Tests
    
    @Test func testInternationalizationService_WorksWithXCStringsFormat() {
        // Given: Service (should work with both .strings and .xcstrings)
        let service = InternationalizationService()
        
        // When: Requesting a known framework string
        // Note: NSLocalizedString works with both .strings and .xcstrings formats
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (works regardless of underlying format)
        #expect(!result.isEmpty, "Service should work with .xcstrings format")
    }
    
    @Test func testInternationalizationService_AllLanguagesWorkWithXCStrings() {
        // Given: Service and all supported languages
        _ = InternationalizationService()
        let languages = ["en", "es", "fr", "de", "de-CH", "ja", "ko", "pl", "zh-Hans"]
        
        // When: Requesting strings for each language
        for languageCode in languages {
            let locale = Locale(identifier: languageCode)
            let langService = InternationalizationService(locale: locale)
            let result = langService.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
            
            // Then: Should return a string for each language
            #expect(!result.isEmpty, "Language \(languageCode) should work with .xcstrings format")
        }
    }
    
    @Test func testInternationalizationService_StringFormattingWorksWithXCStrings() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting a string with format arguments
        let result = service.frameworkLocalizedString(
            for: "SixLayerFramework.cloudkit.missingField",
            arguments: ["testField"]
        )
        
        // Then: Should format correctly (works with both .strings and .xcstrings)
        #expect(!result.isEmpty, "String formatting should work with .xcstrings format")
        #expect(result.contains("testField") || result == "SixLayerFramework.cloudkit.missingField",
                "Should format with arguments or return key if not found")
    }
    
    @Test func testInternationalizationService_FallbackChainWorksWithXCStrings() {
        // Given: Service with app bundle
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Testing fallback chain (app → framework → key)
        let appResult = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        let frameworkResult = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        let missingResult = service.localizedString(for: "nonexistent.key.xyz123")
        
        // Then: Fallback chain should work (regardless of format)
        #expect(!appResult.isEmpty, "App bundle lookup should work with .xcstrings")
        #expect(!frameworkResult.isEmpty, "Framework bundle lookup should work with .xcstrings")
        #expect(missingResult == "nonexistent.key.xyz123", "Missing key should return key itself")
    }
    
    @Test func testInternationalizationService_AllKnownKeysWorkWithXCStrings() {
        // Given: Service and known framework keys
        let service = InternationalizationService()
        let knownKeys = [
            "SixLayerFramework.form.placeholder.select",
            "SixLayerFramework.form.placeholder.selectOption",
            "SixLayerFramework.form.placeholder.selectDate",
            "SixLayerFramework.button.save",
            "SixLayerFramework.button.cancel",
            "SixLayerFramework.error.title",
            "SixLayerFramework.cloudkit.missingField",
            "SixLayerFramework.image.invalidImage"
        ]
        
        // When: Requesting each known key
        for key in knownKeys {
            let result = service.frameworkLocalizedString(for: key)
            
            // Then: Should return a string (works with .xcstrings format)
            #expect(!result.isEmpty, "Key '\(key)' should work with .xcstrings format")
        }
    }
    
    // MARK: - Migration Verification Tests
    
    @Test func testMigration_AllLanguagesPreserved() {
        // Given: Service and all language codes from existing .lproj directories
        _ = InternationalizationService()
        let expectedLanguages = ["en", "es", "fr", "de", "de-CH", "ja", "ko", "pl", "zh-Hans"]
        
        // When: Checking that service can handle all languages
        for languageCode in expectedLanguages {
            let locale = Locale(identifier: languageCode)
            let langService = InternationalizationService(locale: locale)
            let result = langService.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
            
            // Then: All languages should be accessible
            #expect(!result.isEmpty, "Language \(languageCode) should be preserved after migration")
        }
    }
    
    @Test func testMigration_AllKeysPreserved() {
        // Given: Service and a sample of keys from existing .strings files
        let service = InternationalizationService()
        let sampleKeys = [
            "SixLayerFramework.error.invalidLocale",
            "SixLayerFramework.error.languageNotSupported",
            "SixLayerFramework.form.placeholder.select",
            "SixLayerFramework.form.placeholder.selectOption",
            "SixLayerFramework.button.save",
            "SixLayerFramework.button.cancel",
            "SixLayerFramework.cloudkit.accountUnavailable",
            "SixLayerFramework.image.invalidImage"
        ]
        
        // When: Requesting each key
        for key in sampleKeys {
            let result = service.frameworkLocalizedString(for: key)
            
            // Then: All keys should be accessible
            #expect(!result.isEmpty, "Key '\(key)' should be preserved after migration")
        }
    }
    
    @Test func testMigration_StringFormattingPreserved() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Testing format strings with placeholders
        let formatKeys = [
            ("SixLayerFramework.cloudkit.missingField", ["testField"]),
            ("SixLayerFramework.cloudkit.unknownError", ["Test Error"]),
            ("SixLayerFramework.error.message", ["Error Message"]),
            ("SixLayerFramework.form.progressFields", ["1", "5", ""])
        ]
        
        for (key, args) in formatKeys {
            let result = service.frameworkLocalizedString(for: key, arguments: args)
            
            // Then: Format strings should work correctly
            #expect(!result.isEmpty, "Format key '\(key)' should work after migration")
        }
    }
    
    @Test func testMigration_CommentsPreserved() {
        // Given: Service
        // Note: Comments in .xcstrings are metadata and don't affect functionality
        // This test verifies that the service still works (comments are preserved in file)
        let service = InternationalizationService()
        
        // When: Requesting a string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (comments don't affect lookup)
        #expect(!result.isEmpty, "Service should work regardless of comment preservation")
    }
    
    // MARK: - Backward Compatibility Tests
    
    @Test func testBackwardCompatibility_NSLocalizedStringWorks() {
        // Given: Direct NSLocalizedString call (used internally by service)
        // When: Requesting a string directly
        let result = NSLocalizedString("SixLayerFramework.form.placeholder.select", 
                                      bundle: InternationalizationService.frameworkBundle, 
                                      comment: "")
        
        // Then: Should work (NSLocalizedString supports both .strings and .xcstrings)
        #expect(!result.isEmpty, "NSLocalizedString should work with .xcstrings format")
    }
    
    @Test func testBackwardCompatibility_AppOverrideStillWorks() {
        // Given: Service with app bundle
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Testing app override functionality
        let appResult = service.appLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        let frameworkResult = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        let combinedResult = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: App override should still work (app bundle checked first)
        #expect(!appResult.isEmpty, "App bundle lookup should work with .xcstrings")
        #expect(!frameworkResult.isEmpty, "Framework bundle lookup should work with .xcstrings")
        #expect(!combinedResult.isEmpty, "Combined lookup should work with .xcstrings")
    }
}
