//
//  LivePhotoCamera.swift
//  SixLayerFramework
//
//  Live Photo capture for the camera interface (#669). The system camera
//  (`UIImagePickerController`) cannot record Live Photos, so callers that
//  take a ``PlatformPhotoSelection`` get this capture view instead. The
//  system camera stays as the fallback when there is no usable camera.
//

import AVFoundation
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Which camera the camera interface shows.
enum CameraCapturePath: Equatable, Sendable {
    /// The framework's capture view, which records Live Photos when it can.
    case livePhotoCamera
    /// The system camera (`UIImagePickerController`), still only.
    case systemCamera
}

enum LivePhotoCamera {
    /// The capture view only for callers that want motion and a camera that
    /// is, or may become, usable. Everyone else keeps the system camera,
    /// which also handles the photo-library fallback.
    static func capturePath(wantsMotion: Bool, authorization: CameraAuthorizationState) -> CameraCapturePath {
        guard wantsMotion else { return .systemCamera }
        switch authorization {
        case .authorized, .notDetermined:
            return .livePhotoCamera
        case .denied, .restricted, .unavailable:
            return .systemCamera
        }
    }

    #if os(iOS)
    /// Settings for one shot. A Live Photo writes its movie to a new file in
    /// `movieDirectory`, which the caller then owns.
    static func photoSettings(livePhotoSupported: Bool, movieDirectory: URL) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        if livePhotoSupported {
            settings.livePhotoMovieFileURL = movieDirectory
                .appendingPathComponent("LivePhotoMotion-\(UUID().uuidString).mov")
        }
        return settings
    }
    #endif
}

/// Pairs a capture's still and Live Photo movie, which arrive separately
/// and in either order.
struct LivePhotoCaptureAssembly {
    private var image: PlatformImage?
    private var movieURL: URL?

    mutating func receivePhoto(_ image: PlatformImage?) {
        self.image = image
    }

    /// A movie that failed to write is dropped; the still is still delivered.
    mutating func receiveMovie(_ url: URL?, error: (any Error)?) {
        movieURL = error == nil ? url : nil
    }

    /// Nil when the still never arrived.
    func selection() -> PlatformPhotoSelection? {
        guard let image else { return nil }
        return PlatformPhotoSelection(image: image, livePhotoMovieURL: movieURL)
    }
}

/// Holds a finished shot until the user chooses Use Photo or Retake (#669).
struct LivePhotoCaptureConfirmation {
    private var pending: PlatformPhotoSelection?

    // RED STUB (#669): offer stores nothing; usePhoto / retake are no-ops.
    mutating func offer(_ selection: PlatformPhotoSelection) {
        _ = selection
    }

    mutating func usePhoto() -> PlatformPhotoSelection? {
        nil
    }

    mutating func retake(fileManager: FileManager = .default) {
        _ = fileManager
    }
}

#if os(iOS)
/// Camera interface for selection callers: the Live Photo capture view, or
/// the system camera when the capture view cannot run.
struct LivePhotoCameraInterface: View {
    let onSelection: (PlatformPhotoSelection) -> Void
    let onCancel: (() -> Void)?
    let onCameraAuthorizationState: ((CameraAuthorizationState) -> Void)?
    @State private var useSystemCamera = false

    var body: some View {
        let state = resolvedCameraAuthorizationStateForLayer4()
        if !useSystemCamera, LivePhotoCamera.capturePath(wantsMotion: true, authorization: state) == .livePhotoCamera {
            LivePhotoCameraView(
                onSelection: onSelection,
                onCancel: onCancel,
                onUnavailable: { useSystemCamera = true }
            )
            .ignoresSafeArea()
            .onAppear { onCameraAuthorizationState?(state) }
        } else {
            CameraView(
                onImageCaptured: { onSelection(PlatformPhotoSelection(image: $0)) },
                onCameraAuthorizationState: onCameraAuthorizationState,
                onCancel: onCancel
            )
        }
    }
}

private struct LivePhotoCameraView: UIViewControllerRepresentable {
    let onSelection: (PlatformPhotoSelection) -> Void
    let onCancel: (() -> Void)?
    let onUnavailable: () -> Void

    func makeUIViewController(context: Context) -> LivePhotoCameraViewController {
        LivePhotoCameraViewController(onSelection: onSelection, onCancel: onCancel, onUnavailable: onUnavailable)
    }

    func updateUIViewController(_ controller: LivePhotoCameraViewController, context: Context) {}
}

/// Session objects touched only on the session queue.
private final class LivePhotoCaptureSession: @unchecked Sendable {
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    let queue = DispatchQueue(label: "SixLayerFramework.LivePhotoCamera.session")
    private(set) var device: AVCaptureDevice?

    /// False when there is no camera or it cannot be added.
    func configure() -> Bool {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input), session.canAddOutput(output) else {
            return false
        }
        session.addInput(input)
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality
        output.isLivePhotoCaptureEnabled = output.isLivePhotoCaptureSupported
        device = camera
        return true
    }
}

final class LivePhotoCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    private let onSelection: (PlatformPhotoSelection) -> Void
    private let onCancel: (() -> Void)?
    private let onUnavailable: () -> Void
    private let capture = LivePhotoCaptureSession()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private var rotation: AVCaptureDevice.RotationCoordinator?
    private var assemblies: [Int64: LivePhotoCaptureAssembly] = [:]
    private let shutter = UIButton(type: .custom)
    private var didStart = false

    init(
        onSelection: @escaping (PlatformPhotoSelection) -> Void,
        onCancel: (() -> Void)?,
        onUnavailable: @escaping () -> Void
    ) {
        self.onSelection = onSelection
        self.onCancel = onCancel
        self.onUnavailable = onUnavailable
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.accessibilityIdentifier = PlatformCameraInterfaceLayer4Accessibility.hostedTreeIdentifier
        previewLayer.session = capture.session
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        addCancelIfNeeded()
        addShutter()
    }

    /// Starts once, when the view appears: loading the view alone (tests,
    /// previews) must not prompt for camera access.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !didStart else { return }
        didStart = true
        Task { await start() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let capture = capture
        capture.queue.async { capture.session.stopRunning() }
    }

    /// Cancel matches the system camera: only when the host supplies a callback.
    private func addCancelIfNeeded() {
        guard let onCancel else { return }
        let i18n = InternationalizationService()
        let cancel = UIButton(type: .system)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        cancel.setTitle(i18n.localizedString(for: "SixLayerFramework.button.cancel"), for: .normal)
        cancel.setTitleColor(.white, for: .normal)
        cancel.accessibilityLabel = i18n.localizedString(for: "SixLayerFramework.button.cancel")
        cancel.accessibilityIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.cancel"
        // UIAction (not addTarget): sendActions in unit tests must reach the callback.
        cancel.addAction(UIAction { _ in onCancel() }, for: .touchUpInside)
        view.addSubview(cancel)
        NSLayoutConstraint.activate([
            cancel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
    }

    private func addShutter() {
        let i18n = InternationalizationService()
        shutter.translatesAutoresizingMaskIntoConstraints = false
        shutter.backgroundColor = .white
        shutter.layer.cornerRadius = 35
        shutter.layer.borderWidth = 5
        shutter.layer.borderColor = UIColor.lightGray.cgColor
        shutter.isEnabled = false
        shutter.accessibilityLabel = i18n.localizedString(for: "SixLayerFramework.photo.captureNew")
        shutter.accessibilityIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.shutter"
        shutter.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(shutter)
        NSLayoutConstraint.activate([
            shutter.widthAnchor.constraint(equalToConstant: 70),
            shutter.heightAnchor.constraint(equalToConstant: 70),
            shutter.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutter.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func start() async {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                onUnavailable()
                return
            }
        }
        let capture = capture
        let configured = await withCheckedContinuation { continuation in
            capture.queue.async {
                let ok = capture.configure()
                if ok { capture.session.startRunning() }
                continuation.resume(returning: ok)
            }
        }
        guard configured, let device = capture.device else {
            onUnavailable()
            return
        }
        rotation = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        shutter.isEnabled = true
    }

    @objc private func takePhoto() {
        let capture = capture
        let angle = rotation?.videoRotationAngleForHorizonLevelCapture
        let movieDirectory = FileManager.default.temporaryDirectory
        capture.queue.async {
            if let angle, let connection = capture.output.connection(with: .video),
               connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
            let settings = LivePhotoCamera.photoSettings(
                livePhotoSupported: capture.output.isLivePhotoCaptureEnabled,
                movieDirectory: movieDirectory
            )
            capture.output.capturePhoto(with: settings, delegate: self)
        }
    }

    /// RED STUB (#669): review UI is not shown yet.
    func offerReviewForTesting(_ selection: PlatformPhotoSelection) {
        _ = selection
    }

    // MARK: AVCapturePhotoCaptureDelegate (called on a capture queue)

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        let id = photo.resolvedSettings.uniqueID
        let data = photo.fileDataRepresentation()
        // Main queue keeps the callbacks in order; separate Tasks would not.
        DispatchQueue.main.async { MainActor.assumeIsolated {
            // System boundary conversion: photo data → PlatformImage
            self.assemblies[id, default: LivePhotoCaptureAssembly()].receivePhoto(data.flatMap(PlatformImage.init(data:)))
        } }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
        duration: CMTime,
        photoDisplayTime: CMTime,
        resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        let id = resolvedSettings.uniqueID
        let failed = error != nil
        // Main queue keeps the callbacks in order; separate Tasks would not.
        DispatchQueue.main.async { MainActor.assumeIsolated {
            self.assemblies[id, default: LivePhotoCaptureAssembly()]
                .receiveMovie(outputFileURL, error: failed ? CocoaError(.fileWriteUnknown) : nil)
        } }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: (any Error)?
    ) {
        let id = resolvedSettings.uniqueID
        // Main queue keeps the callbacks in order; separate Tasks would not.
        DispatchQueue.main.async { MainActor.assumeIsolated {
            guard let selection = self.assemblies.removeValue(forKey: id)?.selection() else { return }
            self.onSelection(selection)
        } }
    }
}
#endif
