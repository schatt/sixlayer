import SwiftUI
import Testing
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// #532: embedded and sheet settings dismissal must run from an explicit control.
/// Applying the modifier must not fire the close or dismiss action during construction.
@Suite("Platform settings dismiss", HostedViewTestIsolationTrait())
struct PlatformDismissSettingsUnitTests {

    @Test @MainActor
    func applyingEmbeddedSettingsDismissDoesNotRunCloseAction() {
        let counter = CloseActionCounter()
        let view = Text("Settings").platformDismissEmbeddedSettings {
            counter.record()
        }
        _ = view
        #expect(
            counter.count == 0,
            "Applying platformDismissEmbeddedSettings ran onClose during view construction"
        )
    }

    @Test @MainActor
    func closeControlRunsEmbeddedSettingsDismissAction() throws {
        #if canImport(ViewInspector)
        let counter = CloseActionCounter()
        let view = Text("Settings").platformDismissEmbeddedSettings {
            counter.record()
        }
        let close = findAllInViewHierarchy(view, ViewType.Button.self).first { button in
            (try? button.accessibilityIdentifier()) == "platformDismissEmbeddedSettings.close"
        }
        #expect(close != nil, "Embedded settings dismiss must expose an explicit close control")
        try close?.tap()
        #expect(counter.count == 1, "Activating the close control must run onClose once")
        #endif
    }

    @Test @MainActor
    func applyingSheetSettingsDismissDoesNotDismissDuringConstruction() throws {
        #if canImport(ViewInspector)
        let host = SheetSettingsDismissHost()
        let dismiss = findAllInViewHierarchy(host, ViewType.Button.self).first { button in
            (try? button.accessibilityIdentifier()) == "platformDismissSheetSettings.dismiss"
        }
        #expect(
            dismiss != nil,
            "Sheet settings dismiss must install a dismiss control instead of dismissing during construction"
        )
        try dismiss?.tap()
        #endif
    }
}

/// Hosts the public sheet-dismiss API with the environment presentation binding.
private struct SheetSettingsDismissHost: View {
    var body: some View {
        SheetSettingsDismissBody()
    }
}

private struct SheetSettingsDismissBody: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Text("Settings").platformDismissSheetSettings(presentationMode: presentationMode)
    }
}
