//
//  CategoryEOneOffAuditView.swift
//  SixLayerFrameworkUITests
//
//  Issue #201: Category E one-off UI coverage host.
//

import SwiftUI
import SixLayerFramework

struct CategoryEOneOffAuditView: View {
    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 20) {
                Text("Category E One-Off Coverage")
                    .font(.title2)
                    .bold()
                    .accessibilityIdentifier("Category E One-Off Coverage")

                Text("Explicit enable for plain SwiftUI")
                    .font(.headline)

                // This row keeps an explicit stable identifier for XCUI lookup
                // while also exercising explicit enable for plain SwiftUI content.
                Button("Category E Explicit Enable Row") {}
                    .enableGlobalAutomaticCompliance()
                    .exactNamed("category-e-explicit-enable-row")

                Divider()

                Text("View-level opt-out")
                    .font(.headline)

                // This row asks for an automatic identifier but disables automatic IDs
                // at the view level; no `category-e-opt-out-row` identifier should exist.
                Button("Category E Opt-Out Row") {}
                    .automaticCompliance(identifierName: "category-e-opt-out-row")
                    .disableAutomaticAccessibilityIdentifiers()
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Category E One-Off Coverage")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
