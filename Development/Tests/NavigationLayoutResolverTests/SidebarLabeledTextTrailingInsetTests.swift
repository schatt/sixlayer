import CoreGraphics
import SwiftUI
import Testing
#if canImport(ViewInspector)
import ViewInspector
#endif
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

    #if canImport(ViewInspector)
    /// macOS installs the modest trailing inset. Other ViewInspector lanes keep the system row (#554).
    @Test @MainActor
    func navigationButtonRowInsetFollowsPlatform() throws {
        let view = EmptyView().platformNavigationButton_L4(
            title: "Message Center",
            systemImage: "bell",
            accessibilityLabel: "Message Center",
            accessibilityHint: "Opens messages",
            action: {}
        )
        #if os(macOS)
        let insets = try view.inspect().listRowInsets()
        #expect(insets.trailing == SidebarLabeledTextTrailingInset.points)
        #expect(insets.trailing <= insets.leading)
        #else
        do {
            _ = try view.inspect().listRowInsets()
            Issue.record("Non-macOS lanes must not install the macOS listRowInsets")
        } catch {
            #expect(
                String(describing: error).contains("listRowInsets"),
                "Expected a missing listRowInsets modifier, got: \(error)"
            )
        }
        #endif
    }
    #endif

    @Test
    func nonMacPlatformsKeepTheSystemRowInset() {
        for platform in [SixLayerPlatform.iOS, .watchOS, .tvOS, .visionOS] {
            #expect(SidebarLabeledTextTrailingInset.rowInsets(for: platform) == nil)
        }
    }
}
