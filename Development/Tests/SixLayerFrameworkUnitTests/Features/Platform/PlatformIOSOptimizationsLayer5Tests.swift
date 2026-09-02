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
    /// Deliberate red: expect four unique names until locked from got: (#424).
    @Test
    func iosAnimationTypeCasesAreDistinct() {
        let names = [
            String(describing: IOSAnimationType.spring),
            String(describing: IOSAnimationType.easeIn),
            String(describing: IOSAnimationType.easeOut),
            String(describing: IOSAnimationType.easeInOut),
            String(describing: IOSAnimationType.linear)
        ]
        #expect(
            Set(names).count == 4,
            "IOSAnimationType must expose five distinct cases, got: \(names)"
        )
    }

    /// Each animation type is applied so the production `switch` is exercised.
    /// Deliberate red: dummy wrapper name until locked from got:.
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
            BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAnAnimationWrapper")
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
        // Cross-axis outside reject band (±50)
        #expect(platformIOSSwipeDirection(from: CGSize(width: -150, height: 50)) == nil)
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
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotANavigationBarWrapper")
    }

    @Test @MainActor
    func platformIOSToolbarWrapsRootOnIOS() {
        let view = Text("toolbar-root").platformIOSToolbar { Button("Go") {} }
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAToolbarWrapper")
    }

    @Test @MainActor
    func platformIOSSwipeGesturesWrapsRootOnIOS() {
        let view = Text("swipe-root").platformIOSSwipeGestures(onSwipeLeft: {})
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotASwipeWrapper")
    }

    @Test @MainActor
    func platformIOSLayoutWrapsRootOnIOS() {
        let view = Text("layout-root").platformIOSLayout(safeAreaInsets: true, keyboardAware: false)
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotALayoutWrapper")
    }

    @Test @MainActor
    func platformIOSPullToRefreshWrapsRootOnIOS() {
        let refreshing = Binding.constant(false)
        let view = Text("refresh-root").platformIOSPullToRefresh(isRefreshing: refreshing, onRefresh: {})
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotARefreshWrapper")
    }

    @Test @MainActor
    func platformIOSContextMenuWrapsRootOnIOS() {
        let view = Text("menu-root").platformIOSContextMenu { Button("Item") {} }
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "NotAContextMenuWrapper")
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
        // Deliberate red: wrong strings until locked from got:
        let label = try inspected.accessibilityLabel().string()
        let hint = try inspected.accessibilityHint().string()
        let value = try inspected.accessibilityValue().string()
        #expect(label == "Wrong-Label")
        #expect(hint == "Wrong-Hint")
        #expect(value == "Wrong-Value")
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

    /// Deliberate red on macOS too: wrong label until locked (cross-platform a11y modifiers).
    @Test @MainActor
    func platformIOSAccessibilityExposesLabelHintValueOnMacOS() throws {
        let view = Text("a11y-root").platformIOSAccessibility(
            label: "Label-A",
            hint: "Hint-B",
            value: "Value-C"
        )
        #if canImport(ViewInspector)
        let inspected = try view.inspect()
        #expect(try inspected.accessibilityLabel().string() == "Wrong-Label")
        #expect(try inspected.accessibilityHint().string() == "Wrong-Hint")
        #expect(try inspected.accessibilityValue().string() == "Wrong-Value")
        #else
        Issue.record("ViewInspector unavailable — cannot observe accessibility contract")
        #endif
    }
    #endif
}
