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
                // Group + combine: Text + font chains often omit identifiers on the leaf XCUITest sees; collapse to one a11y element.
                Group {
                    Text("Category A — identifier audit (#197)")
                        .font(.headline)
                        .automaticCompliance(named: "CatAAuditTitle")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Category A — identifier audit (#197)")
                .accessibilityIdentifier(Self.auditTitleUITestID)

                // `children: .combine` surfaces one element with explicit identifier for XCUITest (Issue #197).
                sectionCaption("Manual id on outer Group (wrapper)")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manual wins on wrapper")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Manual wins on wrapper")
                .accessibilityIdentifier("CatAManualWinsOnOuter")

                sectionCaption("Unicode + label")
                platformText("café 日本語")
                    .basicAutomaticCompliance(
                        identifierName: "CatAUnicodeText",
                        identifierLabel: "café 日本語"
                    )

                // Outer name on a Text — layout containers often do not surface a stable identifier to XCTest.
                Group {
                    Text("Nested named components")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .automaticCompliance(named: "CatANestedOuter")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Nested named components")
                .accessibilityIdentifier(Self.nestedOuterUITestID)
                platformVStack(alignment: .leading, spacing: 8) {
                    Group {
                        platformButton(label: "CatA Nested Action", id: nil) { }
                            .automaticCompliance(named: "CatANestedInnerButton")
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("CatA Nested Action")
                    .accessibilityIdentifier(Self.nestedInnerUITestID)
                }

                sectionCaption("Manual-only identifier (explicit id via platformButton id:)")
                platformButton(label: "CatA manual only visible", id: "CatA_ManualOnly_StaticText") { }

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

                // exactNamed: minimal identifier string (no namespace) — audit exactNamed* / minimal IDs.
                sectionCaption("exactNamed (minimal identifier)")
                Group {
                    platformText("Exact named minimal")
                        .exactNamed("CatAExactNamed")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Exact named minimal")
                .accessibilityIdentifier("CatAExactNamed")

                // accessibilityLabel parameter (AutomaticAccessibilityLabelTests / VoiceOver string).
                sectionCaption("Explicit accessibilityLabel (basicAutomaticCompliance)")
                platformText("Label row")
                    .basicAutomaticCompliance(
                        identifierName: "CatALabelAndId",
                        identifierLabel: "Visible",
                        accessibilityLabel: "VoiceOver Cat A Label"
                    )

                // Empty identifierName: generator falls back to "element" and includes sanitized label (audit empty string).
                sectionCaption("Empty identifier name (sanitized label segment)")
                platformText("Empty name row")
                    .basicAutomaticCompliance(
                        identifierName: "",
                        identifierLabel: "Empty name row"
                    )

                // Mid-hierarchy: `enableGlobalAutomaticCompliance` on a sub-stack (auto row only). Sibling is a manual
                // combined wrapper (VStack + Text) so the identifier matches XCUITest, same as "Manual wins on wrapper".
                sectionCaption("Mid-hierarchy: auto sibling + manual sibling")
                // Keep siblings as direct children of the audit stack — an extra wrapping `platformVStack` around
                // both rows prevented the manual `accessibilityIdentifier` from appearing in XCUITest (#197).
                platformVStack(alignment: .leading, spacing: 8) {
                    platformText("CatA mid auto")
                        .basicAutomaticCompliance(
                            identifierName: "CatAMidAutoSibling",
                            identifierLabel: "CatA mid auto"
                        )
                }
                .enableGlobalAutomaticCompliance()
                VStack(alignment: .leading, spacing: 2) {
                    Text("CatA mid opt-out label")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("CatA mid opt-out label")
                .accessibilityIdentifier("CatAMid_LocalOptOut_Static")
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
