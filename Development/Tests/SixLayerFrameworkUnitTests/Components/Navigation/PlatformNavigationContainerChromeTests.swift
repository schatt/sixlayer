//
//  PlatformNavigationContainerChromeTests.swift
//  SixLayerFrameworkTests
//
//  Host subject-type for platformNavigation_L4 NavigationStack chrome (#638).
//  Compile-time `#if os` apply so Mirror types stay platform-truthful (#447 / #636).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform navigation container chrome")
struct PlatformNavigationContainerChromeTests {

    @Test @MainActor
    func platformNavigation_L4_wrapsNavigationStackOnCurrentHostWhenExpected() {
        let view = EmptyView().platformNavigation_L4 {
            Text("nav-root")
        }
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #if os(iOS) || os(macOS)
        #expect(
            description.contains("NavigationStack"),
            "platformNavigation_L4 should wrap NavigationStack on iOS/macOS, got: \(description)"
        )
        #else
        #expect(
            description.contains("Text") || description == "Text",
            "Secondary platforms leave navigation content unmodified, got: \(description)"
        )
        #expect(
            !description.contains("NavigationStack"),
            "Secondary platforms must not invent NavigationStack, got: \(description)"
        )
        #endif
    }
}
