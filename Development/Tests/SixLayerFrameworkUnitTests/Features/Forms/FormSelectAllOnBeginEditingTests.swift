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

@Suite("Form select-all on begin editing (#472)", HostedViewTestIsolationTrait())
open class FormSelectAllOnBeginEditingTests: BaseTestClass {

    @Test func configuration_defaultsToFalse() {
        let config = DynamicFormConfiguration(id: "fuel", title: "Fuel", sections: [])
        #expect(config.selectAllOnBeginEditing == false)
    }

    @Test func configuration_storesTrue() {
        let config = DynamicFormConfiguration(
            id: "fuel",
            title: "Fuel",
            sections: [],
            selectAllOnBeginEditing: true
        )
        #expect(config.selectAllOnBeginEditing == true)
    }

    @Test func applyingHints_preservesSelectAllFlag() {
        let config = DynamicFormConfiguration(
            id: "fuel",
            title: "Fuel",
            sections: [],
            modelName: nil,
            selectAllOnBeginEditing: true
        )
        let applied = config.applyingHints()
        #expect(applied.selectAllOnBeginEditing == true)
    }

    @Test func environment_defaultsToFalse() {
        #expect(FormSelectAllOnBeginEditingKey.defaultValue == false)
    }

    #if os(iOS)
    @Test @MainActor func matchingField_selectsEntireContents() {
        let field = UITextField()
        field.text = "42000"

        TextFieldBeginEditingSelection.applySelectAll(
            to: field,
            matching: field,
            shouldSelect: true
        )

        guard let selected = field.selectedTextRange else {
            Issue.record("matching field should have a selected range after select-all")
            return
        }
        #expect(field.text(in: selected) == "42000")
    }

    @Test @MainActor func shouldSelectFalse_doesNotSelectAll() {
        let field = UITextField()
        field.text = "42000"
        if let start = field.position(from: field.beginningOfDocument, offset: 0),
           let end = field.position(from: field.beginningOfDocument, offset: 1) {
            field.selectedTextRange = field.textRange(from: start, to: end)
        }

        TextFieldBeginEditingSelection.applySelectAll(
            to: field,
            matching: field,
            shouldSelect: false
        )

        guard let selected = field.selectedTextRange else {
            return
        }
        #expect(field.text(in: selected) != "42000")
    }

    @Test @MainActor func differentField_doesNotSelectAll() {
        let field = UITextField()
        field.text = "42000"
        let other = UITextField()
        other.text = "Station"
        if let start = field.position(from: field.beginningOfDocument, offset: 0),
           let end = field.position(from: field.beginningOfDocument, offset: 1) {
            field.selectedTextRange = field.textRange(from: start, to: end)
        }

        TextFieldBeginEditingSelection.applySelectAll(
            to: field,
            matching: other,
            shouldSelect: true
        )

        guard let selected = field.selectedTextRange else {
            return
        }
        #expect(field.text(in: selected) != "42000")
    }

    @Test @MainActor func textView_matchingSelectsEntireContents() {
        let view = UITextView()
        view.text = "notes"
        TextFieldBeginEditingSelection.applySelectAll(
            to: view,
            matching: view,
            shouldSelect: true
        )
        let range = view.selectedRange
        #expect(range.location == 0)
        #expect(range.length == (view.text as NSString).length)
    }
    #endif

    #if os(macOS)
    @Test func matchingNSTextField_selectsEntireContents() {
        let field = NSTextField(string: "42000")
        TextFieldBeginEditingSelection.applySelectAll(
            to: field,
            matching: field,
            shouldSelect: true
        )
        let length = (field.stringValue as NSString).length
        if let editor = field.currentEditor() {
            #expect(editor.selectedRange.length == length)
        } else {
            Issue.record("macOS field editor missing after select-all; selectedRange not observed")
        }
    }

    @Test func differentNSTextField_doesNotSelectAll() {
        let field = NSTextField(string: "42000")
        let other = NSTextField(string: "Station")
        TextFieldBeginEditingSelection.applySelectAll(
            to: field,
            matching: other,
            shouldSelect: true
        )
        if let editor = field.currentEditor() {
            #expect(editor.selectedRange.length != (field.stringValue as NSString).length)
        }
    }

    @Test func matchingNSTextView_selectsEntireContents() {
        let view = NSTextView()
        view.string = "notes"
        TextFieldBeginEditingSelection.applySelectAll(
            to: view,
            matching: view,
            shouldSelect: true
        )
        #expect(view.selectedRange.location == 0)
        #expect(view.selectedRange.length == (view.string as NSString).length)
    }
    #endif

    #if os(iOS)
    @Test @MainActor func nearestLookup_flatSiblings_selectsMatchingFieldNotFirst() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let first = UITextField()
        first.text = "42000"
        let firstMarker = UIView()
        let second = UITextField()
        second.text = "Station"
        let secondMarker = UIView()
        container.addSubview(first)
        container.addSubview(firstMarker)
        container.addSubview(second)
        container.addSubview(secondMarker)

        let found = NativeTextControlLookup.nearestTextControl(from: secondMarker)
        #expect(found === second)
        #expect(found !== first)
    }

    @Test @MainActor func nearestLookup_wrappedFields_secondWrapFindsSecondField() {
        let form = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let wrapA = UIView()
        let fieldA = UITextField()
        fieldA.text = "42000"
        let markerA = UIView()
        wrapA.addSubview(fieldA)
        wrapA.addSubview(markerA)
        let wrapB = UIView()
        let fieldB = UITextField()
        fieldB.text = "Station"
        let markerB = UIView()
        wrapB.addSubview(fieldB)
        wrapB.addSubview(markerB)
        form.addSubview(wrapA)
        form.addSubview(wrapB)

        #expect(NativeTextControlLookup.nearestTextControl(from: markerA) === fieldA)
        #expect(NativeTextControlLookup.nearestTextControl(from: markerB) === fieldB)
    }
    #endif

    #if os(macOS)
    @Test func nearestLookup_flatSiblings_selectsMatchingNSTextFieldNotFirst() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 200))
        let first = NSTextField(string: "42000")
        let firstMarker = NSView()
        let second = NSTextField(string: "Station")
        let secondMarker = NSView()
        container.addSubview(first)
        container.addSubview(firstMarker)
        container.addSubview(second)
        container.addSubview(secondMarker)

        let found = NativeTextControlLookup.nearestTextControl(from: secondMarker)
        #expect(found === second)
        #expect(found !== first)
    }
    #endif

    @Test @MainActor func hostedForm_secondFieldSelectsEntireContentsWhenOptedIn() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = twoFieldForm(selectAll: true, first: "42000", second: "Station")
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted platform root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else {
                Issue.record("expected UIView root")
                return
            }
            pumpSelectAllHost()
            let fields = collectUITextFields(in: uiRoot)
            #expect(fields.count >= 2, "hosted form should expose at least two UITextFields")
            guard fields.count >= 2 else { return }
            let second = fields[1]
            beginEditing(second)
            #expect(isFullySelected(second), "opted-in form must select-all the focused field, not the first field")
            #expect(!isFullySelected(fields[0]), "unfocused first field must not be selected")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else {
                Issue.record("expected NSView root")
                return
            }
            pumpSelectAllHost()
            let fields = collectNSTextFields(in: nsRoot)
            #expect(fields.count >= 2, "hosted form should expose at least two NSTextFields")
            guard fields.count >= 2 else { return }
            let second = fields[1]
            beginEditing(second)
            if let editor = second.currentEditor() {
                #expect(editor.selectedRange.length == (second.stringValue as NSString).length)
            } else {
                Issue.record("macOS field editor missing after begin-editing")
            }
            #endif
        }
    }

    @Test @MainActor func hostedForm_flagOff_doesNotSelectAll() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = twoFieldForm(selectAll: false, first: "42000", second: "Station")
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted platform root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else { return }
            pumpSelectAllHost()
            let fields = collectUITextFields(in: uiRoot)
            guard fields.count >= 2 else {
                Issue.record("expected two hosted UITextFields")
                return
            }
            let second = fields[1]
            beginEditing(second)
            #expect(!isFullySelected(second), "flag off must keep caret-at-end")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else { return }
            pumpSelectAllHost()
            let fields = collectNSTextFields(in: nsRoot)
            guard fields.count >= 2 else {
                Issue.record("expected two hosted NSTextFields")
                return
            }
            beginEditing(fields[1])
            if let editor = fields[1].currentEditor() {
                #expect(editor.selectedRange.length != (fields[1].stringValue as NSString).length)
            }
            #endif
        }
    }

    @Test @MainActor func twoForms_onlyOptedInFormSelectsAll() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = VStack {
                twoFieldForm(selectAll: true, first: "on-a", second: "on-b")
                twoFieldForm(selectAll: false, first: "off-a", second: "off-b")
            }
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted platform root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else { return }
            pumpSelectAllHost()
            let fields = collectUITextFields(in: uiRoot)
            let offField = fields.first { $0.text == "off-b" }
            let onField = fields.first { $0.text == "on-b" }
            #expect(offField != nil && onField != nil)
            guard let offField, let onField else { return }
            beginEditing(offField)
            #expect(!isFullySelected(offField), "opted-out form must not select-all")
            beginEditing(onField)
            #expect(isFullySelected(onField), "opted-in form must select-all its own focused field")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else { return }
            pumpSelectAllHost()
            let fields = collectNSTextFields(in: nsRoot)
            let offField = fields.first { $0.stringValue == "off-b" }
            guard let offField else {
                Issue.record("expected opted-out field")
                return
            }
            beginEditing(offField)
            if let editor = offField.currentEditor() {
                #expect(editor.selectedRange.length != (offField.stringValue as NSString).length)
            }
            #endif
        }
    }

    @Test @MainActor func standaloneField_withoutFormParent_doesNotSelectAll() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let view = TextField("", text: .constant("42000"))
                .selectAllTextOnBeginEditingIfFormOptedIn()
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted platform root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else { return }
            pumpSelectAllHost()
            let fields = collectUITextFields(in: uiRoot)
            guard let field = fields.first else {
                Issue.record("expected a hosted UITextField")
                return
            }
            beginEditing(field)
            #expect(!isFullySelected(field), "standalone field has no opted-in form")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else { return }
            pumpSelectAllHost()
            let fields = collectNSTextFields(in: nsRoot)
            guard let field = fields.first else {
                Issue.record("expected a hosted NSTextField")
                return
            }
            beginEditing(field)
            if let editor = field.currentEditor() {
                #expect(editor.selectedRange.length != (field.stringValue as NSString).length)
            }
            #endif
        }
    }

    @Test @MainActor func l1_selectAllOnBeginEditing_selectsFocusedField() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let fields = [
                DynamicFormField(id: "odometer", contentType: .number, label: "Odometer", defaultValue: "42000"),
                DynamicFormField(id: "station", contentType: .text, label: "Station", defaultValue: "Station")
            ]
            let hints = EnhancedPresentationHints(
                dataType: .generic,
                presentationPreference: .form,
                complexity: .simple,
                context: .form
            )
            let view = platformPresentFormData_L1(
                fields: fields,
                hints: hints,
                selectAllOnBeginEditing: true
            )
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted L1 root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else { return }
            pumpSelectAllHost()
            let hosted = collectUITextFields(in: uiRoot)
            guard hosted.count >= 2 else {
                Issue.record("L1 form should host two text fields")
                return
            }
            let second = hosted[1]
            beginEditing(second)
            #expect(isFullySelected(second), "L1 opted-in form must select-all the focused field")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else { return }
            pumpSelectAllHost()
            let hosted = collectNSTextFields(in: nsRoot)
            guard hosted.count >= 2 else {
                Issue.record("L1 form should host two text fields")
                return
            }
            beginEditing(hosted[1])
            if let editor = hosted[1].currentEditor() {
                #expect(editor.selectedRange.length == (hosted[1].stringValue as NSString).length)
            }
            #endif
        }
    }

    @Test @MainActor func intelligentFormView_selectAllOnBeginEditing_selectsFocusedField() {
        initializeTestConfig()
        runWithTaskLocalConfig {
            let data = SelectAllFormFixture(odometer: "42000", station: "Station")
            let view = IntelligentFormView.generateForm(
                for: SelectAllFormFixture.self,
                initialData: data,
                selectAllOnBeginEditing: true
            )
            guard let root = hostRootPlatformView(view, forceLayout: true) else {
                Issue.record("expected hosted IFV root")
                return
            }
            #if os(iOS)
            guard let uiRoot = root as? UIView else { return }
            pumpSelectAllHost()
            let hosted = collectUITextFields(in: uiRoot)
            guard hosted.count >= 2 else {
                Issue.record("IFV should host two text fields")
                return
            }
            let second = hosted[1]
            beginEditing(second)
            #expect(isFullySelected(second), "IFV opted-in form must select-all the focused field")
            #elseif os(macOS)
            guard let nsRoot = root as? NSView else { return }
            pumpSelectAllHost()
            let hosted = collectNSTextFields(in: nsRoot)
            guard hosted.count >= 2 else {
                Issue.record("IFV should host two text fields")
                return
            }
            beginEditing(hosted[1])
            if let editor = hosted[1].currentEditor() {
                #expect(editor.selectedRange.length == (hosted[1].stringValue as NSString).length)
            }
            #endif
        }
    }

    @MainActor
    private func twoFieldForm(selectAll: Bool, first: String, second: String) -> some View {
        let configuration = DynamicFormConfiguration(
            id: "fuel-\(selectAll)-\(first)",
            title: "Fuel",
            sections: [
                DynamicFormSection(
                    id: "entry",
                    title: "Entry",
                    fields: [
                        DynamicFormField(id: "odometer", contentType: .number, label: "Odometer", defaultValue: first),
                        DynamicFormField(id: "station", contentType: .text, label: "Station", defaultValue: second)
                    ]
                )
            ],
            selectAllOnBeginEditing: selectAll
        )
        return DynamicFormView(configuration: configuration, onSubmit: { _ in })
    }

    @MainActor
    private func pumpSelectAllHost() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }

    #if os(iOS)
    @MainActor
    private func collectUITextFields(in view: UIView) -> [UITextField] {
        var result: [UITextField] = []
        if let field = view as? UITextField {
            result.append(field)
        }
        for child in view.subviews {
            result.append(contentsOf: collectUITextFields(in: child))
        }
        return result
    }

    @MainActor
    private func isFullySelected(_ field: UITextField) -> Bool {
        guard let text = field.text, !text.isEmpty, let range = field.selectedTextRange else {
            return false
        }
        return field.text(in: range) == text
    }

    @MainActor
    private func beginEditing(_ field: UITextField) {
        _ = field.becomeFirstResponder()
        NotificationCenter.default.post(
            name: UITextField.textDidBeginEditingNotification,
            object: field
        )
        pumpSelectAllHost()
    }
    #endif

    #if os(macOS)
    @MainActor
    private func collectNSTextFields(in view: NSView) -> [NSTextField] {
        var result: [NSTextField] = []
        if let field = view as? NSTextField {
            result.append(field)
        }
        for child in view.subviews {
            result.append(contentsOf: collectNSTextFields(in: child))
        }
        return result
    }

    @MainActor
    private func beginEditing(_ field: NSTextField) {
        _ = field.becomeFirstResponder()
        NotificationCenter.default.post(
            name: NSControl.textDidBeginEditingNotification,
            object: field
        )
        pumpSelectAllHost()
    }
    #endif
}

private struct SelectAllFormFixture {
    var odometer: String
    var station: String
}
