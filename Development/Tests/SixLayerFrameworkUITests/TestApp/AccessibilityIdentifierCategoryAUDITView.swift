//
//  AccessibilityIdentifierCategoryAUDITView.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A UI backfill — scenarios ViewInspector often cannot assert on iOS;
//  XCUITest asserts identifiers and labels via XCUIElement.
//
//  #316: optional `-CatASection=<name>` mounts one section only — no scroll-as-discovery.
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

    /// `-CatASection=title|label|wrapper|unicode|nested|manual|special|long|exact|empty|mid|disable`
    private var focusedSection: String? {
        guard let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-CatASection=") })?
            .split(separator: "=", maxSplits: 1)
            .last
        else { return nil }
        let name = String(raw).lowercased()
        return name.isEmpty ? nil : name
    }

    private func shows(_ section: String) -> Bool {
        guard let focusedSection else { return true }
        return focusedSection == section
    }

    var body: some View {
        // Deep-linked section: no ScrollView (#316). Full audit keeps scroll for manual browsing only.
        Group {
            if focusedSection != nil {
                platformVStack(alignment: .leading, spacing: 24) {
                    sectionBody
                }
                .padding()
            } else {
                platformScrollViewContainer {
                    platformVStack(alignment: .leading, spacing: 24) {
                        sectionBody
                    }
                    .padding()
                }
            }
        }
        .platformFrame()
        .navigationTitle("Category A Audit")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }

    @ViewBuilder
    private var sectionBody: some View {
        if shows("title") {
            sectionMarker("CatA_Section_Title")
            Group {
                Text("Category A — identifier audit (#197)")
                    .font(.headline)
                    .automaticCompliance(named: "CatAAuditTitle")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Category A — identifier audit (#197)")
            .accessibilityIdentifier(Self.auditTitleUITestID)
        }

        if shows("label") {
            sectionMarker("CatA_Section_Label")
            sectionCaption("Explicit accessibilityLabel (basicAutomaticCompliance)")
            platformText("Label row")
                .basicAutomaticCompliance(
                    identifierName: "CatALabelAndId",
                    identifierLabel: "Visible",
                    accessibilityLabel: "VoiceOver Cat A Label"
                )
        }

        if shows("wrapper") {
            sectionMarker("CatA_Section_Wrapper")
            sectionCaption("Manual id on outer Group (wrapper)")
            Group {
                Text("Manual wins on wrapper")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Manual wins on wrapper")
            .accessibilityIdentifier("CatAManualWinsOnOuter")
        }

        if shows("unicode") {
            sectionMarker("CatA_Section_Unicode")
            sectionCaption("Unicode + label")
            platformText("café 日本語")
                .basicAutomaticCompliance(
                    identifierName: "CatAUnicodeText",
                    identifierLabel: "café 日本語"
                )
        }

        if shows("nested") {
            sectionMarker("CatA_Section_Nested")
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
        }

        if shows("manual") {
            sectionMarker("CatA_Section_Manual")
            sectionCaption("Manual-only identifier (explicit id via platformButton id:)")
            platformButton(label: "CatA manual only visible", id: "CatA_ManualOnly_StaticText") { }
        }

        if shows("special") {
            sectionMarker("CatA_Section_Special")
            sectionCaption("Special characters in label")
            platformText("Special")
                .basicAutomaticCompliance(
                    identifierName: "CatASpecialChars",
                    identifierLabel: "Save & Load! <test>"
                )
        }

        if shows("long") {
            sectionMarker("CatA_Section_Long")
            sectionCaption("Long identifier name (sanitization)")
            platformText("Long")
                .basicAutomaticCompliance(
                    identifierName: longIdentifierName,
                    identifierLabel: "Long"
                )
        }

        if shows("exact") {
            sectionMarker("CatA_Section_Exact")
            sectionCaption("exactNamed (minimal identifier)")
            Group {
                platformText("Exact named minimal")
                    .exactNamed("CatAExactNamed")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Exact named minimal")
            .accessibilityIdentifier("CatAExactNamed")
        }

        if shows("empty") {
            sectionMarker("CatA_Section_Empty")
            sectionCaption("Empty identifier name (sanitized label segment)")
            platformText("Empty name row")
                .basicAutomaticCompliance(
                    identifierName: "",
                    identifierLabel: "Empty name row"
                )
        }

        if shows("mid") {
            sectionMarker("CatA_Section_Mid")
            sectionCaption("Mid-hierarchy: auto text + explicit platformButton id")
            platformVStack(alignment: .leading, spacing: 8) {
                platformText("CatA mid auto")
                    .basicAutomaticCompliance(
                        identifierName: "CatAMidAutoSibling",
                        identifierLabel: "CatA mid auto"
                    )
            }
            platformButton(label: "CatA mid opt-out label", id: "CatAMid_LocalOptOut_Static") { }
        }

        if shows("disable") {
            sectionMarker("CatA_Section_Disable")
            sectionCaption("Mid-hierarchy: disableAutomatic + basicAutomaticCompliance")
            platformVStack(alignment: .leading, spacing: 8) {
                platformText("CatA disable mid auto")
                    .basicAutomaticCompliance(
                        identifierName: "CatADisableMid_AutoPresent",
                        identifierLabel: "CatA disable mid auto"
                    )
                Group {
                    platformText("CatA disable mid suppressed")
                        .basicAutomaticCompliance(
                            identifierName: "CatADisableMid_LocalAutoOff",
                            identifierLabel: "CatA disable mid suppressed"
                        )
                }
                .disableAutomaticAccessibilityIdentifiers()
            }
        }
    }

    private func sectionMarker(_ id: String) -> some View {
        Text(id)
            .font(.caption2)
            .foregroundColor(.secondary)
            .accessibilityIdentifier(id)
            .accessibilityLabel(id)
    }

    private func sectionCaption(_ title: String) -> some View {
        platformText(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }
}
