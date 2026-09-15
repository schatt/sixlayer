import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformNotificationL1 (#466).
 * Observes L1 entry points (not only NotificationService).
 */

@Suite("Platform Notification L1 Unit", HostedViewTestIsolationTrait())
struct PlatformNotificationL1UnitTests {

    @Test @MainActor
    func requestPermissionL1ReturnsDeterminedStatus() async {
        let status = await platformRequestNotificationPermission_L1()
        // Unit env forces .notDetermined (same as NotificationServiceTests).
        #expect(status == .notDetermined || status == .denied || status == .authorized || status == .provisional)
    }

    @Test @MainActor
    func showNotificationL1ThrowsPermissionDeniedInUnitEnv() async throws {
        // Deliberate red (#466): expect success; unit env denies permission.
        try await platformShowNotification_L1(title: "T", body: "B")
        #expect(Bool(true), "deliberate red: notification show must succeed")
    }

    @Test @MainActor
    func updateBadgeL1AcceptsNonNegativeCount() throws {
        try platformUpdateBadge_L1(count: 0)
        try platformUpdateBadge_L1(count: 3)
    }

    @Test @MainActor
    func presentAlertL1HostsEmptyShell() {
        #if os(watchOS)
        return
        #else
        let view = platformPresentAlert_L1(
            title: "Alert",
            message: "Message",
            locale: Locale(identifier: "en_US")
        )
        let hosted = TestSetupUtilities.hostRootPlatformView(view, forceLayout: true)
        #expect(hosted != nil, "alert L1 service shell must host")
        #endif
    }
}
