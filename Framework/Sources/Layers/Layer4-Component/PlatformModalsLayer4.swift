import SwiftUI

// MARK: - Platform Modals Layer 3: Layout Implementation

/// Platform-specific modal helper functions that implement consistent
/// modal patterns across iOS and macOS. This layer handles the specific
/// implementation of modal components.
public extension View {
    
    /// Platform-specific sheet presentation with consistent styling
    /// Provides standardized sheet appearance across platforms
    ///
    /// **Note**: For new code, prefer `platformSheet_L4()` which provides
    /// `PlatformPresentationSize` sizing (#384) and better cross-platform documentation.
    /// This function is maintained for backward compatibility (defaults to `[.large]`).
    ///
    /// - SeeAlso: `platformSheet_L4()` for enhanced sheet presentation with size hints
    @MainActor
    func platformSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        // Use platformSheet_L4 internally for consistency
        return self.platformSheet_L4(
            isPresented: isPresented,
            onDismiss: onDismiss,
            sizes: [.large],
            dragIndicator: .automatic,
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
