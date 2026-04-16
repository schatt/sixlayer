//
//  DetailViewCategoryBAuditView.swift
//  SixLayerFrameworkUITests
//
//  Issue #198: Category B UI backfill host for IntelligentDetailView visible content.
//

import SwiftUI
import SixLayerFramework

private struct CategoryBDetailItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let description: String?
    let value: Int
    let isActive: Bool
}

struct DetailViewCategoryBAuditView: View {
    private let defaultItem = CategoryBDetailItem(
        id: "category-b-default",
        title: "Category B Item",
        subtitle: "Category B Subtitle",
        description: "Category B Description",
        value: 42,
        isActive: true
    )

    private let nilValueItem = CategoryBDetailItem(
        id: "category-b-nil",
        title: "Nil Item",
        subtitle: nil,
        description: "Nil Description",
        value: 0,
        isActive: false
    )

    private let compactHints = PresentationHints(
        dataType: .generic,
        presentationPreference: .compact,
        complexity: .moderate,
        context: .dashboard
    )

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 24) {
                Text("Category B Detail Coverage")
                    .font(.title2)
                    .bold()
                    .accessibilityIdentifier("Category B Detail Coverage")

                Text("Default IntelligentDetailView")
                    .font(.headline)
                IntelligentDetailView.platformDetailView(for: defaultItem, showEditButton: false)

                Divider()

                Text("Custom Field IntelligentDetailView")
                    .font(.headline)
                IntelligentDetailView.platformDetailView(
                    for: defaultItem,
                    hints: compactHints,
                    showEditButton: false,
                    customFieldView: { fieldName, value, _ in
                        Text("Custom Field: \(fieldName) = \(value)")
                    }
                )

                Divider()

                Text("Nil Value IntelligentDetailView")
                    .font(.headline)
                IntelligentDetailView.platformDetailView(
                    for: nilValueItem,
                    showEditButton: false
                )
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Category B Detail Coverage")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
