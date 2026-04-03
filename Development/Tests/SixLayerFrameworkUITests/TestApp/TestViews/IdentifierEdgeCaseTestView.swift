//
//  IdentifierEdgeCaseTestView.swift
//  SixLayerFrameworkUITests
//
//  Test view for accessibility identifier edge cases (issue #178).
//  Runtime contract for manual `platformButton(..., id:)` identifiers:
//  `ManualAccessibilityIdentifierHarnessUITests` (XCUITest). ViewInspector / in-process UIKit collection
//  in unit tests are not reliable for these (see file comment there).
//

import SwiftUI
import SixLayerFramework

struct IdentifierEdgeCaseTestView: View {
    var onBackToMain: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        platformScrollViewContainer {
            platformVStack(spacing: 24) {
                platformText("Identifier Edge Case Test")
                    .font(.headline)
                    .automaticCompliance()

                platformButton("Back to Main") {
                    if let action = onBackToMain { action() } else { dismiss() }
                }
                .accessibilityIdentifier("back-to-main-button")
                .padding(.bottom)

                // Manual override: explicit .accessibilityIdentifier overrides automatic generation.
                // UI test asserts this element is findable (covers testManualIDOverride-style behavior).
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Manual ID override")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()

                    platformButton(label: "Submit", id: "manual-override-id") { }
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)

                // Second element with different manual ID so tests can assert distinct identifiers.
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("Second manual ID")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .automaticCompliance()

                    platformButton(label: "Cancel", id: "manual-cancel-id") { }
                }
                .padding()
                .background(Color.platformSecondaryBackground)
                .cornerRadius(8)
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Identifier Edge Case")
    }
}
