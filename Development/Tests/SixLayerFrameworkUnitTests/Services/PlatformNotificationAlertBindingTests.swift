import SwiftUI
import Testing
@testable import SixLayerFramework

/// #555 / #556: suppression must not write `isPresented` while the modifier is built.
/// The caller binding stays the one SwiftUI presents, and hosting clears it
/// only when Do Not Disturb actually blocks the alert. RTL uses the same rule.
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
        let binding = Binding(get: { presented }, set: { presented = $0 })
        let view = Text("Alert").platformNotificationAlert(
            isPresented: binding,
            title: "Blocked",
            primaryAction: .default(Text("OK")),
            notificationService: service
        )

        #if os(iOS) || os(macOS)
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        pumpMainRunLoop(for: 0.3)
        #expect(
            presented == false,
            "Hosting a suppressed alert must clear the caller binding"
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

    @Test @MainActor
    func suppressedRTLAlertDoesNotWriteBindingDuringConstruction() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(true)
        var presented = true
        let binding = Binding(get: { presented }, set: { presented = $0 })

        _ = Text("Alert").platformNotificationAlertRTL(
            isPresented: binding,
            title: "Blocked",
            primaryAction: .default(Text("OK")),
            locale: Locale(identifier: "ar"),
            notificationService: service
        )

        #expect(
            presented == true,
            "Building platformNotificationAlertRTL must not write isPresented"
        )
    }

    @Test @MainActor
    func suppressedRTLAlertClearsCallerAfterHosting() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(true)
        var presented = true
        let binding = Binding(get: { presented }, set: { presented = $0 })
        let view = Text("Alert").platformNotificationAlertRTL(
            isPresented: binding,
            title: "Blocked",
            primaryAction: .default(Text("OK")),
            locale: Locale(identifier: "ar"),
            notificationService: service
        )

        #if os(iOS) || os(macOS)
        #expect(TestSetupUtilities.hostRootPlatformView(view, forceLayout: true) != nil)
        pumpMainRunLoop(for: 0.3)
        #expect(
            presented == false,
            "Hosting a suppressed RTL alert must clear the caller binding"
        )
        #else
        _ = view
        #endif
    }

    @Test @MainActor
    func unsuppressedRTLAlertStaysPresentedThroughHosting() {
        let service = NotificationService()
        service.setDoNotDisturbActiveForTesting(false)
        var presented = true
        let binding = Binding(get: { presented }, set: { presented = $0 })
        let view = Text("Alert").platformNotificationAlertRTL(
            isPresented: binding,
            title: "Shown",
            primaryAction: .default(Text("OK")),
            locale: Locale(identifier: "ar"),
            notificationService: service
        )

        #expect(presented == true)
        #if os(iOS) || os(macOS)
        #expect(TestSetupUtilities.hostRootPlatformView(view) != nil)
        #endif
        #expect(
            presented == true,
            "An unsuppressed RTL alert must leave the caller binding presented"
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
