//
//  DetailViewTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for IntelligentDetailView content (issue #178).
//  ViewInspector cannot traverse this on iOS; UI tests assert visible content via XCUIElement.
//

import SwiftUI
import SixLayerFramework

private struct DetailTestItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: Int

    init(id: String = "detail-1", title: String, description: String, priority: Int = 1) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
    }
}

struct DetailViewTestView: View {
    let onBackToMain: () -> Void

    private static let detailItem = DetailTestItem(
        title: "Detail Title",
        description: "Detail subtitle and content for UI test to find.",
        priority: 1
    )

    var body: some View {
        platformScrollViewContainer {
            platformVStack(spacing: 24) {
                platformButton("Back to Main") {
                    onBackToMain()
                }
                .accessibilityIdentifier("back-to-main-button")
                .padding(.bottom)

                IntelligentDetailView.platformDetailView(
                    for: Self.detailItem,
                    showEditButton: false
                )
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Detail View Test")
    }
}
