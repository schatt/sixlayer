import SwiftUI

/// A committed editor string that must apply even while the field is focused.
///
/// Token `0` is the idle value and is ignored. Autocomplete suggestion taps increment
/// the token so the choice replaces the local buffer (#560).
struct FormEditorCommit: Equatable {
    var token: Int = 0
    var text: String = ""
}

/// Binds a form text editor to local state while it is focused (#560).
///
/// Keystrokes write into ``DynamicFormState``. A later `setValue`, including a sibling
/// field, may refresh an unfocused editor. It does not assign the local text, so SwiftUI
/// does not push a replacement into the field editor.
@MainActor
struct FormEditorText<Editor: View>: View {
    @ObservedObject var formState: DynamicFormState
    let fieldID: String
    let externalDisplay: String
    var forcedCommit: FormEditorCommit = FormEditorCommit()
    let write: (String) -> Void
    @ViewBuilder let editor: (Binding<String>) -> Editor

    @FocusState private var isFocused: Bool
    @State private var editingText = ""
    @State private var gate = WriteGate()

    var body: some View {
        editor($editingText)
            .focused($isFocused)
            .onAppear {
                applyExternal(externalDisplay)
                if formState.focusedFieldId == fieldID {
                    isFocused = true
                }
            }
            .onChange(of: editingText) { _, newValue in
                if gate.suppressed {
                    gate.suppressed = false
                    return
                }
                write(newValue)
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    applyExternal(externalDisplay)
                    if formState.focusedFieldId != fieldID {
                        formState.focusedFieldId = fieldID
                    }
                } else if formState.focusedFieldId == fieldID {
                    formState.focusedFieldId = nil
                }
            }
            .onChange(of: formState.focusedFieldId) { _, newValue in
                let shouldFocus = newValue == fieldID
                if isFocused != shouldFocus {
                    isFocused = shouldFocus
                }
            }
            .onChange(of: externalDisplay) { _, newValue in
                guard !isFocused else { return }
                applyExternal(newValue)
            }
            .onChange(of: forcedCommit) { _, commit in
                guard commit.token > 0 else { return }
                applyExternal(commit.text)
            }
    }

    private func applyExternal(_ value: String) {
        guard editingText != value else { return }
        gate.suppressed = true
        editingText = value
    }

    private final class WriteGate {
        var suppressed = false
    }
}
