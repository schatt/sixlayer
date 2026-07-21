//
//  EmptyStateWrapperBisectExamples.swift
//  SixLayerFrameworkUITests
//
//  Incremental destination-wrapper ladder for empty-state hint a11y ids (#360).
//  Baseline (`emptyItems` / #359) is known green. Each step adds one CarManager-like
//  wrapper; the first red step is the overwrite site (CarManager #757).
//

import SwiftUI
import SixLayerFramework

/// Shared empty collection + hint ids used by every bisect step (#360).
enum EmptyStateWrapperBisectIDs {
    static let emptyStateTitle = "SixLayer.uitest.collectionEmpty.EmptyStateTitle"
    static let createButton = "SixLayer.uitest.collectionEmpty.EmptyStateCreateButton"
    static let scrollHost = "SixLayer.uitest.collectionEmpty.scrollHost"
    static let namedComponent = "EmptyStateWrapperBisectHost"
    /// Container id for `.exactNamed` overwrite proof (#364) — exact string, no framework prefix.
    static let exactNamedComponent = "EmptyStateWrapperBisectExactHost"
}

private struct BisectEmptyItem: Identifiable {
    let id = UUID()
    let name: String
}

private let bisectEmptyHints = PresentationHints(
    dataType: .generic,
    presentationPreference: .list,
    complexity: .simple,
    customPreferences: [
        "emptyTitle": "No Items Yet",
        "emptyMessage": "Add your first item to get started.",
        "createButtonTitle": "Add Item",
        "emptyStateTitleAccessibilityIdentifier": EmptyStateWrapperBisectIDs.emptyStateTitle,
        "createButtonAccessibilityIdentifier": EmptyStateWrapperBisectIDs.createButton
    ]
)

/// Empty collection surface shared by all ladder steps.
@MainActor
@ViewBuilder
private func emptyCollectionWithHintIds() -> some View {
    platformPresentItemCollection_L1(
        items: [BisectEmptyItem](),
        hints: bisectEmptyHints,
        onCreateItem: { print("Create item tapped") },
        onItemSelected: { _ in },
        customItemView: { item in
            Text(item.name)
        }
    )
    .frame(height: 280)
}

// MARK: - Step 1: + `.named`

/// Baseline empty+hints, plus `.named` (CarManager AllVehiclesView).
struct EmptyStateWrapperBisectNamedExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Empty + hint ids + .named")
                .font(.headline)
            emptyCollectionWithHintIds()
                .named(EmptyStateWrapperBisectIDs.namedComponent)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - ExactNamed container mirror of step 1 (#364)

/// Same empty+hints surface as step 1, but wrapped with `.exactNamed` on the collection
/// container. Proves nested hint ids stay queryable (host-sentinel parity with `.named`).
struct EmptyStateWrapperBisectExactNamedExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Empty + hint ids + .exactNamed")
                .font(.headline)
            emptyCollectionWithHintIds()
                .exactNamed(EmptyStateWrapperBisectIDs.exactNamedComponent)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Step 2: + named + platformNavigationTitle_L4

struct EmptyStateWrapperBisectNavTitleExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Empty + hint ids + .named + nav title")
                .font(.headline)
            emptyCollectionWithHintIds()
                .named(EmptyStateWrapperBisectIDs.namedComponent)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .platformNavigationTitle_L4("All Vehicles")
        .platformNavigationTitleDisplayMode_L4(.large)
    }
}

// MARK: - Step 3: + outer scrollHost accessibilityIdentifier

struct EmptyStateWrapperBisectOuterScrollHostExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Empty + hint ids + named + nav + outer scrollHost")
                .font(.headline)
            emptyCollectionWithHintIds()
                .named(EmptyStateWrapperBisectIDs.namedComponent)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .platformNavigationTitle_L4("All Vehicles")
        .platformNavigationTitleDisplayMode_L4(.large)
        .accessibilityHostIdentifier(EmptyStateWrapperBisectIDs.scrollHost)
    }
}

// MARK: - Step 4: + outer scrollHost + children .contain

struct EmptyStateWrapperBisectOuterContainExamples: View {
    var body: some View {
        platformVStack(alignment: .leading, spacing: 12) {
            Text("Empty + hint ids + named + nav + scrollHost + contain")
                .font(.headline)
            emptyCollectionWithHintIds()
                .named(EmptyStateWrapperBisectIDs.namedComponent)
        }
        .padding()
        .background(Color.platformSecondaryBackground)
        .cornerRadius(8)
        .platformNavigationTitle_L4("All Vehicles")
        .platformNavigationTitleDisplayMode_L4(.large)
        .accessibilityHostIdentifier(EmptyStateWrapperBisectIDs.scrollHost)
        .accessibilityElement(children: .contain)
    }
}
