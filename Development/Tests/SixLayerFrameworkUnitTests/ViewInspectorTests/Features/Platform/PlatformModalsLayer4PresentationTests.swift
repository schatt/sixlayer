import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// #507: Layer4 modals must present from the caller binding, not a hardcoded false.
@Suite("Platform Layer4 modal presentation", HostedViewTestIsolationTrait())
struct PlatformModalsLayer4PresentationTests {

    @Test @MainActor
    func platformAlertPresentsAndDismissesThroughCallerBinding() throws {
        #if canImport(ViewInspector)
        let presented = Binding(wrappedValue: true)
        let view = Text("Root").platformAlert(
            isPresented: presented,
            title: "Confirmation",
            actions: { Button("OK") {} },
            message: { Text("Are you sure?") }
        )
        let alert = try view.inspect().find(ViewType.Alert.self)
        #expect(try alert.title().string() == "Confirmation")
        try alert.dismiss()
        #expect(presented.wrappedValue == false)
        #endif
    }

    @Test @MainActor
    func platformAlertStaysHiddenWhenCallerBindingIsFalse() {
        #if canImport(ViewInspector)
        let view = Text("Root").platformAlert(
            isPresented: .constant(false),
            title: "Confirmation",
            actions: { Button("OK") {} },
            message: { Text("Are you sure?") }
        )
        #expect(isHidden { _ = try view.inspect().find(ViewType.Alert.self) })
        #endif
    }

    @Test @MainActor
    func platformConfirmationDialogPresentsAndDismissesThroughCallerBinding() throws {
        #if canImport(ViewInspector)
        let presented = Binding(wrappedValue: true)
        let view = Text("Root").platformConfirmationDialog(
            isPresented: presented,
            title: "Confirm",
            actions: { Button("Yes") {} },
            message: { Text("Sure?") }
        )
        let dialog = try view.inspect().find(ViewType.ConfirmationDialog.self)
        #expect(try dialog.title().string() == "Confirm")
        try dialog.dismiss()
        #expect(presented.wrappedValue == false)
        #endif
    }

    @Test @MainActor
    func platformConfirmationDialogStaysHiddenWhenCallerBindingIsFalse() {
        #if canImport(ViewInspector)
        let view = Text("Root").platformConfirmationDialog(
            isPresented: .constant(false),
            title: "Confirm",
            actions: { Button("Yes") {} },
            message: { Text("Sure?") }
        )
        #expect(isHidden { _ = try view.inspect().find(ViewType.ConfirmationDialog.self) })
        #endif
    }

    #if canImport(ViewInspector)
    @MainActor
    private func isHidden(_ body: () throws -> Void) -> Bool {
        do {
            try body()
            return false
        } catch {
            return true
        }
    }
    #endif
}
