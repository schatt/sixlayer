import CoreGraphics
import Foundation

/// Layout chosen from `PresentationHints` for catalog surfaces that previously ignored hints (#477).
enum HintsDrivenCatalogLayout {
    enum Strategy: Equatable {
        case list
        case grid
    }

    enum Surface {
        case settings
        case media
        case hierarchical
        case temporal
        case numeric
    }

    /// Stub: always list so preference/surface tests fail until green.
    static func strategy(
        hints: PresentationHints,
        itemCount: Int,
        surface: Surface
    ) -> Strategy {
        _ = (hints, itemCount, surface)
        return .list
    }

    /// Stub: always the fallback so explicit hint dataType is ignored.
    static func layoutDataType(hints: PresentationHints, fallback: DataTypeHint) -> DataTypeHint {
        _ = hints
        return fallback
    }

    /// Stub: ignore complexity.
    static func spacingScale(complexity: ContentComplexity) -> CGFloat {
        _ = complexity
        return 1.0
    }

    /// Stub: ignore customPreferences.
    static func rowVisualStyleIsCard(hints: PresentationHints) -> Bool {
        _ = hints
        return false
    }
}

enum SettingsActionChrome {
    /// Stub: never show chrome so callback tests fail until green.
    static func isVisible(onSaved: (() -> Void)?, onCancelled: (() -> Void)?) -> Bool {
        _ = (onSaved, onCancelled)
        return false
    }
}
