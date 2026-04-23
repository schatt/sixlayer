import SwiftUI
import SixLayerFramework

/// RealUI/TestApp coverage for `platformAccessibility*` extension APIs (issue #170, Phase 2).
struct PlatformAccessibilityExtensionsAuditView: View {
    @State private var actionCount = 0
    var onBackToMain: (() -> Void)?

    var body: some View {
        platformScrollViewContainer {
            platformVStack(alignment: .leading, spacing: 16) {
                platformText("Platform Accessibility Extensions Audit")
                    .font(.headline)
                    .platformAccessibilityIdentifier("platform-a11y-audit-title")

                platformText("Label demo")
                    .platformAccessibilityLabel("Platform label demo")
                    .platformAccessibilityIdentifier("platform-a11y-label-row")

                platformText("Hint demo")
                    .platformAccessibilityHint("Describes how this row should be read by assistive technologies")
                    .platformAccessibilityIdentifier("platform-a11y-hint-row")

                platformText("Value demo")
                    .platformAccessibilityValue("Current value is 42 percent")
                    .platformAccessibilityIdentifier("platform-a11y-value-row")

                platformText("Add traits demo")
                    .platformAccessibilityAddTraits(.isButton)
                    .platformAccessibilityIdentifier("platform-a11y-add-traits-row")

                platformText("Remove traits demo")
                    .accessibilityAddTraits(.isButton)
                    .platformAccessibilityRemoveTraits(.isButton)
                    .platformAccessibilityIdentifier("platform-a11y-remove-traits-row")

                platformText("Sort priority high")
                    .platformAccessibilitySortPriority(100)
                    .platformAccessibilityIdentifier("platform-a11y-sort-priority-row")

                platformText("Decorative text hidden from a11y tree")
                    .platformAccessibilityHidden(true)
                    .platformAccessibilityIdentifier("platform-a11y-hidden-row")

                platformButton(label: "Custom accessibility action", id: nil) {
                    actionCount += 1
                }
                .platformAccessibilityAction(named: "Increment action count") {
                    actionCount += 1
                }
                .platformAccessibilityIdentifier("platform-a11y-action-button")

                platformText("Action count: \(actionCount)")
                    .platformAccessibilityIdentifier("platform-a11y-action-count")

                if let onBackToMain {
                    platformButton(label: "Back to Main", id: "platform-a11y-back-to-main") {
                        onBackToMain()
                    }
                }
            }
            .padding()
        }
        .platformFrame()
        .navigationTitle("Platform A11y Extensions")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}
