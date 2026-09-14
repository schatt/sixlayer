import CoreGraphics
import Foundation

extension FieldLayout {
    /// How many fields `PackedGenericFormFieldsLayout` may place on one row (#485).
    /// Stub: historical GenericFormView always packed up to 4.
    var formPackMaxItemsPerRow: Int { 4 }

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
    /// Stub: L4 currently never treats validation as live (#483).
    var isLive: Bool { false }
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
