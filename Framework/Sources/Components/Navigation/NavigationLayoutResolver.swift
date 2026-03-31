import Foundation
import CoreGraphics

public struct NavigationSidebarProfile: Sendable, Hashable {
    public let id: String
    public let minWidth: CGFloat
    public let idealWidthRatio: CGFloat
    public let maxWidth: CGFloat

    public init(
        id: String,
        minWidth: CGFloat,
        idealWidthRatio: CGFloat,
        maxWidth: CGFloat
    ) {
        self.id = id
        self.minWidth = minWidth
        self.idealWidthRatio = idealWidthRatio
        self.maxWidth = maxWidth
    }
}

public extension NavigationSidebarProfile {
    static let iconRail = NavigationSidebarProfile(
        id: "iconRail",
        minWidth: 80,
        idealWidthRatio: 0.12,
        maxWidth: 120
    )

    static let compactList = NavigationSidebarProfile(
        id: "compactList",
        minWidth: 140,
        idealWidthRatio: 0.18,
        maxWidth: 220
    )

    static let textSidebar = NavigationSidebarProfile(
        id: "textSidebar",
        minWidth: 180,
        idealWidthRatio: 0.25,
        maxWidth: 320
    )
}

public enum NavigationLayoutPolicy: Sendable {
    case automatic
    case preferOuter
    case preferInner
}

public enum NavigationLayoutMode: Sendable, Equatable {
    case sideBySide
    case compactCollapsedOuter
    case compactCollapsedInner
}

public struct NavigationLayoutResolution: Sendable, Equatable {
    public let mode: NavigationLayoutMode
    public let outerWidth: CGFloat
    public let innerWidth: CGFloat
    public let detailWidth: CGFloat
}

public enum NavigationLayoutResolver {
    /// Minimum width reserved for the settings detail pane when resolving the nested settings shell.
    private static let settingsContainerMinimumDetailWidth: CGFloat = 480

    /// Preset resolution for the Layer 4 settings container: host `compactList` plus inner `textSidebar`, preferring the outer column when space is tight (`.preferOuter`).
    public static func resolveSettingsContainer(availableWidth: CGFloat) -> NavigationLayoutResolution {
        resolve(
            availableWidth: availableWidth,
            outerProfile: .compactList,
            innerProfile: .textSidebar,
            minimumDetailWidth: settingsContainerMinimumDetailWidth,
            policy: .preferOuter
        )
    }

    public static func resolve(
        availableWidth: CGFloat,
        outerProfile: NavigationSidebarProfile,
        innerProfile: NavigationSidebarProfile,
        minimumDetailWidth: CGFloat,
        policy: NavigationLayoutPolicy
    ) -> NavigationLayoutResolution {
        let safeAvailableWidth = max(0, availableWidth)
        let safeDetailMin = max(0, minimumDetailWidth)
        let outerWidth = resolvedWidth(for: outerProfile, availableWidth: safeAvailableWidth)
        let innerWidth = resolvedWidth(for: innerProfile, availableWidth: safeAvailableWidth)
        let widthBudget = outerWidth + innerWidth + safeDetailMin

        if widthBudget <= safeAvailableWidth {
            return sideBySideResolution(
                availableWidth: safeAvailableWidth,
                outerWidth: outerWidth,
                innerWidth: innerWidth
            )
        }

        return compactResolution(
            availableWidth: safeAvailableWidth,
            minimumDetailWidth: safeDetailMin,
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            policy: policy
        )
    }

    private static func sideBySideResolution(
        availableWidth: CGFloat,
        outerWidth: CGFloat,
        innerWidth: CGFloat
    ) -> NavigationLayoutResolution {
        NavigationLayoutResolution(
            mode: .sideBySide,
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            detailWidth: availableWidth - outerWidth - innerWidth
        )
    }

    private static func compactResolution(
        availableWidth: CGFloat,
        minimumDetailWidth: CGFloat,
        outerWidth: CGFloat,
        innerWidth: CGFloat,
        policy: NavigationLayoutPolicy
    ) -> NavigationLayoutResolution {
        let mode: NavigationLayoutMode
        switch policy {
        case .automatic, .preferInner:
            mode = .compactCollapsedOuter
        case .preferOuter:
            mode = .compactCollapsedInner
        }

        return NavigationLayoutResolution(
            mode: mode,
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            detailWidth: max(0, availableWidth - minimumDetailWidth)
        )
    }

    private static func resolvedWidth(
        for profile: NavigationSidebarProfile,
        availableWidth: CGFloat
    ) -> CGFloat {
        let ideal = availableWidth * profile.idealWidthRatio
        let lowerBound = min(profile.minWidth, profile.maxWidth)
        return min(max(ideal, lowerBound), profile.maxWidth)
    }
}
