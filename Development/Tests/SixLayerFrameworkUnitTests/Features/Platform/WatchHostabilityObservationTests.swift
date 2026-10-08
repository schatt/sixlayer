//
//  WatchHostabilityObservationTests.swift
//  SixLayerFrameworkTests
//
//  Watch unit lane cannot host SwiftUI (#379). Observation must say
//  unavailable instead of reporting a false "not hostable" / "no Form".
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Watch hostability observation", HostedViewTestIsolationTrait())
struct WatchHostabilityObservationTests {

    @Test @MainActor
    func observeHostability_matchesLane() {
        let view = Text("379-host")
        let observation = PlatformContainerStructureAssertions.observeHostability(view)
        #if os(watchOS)
        #expect(observation == .unavailable)
        #else
        #expect(observation == .observed(true))
        #endif
    }

    @Test @MainActor
    func observeContainsForm_typeTokenOrUnavailableOnWatch() {
        let form = Form { Text("379-form") }
        let plain = Text("379-plain")
        let formObservation = PlatformContainerStructureAssertions.observeContainsForm(form)
        let plainObservation = PlatformContainerStructureAssertions.observeContainsForm(plain)
        #expect(formObservation == .observed(true))
        #if os(watchOS)
        #expect(plainObservation == .unavailable)
        #else
        #expect(plainObservation == .observed(false))
        #endif
    }

    @Test @MainActor
    func observeContainsSection_typeTokenOrUnavailableOnWatch() {
        let section = Section { Text("379-section") }
        let plain = Text("379-plain")
        let sectionObservation = PlatformContainerStructureAssertions.observeContainsSection(section)
        let plainObservation = PlatformContainerStructureAssertions.observeContainsSection(plain)
        #expect(sectionObservation == .observed(true))
        #if os(watchOS)
        #expect(plainObservation == .unavailable)
        #else
        #expect(plainObservation == .observed(false))
        #endif
    }

    @Test @MainActor
    func observeContainsVStackWithoutSection_typeTokenOrUnavailableOnWatch() {
        let stack = VStack { Text("379-stack") }
        let section = Section { Text("379-section") }
        let plain = Text("379-plain")
        #expect(
            PlatformContainerStructureAssertions.observeContainsVStackWithoutSection(stack)
                == .observed(true)
        )
        #expect(
            PlatformContainerStructureAssertions.observeContainsVStackWithoutSection(section)
                == .observed(false)
        )
        #if os(watchOS)
        #expect(
            PlatformContainerStructureAssertions.observeContainsVStackWithoutSection(plain)
                == .unavailable
        )
        #else
        #expect(
            PlatformContainerStructureAssertions.observeContainsVStackWithoutSection(plain)
                == .observed(false)
        )
        #endif
    }

    /// `verifyViewContainsText` must not fail the watch lane by treating an
    /// unobservable host as "not hostable". On lanes that can host, the smoke
    /// still requires a successful host.
    @Test @MainActor
    func textSmoke_doesNotClaimUnobservableHostability() {
        let probe = HostabilitySmokeProbe()
        probe.verifyViewContainsText(
            Text("379-smoke"),
            expectedText: "379-smoke",
            testName: "379-smoke"
        )
    }
}

private final class HostabilitySmokeProbe: BaseTestClass {}
