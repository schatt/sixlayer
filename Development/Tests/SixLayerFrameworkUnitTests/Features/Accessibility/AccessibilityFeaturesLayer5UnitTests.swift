import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * Unit-lane coverage for AccessibilityFeaturesLayer5.swift (#454).
 * VI suite under ViewInspectorTests/ is excluded from SLF-*-UnitTests.
 */

@Suite("Accessibility Features Layer5 Unit", DefaultRuntimeCapabilityIsolationTrait())
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
        #expect(ContrastLevel.allCases.count == 3)
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

@Suite("Accessibility Features Layer5 hosts (#470)", HostedViewTestIsolationTrait())
struct AccessibilityFeaturesLayer5HostUnitTests {

    @Test @MainActor
    func accessibilityEnhancedUsesNamedCompliance() {
        hostExpectingNamedCompliance("accessibility-enhanced") {
            Text("Content").accessibilityEnhanced()
        }
    }

    @Test @MainActor
    func voiceOverEnabledUsesNamedCompliance() {
        hostExpectingNamedCompliance("voiceOverEnabled") {
            Text("Content").voiceOverEnabled()
        }
    }

    @Test @MainActor
    func keyboardNavigableHosts() {
        hostView {
            Text("Content").keyboardNavigable()
        }
    }

    @Test @MainActor
    func highContrastEnabledHosts() {
        hostView {
            Text("Content").highContrastEnabled()
        }
    }

    @Test @MainActor
    func accessibilityTestingViewUsesNamedCompliance() {
        hostExpectingNamedCompliance("AccessibilityTestingView") {
            AccessibilityTestingView()
        }
    }

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let (hosted, log) = TestSetupUtilities.hostRootPlatformViewNamedDebugLog(view())
        #expect(hosted != nil)
        #expect(
            log.contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
    }

    @MainActor
    private func hostView<V: View>(@ViewBuilder _ view: () -> V) {
        #if os(watchOS)
        return
        #else
        #expect(TestSetupUtilities.hostRootPlatformView(view(), forceLayout: true) != nil)
        #endif
    }
}
