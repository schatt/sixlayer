import Testing
import SwiftUI
@testable import SixLayerFramework

//
//  PlatformToolbarPlacementTests.swift
//  SixLayerFrameworkUITests
//
//  BUSINESS PURPOSE:
//  Validates the platform toolbar placement helper functions that abstract toolbar
//  item placement across iOS, macOS, watchOS, tvOS, and visionOS platforms.
//
//  Issue #219 — one test per API with real platform-branch expects (no Bool(true) else no-ops).
//  ToolbarItemPlacement is not Equatable on all SDKs; compare via String(describing:).
//

@Suite("Platform Toolbar Placement Helpers", HostedViewTestIsolationTrait())
open class PlatformToolbarPlacementTests: BaseTestClass {
    
    private static func placementDescription(_ placement: ToolbarItemPlacement) -> String {
        String(describing: placement)
    }
    
    /// Expected confirmation placement for the compile-time platform.
    private static var expectedConfirmationPlacement: ToolbarItemPlacement {
        #if os(watchOS)
        if #available(watchOS 9.0, *) { return .confirmationAction }
        return .automatic
        #elseif os(iOS) || os(visionOS)
        if #available(iOS 16.0, *) { return .confirmationAction }
        return .navigationBarTrailing
        #elseif os(tvOS)
        if #available(tvOS 16.0, *) { return .confirmationAction }
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .automatic
        #endif
    }
    
    private static var expectedCancellationPlacement: ToolbarItemPlacement {
        #if os(watchOS)
        if #available(watchOS 9.0, *) { return .cancellationAction }
        return .automatic
        #elseif os(iOS) || os(visionOS)
        if #available(iOS 16.0, *) { return .cancellationAction }
        return .navigationBarTrailing
        #elseif os(tvOS)
        if #available(tvOS 16.0, *) { return .cancellationAction }
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .automatic
        #endif
    }
    
    private static var expectedPrimaryPlacement: ToolbarItemPlacement {
        #if os(watchOS)
        if #available(watchOS 9.0, *) { return .primaryAction }
        return .automatic
        #elseif os(iOS) || os(visionOS)
        if #available(iOS 16.0, *) { return .primaryAction }
        return .navigationBarTrailing
        #elseif os(tvOS)
        if #available(tvOS 16.0, *) { return .primaryAction }
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .automatic
        #endif
    }
    
    private static var expectedSecondaryPlacement: ToolbarItemPlacement {
        #if os(watchOS)
        return .automatic
        #elseif os(iOS) || os(visionOS)
        if #available(iOS 16.0, *) { return .secondaryAction }
        return .navigationBarTrailing
        #elseif os(tvOS)
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .automatic
        #endif
    }
    
    private static var expectedBottomBarPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .bottomBar
        #else
        return .automatic
        #endif
    }
    
    @Test @MainActor func testConfirmationActionPlacement_MatchesPlatformContract() {
        let placement = EmptyView().platformConfirmationActionPlacement()
        #expect(
            Self.placementDescription(placement)
                == Self.placementDescription(Self.expectedConfirmationPlacement)
        )
    }
    
    @Test @MainActor func testCancellationActionPlacement_MatchesPlatformContract() {
        let placement = EmptyView().platformCancellationActionPlacement()
        #expect(
            Self.placementDescription(placement)
                == Self.placementDescription(Self.expectedCancellationPlacement)
        )
    }
    
    @Test @MainActor func testPrimaryActionPlacement_MatchesPlatformContract() {
        let placement = EmptyView().platformPrimaryActionPlacement()
        #expect(
            Self.placementDescription(placement)
                == Self.placementDescription(Self.expectedPrimaryPlacement)
        )
    }
    
    @Test @MainActor func testSecondaryActionPlacement_MatchesPlatformContract() {
        let placement = EmptyView().platformSecondaryActionPlacement()
        #expect(
            Self.placementDescription(placement)
                == Self.placementDescription(Self.expectedSecondaryPlacement)
        )
    }
    
    @Test @MainActor func testBottomBarPlacement_MatchesPlatformContract() {
        let placement = platformBottomBarPlacement()
        #expect(
            Self.placementDescription(placement)
                == Self.placementDescription(Self.expectedBottomBarPlacement)
        )
    }
    
    @Test @MainActor func testPlacementFunctions_ReturnCorrectType() {
        let testView = EmptyView()
        let confirmation = testView.platformConfirmationActionPlacement()
        let cancellation = testView.platformCancellationActionPlacement()
        let primary = testView.platformPrimaryActionPlacement()
        let secondary = testView.platformSecondaryActionPlacement()
        
        #expect(type(of: confirmation) == ToolbarItemPlacement.self)
        #expect(type(of: cancellation) == ToolbarItemPlacement.self)
        #expect(type(of: primary) == ToolbarItemPlacement.self)
        #expect(type(of: secondary) == ToolbarItemPlacement.self)
    }
}
