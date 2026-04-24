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
/// Uses a ``Button`` + ``navigationDestination(isPresented:)`` so ``UITestContractElementResolver`` hits the
/// `.button` slot first (``NavigationLink`` is often surfaced as `.link` and can be order-dependent across OS versions).
struct UITestContractSmokeHostView: View {
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("UITestContractSmokeHost")
                    .accessibilityIdentifier("com.sixlayer.smoke.ready.marker")
                    .accessibilityLabel("UITestContractSmokeHost")

                Button {
                    showDetail = true
                } label: {
                    Text("Open detail")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier("com.sixlayer.smoke.screen.entry")
            }
            .padding()
            .navigationTitle("Smoke")
            .navigationDestination(isPresented: $showDetail) {
                detailView
            }
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
