import SwiftUI

extension NavigationSplitViewVisibility {
    /// Whether the split is explicitly detail-only, not iOS `.automatic` (which can compare equal to `.detailOnly`).
    ///
    /// On iOS, `.automatic` is represented as `kind: .detailOnly` with `isAutomatic: true`; naive `== .detailOnly`
    /// treats automatic placement like a collapsed sidebar (#325).
    var isExplicitDetailOnly: Bool {
        guard self == .detailOnly else { return false }
        guard let isAutomatic = navigationSplitAutomaticPlacementFlag else { return true }
        return !isAutomatic
    }

    private var navigationSplitAutomaticPlacementFlag: Bool? {
        for child in Mirror(reflecting: self).children {
            if child.label == "isAutomatic", let value = child.value as? Bool {
                return value
            }
        }
        return nil
    }
}
