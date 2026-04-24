//
//  UITestContractSmokeHostView.swift
//  SixLayerFrameworkUITests
//
//  Minimal SwiftUI host for consumer navigator / contract smoke (#231).
//  Launch TestApp with argument `-OpenUITestContractSmokeHost`. Identifiers use `com.sixlayer.smoke.*` only.
//

import SwiftUI

/// Two-level navigation used by ``SixLayerUITestNavigatorConsumerSmokeUITests`` (public APIs + stable IDs).
///
/// Uses `NavigationLink(destination:)` for reliable macOS + iOS XCUITest resolution (NavigationLink(value:)
/// labels can be harder to tap consistently across platforms).
struct UITestContractSmokeHostView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("UITestContractSmokeHost")
                    .accessibilityIdentifier("com.sixlayer.smoke.ready.marker")
                    .accessibilityLabel("UITestContractSmokeHost")

                NavigationLink(destination: detailView) {
                    Text("Open detail")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier("com.sixlayer.smoke.screen.entry")
            }
            .padding()
            .navigationTitle("Smoke")
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detail body")
                .accessibilityIdentifier("com.sixlayer.smoke.route.section")
                .accessibilityLabel("Detail body")
        }
        .padding()
        .navigationTitle("Detail")
    }
}
