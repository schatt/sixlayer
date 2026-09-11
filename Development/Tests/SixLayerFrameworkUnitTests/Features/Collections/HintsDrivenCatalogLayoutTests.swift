//
//  HintsDrivenCatalogLayoutTests.swift
//  SixLayerFrameworkUnitTests
//
//  TDD for #477: catalog custom/generic views must honor PresentationHints.
//

import Testing
@testable import SixLayerFramework

@Suite("Hints-driven catalog layout (#477)")
struct HintsDrivenCatalogLayoutTests {

    private func hints(
        dataType: DataTypeHint = .generic,
        preference: PresentationPreference = .automatic,
        complexity: ContentComplexity = .moderate,
        custom: [String: String] = [:]
    ) -> PresentationHints {
        PresentationHints(
            dataType: dataType,
            presentationPreference: preference,
            complexity: complexity,
            context: .dashboard,
            customPreferences: custom
        )
    }

    @Test func settingsAutomatic_defaultsToList() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(),
            itemCount: 4,
            surface: .settings
        )
        #expect(strategy == .list)
    }

    @Test func settingsGridPreference_usesGrid() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: .grid),
            itemCount: 4,
            surface: .settings
        )
        #expect(strategy == .grid)
    }

    @Test func settingsCardsPreference_usesGrid() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: .cards),
            itemCount: 4,
            surface: .settings
        )
        #expect(strategy == .grid)
    }

    @Test func settingsListPreference_usesList() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: .list),
            itemCount: 4,
            surface: .settings
        )
        #expect(strategy == .list)
    }

    @Test func mediaAutomatic_defaultsToGrid() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(dataType: .media),
            itemCount: 8,
            surface: .media
        )
        #expect(strategy == .grid)
    }

    @Test func mediaListPreference_usesList() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(dataType: .media, preference: .list),
            itemCount: 8,
            surface: .media
        )
        #expect(strategy == .list)
    }

    @Test func numericAutomatic_defaultsToGrid() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(dataType: .numeric),
            itemCount: 6,
            surface: .numeric
        )
        #expect(strategy == .grid)
    }

    @Test func hierarchicalAutomatic_defaultsToList() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(dataType: .hierarchical),
            itemCount: 3,
            surface: .hierarchical
        )
        #expect(strategy == .list)
    }

    @Test func temporalAutomatic_defaultsToList() {
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(dataType: .temporal),
            itemCount: 3,
            surface: .temporal
        )
        #expect(strategy == .list)
    }

    @Test func countBased_usesThreshold() {
        let preference = PresentationPreference.countBased(
            lowCount: .grid,
            highCount: .list,
            threshold: 10
        )
        let low = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: preference),
            itemCount: 4,
            surface: .settings
        )
        let high = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: preference),
            itemCount: 20,
            surface: .settings
        )
        #expect(low == .grid)
        #expect(high == .list)
    }

    @Test func layoutDataType_usesHintsWhenNotGeneric() {
        let result = HintsDrivenCatalogLayout.layoutDataType(
            hints: hints(dataType: .numeric),
            fallback: .media
        )
        #expect(result == .numeric)
    }

    @Test func layoutDataType_genericFallsBackToSurface() {
        let result = HintsDrivenCatalogLayout.layoutDataType(
            hints: hints(dataType: .generic),
            fallback: .media
        )
        #expect(result == .media)
    }

    @Test func spacingScale_followsComplexity() {
        #expect(HintsDrivenCatalogLayout.spacingScale(complexity: .simple) == 0.75)
        #expect(HintsDrivenCatalogLayout.spacingScale(complexity: .moderate) == 1.0)
        #expect(HintsDrivenCatalogLayout.spacingScale(complexity: .complex) == 1.25)
        #expect(HintsDrivenCatalogLayout.spacingScale(complexity: .veryComplex) == 1.5)
        #expect(HintsDrivenCatalogLayout.spacingScale(complexity: .advanced) == 1.5)
    }

    @Test func rowVisualStyle_cardCustomPreference() {
        #expect(
            HintsDrivenCatalogLayout.rowVisualStyleIsCard(
                hints: hints(custom: ["rowVisualStyle": "card"])
            )
        )
        #expect(
            !HintsDrivenCatalogLayout.rowVisualStyleIsCard(hints: hints())
        )
    }

    @Test func settingsActionChrome_visibleWhenCallbacksPresent() {
        #expect(SettingsActionChrome.isVisible(onSaved: {}, onCancelled: nil))
        #expect(SettingsActionChrome.isVisible(onSaved: nil, onCancelled: {}))
        #expect(!SettingsActionChrome.isVisible(onSaved: nil, onCancelled: nil))
    }

    @Test func masonryAndCoverFlow_useGrid() {
        #expect(
            HintsDrivenCatalogLayout.strategy(
                hints: hints(preference: .masonry),
                itemCount: 8,
                surface: .settings
            ) == .grid
        )
        #expect(
            HintsDrivenCatalogLayout.strategy(
                hints: hints(preference: .coverFlow),
                itemCount: 8,
                surface: .media
            ) == .grid
        )
    }

    @Test func nestedCountBased_doesNotRecurse_usesSurfaceDefault() {
        let nested = PresentationPreference.countBased(
            lowCount: .countBased(lowCount: .grid, highCount: .list, threshold: 2),
            highCount: .list,
            threshold: 10
        )
        let strategy = HintsDrivenCatalogLayout.strategy(
            hints: hints(preference: nested),
            itemCount: 4,
            surface: .settings
        )
        #expect(strategy == .list)
    }

    @Test func resolvedViewportWidth_ignoresZeroUntilMeasured() {
        #expect(HintsDrivenCatalogLayout.resolvedViewportWidth(0) == 800)
        #expect(HintsDrivenCatalogLayout.resolvedViewportWidth(390) == 390)
    }
}
