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

        var fallbackDataType: DataTypeHint {
            switch self {
            case .settings:
                return .generic
            case .media:
                return .media
            case .hierarchical:
                return .hierarchical
            case .temporal:
                return .temporal
            case .numeric:
                return .numeric
            }
        }
    }

    static func strategy(
        hints: PresentationHints,
        itemCount: Int,
        surface: Surface
    ) -> Strategy {
        strategy(
            for: hints.presentationPreference,
            itemCount: itemCount,
            surface: surface
        )
    }

    /// Uses `hints.dataType` when it is not `.generic`; otherwise the surface fallback
    /// (so `CustomMediaView` still lays out as media when callers pass default hints).
    static func layoutDataType(hints: PresentationHints, fallback: DataTypeHint) -> DataTypeHint {
        hints.dataType == .generic ? fallback : hints.dataType
    }

    static func spacingScale(complexity: ContentComplexity) -> CGFloat {
        switch complexity {
        case .simple:
            return 0.75
        case .moderate:
            return 1.0
        case .complex:
            return 1.25
        case .veryComplex, .advanced:
            return 1.5
        }
    }

    static func rowVisualStyleIsCard(hints: PresentationHints) -> Bool {
        hints.customPreferences["rowVisualStyle"]?.lowercased() == "card"
    }

    /// Background `GeometryReader` reports 0 until laid out; don't feed that to column math.
    static func resolvedViewportWidth(_ measured: CGFloat) -> CGFloat {
        measured > 0 ? measured : 800
    }

    private static func strategy(
        for preference: PresentationPreference,
        itemCount: Int,
        surface: Surface
    ) -> Strategy {
        switch preference {
        case .list, .compact, .form, .standard, .minimal:
            return .list
        case .grid, .cards, .card, .masonry, .coverFlow:
            return .grid
        case .countBased(let lowCount, let highCount, let threshold):
            let chosen = itemCount <= threshold ? lowCount : highCount
            if case .countBased = chosen {
                return defaultStrategy(surface)
            }
            return strategy(for: chosen, itemCount: itemCount, surface: surface)
        case .automatic, .custom, .detail, .modal, .navigation, .chart, .moderate, .rich:
            return defaultStrategy(surface)
        }
    }

    private static func defaultStrategy(_ surface: Surface) -> Strategy {
        switch surface {
        case .settings, .hierarchical, .temporal:
            return .list
        case .media, .numeric:
            return .grid
        }
    }
}

enum SettingsActionChrome {
    static func isVisible(onSaved: (() -> Void)?, onCancelled: (() -> Void)?) -> Bool {
        onSaved != nil || onCancelled != nil
    }
}
