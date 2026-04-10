//
//  PlatformToolbarIssue221TestView.swift
//  SixLayerFrameworkUITests
//
//  Host views for XCUITest: optional accessibilityIdentifier on platformFormToolbar / platformDetailToolbar (Issue #221).
//

import SwiftUI
import SixLayerFramework

/// Identifiers shared with `PlatformFormToolbarAccessibilityTests` (nil case) and `PlatformToolbarAccessibilityUITests`.
enum PlatformToolbarIssue221TestIDs {
    static let formSave = "SixLayer.tests.platformFormToolbar.save.221"
    static let formCancel = "SixLayer.tests.platformFormToolbar.cancel.221"
    static let formSelect = "SixLayer.tests.platformFormToolbar.select.221"
    static let detailSave = "SixLayer.tests.platformDetailToolbar.save.221"
    static let detailCancel = "SixLayer.tests.platformDetailToolbar.cancel.221"
}

/// Hub: open from launch page (`onBackToMain`) or alone via `-OpenPlatformToolbarIssue221` (`onBackToMain == nil`).
struct PlatformToolbarIssue221HubView: View {
    var onBackToMain: (() -> Void)?

    var body: some View {
        List {
            if let onBackToMain {
                Button("Back to Main", action: onBackToMain)
                    .accessibilityIdentifier("back-to-main-button")
            }
            NavigationLink("Form toolbar") {
                PlatformToolbarIssue221FormHostView()
            }
            .accessibilityIdentifier("uitest-221-nav-form")
            NavigationLink("Detail toolbar") {
                PlatformToolbarIssue221DetailHostView()
            }
            .accessibilityIdentifier("uitest-221-nav-detail")
        }
        .navigationTitle("Toolbar Issue 221")
    }
}

struct PlatformToolbarIssue221TestView: View {
    let onBackToMain: () -> Void

    var body: some View {
        PlatformToolbarIssue221HubView(onBackToMain: onBackToMain)
    }
}

private struct PlatformToolbarIssue221FormHostView: View {
    var body: some View {
        Text("Form toolbar host")
            .accessibilityIdentifier("uitest-221-form-host-content")
            .navigationTitle("Form Toolbar")
            .platformFormToolbar(
                onCancel: {},
                onSave: {},
                saveButtonTitle: "Save",
                cancelButtonTitle: "Cancel",
                saveButtonAccessibilityIdentifier: PlatformToolbarIssue221TestIDs.formSave,
                cancelButtonAccessibilityIdentifier: PlatformToolbarIssue221TestIDs.formCancel,
                selectButtonAccessibilityIdentifier: PlatformToolbarIssue221TestIDs.formSelect
            )
    }
}

private struct PlatformToolbarIssue221DetailHostView: View {
    var body: some View {
        Text("Detail toolbar host")
            .accessibilityIdentifier("uitest-221-detail-host-content")
            .navigationTitle("Detail Toolbar")
            .platformDetailToolbar(
                onCancel: {},
                onSave: {},
                saveButtonTitle: "Done",
                saveButtonAccessibilityIdentifier: PlatformToolbarIssue221TestIDs.detailSave,
                cancelButtonAccessibilityIdentifier: PlatformToolbarIssue221TestIDs.detailCancel
            )
    }
}
