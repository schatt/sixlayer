import SwiftUI
import Testing
@testable import SixLayerFramework

/// #533: Do Not Disturb suppression must not replace the caller binding
/// with a constant. The caller is cleared, and later writes still hit it.
@Suite("Platform notification alert binding")
struct PlatformNotificationAlertBindingTests {

    @Test @MainActor
    func suppressionClearsCallerAndKeepsWriteThrough() {
        var presented = true
        let caller = Binding(get: { presented }, set: { presented = $0 })
        let presentable = PlatformNotificationAlertPresentation.presentableBinding(
            caller: caller,
            suppress: true
        )
        #expect(
            presented == false,
            "Suppressing the alert must clear the caller binding"
        )
        presentable.wrappedValue = true
        #expect(
            presented == true,
            "The presented binding must write through to the caller"
        )
    }

    @Test @MainActor
    func unsuppressedAlertKeepsCallerPresented() {
        var presented = true
        let caller = Binding(get: { presented }, set: { presented = $0 })
        let presentable = PlatformNotificationAlertPresentation.presentableBinding(
            caller: caller,
            suppress: false
        )
        #expect(presented == true)
        presentable.wrappedValue = false
        #expect(presented == false, "Dismiss must clear the caller binding")
    }
}
