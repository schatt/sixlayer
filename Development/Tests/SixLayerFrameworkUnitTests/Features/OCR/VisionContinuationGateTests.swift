//
//  VisionContinuationGateTests.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Vision's request completion and `VNImageRequestHandler.perform`'s throw can
//  both try to resume one continuation. A second resume traps the process (#563).
//
//  TESTING SCOPE:
//  - The first claim wins.
//  - A second claim is rejected.
//

import Testing
@testable import SixLayerFramework

@Suite("Vision continuation gate")
struct VisionContinuationGateTests {

    @Test func secondClaimIsRejected() {
        let gate = VisionContinuationGate()
        #expect(gate.claim())
        #expect(gate.claim() == false)
    }
}
