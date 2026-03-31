//
//  AccessibilityIdentifierCategoryAGlobalOffAUDITView.swift
//  SixLayerFrameworkUITests
//
//  Issue #197: Category A — when `globalAutomaticAccessibilityIdentifiers` is false (launch
//  `-CategoryAGlobalAutoOff`), `basicAutomaticCompliance` should not emit framework IDs;
//  explicit `.named` / `.exactNamed` should still apply.
//

import SwiftUI
import SixLayerFramework

/// Minimal audit surface for global-off vs explicit-identifier behavior (separate from main Category A screen).
struct AccessibilityIdentifierCategoryAGlobalOffAUDITView: View {
    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 24) {
                Group {
                    Text("Category A — global automatic IDs off")
                        .font(.headline)
                        .automaticCompliance(named: "CatAGlobalOffTitle")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Category A — global automatic IDs off")

                sectionCaption("basicAutomaticCompliance (auto ID suppressed when global off)")
                platformText("Auto suppressed")
                    .basicAutomaticCompliance(
                        identifierName: "CatAAutoSuppressed",
                        identifierLabel: "Auto suppressed"
                    )

                sectionCaption("named() when global off")
                platformText("Named when global off")
                    .named("CatANamedWhenGlobalOff")

                sectionCaption("exactNamed when global off")
                platformText("Exact when global off")
                    .exactNamed("CatAExactWhenGlobalOff")
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Category A Global Off")
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
