import Testing
import SwiftUI
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformMessagingLayer5 + PlatformResourceLayer5 (#455).
 * VI a11y tests exist but are excluded from SLF-*-UnitTests.
 */

@Suite("Platform Messaging & Resource Layer5 Unit")
struct PlatformMessagingResourceLayer5UnitTests {

    // MARK: - Messaging enums (deliberate red: wrong ToastType count)

    @Test func testToastTypeExhaustiveCaseCount() {
        let types: [ToastType] = [.success, .error, .warning, .info]
        // Deliberate red for #455 until locked to production (4).
        #expect(types.count == 99)
    }

    @Test func testBannerTypeExhaustiveCaseCount() {
        let types: [BannerType] = [.success, .error, .warning, .info]
        #expect(types.count == 4)
    }

    @Test func testAlertStyleCasesAreDistinct() {
        #expect(AlertStyle.default != AlertStyle.destructive)
    }

    // MARK: - PlatformMessagingLayer5 public helpers

    @Test @MainActor func testCreateAlertButtonDefaultAndDestructive() {
        let layer = PlatformMessagingLayer5()
        var defaultTapped = false
        var destructiveTapped = false
        let defaultButton = layer.createAlertButton(title: "OK", style: .default) {
            defaultTapped = true
        }
        let destructiveButton = layer.createAlertButton(title: "Delete", style: .destructive) {
            destructiveTapped = true
        }
        _ = defaultButton
        _ = destructiveButton
        #expect(!defaultTapped)
        #expect(!destructiveTapped)
    }

    @Test @MainActor func testCreateToastNotificationForAllTypes() {
        let layer = PlatformMessagingLayer5()
        for type in [ToastType.success, .error, .warning, .info] {
            let toast = layer.createToastNotification(message: "msg-\(type)", type: type)
            _ = toast
        }
    }

    @Test @MainActor func testCreateBannerNotificationForAllTypes() {
        let layer = PlatformMessagingLayer5()
        for type in [BannerType.success, .error, .warning, .info] {
            let banner = layer.createBannerNotification(
                title: "Title",
                message: "Body-\(type)",
                type: type
            )
            _ = banner
        }
    }

    // MARK: - PlatformResourceLayer5 public helpers

    @Test @MainActor func testCreateResourceButton() {
        let layer = PlatformResourceLayer5()
        var tapped = false
        let button = layer.createResourceButton(title: "Load") {
            tapped = true
        }
        _ = button
        #expect(!tapped)
    }

    @Test @MainActor func testCreateImagePickerButton() {
        let layer = PlatformResourceLayer5()
        let button = layer.createImagePickerButton(action: {})
        _ = button
    }

    @Test @MainActor func testCreateResourceTextField() {
        let layer = PlatformResourceLayer5()
        var text = "seed"
        let field = layer.createResourceTextField(placeholder: "Name", text: Binding(
            get: { text },
            set: { text = $0 }
        ))
        _ = field
        #expect(text == "seed")
    }

    @Test @MainActor func testCreateImageViewPlaceholderAndNilImage() {
        let layer = PlatformResourceLayer5()
        let placeholder = layer.createImageView(image: nil, placeholder: "No Image Yet")
        _ = placeholder
    }

    @Test @MainActor func testCreateLoadingIndicator() {
        let layer = PlatformResourceLayer5()
        let indicator = layer.createLoadingIndicator()
        _ = indicator
    }
}
