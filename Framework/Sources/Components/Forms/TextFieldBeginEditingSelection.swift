import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

/// Form-level opt-in for select-all on begin editing (#472). Default is caret-at-end.
public struct FormSelectAllOnBeginEditingKey: EnvironmentKey {
    public static let defaultValue = false
}

public extension EnvironmentValues {
    var formSelectAllOnBeginEditing: Bool {
        get { self[FormSelectAllOnBeginEditingKey.self] }
        set { self[FormSelectAllOnBeginEditingKey.self] = newValue }
    }
}

/// Selects all contents of a native text control when it matches the form field that began editing.
/// Stub: no-op until #472 green.
public enum TextFieldBeginEditingSelection {
    public static func applySelectAll(
        to object: Any?,
        matching nativeField: AnyObject?,
        shouldSelect: Bool
    ) {
        // Intentionally empty (TDD red).
        _ = object
        _ = nativeField
        _ = shouldSelect
    }
}

extension View {
    /// Selects all text when this field begins editing if the enclosing form opted in.
    public func selectAllTextOnBeginEditingIfFormOptedIn() -> some View {
        self
    }
}
