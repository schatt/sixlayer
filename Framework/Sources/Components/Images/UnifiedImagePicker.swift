//
//  UnifiedImagePicker.swift
//  SixLayerFramework
//
//  Unified cross-platform image picker that provides a single API
//  for both iOS and macOS, returning PlatformImage consistently.
//
//  This is the core unified API - the whole point of our framework.
//
//  Both platforms use Apple's Photos picker, which can hand back a Live
//  Photo's paired movie (#668).
//

import SwiftUI

#if os(iOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
import PhotosUI
#endif

/// Unified cross-platform image picker
/// Provides a single API that works identically on iOS and macOS
/// Always returns PlatformImage (never platform-specific types)
///
/// Uses Apple's Photos picker on iOS and macOS. Take a ``PlatformPhotoSelection``
/// (``init(onSelection:dismissPolicy:)``) to also receive a Live Photo's movie.
///
/// **Presentation:** Default ``SystemImagePickerDismissPolicy/hostManaged`` — this picker does not
/// UIKit-dismiss ancestor presentations. Close SwiftUI sheets/covers via bindings in `onImageSelected`
/// (GitHub #441).
public struct UnifiedImagePicker: View {
    let onSelection: (PlatformPhotoSelection) -> Void
    let includeLivePhotoMotion: Bool
    let dismissPolicy: SystemImagePickerDismissPolicy

    /// Delivers the picked image only.
    public init(
        onImageSelected: @escaping (PlatformImage) -> Void,
        dismissPolicy: SystemImagePickerDismissPolicy = .default
    ) {
        self.onSelection = { onImageSelected($0.image) }
        self.includeLivePhotoMotion = false
        self.dismissPolicy = dismissPolicy
    }

    /// Delivers the picked image plus, for a Live Photo, its paired movie.
    @_disfavoredOverload
    public init(
        onSelection: @escaping (PlatformPhotoSelection) -> Void,
        dismissPolicy: SystemImagePickerDismissPolicy = .default
    ) {
        self.onSelection = onSelection
        self.includeLivePhotoMotion = true
        self.dismissPolicy = dismissPolicy
    }

    public var body: some View {
        Group {
            #if os(iOS)
            PhotosPickerController(
                onSelection: onSelection,
                includeLivePhotoMotion: includeLivePhotoMotion,
                dismissPolicy: dismissPolicy
            )
            #elseif os(macOS)
            MacPhotosPickerButton(onSelection: onSelection, includeLivePhotoMotion: includeLivePhotoMotion)
            #else
            let i18n = InternationalizationService()
            Text(i18n.localizedString(for: "SixLayerFramework.imagePicker.notAvailable"))
            #endif
        }
        .automaticCompliance(named: "UnifiedImagePicker")
    }
}

#if os(iOS) || os(macOS)
/// One image from the Photos picker, in its current format.
func photosPickerConfiguration() -> PHPickerConfiguration {
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 1
    configuration.preferredAssetRepresentationMode = .current
    return configuration
}

/// Loads the first picked item and delivers it on the main actor.
@MainActor
private func deliverFirstResult(
    _ results: [PHPickerResult],
    includeLivePhotoMotion: Bool,
    to onSelection: @escaping (PlatformPhotoSelection) -> Void
) {
    guard let provider = results.first?.itemProvider else { return }
    Task { @MainActor in
        guard let selection = await PhotoPickerSelectionLoader.selection(
            from: provider,
            includeLivePhotoMotion: includeLivePhotoMotion
        ) else { return }
        onSelection(selection)
    }
}
#endif

// MARK: - iOS Implementation

#if os(iOS)
private struct PhotosPickerController: UIViewControllerRepresentable {
    let onSelection: (PlatformPhotoSelection) -> Void
    let includeLivePhotoMotion: Bool
    let dismissPolicy: SystemImagePickerDismissPolicy

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let picker = PHPickerViewController(configuration: photosPickerConfiguration())
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotosPickerController

        init(_ parent: PhotosPickerController) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            applySystemImagePickerDismissPolicy(
                parent.dismissPolicy,
                presentingViewController: picker.presentingViewController,
                dismiss: { picker.dismiss(animated: true) }
            )
            deliverFirstResult(
                results,
                includeLivePhotoMotion: parent.includeLivePhotoMotion,
                to: parent.onSelection
            )
        }
    }
}
#endif

// MARK: - macOS Implementation

#if os(macOS)
/// A button that opens the Photos picker as a sheet.
private struct MacPhotosPickerButton: NSViewControllerRepresentable {
    let onSelection: (PlatformPhotoSelection) -> Void
    let includeLivePhotoMotion: Bool

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        let i18n = InternationalizationService()
        let button = NSButton(
            title: i18n.localizedString(for: "SixLayerFramework.button.chooseImage"),
            target: context.coordinator,
            action: #selector(Coordinator.chooseImage)
        )
        button.bezelStyle = .rounded
        controller.view = button
        context.coordinator.host = controller
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MacPhotosPickerButton
        weak var host: NSViewController?

        init(_ parent: MacPhotosPickerButton) {
            self.parent = parent
        }

        @MainActor
        @objc func chooseImage() {
            let picker = PHPickerViewController(configuration: photosPickerConfiguration())
            picker.delegate = self
            host?.presentAsSheet(picker)
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(nil)
            deliverFirstResult(
                results,
                includeLivePhotoMotion: parent.includeLivePhotoMotion,
                to: parent.onSelection
            )
        }
    }
}
#endif
