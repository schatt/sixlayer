//
//  AccessibilityIdentifierConfigResolutionTests.swift
//  SixLayerFrameworkTests
//
//  Identifier generation must resolve config from @TaskLocal then .shared,
//  never from SwiftUI Environment (inspect() cannot install Environment; #435).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("AccessibilityIdentifierConfig resolution")
struct AccessibilityIdentifierConfigResolutionTests {

    @Test @MainActor
    func resolvedForIdentifierGenerationUsesTaskLocalWhenSet() {
        let taskLocal = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()

        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(taskLocal) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration()
            #expect(resolved === taskLocal)
        }
    }

    @Test @MainActor
    func resolvedForIdentifierGenerationUsesSharedWhenTaskLocalMissing() {
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let resolved = AccessibilityIdentifierConfig.resolvedForIdentifierGeneration()
            #expect(resolved === AccessibilityIdentifierConfig.shared)
        }
    }

    @Test @MainActor
    func unhostedInspectionDefaultsToFalse() {
        #expect(!AccessibilityIdentifierConfig.unhostedInspection)
    }

    @Test @MainActor
    func withUnhostedInspectionSetsTaskLocalFlag() {
        AccessibilityIdentifierConfig.withUnhostedInspection {
            #expect(AccessibilityIdentifierConfig.unhostedInspection)
        }
        #expect(!AccessibilityIdentifierConfig.unhostedInspection)
    }

    @Test @MainActor
    func resolvedLocalDisableHonorsEnvironmentWhenHosted() {
        #expect(
            AccessibilityIdentifierConfig.resolvedAutomaticIdentifiersLocallyDisabled(
                environmentValue: true
            )
        )
        #expect(
            !AccessibilityIdentifierConfig.resolvedAutomaticIdentifiersLocallyDisabled(
                environmentValue: false
            )
        )
    }

    @Test @MainActor
    func resolvedLocalDisableIgnoresEnvironmentWhenUnhosted() {
        AccessibilityIdentifierConfig.withUnhostedInspection {
            #expect(
                !AccessibilityIdentifierConfig.resolvedAutomaticIdentifiersLocallyDisabled(
                    environmentValue: true
                ),
                "inspect() cannot install Environment; unhosted path must not treat disable as set"
            )
        }
    }

    @Test @MainActor
    func unhostedInspectionSelectUsesHostedBranchByDefault() {
        let selected = UnhostedInspection.select(unhosted: { "unhosted" }, hosted: { "hosted" })
        #expect(selected == "hosted")
    }

    @Test @MainActor
    func unhostedInspectionSelectUsesUnhostedBranchWhenInspecting() {
        AccessibilityIdentifierConfig.withUnhostedInspection {
            let selected = UnhostedInspection.select(unhosted: { "unhosted" }, hosted: { "hosted" })
            #expect(
                selected == "unhosted",
                "inspect() cannot install Environment or StateObject; unhosted branch must run"
            )
        }
    }

    /// TestApp injects a non-shared config via Environment (#247). Hosted generation must use it
    /// so XCUI sees `SixLayer.main.ui…` (#437). inspect() still must not instantiate Environment.
    @Test @MainActor
    func hostedViewSeesEnvironmentIdentifierConfig() {
        let envConfig = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        envConfig.namespace = "EnvNS"

        let identifiers = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let view = EnvironmentIdentifierConfigProbeView()
                .environment(\.accessibilityIdentifierConfig, envConfig)
            let hosted = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: nil
            )
            return findAllAccessibilityIdentifiersFromPlatformView(hosted)
        }

        #expect(
            identifiers.contains(where: { $0.contains("EnvNS") }),
            "UIHostingController must propagate accessibilityIdentifierConfig Environment. Got \(identifiers)"
        )
    }

    /// TestApp injects a non-shared config via Environment (#247). Hosted generation must use it
    /// so XCUI sees `SixLayer.main.ui…` (#437). inspect() still must not instantiate Environment.
    @Test @MainActor
    func hostedIdentifierGenerationUsesEnvironmentConfigWhenTaskLocalMissing() {
        let envConfig = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        envConfig.namespace = "EnvNS"
        envConfig.enableAutoIDs = true
        envConfig.globalAutomaticAccessibilityIdentifiers = true
        envConfig.enableUITestIntegration = true
        envConfig.includeComponentNames = true
        envConfig.includeElementTypes = true

        let identifiers = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let view = Text("probe")
                .named("EnvProbe")
                .environment(\.accessibilityIdentifierConfig, envConfig)
            let hosted = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: nil
            )
            return findAllAccessibilityIdentifiersFromPlatformView(hosted)
        }

        #expect(
            identifiers.contains(where: { $0.contains("EnvNS") }),
            "Hosted views must honor Environment identifier config (TestApp #247). Got \(identifiers)"
        )
    }

    /// Category A global-off UITest (`-CategoryAGlobalAutoOff`) sets the flag on the Environment
    /// instance, not `.shared`. Hosted `basicAutomaticCompliance` must not emit the suppressed name.
    @Test @MainActor
    func hostedAutomaticComplianceHonorsEnvironmentGlobalOffWhenTaskLocalMissing() {
        let envConfig = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        envConfig.namespace = "EnvNS"
        envConfig.enableAutoIDs = true
        envConfig.globalAutomaticAccessibilityIdentifiers = false
        envConfig.enableUITestIntegration = true
        envConfig.includeComponentNames = true
        envConfig.includeElementTypes = true

        let identifiers = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let view = Text("probe")
                .basicAutomaticCompliance(identifierName: "CatAAutoSuppressed")
                .environment(\.accessibilityIdentifierConfig, envConfig)
            let hosted = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: nil
            )
            return findAllAccessibilityIdentifiersFromPlatformView(hosted)
        }

        #expect(
            !identifiers.contains(where: { $0.contains("CatAAutoSuppressed") }),
            "Hosted automatic compliance must honor Environment global-off (TestApp #247). Got \(identifiers)"
        )
    }
}

private struct EnvironmentIdentifierConfigProbeView: View {
    @Environment(\.accessibilityIdentifierConfig) private var environmentConfig

    var body: some View {
        let namespace = environmentConfig?.namespace ?? "nil-env"
        Text(namespace)
            .accessibilityIdentifier(namespace)
    }
}
