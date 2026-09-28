import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// #508: applying `platformDismissWindowSettings` must not dismiss.
/// The close action runs only when the close control is activated.
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

    @Test @MainActor
    func closeControlRunsWindowSettingsDismissAction() throws {
        #if canImport(ViewInspector) && os(macOS)
        let counter = CloseActionCounter()
        let view = Text("Settings").platformDismissWindowSettings {
            counter.record()
        }
        let close = findAllInViewHierarchy(view, ViewType.Button.self).first { button in
            (try? button.accessibilityIdentifier()) == "platformDismissWindowSettings.close"
        }
        #expect(close != nil, "Window settings dismiss must expose an explicit close control")
        try close?.tap()
        #expect(counter.count == 1, "Activating the close control must run the close action once")
        #endif
    }
}

@MainActor
final class CloseActionCounter {
    private(set) var count = 0

    func record() {
        count += 1
    }
}
