//
//  PlatformFrameSpacingUtilitiesAuditHost.swift
//  SixLayerFramework
//
//  Shared RealUI (TestApp) + ViewInspector host for frame, spacing, help, and hover utilities (Issue #170).
//

import SwiftUI
import SixLayerFramework

struct PlatformFrameSpacingUtilitiesAuditHost: View {
    var onBackToMain: (() -> Void)?
    @State private var hoverStatus = "Idle"

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 18) {
                platformText("Platform Frame / Spacing Utilities Audit")
                    .font(.headline)
                    .accessibilityIdentifier("platform-frame-spacing-audit-title")

                platformText("platformFrame() default")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Default platform frame")
                    .padding(6)
                    .background(Color.blue.opacity(0.12))
                    .platformFrame(width: 180, height: 44, alignment: .leading)
                    .accessibilityIdentifier("platform-frame-spacing-fixed-frame")

                platformText("platformFrame(min/ideal/max)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Flexible platform frame")
                    .padding(6)
                    .background(Color.green.opacity(0.12))
                    .platformFrame(minWidth: 120, idealWidth: 180, maxWidth: 240, minHeight: 36, maxHeight: 56)
                    .accessibilityIdentifier("platform-frame-spacing-flex-frame")

                platformText("platformContentSpacing(topPadding:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Top spacing")
                    .platformContentSpacing(topPadding: 8)
                    .background(Color.orange.opacity(0.12))
                    .accessibilityIdentifier("platform-frame-spacing-top-padding")

                platformText("platformContentSpacing directional")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Directional spacing")
                    .platformContentSpacing(top: 4, bottom: 6, leading: 8, trailing: 10)
                    .background(Color.purple.opacity(0.12))
                    .accessibilityIdentifier("platform-frame-spacing-directional")

                platformText("platformContentSpacing(horizontal:vertical:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Axis spacing")
                    .platformContentSpacing(horizontal: 10, vertical: 6)
                    .background(Color.gray.opacity(0.12))
                    .accessibilityIdentifier("platform-frame-spacing-axis")

                platformText("platformContentSpacing(all:)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Uniform spacing")
                    .platformContentSpacing(all: 8)
                    .background(Color.yellow.opacity(0.18))
                    .accessibilityIdentifier("platform-frame-spacing-uniform")

                platformText("platformHelp + platformHoverEffect")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                platformText("Hover/help target")
                    .platformHelp("Issue #170 help tooltip probe")
                    .platformHoverEffect { hovering in
                        hoverStatus = hovering ? "Hovering" : "Not hovering"
                    }
                    .accessibilityIdentifier("platform-frame-spacing-help-hover-target")

                platformText("Hover status: \(hoverStatus)")
                    .accessibilityIdentifier("platform-frame-spacing-hover-status")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-frame-spacing-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Frame / Spacing")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
