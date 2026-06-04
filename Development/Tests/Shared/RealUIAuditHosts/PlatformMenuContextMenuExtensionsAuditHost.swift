//
//  PlatformMenuContextMenuExtensionsAuditHost.swift
//  SixLayerFramework
//
//  Shared RealUI (TestApp) + ViewInspector host for `platformMenu` / `platformContextMenu` (Issue #170).
//

import SwiftUI
import SixLayerFramework

struct PlatformMenuContextMenuExtensionsAuditHost: View {
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 18) {
                platformText("Platform Menu + Context Menu Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-menu-context-audit-title")

                platformText("platformContextMenu (no preview)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Long-press / secondary-click this row for context actions.")
                    .platformContextMenu {
                        Button("Context Alpha", systemImage: "a.circle", action: {})
                        Button("Context Beta", systemImage: "b.circle", action: {})
                    }
                    .accessibilityIdentifier("platform-context-menu-basic-trigger")

                platformText("platformContextMenu (with preview)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Preview host row")
                    .platformContextMenu(
                        menuItems: {
                            Button("Preview action", systemImage: "eye", action: {})
                        },
                        preview: {
                            Text("Preview body")
                                .accessibilityIdentifier("platform-context-menu-preview-body")
                        }
                    )
                    .accessibilityIdentifier("platform-context-menu-preview-trigger")

                platformText("platformMenu { } (SwiftUI Menu on iOS + macOS)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Tap for menu")
                    .font(.body)
                    .platformMenu {
                        Button("Menu item one", systemImage: "1.circle", action: {})
                        Button("Menu item two", systemImage: "2.circle", action: {})
                    }
                    .accessibilityIdentifier("platform-menu-trailing-content-host")

                platformText("platformMenu(title:content:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Title-menu label uses `Text(title)`")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .platformMenu(title: "Title menu") {
                        Button("Title menu action", systemImage: "text.badge.plus", action: {})
                    }
                    .accessibilityIdentifier("platform-menu-title-host")

                platformText("platformMenu(label:content:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Label("Overflow label", systemImage: "ellipsis.circle")
                    .platformMenu(label: Text("Custom menu label")) {
                        Button("Overflow A", action: {})
                        Button("Overflow B", action: {})
                    }
                    .accessibilityIdentifier("platform-menu-custom-label-host")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-menu-context-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Menu + Context Menu")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
