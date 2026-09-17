import Foundation
import SwiftUI
import Testing
@testable import SixLayerFramework

/**
 * Unit-lane coverage for PlatformSplitViewState (#467).
 * View split builders stay VI/XCUI; state + persistence execute on unit schemes.
 */

@Suite("Platform Split View Layer4 State Unit")
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

        let restored = PlatformSplitViewState()
        #expect(restored.restoreFromUserDefaults(key: key))
        #expect(!restored.isPaneVisible(0))
        #expect(restored.isPaneLocked(1))
    }

    @Test func animationConfigurationCasesAreDistinct() {
        let ease = PlatformSplitViewAnimationConfiguration(duration: 0.2, curve: .easeInOut)
        let spring = PlatformSplitViewAnimationConfiguration(duration: 0.3, curve: .spring)
        #expect(ease.curveType != spring.curveType)
        _ = ease.animation
        _ = spring.animation
    }
}
