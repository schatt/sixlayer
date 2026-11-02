//
//  UnitLaneHostHelperContractTests.swift
//  SixLayerFrameworkUnitTests
//
//  Shared unit-lane host helpers must observe nil-host on watchOS/visionOS
//  (#379/#380) and named-compliance / non-nil host on iOS/macOS (#616/#622).
//  No silent `return`.
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Unit-lane host helper contract (#622)", HostedViewTestIsolationTrait())
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
}
