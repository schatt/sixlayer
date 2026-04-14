import SwiftUI

// MARK: - Modal sheet navigation chrome (issue #223)

public extension View {
    /// Composable shell for modal sheet roots: wraps content in ``platformNavigation_L4`` (iOS),
    /// applies navigation title and display mode, and adds a trailing confirmation toolbar action.
    ///
    /// Use this (or ``platformNavigation_L4`` manually) for sheet content that sets a toolbar on iOS
    /// so items appear in the navigation bar.
    ///
    /// - Parameters:
    ///   - title: Navigation title string.
    ///   - titleDisplayMode: Bar title display mode; defaults to ``PlatformTitleDisplayMode/inline`` for typical sheets.
    ///   - confirmationTitle: Trailing action title (e.g. "Done").
    ///   - onConfirmation: Action for the confirmation control.
    ///   - content: Sheet body inside the navigation hierarchy.
    @ViewBuilder
    func platformModalSheetNavigationChrome_L4<Content: View>(
        title: String,
        titleDisplayMode: PlatformTitleDisplayMode = .inline,
        confirmationTitle: String = "Done",
        onConfirmation: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        platformNavigation_L4 {
            content()
                .platformNavigationTitle_L4(title)
                .platformNavigationTitleDisplayMode_L4(titleDisplayMode)
                .platformToolbarWithConfirmationAction(
                    confirmationAction: onConfirmation,
                    confirmationTitle: confirmationTitle
                )
        }
        .automaticCompliance(named: "platformModalSheetNavigationChrome_L4")
    }

    /// Like ``platformModalSheetNavigationChrome_L4(title:titleDisplayMode:confirmationTitle:onConfirmation:content:)``
    /// but adds a leading toolbar slot (e.g. Reset) before the confirmation action.
    @ViewBuilder
    func platformModalSheetNavigationChrome_L4<Content: View, Leading: View>(
        title: String,
        titleDisplayMode: PlatformTitleDisplayMode = .inline,
        confirmationTitle: String = "Done",
        onConfirmation: @escaping () -> Void,
        @ViewBuilder leadingToolbar: @escaping () -> Leading,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        platformNavigation_L4 {
            content()
                .platformNavigationTitle_L4(title)
                .platformNavigationTitleDisplayMode_L4(titleDisplayMode)
                .platformToolbarWithLeadingActions { leadingToolbar() }
                .platformToolbarWithConfirmationAction(
                    confirmationAction: onConfirmation,
                    confirmationTitle: confirmationTitle
                )
        }
        .automaticCompliance(named: "platformModalSheetNavigationChrome_L4")
    }
}
