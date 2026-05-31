import Foundation
import Testing
@testable import SixLayerFramework

/// Validates real dependency cascades in `RuntimeCapabilityDetection` test setters (#311).
@Suite("Capability Combination Validation Tests")
struct CapabilityCombinationValidationTests {

    @Test("AssistiveTouch enable cascades to touch on iOS")
    func testAssistiveTouchEnableCascadesToTouchOnIOS() async throws {
        #if os(iOS)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        #expect(RuntimeCapabilityDetection.supportsTouch)
        #expect(RuntimeCapabilityDetection.supportsAssistiveTouch)
        #else
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestAssistiveTouch(true)

        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
        #expect(!RuntimeCapabilityDetection.supportsTouch)
        #endif
    }

    @Test("Touch disable clears AssistiveTouch on iOS")
    func testTouchDisableClearsAssistiveTouchOnIOS() async throws {
        #if os(iOS)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        RuntimeCapabilityDetection.setTestAssistiveTouch(true)
        RuntimeCapabilityDetection.setTestTouchSupport(false)

        #expect(!RuntimeCapabilityDetection.supportsTouch)
        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
        #else
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)

        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
        #endif
    }

    @Test("Vision framework enable cascades to OCR on tvOS")
    func testVisionFrameworkEnableCascadesToOCROnTvOS() async throws {
        #if os(tvOS)
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestVisionFrameworkAvailable(false)
        RuntimeCapabilityDetection.setTestVisionFrameworkAvailable(true)

        #expect(RuntimeCapabilityDetection.isVisionFrameworkAvailable)
        #expect(RuntimeCapabilityDetection.supportsOCR)
        #else
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestVisionFrameworkAvailable(true)

        #expect(RuntimeCapabilityDetection.isVisionFrameworkAvailable)
        #expect(RuntimeCapabilityDetection.supportsOCR)
        #endif
    }

    @Test("Haptic feedback does not require touch support")
    func testHapticFeedbackDoesNotRequireTouchSupport() async throws {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)

        #expect(!RuntimeCapabilityDetection.supportsTouch)
        #expect(RuntimeCapabilityDetection.supportsHapticFeedback)
    }
}
