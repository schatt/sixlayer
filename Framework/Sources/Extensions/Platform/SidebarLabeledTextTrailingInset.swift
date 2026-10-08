import CoreGraphics
import SwiftUI

/// Trailing inset after a full text sidebar label (#552).
///
/// macOS 26+ sidebar rows keep a wide trailing gutter. Inside the labeled column
/// that gutter consumes the title, so the label clips.
public enum SidebarLabeledTextTrailingInset {
    /// Gap after the title. Kept modest so the label stays inside the column.
    public static let points: CGFloat = 8

    public static let leading: CGFloat = 10
    public static let vertical: CGFloat = 2

    public static var rowInsets: EdgeInsets {
        EdgeInsets(top: vertical, leading: leading, bottom: vertical, trailing: points)
    }

    /// macOS replaces the system row inset. Other platforms keep it.
    public static func rowInsets(for platform: SixLayerPlatform) -> EdgeInsets? {
        switch platform {
        case .macOS:
            return rowInsets
        case .iOS, .watchOS, .tvOS, .visionOS:
            return nil
        }
    }
}

struct SidebarLabeledRowInsetsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if let insets = SidebarLabeledTextTrailingInset.rowInsets(for: .current) {
            content.listRowInsets(insets)
        } else {
            content
        }
    }
}

public extension View {
    /// Modest trailing inset for a full-text sidebar row on macOS (#552).
    ///
    /// `nonisolated` so it is visible on the opaque `some View` returned by
    /// `automaticCompliance` (also nonisolated). A MainActor-isolated method
    /// is not a member of that opaque type.
    nonisolated func platformSidebarLabeledRowInsets() -> some View {
        modifier(SidebarLabeledRowInsetsModifier())
    }
}

/// Applies the sidebar row inset when the receiver is an opaque `some View`.
/// Member lookup on that opaque type does not see `platformSidebarLabeledRowInsets`.
nonisolated func applySidebarLabeledRowInsets<V: View>(_ view: V) -> some View {
    view.modifier(SidebarLabeledRowInsetsModifier())
}
