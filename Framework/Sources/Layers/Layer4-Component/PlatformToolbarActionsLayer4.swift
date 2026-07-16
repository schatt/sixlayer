import Foundation
import SwiftUI

// MARK: - Platform Toolbar Actions Packing (Issue #352)

/// Descriptor for a toolbar action used by ``PlatformToolbarActionsPacker``.
///
/// - Priority: lower number is kept in the visible bucket sooner.
/// - `overflowEligible: false` pins the action so it never enters the overflow menu
///   (even when that exceeds ``PlatformToolbarActionsCapacity/maxVisible``).
public struct PlatformToolbarActionDescriptor: Identifiable, Sendable, Equatable {
    public let id: String
    public var priority: Int
    public var overflowEligible: Bool
    public var label: String
    public var systemImage: String?

    public init(
        id: String,
        priority: Int = 0,
        overflowEligible: Bool = true,
        label: String,
        systemImage: String? = nil
    ) {
        self.id = id
        self.priority = priority
        self.overflowEligible = overflowEligible
        self.label = label
        self.systemImage = systemImage
    }
}

/// Declared visible-slot capacity for toolbar packing (prefer over live geometry).
public struct PlatformToolbarActionsCapacity: Sendable, Equatable {
    public var maxVisible: Int

    public init(maxVisible: Int) {
        self.maxVisible = maxVisible
    }

    /// Host-platform default density. Does not use system toolbar `…` collapse.
    public static var platformDefault: PlatformToolbarActionsCapacity {
        switch SixLayerPlatform.current {
        case .iOS:
            return PlatformToolbarActionsCapacity(maxVisible: 2)
        case .macOS:
            return PlatformToolbarActionsCapacity(maxVisible: 4)
        case .tvOS, .visionOS:
            return PlatformToolbarActionsCapacity(maxVisible: 3)
        case .watchOS:
            return PlatformToolbarActionsCapacity(maxVisible: 1)
        }
    }
}

/// Result of packing toolbar actions into visible vs overflow buckets.
public struct PlatformToolbarActionsPackResult: Sendable, Equatable {
    public let visibleIDs: [String]
    public let overflowIDs: [String]

    public var showsOverflowMenu: Bool {
        !overflowIDs.isEmpty
    }

    public init(visibleIDs: [String], overflowIDs: [String]) {
        self.visibleIDs = visibleIDs
        self.overflowIDs = overflowIDs
    }
}

/// Pure packing policy: keep up to capacity visible; remainder → overflow (via `platformMenu` at L4).
public enum PlatformToolbarActionsPacker {
    /// Packs `actions` into visible and overflow ID lists.
    ///
    /// Visible order is all pinned actions first (priority, then input order), then
    /// overflow-eligible actions that fit remaining slots under the same ordering.
    /// Pinned actions (`overflowEligible == false`) never enter overflow, even when
    /// that exceeds ``PlatformToolbarActionsCapacity/maxVisible``.
    public static func pack(
        _ actions: [PlatformToolbarActionDescriptor],
        capacity: PlatformToolbarActionsCapacity
    ) -> PlatformToolbarActionsPackResult {
        typealias Indexed = (index: Int, action: PlatformToolbarActionDescriptor)

        var pinned: [Indexed] = []
        var overflowable: [Indexed] = []
        for (index, action) in actions.enumerated() {
            if action.overflowEligible {
                overflowable.append((index, action))
            } else {
                pinned.append((index, action))
            }
        }

        pinned.sort(by: Self.byPriorityThenInput)
        overflowable.sort(by: Self.byPriorityThenInput)

        let maxVisible = max(0, capacity.maxVisible)
        let overflowableSlots = max(0, maxVisible - pinned.count)
        let visibleOverflowable = overflowable.prefix(overflowableSlots)
        let overflow = overflowable.dropFirst(overflowableSlots)

        return PlatformToolbarActionsPackResult(
            visibleIDs: (pinned + visibleOverflowable).map(\.action.id),
            overflowIDs: overflow.map(\.action.id)
        )
    }

    private static func byPriorityThenInput(
        _ lhs: (index: Int, action: PlatformToolbarActionDescriptor),
        _ rhs: (index: Int, action: PlatformToolbarActionDescriptor)
    ) -> Bool {
        if lhs.action.priority != rhs.action.priority {
            return lhs.action.priority < rhs.action.priority
        }
        return lhs.index < rhs.index
    }

    /// Whether this host can present overflow via ``View/platformMenu``.
    /// iOS and macOS: yes. watchOS / tvOS / visionOS: no (label passthrough only).
    public static var supportsOverflowMenu: Bool {
        switch SixLayerPlatform.current {
        case .iOS, .macOS:
            return true
        case .watchOS, .tvOS, .visionOS:
            return false
        }
    }

    /// Partitions descriptors into visible vs overflow buckets (same policy as ``pack``).
    public static func partition(
        _ actions: [PlatformToolbarActionDescriptor],
        capacity: PlatformToolbarActionsCapacity
    ) -> (visible: [PlatformToolbarActionDescriptor], overflow: [PlatformToolbarActionDescriptor]) {
        let packed = pack(actions, capacity: capacity)
        let byID = Dictionary(uniqueKeysWithValues: actions.map { ($0.id, $0) })
        let visible = packed.visibleIDs.compactMap { byID[$0] }
        let overflow = packed.overflowIDs.compactMap { byID[$0] }
        return (visible, overflow)
    }

    /// Resolves how L4 should render packed actions on the current (or declared) chrome.
    ///
    /// When `supportsOverflowMenu` is false, overflow IDs are omitted (no fake Menu).
    public static func renderPlan(
        for actions: [PlatformToolbarActionDescriptor],
        capacity: PlatformToolbarActionsCapacity,
        supportsOverflowMenu: Bool = PlatformToolbarActionsPacker.supportsOverflowMenu
    ) -> PlatformToolbarActionsRenderPlan {
        let packed = pack(actions, capacity: capacity)
        if supportsOverflowMenu, packed.showsOverflowMenu {
            return .inlinePlusOverflowMenu(
                visibleIDs: packed.visibleIDs,
                overflowIDs: packed.overflowIDs
            )
        }
        return .inline(visibleIDs: packed.visibleIDs)
    }
}

/// How ``platformToolbarActions_L4`` should present packed toolbar actions.
public enum PlatformToolbarActionsRenderPlan: Sendable, Equatable {
    /// Only these IDs appear as toolbar controls; any packed overflow is omitted.
    case inline(visibleIDs: [String])
    /// Visible IDs as toolbar controls; overflow IDs inside a `platformMenu`.
    case inlinePlusOverflowMenu(visibleIDs: [String], overflowIDs: [String])
}

/// Interactive toolbar action for ``platformToolbarActions_L4``.
public struct PlatformToolbarActionItem: Identifiable {
    public let id: String
    public var priority: Int
    public var overflowEligible: Bool
    public var label: String
    public var systemImage: String?
    public let action: () -> Void

    public init(
        id: String,
        priority: Int = 0,
        overflowEligible: Bool = true,
        label: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.priority = priority
        self.overflowEligible = overflowEligible
        self.label = label
        self.systemImage = systemImage
        self.action = action
    }

    public var descriptor: PlatformToolbarActionDescriptor {
        PlatformToolbarActionDescriptor(
            id: id,
            priority: priority,
            overflowEligible: overflowEligible,
            label: label,
            systemImage: systemImage
        )
    }
}

/// L4 toolbar content: keep-K inline actions; remainder in ``View/platformMenu`` when supported.
///
/// Does **not** rely on system toolbar fold-into-`…`. Overflow uses explicit `platformMenu`
/// on iOS/macOS; on platforms without Menu, only the packed visible bucket is shown.
public struct PlatformToolbarActionsContent: ToolbarContent {
    private let actions: [PlatformToolbarActionItem]
    private let capacity: PlatformToolbarActionsCapacity
    private let overflowTitle: String
    private let overflowSystemImage: String
    private let placement: ToolbarItemPlacement

    public init(
        actions: [PlatformToolbarActionItem],
        capacity: PlatformToolbarActionsCapacity = .platformDefault,
        overflowTitle: String = "More",
        overflowSystemImage: String = "ellipsis",
        placement: ToolbarItemPlacement = .automatic
    ) {
        self.actions = actions
        self.capacity = capacity
        self.overflowTitle = overflowTitle
        self.overflowSystemImage = overflowSystemImage
        self.placement = placement
    }

    public var body: some ToolbarContent {
        ToolbarItemGroup(placement: placement) {
            ForEach(visibleIDs, id: \.self) { id in
                if let item = actionsByID[id] {
                    toolbarActionButton(item)
                }
            }
            if !overflowIDs.isEmpty {
                Image(systemName: overflowSystemImage)
                    .accessibilityLabel(Text(overflowTitle))
                    .platformMenu {
                        ForEach(overflowIDs, id: \.self) { id in
                            if let item = actionsByID[id] {
                                toolbarActionButton(item)
                            }
                        }
                    }
            }
        }
    }

    private var actionsByID: [String: PlatformToolbarActionItem] {
        Dictionary(uniqueKeysWithValues: actions.map { ($0.id, $0) })
    }

    private var visibleIDs: [String] {
        switch renderPlan {
        case .inline(let ids):
            return ids
        case .inlinePlusOverflowMenu(let visible, _):
            return visible
        }
    }

    private var overflowIDs: [String] {
        switch renderPlan {
        case .inline:
            return []
        case .inlinePlusOverflowMenu(_, let overflow):
            return overflow
        }
    }

    private var renderPlan: PlatformToolbarActionsRenderPlan {
        PlatformToolbarActionsPacker.renderPlan(
            for: actions.map(\.descriptor),
            capacity: capacity
        )
    }

    @ViewBuilder
    private func toolbarActionButton(_ item: PlatformToolbarActionItem) -> some View {
        if let systemImage = item.systemImage {
            Button(item.label, systemImage: systemImage, action: item.action)
        } else {
            Button(item.label, action: item.action)
        }
    }
}

/// Space-aware toolbar actions (Issue #352). Uses packing policy + `platformMenu` for overflow.
@MainActor
public func platformToolbarActions_L4(
    _ actions: [PlatformToolbarActionItem],
    capacity: PlatformToolbarActionsCapacity = .platformDefault,
    overflowTitle: String = "More",
    overflowSystemImage: String = "ellipsis",
    placement: ToolbarItemPlacement = .automatic
) -> some ToolbarContent {
    PlatformToolbarActionsContent(
        actions: actions,
        capacity: capacity,
        overflowTitle: overflowTitle,
        overflowSystemImage: overflowSystemImage,
        placement: placement
    )
}
