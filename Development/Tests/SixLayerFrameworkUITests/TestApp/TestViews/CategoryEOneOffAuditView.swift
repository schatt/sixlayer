//
//  CategoryEOneOffAuditView.swift
//  SixLayerFrameworkUITests
//
//  Issue #201: Category E one-off UI coverage host.
//

import SwiftUI
import SixLayerFramework
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CategoryEOneOffAuditView: View {
    @State private var clipboardState = "Clipboard state: idle"

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

                Divider()

                Text("UI test code clipboard generation")
                    .font(.headline)

                Button("Generate UI test code to clipboard") {
                    let config = AccessibilityIdentifierConfig.shared
                    config.enableDebugLogging = true
                    config.clearDebugLog()
                    config.addDebugLogEntry("Generated ID: SixLayer.category-e.clipboard.button for: category-e")
                    config.generateUITestCodeToClipboard()

                    let clipboardText = readClipboardText() ?? ""
                    clipboardState = clipboardText.contains("XCUIApplication")
                        ? "Clipboard state: generated"
                        : "Clipboard state: empty"
                }
                .accessibilityIdentifier("category-e-clipboard-generate-button")

                Text(clipboardState)
                    .accessibilityIdentifier("category-e-clipboard-state-label")
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Category E One-Off Coverage")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }

    private func readClipboardText() -> String? {
#if canImport(UIKit)
        return UIPasteboard.general.string
#elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
#else
        return nil
#endif
    }
}
