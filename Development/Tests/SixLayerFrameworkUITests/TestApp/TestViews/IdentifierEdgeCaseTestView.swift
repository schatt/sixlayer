//
//  IdentifierEdgeCaseTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for accessibility identifier edge cases (issue #178).
//  Covers scenarios ViewInspector cannot assert on iOS; UI tests assert via XCUIElement.
//

import SwiftUI
import SixLayerFramework

struct IdentifierEdgeCaseTestView: View {
    let onBackToMain: () -> Void

    var body: some View {
        platformScrollViewContainer {
            platformVStack(spacing: 24) {
                platformText("Identifier Edge Case Test")
                    .font(.headline)
                    .automaticCompliance()

                platformButton("Back to Main") {
                    onBackToMain()
                }
                .accessibilityIdentifier("back-to-main-button")
                .padding(.bottom)

                // Manual override: plain SwiftUI so .accessibilityIdentifier is not overridden by framework.
                // UI test asserts this element is findable (covers testManualIDOverride-style behavior).
                VStack(alignment: .leading, spacing: 8) {
                    platformText("Manual ID override")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()

                    Button("Submit") { }
                        .accessibilityIdentifier("manual-override-id")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)

                // Second element with different manual ID so tests can assert distinct identifiers.
                VStack(alignment: .leading, spacing: 8) {
                    platformText("Second manual ID")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()

                    Button("Cancel") { }
                        .accessibilityIdentifier("manual-cancel-id")
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Identifier Edge Case")
    }
}
