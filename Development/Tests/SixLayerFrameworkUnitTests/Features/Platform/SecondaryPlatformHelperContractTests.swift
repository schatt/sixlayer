//
//  SecondaryPlatformHelperContractTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane sample of #219 container and drop-in contracts.
//  ViewInspectorTests/** is excluded from tvOS, watchOS, and visionOS unit targets,
//  so those lanes never executed the converted smokes. This suite is that sample (#380).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Secondary platform helper contracts", HostedViewTestIsolationTrait())
struct SecondaryPlatformHelperContractTests {

    /// watchOS has no UIHostingController harness (#379). visionOS unit tests have no
    /// UIWindowScene, so `hostRootPlatformView` returns nil instead of hanging (#380).
    private static var hostsPlatformViews: Bool {
        #if os(watchOS) || os(visionOS)
        false
        #else
        true
        #endif
    }

    @Test @MainActor func testPlatformFormContainer_ContainsForm() {
        let view = EmptyView().platformFormContainer {
            Text("FormOwnedMarker")
        }
        expectStructure(
            view,
            PlatformContainerStructureAssertions.containsForm(view)
        )
    }

    @Test @MainActor func testPlatformSectionContainer_ContainsSection() {
        let view = EmptyView().platformFormContainer {
            platformSectionContainer {
                Text("SectionRowMarker")
            }
        }
        expectStructure(
            view,
            PlatformContainerStructureAssertions.containsSection(view)
        )
    }

    @Test @MainActor func testPlatformGroupedInsetContainer_IsVStackWithoutSection() {
        let view = EmptyView().platformGroupedInsetContainer {
            Text("InsetMarker")
        }
        expectStructure(
            view,
            PlatformContainerStructureAssertions.containsVStackWithoutSection(view)
        )
    }

    @Test @MainActor func testDropInTextField_IsHostable() {
        let view = platformTextField("Enter name", text: .constant(""))
        #expect(PlatformContainerStructureAssertions.isHostable(view) == Self.hostsPlatformViews)
    }

    @Test @MainActor func testDropInToggleAndButton_AreHostable() {
        let toggle = platformToggle("Enable notifications", isOn: .constant(false))
        let button = platformButton(label: "Save") { }
        #expect(PlatformContainerStructureAssertions.isHostable(toggle) == Self.hostsPlatformViews)
        #expect(PlatformContainerStructureAssertions.isHostable(button) == Self.hostsPlatformViews)
    }

    /// watchOS only checks that hosting is unavailable. visionOS still checks structure
    /// because that path does not need a window. Other platforms require a hosted match.
    @MainActor
    private func expectStructure<V: View>(_ view: V, _ matches: Bool) {
        #if os(watchOS)
        #expect(!PlatformContainerStructureAssertions.isHostable(view))
        #else
        #expect(matches)
        if !Self.hostsPlatformViews {
            #expect(!PlatformContainerStructureAssertions.isHostable(view))
        }
        #endif
    }
}
