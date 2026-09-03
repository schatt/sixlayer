//
//  PlatformElseStubIdentityTests.swift
//  SixLayerFrameworkTests
//
//  Opposite-lane identity coverage for public platform `#else { self }` stubs (#449).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform else stub identity")
struct PlatformElseStubIdentityTests {

    // MARK: - iOS-named APIs: identity on macOS

    #if os(macOS)
    @Test @MainActor
    func platformIOSNavigationStackEnhancementsStubPreservesRootOnMacOS() {
        let view = Text("stub-root").platformIOSNavigationStackEnhancements_L6()
        // Deliberate red (#449): invert until locked to Text.
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }

    @Test @MainActor
    func platformIOSSplitViewOptimizationsStubPreservesRootOnMacOS() {
        let view = Text("stub-root").platformIOSSplitViewOptimizations_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }

    @Test @MainActor
    func platformIOSNavigationStackOptimizationsStubPreservesRootOnMacOS() {
        let view = Text("stub-root").platformIOSNavigationStackOptimizations_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }
    #endif

    // MARK: - macOS-named APIs: identity on iOS

    #if os(iOS)
    @Test @MainActor
    func platformMacOSNavigationStackEnhancementsStubPreservesRootOnIOS() {
        let view = Text("stub-root").platformMacOSNavigationStackEnhancements_L6()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }

    @Test @MainActor
    func platformMacOSSplitViewOptimizationsStubPreservesRootOnIOS() {
        let view = Text("stub-root").platformMacOSSplitViewOptimizations_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }

    @Test @MainActor
    func platformMacOSNavigationStackOptimizationsStubPreservesRootOnIOS() {
        let view = Text("stub-root").platformMacOSNavigationStackOptimizations_L5()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotTheRootText")
    }
    #endif
}
