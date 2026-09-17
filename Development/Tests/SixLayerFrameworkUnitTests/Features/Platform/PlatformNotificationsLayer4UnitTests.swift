import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformNotificationsLayer4 (#467).
 * In DEBUG+test hosts, registration short-circuits without calling system APIs.
 */

@Suite("Platform Notifications Layer4 Unit")
struct PlatformNotificationsLayer4UnitTests {

    @Test @MainActor
    func registerForRemoteNotificationsL4ReturnsTrueOnPrimaryPlatforms() {
        #if os(iOS) || os(macOS)
        let initiated = platformRegisterForRemoteNotifications_L4()
        // Deliberate red (#467): expect false so primary-platform path must be exercised.
        #expect(!initiated, "deliberate red: expect registration not initiated")
        #else
        #expect(platformRegisterForRemoteNotifications_L4() == false)
        #endif
    }
}
