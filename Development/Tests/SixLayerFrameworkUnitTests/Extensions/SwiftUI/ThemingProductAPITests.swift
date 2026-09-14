//
//  ThemingProductAPITests.swift
//  SixLayerFrameworkTests
//
//  Unit-lane coverage for ThemedViewModifiers + ThemingIntegration (#465).
//  Product APIs only; example/demo Sources are out of this file.
//  Observations are stored inputs and progress clamp, not body-only eval.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

private struct ThemingFormProbe: Codable {
    var name: String
}

@Suite("Theming product API")
struct ThemingProductAPITests {

    @Test @MainActor
    func progressBarClampsAboveOne() {
        #expect(ThemedProgressBar(progress: 1.5, variant: .primary).progress == 1.0)
    }

    @Test @MainActor
    func progressBarClampsBelowZero() {
        #expect(ThemedProgressBar(progress: -0.25, variant: .error).progress == 0.0)
    }

    @Test @MainActor
    func progressBarPreservesInRangeProgressAndVariant() {
        let bar = ThemedProgressBar(progress: 0.4, variant: .warning)
        #expect(bar.progress == 0.4)
        #expect(bar.variant == .warning)
    }

    @Test
    func buttonVariantRawValuesAreStable() {
        #expect(
            Set(ButtonVariant.allCases.map(\.rawValue))
                == ["primary", "secondary", "outline", "ghost"]
        )
    }

    @Test
    func buttonSizeRawValuesAreStable() {
        #expect(
            Set(ButtonSize.allCases.map(\.rawValue))
                == ["small", "medium", "large"]
        )
    }

    @Test
    func progressVariantRawValuesAreStable() {
        #expect(
            Set(ProgressVariant.allCases.map(\.rawValue))
                == ["primary", "success", "warning", "error"]
        )
    }

    @Test @MainActor
    func themedResponsiveCardStoresTitleAndSubtitle() {
        let card = ThemedResponsiveCardView(
            title: "Card Title",
            subtitle: "Card Subtitle",
            content: AnyView(Text("content")),
            action: nil
        )
        #expect(card.title == "Card Title")
        #expect(card.subtitle == "Card Subtitle")
        AccessibilityIdentifierConfig.withUnhostedInspection {
            _ = card.body
        }
    }

    @Test @MainActor
    func themedNumericDataViewStoresSeries() {
        let view = ThemedGenericNumericDataView(
            data: [1.0, 2.5, 4.0],
            title: "Readings",
            unit: "psi"
        )
        #expect(view.data == [1.0, 2.5, 4.0])
        #expect(view.title == "Readings")
        #expect(view.unit == "psi")
        AccessibilityIdentifierConfig.withUnhostedInspection {
            _ = view.body
        }
    }

    @Test @MainActor
    func themedItemCollectionStoresTitleAndCount() {
        let view = ThemedGenericItemCollectionView(
            items: ["a", "b", "c"],
            title: "Items",
            onItemTap: { _ in }
        )
        #expect(view.title == "Items")
        #expect(view.items.count == 3)
        AccessibilityIdentifierConfig.withUnhostedInspection {
            _ = view.body
        }
    }

    @Test @MainActor
    func themedIntelligentFormViewStoresTypeAndInitialData() {
        let initial = ThemingFormProbe(name: "Ada")
        let view = ThemedIntelligentFormView(
            for: ThemingFormProbe.self,
            initialData: initial,
            onSubmit: { _ in }
        )
        #expect(view.dataType == ThemingFormProbe.self)
        #expect(view.initialData?.name == "Ada")
        AccessibilityIdentifierConfig.withUnhostedInspection {
            _ = view.body
        }
    }
}
