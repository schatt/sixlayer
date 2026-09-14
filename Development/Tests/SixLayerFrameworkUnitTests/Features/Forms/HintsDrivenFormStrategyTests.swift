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

    @Test func automaticModerate_keepsStandardAdaptiveDeferred() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .adaptive, validation: .deferred)
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
        expect(strategy, container: .standard, layout: .adaptive, validation: .realTime)
    }

    @Test func hasValidationCustomPreference_usesRealTime() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(custom: ["hasValidation": "true"]),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .adaptive, validation: .realTime)
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
        expect(strategy, container: .standard, layout: .adaptive, validation: .deferred)
    }

    @Test func automaticSimple_moreThanThreeFields_usesStandardDeferred() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(complexity: .simple),
            fieldCount: 4
        )
        expect(strategy, container: .standard, layout: .vertical, validation: .deferred)
    }

    @Test func formPreference_doesNotTakeSimpleImmediateValidation() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .form, complexity: .simple),
            fieldCount: 2
        )
        expect(strategy, container: .form, layout: .vertical, validation: .deferred)
    }

    @Test func countBased_atThreshold_usesLowPreference() {
        let preference = PresentationPreference.countBased(
            lowCount: .form,
            highCount: .list,
            threshold: 5
        )
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: preference),
            fieldCount: 5
        )
        expect(strategy, container: .form, layout: .vertical, validation: .deferred)
    }

    @Test func invalidCustomOverrides_areIgnored() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(
                preference: .form,
                custom: [
                    "containerType": "not-a-container",
                    "fieldLayout": "nope",
                    "validation": "bogus"
                ]
            ),
            fieldCount: 3
        )
        expect(strategy, container: .form, layout: .vertical, validation: .deferred)
    }

    @Test func customFieldLayoutOverride_wins() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .form, custom: ["fieldLayout": "horizontal"]),
            fieldCount: 3
        )
        expect(strategy, container: .form, layout: .horizontal, validation: .deferred)
    }

    @Test func validationKey_winsOverHasValidation() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(custom: ["validation": "none", "hasValidation": "true"]),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .adaptive, validation: .none)
    }

    @Test func hasValidationOtherThanTrue_doesNotForceRealTime() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(custom: ["hasValidation": "false"]),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .adaptive, validation: .deferred)
    }

    @Test func customPreference_usesCustomContainer() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .custom),
            fieldCount: 3
        )
        expect(strategy, container: .custom, layout: .vertical, validation: .deferred)
    }

    @Test func richPreference_usesSpaciousFieldLayout() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .rich),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .spacious, validation: .deferred)
    }

    @Test func minimalPreference_usesCompactFieldLayout() {
        let strategy = HintsDrivenFormStrategy.strategy(
            hints: hints(preference: .minimal),
            fieldCount: 3
        )
        expect(strategy, container: .standard, layout: .compact, validation: .deferred)
    }
}
