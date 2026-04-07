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

/// Maps resolver output to Layer 4 UI (split vs detail-only vs outer overlay). See issue #206.
public enum NavigationLayoutCompactPresentation: Sendable, Equatable {
    case fullSplit
    case detailOnlyCollapsedInner
    case overlayOuterSidebar
}

public enum Layer4OverlayFocusTarget: Sendable, Equatable {
    case expandSidebarButton
    case overlayContent
}

public struct Layer4OverlayAccessibilityState: Sendable, Equatable {
    public let isUnderlyingContentAccessibilityHidden: Bool
    public let focusTarget: Layer4OverlayFocusTarget
}

public extension NavigationLayoutCompactPresentation {
    init(resolution: NavigationLayoutResolution) {
        switch resolution.mode {
        case .sideBySide:
            self = .fullSplit
        case .compactCollapsedOuter:
            self = .overlayOuterSidebar
        case .compactCollapsedInner:
            self = .detailOnlyCollapsedInner
        }
    }
}

// MARK: - Issue #208 stress matrix (Dynamic Type / long-form / persistence helpers)

/// Optional inputs that fold **Dynamic Type** and **long-form copy** into nested-split minimum detail width.
///
/// Hosts should pass **layout-direction-aware** leading/trailing insets when computing `availableWidth`
/// for ``NavigationLayoutResolver/resolveSettingsContainer(availableWidth:)``; see
/// ``NavigationLayoutResolver/effectiveContentWidthForSplitAxis(containerWidth:leadingInset:trailingInset:)``.
public struct NavigationLayoutStressMetrics: Sendable, Equatable {
    /// Multiplier applied to the base nested-split minimum detail width (1.0 = default).
    public let dynamicTypeScale: CGFloat
    /// Estimated extra characters vs baseline copy (e.g. German vs English); boosts minimum detail width.
    public let estimatedLongFormExtraCharacters: Int

    public init(dynamicTypeScale: CGFloat = 1, estimatedLongFormExtraCharacters: Int = 0) {
        self.dynamicTypeScale = dynamicTypeScale
        self.estimatedLongFormExtraCharacters = estimatedLongFormExtraCharacters
    }

    public static let `default` = NavigationLayoutStressMetrics()
}

extension NavigationLayoutCompactPresentation: Codable {}

// MARK: - Core resolution

/// Width-driven layout resolution for nested sidebars and Layer 4 shells.
///
/// Callers pass an **available width in points** along the split axis. For **Dynamic Type**, **long-form
/// localization**, or **RTL margin** effects on the budget, use ``NavigationLayoutStressMetrics`` with
/// ``NavigationLayoutResolver/resolveSettingsContainer(availableWidth:stressMetrics:)`` and/or fold insets into
/// ``NavigationLayoutResolver/effectiveContentWidthForSplitAxis(containerWidth:leadingInset:trailingInset:)``
/// before resolving (issue #208).
public enum NavigationLayoutResolver {
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
        let detailWidth = max(0, availableWidth - outerWidth - innerWidth)
        return NavigationLayoutResolution(
            mode: .sideBySide,
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            detailWidth: detailWidth
        )
    }

    private static func compactResolution(
        availableWidth: CGFloat,
        minimumDetailWidth: CGFloat,
        outerWidth: CGFloat,
        innerWidth: CGFloat,
        policy: NavigationLayoutPolicy
    ) -> NavigationLayoutResolution {
        NavigationLayoutResolution(
            mode: compactMode(for: policy),
            outerWidth: outerWidth,
            innerWidth: innerWidth,
            detailWidth: max(0, availableWidth - minimumDetailWidth)
        )
    }

    private static func compactMode(for policy: NavigationLayoutPolicy) -> NavigationLayoutMode {
        switch policy {
        case .automatic, .preferInner:
            return .compactCollapsedOuter
        case .preferOuter:
            return .compactCollapsedInner
        }
    }

    private static func resolvedWidth(
        for profile: NavigationSidebarProfile,
        availableWidth: CGFloat
    ) -> CGFloat {
        let ideal = availableWidth * profile.idealWidthRatio
        let lowerBound = min(profile.minWidth, profile.maxWidth)
        return min(max(ideal, lowerBound), profile.maxWidth)
    }

    // MARK: Layer 4 nested split presets (settings + app navigation)

    /// Minimum width reserved for the detail pane when resolving Layer 4 nested split shells (host + inner + detail).
    public static let layer4NestedSplitShellMinimumDetailWidth: CGFloat = 480

    /// Shared preset for nested split columns: host `compactList` plus inner `textSidebar`. When the width budget fails, `.automatic` yields `.compactCollapsedOuter` (collapse outer first; overlay expansion in Layer 4). Issue #206.
    private static func resolveLayer4NestedSplitShell(availableWidth: CGFloat, minimumDetailWidth: CGFloat) -> NavigationLayoutResolution {
        resolve(
            availableWidth: availableWidth,
            outerProfile: .compactList,
            innerProfile: .textSidebar,
            minimumDetailWidth: minimumDetailWidth,
            policy: .automatic
        )
    }

    /// Preset resolution for the Layer 4 settings container.
    public static func resolveSettingsContainer(availableWidth: CGFloat) -> NavigationLayoutResolution {
        resolveLayer4NestedSplitShell(
            availableWidth: availableWidth,
            minimumDetailWidth: layer4NestedSplitShellMinimumDetailWidth
        )
    }

    /// Preset resolution for the Layer 4 app navigation split shell (same contract as `resolveSettingsContainer`).
    public static func resolveAppNavigationShell(availableWidth: CGFloat) -> NavigationLayoutResolution {
        resolveLayer4NestedSplitShell(
            availableWidth: availableWidth,
            minimumDetailWidth: layer4NestedSplitShellMinimumDetailWidth
        )
    }

    /// Same contract as ``resolveSettingsContainer(availableWidth:stressMetrics:)`` for app navigation shell parity (#205 / #208).
    public static func resolveAppNavigationShell(
        availableWidth: CGFloat,
        stressMetrics: NavigationLayoutStressMetrics
    ) -> NavigationLayoutResolution {
        resolveSettingsContainer(availableWidth: availableWidth, stressMetrics: stressMetrics)
    }

    /// Same as ``resolveSettingsContainer(availableWidth:)`` but with **stress metrics** folded into the effective minimum detail width (#208).
    public static func resolveSettingsContainer(
        availableWidth: CGFloat,
        stressMetrics: NavigationLayoutStressMetrics
    ) -> NavigationLayoutResolution {
        let minDetail = effectiveDetailMinimumWidthForNestedSplit(stressMetrics: stressMetrics)
        return resolveLayer4NestedSplitShell(
            availableWidth: availableWidth,
            minimumDetailWidth: minDetail
        )
    }

    /// Scales the nested-split minimum detail width by a Dynamic Type–style multiplier (clamped).
    public static func scaledMinimumDetailWidthForNestedSplit(base: CGFloat, dynamicTypeScale: CGFloat) -> CGFloat {
        let s = max(0.5, min(dynamicTypeScale, 3.0))
        return max(0, base * s)
    }

    /// Additional minimum detail width for long-form / localized copy (capped).
    public static func additionalDetailWidthForLongFormContent(estimatedExtraCharacters: Int) -> CGFloat {
        let n = max(0, estimatedExtraCharacters)
        return min(160, CGFloat(n) * 0.15)
    }

    /// Effective minimum detail width for the nested split shell given stress metrics (#208).
    public static func effectiveDetailMinimumWidthForNestedSplit(stressMetrics: NavigationLayoutStressMetrics) -> CGFloat {
        scaledMinimumDetailWidthForNestedSplit(
            base: layer4NestedSplitShellMinimumDetailWidth,
            dynamicTypeScale: stressMetrics.dynamicTypeScale
        ) + additionalDetailWidthForLongFormContent(estimatedExtraCharacters: stressMetrics.estimatedLongFormExtraCharacters)
    }

    /// Semantic content width along the split axis after **leading** and **trailing** insets (layout-direction aware at call site).
    public static func effectiveContentWidthForSplitAxis(
        containerWidth: CGFloat,
        leadingInset: CGFloat,
        trailingInset: CGFloat
    ) -> CGFloat {
        max(0, containerWidth - max(0, leadingInset) - max(0, trailingInset))
    }

    /// Canonical Layer 4 UI presentation for `availableWidth` (issue #206).
    public static func layer4CompactPresentation(forAvailableWidth width: CGFloat) -> NavigationLayoutCompactPresentation {
        NavigationLayoutCompactPresentation(resolution: resolveSettingsContainer(availableWidth: width))
    }

    /// Layer 4 compact presentation after a resize, using the previous UI mode to avoid thrashing (issue #208).
    ///
    /// When the width budget fits a full split, always returns ``NavigationLayoutCompactPresentation/fullSplit``.
    /// When constrained, if the shell was already in ``NavigationLayoutCompactPresentation/detailOnlyCollapsedInner``,
    /// that mode is preserved across rapid width changes; otherwise the current resolution mapping applies.
    public static func layer4CompactPresentationForTransition(
        availableWidth: CGFloat,
        previousPresentation: NavigationLayoutCompactPresentation
    ) -> NavigationLayoutCompactPresentation {
        let fresh = layer4CompactPresentation(forAvailableWidth: availableWidth)
        if fresh == .fullSplit {
            return .fullSplit
        }
        if previousPresentation == .detailOnlyCollapsedInner {
            return .detailOnlyCollapsedInner
        }
        return fresh
    }

    /// Deterministic accessibility state for Layer 4 overlay open/close transitions (issue #207).
    public static func layer4OverlayAccessibilityState(isOverlayPresented: Bool) -> Layer4OverlayAccessibilityState {
        Layer4OverlayAccessibilityState(
            isUnderlyingContentAccessibilityHidden: isOverlayPresented,
            focusTarget: layer4OverlayFocusTarget(isOverlayPresented: isOverlayPresented)
        )
    }

    private static func layer4OverlayFocusTarget(isOverlayPresented: Bool) -> Layer4OverlayFocusTarget {
        isOverlayPresented ? .overlayContent : .expandSidebarButton
    }

    /// Transition-level focus handoff for overlay open/close.
    public static func layer4OverlayAccessibilityTransition(
        previouslyPresented: Bool,
        currentlyPresented: Bool
    ) -> Layer4OverlayFocusTarget? {
        guard previouslyPresented != currentlyPresented else { return nil }
        return layer4OverlayFocusTarget(isOverlayPresented: currentlyPresented)
    }
}
