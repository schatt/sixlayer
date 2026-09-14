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
/// Walks to the nearest sibling subtree by subview-index distance instead of taking
/// the first text control in an ancestor (which binds every field to field 1).
enum NativeTextControlLookup {
    #if os(iOS)
    static func nearestTextControl(from marker: UIView) -> AnyObject? {
        nearest(
            from: marker,
            superview: { $0.superview },
            subviews: { $0.subviews },
            isTextControl: { $0 is UITextField || $0 is UITextView }
        )
    }
    #elseif os(macOS)
    static func nearestTextControl(from marker: NSView) -> AnyObject? {
        nearest(
            from: marker,
            superview: { $0.superview },
            subviews: { $0.subviews },
            isTextControl: { $0 is NSTextField || $0 is NSTextView }
        )
    }
    #endif

    #if os(iOS) || os(macOS)
    private static func nearest<ViewType: AnyObject>(
        from marker: ViewType,
        superview: (ViewType) -> ViewType?,
        subviews: (ViewType) -> [ViewType],
        isTextControl: (ViewType) -> Bool
    ) -> ViewType? {
        var child = marker
        var ancestor = superview(marker)
        while let current = ancestor {
            if isTextControl(current) {
                return current
            }
            if let found = nearestTextControlAmongSiblings(
                of: child,
                in: current,
                subviews: subviews,
                isTextControl: isTextControl
            ) {
                return found
            }
            child = current
            ancestor = superview(current)
        }
        return nil
    }

    private static func nearestTextControlAmongSiblings<ViewType: AnyObject>(
        of child: ViewType,
        in parent: ViewType,
        subviews: (ViewType) -> [ViewType],
        isTextControl: (ViewType) -> Bool
    ) -> ViewType? {
        let siblings = subviews(parent)
        guard let childIndex = siblings.firstIndex(where: { $0 === child }) else {
            return nil
        }
        var best: (view: ViewType, distance: Int, index: Int)?
        for (index, sibling) in siblings.enumerated() where sibling !== child {
            guard let control = firstTextControl(
                in: sibling,
                subviews: subviews,
                isTextControl: isTextControl
            ) else {
                continue
            }
            let distance = abs(index - childIndex)
            if let currentBest = best {
                if distance < currentBest.distance
                    || (distance == currentBest.distance && index > currentBest.index) {
                    best = (control, distance, index)
                }
            } else {
                best = (control, distance, index)
            }
        }
        return best?.view
    }

    private static func firstTextControl<ViewType: AnyObject>(
        in view: ViewType,
        subviews: (ViewType) -> [ViewType],
        isTextControl: (ViewType) -> Bool
    ) -> ViewType? {
        if isTextControl(view) {
            return view
        }
        for child in subviews(view) {
            if let found = firstTextControl(
                in: child,
                subviews: subviews,
                isTextControl: isTextControl
            ) {
                return found
            }
        }
        return nil
    }
    #endif
}

/// Selects all contents of a native text control when it is the same instance that began editing.
enum TextFieldBeginEditingSelection {
    static func applySelectAll(
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
            // Unhosted NSTextView selection/mutation can abort via TextInputUI (#447 CI).
            guard textView.window != nil else { return }
            let length = (textView.string as NSString).length
            textView.selectedRange = NSRange(location: 0, length: length)
        }
        #endif
    }

    #if os(iOS)
    static func handleBeginEditing(_ object: Any?, marker: UIView, shouldSelect: Bool) {
        applySelectAll(
            to: object,
            matching: NativeTextControlLookup.nearestTextControl(from: marker),
            shouldSelect: shouldSelect
        )
    }

    private static func selectAll(in textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else { return }
        if let from = textField.position(from: textField.beginningOfDocument, offset: 0),
           let to = textField.position(from: textField.beginningOfDocument, offset: text.count) {
            textField.selectedTextRange = textField.textRange(from: from, to: to)
        }
    }
    #elseif os(macOS)
    static func handleBeginEditing(_ object: Any?, marker: NSView, shouldSelect: Bool) {
        applySelectAll(
            to: object,
            matching: NativeTextControlLookup.nearestTextControl(from: marker),
            shouldSelect: shouldSelect
        )
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

    func body(content: Content) -> some View {
        content
            .background(NativeTextControlAnchor(shouldSelect: shouldSelect))
    }
}

/// Zero-size marker that observes begin-editing and select-alls only its nearest native field.
private struct NativeTextControlAnchor: View {
    let shouldSelect: Bool

    var body: some View {
        NativeTextControlAnchorRepresentable(shouldSelect: shouldSelect)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

#if os(iOS)
private final class NativeTextControlMarkerView: UIView {
    var shouldSelect = false
    private var observers: [NSObjectProtocol] = []

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshObservers()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            removeObservers()
        }
    }

    func refreshObservers() {
        removeObservers()
        guard window != nil else { return }
        let names = [
            UITextField.textDidBeginEditingNotification,
            UITextView.textDidBeginEditingNotification
        ]
        for name in names {
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: name,
                    object: nil,
                    queue: .main
                ) { [weak self] note in
                    guard let self else { return }
                    TextFieldBeginEditingSelection.handleBeginEditing(
                        note.object,
                        marker: self,
                        shouldSelect: self.shouldSelect
                    )
                }
            )
        }
    }

    private func removeObservers() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        removeObservers()
    }
}

private struct NativeTextControlAnchorRepresentable: UIViewRepresentable {
    let shouldSelect: Bool

    func makeUIView(context: Context) -> NativeTextControlMarkerView {
        NativeTextControlMarkerView()
    }

    func updateUIView(_ uiView: NativeTextControlMarkerView, context: Context) {
        uiView.shouldSelect = shouldSelect
    }
}
#elseif os(macOS)
private final class NativeTextControlMarkerView: NSView {
    var shouldSelect = false
    private var observers: [NSObjectProtocol] = []

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshObservers()
    }

    func refreshObservers() {
        removeObservers()
        guard window != nil else { return }
        let names = [
            NSControl.textDidBeginEditingNotification,
            NSText.didBeginEditingNotification
        ]
        for name in names {
            observers.append(
                NotificationCenter.default.addObserver(
                    forName: name,
                    object: nil,
                    queue: .main
                ) { [weak self] note in
                    guard let self else { return }
                    TextFieldBeginEditingSelection.handleBeginEditing(
                        note.object,
                        marker: self,
                        shouldSelect: self.shouldSelect
                    )
                }
            )
        }
    }

    private func removeObservers() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    deinit {
        removeObservers()
    }
}

private struct NativeTextControlAnchorRepresentable: NSViewRepresentable {
    let shouldSelect: Bool

    func makeNSView(context: Context) -> NativeTextControlMarkerView {
        NativeTextControlMarkerView()
    }

    func updateNSView(_ nsView: NativeTextControlMarkerView, context: Context) {
        nsView.shouldSelect = shouldSelect
    }
}
#else
private struct NativeTextControlAnchorRepresentable: View {
    var shouldSelect: Bool
    var body: some View { EmptyView() }
}
#endif
