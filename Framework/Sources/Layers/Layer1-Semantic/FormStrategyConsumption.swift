import CoreGraphics
import Foundation

extension FieldLayout {
    /// How many fields `PackedGenericFormFieldsLayout` may place on one row (#485).
    var formPackMaxItemsPerRow: Int {
        switch self {
        case .vertical: return 1
        case .horizontal: return 2
        case .grid: return 3
        case .compact, .standard, .spacious, .adaptive: return 4
        }
    }

    var formContainerSpacing: CGFloat {
        switch self {
        case .compact: return 8
        case .horizontal: return 12
        case .spacious, .grid: return 20
        case .standard, .adaptive, .vertical: return 16
        }
    }

    var asSpacingPreference: SpacingPreference {
        switch self {
        case .compact: return .compact
        case .spacious: return .spacious
        default: return .comfortable
        }
    }
}

extension ValidationStrategy {
    /// Immediate / real-time strategies validate while editing (#483).
    var isLive: Bool {
        switch self {
        case .immediate, .realTime: return true
        case .none, .deferred, .onSubmit, .custom: return false
        }
    }
}

enum FormFieldLiveValidation {
    /// Message shown by L4 form field chrome when validation is live (#483).
    static func message(
        label: String,
        isRequired: Bool,
        value: String,
        strategy: ValidationStrategy
    ) -> String? {
        guard strategy.isLive else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if isRequired && trimmed.isEmpty {
            return "\(label) is required"
        }
        return nil
    }

    static func message(
        field: DynamicFormField,
        value: String,
        strategy: ValidationStrategy
    ) -> String? {
        message(
            label: field.label,
            isRequired: field.isRequired,
            value: value,
            strategy: strategy
        )
    }

    static func message(
        field: DataField,
        value: Any,
        strategy: ValidationStrategy
    ) -> String? {
        guard let stringValue = value as? String else { return nil }
        return message(
            label: field.name.capitalized,
            isRequired: !field.isOptional,
            value: stringValue,
            strategy: strategy
        )
    }
}

extension FormContainerType {
    var asContainerPreference: ContainerPreference {
        switch self {
        case .form: return .structured
        case .scrollView: return .flexible
        case .standard, .custom, .adaptive: return .adaptive
        }
    }
}
