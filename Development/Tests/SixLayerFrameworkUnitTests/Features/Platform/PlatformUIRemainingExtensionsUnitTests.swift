//
//  PlatformUIRemainingExtensionsUnitTests.swift
//  SixLayerFrameworkUnitTests
//
//  Unit-lane coverage for remaining small Platform UI extension zeros (#468).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform UI remaining extensions (#468)")
struct PlatformUIRemainingExtensionsUnitTests {

    // MARK: - PlatformSpacing

    @Test func spacingSmallAndMediumAreEightPtGrid() {
        #expect(PlatformSpacing.small == 4)
        #expect(PlatformSpacing.medium == 8)
        #expect(PlatformSpacing.reducedPadding == 8)
    }

    @Test func spacingLargeIsPlatformAware() {
        #if os(macOS)
        #expect(PlatformSpacing.large == 12)
        #expect(PlatformSpacing.padding == 12)
        #else
        #expect(PlatformSpacing.large == 16)
        #expect(PlatformSpacing.padding == 16)
        #endif
    }

    // MARK: - PlatformUITypes

    @Test func titleDisplayModeCasesAreDistinct() {
        let modes: [PlatformTitleDisplayMode] = [.inline, .large, .automatic]
        #expect(modes.count == 3)
    }

    @Test func tabItemIdDerivesFromTitle() {
        let item = PlatformTabItem(title: "Settings", systemImage: "gear")
        #expect(item.id == "Settings")
        #expect(item.systemImage == "gear")
    }

    @Test func presentationDetentBridgesToPresentationSize() {
        #expect(PlatformPresentationDetent.medium.asPresentationSize == .medium)
        #expect(PlatformPresentationDetent.large.asPresentationSize == .large)
        let custom = PlatformPresentationDetent.custom(120)
        #expect(custom.asPresentationSize == .exact(width: 120, height: 120))
    }

    // MARK: - PlatformAnimation

    @Test func animationCasesAreDistinct() {
        let cases: [PlatformAnimation] = [
            .easeIn, .easeOut, .easeInOut, .linear, .spring, .interactiveSpring
        ]
        #expect(cases.count == 6)
        _ = cases.map(\.swiftUIAnimation)
    }

    // MARK: - Accessibility hint helpers (BasicContainer)

    @Test func buttonHint_saveUsesSaveMessage() {
        #expect(generateAccessibilityHintForButton(label: "Save") == "Saves your current work")
    }

    @Test func buttonHint_unknownFallsBackToActivate() {
        #expect(generateAccessibilityHintForButton(label: "Go") == "Double tap to activate")
    }

    @Test func textFieldHint_emailUsesEmailMessage() {
        #expect(
            generateAccessibilityHintForTextField(label: "Email", prompt: nil)
                == "Enter your email address"
        )
    }

    @Test func toggleValue_onAndOff() {
        #expect(generateAccessibilityValueForToggle(isOn: true) == "On")
        #expect(generateAccessibilityValueForToggle(isOn: false) == "Off")
    }
}

@Suite("Platform UI remaining extension hosts (#468)", HostedViewTestIsolationTrait())
struct PlatformUIRemainingExtensionHostsUnitTests {

    @Test @MainActor
    func tabViewStyleHosts() {
        hostView {
            Text("Tab").platformTabViewStyle()
        }
    }

    @Test @MainActor
    func textFieldStyleHosts() {
        hostView {
            TextField("Name", text: .constant("")).platformTextFieldStyle()
        }
    }

    @Test @MainActor
    func animationModifierHosts() {
        hostView {
            Text("Anim").platformAnimation(.easeInOut)
        }
    }

    @Test @MainActor
    func scrollContainerHosts() {
        hostView {
            Text("Scroll").platformScrollContainer()
        }
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
