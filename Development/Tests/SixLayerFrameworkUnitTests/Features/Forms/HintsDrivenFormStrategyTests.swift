//
//  HintsDrivenFormStrategyTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #480: GenericFormView must derive FormStrategy from PresentationHints
//  instead of hardcoding standard / vertical / deferred.
//

import Testing
@testable import SixLayerFramework

@Suite("Hints-driven form strategy (#480)")
struct HintsDrivenFormStrategyTests {

    private func hints(
        preference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        custom: [String: String] = [:]
    ) -> PresentationHints {
        PresentationHints(
            dataType: .generic,
            presentationPreference: preference,
            complexity: complexity,
            context: .form,
            customPreferences: custom
        )
    }

    private func expect(
        _ strategy: FormStrategy,
        container: FormContainerType,
        layout: FieldLayout,
        validation: ValidationStrategy,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(strategy.containerType == container, sourceLocation: sourceLocation)
        #expect(strategy.fieldLayout == layout, sourceLocation: sourceLocation)
        #expect(strategy.validation == validation, sourceLocation: sourceLocation)
    }

    @Test func automaticModerate_keepsStandardVerticalDeferred() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .vertical, validation: .deferred)
    }

    @Test func formPreference_usesFormContainer() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .form),
            fieldCount: 3
        )
        expect(strategy, container: .form, layout: .vertical, validation: .deferred)
    }

    @Test func gridPreference_usesGridFieldLayout() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .grid),
            fieldCount: 6
        )
        expect(strategy, container: .standard, layout: .grid, validation: .deferred)
    }

    @Test func compactPreference_usesCompactFieldLayout() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .compact),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .compact, validation: .deferred)
    }

    @Test func automaticComplex_usesScrollView() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(complexity: .complex),
            fieldCount: 12
        )
        expect(strategy, container: .scrollView, layout: .adaptive, validation: .deferred)
    }

    @Test func automaticSimpleFewFields_usesFormImmediate() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(complexity: .simple),
            fieldCount: 2
        )
        expect(strategy, container: .form, layout: .vertical, validation: .immediate)
    }

    @Test func customValidationPreference_overrides() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(custom: ["validation": "realTime"]),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .vertical, validation: .realTime)
    }

    @Test func hasValidationCustomPreference_usesRealTime() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(custom: ["hasValidation": "true"]),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .vertical, validation: .realTime)
    }

    @Test func customContainerTypeOverride_wins() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .form, custom: ["containerType": "scrollView"]),
            fieldCount: 3
        )
        expect(strategy, container: .scrollView, layout: .vertical, validation: .deferred)
    }

    @Test func countBased_usesThreshold() {
        let preference = PresentationPreference.countBased(
            lowCount: .form,
            highCount: .list,
            threshold: 5
        )
        let low = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: preference),
            fieldCount: 3
        )
        let high = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: preference),
            fieldCount: 8
        )
        expect(low, container: .form, layout: .vertical, validation: .deferred)
        expect(high, container: .scrollView, layout: .vertical, validation: .deferred)
    }

    @Test func nestedCountBased_doesNotRecurse_usesAutomatic() {
        let nested = PresentationPreference.countBased(
            lowCount: .countBased(lowCount: .grid, highCount: .list, threshold: 2),
            highCount: .list,
            threshold: 10
        )
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: nested),
            fieldCount: 4
        )
        expect(strategy, container: .standard, layout: .vertical, validation: .deferred)
    }
}
