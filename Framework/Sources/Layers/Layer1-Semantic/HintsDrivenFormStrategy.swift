import Foundation

/// Derives ``FormStrategy`` from ``PresentationHints`` for generic L1 forms (#480).
enum HintsDrivenFormStrategy {
    /// Stub: current GenericFormView hardcode so tests compile and fail at runtime.
    static func strategy(hints: PresentationHints, fieldCount: Int) -> FormStrategy {
        _ = (hints, fieldCount)
        return FormStrategy(
            containerType: .standard,
            fieldLayout: .vertical,
            validation: .deferred
        )
    }
}
