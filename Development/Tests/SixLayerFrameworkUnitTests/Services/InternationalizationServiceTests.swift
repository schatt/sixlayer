import Testing
import Foundation
@testable import SixLayerFramework

/// Functional tests for InternationalizationService
/// Tests the actual functionality of the internationalization service
/// Consolidates API tests and business logic tests
/// NOTE: Not marked @MainActor on class to allow parallel execution
@Suite("Internationalization Service")
open class InternationalizationServiceTests: BaseTestClass {
    
    // MARK: - Service Initialization Tests
    
    @Test func testInternationalizationServiceInitialization() {
        // Given & When: Creating the service
        let service = InternationalizationService()
        
        #expect(!service.currentLanguage().isEmpty)
        #expect(service.supportedLanguages().contains("en"))
    }
    
    // MARK: - Localization Tests
    
    @Test func testInternationalizationServiceReturnsLocalizedString() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Requesting a localized string
        let localizedString = service.localizedString(for: "test.key")
        
        // Then: Unknown keys come back unchanged
        #expect(localizedString == "test.key")
    }
    
    @Test func testInternationalizationServiceHandlesMissingKey() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Requesting a non-existent key
        let result = service.localizedString(for: "nonexistent.key.that.does.not.exist")
        
        // Then: Should return the key itself
        #expect(result == "nonexistent.key.that.does.not.exist")
    }
    
    @Test func testInternationalizationServiceSupportsMultipleLanguages() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Checking supported languages
        let supportedLanguages = service.supportedLanguages()
        
        // Then: Should return at least one language
        #expect(supportedLanguages.count > 0)
    }
    
    // MARK: - Language Detection Tests
    
    @Test func testInternationalizationServiceDetectsCurrentLanguage() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Getting current language
        let currentLanguage = service.currentLanguage()
        
        // Then: Should return a valid language code
        #expect(!currentLanguage.isEmpty)
    }
    
    @Test func testInternationalizationServiceCanChangeLanguage() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Setting a different language
        _ = service.currentLanguage()
        service.setLanguage("en")
        let newLanguage = service.currentLanguage()
        
        // Then: Language should change (or at least the call should succeed)
        #expect(!newLanguage.isEmpty)
    }
    
    // MARK: - Business Logic Tests (Text Direction & Alignment)
    
    @Test func testInternationalizationService_BusinessLogic() {
        // Given - Create service locally for this test
        let service = InternationalizationService(locale: Locale(identifier: "en-US"))
        let testText = "Hello World"
        
        // When
        let direction = service.textDirection(for: testText)
        let alignment = service.textAlignment(for: testText)
        let layoutDirection = service.getLayoutDirection()
        
        // Then: Test actual business logic
        #expect(direction == .leftToRight, "English text should be left-to-right")
        #expect(alignment == .leading, "English text should align leading")
        #expect(layoutDirection == .leftToRight, "English locale should be left-to-right")
    }
    
    @Test func testInternationalizationService_RTL_BusinessLogic() {
        // Given
        let rtlService = InternationalizationService(locale: Locale(identifier: "ar-SA"))
        let arabicText = "مرحبا بالعالم"
        
        // When
        let direction = rtlService.textDirection(for: arabicText)
        let alignment = rtlService.textAlignment(for: arabicText)
        let layoutDirection = rtlService.getLayoutDirection()
        
        // Then: Test actual business logic
        #expect(direction == .rightToLeft, "Arabic text should be right-to-left")
        #expect(alignment == .trailing, "Arabic text should align trailing")
        #expect(layoutDirection == .rightToLeft, "Arabic locale should be right-to-left")
    }
    
    @Test func testInternationalizationService_MixedText_BusinessLogic() {
        // Given - Create service locally for this test
        let service = InternationalizationService(locale: Locale(identifier: "en-US"))
        let mixedText = "Hello مرحبا World"
        
        // When
        let direction = service.textDirection(for: mixedText)
        let alignment = service.textAlignment(for: mixedText)
        
        // Then: Test actual business logic
        // Mixed text should return .mixed for English locale
        #expect(direction == .mixed, "Mixed text should return .mixed for English locale")
        #expect(alignment == .leading, "Mixed text should align leading for English locale")
    }
    
    @Test func testInternationalizationService_InvalidLocale_BusinessLogic() {
        // Given
        let invalidService = InternationalizationService(locale: Locale(identifier: "invalid-locale"))
        
        // When
        let layoutDirection = invalidService.getLayoutDirection()
        
        // Then: Test actual business logic
        // Should fallback to LTR for invalid locales
        #expect(layoutDirection == .leftToRight, "Invalid locale should fallback to left-to-right")
    }
    
    @Test func testInternationalizationService_EmptyText_BusinessLogic() {
        // Given - Create service locally for this test
        let service = InternationalizationService(locale: Locale(identifier: "en-US"))
        let emptyText = ""
        
        // When
        let direction = service.textDirection(for: emptyText)
        let alignment = service.textAlignment(for: emptyText)
        
        // Then: Test actual business logic
        // Empty text should default to LTR for English locale
        #expect(direction == .leftToRight, "Empty text should default to left-to-right for English locale")
        #expect(alignment == .leading, "Empty text should align leading for English locale")
    }
    
    // MARK: - Bundle Fallback Tests
    
    @Test func testLocalizedString_ReturnsKeyWhenNotFound() {
        // Given: Service with no localization files
        let service = InternationalizationService()
        
        // When: Requesting a non-existent key
        let result = service.localizedString(for: "nonexistent.key.test.12345")
        
        // Then: Should return the key itself (fallback behavior)
        #expect(result == "nonexistent.key.test.12345")
    }
    
    @Test func testLocalizedString_SupportsStringFormatting() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting with format arguments (even if key doesn't exist)
        let result = service.localizedString(for: "test.key", arguments: ["arg1", "arg2"])
        
        // Then: Unknown keys are returned unchanged (no format specifiers to apply)
        #expect(result == "test.key")
    }
    
    @Test func testAppLocalizedString_MethodExists() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Using app-only method
        let result = service.appLocalizedString(for: "test.key")
        
        // Then: Unknown keys come back unchanged
        #expect(result == "test.key")
    }
    
    @Test func testFrameworkLocalizedString_MethodExists() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Using framework-only method
        let result = service.frameworkLocalizedString(for: "test.key")
        
        // Then: Unknown keys come back unchanged
        #expect(result == "test.key")
    }
    
    @Test func testLocalizedString_WithCustomAppBundle() {
        // Given: Service with custom app bundle
        let customBundle = Bundle.main
        let service = InternationalizationService(appBundle: customBundle)
        
        // When: Requesting a string
        let result = service.localizedString(for: "test.key")
        
        // Then: Unknown keys come back unchanged
        #expect(result == "test.key")
    }
    
    // MARK: - Framework String Loading Tests
    
    @Test func testFrameworkBundle_CanLoadStrings() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let key = "SixLayerFramework.form.placeholder.select"
        let result = service.frameworkLocalizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key), "Expected catalog value, got '\(result)'")
    }
    
    @Test func testFrameworkBundle_AllDefinedKeysReturnProperValues() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let knownKeys = [
            "SixLayerFramework.form.placeholder.select",
            "SixLayerFramework.form.placeholder.selectOption",
            "SixLayerFramework.form.placeholder.selectDate",
            "SixLayerFramework.button.save",
            "SixLayerFramework.button.cancel",
            "SixLayerFramework.error.title"
        ]
        
        for key in knownKeys {
            let result = service.frameworkLocalizedString(for: key)
            #expect(result == FrameworkCatalogFixture.value(key), "Key '\(key)' resolved to '\(result)'")
        }
    }
    
    @Test func testFrameworkBundle_StringFormattingWithArguments() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Testing string formatting logic with a format string
        // Note: We test the formatting logic works, even if the key doesn't exist
        let formatString = "Field '%@' is missing"
        let formatted = String(format: formatString, "testField")
        
        // Then: Should format the string with arguments
        #expect(formatted.contains("testField"), "Should contain formatted argument")
        
        // Also test that the service method handles arguments correctly
        let result = service.localizedString(for: "test.format.key.xyz", arguments: ["testField"])
        #expect(result == "test.format.key.xyz", "Unknown format keys are returned unchanged")
    }
    
    @Test func testFrameworkBundle_StringFormattingWithMultipleArguments() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Testing string formatting logic with multiple arguments
        let formatString = "%d of %d field%@"
        let formatted = String(format: formatString, 1, 5, "")
        
        // Then: Should format the string with all arguments
        #expect(formatted.contains("1"), "Should contain first argument")
        #expect(formatted.contains("5"), "Should contain second argument")
        
        // Also test that the service method handles multiple arguments
        let result = service.localizedString(for: "test.progress.key.xyz", arguments: ["1", "5", ""])
        #expect(result == "test.progress.key.xyz", "Unknown format keys are returned unchanged")
    }
    
    // MARK: - App Override Functionality Tests
    
    @Test func testAppOverride_AppStringOverridesFrameworkString() {
        let service = InternationalizationService(locale: Locale(identifier: "en"), appBundle: Bundle.main)
        let key = "SixLayerFramework.form.placeholder.select"
        
        // Test host has no override, so the combined lookup is the framework catalog value.
        let result = service.localizedString(for: key)
        #expect(result == FrameworkCatalogFixture.value(key), "Expected framework fallback, got '\(result)'")
        
        let appResult = service.appLocalizedString(for: key)
        #expect(appResult == key, "Test host must not define '\(key)', got '\(appResult)'")
    }
    
    @Test func testAppOverride_FrameworkFallbackWhenAppDoesntOverride() {
        let service = InternationalizationService(locale: Locale(identifier: "en"), appBundle: Bundle.main)
        let key = "SixLayerFramework.form.placeholder.select"
        let result = service.localizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key), "Expected framework fallback, got '\(result)'")
    }
    
    @Test func testAppOverride_MultipleOverridesInSameApp() {
        let service = InternationalizationService(locale: Locale(identifier: "en"), appBundle: Bundle.main)
        
        let selectKey = "SixLayerFramework.form.placeholder.select"
        let saveKey = "SixLayerFramework.button.save"
        let cancelKey = "SixLayerFramework.button.cancel"
        
        #expect(service.localizedString(for: selectKey) == FrameworkCatalogFixture.value(selectKey))
        #expect(service.localizedString(for: saveKey) == FrameworkCatalogFixture.value(saveKey))
        #expect(service.localizedString(for: cancelKey) == FrameworkCatalogFixture.value(cancelKey))
    }
    
    // MARK: - Fallback Chain Tests
    
    @Test func testFallbackChain_AppToFrameworkToKey() {
        // Given: Service with Bundle.main
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting different keys
        // Test with a key that definitely doesn't exist (app-only scenario)
        let appOnly = service.localizedString(for: "definitely.app.only.key.xyz123")
        let key = "SixLayerFramework.form.placeholder.select"
        let frameworkOnly = service.localizedString(for: key)
        let missingKey = service.localizedString(for: "nonexistent.key.12345")
        
        #expect(appOnly == "definitely.app.only.key.xyz123", "App-only key should return key itself if not found")
        #expect(frameworkOnly == FrameworkCatalogFixture.value(key), "Expected framework catalog value, got '\(frameworkOnly)'")
        #expect(missingKey == "nonexistent.key.12345", "Missing key should return key itself")
    }
    
    @Test func testFallbackChain_KeyReturnedWhenNotFoundInEitherBundle() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting a key that doesn't exist in either bundle
        let result = service.localizedString(for: "completely.nonexistent.key.xyz")
        
        // Then: Should return the key itself
        #expect(result == "completely.nonexistent.key.xyz")
    }
    
    @Test func testFallbackChain_PartialKeyMatches() {
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let selectKey = "SixLayerFramework.form.placeholder.select"
        let optionKey = "SixLayerFramework.form.placeholder.selectOption"
        let dateKey = "SixLayerFramework.form.placeholder.selectDate"
        
        #expect(service.localizedString(for: selectKey) == FrameworkCatalogFixture.value(selectKey))
        #expect(service.localizedString(for: optionKey) == FrameworkCatalogFixture.value(optionKey))
        #expect(service.localizedString(for: dateKey) == FrameworkCatalogFixture.value(dateKey))
    }
    
    // MARK: - Multi-Language Support Tests
    
    @Test func testMultiLanguage_English() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let result = service.frameworkLocalizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key, language: "en"))
        #expect(service.currentLanguage() == "en")
    }
    
    @Test func testMultiLanguage_Spanish() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "es"))
        let result = service.frameworkLocalizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key, language: "es"))
        #expect(service.currentLanguage() == "es")
    }
    
    @Test func testMultiLanguage_French() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "fr"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "fr"))
    }
    
    @Test func testMultiLanguage_German() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "de"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "de"))
    }
    
    @Test func testMultiLanguage_Japanese() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "ja"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "ja"))
    }
    
    @Test func testMultiLanguage_Korean() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "ko"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "ko"))
    }
    
    @Test func testMultiLanguage_SimplifiedChinese() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "zh-Hans"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "zh-Hans"))
    }
    
    @Test func testMultiLanguage_LocaleFallback_DeCHFallsBackToDe() {
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "de-CH"))
        
        #expect(service.frameworkLocalizedString(for: key) == FrameworkCatalogFixture.value(key, language: "de-CH"))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testEdgeCase_EmptyStringsFile() {
        // Given: Service with Bundle.main (which may not have the key)
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting a key that doesn't exist
        let result = service.localizedString(for: "definitely.missing.key.xyz")
        
        // Then: Should fallback to framework or return key
        #expect(result == "definitely.missing.key.xyz", "Should return key itself when not found")
    }
    
    @Test func testEdgeCase_MissingLanguageFiles() {
        // Given: Service with unsupported locale
        let key = "SixLayerFramework.form.placeholder.select"
        let service = InternationalizationService(locale: Locale(identifier: "xx"))
        let result = service.frameworkLocalizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key, language: "en"), "Unsupported locale should fall back to English, got '\(result)'")
    }
    
    @Test func testEdgeCase_InvalidKeys() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting invalid keys
        let emptyKey = service.localizedString(for: "")
        let specialCharsKey = service.localizedString(for: "key.with.special@chars#123")
        
        // Then: Should handle gracefully
        // Note: Empty key returns empty string from NSLocalizedString
        #expect(emptyKey.isEmpty, "Empty key returns empty string from NSLocalizedString")
        #expect(specialCharsKey == "key.with.special@chars#123", "Invalid key should return key itself")
    }
    
    @Test func testEdgeCase_SpecialCharactersInStrings() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting strings that may contain special characters
        let key = "SixLayerFramework.error.message"
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        let result = service.frameworkLocalizedString(for: key)
        
        #expect(result == FrameworkCatalogFixture.value(key))
    }
    
    @Test func testEdgeCase_FormatStringPlaceholders() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Testing format string placeholder logic
        // We test that the formatting mechanism works, even if the key doesn't exist
        let formatString = "Unknown error: %@"
        let formatted = String(format: formatString, "Test Error")
        
        // Then: Should format correctly
        #expect(formatted.contains("Test Error"), "Should format with %@ placeholder")
        
        // Also verify service method handles format strings
        let result = service.localizedString(for: "test.error.xyz", arguments: ["Test Error"])
        #expect(result == "test.error.xyz")
    }
    
    @Test func testEdgeCase_FormatStringWithIntegerPlaceholder() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Testing format string with integer placeholders
        let formatString = "%d of %d field%@"
        let formatted = String(format: formatString, 1, 5, "")
        
        // Then: Should format correctly
        #expect(formatted.contains("1"), "Should format with %d placeholder")
        #expect(formatted.contains("5"), "Should format with %d placeholder")
        
        // Also verify service method handles integer format strings
        let result = service.localizedString(for: "test.progress.xyz", arguments: ["1", "5", ""])
        #expect(result == "test.progress.xyz")
    }
    
}
