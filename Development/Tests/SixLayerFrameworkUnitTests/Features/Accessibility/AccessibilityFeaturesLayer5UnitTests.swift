import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * Unit-lane coverage for AccessibilityFeaturesLayer5.swift (#454).
 *
 * ViewInspectorTests/…/AccessibilityFeaturesLayer5Tests.swift exercises some of
 * this surface but is excluded from SLF-*-UnitTests. Epic #426 measures unit lanes.
 */

@Suite("Accessibility Features Layer5 Unit")
struct AccessibilityFeaturesLayer5UnitTests {

    // MARK: - AccessibilityConfig

    @Test func testAccessibilityConfigDefaultsEnableAllFeatures() {
        let config = AccessibilityConfig()
        #expect(config.enableVoiceOver)
        #expect(config.enableKeyboardNavigation)
        #expect(config.enableHighContrast)
        #expect(config.enableReducedMotion)
        #expect(config.enableLargeText)
    }

    @Test func testAccessibilityConfigCustomInitializerStoresFlags() {
        let config = AccessibilityConfig(
            enableVoiceOver: false,
            enableKeyboardNavigation: true,
            enableHighContrast: false,
            enableReducedMotion: true,
            enableLargeText: false
        )
        #expect(!config.enableVoiceOver)
        #expect(config.enableKeyboardNavigation)
        #expect(!config.enableHighContrast)
        #expect(config.enableReducedMotion)
        #expect(!config.enableLargeText)
    }

    // MARK: - Enums

    @Test func testVoiceOverPriorityCasesAndRawValues() {
        #expect(VoiceOverPriority.allCases.count == 4)
        #expect(VoiceOverPriority.low.rawValue == "Low")
        #expect(VoiceOverPriority.normal.rawValue == "Normal")
        #expect(VoiceOverPriority.high.rawValue == "High")
        #expect(VoiceOverPriority.critical.rawValue == "Critical")
    }

    @Test func testFocusDirectionCasesAndRawValues() {
        #expect(FocusDirection.allCases.count == 4)
        #expect(FocusDirection.next.rawValue == "Next")
        #expect(FocusDirection.previous.rawValue == "Previous")
        #expect(FocusDirection.first.rawValue == "First")
        #expect(FocusDirection.last.rawValue == "Last")
    }

    @Test func testContrastLevelCasesAndRawValues() {
        // Deliberate red for #454: wrong count until locked to production (3).
        #expect(ContrastLevel.allCases.count == 99)
        #expect(ContrastLevel.normal.rawValue == "Normal")
        #expect(ContrastLevel.high.rawValue == "High")
        #expect(ContrastLevel.extreme.rawValue == "Extreme")
    }

    @Test func testTestStatusCasesAndRawValues() {
        #expect(TestStatus.allCases.count == 4)
        #expect(TestStatus.passed.rawValue == "Passed")
        #expect(TestStatus.warning.rawValue == "Warning")
        #expect(TestStatus.failed.rawValue == "Failed")
        #expect(TestStatus.skipped.rawValue == "Skipped")
    }

    // MARK: - HighContrastManager

    @Test @MainActor func testHighContrastManagerPassesThroughWhenDisabled() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }
        RuntimeCapabilityDetection.setTestHighContrast(false)
        let manager = HighContrastManager()
        #expect(!manager.isHighContrastEnabled)
        let base = Color.red
        manager.contrastLevel = .extreme
        #expect(manager.getHighContrastColor(base) == base)
    }

    @Test @MainActor func testHighContrastManagerAppliesOpacityWhenEnabled() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }
        RuntimeCapabilityDetection.setTestHighContrast(true)
        let manager = HighContrastManager()
        #expect(manager.isHighContrastEnabled)
        let base = Color.blue
        manager.contrastLevel = .normal
        #expect(manager.getHighContrastColor(base) == base)
        manager.contrastLevel = .high
        #expect(manager.getHighContrastColor(base) == base.opacity(0.9))
        manager.contrastLevel = .extreme
        #expect(manager.getHighContrastColor(base) == base.opacity(0.8))
    }

    // MARK: - VoiceOverManager

    @Test @MainActor func testVoiceOverManagerAnnounceRecordsLastAnnouncement() {
        let manager = VoiceOverManager()
        manager.announce("Hello accessibility", priority: .high)
        #expect(manager.lastAnnouncement == "Hello accessibility")
    }

    // MARK: - AccessibilityTestingManager

    @Test @MainActor func testAccessibilityTestingManagerProducesExpectedResults() async {
        let manager = AccessibilityTestingManager()
        #expect(manager.testResults.isEmpty)
        #expect(!manager.isRunningTests)

        manager.runAccessibilityTests()
        // generateTestResults runs on MainActor Task — yield until settled
        for _ in 0..<50 {
            if !manager.isRunningTests && !manager.testResults.isEmpty { break }
            await Task.yield()
        }

        #expect(!manager.isRunningTests)
        #expect(manager.testResults.count == 4)
        #expect(manager.testResults.map(\.testName).contains("VoiceOver Labels"))
        #expect(manager.testResults.map(\.testName).contains("Keyboard Navigation"))
        #expect(manager.testResults.map(\.testName).contains("Color Contrast"))
        #expect(manager.testResults.map(\.testName).contains("Focus Indicators"))
        #expect(manager.testResults.first { $0.testName == "Focus Indicators" }?.status == .warning)
        #expect(manager.testResults.filter { $0.status == .passed }.count == 3)
    }

    @Test func testAccessibilityTestResultStoresFields() {
        let result = AccessibilityTestResult(
            testName: "Sample",
            status: .failed,
            description: "Missing label"
        )
        #expect(result.testName == "Sample")
        #expect(result.status == .failed)
        #expect(result.description == "Missing label")
        #expect(result.timestamp <= Date())
    }
}
