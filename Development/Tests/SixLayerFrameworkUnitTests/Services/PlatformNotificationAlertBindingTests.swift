import SwiftUI
import Testing
@testable import SixLayerFramework

/// #555: suppression must not write `isPresented` while the modifier is built.
/// The caller binding stays the one SwiftUI presents, and hosting clears it
/// only when Do Not Disturb actually blocks the alert.
@Suite("Platform notification alert binding", HostedViewTestIsolationTrait())
@MainActor
struct PlatformNotificationAlertBindingTests {

    @Test @MainActor
    func suppressedAlertDoesNotWriteBindingDuringConstruction() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(true)
        var presented = true
        let binding = Binding(get: { presented }, set: { presented = $0 })

        _ = Text("Alert").platformNotificationAlert(
            isPresented: binding,
            title: "Blocked",
            primaryAction: .default(Text("OK")),
            notificationService: service
        )

        #expect(
            presented == true,
            "Building platformNotificationAlert must not write isPresented"
        )
    }

    @Test @MainActor
    func suppressedAlertClearsCallerAfterHosting() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(true)
        var presented = true
        var writes = 0
        let binding = Binding(get: { presented }, set: { newValue in
            presented = newValue
            writes += 1
        })
        let view = Text("Alert").platformNotificationAlert(
            isPresented: binding,
            title: "Blocked",
            primaryAction: .default(Text("OK")),
            notificationService: service
        )

        #if os(iOS) || os(macOS)
        #expect(TestSetupUtilities.hostRootPlatformView(view) != nil)
        pumpMainRunLoop(for: 0.3)
        #expect(
            presented == false,
            "Hosting a suppressed alert must clear the caller binding (writes=\(writes), presented=\(presented))"
        )
        #else
        _ = view
        #endif
    }

    @Test @MainActor
    func unsuppressedAlertStaysPresentedThroughHosting() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(false)
        var presented = true
        let binding = Binding(get: { presented }, set: { presented = $0 })
        let view = Text("Alert").platformNotificationAlert(
            isPresented: binding,
            title: "Shown",
            primaryAction: .default(Text("OK")),
            notificationService: service
        )

        #expect(presented == true)
        #if os(iOS) || os(macOS)
        #expect(TestSetupUtilities.hostRootPlatformView(view) != nil)
        #endif
        #expect(
            presented == true,
            "An unsuppressed alert must leave the caller binding presented"
        )
    }
}

@MainActor
private func pumpMainRunLoop(for duration: TimeInterval) {
    let deadline = Date().addingTimeInterval(duration)
    while Date() < deadline {
        RunLoop.main.run(mode: .common, before: Date(timeIntervalSinceNow: 0.005))
    }
}
