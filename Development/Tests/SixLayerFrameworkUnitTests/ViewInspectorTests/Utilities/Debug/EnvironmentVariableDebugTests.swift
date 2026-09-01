import Testing

import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import SixLayerFramework

/// Config-path accessibility identifier generation (env var removed in #160).
/// Do not use `findAll(Button)` here — descendant search SIGTRAPs on iOS 27 (#408).
@Suite("Environment Variable Debug", HostedViewTestIsolationTrait())
open class EnvironmentVariableDebugTests: BaseTestClass {

    /// Local `automaticCompliance(identifierName:)` still generates an ID when global auto-IDs are off.
    @Test @MainActor func testEnvironmentVariablePropagation() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = false

            let view = Button("Test") { }
                .automaticCompliance(identifierName: "EnvVarLocalEnable")

            #if canImport(ViewInspector)
            let hasID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*EnvVarLocalEnable*",
                platform: SixLayerPlatform.current,
                componentName: "EnvVarLocalEnable"
            )
            #expect(hasID, "Local automaticCompliance(identifierName:) should generate an ID when enableAutoIDs is false")
            #endif
        }
    }

    /// `globalAutomaticAccessibilityIdentifiers` (env-var replacement) plus `enableAutoIDs` generate an ID.
    @Test @MainActor func testDirectEnvironmentVariableSetting() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            guard let config = testConfig else {
                Issue.record("testConfig is nil")
                return
            }
            config.enableAutoIDs = true
            config.globalAutomaticAccessibilityIdentifiers = true

            let view = Button("Test") { }
                .automaticCompliance(identifierName: "EnvVarConfigEnable")

            #if canImport(ViewInspector)
            let hasID = testComponentComplianceSinglePlatform(
                view,
                expectedPattern: "*EnvVarConfigEnable*",
                platform: SixLayerPlatform.current,
                componentName: "EnvVarConfigEnable"
            )
            #expect(hasID, "Named automaticCompliance should generate an ID when both config flags are enabled")
            #endif
        }
    }
}
