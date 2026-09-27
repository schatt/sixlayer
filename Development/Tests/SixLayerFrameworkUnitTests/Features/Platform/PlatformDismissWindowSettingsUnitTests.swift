import SwiftUI
import Testing
@testable import SixLayerFramework

/// #508: applying `platformDismissWindowSettings` must not dismiss.
/// Close runs only from an explicit control (ViewInspector lane).
@Suite("Platform window settings dismiss", HostedViewTestIsolationTrait())
struct PlatformDismissWindowSettingsUnitTests {

    @Test @MainActor
    func applyingPlatformDismissWindowSettingsDoesNotRunCloseAction() {
        let counter = CloseActionCounter()
        let view = Text("Settings").platformDismissWindowSettings {
            counter.record()
        }
        _ = view
        #expect(
            counter.count == 0,
            "Applying platformDismissWindowSettings ran the close action during view construction"
        )
    }
}

@MainActor
final class CloseActionCounter {
    private(set) var count = 0

    func record() {
        count += 1
    }
}
