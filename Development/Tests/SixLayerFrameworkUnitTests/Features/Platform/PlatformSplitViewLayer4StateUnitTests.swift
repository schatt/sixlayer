import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformSplitViewLayer4 (#467):
 * state/persistence plus split builders' named compliance.
 */

@Suite("Platform Split View Layer4 State Unit", HostedViewTestIsolationTrait())
@MainActor
struct PlatformSplitViewLayer4StateUnitTests {

    @Test func defaultVisibilityAndToggle() {
        let state = PlatformSplitViewState()
        #expect(state.isPaneVisible(0))
        state.togglePane(0)
        #expect(!state.isPaneVisible(0))
        state.togglePane(0)
        #expect(state.isPaneVisible(0))
    }

    @Test func defaultVisibilityFalseAppliesUntilSet() {
        let state = PlatformSplitViewState(defaultVisibility: false)
        #expect(!state.isPaneVisible(3))
        state.setPaneVisible(3, visible: true)
        #expect(state.isPaneVisible(3))
    }

    @Test func setPaneVisibleInvokesCallback() {
        var seen: (Int, Bool)?
        let state = PlatformSplitViewState()
        state.onVisibilityChange = { index, visible in
            seen = (index, visible)
        }
        state.setPaneVisible(2, visible: false)
        #expect(seen?.0 == 2)
        #expect(seen?.1 == false)
    }

    @Test func paneLockDefaultsAndSet() {
        let state = PlatformSplitViewState()
        #expect(!state.isPaneLocked(0))
        state.setPaneLocked(0, locked: true)
        #expect(state.isPaneLocked(0))
    }

    @Test func userDefaultsRoundTrip() {
        let key = "sixlayer-467-split-\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let original = PlatformSplitViewState()
        original.setPaneVisible(0, visible: false)
        original.setPaneLocked(1, locked: true)
        #expect(original.saveToUserDefaults(key: key))
        #expect(original.saveToAppStorage(key: key))

        let restored = PlatformSplitViewState()
        #expect(restored.restoreFromUserDefaults(key: key))
        #expect(!restored.isPaneVisible(0))
        #expect(restored.isPaneLocked(1))
    }

    @Test func restoreFromMissingUserDefaultsKeyFails() {
        let missing = "sixlayer-467-missing-\(UUID().uuidString)"
        let restored = PlatformSplitViewState()
        #expect(!restored.restoreFromUserDefaults(key: missing))
    }

    @Test func animationConfigurationCasesAreDistinct() {
        let curves: [PlatformSplitViewAnimationConfiguration.AnimationCurveType] = [
            .easeInOut, .easeIn, .easeOut, .linear, .spring
        ]
        let animations = curves.map {
            PlatformSplitViewAnimationConfiguration(duration: 0.2, curve: $0)
        }
        #expect(Set(animations.map(\.curveType)).count == curves.count)
        for config in animations {
            _ = config.animation
        }
    }

    @Test func paneSizingAndAppearanceConfigsConstruct() {
        let pane = PlatformSplitViewPaneSizing(
            minWidth: 100,
            idealWidth: 200,
            maxWidth: 400,
            minHeight: 80,
            idealHeight: 160,
            maxHeight: 320,
            priority: 0.8
        )
        let pair = PlatformSplitViewSizing(firstPane: pane, secondPane: pane, responsive: true)
        #expect(pair.firstPane?.priority == 0.8)
        #expect(pair.panes.isEmpty)
        #expect(pair.responsive)

        let arraySizing = PlatformSplitViewSizing(panes: [pane, pane])
        #expect(arraySizing.firstPane?.minWidth == 100)
        #expect(arraySizing.secondPane?.maxWidth == 400)
        #expect(arraySizing.panes.count == 2)

        let divider = PlatformSplitViewDivider(color: .red, width: 2, style: .dashed)
        if case .dashed = divider.style {
            #expect(divider.width == 2)
        } else {
            Issue.record("expected dashed divider style")
        }
        let appearance = PlatformSplitViewAppearance(
            backgroundColor: .blue,
            cornerRadius: 8,
            shadow: PlatformSplitViewShadow(color: .black, radius: 4, x: 1, y: 2)
        )
        #expect(appearance.cornerRadius == 8)
        let styles: [PlatformSplitViewStyle] = [.balanced, .prominentDetail, .custom]
        #expect(styles.count == 3)
        let dividerStyles: [PlatformSplitViewDividerStyle] = [.solid, .dashed, .dotted, .none]
        #expect(dividerStyles.count == 4)
    }

    #if os(macOS)
    @Test func keyboardShortcutUsesFirstCharacterAndEmptyFallback() {
        let typed = PlatformSplitViewKeyboardShortcut(
            key: "t",
            modifiers: .command,
            action: .togglePane(0)
        )
        #expect(typed.action == .togglePane(0))

        let empty = PlatformSplitViewKeyboardShortcut(
            key: "",
            modifiers: .option,
            action: .toggleAll
        )
        #expect(empty.action == .toggleAll)
        #expect(PlatformSplitViewKeyboardAction.showPane(1) != .hidePane(1))
    }
    #endif

    @Test @MainActor
    func verticalSplitUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformVerticalSplit_L4") {
            Text("Root").platformVerticalSplit_L4(spacing: 4) {
                Text("Top")
                Text("Bottom")
            }
        }
    }

    @Test @MainActor
    func verticalSplitWithSizingUsesNamedCompliance() {
        let sizing = PlatformSplitViewSizing(
            firstPane: PlatformSplitViewPaneSizing(minWidth: 80),
            container: PlatformSplitViewPaneSizing(maxWidth: 600)
        )
        hostExpectingNamedCompliance("platformVerticalSplit_L4") {
            Text("Root").platformVerticalSplit_L4(spacing: 4, sizing: sizing) {
                Text("Top")
                Text("Bottom")
            }
        }
    }

    @Test @MainActor
    func verticalSplitWithStyleAppearanceUsesNamedCompliance() {
        let appearance = PlatformSplitViewAppearance(
            backgroundColor: .gray,
            cornerRadius: 6,
            shadow: PlatformSplitViewShadow(color: .black, radius: 2)
        )
        hostExpectingNamedCompliance("platformVerticalSplit_L4") {
            Text("Root").platformVerticalSplit_L4(
                spacing: 4,
                style: .balanced,
                divider: PlatformSplitViewDivider(style: .solid),
                appearance: appearance
            ) {
                Text("Top")
                Text("Bottom")
            }
        }
    }

    @Test @MainActor
    func verticalSplitWithStateUsesNamedCompliance() {
        let state = PlatformSplitViewState()
        hostExpectingNamedCompliance("platformVerticalSplit_L4") {
            Text("Root").platformVerticalSplit_L4(state: .constant(state), spacing: 4) {
                Text("Top")
                Text("Bottom")
            }
        }
    }

    @Test @MainActor
    func horizontalSplitUsesNamedCompliance() {
        hostExpectingNamedCompliance("platformHorizontalSplit_L4") {
            Text("Root").platformHorizontalSplit_L4(spacing: 4) {
                Text("Leading")
                Text("Trailing")
            }
        }
    }

    @Test @MainActor
    func paneVisibilityAndSizingModifiersHost() {
        let state = PlatformSplitViewState()
        state.setPaneVisible(0, visible: false)
        hostView {
            Text("Pane")
                .splitViewPaneVisibility(index: 0, state: state)
                .splitViewPaneSizing(
                    PlatformSplitViewPaneSizing(minWidth: 40, maxWidth: 200)
                )
        }
    }

    @MainActor
    private func hostExpectingNamedCompliance<V: View>(
        _ name: String,
        @ViewBuilder _ view: () -> V
    ) {
        #if os(watchOS)
        return
        #else
        let isolated = TestSetupUtilities.makeIsolatedAccessibilityIdentifierConfig()
        isolated.enableDebugLogging = true
        isolated.clearDebugLog()
        let hosted = AccessibilityIdentifierConfig.$taskLocalConfig.withValue(isolated) {
            TestSetupUtilities.hostRootPlatformView(
                view(),
                forceLayout: true,
                accessibilityIdentifierConfig: isolated
            )
        }
        #expect(hosted != nil)
        #expect(
            isolated.getDebugLog().contains(name),
            "named compliance \(name) must appear in debug log"
        )
        #endif
    }

    @MainActor
    private func hostView<V: View>(@ViewBuilder _ view: () -> V) {
        #if os(watchOS)
        return
        #else
        #expect(TestSetupUtilities.hostRootPlatformView(view(), forceLayout: true) != nil)
        #endif
    }
}
