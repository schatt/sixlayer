import Foundation

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
    /// Pinned actions (`overflowEligible == false`) always stay visible. Remaining
    /// slots (after pins) go to overflow-eligible actions ordered by ascending
    /// priority, then input order. Overflow preserves that same relative order.
    public static func pack(
        _ actions: [PlatformToolbarActionDescriptor],
        capacity: PlatformToolbarActionsCapacity
    ) -> PlatformToolbarActionsPackResult {
        let indexed = actions.enumerated().map { (index: $0.offset, action: $0.element) }

        func byPriorityThenInput(
            _ lhs: (index: Int, action: PlatformToolbarActionDescriptor),
            _ rhs: (index: Int, action: PlatformToolbarActionDescriptor)
        ) -> Bool {
            if lhs.action.priority != rhs.action.priority {
                return lhs.action.priority < rhs.action.priority
            }
            return lhs.index < rhs.index
        }

        let pinned = indexed
            .filter { !$0.action.overflowEligible }
            .sorted(by: byPriorityThenInput)
        let overflowable = indexed
            .filter { $0.action.overflowEligible }
            .sorted(by: byPriorityThenInput)

        let overflowableSlots = max(0, capacity.maxVisible - pinned.count)
        let visibleOverflowable = Array(overflowable.prefix(overflowableSlots))
        let overflow = Array(overflowable.dropFirst(overflowableSlots))

        let visibleIDs = (pinned + visibleOverflowable).map(\.action.id)
        let overflowIDs = overflow.map(\.action.id)
        return PlatformToolbarActionsPackResult(
            visibleIDs: visibleIDs,
            overflowIDs: overflowIDs
        )
    }
}
