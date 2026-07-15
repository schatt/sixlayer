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
        // Deliberately wrong for TDD red — corrected in green (#352).
        PlatformToolbarActionsCapacity(maxVisible: 0)
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
    /// **Stub (TDD red):** returns everything as visible and nothing in overflow.
    public static func pack(
        _ actions: [PlatformToolbarActionDescriptor],
        capacity: PlatformToolbarActionsCapacity
    ) -> PlatformToolbarActionsPackResult {
        _ = capacity
        return PlatformToolbarActionsPackResult(
            visibleIDs: actions.map(\.id),
            overflowIDs: []
        )
    }
}
