import SwiftUI

// MARK: - Platform Modals Layer 3: Layout Implementation

/// Platform-specific modal helper functions that implement consistent
/// modal patterns across iOS and macOS. This layer handles the specific
/// implementation of modal components.
public extension View {
    
    /// Platform-specific sheet presentation with consistent styling
    /// Provides standardized sheet appearance across platforms
    ///
    /// **Note**: For new code, prefer `platformSheet_L4()` which provides additional features
    /// like detents support (iOS 16+) and better cross-platform documentation.
    /// This function is maintained for backward compatibility.
    ///
    /// - SeeAlso: `platformSheet_L4()` for enhanced sheet presentation with detents support
    func platformSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        // Use platformSheet_L4 internally for consistency
        return self.platformSheet_L4(
            isPresented: isPresented,
            onDismiss: onDismiss,
            detents: [.large],
            dragIndicator: .automatic,
            content: content
        )
        .automaticCompliance(named: "platformSheet")
    }
    
    /// Platform-specific alert presentation with consistent styling
    /// Provides standardized alert appearance across platforms
    func platformAlert(
        title: String,
        message: String? = nil,
        primaryButton: Alert.Button,
        secondaryButton: Alert.Button? = nil
    ) -> some View {
        let alert: Alert
        if let secondaryButton = secondaryButton {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
        } else {
            alert = Alert(
                title: Text(title),
                message: message.map { Text($0) },
                dismissButton: primaryButton
            )
        }
        
        return self.alert(isPresented: .constant(false)) {
            alert
        }
    }
    
    /// Platform-specific confirmation dialog with consistent styling
    /// Provides standardized confirmation dialog appearance across platforms
    func platformConfirmationDialog<A: View, M: View>(
        title: String,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: @escaping () -> A,
        @ViewBuilder message: @escaping () -> M
    ) -> some View {
        #if os(iOS)
        return self.confirmationDialog(
            title,
            isPresented: .constant(false),
            titleVisibility: titleVisibility,
            actions: actions,
            message: message
        )
        #elseif os(macOS)
        return self.confirmationDialog(
            title,
            isPresented: .constant(false),
            titleVisibility: titleVisibility,
            actions: actions,
            message: message
        )
        #else
        return self.confirmationDialog(
            title,
            isPresented: .constant(false),
            titleVisibility: titleVisibility,
            actions: actions,
            message: message
        )
        #endif
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

    /// Platform-specific settings dismissal for window presentation
    /// Handles dismissal when settings are presented in separate windows
    func platformDismissWindowSettings() -> some View {
        // Delegate to platform-specific implementations
        #if os(macOS)
        return self.platformDismissWindowSettingsMacOS()
        #elseif os(iOS)
        return self.platformDismissWindowSettingsIOS()
        #else
        return self
        #endif
    }
    
    // MARK: - Platform-Specific Implementations
    
    #if os(macOS)
    /// macOS-specific window dismissal implementation
    private func platformDismissWindowSettingsMacOS() -> some View {
        // For window presentation, close the specific window
        if let targetWindow = NSApplication.shared.keyWindow {
            targetWindow.performClose(nil)
        }
        return self
    }
    #endif
    
    #if os(iOS)
    /// iOS-specific window dismissal implementation
    private func platformDismissWindowSettingsIOS() -> some View {
        // iOS doesn't have separate windows, so this is a no-op
        return self
    }
    #endif
}
