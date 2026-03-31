//
//  AccessibilityIdentifierCategoryAUDITView.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A UI backfill — scenarios ViewInspector often cannot assert on iOS;
//  XCUITest asserts identifiers and labels via XCUIElement.
//

import SwiftUI
import SixLayerFramework

/// Contract surface for Category A (accessibility identifier edge cases, nested named, unicode, manual-only).
struct AccessibilityIdentifierCategoryAUDITView: View {
    /// Long `identifierName` exercises sanitization / truncation paths (audit: very long names).
    private let longIdentifierName = "CatALong" + String(repeating: "Z", count: 48)

    /// Matches `generateAccessibilityIdentifier` when `enableUITestIntegration` is true (TestApp `init`).
    private static let auditTitleUITestID = "SixLayer.main.ui.CatAAuditTitle.View"
    private static let nestedOuterUITestID = "SixLayer.main.ui.CatANestedOuter.View"
    private static let nestedInnerUITestID = "SixLayer.main.ui.CatANestedInnerButton.View"

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 24) {
                // Named compliance + explicit ID: some Text + font chains do not surface generated IDs to XCTest; last wins for UI tests.
                platformText("Category A — identifier audit (#197)")
                    .automaticCompliance(named: "CatAAuditTitle")
                    .font(.headline)
                    .accessibilityIdentifier(Self.auditTitleUITestID)

                sectionCaption("Unicode + label")
                platformText("café 日本語")
                    .basicAutomaticCompliance(
                        identifierName: "CatAUnicodeText",
                        identifierLabel: "café 日本語"
                    )

                // Outer name on a Text — layout containers often do not surface a stable identifier to XCTest.
                platformText("Nested named components")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .automaticCompliance(named: "CatANestedOuter")
                    .accessibilityIdentifier(Self.nestedOuterUITestID)
                platformVStack(alignment: .leading, spacing: 8) {
                    platformButton(label: "CatA Nested Action", id: nil) { }
                        .automaticCompliance(named: "CatANestedInnerButton")
                        .accessibilityIdentifier(Self.nestedInnerUITestID)
                }

                sectionCaption("Manual-only identifier (no automaticCompliance on this view)")
                Text("CatA manual only visible")
                    .accessibilityIdentifier("CatA_ManualOnly_StaticText")

                sectionCaption("Special characters in label")
                platformText("Special")
                    .basicAutomaticCompliance(
                        identifierName: "CatASpecialChars",
                        identifierLabel: "Save & Load! <test>"
                    )

                sectionCaption("Long identifier name (sanitization)")
                platformText("Long")
                    .basicAutomaticCompliance(
                        identifierName: longIdentifierName,
                        identifierLabel: "Long"
                    )
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Category A Audit")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }

    private func sectionCaption(_ title: String) -> some View {
        platformText(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }
}
