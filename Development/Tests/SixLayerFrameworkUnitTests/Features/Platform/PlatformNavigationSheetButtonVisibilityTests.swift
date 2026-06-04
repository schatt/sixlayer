import SixLayerFramework
import SwiftUI
import Testing

@Suite("PlatformNavigationSheetButtonVisibility")
struct PlatformNavigationSheetButtonVisibilityTests {

    @Test func phoneOrDetailOnly_showsOnPhone() {
        #expect(
            PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .phone,
                columnVisibility: .all
            )
        )
    }

    @Test func phoneOrDetailOnly_showsOnCarPlayDevice() {
        #expect(
            PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .car,
                columnVisibility: .all
            )
        )
    }

    @Test func phoneOrDetailOnly_showsOnPadWhenDetailOnlyColumn() {
        #expect(
            PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .pad,
                columnVisibility: .detailOnly
            )
        )
    }

    @Test func phoneOrDetailOnly_hidesOnPadWhenSplitVisible() {
        #expect(
            !PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .pad,
                columnVisibility: .all
            )
        )
    }

    @Test func phoneOrDetailOnly_hidesOnPadWhenDoubleColumn() {
        #expect(
            !PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .pad,
                columnVisibility: .doubleColumn
            )
        )
    }

    @Test func phoneOrDetailOnly_showsOnMacForSidebarToggle() {
        #expect(
            PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .phoneOrDetailOnly,
                deviceType: .mac,
                columnVisibility: .all
            )
        )
    }

    @Test func always_showsRegardlessOfDeviceAndVisibility() {
        #expect(
            PlatformNavigationSheetButtonVisibility.shouldShow(
                policy: .always,
                deviceType: .pad,
                columnVisibility: .all
            )
        )
    }
}
