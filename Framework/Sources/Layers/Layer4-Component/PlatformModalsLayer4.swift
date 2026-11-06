import SwiftUI

// MARK: - Platform Modals Layer 3: Layout Implementation

/// Platform-specific modal helper functions that implement consistent
/// modal patterns across iOS and macOS. This layer handles the specific
/// implementation of modal components.
public extension View {
    
    /// Platform-specific sheet presentation with consistent styling
    /// Provides standardized sheet appearance across platforms.
    ///
    /// Routes through the sizes-based `platformSheet` overload so presented roots get
    /// ``platformSheetNavigationChrome()`` on iOS and macOS (#636 / #639). Kept as a
    /// no-`sizes:` convenience; defaults to `[.large]`.
    ///
    /// **Note**: Prefer the sizes overload or `platformSheet_L4` when you need detents /
    /// drag-indicator control. `platformSheet_L4` stays wrapper-minimal (#193) and does
    /// **not** apply navigation chrome — call ``platformSheetNavigationChrome()`` on L4
    /// content when you need a titled toolbar root.
    ///
    /// - SeeAlso: `platformSheet(isPresented:sizes:onDismiss:content:)` for explicit sizes
    @MainActor
    func platformSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        // Sizes overload owns NavigationStack chrome (#639); do not route via L4 (#193).
        return self.platformSheet(
            isPresented: isPresented,
            sizes: [.large],
            onDismiss: onDismiss,
            content: content
        )
        .automaticCompliance(named: "platformSheet")
    }
    
    /// Platform-specific alert presentation.
    /// Visibility follows the caller binding, including dismiss writing `false`.
    func platformAlert<A: View, M: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder actions: @escaping () -> A,
        @ViewBuilder message: @escaping () -> M
    ) -> some View {
        self.platformAlert(
            title,
            isPresented: isPresented,
            actions: actions,
            message: message
        )
    }
    
    /// Platform-specific confirmation dialog.
    /// Visibility follows the caller binding, including dismiss writing `false`.
    func platformConfirmationDialog<A: View, M: View>(
        isPresented: Binding<Bool>,
        title: String,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: @escaping () -> A,
        @ViewBuilder message: @escaping () -> M
    ) -> some View {
        self.confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: titleVisibility,
            actions: actions,
            message: message
        )
    }

    /// Platform-specific settings dismissal for embedded navigation.
    /// Applying this modifier does not run `onClose`.
    /// The close control runs `onClose` when activated.
    func platformDismissEmbeddedSettings(
        onClose: @escaping () -> Void
    ) -> some View {
        settingsDismissControl(
            accessibilityIdentifier: "platformDismissEmbeddedSettings.close",
            action: onClose
        )
    }

    /// Platform-specific settings dismissal for sheet presentation.
    /// Applying this modifier does not dismiss.
    /// The dismiss control calls `presentationMode.dismiss()` when activated.
    func platformDismissSheetSettings(
        presentationMode: Binding<PresentationMode>
    ) -> some View {
        settingsDismissControl(
            accessibilityIdentifier: "platformDismissSheetSettings.dismiss",
            action: { presentationMode.wrappedValue.dismiss() }
        )
    }

    /// Explicit Done control. Construction must not run `action`.
    private func settingsDismissControl(
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .topTrailing) {
            Button(action: action) {
                Text(InternationalizationService().localizedString(for: "SixLayerFramework.button.done"))
            }
            .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    /// Settings shown in their own window.
    /// Applying this modifier does not close the window.
    /// The close control runs `onClose`; the zero-argument form closes the macOS key window.
    @MainActor
    func platformDismissWindowSettings() -> some View {
        platformDismissWindowSettings(onClose: PlatformWindowSettingsDismissal.closeKeyWindow)
    }

    /// Settings shown in their own window.
    /// Applying this modifier does not run `onClose`.
    /// On macOS, the close control runs `onClose` when activated.
    @MainActor
    @ViewBuilder
    func platformDismissWindowSettings(
        onClose: @escaping @MainActor () -> Void
    ) -> some View {
        #if os(macOS)
        self.overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Text(InternationalizationService().localizedString(for: "SixLayerFramework.button.done"))
            }
            .accessibilityIdentifier("platformDismissWindowSettings.close")
        }
        #else
        self
        #endif
    }
}

/// Default window-settings dismiss: close the key window when the caller asks.
enum PlatformWindowSettingsDismissal {
    @MainActor
    static func closeKeyWindow() {
        #if os(macOS)
        NSApplication.shared.keyWindow?.performClose(nil)
        #endif
    }
}
