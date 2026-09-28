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

    /// Platform-specific settings dismissal for embedded navigation
    /// Handles dismissal when settings are presented as embedded views in navigation
    func platformDismissEmbeddedSettings(
        onClose: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        // For embedded navigation, just trigger the onClose callback
        // This prevents window closing in single-window architecture
        // Note: onAppear removed as it was unused
        #else
        // iOS handles this through navigation state
        #endif
        
        return self
    }

    /// Platform-specific settings dismissal for sheet presentation
    /// Handles dismissal when settings are presented as sheets
    func platformDismissSheetSettings(
        presentationMode: Binding<PresentationMode>
    ) -> some View {
        #if os(macOS)
        // For sheet presentation, dismiss the sheet
        // Note: onAppear removed as it was unused - use direct dismissal instead
        if presentationMode.wrappedValue.isPresented {
            presentationMode.wrappedValue.dismiss()
        }
        #else
        // iOS handles this through presentationMode
        #endif
        
        return self
    }

    /// Platform-specific settings dismissal for window presentation.
    /// `onClose` is the dismiss action. The default closes the macOS key window.
    @MainActor
    func platformDismissWindowSettings(
        onClose: @escaping @MainActor () -> Void = PlatformWindowSettingsDismissal.closeKeyWindow
    ) -> some View {
        #if os(macOS)
        onClose()
        #endif
        return self
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
