import Foundation

/// Derives ``FormStrategy`` from ``PresentationHints`` for generic L1 forms (#480).
///
/// Default hints (`.automatic` + `.moderate`) keep the historical
/// `standard` / `vertical` / `deferred` container. Explicit preference,
/// complexity, and `customPreferences` keys override that hardcode.
enum HintsDrivenFormStrategy {
    static func strategy(hints: PresentationHints, fieldCount: Int) -> FormStrategy {
        let preference = resolvedPreference(hints.presentationPreference, fieldCount: fieldCount)
        var container = containerType(
            preference: preference,
            complexity: hints.complexity,
            fieldCount: fieldCount
        )
        var layout = fieldLayout(preference: preference, complexity: hints.complexity)
        var validation = validationStrategy(
            preference: preference,
            complexity: hints.complexity,
            fieldCount: fieldCount
        )

        if let raw = hints.customPreferences["containerType"],
           let override = FormContainerType(rawValue: raw) {
            container = override
        }
        if let raw = hints.customPreferences["fieldLayout"],
           let override = FieldLayout(rawValue: raw) {
            layout = override
        }
        if let raw = hints.customPreferences["validation"],
           let override = ValidationStrategy(rawValue: raw) {
            validation = override
        } else if hints.customPreferences["hasValidation"] == "true" {
            validation = .realTime
        }

        return FormStrategy(
            containerType: container,
            fieldLayout: layout,
            validation: validation
        )
    }

    private static func resolvedPreference(
        _ preference: PresentationPreference,
        fieldCount: Int
    ) -> PresentationPreference {
        guard case .countBased(let lowCount, let highCount, let threshold) = preference else {
            return preference
        }
        let chosen = fieldCount <= threshold ? lowCount : highCount
        if case .countBased = chosen {
            return .automatic
        }
        return chosen
    }

    private static func usesComplexityDefaults(_ preference: PresentationPreference) -> Bool {
        switch preference {
        case .automatic, .moderate, .rich:
            return true
        default:
            return false
        }
    }

    private static func containerType(
        preference: PresentationPreference,
        complexity: ContentComplexity,
        fieldCount: Int
    ) -> FormContainerType {
        switch preference {
        case .form, .modal:
            return .form
        case .custom:
            return .custom
        case .list, .detail, .navigation:
            return .scrollView
        case .compact, .minimal, .standard, .grid, .cards, .card, .masonry, .coverFlow, .chart:
            return .standard
        case .automatic, .moderate, .rich:
            return complexityContainer(complexity: complexity, fieldCount: fieldCount)
        case .countBased:
            return complexityContainer(complexity: complexity, fieldCount: fieldCount)
        }
    }

    private static func complexityContainer(
        complexity: ContentComplexity,
        fieldCount: Int
    ) -> FormContainerType {
        switch complexity {
        case .simple:
            return fieldCount <= 3 ? .form : .standard
        case .moderate:
            return .standard
        case .complex, .veryComplex, .advanced:
            return .scrollView
        }
    }

    private static func fieldLayout(
        preference: PresentationPreference,
        complexity: ContentComplexity
    ) -> FieldLayout {
        switch preference {
        case .grid, .masonry, .cards, .card, .coverFlow, .chart:
            return .grid
        case .compact, .minimal:
            return .compact
        case .rich:
            return .spacious
        case .automatic, .moderate:
            switch complexity {
            case .simple, .moderate:
                return .vertical
            case .complex, .veryComplex, .advanced:
                return .adaptive
            }
        case .form, .standard, .modal, .custom, .list, .detail, .navigation, .countBased:
            return .vertical
        }
    }

    private static func validationStrategy(
        preference: PresentationPreference,
        complexity: ContentComplexity,
        fieldCount: Int
    ) -> ValidationStrategy {
        if usesComplexityDefaults(preference),
           complexity == .simple,
           fieldCount <= 3 {
            return .immediate
        }
        return .deferred
    }
}
