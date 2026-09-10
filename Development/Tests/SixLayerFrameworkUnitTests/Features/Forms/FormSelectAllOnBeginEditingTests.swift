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

@Suite("Form select-all on begin editing (#472)")
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
    #endif
}
