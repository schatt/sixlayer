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
        if Self.hostsPlatformViews {
            #expect(
                PlatformContainerStructureAssertions.containsForm(view),
                "platformFormContainer should wrap content in Form"
            )
        } else {
            #expect(!PlatformContainerStructureAssertions.isHostable(view))
            #if os(visionOS)
            #expect(
                PlatformContainerStructureAssertions.containsForm(view),
                "platformFormContainer should wrap content in Form"
            )
            #endif
        }
    }

    @Test @MainActor func testPlatformSectionContainer_ContainsSection() {
        let view = EmptyView().platformFormContainer {
            platformSectionContainer {
                Text("SectionRowMarker")
            }
        }
        if Self.hostsPlatformViews {
            #expect(
                PlatformContainerStructureAssertions.containsSection(view),
                "no-header platformSectionContainer should use Section inside platformFormContainer"
            )
        } else {
            #expect(!PlatformContainerStructureAssertions.isHostable(view))
            #if os(visionOS)
            #expect(
                PlatformContainerStructureAssertions.containsSection(view),
                "no-header platformSectionContainer should use Section inside platformFormContainer"
            )
            #endif
        }
    }

    @Test @MainActor func testPlatformGroupedInsetContainer_IsVStackWithoutSection() {
        let view = EmptyView().platformGroupedInsetContainer {
            Text("InsetMarker")
        }
        if Self.hostsPlatformViews {
            #expect(
                PlatformContainerStructureAssertions.containsVStackWithoutSection(view),
                "platformGroupedInsetContainer should use VStack for inset grouping without Section"
            )
        } else {
            #expect(!PlatformContainerStructureAssertions.isHostable(view))
            #if os(visionOS)
            #expect(
                PlatformContainerStructureAssertions.containsVStackWithoutSection(view),
                "platformGroupedInsetContainer should use VStack for inset grouping without Section"
            )
            #endif
        }
    }

    @Test @MainActor func testDropInTextField_IsHostable() {
        let text = State(initialValue: "")
        let view = platformTextField("Enter name", text: text.projectedValue)
        #expect(PlatformContainerStructureAssertions.isHostable(view) == Self.hostsPlatformViews)
    }

    @Test @MainActor func testDropInToggleAndButton_AreHostable() {
        let isOn = State(initialValue: false)
        let toggle = platformToggle("Enable notifications", isOn: isOn.projectedValue)
        let button = platformButton(label: "Save") { }
        #expect(PlatformContainerStructureAssertions.isHostable(toggle) == Self.hostsPlatformViews)
        #expect(PlatformContainerStructureAssertions.isHostable(button) == Self.hostsPlatformViews)
    }
}
