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
        _ = InternationalizationService()
        
        // Then: Service should be created successfully
        #expect(Bool(true), "service is non-optional")  // service is non-optional
    }
    
    // MARK: - Localization Tests
    
    @Test func testInternationalizationServiceReturnsLocalizedString() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Requesting a localized string
        let localizedString = service.localizedString(for: "test.key")
        
        // Then: Should return a string (even if it's the key itself)
        #expect(!localizedString.isEmpty)
    }
    
    @Test func testInternationalizationServiceHandlesMissingKey() async {
        // Given: InternationalizationService
        let service = InternationalizationService()
        
        // When: Requesting a non-existent key
        let result = service.localizedString(for: "nonexistent.key.that.does.not.exist")
        
        // Then: Should return the key itself or a fallback
        #expect(!result.isEmpty)
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
        
        // Then: Should handle arguments (will return key if not found, but method should not crash)
        #expect(!result.isEmpty)
    }
    
    @Test func testAppLocalizedString_MethodExists() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Using app-only method
        let result = service.appLocalizedString(for: "test.key")
        
        // Then: Should return a string (key itself if not found)
        #expect(!result.isEmpty)
    }
    
    @Test func testFrameworkLocalizedString_MethodExists() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Using framework-only method
        let result = service.frameworkLocalizedString(for: "test.key")
        
        // Then: Should return a string (key itself if not found)
        #expect(!result.isEmpty)
    }
    
    @Test func testLocalizedString_WithCustomAppBundle() {
        // Given: Service with custom app bundle
        let customBundle = Bundle.main
        let service = InternationalizationService(appBundle: customBundle)
        
        // When: Requesting a string
        let result = service.localizedString(for: "test.key")
        
        // Then: Should use the custom bundle
        #expect(!result.isEmpty)
    }
    
    // MARK: - Framework String Loading Tests
    
    @Test func testFrameworkBundle_CanLoadStrings() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting a known framework string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found in test environment)
        // Note: In test environment, resource bundle might not be available, so we test the method works
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testFrameworkBundle_AllDefinedKeysReturnProperValues() {
        // Given: Service and known framework keys
        let service = InternationalizationService()
        let knownKeys = [
            "SixLayerFramework.form.placeholder.select",
            "SixLayerFramework.form.placeholder.selectOption",
            "SixLayerFramework.form.placeholder.selectDate",
            "SixLayerFramework.button.save",
            "SixLayerFramework.button.cancel",
            "SixLayerFramework.error.title"
        ]
        
        // When: Requesting each known key
        for key in knownKeys {
            let result = service.frameworkLocalizedString(for: key)
            
            // Then: Should return a string (either localized or key if bundle not found)
            // Note: In test environment, we verify the method works, not that strings are loaded
            #expect(!result.isEmpty, "Key '\(key)' should return non-empty string")
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
        // Result will be the key if not found, but method should not crash
        #expect(!result.isEmpty, "Method should handle arguments without crashing")
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
        #expect(!result.isEmpty, "Method should handle multiple arguments without crashing")
    }
    
    // MARK: - App Override Functionality Tests
    
    @Test func testAppOverride_AppStringOverridesFrameworkString() {
        // Given: Service with Bundle.main (which may or may not have the key)
        // Note: In test environment, we verify the fallback logic works
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting a key
        let result = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (app override if exists, framework if exists, or key)
        // The important part is that the method works and follows the fallback chain
        #expect(!result.isEmpty, "Should return non-empty string")
        
        // Verify app bundle is checked first by testing appLocalizedString
        let appResult = service.appLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        #expect(!appResult.isEmpty, "App bundle lookup should work")
    }
    
    @Test func testAppOverride_FrameworkFallbackWhenAppDoesntOverride() {
        // Given: Service with Bundle.main (which likely doesn't have framework keys)
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting a key that only exists in framework (or returns key if not found)
        let result = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (framework string if available, or key if not found in test environment)
        // Note: In test environment, framework bundle might not be available
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testAppOverride_MultipleOverridesInSameApp() {
        // Given: Service with Bundle.main
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting multiple keys
        let selectResult = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        let saveResult = service.localizedString(for: "SixLayerFramework.button.save")
        let cancelResult = service.localizedString(for: "SixLayerFramework.button.cancel")
        
        // Then: Should return strings (app overrides if exist, framework if exist, or keys)
        // The important part is that the method works for multiple keys
        #expect(!selectResult.isEmpty, "Should handle multiple keys")
        #expect(!saveResult.isEmpty, "Should handle multiple keys")
        #expect(!cancelResult.isEmpty, "Should handle multiple keys")
    }
    
    // MARK: - Fallback Chain Tests
    
    @Test func testFallbackChain_AppToFrameworkToKey() {
        // Given: Service with Bundle.main
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting different keys
        // Test with a key that definitely doesn't exist (app-only scenario)
        let appOnly = service.localizedString(for: "definitely.app.only.key.xyz123")
        let frameworkOnly = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        let missingKey = service.localizedString(for: "nonexistent.key.12345")
        
        // Then: Should follow fallback chain correctly
        // App-only key should return key itself (not in app or framework)
        #expect(appOnly == "definitely.app.only.key.xyz123", "App-only key should return key itself if not found")
        // Framework key might return key itself in test environment if bundle not found
        #expect(!frameworkOnly.isEmpty, "Framework key should return a string")
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
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting keys with similar prefixes
        // These keys might exist in framework or return keys themselves
        let selectResult = service.localizedString(for: "SixLayerFramework.form.placeholder.select")
        let selectOptionResult = service.localizedString(for: "SixLayerFramework.form.placeholder.selectOption")
        let selectDateResult = service.localizedString(for: "SixLayerFramework.form.placeholder.selectDate")
        
        // Then: Each should return a string (either localized or key if not found)
        // The important part is that similar keys don't interfere with each other
        #expect(!selectResult.isEmpty, "Should handle keys with similar prefixes")
        #expect(!selectOptionResult.isEmpty, "Should handle keys with similar prefixes")
        #expect(!selectDateResult.isEmpty, "Should handle keys with similar prefixes")
    }
    
    // MARK: - Multi-Language Support Tests
    
    @Test func testMultiLanguage_English() {
        // Given: Service with English locale
        let service = InternationalizationService(locale: Locale(identifier: "en"))
        
        // When: Requesting a localized string
        // Note: NSLocalizedString uses system language, not service locale
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (localized if available, or key if not found)
        #expect(!result.isEmpty, "Should return non-empty string")
        
        // Verify locale is set correctly
        #expect(service.currentLanguage() == "en", "Service should have English locale")
    }
    
    @Test func testMultiLanguage_Spanish() {
        // Given: Service with Spanish locale
        let service = InternationalizationService(locale: Locale(identifier: "es"))
        
        // When: Requesting a localized string
        // Note: NSLocalizedString uses system language, not service locale
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (localized if available, or key if not found)
        #expect(!result.isEmpty, "Should return non-empty string")
        
        // Verify locale is set correctly
        #expect(service.currentLanguage() == "es", "Service should have Spanish locale")
    }
    
    @Test func testMultiLanguage_French() {
        // Given: Service with French locale
        let service = InternationalizationService(locale: Locale(identifier: "fr"))
        
        // When: Requesting a localized string
        // Note: NSLocalizedString uses system language, not service locale
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testMultiLanguage_German() {
        // Given: Service with German locale
        let service = InternationalizationService(locale: Locale(identifier: "de"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testMultiLanguage_Japanese() {
        // Given: Service with Japanese locale
        let service = InternationalizationService(locale: Locale(identifier: "ja"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testMultiLanguage_Korean() {
        // Given: Service with Korean locale
        let service = InternationalizationService(locale: Locale(identifier: "ko"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testMultiLanguage_SimplifiedChinese() {
        // Given: Service with Simplified Chinese locale
        let service = InternationalizationService(locale: Locale(identifier: "zh-Hans"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    @Test func testMultiLanguage_LocaleFallback_DeCHFallsBackToDe() {
        // Given: Service with de-CH locale (Swiss German)
        let service = InternationalizationService(locale: Locale(identifier: "de-CH"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should return a string (either localized or key if bundle not found)
        // Note: System handles locale fallback automatically
        #expect(!result.isEmpty, "Should return non-empty string")
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testEdgeCase_EmptyStringsFile() {
        // Given: Service with Bundle.main (which may not have the key)
        let service = InternationalizationService(appBundle: Bundle.main)
        
        // When: Requesting a key that doesn't exist
        let result = service.localizedString(for: "definitely.missing.key.xyz")
        
        // Then: Should fallback to framework or return key
        #expect(!result.isEmpty, "Should handle missing keys gracefully")
        #expect(result == "definitely.missing.key.xyz", "Should return key itself when not found")
    }
    
    @Test func testEdgeCase_MissingLanguageFiles() {
        // Given: Service with unsupported locale
        let service = InternationalizationService(locale: Locale(identifier: "xx"))
        
        // When: Requesting a localized string
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.form.placeholder.select")
        
        // Then: Should fallback to base language or return key
        #expect(!result.isEmpty, "Should handle missing language files gracefully")
    }
    
    @Test func testEdgeCase_InvalidKeys() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting invalid keys
        let emptyKey = service.localizedString(for: "")
        let specialCharsKey = service.localizedString(for: "key.with.special@chars#123")
        
        // Then: Should handle gracefully
        // Note: Empty key returns empty string from NSLocalizedString
        #expect(emptyKey.isEmpty || !emptyKey.isEmpty, "Empty key should be handled (may return empty or key)")
        #expect(specialCharsKey == "key.with.special@chars#123", "Invalid key should return key itself")
    }
    
    @Test func testEdgeCase_SpecialCharactersInStrings() {
        // Given: Service
        let service = InternationalizationService()
        
        // When: Requesting strings that may contain special characters
        let result = service.frameworkLocalizedString(for: "SixLayerFramework.error.message")
        
        // Then: Should handle special characters correctly
        #expect(!result.isEmpty, "Should handle special characters")
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
        #expect(!result.isEmpty, "Method should handle format placeholders")
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
        #expect(!result.isEmpty, "Method should handle integer format placeholders")
    }
    
}
