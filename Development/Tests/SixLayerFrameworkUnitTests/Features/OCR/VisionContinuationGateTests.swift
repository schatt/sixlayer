//
//  VisionContinuationGateTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Vision's request completion and `VNImageRequestHandler.perform`'s throw can
//  both try to resume one continuation. A second resume traps the process (#563).
//
//  TESTING SCOPE:
//  - The first claim wins and a second claim is rejected.
//  - Completion then perform-throw keeps the completion value.
//  - Perform-throw then a late completion keeps the throw.
//

import Testing
@testable import SixLayerFramework

private struct VisionGateProbeError: Error {}

@Suite("Vision continuation gate")
struct VisionContinuationGateTests {

    @Test func secondClaimIsRejected() {
        let gate = VisionContinuationGate()
        #expect(gate.claim())
        #expect(gate.claim() == false)
    }

    /// Completion resumes, then `perform` throws. The throw must not resume again.
    @Test func completionThenPerformThrowKeepsTheFirstResult() async throws {
        let gate = VisionContinuationGate()
        let value = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            if gate.claim() {
                continuation.resume(returning: "33.82")
            }
            if gate.claim() {
                continuation.resume(throwing: VisionGateProbeError())
            }
        }
        #expect(value == "33.82")
    }

    /// `perform` throws before a late completion. The completion must not replace the error.
    @Test func performThrowThenLateCompletionKeepsTheThrow() async {
        let gate = VisionContinuationGate()
        await #expect(throws: VisionGateProbeError.self) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                if gate.claim() {
                    continuation.resume(throwing: VisionGateProbeError())
                }
                if gate.claim() {
                    continuation.resume(returning: "late")
                }
            }
        }
    }
}
