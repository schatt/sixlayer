import Foundation
import SwiftUI
import Testing
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

@testable import SixLayerFramework

/// Focused form editors must ignore `DynamicFormState` publishes (#560).
///
/// A sibling or same-field `setValue` while the editor is focused republishes every
/// `TextField` / `TextEditor` / `SecureField` bound straight at `formState`. On macOS
/// that replacement hits the field editor's undo range after ⌘A + delete.
@Suite("Focused form text editor (#560)", HostedViewTestIsolationTrait())
open class FocusedFormTextEditorTests: BaseTestClass {

    @Test(arguments: EditorKind.allCases)
    @MainActor
    func focusedPublish_doesNotPushIntoEditor(_ kind: EditorKind) {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let state = makeState()
            kind.seed(state, text: "10")
            guard let root = host(kind.view(state: state), kind: kind) else { return }

            state.focusedFieldId = kind.focusID
            pump()
            state.setValue("other", for: "sibling")
            pump()

            let afterSibling = firstEditorText(in: root)
            #expect(afterSibling == "10", "\(kind) sibling publish must leave the focused editor unchanged")

            kind.seed(state, text: "99")
            pump()
            let afterSameField = firstEditorText(in: root)
            #expect(
                afterSameField == "10",
                "\(kind) same-field publish while focused must leave the editor on the local text"
            )
        }
    }

    @Test(arguments: EditorKind.allCases)
    @MainActor
    func unfocusedPublish_updatesEditor(_ kind: EditorKind) {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let state = makeState()
            kind.seed(state, text: "10")
            guard let root = host(kind.view(state: state), kind: kind) else { return }

            kind.seed(state, text: "99")
            pump()
            #expect(
                firstEditorText(in: root) == "99",
                "\(kind) must show a publish that arrives while the editor is not focused"
            )
        }
    }

    #if os(macOS)
    /// ⌘A, delete, sibling `setValue`. `deleteBackward` + `selectAll` does not count.
    ///
    /// The binding check is after a run-loop pump outside the key-window lock.
    /// `sendEvent` can clear the field editor without updating SwiftUI until that pump.
    @Test @MainActor func numberField_commandADeleteSiblingWrite_staysEmpty() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let state = makeState()
            let gallons = DynamicFormField(id: "gallons", contentType: .number, label: "Gallons")
            let cost = DynamicFormField(id: "cost", contentType: .number, label: "Cost")
            state.setValue("10", for: "gallons")
            state.setValue("20", for: "cost")
            let view = VStack {
                DynamicNumberField(field: gallons, formState: state)
                DynamicNumberField(field: cost, formState: state)
            }
            guard let root = host(AnyView(view), kind: .number) else { return }
            guard let nsRoot = root as? NSView, let window = nsRoot.window else {
                Issue.record("expected an NSWindow for the hosted number field")
                return
            }

            AppKitKeyWindowIsolation.withExclusiveKeyWindow {
                window.makeKeyAndOrderFront(nil)
                guard let field = firstEditableTextField(in: window.contentView ?? nsRoot) else {
                    Issue.record("expected an editable NSTextField after making the host key")
                    return
                }
                _ = window.makeFirstResponder(field)
                guard field.currentEditor() != nil else {
                    Issue.record("expected a field editor before ⌘A")
                    return
                }

                let before = editorString(of: field)
                #expect(before == "10", "⌘A must start from the gallons value, got \(before.debugDescription)")

                sendKey(keyCode: 0, characters: "a", modifiers: .command, window: window)
                sendKey(keyCode: 51, characters: "\u{7F}", modifiers: [], window: window)
                #expect(editorString(of: field).isEmpty, "⌘A then delete must clear the field editor")
            }
            pump()
            #expect(
                state.getValue(for: "gallons") as String? == "",
                "delete must write through the text binding, still \(String(describing: state.getValue(for: "gallons") as String?))"
            )
            state.setValue("99", for: "cost")
            pump()
            if let field = firstEditableTextField(in: window.contentView ?? nsRoot) {
                #expect(editorString(of: field).isEmpty, "sibling publish must not rewrite the cleared field editor")
            } else {
                Issue.record("field editor disappeared before the sibling publish could be observed")
            }
            window.orderOut(nil)
        }
    }
    #endif

    // MARK: - Host

    @MainActor
    private func makeState() -> DynamicFormState {
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        return DynamicFormState(configuration: config)
    }

    @MainActor
    private func host(_ view: AnyView, kind: EditorKind) -> Any? {
        guard let root = hostRootPlatformView(view, forceLayout: true) else {
            #if os(iOS) || os(macOS)
            Issue.record("expected hosted platform root for \(kind)")
            #endif
            return nil
        }
        return root
    }

    @MainActor
    private func pump() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
    }

    @MainActor
    private func firstEditorText(in root: Any) -> String? {
        #if os(iOS)
        guard let view = root as? UIView else { return nil }
        return firstIOSEditorText(in: view)
        #elseif os(macOS)
        guard let view = root as? NSView else { return nil }
        if let field = firstEditableTextField(in: view) {
            return editorString(of: field)
        }
        return firstEditableTextView(in: view)?.string
        #else
        _ = root
        return nil
        #endif
    }

    #if os(iOS)
    @MainActor
    private func firstIOSEditorText(in view: UIView) -> String? {
        if let field = view as? UITextField {
            return field.text ?? ""
        }
        if let textView = view as? UITextView {
            return textView.text ?? ""
        }
        for child in view.subviews {
            if let text = firstIOSEditorText(in: child) {
                return text
            }
        }
        return nil
    }
    #endif

    #if os(macOS)
    @MainActor
    private func firstEditableTextField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.isEditable, field.window != nil {
            return field
        }
        for child in view.subviews {
            if let field = firstEditableTextField(in: child) {
                return field
            }
        }
        return nil
    }

    @MainActor
    private func firstEditableTextView(in view: NSView) -> NSTextView? {
        if let textView = view as? NSTextView, textView.isEditable, !textView.isFieldEditor, textView.window != nil {
            return textView
        }
        for child in view.subviews {
            if let textView = firstEditableTextView(in: child) {
                return textView
            }
        }
        return nil
    }

    @MainActor
    private func editorString(of field: NSTextField) -> String {
        if let editor = field.currentEditor() as? NSTextView {
            return editor.string
        }
        return field.stringValue
    }

    @MainActor
    private func sendKey(
        keyCode: UInt16,
        characters: String,
        modifiers: NSEvent.ModifierFlags,
        window: NSWindow
    ) {
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        ) else {
            Issue.record("failed to build key event \(characters)")
            return
        }
        window.sendEvent(event)
    }
    #endif
}

enum EditorKind: String, CaseIterable, Sendable {
    case text
    case textMultiline
    case email
    case password
    case phone
    case url
    case number
    case integer
    case textArea
    case richText
    case autocomplete
    case arrayItem
    case data

    static let fieldID = "value"

    /// Array rows focus `value.0`. Every other editor focuses `value`.
    var focusID: String {
        self == .arrayItem ? "\(Self.fieldID).0" : Self.fieldID
    }

    @MainActor
    func seed(_ state: DynamicFormState, text: String) {
        switch self {
        case .arrayItem:
            state.setValue([text], for: Self.fieldID)
        case .data:
            state.setValue(Data(text.utf8), for: Self.fieldID)
        default:
            state.setValue(text, for: Self.fieldID)
        }
    }

    @MainActor
    func view(state: DynamicFormState) -> AnyView {
        let field = makeField()
        switch self {
        case .text, .textMultiline:
            return AnyView(DynamicTextField(field: field, formState: state))
        case .email:
            return AnyView(DynamicEmailField(field: field, formState: state))
        case .password:
            return AnyView(DynamicPasswordField(field: field, formState: state))
        case .phone:
            return AnyView(DynamicPhoneField(field: field, formState: state))
        case .url:
            return AnyView(DynamicURLField(field: field, formState: state))
        case .number:
            return AnyView(DynamicNumberField(field: field, formState: state))
        case .integer:
            return AnyView(DynamicIntegerField(field: field, formState: state))
        case .textArea:
            return AnyView(DynamicTextAreaField(field: field, formState: state))
        case .richText:
            return AnyView(DynamicRichTextField(field: field, formState: state))
        case .autocomplete:
            return AnyView(DynamicAutocompleteField(field: field, formState: state))
        case .arrayItem:
            return AnyView(DynamicArrayField(field: field, formState: state))
        case .data:
            return AnyView(DynamicDataField(field: field, formState: state))
        }
    }

    private func makeField() -> DynamicFormField {
        let metadata: [String: String]? = self == .textMultiline ? ["multiLine": "true"] : nil
        let contentType: DynamicContentType = switch self {
        case .text, .textMultiline:
            .text
        case .email:
            .email
        case .password:
            .password
        case .phone:
            .phone
        case .url:
            .url
        case .number:
            .number
        case .integer:
            .integer
        case .textArea:
            .textarea
        case .richText:
            .richtext
        case .autocomplete:
            .autocomplete
        case .arrayItem:
            .array
        case .data:
            .data
        }
        return DynamicFormField(
            id: Self.fieldID,
            contentType: contentType,
            label: rawValue,
            options: self == .autocomplete ? ["alpha", "beta"] : nil,
            metadata: metadata
        )
    }
}
