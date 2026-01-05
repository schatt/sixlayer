//
//  InternationalizationService.swift
//  SixLayerFramework
//
//  Internationalization & Localization Service
//  Provides RTL support, number formatting, date/time formatting, currency formatting
//

import Foundation
import SwiftUI

// MARK: - Internationalization Service

/// Main service for internationalization and localization
public class InternationalizationService: ObservableObject {
    
    // MARK: - Properties
    
    /// Current locale (published so views can observe changes)
    @Published public private(set) var locale: Locale
    
    // Formatters are computed to always use current locale
    private var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        return f
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = nil  // Clear any custom format when using styles
        return f
    }
    
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = nil  // Clear any custom format when using styles
        return f
    }
    
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .currency
        return f
    }
    
    private var percentageFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .percent
        return f
    }
    
    /// Framework bundle for loading framework-localized strings
    internal static let frameworkBundle: Bundle = {
        // Try Bundle.module first (available when compiled as Swift Package)
        // This is the modern way to access resources in SPM packages
        #if SWIFT_PACKAGE
        // When building as Swift Package, Bundle.module is available
        return Bundle.module
        #else
        // When building as Xcode framework, use Bundle(for:) approach
        let bundle = Bundle(for: InternationalizationService.self)
        
        // Try to find the resource bundle (SPM creates resource bundles with naming pattern: ModuleName_ModuleName.bundle)
        if let resourceURL = bundle.resourceURL {
            // Try common SPM resource bundle naming patterns
            let possibleNames = [
                "SixLayerFramework_SixLayerFramework.bundle",
                "SixLayerFramework.bundle"
            ]
            
            for bundleName in possibleNames {
                if let resourceBundle = Bundle(url: resourceURL.appendingPathComponent(bundleName)) {
                    return resourceBundle
                }
            }
        }
        
        // Fallback: the bundle itself contains resources
        return bundle
        #endif
    }()
    
    /// App bundle for loading app-localized strings (defaults to main bundle)
    private let appBundle: Bundle
    
    // MARK: - Initialization
    
    /// Initialize the internationalization service
    /// - Parameters:
    ///   - locale: The locale to use for formatting (defaults to current locale)
    ///   - appBundle: The app bundle to use for app-localized strings (defaults to Bundle.main)
    public init(locale: Locale = Locale.current, appBundle: Bundle = .main) {
        self.locale = locale
        self.appBundle = appBundle
        // Formatters are now computed properties, so no initialization needed
    }
    
    // MARK: - Text Direction
    
    /// Determine text direction for a given string
    /// - Parameter text: The text to analyze
    /// - Returns: Text direction (LTR, RTL, or mixed)
    public func textDirection(for text: String) -> TextDirection {
        guard !text.isEmpty else { return .leftToRight }
        
        // RTL character ranges
        let rtlRanges = [
            "\u{0590}"..."\u{05FF}", // Hebrew
            "\u{0600}"..."\u{06FF}", // Arabic
            "\u{0750}"..."\u{077F}", // Arabic Supplement
            "\u{08A0}"..."\u{08FF}", // Arabic Extended-A
            "\u{FB1D}"..."\u{FDFF}", // Arabic Presentation Forms-A
            "\u{FE70}"..."\u{FEFF}"  // Arabic Presentation Forms-B
        ]
        
        var rtlCount = 0
        var ltrCount = 0
        
        for scalar in text.unicodeScalars {
            let isRTL = rtlRanges.contains { range in
                range.contains(String(scalar))
            }
            
            if isRTL {
                rtlCount += 1
            } else if scalar.isASCII && scalar.properties.isAlphabetic {
                ltrCount += 1
            }
        }
        
        if rtlCount > 0 && ltrCount > 0 {
            return .mixed
        } else if rtlCount > 0 {
            return .rightToLeft
        } else {
            return .leftToRight
        }
    }
    
    /// Determine text alignment for a given string
    /// - Parameter text: The text to analyze
    /// - Returns: Text alignment (leading, trailing, or center)
    public func textAlignment(for text: String) -> TextAlignment {
        let direction = textDirection(for: text)
        
        switch direction {
        case .rightToLeft:
            return .trailing
        case .leftToRight, .mixed:
            return .leading
        }
    }
    
    // MARK: - Number Formatting
    
    /// Format a number according to locale
    /// - Parameters:
    ///   - number: The number to format
    ///   - decimalPlaces: Number of decimal places (optional)
    /// - Returns: Formatted number string
    public func formatNumber(_ number: Double, decimalPlaces: Int? = nil) -> String {
        let f = formatter
        if let decimalPlaces = decimalPlaces {
            f.minimumFractionDigits = decimalPlaces
            f.maximumFractionDigits = decimalPlaces
        } else {
            f.minimumFractionDigits = 0
            f.maximumFractionDigits = 2
        }
        f.roundingMode = .halfEven
        
        return f.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Format a number as percentage
    /// - Parameter number: The number to format (0.0 to 1.0)
    /// - Returns: Formatted percentage string
    public func formatPercentage(_ number: Double) -> String {
        percentageFormatter.string(from: NSNumber(value: number)) ?? "\(Int(number * 100))%"
    }
    
    /// Format a number as currency
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currencyCode: The currency code (e.g., "USD", "EUR")
    /// - Returns: Formatted currency string
    public func formatCurrency(_ amount: Double, currencyCode: String) -> String {
        currencyFormatter.currencyCode = currencyCode
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    // MARK: - Date Formatting
    
    /// Format a date according to locale
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The date format style
    /// - Returns: Formatted date string
    public func formatDate(_ date: Date, style: DateFormatStyle) -> String {
        let formatter = dateFormatter
        switch style {
        case .short:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            formatter.dateFormat = nil
        case .medium:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.dateFormat = nil
        case .long:
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.dateFormat = nil
        case .full:
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            formatter.dateFormat = nil
        case .custom:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.dateFormat = nil
        }
        
        return formatter.string(from: date)
    }
    
    /// Format a date with custom format
    /// - Parameters:
    ///   - date: The date to format
    ///   - format: Custom date format string
    /// - Returns: Formatted date string
    public func formatDate(_ date: Date, format: String) -> String {
        let formatter = dateFormatter
        // Clear styles first, then set custom format
        formatter.dateStyle = .none
        formatter.timeStyle = .none
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    /// Format a date as relative time
    /// - Parameter date: The date to format
    /// - Returns: Formatted relative date string
    public func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Time Formatting
    
    /// Format a time according to locale
    /// - Parameters:
    ///   - date: The date containing the time to format
    ///   - style: The time format style
    /// - Returns: Formatted time string
    public func formatTime(_ date: Date, style: TimeFormatStyle) -> String {
        let formatter = timeFormatter
        switch style {
        case .short:
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            formatter.dateFormat = nil
        case .medium:
            formatter.timeStyle = .medium
            formatter.dateStyle = .none
            formatter.dateFormat = nil
        case .long:
            formatter.timeStyle = .long
            formatter.dateStyle = .none
            formatter.dateFormat = nil
        case .full:
            formatter.timeStyle = .full
            formatter.dateStyle = .none
            formatter.dateFormat = nil
        case .custom:
            formatter.timeStyle = .medium
            formatter.dateStyle = .none
            formatter.dateFormat = nil
        }
        
        return formatter.string(from: date)
    }
    
    /// Format a time with custom format
    /// - Parameters:
    ///   - date: The date containing the time to format
    ///   - format: Custom time format string
    /// - Returns: Formatted time string
    public func formatTime(_ date: Date, format: String) -> String {
        let formatter = timeFormatter
        // Clear styles first, then set custom format
        formatter.dateStyle = .none
        formatter.timeStyle = .none
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // MARK: - Pluralization
    
    /// Pluralize a word based on count
    /// - Parameters:
    ///   - word: The word to pluralize
    ///   - count: The count
    /// - Returns: Pluralized word
    public func pluralize(_ word: String, count: Int) -> String {
        // Basic English pluralization rules
        if count == 1 {
            return word
        }
        
        // Handle common irregular plurals
        let irregularPlurals: [String: String] = [
            "child": "children",
            "person": "people",
            "man": "men",
            "woman": "women",
            "foot": "feet",
            "tooth": "teeth",
            "mouse": "mice",
            "goose": "geese",
            "ox": "oxen",
            "sheep": "sheep",
            "deer": "deer",
            "fish": "fish",
            "moose": "moose",
            "series": "series",
            "species": "species"
        ]
        
        if let irregular = irregularPlurals[word.lowercased()] {
            return irregular
        }
        
        // Handle words ending in -y
        if word.hasSuffix("y") && !word.hasSuffix("ay") && !word.hasSuffix("ey") && !word.hasSuffix("iy") && !word.hasSuffix("oy") && !word.hasSuffix("uy") {
            return String(word.dropLast()) + "ies"
        }
        
        // Handle words ending in -s, -sh, -ch, -x, -z
        if word.hasSuffix("s") || word.hasSuffix("sh") || word.hasSuffix("ch") || word.hasSuffix("x") || word.hasSuffix("z") {
            return word + "es"
        }
        
        // Handle words ending in -f or -fe
        if word.hasSuffix("f") {
            return String(word.dropLast()) + "ves"
        } else if word.hasSuffix("fe") {
            return String(word.dropLast(2)) + "ves"
        }
        
        // Default: add -s
        return word + "s"
    }
    
    // MARK: - Localized Strings
    
    /// Helper method to get localized string from a bundle for a specific locale
    private func getLocalizedString(from bundle: Bundle, for key: String, locale: Locale) -> String? {
        // Get the locale identifier (e.g., "en", "es", "zh-Hans", "de-CH")
        let localeIdentifier = locale.identifier
        
        // Extract language code (e.g., "zh" from "zh-Hans")
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        
        // Try locale identifiers in order of specificity:
        // 1. Full locale identifier (e.g., "zh-Hans", "de-CH")
        // 2. Language code with script/region (if different from identifier)
        // 3. Base language code (e.g., "zh" from "zh-Hans")
        // 4. English fallback
        
        var localeCodesToTry: [String] = []
        
        // Add full identifier if it's different from language code
        if localeIdentifier != languageCode {
            localeCodesToTry.append(localeIdentifier)
        }
        
        // Add language code
        localeCodesToTry.append(languageCode)
        
        // If language code contains a hyphen, try base language
        if languageCode.contains("-") {
            let baseLanguage = String(languageCode.prefix(while: { $0 != "-" }))
            if baseLanguage != languageCode {
                localeCodesToTry.append(baseLanguage)
            }
        }
        
        // Add English as final fallback
        if languageCode != "en" {
            localeCodesToTry.append("en")
        }
        
        // Try each locale code
        for localeCode in localeCodesToTry {
            if let stringsPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: localeCode) {
                // Load the strings dictionary from the file
                if let stringsDict = NSDictionary(contentsOfFile: stringsPath) as? [String: String],
                   let value = stringsDict[key] {
                    return value
                }
            }
        }
        
        return nil
    }
    
    /// Get localized string for a key with fallback support
    /// 
    /// Lookup order:
    /// 1. App bundle (allows app to override framework strings)
    /// 2. Framework bundle (framework default strings)
    /// 3. Return key itself if not found in either bundle
    ///
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: Optional arguments for string formatting
    /// - Returns: Localized string from app bundle, framework bundle, or the key itself
    public func localizedString(for key: String, arguments: [String] = []) -> String {
        var localizedString: String
        
        // Step 1: Try app bundle first (allows app to override framework strings)
        if let appLocalized = getLocalizedString(from: appBundle, for: key, locale: locale) {
            localizedString = appLocalized
        } else {
            // Step 2: Try framework bundle (framework default strings)
            if let frameworkLocalized = getLocalizedString(from: Self.frameworkBundle, for: key, locale: locale) {
                localizedString = frameworkLocalized
            } else {
                // Step 3: Not found in either bundle, return the key itself
                return key
            }
        }
        
        // Apply string formatting if arguments provided
        if arguments.isEmpty {
            return localizedString
        } else {
            return String(format: localizedString, arguments: arguments)
        }
    }
    
    /// Get localized string from app bundle only (no framework fallback)
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: Optional arguments for string formatting
    /// - Returns: Localized string from app bundle, or the key itself if not found
    public func appLocalizedString(for key: String, arguments: [String] = []) -> String {
        guard let localizedString = getLocalizedString(from: appBundle, for: key, locale: locale) else {
            return key
        }
        
        if arguments.isEmpty {
            return localizedString
        } else {
            return String(format: localizedString, arguments: arguments)
        }
    }
    
    /// Get localized string from framework bundle only (no app fallback)
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: Optional arguments for string formatting
    /// - Returns: Localized string from framework bundle, or the key itself if not found
    public func frameworkLocalizedString(for key: String, arguments: [String] = []) -> String {
        guard let localizedString = getLocalizedString(from: Self.frameworkBundle, for: key, locale: locale) else {
            return key
        }
        
        if arguments.isEmpty {
            return localizedString
        } else {
            return String(format: localizedString, arguments: arguments)
        }
    }
    
    // MARK: - Common Placeholder Helpers
    
    /// Get localized placeholder for "Select" (generic)
    public func placeholderSelect() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.select")
    }
    
    /// Get localized placeholder for "Select an option"
    public func placeholderSelectOption() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectOption")
    }
    
    /// Get localized placeholder for "Select date"
    public func placeholderSelectDate() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectDate")
    }
    
    /// Get localized placeholder for "Select time"
    public func placeholderSelectTime() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectTime")
    }
    
    /// Get localized placeholder for "Select date and time"
    public func placeholderSelectDateTime() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectDateTime")
    }
    
    /// Get localized placeholder for "Select dates" (multiple)
    public func placeholderSelectDates() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectDates")
    }
    
    /// Get localized placeholder for "Select file"
    public func placeholderSelectFile() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectFile")
    }
    
    /// Get localized placeholder for "Select image"
    public func placeholderSelectImage() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectImage")
    }
    
    /// Get localized placeholder for "Select color"
    public func placeholderSelectColor() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectColor")
    }
    
    /// Get localized placeholder for "Select start date"
    public func placeholderSelectStartDate() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectStartDate")
    }
    
    /// Get localized placeholder for "Select start time"
    public func placeholderSelectStartTime() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectStartTime")
    }
    
    /// Get localized placeholder for "Select end date"
    public func placeholderSelectEndDate() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectEndDate")
    }
    
    /// Get localized placeholder for "Select end time"
    public func placeholderSelectEndTime() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectEndTime")
    }
    
    /// Get localized placeholder for "Select creation date"
    public func placeholderSelectCreationDate() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectCreationDate")
    }
    
    /// Get localized placeholder for "Select creation time"
    public func placeholderSelectCreationTime() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectCreationTime")
    }
    
    /// Get localized placeholder for "Select birth date"
    public func placeholderSelectBirthDate() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectBirthDate")
    }
    
    /// Get localized placeholder for "Select country"
    public func placeholderSelectCountry() -> String {
        return localizedString(for: "SixLayerFramework.form.placeholder.selectCountry")
    }

    /// Get the current language code
    /// - Returns: Current language code (e.g., "en", "es", "fr")
    public func currentLanguage() -> String {
        return locale.language.languageCode?.identifier ?? "en"
    }

    /// Get the list of supported languages
    /// - Returns: Array of supported language codes
    public func supportedLanguages() -> [String] {
        // Return a reasonable set of commonly supported languages
        return ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko", "ar", "ru", "hi"]
    }

    /// Set the current language
    /// - Parameter languageCode: The language code to set (e.g., "en", "es", "fr", "de-CH", "zh-Hans")
    /// - Note: This updates the locale which will trigger UI updates via @Published
    public func setLanguage(_ languageCode: String) {
        // Create a new locale from the language code
        // Handle region-specific codes like "de-CH" or "zh-Hans"
        let newLocale: Locale
        if languageCode.contains("-") {
            // Language code with region (e.g., "de-CH", "zh-Hans")
            newLocale = Locale(identifier: languageCode)
        } else {
            // Simple language code (e.g., "en", "es")
            // Use current region if available, otherwise default to language's primary region
            if let currentRegion = locale.region?.identifier {
                newLocale = Locale(identifier: "\(languageCode)-\(currentRegion)")
            } else {
                newLocale = Locale(identifier: languageCode)
            }
        }
        
        // Update the locale (this will trigger @Published and update all formatters)
        self.locale = newLocale
        
        // Post notification for any observers that want to react to language changes
        NotificationCenter.default.post(name: .languageDidChange, object: self, userInfo: ["languageCode": languageCode, "locale": newLocale])
    }
    
    // MARK: - Locale Information
    
    /// Get current locale information
    /// - Returns: Locale information
    public func getLocaleInfo() -> LocaleInfo {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        let regionCode = locale.region?.identifier ?? "US"
        let currencyCode = locale.currency?.identifier ?? "USD"
        let isRTL = locale.language.languageCode?.identifier.hasPrefix("ar") == true || 
                   locale.language.languageCode?.identifier.hasPrefix("he") == true ||
                   locale.language.languageCode?.identifier.hasPrefix("fa") == true
        
        let numberFormat = NumberFormat(
            decimalSeparator: locale.decimalSeparator ?? ".",
            groupingSeparator: locale.groupingSeparator ?? ",",
            currencySymbol: locale.currencySymbol ?? "$",
            currencyPosition: .before,
            negativeFormat: .minus
        )
        
        let dateFormat = DateFormat(
            shortFormat: "M/d/yy",
            mediumFormat: "MMM d, yyyy",
            longFormat: "MMMM d, yyyy",
            fullFormat: "EEEE, MMMM d, yyyy",
            firstWeekday: 1,
            minimumDaysInFirstWeek: 1
        )
        
        let timeFormat = TimeFormat(
            shortFormat: "h:mm a",
            mediumFormat: "h:mm:ss a",
            longFormat: "h:mm:ss a z",
            fullFormat: "h:mm:ss a zzzz",
            is24Hour: false,
            amSymbol: "AM",
            pmSymbol: "PM"
        )
        
        return LocaleInfo(
            identifier: locale.identifier,
            languageCode: languageCode,
            regionCode: regionCode,
            currencyCode: currencyCode,
            isRTL: isRTL,
            numberFormat: numberFormat,
            dateFormat: dateFormat,
            timeFormat: timeFormat
        )
    }
    
    // MARK: - RTL Layout Support
    
    /// Get RTL-aware layout direction
    /// - Returns: Layout direction for SwiftUI
    public func getLayoutDirection() -> LayoutDirection {
        return getLocaleInfo().isRTL ? .rightToLeft : .leftToRight
    }
    
    /// Get RTL-aware text alignment
    /// - Parameter text: The text to analyze
    /// - Returns: Text alignment for SwiftUI
    public func getTextAlignment(for text: String) -> TextAlignment {
        return textAlignment(for: text)
    }
    
    // MARK: - Validation
    
    /// Validate if a locale is supported
    /// - Parameter locale: The locale to validate
    /// - Returns: True if supported, false otherwise
    public static func isLocaleSupported(_ locale: Locale) -> Bool {
        let supportedLanguages = ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko", "ar", "ru", "hi", "th", "vi", "tr", "pl", "nl", "sv", "da", "no", "fi", "cs", "hu", "ro", "bg", "hr", "sk", "sl", "et", "lv", "lt", "el", "he", "fa", "ur", "bn", "ta", "te", "ml", "kn", "gu", "pa", "or", "as", "ne", "si", "my", "km", "lo", "ka", "hy", "az", "kk", "ky", "uz", "tg", "mn", "bo", "dz", "ti", "am", "om", "so", "sw", "zu", "af", "sq", "eu", "be", "bs", "ca", "cy", "eo", "fo", "gl", "is", "mk", "mt", "rm", "sq", "sr", "uk", "wa"]
        
        guard let languageCode = locale.language.languageCode?.identifier else { return false }
        return supportedLanguages.contains(languageCode)
    }
}
