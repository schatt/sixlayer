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

        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
        #if os(iOS) || os(watchOS)
        #expect(RuntimeCapabilityDetection.supportsTouch)
        #else
        #expect(!RuntimeCapabilityDetection.supportsTouch)
        #endif
        #else
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)

        #expect(!RuntimeCapabilityDetection.supportsAssistiveTouch)
        #endif
    }

    @Test("Vision framework enable cascades to OCR")
    func testVisionFrameworkEnableCascadesToOCR() async throws {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.Vision.setTestIsFrameworkAvailable(false)
        RuntimeCapabilityDetection.Vision.setTestIsFrameworkAvailable(true)

        #if os(tvOS) || os(watchOS)
        #expect(!RuntimeCapabilityDetection.Vision.isFrameworkAvailable)
        #expect(!RuntimeCapabilityDetection.Vision.supportsOCR)
        #else
        #expect(RuntimeCapabilityDetection.Vision.isFrameworkAvailable)
        #expect(RuntimeCapabilityDetection.Vision.supportsOCR)
        #endif
    }

    @Test("Haptic feedback does not require touch support")
    func testHapticFeedbackDoesNotRequireTouchSupport() async throws {
        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        RuntimeCapabilityDetection.setTestHapticFeedback(true)

        #expect(RuntimeCapabilityDetection.supportsHapticFeedback)
        #if !(os(iOS) || os(watchOS))
        #expect(!RuntimeCapabilityDetection.supportsTouch)
        #endif
    }
}
