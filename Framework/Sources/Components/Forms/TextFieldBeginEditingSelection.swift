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

/// Resolves the native text control owned by a field's zero-size anchor.
///
/// Tests exercise the lookup against synthetic view trees. The production modifier
/// uses the same function so hosted select-all cannot bind every field to the first control.
enum NativeTextControlLookup {
    #if os(iOS)
    static func nearestTextControl(from marker: UIView) -> AnyObject? {
        firstTextControlInAncestors(from: marker)
    }

    private static func firstTextControlInAncestors(from view: UIView) -> AnyObject? {
        var ancestor: UIView? = view.superview
        while let current = ancestor {
            if let found = firstTextControl(in: current) {
                return found
            }
            ancestor = current.superview
        }
        return nil
    }

    private static func firstTextControl(in view: UIView) -> AnyObject? {
        if view is UITextField || view is UITextView {
            return view
        }
        for child in view.subviews {
            if let found = firstTextControl(in: child) {
                return found
            }
        }
        return nil
    }
    #elseif os(macOS)
    static func nearestTextControl(from marker: NSView) -> AnyObject? {
        firstTextControlInAncestors(from: marker)
    }

    private static func firstTextControlInAncestors(from view: NSView) -> AnyObject? {
        var ancestor: NSView? = view.superview
        while let current = ancestor {
            if let found = firstTextControl(in: current) {
                return found
            }
            ancestor = current.superview
        }
        return nil
    }

    private static func firstTextControl(in view: NSView) -> AnyObject? {
        if view is NSTextField || view is NSTextView {
            return view
        }
        for child in view.subviews {
            if let found = firstTextControl(in: child) {
                return found
            }
        }
        return nil
    }
    #endif
}

/// Selects all contents of a native text control when it is the same instance that began editing.
public enum TextFieldBeginEditingSelection {
    public static func applySelectAll(
        to object: Any?,
        matching nativeField: AnyObject?,
        shouldSelect: Bool
    ) {
        guard shouldSelect else { return }
        guard let nativeField else { return }
        guard let object else { return }
        guard (object as AnyObject) === nativeField else { return }

        #if os(iOS)
        if let textField = object as? UITextField {
            selectAll(in: textField)
        } else if let textView = object as? UITextView {
            let length = (textView.text as NSString).length
            textView.selectedRange = NSRange(location: 0, length: length)
        }
        #elseif os(macOS)
        if let textField = object as? NSTextField {
            let length = (textField.stringValue as NSString).length
            guard length > 0 else { return }
            textField.selectText(nil)
            textField.currentEditor()?.selectedRange = NSRange(location: 0, length: length)
        } else if let textView = object as? NSTextView {
            let length = (textView.string as NSString).length
            textView.selectedRange = NSRange(location: 0, length: length)
        }
        #endif
    }

    #if os(iOS)
    private static func selectAll(in textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }
        if let from = textField.position(from: textField.beginningOfDocument, offset: 0),
           let to = textField.position(from: textField.beginningOfDocument, offset: text.count) {
            textField.selectedTextRange = textField.textRange(from: from, to: to)
        }
    }
    #endif
}

extension View {
    /// Selects all text when this field begins editing if the enclosing form opted in.
    public func selectAllTextOnBeginEditingIfFormOptedIn() -> some View {
        modifier(SelectAllOnBeginEditingIfFormOptedInModifier())
    }
}

private struct SelectAllOnBeginEditingIfFormOptedInModifier: ViewModifier {
    @Environment(\.formSelectAllOnBeginEditing) private var shouldSelect
    @State private var nativeField: AnyObject?

    func body(content: Content) -> some View {
        content
            .background(NativeTextControlAnchor(nativeField: $nativeField))
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
                TextFieldBeginEditingSelection.applySelectAll(
                    to: note.object,
                    matching: nativeField,
                    shouldSelect: shouldSelect
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidBeginEditingNotification)) { note in
                TextFieldBeginEditingSelection.applySelectAll(
                    to: note.object,
                    matching: nativeField,
                    shouldSelect: shouldSelect
                )
            }
            #elseif os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidBeginEditingNotification)) { note in
                TextFieldBeginEditingSelection.applySelectAll(
                    to: note.object,
                    matching: nativeField,
                    shouldSelect: shouldSelect
                )
            }
            #endif
    }
}

/// Finds this view's backing `UITextField` / `UITextView` / `NSTextField` so select-all is instance-scoped.
private struct NativeTextControlAnchor: View {
    @Binding var nativeField: AnyObject?

    var body: some View {
        NativeTextControlAnchorRepresentable(nativeField: $nativeField)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

#if os(iOS)
private struct NativeTextControlAnchorRepresentable: UIViewRepresentable {
    @Binding var nativeField: AnyObject?

    func makeUIView(context: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            nativeField = NativeTextControlLookup.nearestTextControl(from: uiView)
        }
    }
}
#elseif os(macOS)
private struct NativeTextControlAnchorRepresentable: NSViewRepresentable {
    @Binding var nativeField: AnyObject?

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nativeField = NativeTextControlLookup.nearestTextControl(from: nsView)
        }
    }
}
#else
private struct NativeTextControlAnchorRepresentable: View {
    @Binding var nativeField: AnyObject?
    var body: some View { EmptyView() }
}
#endif
