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
    func hostedIdentifierGenerationUsesEnvironmentConfigWhenTaskLocalMissing() {
        let envConfig = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        envConfig.namespace = "EnvNS"
        envConfig.enableAutoIDs = true
        envConfig.globalAutomaticAccessibilityIdentifiers = true
        envConfig.enableUITestIntegration = true
        envConfig.includeComponentNames = true
        envConfig.includeElementTypes = true

        let identifier = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(nil) {
            let view = Text("probe")
                .named("EnvProbe")
                .environment(\.accessibilityIdentifierConfig, envConfig)
            let hosted = TestSetupUtilities.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: nil
            )
            return getAccessibilityIdentifierForTest(view: view, hostedRoot: hosted)
        }

        #expect(
            identifier?.contains("EnvNS") == true,
            "Hosted views must honor Environment identifier config (TestApp #247). Got \(identifier ?? "nil")"
        )
    }
}
