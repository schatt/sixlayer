import Testing
import Foundation
@testable import SixLayerFramework

/// Tests for .xcstrings migration and compatibility
/// Verifies that InternationalizationService resolves catalog values, not raw keys.
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("XCStrings Migration")
open class XCStringsMigrationTests: BaseTestClass {
    
    private let selectKey = "SixLayerFramework.form.placeholder.select"
    
    @Test func testInternationalizationService_WorksWithXCStringsFormat() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let result = service.frameworkLocalizedString(for: selectKey)
        
        #expect(result == FrameworkCatalogFixture.value(selectKey))
    }
    
    @Test func testInternationalizationService_AllLanguagesWorkWithXCStrings() {
        let languages = ["en", "es", "fr", "de", "de-CH", "ja", "ko", "pl", "zh-Hans"]
        
        for languageCode in languages {
            let langService = InternationalizationService(locale: Locale(identifier: languageCode))
            let result = langService.frameworkLocalizedString(for: selectKey)
            
            #expect(
                result == FrameworkCatalogFixture.value(selectKey, language: languageCode),
                "Language \(languageCode) resolved to '\(result)'"
            )
        }
    }
    
    @Test func testInternationalizationService_StringFormattingWorksWithXCStrings() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let key = "SixLayerFramework.cloudkit.missingField"
        let result = service.frameworkLocalizedString(for: key, arguments: ["testField"])
        
        #expect(result == FrameworkCatalogFixture.formatted(key, arguments: ["testField"]))
    }
    
    @Test func testInternationalizationService_FallbackChainWorksWithXCStrings() {
        let service = InternationalizationService(locale: Locale(identifier: "en"), appBundle: Bundle.main)
        let appResult = service.localizedString(for: selectKey)
        let frameworkResult = service.frameworkLocalizedString(for: selectKey)
        let missingResult = service.localizedString(for: "nonexistent.key.xyz123")
        
        #expect(appResult == FrameworkCatalogFixture.value(selectKey))
        #expect(frameworkResult == FrameworkCatalogFixture.value(selectKey))
        #expect(missingResult == "nonexistent.key.xyz123")
    }
    
    @Test func testInternationalizationService_AllKnownKeysWorkWithXCStrings() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
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
        
        for key in knownKeys {
            let result = service.frameworkLocalizedString(for: key)
            #expect(result == FrameworkCatalogFixture.value(key), "Key '\(key)' resolved to '\(result)'")
        }
    }
    
    @Test func testMigration_AllKeysPreserved() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let sampleKeys = [
            "SixLayerFramework.error.invalidLocale",
            "SixLayerFramework.error.languageNotSupported",
            "SixLayerFramework.form.placeholder.select",
            "SixLayerFramework.form.placeholder.selectOption",
            "SixLayerFramework.button.save",
            "SixLayerFramework.button.cancel",
            "SixLayerFramework.cloudkit.accountUnavailable",
            "SixLayerFramework.image.invalidImage",
            "SixLayerFramework.form.progressFields"
        ]
        
        for key in sampleKeys {
            let result = service.frameworkLocalizedString(for: key)
            #expect(result == FrameworkCatalogFixture.value(key), "Key '\(key)' resolved to '\(result)'")
        }
    }
    
    @Test func testMigration_StringFormattingPreserved() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        // %@ only. progressFields uses %d; arguments: [String] cannot format it.
        // FormProgressIndicator formats that key with Ints. The template itself is
        // locked in testMigration_AllKeysPreserved.
        let formatKeys = [
            ("SixLayerFramework.cloudkit.missingField", ["testField"]),
            ("SixLayerFramework.cloudkit.unknownError", ["Test Error"]),
            ("SixLayerFramework.error.message", ["Error Message"])
        ]
        
        for (key, args) in formatKeys {
            let result = service.frameworkLocalizedString(for: key, arguments: args)
            #expect(
                result == FrameworkCatalogFixture.formatted(key, arguments: args),
                "Format key '\(key)' resolved to '\(result)'"
            )
        }
    }
    
    @Test func testBackwardCompatibility_NSLocalizedStringWorks() {
        let result = NSLocalizedString(
            selectKey,
            bundle: InternationalizationService.frameworkBundle,
            comment: ""
        )
        
        #expect(result == FrameworkCatalogFixture.value(selectKey), "NSLocalizedString resolved to '\(result)'")
    }
    
    @Test func testBackwardCompatibility_AppOverrideStillWorks() {
        let service = InternationalizationService(locale: Locale(identifier: "en"), appBundle: Bundle.main)
        let appResult = service.appLocalizedString(for: selectKey)
        let frameworkResult = service.frameworkLocalizedString(for: selectKey)
        let combinedResult = service.localizedString(for: selectKey)
        
        #expect(appResult == selectKey, "Test host must not override '\(selectKey)', got '\(appResult)'")
        #expect(frameworkResult == FrameworkCatalogFixture.value(selectKey))
        #expect(combinedResult == FrameworkCatalogFixture.value(selectKey))
    }
}
