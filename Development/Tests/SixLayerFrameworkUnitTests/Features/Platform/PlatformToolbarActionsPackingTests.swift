import Testing
@testable import SixLayerFramework

//
//  PlatformToolbarActionsPackingTests.swift
//  SixLayerFrameworkUnitTests
//
//  Issue #352: space-aware toolbar action packing — pure capacity policy.
//

@Suite("Platform Toolbar Actions Packing")
struct PlatformToolbarActionsPackingTests {

    // MARK: - Helpers

    private func action(
        _ id: String,
        priority: Int = 0,
        overflowEligible: Bool = true
    ) -> PlatformToolbarActionDescriptor {
        PlatformToolbarActionDescriptor(
            id: id,
            priority: priority,
            overflowEligible: overflowEligible,
            label: id
        )
    }

    // MARK: - Empty / under capacity

    @Test func testPack_emptyActions_yieldsEmptyBuckets() {
        let result = PlatformToolbarActionsPacker.pack(
            [],
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == [])
        #expect(result.overflowIDs == [])
        #expect(result.showsOverflowMenu == false)
    }

    @Test func testPack_underCapacity_allVisibleNoOverflow() {
        let actions = [action("a", priority: 0), action("b", priority: 1)]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 3)
        )
        #expect(result.visibleIDs == ["a", "b"])
        #expect(result.overflowIDs == [])
        #expect(result.showsOverflowMenu == false)
    }

    @Test func testPack_exactCapacity_allVisibleNoOverflow() {
        let actions = [action("a"), action("b")]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == ["a", "b"])
        #expect(result.overflowIDs == [])
        #expect(result.showsOverflowMenu == false)
    }

    // MARK: - Over capacity → keep K, overflow rest

    @Test func testPack_overCapacity_keepsMaxVisible_restOverflow() {
        let actions = [
            action("a", priority: 0),
            action("b", priority: 1),
            action("c", priority: 2),
            action("d", priority: 3)
        ]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == ["a", "b"])
        #expect(result.overflowIDs == ["c", "d"])
        #expect(result.showsOverflowMenu == true)
    }

    @Test func testPack_priorityOrdersVisibleBeforeOverflow() {
        // Lower priority number = kept sooner (more visible).
        let actions = [
            action("low", priority: 10),
            action("high", priority: 0),
            action("mid", priority: 5)
        ]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == ["high", "mid"])
        #expect(result.overflowIDs == ["low"])
    }

    @Test func testPack_stableOrderForEqualPriority() {
        let actions = [
            action("first", priority: 1),
            action("second", priority: 1),
            action("third", priority: 1)
        ]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == ["first", "second"])
        #expect(result.overflowIDs == ["third"])
    }

    // MARK: - Pins (overflowEligible: false)

    @Test func testPack_pinnedActionsNeverEnterOverflow() {
        let actions = [
            action("overflowable-high", priority: 0, overflowEligible: true),
            action("pinned", priority: 50, overflowEligible: false),
            action("overflowable-low", priority: 1, overflowEligible: true)
        ]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        // Pinned always visible; remaining slot goes to highest-priority overflowable.
        #expect(result.visibleIDs.contains("pinned"))
        #expect(!result.overflowIDs.contains("pinned"))
        #expect(result.visibleIDs == ["pinned", "overflowable-high"])
        #expect(result.overflowIDs == ["overflowable-low"])
    }

    @Test func testPack_pinnedExceedCapacity_stillAllVisible_overflowableInOverflow() {
        let actions = [
            action("p1", priority: 0, overflowEligible: false),
            action("p2", priority: 1, overflowEligible: false),
            action("p3", priority: 2, overflowEligible: false),
            action("o1", priority: 0, overflowEligible: true)
        ]
        let result = PlatformToolbarActionsPacker.pack(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(result.visibleIDs == ["p1", "p2", "p3"])
        #expect(result.overflowIDs == ["o1"])
        #expect(result.showsOverflowMenu == true)
    }

    // MARK: - Platform defaults

    @Test func testPlatformDefaultCapacity_isPositive() {
        let capacity = PlatformToolbarActionsCapacity.platformDefault
        #expect(capacity.maxVisible >= 1)
    }

    @Test func testPlatformDefaultCapacity_matchesHostPlatform() {
        let capacity = PlatformToolbarActionsCapacity.platformDefault
        switch SixLayerPlatform.current {
        case .iOS:
            #expect(capacity.maxVisible == 2)
        case .macOS:
            #expect(capacity.maxVisible == 4)
        case .tvOS, .visionOS:
            #expect(capacity.maxVisible == 3)
        case .watchOS:
            #expect(capacity.maxVisible == 1)
        }
    }

    // MARK: - Partition (descriptor buckets)

    @Test func testPartition_overCapacity_matchesPackOrder() {
        let actions = [
            action("a", priority: 0),
            action("b", priority: 1),
            action("c", priority: 2),
            action("d", priority: 3)
        ]
        let partitioned = PlatformToolbarActionsPacker.partition(
            actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2)
        )
        #expect(partitioned.visible.map(\.id) == ["a", "b"])
        #expect(partitioned.overflow.map(\.id) == ["c", "d"])
        #expect(partitioned.visible.map(\.label) == ["a", "b"])
    }

    // MARK: - Render plan (L4 chrome)

    @Test func testRenderPlan_withMenuSupport_usesOverflowMenuWhenOverCapacity() {
        let actions = [
            action("a", priority: 0),
            action("b", priority: 1),
            action("c", priority: 2)
        ]
        let plan = PlatformToolbarActionsPacker.renderPlan(
            for: actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 2),
            supportsOverflowMenu: true
        )
        #expect(
            plan == .inlinePlusOverflowMenu(
                visibleIDs: ["a", "b"],
                overflowIDs: ["c"]
            )
        )
    }

    @Test func testRenderPlan_withMenuSupport_inlineOnlyWhenUnderCapacity() {
        let actions = [action("a"), action("b")]
        let plan = PlatformToolbarActionsPacker.renderPlan(
            for: actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 3),
            supportsOverflowMenu: true
        )
        #expect(plan == .inline(visibleIDs: ["a", "b"]))
    }

    @Test func testRenderPlan_withoutMenuSupport_omitsOverflowIDs() {
        // watch/tv/vision: no platformMenu — keep packed visible only; do not fake Menu.
        let actions = [
            action("a", priority: 0),
            action("b", priority: 1),
            action("c", priority: 2)
        ]
        let plan = PlatformToolbarActionsPacker.renderPlan(
            for: actions,
            capacity: PlatformToolbarActionsCapacity(maxVisible: 1),
            supportsOverflowMenu: false
        )
        #expect(plan == .inline(visibleIDs: ["a"]))
        if case .inlinePlusOverflowMenu = plan {
            Issue.record("Must not emit overflow menu plan when Menu unsupported")
        }
    }

    @Test func testSupportsOverflowMenu_matchesHostPlatform() {
        switch SixLayerPlatform.current {
        case .iOS, .macOS:
            #expect(PlatformToolbarActionsPacker.supportsOverflowMenu == true)
        case .watchOS, .tvOS, .visionOS:
            #expect(PlatformToolbarActionsPacker.supportsOverflowMenu == false)
        }
    }
}
