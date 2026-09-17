//
//  PlatformMacOSNavigationStackLayer6Tests.swift
//  SixLayerFrameworkTests
//
//  macOS NavigationStack L6 keyboard-first navigation (#446).
//  Decisions + modifier subject types. Do not host NavigationStack (#369).
//  Opposite-lane identity for the zero-arg L6 API: PlatformElseStubIdentityTests (#449).
//

import SwiftUI
import Testing
@testable import SixLayerFramework

@Suite("Platform macOS NavigationStack Layer 6")
struct PlatformMacOSNavigationStackLayer6Tests {

    // MARK: - Keyboard chrome decision

    @Test
    func macOSUsesKeyboardFirstNavigationChrome() {
        #expect(platformMacOSNavigationStackKeyboardChrome(for: .macOS) == .keyboardFirst)
    }

    @Test
    func nonMacOSLeavesNavigationStackKeyboardChromeUnmodified() {
        for platform in [SixLayerPlatform.iOS, .tvOS, .watchOS, .visionOS] {
            #expect(
                platformMacOSNavigationStackKeyboardChrome(for: platform) == .unmodified,
                "\(platform) must not invent macOS NavigationStack keyboard chrome"
            )
        }
    }

    // MARK: - List ↔ detail default focus

    @Test
    func defaultFocusPaneIsListWhenDetailIsNotPresented() {
        #expect(platformMacOSNavigationDefaultFocusPane(isDetailPresented: false) == .list)
    }

    @Test
    func defaultFocusPaneIsDetailWhenDetailIsPresented() {
        #expect(platformMacOSNavigationDefaultFocusPane(isDetailPresented: true) == .detail)
    }

    @Test
    func defaultFocusValueFollowsResolvedPane() {
        #expect(
            platformMacOSNavigationDefaultFocusValue(pane: .list, list: "list", detail: "detail") == "list"
        )
        #expect(
            platformMacOSNavigationDefaultFocusValue(pane: .detail, list: "list", detail: "detail") == "detail"
        )
    }

    // MARK: - Escape / cancel for presented navigation

    @Test
    func exitCommandDismissesOnlyWhenPresented() {
        #expect(platformMacOSNavigationShouldDismissOnExit(isPresented: true))
        #expect(!platformMacOSNavigationShouldDismissOnExit(isPresented: false))
    }

    // MARK: - Keyboard shortcut kinds (Scene `commands` is not a View API)

    @Test
    func keyboardShortcutKindForBackIsCommandLeftBracket() {
        #expect(platformMacOSNavigationKeyboardShortcutKind(for: .back) == .commandLeftBracket)
    }

    @Test
    func keyboardShortcutKindForSelectIsDefaultAction() {
        #expect(platformMacOSNavigationKeyboardShortcutKind(for: .select) == .defaultAction)
    }

    @Test
    func keyboardShortcutKindForDismissIsCancelAction() {
        #expect(platformMacOSNavigationKeyboardShortcutKind(for: .dismiss) == .cancelAction)
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    @Test
    func keyboardShortcutMapsToSDKCancelAndDefaultActions() {
        let dismiss = platformMacOSNavigationKeyboardShortcut(for: .dismiss)
        #expect(dismiss.key == KeyboardShortcut.cancelAction.key)
        #expect(dismiss.modifiers == KeyboardShortcut.cancelAction.modifiers)

        let select = platformMacOSNavigationKeyboardShortcut(for: .select)
        #expect(select.key == KeyboardShortcut.defaultAction.key)
        #expect(select.modifiers == KeyboardShortcut.defaultAction.modifiers)

        let back = platformMacOSNavigationKeyboardShortcut(for: .back)
        #expect(back.key == KeyEquivalent("["))
        #expect(back.modifiers == EventModifiers.command)
    }
    #endif

    // MARK: - macOS L6 view adapters

    #if os(macOS)
    @Test @MainActor
    func platformMacOSNavigationStackEnhancementsAppliesKeyboardFirstChrome() {
        let view = Text("stack-root").platformMacOSNavigationStackEnhancements_L6()
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)

        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "PlatformMacOSNavigationFocusSectionModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "PlatformMacOSNavigationExitCommandModifier")
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "_FlexFrameLayout")

        #expect(
            !description.contains("AccessibilityAttachmentModifier"),
            "L6 must not blanket .isHeader, got: \(description)"
        )
        #expect(
            !description.contains("_FocusableModifier"),
            "L5 owns .focusable(); L6 must not duplicate it, got: \(description)"
        )
    }

    @Test @MainActor
    func platformMacOSNavigationKeyboardShortcutsWrapsRootOnMacOS() {
        let view = Text("shortcut-root").platformMacOSNavigationKeyboardShortcuts_L6(
            onBack: {},
            onSelect: {},
            onDismiss: {}
        )
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        BaseTestClass.expectViewSubjectTypeContains(
            view,
            rootViewName: "PlatformMacOSNavigationKeyboardShortcutsModifier"
        )
    }
    #endif

    // MARK: - Opposite-lane identity for new L6 helpers

    #if os(iOS)
    @Test @MainActor
    func platformMacOSNavigationKeyboardShortcutsStubPreservesRootOnIOS() {
        let view = Text("shortcut-root").platformMacOSNavigationKeyboardShortcuts_L6(
            onBack: {},
            onSelect: {},
            onDismiss: {}
        )
        BaseTestClass.expectViewSubjectTypeContains(view, rootViewName: "Text")
        let description = BaseTestClass.viewSubjectTypeDescription(for: view)
        #expect(
            !description.contains("PlatformMacOSNavigationKeyboardShortcutsModifier"),
            "iOS stub must stay identity, got: \(description)"
        )
    }
    #endif
}
