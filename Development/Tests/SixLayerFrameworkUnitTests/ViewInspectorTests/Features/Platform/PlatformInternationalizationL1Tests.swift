import Testing
import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformInternationalizationL1.swift
/// 
/// BUSINESS PURPOSE: Ensure all internationalization Layer 1 functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformInternationalizationL1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Internationalization L")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformInternationalizationL1Tests: BaseTestClass {

    /// Debug log line emitted by `NamedAutomaticComplianceModifier` when `enableDebugLogging` is on (issue #245 audit).
    private nonisolated static func issue245_namedAutomaticComplianceFingerprint(componentName: String) -> String {
        "NAMED MODIFIER DEBUG: body() called for '\(componentName)'"
    }

    /// Shells that must not use `automaticCompliance(named:)` (NamedAutomaticComplianceModifier); see #245 / gh-243.
    private nonisolated static func issue245_shellsThatMustNotUseNamedAutomaticCompliance(
        hints: InternationalizationHints
    ) -> [(name: String, view: AnyView)] {
        [
            ("platformPresentLocalizedContent_L1", platformPresentLocalizedContent_L1(content: Text("c"), hints: hints)),
            ("platformPresentLocalizedText_L1", platformPresentLocalizedText_L1(text: "t", hints: hints)),
            ("platformPresentLocalizedNumber_L1", platformPresentLocalizedNumber_L1(number: 1, hints: hints)),
            ("platformPresentLocalizedCurrency_L1", platformPresentLocalizedCurrency_L1(amount: 1, hints: hints)),
            ("platformPresentLocalizedDate_L1", platformPresentLocalizedDate_L1(date: Date(timeIntervalSince1970: 0), hints: hints)),
            ("platformPresentLocalizedTime_L1", platformPresentLocalizedTime_L1(date: Date(timeIntervalSince1970: 0), hints: hints)),
            ("platformPresentLocalizedPercentage_L1", platformPresentLocalizedPercentage_L1(value: 0.5, hints: hints)),
            ("platformPresentLocalizedPlural_L1", platformPresentLocalizedPlural_L1(word: "item", count: 2, hints: hints)),
            ("platformPresentLocalizedString_L1", platformPresentLocalizedString_L1(key: "CFBundleName", arguments: [], hints: hints)),
            ("platformRTLContainer_L1", platformRTLContainer_L1(content: Text("rtl"), hints: hints)),
            ("platformRTLHStack_L1", platformRTLHStack_L1(alignment: .center, spacing: nil, content: { Text("h") }, hints: hints)),
            ("platformRTLVStack_L1", platformRTLVStack_L1(alignment: .center, spacing: nil, content: { Text("v") }, hints: hints)),
            ("platformRTLZStack_L1", platformRTLZStack_L1(alignment: .center, content: { Text("z") }, hints: hints))
        ]
    }

    /// Issue #245 / gh-243 parity: listed i18n shells must not use `automaticCompliance(named:)` (NamedAutomaticComplianceModifier).
    @Test @MainActor
    func testIssue245_platformInternationalizationShellsDoNotUseNamedAutomaticComplianceModifier() async {
        let hints = InternationalizationHints()
        for shell in Self.issue245_shellsThatMustNotUseNamedAutomaticCompliance(hints: hints) {
            let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
            AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
                let host = Self.hostRootPlatformView(
                    shell.view,
                    forceLayout: true,
                    accessibilityIdentifierConfig: isolated
                )
                #expect(host != nil, "\(shell.name) should host")
                let log = isolated.getDebugLog()
                let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(componentName: shell.name)
                #expect(
                    !log.contains(fingerprint),
                    "\(shell.name) must not use NamedAutomaticComplianceModifier (issue #245); log sample: \(String(log.suffix(400)))"
                )
            }
        }
    }

    /// Structured L1 fields keep `automaticCompliance(named:accessibilityLabel:)` (NamedAutomaticComplianceModifier).
    @Test @MainActor
    func testIssue245_platformLocalizedTextFieldUsesNamedAutomaticComplianceModifier() async {
        let hints = InternationalizationHints()
        let view = platformLocalizedTextField_L1(
            title: "Title",
            text: .constant(""),
            hints: hints,
            accessibilityLabel: nil
        )
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            let host = Self.hostRootPlatformView(
                view,
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
            #expect(host != nil, "platformLocalizedTextField_L1 should host")
            let log = isolated.getDebugLog()
            let fingerprint = Self.issue245_namedAutomaticComplianceFingerprint(
                componentName: "platformLocalizedTextField_L1"
            )
            #expect(
                log.contains(fingerprint),
                "platformLocalizedTextField_L1 should still use NamedAutomaticComplianceModifier; log sample: \(String(log.suffix(400)))"
            )
        }
    }
    
@Test @MainActor func testPlatformPresentLocalizedContentL1GeneratesAccessibilityIdentifiersOnIOS() {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedContent_L1(
                content: platformPresentContent_L1(content: "Test Localized Content", hints: PresentationHints()),
                hints: hints
            )
        
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedContent_L1 should generate accessibility identifiers on iOS ")
        }
    }

    
    @Test @MainActor func testPlatformPresentLocalizedContentL1GeneratesAccessibilityIdentifiersOnMacOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedContent_L1(
                content: platformPresentContent_L1(content: "Test Localized Content", hints: PresentationHints()),
                hints: hints
            )
        
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedContent_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedContent_L1 should generate accessibility identifiers on macOS ")
        }
    }

    
    // MARK: - platformPresentLocalizedText_L1 Tests
    
    @Test @MainActor func testPlatformPresentLocalizedTextL1GeneratesAccessibilityIdentifiersOnIOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedText_L1(text: "Test Localized Text", hints: hints)
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedText_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedText_L1 should generate accessibility identifiers on iOS ")
        }
    }

    
    @Test @MainActor func testPlatformPresentLocalizedTextL1GeneratesAccessibilityIdentifiersOnMacOS() async {
            initializeTestConfig()
        runWithTaskLocalConfig {

            let hints = InternationalizationHints()
        
            let view = platformPresentLocalizedText_L1(text: "Test Localized Text", hints: hints)
            let hasAccessibilityID = testComponentComplianceCrossPlatform(
                view, 
                expectedPattern: "SixLayer.main.ui.*", 
                componentName: "platformPresentLocalizedText_L1"
            )
            #expect(hasAccessibilityID, "platformPresentLocalizedText_L1 should generate accessibility identifiers on macOS ")
        }
    }

}
