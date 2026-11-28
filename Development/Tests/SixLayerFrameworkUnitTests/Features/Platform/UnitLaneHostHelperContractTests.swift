//
//  UnitLaneHostHelperContractTests.swift
//  SixLayerFrameworkUnitTests
//
//  Shared unit-lane host helpers must observe nil-host on watchOS/visionOS
//  (#379/#380) and named-compliance / non-nil host on iOS/macOS (#616/#622/#626).
//  No silent `return`.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Unit-lane host helper contract (#622/#626)", HostedViewTestIsolationTrait())
struct UnitLaneHostHelperContractTests {

    @Test @MainActor
    func hostExpectingNamedComplianceHonorsPlatformContract() {
        TestSetupUtilities.hostExpectingNamedCompliance("SixLayerHostProbe") {
            Text("622-named").automaticCompliance(named: "SixLayerHostProbe")
        }
    }

    @Test @MainActor
    func hostExpectingPlatformRootHonorsPlatformContract() {
        TestSetupUtilities.hostExpectingPlatformRoot {
            Text("622-root")
        }
    }

    @Test @MainActor
    func hostObservingPlatformRootReturnsRootMatchingContract() {
        let hosted = TestSetupUtilities.hostObservingPlatformRoot {
            Text("626-root")
        }
        #if os(watchOS) || os(visionOS)
        #expect(hosted == nil, "unit harness cannot host on this platform (#379/#380)")
        #else
        #expect(hosted != nil)
        #endif
    }
}
