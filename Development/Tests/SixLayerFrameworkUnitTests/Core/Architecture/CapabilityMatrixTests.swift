import Testing


//
//  CapabilityMatrixTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Tests that the framework correctly responds to capability detection results.
//  We trust what RuntimeCapabilityDetection returns from the OS - we test what we DO with those results.
//
//  TESTING SCOPE:
//  - Framework behavior when capabilities are detected
//  - Framework behavior when capabilities are not detected
//  - Cross-platform behavior consistency
//  - Graceful degradation when capabilities are missing
//
//  METHODOLOGY:
//  - Test framework behavior based on OS-reported capabilities (not hardcoded expectations)
//  - Verify that the framework enables features when capabilities are detected
//  - Verify that the framework gracefully degrades when capabilities are missing
//  - Test across all platforms to ensure consistent behavior
//
//  PHILOSOPHY:
//  - We don't test what the OS returns (that's the OS's job)
//  - We test what our framework DOES with what the OS returns
//  - This makes tests more meaningful and less brittle
//

import SwiftUI
@testable import SixLayerFramework

/// Comprehensive capability matrix testing on the **current host**
@Suite(DefaultRuntimeCapabilityIsolationTrait())
open class CapabilityMatrixTests: BaseTestClass {
    
    // MARK: - Capability Behavior Test Matrix
    
    struct CapabilityBehaviorTest: Sendable {
        let name: String
        let testBehavior: @MainActor () -> Void
    }
    
    @MainActor static let capabilityBehaviorTests: [CapabilityBehaviorTest] = [
        // Touch Capability Behavior
        CapabilityBehaviorTest(
            name: "Touch Support Behavior",
            testBehavior: {
                let platform = SixLayerPlatform.current
                let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
                let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                    for: platform,
                    touchDetected: effectiveTouch
                )
                #expect(platform.supportsTouchGestures == effectiveTouch)
                #expect(RuntimeCapabilityDetection.minTouchTarget == expectedMin)
            }
        ),
        
        // Haptic Feedback Capability Behavior
        CapabilityBehaviorTest(
            name: "Haptic Feedback Behavior",
            testBehavior: {
                let hasHaptic = RuntimeCapabilityDetection.supportsHapticFeedback
                let hasTouch = RuntimeCapabilityDetection.supportsTouch
                if hasHaptic {
                    #expect(hasTouch, "Haptic feedback logically requires touch on current host")
                }
            }
        ),
        
        // OCR Capability Behavior
        CapabilityBehaviorTest(
            name: "OCR Behavior",
            testBehavior: {
                // Test what the framework DOES when OCR is available
                let isOCRAvailable = RuntimeCapabilityDetection.Vision.supportsOCR
                let isVisionAvailable = RuntimeCapabilityDetection.Vision.isFrameworkAvailable

                // OCR should only be available if Vision is available (logical dependency)
                #expect(isOCRAvailable == isVisionAvailable, 
                             "OCR availability should match Vision framework availability")

                if isOCRAvailable {
                    // When OCR is available, the framework should allow OCR operations
                    let testImage = PlatformImage()
                    let context = OCRContext(
                        textTypes: [.general],
                        language: .english,
                        confidenceThreshold: 0.8
                    )
                    let strategy = OCRStrategy(
                        supportedTextTypes: [.general],
                        supportedLanguages: [.english],
                        processingMode: .standard
                    )

                    // Test that OCR functions can be called without crashing
                    let service = OCRService()
                    Task {
                        do {
                            let _ = try await service.processImage(
                                testImage,
                                context: context,
                                strategy: strategy
                            )
                        } catch {
                            // Expected for test images - the important thing is it doesn't crash
                        }
                    }
                }
            }
        ),
        
        // Color Encoding Capability Behavior
        CapabilityBehaviorTest(
            name: "Color Encoding Behavior",
            testBehavior: {
                // Issue #237: pin the per-platform documented contract.
                // iOS/macOS succeed; tvOS/watchOS/visionOS throw
                // .platformNotSupported until a real implementation lands
                // under #241. Asserting "should work on all platforms" was
                // incorrect for the capability matrix.
                let testColor = Color.blue
                #if os(iOS) || os(macOS)
                do {
                    let encodedData = try platformColorEncode(testColor)
                    #expect(!encodedData.isEmpty, "Color encoding should produce data on iOS/macOS")

                    let _ = try platformColorDecode(encodedData)
                } catch {
                    Issue.record("Color encoding/decoding should work on iOS/macOS: \(error)")
                }
                #else
                #expect(throws: ColorEncodingError.self,
                        "tvOS/watchOS/visionOS: documented to throw .platformNotSupported until #241") {
                    _ = try platformColorEncode(testColor)
                }
                #endif
            }
        )
    ]
    
    // MARK: - Capability Behavior Testing
    
    /// Test that the framework correctly responds to capability detection results
    /// We trust what RuntimeCapabilityDetection returns - we test what we DO with those results
    @Test @MainActor func testCapabilityBehaviors() {
        for behaviorTest in Self.capabilityBehaviorTests {
            behaviorTest.testBehavior()
        }
    }
    
    /// Secondary plumbing (#251): touch override → minTouchTarget on **current host**.
    @Test @MainActor func testMinTouchTargetMatrixTriStatePhases() {
        defer { RuntimeCapabilityDetection.clearAllCapabilityOverrides() }

        func assertMatrixTouchLaw(phase: String) {
            let platform = SixLayerPlatform.current
            let effectiveTouch = RuntimeCapabilityDetection.supportsTouch
            let expectedMin = PlatformTestUtilities.expectedMinTouchTarget(
                for: platform,
                touchDetected: effectiveTouch
            )

            switch platform {
            case .iOS, .watchOS, .macOS, .tvOS, .visionOS:
                #expect(
                    RuntimeCapabilityDetection.minTouchTarget == expectedMin,
                    "\(phase) on \(platform): matrix minTouchTarget should match HIG"
                )
                #expect(platform.supportsTouchGestures == effectiveTouch)
            }
        }

        RuntimeCapabilityDetection.clearAllCapabilityOverrides()
        assertMatrixTouchLaw(phase: "current")

        RuntimeCapabilityDetection.setTestTouchSupport(false)
        assertMatrixTouchLaw(phase: "disabled")

        RuntimeCapabilityDetection.setTestTouchSupport(true)
        assertMatrixTouchLaw(phase: "enabled")
    }
}
