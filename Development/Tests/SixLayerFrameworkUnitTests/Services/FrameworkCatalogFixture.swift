import Foundation

/// Expected framework-catalog values for tests that claim a key resolves (#501).
/// Hard-coded so a missing catalog cannot satisfy the assertion by returning the key.
enum FrameworkCatalogFixture {
    static func value(_ key: String, language: String = "en") -> String {
        guard let byLanguage = values[key], let value = byLanguage[language] else {
            preconditionFailure("No catalog fixture for \(key) [\(language)]")
        }
        return value
    }

    static func formatted(_ key: String, language: String = "en", arguments: [String]) -> String {
        let template = value(key, language: language)
        precondition(
            template.range(of: "%(?!@)", options: .regularExpression) == nil,
            "formatted() only supports %@; \(key) is '\(template)'"
        )
        return String(format: template, arguments: arguments)
    }

    private static let values: [String: [String: String]] = [
        "SixLayerFramework.form.placeholder.select": [
            "en": "Select",
            "es": "Seleccionar",
            "fr": "Sélectionner",
            "de": "Auswählen",
            "de-CH": "Auswählen",
            "ja": "選択",
            "ko": "선택",
            "pl": "Wybierz",
            "zh-Hans": "选择"
        ],
        "SixLayerFramework.form.placeholder.selectOption": [
            "en": "Select option"
        ],
        "SixLayerFramework.form.placeholder.selectDate": [
            "en": "Select date"
        ],
        "SixLayerFramework.button.save": [
            "en": "Save"
        ],
        "SixLayerFramework.button.cancel": [
            "en": "Cancel"
        ],
        "SixLayerFramework.error.title": [
            "en": "Error"
        ],
        "SixLayerFramework.error.message": [
            "en": "Error: %@"
        ],
        "SixLayerFramework.error.invalidLocale": [
            "en": "Invalid locale provided"
        ],
        "SixLayerFramework.error.languageNotSupported": [
            "en": "Language not supported"
        ],
        "SixLayerFramework.cloudkit.missingField": [
            "en": "Required field '%@' is missing"
        ],
        "SixLayerFramework.cloudkit.unknownError": [
            "en": "Unknown error: %@"
        ],
        "SixLayerFramework.cloudkit.accountUnavailable": [
            "en": "iCloud account is not available"
        ],
        "SixLayerFramework.image.invalidImage": [
            "en": "Invalid image provided for processing"
        ],
        "SixLayerFramework.form.progressFields": [
            "en": "%d of %d field%@"
        ]
    ]
}
