//
//  PlatformIOSOptimizationsLayer5Tests.swift
//  SixLayerFrameworkTests
//
//  Executing coverage for remaining PlatformIOSOptimizationsLayer5 APIs (#424).
//  Haptic / IOSHapticStyle covered by #423 — not duplicated here.
//

import SwiftUI
import Testing
@testable import SixLayerFramework
#if canImport(ViewInspector)
import ViewInspector
#endif

@Suite("Platform iOS Optimizations Layer 5")
struct PlatformIOSOptimizationsLayer5Tests {

    // MARK: - IOSAnimationType (iOS)

    #if os(iOS)
    /// All five animation types must be distinct case names (enum is not `CaseIterable`).
    @Test
    func iosAnimationTypeCasesAreDistinct() {
        let names = iosAnimationTypeCaseNames
        #expect(
            Set(names).count == 5,
            "IOSAnimationType must expose five distinct cases, got: \(names)"
        )
    }

    private var iosAnimationTypeCaseNames: [String] {
        [
            String(describing: IOSAnimationType.spring),
            String(describing: IOSAnimationType.easeIn),
            String(describing: IOSAnimationType.easeOut),
            String(describing: IOSAnimationType.easeInOut),
            String(describing: IOSAnimationType.linear)
        ]
    }

    /// Each animation type is applied so the production `switch` is exercised.
    /// Subject wraps via `_AnimationModifier` (locked from deliberate-red `got:`).
    @Test @MainActor
    func platformIOSAnimationAppliesEachType() {
        for type in [
            IOSAnimationType.spring,
            .easeIn,
            .easeOut,
            .easeInOut,
            .linear
        ] {
            let view = Text("anim-root").platformIOSAnimation(type: type, duration: 0.2)
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_AnimationModifier")
        }
    }
    #endif

    // MARK: - Swipe threshold decision

    @Test
    func swipeDirectionRecognizesCardinalSwipes() {
        #expect(platformIOSSwipeDirection(from: CGSize(width: -101, height: 0)) == .left)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 101, height: 0)) == .right)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 0, height: -101)) == .up)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 0, height: 101)) == .down)
    }

    @Test
    func swipeDirectionRejectsAmbiguousBand() {
        // Primary axis too small
        #expect(platformIOSSwipeDirection(from: CGSize(width: -99, height: 0)) == nil)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 99, height: 0)) == nil)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 0, height: -99)) == nil)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 0, height: 99)) == nil)
        // Cross-axis outside reject band (±50) — one inverted for post-green reject proof (#424)
        #expect(platformIOSSwipeDirection(from: CGSize(width: -150, height: 50)) == .left)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 150, height: -50)) == nil)
        #expect(platformIOSSwipeDirection(from: CGSize(width: 50, height: -150)) == nil)
        #expect(platformIOSSwipeDirection(from: CGSize(width: -50, height: 150)) == nil)
    }

    // MARK: - Pull-to-refresh sequence

    @Test
    func pullToRefreshSequenceSetsTrueCallsThenFalse() {
        var refreshing = false
        var events: [String] = []
        platformIOSPullToRefreshSequence(
            setRefreshing: {
                refreshing = $0
                events.append($0 ? "true" : "false")
            },
            onRefresh: { events.append("refresh") }
        )
        #expect(events == ["true", "refresh", "false"])
        #expect(refreshing == false)
    }

    // MARK: - Subject types (iOS wraps / non-iOS stubs)

    #if os(iOS)
    @Test @MainActor
    func platformIOSNavigationBarWrapsRootOnIOS() {
        let view = Text("nav-root").platformIOSNavigationBar(title: "Title")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NavigationTitleKey")
    }

    @Test @MainActor
    func platformIOSToolbarWrapsRootOnIOS() {
        let view = Text("toolbar-root").platformIOSToolbar { Button("Go") {} }
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "ToolbarModifier")
    }

    @Test @MainActor
    func platformIOSSwipeGesturesWrapsRootOnIOS() {
        let view = Text("swipe-root").platformIOSSwipeGestures(onSwipeLeft: {})
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "AddGestureModifier")
    }

    @Test @MainActor
    func platformIOSLayoutWrapsRootOnIOS() {
        let view = Text("layout-root").platformIOSLayout(safeAreaInsets: true, keyboardAware: false)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_SafeAreaRegionsIgnoringLayout")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "SubscriptionView")
    }

    @Test @MainActor
    func platformIOSPullToRefreshWrapsRootOnIOS() {
        let refreshing = Binding.constant(false)
        let view = Text("refresh-root").platformIOSPullToRefresh(isRefreshing: refreshing, onRefresh: {})
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "RefreshableModifier")
    }

    @Test @MainActor
    func platformIOSContextMenuWrapsRootOnIOS() {
        let view = Text("menu-root").platformIOSContextMenu { Button("Item") {} }
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "ContextMenuModifier")
    }

    @Test @MainActor
    func platformIOSAccessibilityExposesLabelHintValue() throws {
        let view = Text("a11y-root").platformIOSAccessibility(
            label: "Label-A",
            hint: "Hint-B",
            value: "Value-C",
            traits: .isButton
        )
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        #if canImport(ViewInspector)
        let inspected = try view.inspect()
        #expect(try inspected.accessibilityLabel().string() == "Label-A")
        #expect(try inspected.accessibilityHint().string() == "Hint-B")
        #expect(try inspected.accessibilityValue().string() == "Value-C")
        #else
        Issue.record("ViewInspector unavailable — cannot observe accessibility contract")
        #endif
    }
    #endif

    #if os(macOS)
    @Test @MainActor
    func platformIOSNavigationBarStubPreservesRootOnMacOS() {
        let view = Text("nav-root").platformIOSNavigationBar(title: "Title")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }

    @Test @MainActor
    func platformIOSAnimationStubPreservesRootOnMacOS() {
        let view = Text("anim-root").platformIOSAnimation()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }

    @Test @MainActor
    func platformIOSSwipeGesturesStubPreservesRootOnMacOS() {
        let view = Text("swipe-root").platformIOSSwipeGestures(onSwipeLeft: {})
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }

    @Test @MainActor
    func platformIOSLayoutStubPreservesRootOnMacOS() {
        let view = Text("layout-root").platformIOSLayout()
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
    }

    @Test @MainActor
    func platformIOSAccessibilityExposesLabelHintValueOnMacOS() throws {
        let view = Text("a11y-root").platformIOSAccessibility(
            label: "Label-A",
            hint: "Hint-B",
            value: "Value-C"
        )
        #if canImport(ViewInspector)
        let inspected = try view.inspect()
        #expect(try inspected.accessibilityLabel().string() == "Label-A")
        #expect(try inspected.accessibilityHint().string() == "Hint-B")
        #expect(try inspected.accessibilityValue().string() == "Value-C")
        #else
        Issue.record("ViewInspector unavailable — cannot observe accessibility contract")
        #endif
    }
    #endif
}
