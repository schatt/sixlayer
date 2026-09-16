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
        // Unit env forces .notDetermined (same contract as NotificationServiceTests).
        #expect(status == .notDetermined)
    }

    @Test @MainActor
    func showNotificationL1ThrowsPermissionDeniedInUnitEnv() async {
        do {
            try await platformShowNotification_L1(title: "T", body: "B")
            Issue.record("expected permissionDenied in unit-test env")
        } catch let error as NotificationServiceError {
            #expect(error == .permissionDenied)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
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
