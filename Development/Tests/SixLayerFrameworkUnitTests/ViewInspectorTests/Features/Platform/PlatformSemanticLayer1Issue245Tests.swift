import SwiftUI
import Testing
@testable import SixLayerFramework

/// Issue #245 / gh-243: generic Layer 1 presentation surfaces must not use `automaticCompliance(named:)`
/// over caller-owned or runtime-unknown content (NamedAutomaticComplianceModifier masks inner a11y).
@Suite("Platform Semantic Layer 1 — Issue 245")
open class PlatformSemanticLayer1Issue245Tests: BaseTestClass {

    private nonisolated static func issue245_namedAutomaticComplianceFingerprint(componentName: String) -> String {
        "NAMED MODIFIER DEBUG: body() called for '\(componentName)'"
    }

    /// Shells that must not emit `NamedAutomaticComplianceModifier` debug for these component names.
    @MainActor
    private static func issue245_presentationShells(hints: PresentationHints) -> [(fingerprintName: String, view: AnyView)] {
        struct UnknownRuntimeContent {
            let marker = 1
        }

        let formFields: [DynamicFormField] = [
            DynamicFormField(
                id: "field1",
                textContentType: .emailAddress,
                contentType: .text,
                label: "Email",
                placeholder: "Enter email",
                description: nil,
                isRequired: true,
                validationRules: nil,
                options: nil,
                defaultValue: nil
            )
        ]

        let settings: [SettingsSectionData] = [
            SettingsSectionData(title: "General", items: [
                SettingsItemData(key: "k1", title: "Setting 1", type: .text, value: "v")
            ])
        ]

        return [
            ("GenericFormView", AnyView(GenericFormView(fields: formFields, hints: hints))),
            ("GenericContentView", AnyView(GenericContentView(content: UnknownRuntimeContent(), hints: hints))),
            ("BasicValueView", AnyView(platformPresentBasicValue_L1(value: 42, hints: hints))),
            ("BasicArrayView", AnyView(platformPresentBasicArray_L1(array: [1, 2, 3], hints: hints))),
            ("GenericFallbackView", AnyView(GenericContentView(content: UnknownRuntimeContent(), hints: hints))),
            ("GenericSettingsView", AnyView(GenericSettingsView(settings: settings, hints: hints))),
            (
                "platformResponsiveCard_L1",
                AnyView(
                    platformResponsiveCard_L1(content: { Text("ignored") }, hints: hints)
                )
            )
        ]
    }

    @Test @MainActor
    func testIssue245_genericPresentationShellsDoNotUseNamedAutomaticComplianceModifier() async {
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        for shell in Self.issue245_presentationShells(hints: hints) {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                let host = Self.hostRootPlatformView(
                    shell.view,
                    forceLayout: true,
                    accessibilityIdentifierConfig: isolated
                )
                #expect(host != nil, "\(shell.fingerprintName) should host")
                let log = isolated.getDebugLog()
                let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(componentName: shell.fingerprintName)
                #expect(
                    !log.contains(fingerprint),
                    "\(shell.fingerprintName) must not use NamedAutomaticComplianceModifier (issue #245); log sample: \(String(log.suffix(500)))"
                )
            }
        }
    }
}
