import SwiftUI

/// Splits inspect-time construction from hosted/production construction (#435).
///
/// ViewInspector `inspect()` evaluates `body` without installing the view, so `@Environment`
/// and `@StateObject` always read defaults and flood diagnostics. Call `select` / `split`
/// so the unhosted branch does not instantiate those wrappers.
@MainActor
public enum UnhostedInspection {
    public static var isActive: Bool {
        AccessibilityIdentifierConfig.unhostedInspection
    }

    public static func select<T>(unhosted: () throws -> T, hosted: () throws -> T) rethrows -> T {
        if isActive {
            return try unhosted()
        }
        return try hosted()
    }

    @ViewBuilder
    public static func split<Unhosted: View, Hosted: View>(
        @ViewBuilder unhosted: () -> Unhosted,
        @ViewBuilder hosted: () -> Hosted
    ) -> some View {
        if isActive {
            unhosted()
        } else {
            hosted()
        }
    }
}
