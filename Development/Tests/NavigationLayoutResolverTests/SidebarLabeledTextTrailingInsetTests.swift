import CoreGraphics
import SwiftUI
import Testing
import ViewInspector
@testable import SixLayerFramework

/// Full-text sidebar labels keep a modest trailing inset (#552).
@Suite("Sidebar labeled text trailing inset #552")
struct SidebarLabeledTextTrailingInsetTests {

    @Test
    func macOSTrailingInsetIsModestAndNotWiderThanLeading() {
        let insets = SidebarLabeledTextTrailingInset.rowInsets(for: .macOS)
        #expect(insets != nil)
        let row = insets!
        // Both directions: a zero inset collides with the divider; a wide gutter clips the title.
        #expect(row.trailing >= 8)
        #expect(row.trailing <= 12)
        #expect(row.trailing <= row.leading)
        #expect(row.leading >= 8)
        #expect(row.leading <= 16)
    }

    @Test @MainActor
    func navigationButtonAppliesModestTrailingInset() throws {
        let view = EmptyView().platformNavigationButton_L4(
            title: "Message Center",
            systemImage: "bell",
            accessibilityLabel: "Message Center",
            accessibilityHint: "Opens messages",
            action: {}
        )
        let insets = try view.inspect().listRowInsets()
        #expect(insets.trailing == SidebarLabeledTextTrailingInset.points)
        #expect(insets.trailing <= insets.leading)
    }

    @Test
    func nonMacPlatformsKeepTheSystemRowInset() {
        for platform in [SixLayerPlatform.iOS, .watchOS, .tvOS, .visionOS] {
            #expect(SidebarLabeledTextTrailingInset.rowInsets(for: platform) == nil)
        }
    }
}
