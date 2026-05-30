import SwiftUI
#if os(iOS) || os(macOS)
import AVFoundation
#endif

#if os(iOS) && canImport(PhotosUI)
import PhotosUI
#endif

// MARK: - Camera Authorization State

/// Why the camera interface is or isn’t using the camera.
/// Lets the app show different UI (e.g. “Enable in Settings” when denied vs first-time prompt).
public enum CameraAuthorizationState: Sendable {
    /// Camera is available and authorized; picker will use camera.
    case authorized
    /// Permission not requested yet (first time); picker will use camera and system will prompt.
    case notDetermined
    /// User denied camera access; picker falls back to photo library.
    case denied
    /// Camera restricted by device policy (e.g. parental controls); picker falls back to photo library.
    case restricted
    /// No camera hardware (e.g. Simulator); picker falls back to photo library.
    case unavailable
}

/// Layer 4: Component - Platform Photo Components
///
/// This layer provides platform-aware UI components specifically designed for displaying and interacting with photos.
/// It encapsulates the logic for rendering images, handling gestures (e.g., zoom, pan), and integrating
/// with platform-native photo libraries and image pickers.
///
/// The tests for this component need to be improved to verify:
/// - Correct display of images across different platforms and aspect ratios.
/// - Responsive handling of user gestures for image manipulation.
/// - Seamless integration with platform photo services.
/// - Accessibility features for image content and interactions.
public enum PlatformPhotoComponentsLayer4 {
    
    // MARK: - Camera Interface Components
    
    /// Creates a platform-specific camera interface.
    /// - Parameters:
    ///   - onImageCaptured: Called when the user captures or selects an image.
    ///   - onCameraAuthorizationState: Optional. Called with why camera is or isn’t used (e.g. `.denied` → show “Open Settings”).
    /// Note: Requires @MainActor because CameraView uses @State
    @ViewBuilder
    @MainActor
    public static func platformCameraInterface_L4(
        onImageCaptured: @escaping (PlatformImage) -> Void,
        onCameraAuthorizationState: ((CameraAuthorizationState) -> Void)? = nil
    ) -> some View {
        #if os(iOS)
        CameraView(onImageCaptured: onImageCaptured, onCameraAuthorizationState: onCameraAuthorizationState)
            .automaticCompliance(named: "platformCameraInterface_L4")
            .accessibilityIdentifier("platformCameraInterface_L4")
        #elseif os(macOS)
        MacCameraView(onImageCaptured: onImageCaptured)
            .automaticCompliance(named: "platformCameraInterface_L4")
        #else
        let i18n = InternationalizationService()
        Text(i18n.localizedString(for: "SixLayerFramework.camera.notAvailable"))
            .automaticCompliance(named: "platformCameraInterface_L4")
        #endif
    }
    
    // MARK: - Photo Picker Components
    
    /// Creates a unified cross-platform photo picker
    /// Uses the same API on both iOS and macOS, returning PlatformImage consistently
    /// Note: Requires @MainActor because UnifiedImagePicker is a View
    @ViewBuilder
    @MainActor
    public static func platformPhotoPicker_L4(onImageSelected: @escaping (PlatformImage) -> Void) -> some View {
        UnifiedImagePicker(onImageSelected: onImageSelected)
            .automaticCompliance(named: "platformPhotoPicker_L4")
            .accessibilityIdentifier("platformPhotoPicker_L4")
    }
    
    // MARK: - Photo Display Components
    
    /// Creates a platform-specific photo display
    /// Note: Requires @MainActor because PhotoDisplayView is a View
    @ViewBuilder
    @MainActor
    public static func platformPhotoDisplay_L4(
        image: PlatformImage?,
        style: PhotoDisplayStyle,
        onCaptureRequested: (() -> Void)? = nil
    ) -> some View {
        Group {
            if let image = image {
                PhotoDisplayView(image: image, style: style, onCaptureRequested: onCaptureRequested)
            } else {
                PlaceholderPhotoView(style: style, onCaptureRequested: onCaptureRequested)
            }
        }
        .accessibilityElement(children: .ignore)
        .automaticCompliance(named: "platformPhotoDisplay_L4")
        .accessibilityIdentifier("platformPhotoDisplay_L4")
    }
    
    // MARK: - Camera Preview Components
    
    #if os(iOS) || os(macOS)
    /// Creates a cross-platform camera preview view
    /// Abstracts UIViewControllerRepresentable (iOS) and NSViewRepresentable (macOS)
    /// Note: Requires @MainActor because PlatformCameraPreviewView is a View
    #if !os(watchOS)
    @ViewBuilder
    @MainActor
    public static func platformCameraPreview_L4(session: AVCaptureSession, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> some View {
        PlatformCameraPreviewView(session: session, videoGravity: videoGravity)
            .automaticCompliance(named: "platformCameraPreview_L4")
    }
    #endif
    #endif

    // MARK: - Tabbed Photo Source Components
    
    /// Creates a tabbed interface for switching between camera and photo library
    /// Provides a tab bar at the top to switch between camera and library options.
    /// When both sources are available, the selector is always present so the user can switch from either view (Issue #190).
    /// - Parameter initialSource: Which tab to show first (.camera, .photoLibrary, or .both → camera). Default nil uses .camera.
    /// Note: Requires @MainActor because it creates Views
    @ViewBuilder
    @MainActor
    public static func platformPhotoSourceTabbed_L4(
        initialSource: PhotoSource = .camera,
        onImageCaptured: @escaping (PlatformImage) -> Void,
        onImageSelected: @escaping (PlatformImage) -> Void
    ) -> some View {
        PhotoSourceTabbedView(
            initialSource: initialSource,
            onImageCaptured: onImageCaptured,
            onImageSelected: onImageSelected
        )
        .automaticCompliance(named: "platformPhotoSourceTabbed_L4")
    }

    // MARK: - Live data scanner (VisionKit, Issue #252)

    /// Inner content for the VisionKit live scanner; host may wrap in its own navigation or presentation.
    /// Uses ``RuntimeCapabilityDetection/Photos/supportsLiveDataScanner`` (#253) for gating.
    @ViewBuilder
    @MainActor
    public static func platformDataScannerContent_L4(
        configuration: PlatformDataScannerConfiguration,
        bannerMessage: String,
        sessionController: PlatformDataScannerSessionController? = nil,
        onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
        onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onBecameUnavailable: ((Error) -> Void)? = nil
    ) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            PlatformDataScannerLiveSwiftUIView(
                configuration: configuration,
                bannerMessage: bannerMessage,
                sessionController: sessionController,
                onItemTap: onItemTap,
                onItemsAdded: onItemsAdded,
                onItemsUpdated: onItemsUpdated,
                onItemsRemoved: onItemsRemoved,
                onBecameUnavailable: onBecameUnavailable
            )
            .automaticCompliance(named: "platformDataScannerContent_L4")
        } else {
            let i18n = InternationalizationService()
            Text(i18n.localizedString(for: "SixLayerFramework.camera.notAvailable"))
                .automaticCompliance(named: "platformDataScannerContent_L4")
        }
        #else
        let i18n = InternationalizationService()
        Text(i18n.localizedString(for: "SixLayerFramework.camera.notAvailable"))
            .automaticCompliance(named: "platformDataScannerContent_L4")
        #endif
    }

    /// Presents the live data scanner in a sheet or full-screen cover per `configuration.presentationStyle`.
    @ViewBuilder
    @MainActor
    public static func platformDataScannerInterface_L4(
        isPresented: Binding<Bool>,
        configuration: PlatformDataScannerConfiguration,
        bannerMessage: String,
        sessionController: PlatformDataScannerSessionController? = nil,
        showsDismissControl: Bool = true,
        onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
        onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onBecameUnavailable: ((Error) -> Void)? = nil
    ) -> some View {
        let scannerCore = platformDataScannerContent_L4(
            configuration: configuration,
            bannerMessage: bannerMessage,
            sessionController: sessionController,
            onItemTap: onItemTap,
            onItemsAdded: onItemsAdded,
            onItemsUpdated: onItemsUpdated,
            onItemsRemoved: onItemsRemoved,
            onBecameUnavailable: onBecameUnavailable
        )
        let presentedStack = Group {
            if showsDismissControl {
                NavigationStack {
                    scannerCore
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(InternationalizationService().localizedString(for: "SixLayerFramework.button.cancel")) {
                                    isPresented.wrappedValue = false
                                }
                            }
                        }
                }
            } else {
                scannerCore
            }
        }
        Group {
            switch configuration.presentationStyle {
            case PlatformDataScannerPresentationStyle.sheet:
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                    .sheet(isPresented: isPresented) {
                        presentedStack
                    }
            case PlatformDataScannerPresentationStyle.fullScreenCover:
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                    #if os(iOS)
                    .fullScreenCover(isPresented: isPresented) {
                        presentedStack
                    }
                    #else
                    // `fullScreenCover` is unavailable on macOS; sheet preserves a working presentation surface.
                    .sheet(isPresented: isPresented) {
                        presentedStack
                    }
                    #endif
            }
        }
        .automaticCompliance(named: "platformDataScannerInterface_L4")
    }

    /// Presents the scanner in a **sheet** (forces `presentationStyle` to ``PlatformDataScannerPresentationStyle/sheet``).
    @MainActor
    public static func platformDataScannerInterface_L4AsSheet(
        isPresented: Binding<Bool>,
        configuration: PlatformDataScannerConfiguration,
        bannerMessage: String,
        sessionController: PlatformDataScannerSessionController? = nil,
        showsDismissControl: Bool = true,
        onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
        onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onBecameUnavailable: ((Error) -> Void)? = nil
    ) -> some View {
        var sheetConfiguration = configuration
        sheetConfiguration.presentationStyle = PlatformDataScannerPresentationStyle.sheet
        return platformDataScannerInterface_L4(
            isPresented: isPresented,
            configuration: sheetConfiguration,
            bannerMessage: bannerMessage,
            sessionController: sessionController,
            showsDismissControl: showsDismissControl,
            onItemTap: onItemTap,
            onItemsAdded: onItemsAdded,
            onItemsUpdated: onItemsUpdated,
            onItemsRemoved: onItemsRemoved,
            onBecameUnavailable: onBecameUnavailable
        )
    }

    /// Presents the scanner in a **full-screen cover** (forces `presentationStyle` to ``PlatformDataScannerPresentationStyle/fullScreenCover``).
    @MainActor
    public static func platformDataScannerInterface_L4AsFullScreenCover(
        isPresented: Binding<Bool>,
        configuration: PlatformDataScannerConfiguration,
        bannerMessage: String,
        sessionController: PlatformDataScannerSessionController? = nil,
        showsDismissControl: Bool = true,
        onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
        onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
        onBecameUnavailable: ((Error) -> Void)? = nil
    ) -> some View {
        var fullScreenConfiguration = configuration
        fullScreenConfiguration.presentationStyle = PlatformDataScannerPresentationStyle.fullScreenCover
        return platformDataScannerInterface_L4(
            isPresented: isPresented,
            configuration: fullScreenConfiguration,
            bannerMessage: bannerMessage,
            sessionController: sessionController,
            showsDismissControl: showsDismissControl,
            onItemTap: onItemTap,
            onItemsAdded: onItemsAdded,
            onItemsUpdated: onItemsUpdated,
            onItemsRemoved: onItemsRemoved,
            onBecameUnavailable: onBecameUnavailable
        )
    }
}

// MARK: - Camera Preview View

#if os(iOS) || os(macOS)
/// Cross-platform camera preview view
/// Abstracts UIViewControllerRepresentable (iOS) and NSViewRepresentable (macOS)
#if !os(watchOS)
public struct PlatformCameraPreviewView: View {
    let session: AVCaptureSession
    let videoGravity: AVLayerVideoGravity
    
    public init(
        session: AVCaptureSession,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill
    ) {
        self.session = session
        self.videoGravity = videoGravity
    }
    
    public var body: some View {
        #if os(iOS)
        CameraPreviewViewController(session: session, videoGravity: videoGravity)
        #elseif os(macOS)
        CameraPreviewNSView(session: session, videoGravity: videoGravity)
        #else
        let i18n = InternationalizationService()
        Text(i18n.localizedString(for: "SixLayerFramework.camera.previewNotAvailable"))
        #endif
    }
}
#endif
#endif

// MARK: - Supporting Views

#if os(iOS)
import UIKit

/// Hosted-tree contract for `platformCameraInterface_L4` (#254 / #255). SwiftUI modifiers on
/// `UIViewControllerRepresentable` do not reliably propagate into the embedded picker hierarchy.
private enum PlatformCameraInterfaceLayer4Accessibility {
    static let hostedTreeIdentifier = "SixLayer.main.ui.platformCameraInterface_L4.View"
    static let anchorViewTag = 0x534C4604
}

@MainActor
private func applyPlatformCameraInterfaceLayer4Accessibility(to picker: UIImagePickerController) {
    picker.view.accessibilityIdentifier = PlatformCameraInterfaceLayer4Accessibility.hostedTreeIdentifier
    let tag = PlatformCameraInterfaceLayer4Accessibility.anchorViewTag
    if let anchor = picker.view.viewWithTag(tag) {
        anchor.accessibilityIdentifier = PlatformCameraInterfaceLayer4Accessibility.hostedTreeIdentifier
        return
    }
    let anchor = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    anchor.tag = tag
    anchor.isUserInteractionEnabled = false
    anchor.isAccessibilityElement = true
    anchor.accessibilityIdentifier = PlatformCameraInterfaceLayer4Accessibility.hostedTreeIdentifier
    anchor.accessibilityLabel = "platformCameraInterface_L4"
    anchor.accessibilityTraits = [.button]
    anchor.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    picker.view.addSubview(anchor)
}

public struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (PlatformImage) -> Void
    let onCameraAuthorizationState: ((CameraAuthorizationState) -> Void)?
    
    public init(
        onImageCaptured: @escaping (PlatformImage) -> Void,
        onCameraAuthorizationState: ((CameraAuthorizationState) -> Void)? = nil
    ) {
        self.onImageCaptured = onImageCaptured
        self.onCameraAuthorizationState = onCameraAuthorizationState
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Issue #179: Simulator and some devices have no camera; setting .camera throws.
        // When user has denied camera permission, use photo library to avoid black screen.
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let state: CameraAuthorizationState = {
            if !cameraAvailable { return .unavailable }
            switch authStatus {
            case .authorized: return .authorized
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            case .restricted: return .restricted
            @unknown default: return .denied
            }
        }()
        onCameraAuthorizationState?(state)
        let useCamera = cameraAvailable && (authStatus == .authorized || authStatus == .notDetermined)
        if useCamera {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        applyPlatformCameraInterfaceLayer4Accessibility(to: picker)
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        applyPlatformCameraInterfaceLayer4Accessibility(to: uiViewController)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            #if DEBUG
            if ProcessInfo.processInfo.environment["SLF_DEBUG_PHOTO_CAPTURE"] != nil {
                print("[SLF CameraView] didFinishPickingMediaWithInfo (Use Photo)")
            }
            #endif
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(PlatformImage(image))  // Implicit conversion: UIImage → PlatformImage
            }
            picker.dismiss(animated: true)
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            #if DEBUG
            if ProcessInfo.processInfo.environment["SLF_DEBUG_PHOTO_CAPTURE"] != nil {
                print("[SLF CameraView] imagePickerControllerDidCancel (Cancel or system dismissed picker)")
            }
            #endif
            picker.dismiss(animated: true)
        }
    }
}

/// iOS implementation of camera preview using UIViewControllerRepresentable
private struct CameraPreviewViewController: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let videoGravity: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> CameraPreviewUIViewController {
        let controller = CameraPreviewUIViewController()
        controller.session = session
        controller.videoGravity = videoGravity
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewUIViewController, context: Context) {
        uiViewController.session = session
        uiViewController.videoGravity = videoGravity
    }
}

/// iOS view controller that hosts AVCaptureVideoPreviewLayer
private class CameraPreviewUIViewController: UIViewController {
    var session: AVCaptureSession? {
        didSet {
            previewLayer?.session = session
        }
    }
    
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            previewLayer?.videoGravity = videoGravity
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer = AVCaptureVideoPreviewLayer(session: session ?? AVCaptureSession())
        layer.videoGravity = videoGravity
        view.layer.addSublayer(layer)
        previewLayer = layer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

public struct PhotoPickerView: View {
    let onImageSelected: (PlatformImage) -> Void
    
    public var body: some View {
        Group {
            if #available(iOS 14.0, *) {
                ModernPhotoPickerView(onImageSelected: onImageSelected)
            } else {
                LegacyPhotoPickerView(onImageSelected: onImageSelected)
            }
        }
        .automaticCompliance(named: "PhotoPickerView")
    }
}

// MARK: - Modern PHPickerViewController Implementation (iOS 14+)

@available(iOS 14.0, *)
private struct ModernPhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> ModernPhotoCoordinator {
        ModernPhotoCoordinator(self)
    }
    
    class ModernPhotoCoordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ModernPhotoPickerView
        
        init(_ parent: ModernPhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                return
            }
            
            // Load the image from the result
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    // Capture the UIImage before crossing concurrency boundary
                    guard let uiImage = object as? UIImage else {
                        return
                    }
                    Task { @MainActor in
                        guard let self = self else {
                            return
                        }
                        // System boundary conversion: UIImage → PlatformImage
                        let platformImage = PlatformImage(uiImage)
                        self.parent.onImageSelected(platformImage)
                    }
                }
            }
        }
    }
}

// MARK: - Legacy UIImagePickerController Implementation (iOS 13)

struct LegacyPhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> LegacyPhotoCoordinator {
        LegacyPhotoCoordinator(self)
    }
    
    class LegacyPhotoCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyPhotoPickerView
        
        init(_ parent: LegacyPhotoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageSelected(PlatformImage(image))  // Implicit conversion: UIImage → PlatformImage
            }
            picker.dismiss(animated: true)
        }
    }
}

#elseif os(macOS)
import AppKit

public struct MacCameraView: NSViewControllerRepresentable {
    let onImageCaptured: (PlatformImage) -> Void
    
    public func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        let button = NSButton(title: "Take Photo", target: context.coordinator, action: #selector(Coordinator.takePhoto))
        controller.view = button
        return controller
    }
    
    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject {
        let parent: MacCameraView
        
        init(_ parent: MacCameraView) {
            self.parent = parent
        }
        
        @MainActor
        @objc func takePhoto() {
            // Stub implementation - would integrate with macOS camera APIs
            let image = PlatformImage.createPlaceholder()
            parent.onImageCaptured(image)
        }
    }
}

public struct MacPhotoPickerView: NSViewControllerRepresentable {
    let onImageSelected: (PlatformImage) -> Void
    
    public func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        let i18n = InternationalizationService()
        let button = NSButton(title: i18n.localizedString(for: "SixLayerFramework.button.choosePhoto"), target: context.coordinator, action: #selector(Coordinator.choosePhoto))
        controller.view = button
        return controller
    }
    
    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, @unchecked Sendable {
        let parent: MacPhotoPickerView
        
        init(_ parent: MacPhotoPickerView) {
            self.parent = parent
        }
        
        @MainActor
        @objc func choosePhoto() {
            // Stub implementation - would integrate with macOS photo picker APIs
            let image = PlatformImage.createPlaceholder()
            parent.onImageSelected(image)
        }
    }
}

/// macOS implementation of camera preview using NSViewRepresentable
private struct CameraPreviewNSView: NSViewRepresentable {
    let session: AVCaptureSession
    let videoGravity: AVLayerVideoGravity
    
    func makeNSView(context: Context) -> CameraPreviewNSViewWrapper {
        let wrapper = CameraPreviewNSViewWrapper()
        wrapper.session = session
        wrapper.videoGravity = videoGravity
        return wrapper
    }
    
    func updateNSView(_ nsView: CameraPreviewNSViewWrapper, context: Context) {
        nsView.session = session
        nsView.videoGravity = videoGravity
    }
}

/// macOS view that hosts AVCaptureVideoPreviewLayer
private class CameraPreviewNSViewWrapper: NSView {
    var session: AVCaptureSession? {
        didSet {
            previewLayer?.session = session
        }
    }
    
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            previewLayer?.videoGravity = videoGravity
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        wantsLayer = true
        
        guard let layer = self.layer else { return }
        
        let preview = AVCaptureVideoPreviewLayer(session: session ?? AVCaptureSession())
        preview.videoGravity = videoGravity
        layer.addSublayer(preview)
        previewLayer = preview
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
}
#endif

// MARK: - Photo Display Views

struct PhotoDisplayView: View {
    let image: PlatformImage
    let style: PhotoDisplayStyle
    let onCaptureRequested: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toggle button at the top if callback is provided
            if let onCaptureRequested = onCaptureRequested {
                HStack {
                    Spacer()
                    Button(action: onCaptureRequested) {
                        HStack {
                            Image(systemName: "camera.fill")
                            let i18n = InternationalizationService()
                            Text(i18n.localizedString(for: "SixLayerFramework.photo.captureNew"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 8)
                }
            }
            
            // Image display
            Image(platformImage: image)
                .resizable()
                .aspectRatio(contentMode: aspectRatioForStyle(style))
                .clipShape(clipShapeForStyle(style))
        }
        .automaticCompliance(named: "PhotoDisplayView")
    }
    
    private func aspectRatioForStyle(_ style: PhotoDisplayStyle) -> ContentMode {
        switch style {
        case .aspectFit, .aspectFill:
            return .fit
        case .fullSize, .thumbnail, .rounded:
            return .fill
        }
    }
    
    private func clipShapeForStyle(_ style: PhotoDisplayStyle) -> AnyShape {
        switch style {
        case .rounded:
            return AnyShape(Circle())
        case .aspectFit, .aspectFill, .fullSize, .thumbnail:
            return AnyShape(Rectangle())
        }
    }
}

struct PlaceholderPhotoView: View {
    let style: PhotoDisplayStyle
    let onCaptureRequested: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toggle button at the top if callback is provided
            if let onCaptureRequested = onCaptureRequested {
                HStack {
                    Spacer()
                    Button(action: onCaptureRequested) {
                        HStack {
                            Image(systemName: "camera.fill")
                            let i18n = InternationalizationService()
                            Text(i18n.localizedString(for: "SixLayerFramework.photo.captureNew"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 8)
                }
            }
            
            // Placeholder content
            VStack {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                let i18n = InternationalizationService()
                Text(i18n.localizedString(for: "SixLayerFramework.image.noImage"))
                    .foregroundColor(.secondary)
            }
            .frame(width: sizeForStyle(style).width, height: sizeForStyle(style).height)
            .background(Color.gray.opacity(0.1))
            .clipShape(clipShapeForStyle(style))
        }
        .automaticCompliance(named: "PlaceholderPhotoView")
        .accessibilityIdentifier("platformPhotoDisplay_L4")
    }
    
    private func sizeForStyle(_ style: PhotoDisplayStyle) -> CGSize {
        switch style {
        case .thumbnail:
            return CGSize(width: 100, height: 100)
        case .fullSize:
            return CGSize(width: 300, height: 200)
        case .aspectFit, .aspectFill, .rounded:
            return CGSize(width: 200, height: 200)
        }
    }
    
    private func clipShapeForStyle(_ style: PhotoDisplayStyle) -> AnyShape {
        switch style {
        case .rounded:
            return AnyShape(Circle())
        case .aspectFit, .aspectFill, .fullSize, .thumbnail:
            return AnyShape(Rectangle())
        }
    }
}

// MARK: - Tabbed Photo Source View

/// Tabbed interface for switching between camera and photo library.
/// Selector is always visible so the user can switch from camera to library or library to camera (Issue #190).
struct PhotoSourceTabbedView: View {
    @State private var selectedSource: PhotoSourceTab
    
    let onImageCaptured: (PlatformImage) -> Void
    let onImageSelected: (PlatformImage) -> Void
    
    init(
        initialSource: PhotoSource = .camera,
        onImageCaptured: @escaping (PlatformImage) -> Void,
        onImageSelected: @escaping (PlatformImage) -> Void
    ) {
        let tab: PhotoSourceTab = switch initialSource {
        case .camera, .both: .camera
        case .photoLibrary: .library
        }
        _selectedSource = State(initialValue: tab)
        self.onImageCaptured = onImageCaptured
        self.onImageSelected = onImageSelected
    }
    
    enum PhotoSourceTab: String, CaseIterable {
        case camera = "camera"
        case library = "library"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar at the top
            HStack(spacing: 0) {
                ForEach(PhotoSourceTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedSource = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab == .camera ? "camera.fill" : "photo.on.rectangle")
                                .font(.title3)
                            let i18n = InternationalizationService()
                            Text(tab == .camera ? 
                                 i18n.localizedString(for: "SixLayerFramework.photo.camera") :
                                 i18n.localizedString(for: "SixLayerFramework.photo.library"))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSource == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                        .foregroundColor(selectedSource == tab ? .accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.systemBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.separator),
                alignment: .bottom
            )
            
            // Content area - show selected source
            Group {
                switch selectedSource {
                case .camera:
                    PlatformPhotoComponentsLayer4.platformCameraInterface_L4(onImageCaptured: onImageCaptured)
                case .library:
                    PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageSelected)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .automaticCompliance(named: "PhotoSourceTabbedView")
    }
}

// MARK: - Supporting Types

struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

// MARK: - Convenience Functions (Global)

/// Creates a platform-specific photo picker (convenience wrapper)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@ViewBuilder
@MainActor
public func platformPhotoPicker_L4(onImageSelected: @escaping (PlatformImage) -> Void) -> some View {
    PlatformPhotoComponentsLayer4.platformPhotoPicker_L4(onImageSelected: onImageSelected)
}

/// Creates a platform-specific camera interface (convenience wrapper).
/// - Parameters:
///   - onImageCaptured: Called when the user captures or selects an image.
///   - onCameraAuthorizationState: Optional. Called with why camera is or isn’t used.
@ViewBuilder
@MainActor
public func platformCameraInterface_L4(
    onImageCaptured: @escaping (PlatformImage) -> Void,
    onCameraAuthorizationState: ((CameraAuthorizationState) -> Void)? = nil
) -> some View {
    PlatformPhotoComponentsLayer4.platformCameraInterface_L4(
        onImageCaptured: onImageCaptured,
        onCameraAuthorizationState: onCameraAuthorizationState
    )
}

/// Creates a platform-specific photo display (convenience wrapper)
/// Note: Requires @MainActor because it calls main-actor isolated methods
@ViewBuilder
@MainActor
public func platformPhotoDisplay_L4(image: PlatformImage?, style: PhotoDisplayStyle) -> some View {
    PlatformPhotoComponentsLayer4.platformPhotoDisplay_L4(image: image, style: style)
}

#if os(iOS) || os(macOS)
/// Creates a cross-platform camera preview (convenience wrapper)
/// Note: Requires @MainActor because it calls main-actor isolated methods
#if !os(watchOS)
@ViewBuilder
@MainActor
public func platformCameraPreview_L4(session: AVCaptureSession, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> some View {
    PlatformPhotoComponentsLayer4.platformCameraPreview_L4(session: session, videoGravity: videoGravity)
}
#endif

// MARK: - Live data scanner (Issue #252)

/// Live VisionKit scanner content (convenience wrapper).
@ViewBuilder
@MainActor
public func platformDataScannerContent_L4(
    configuration: PlatformDataScannerConfiguration,
    bannerMessage: String,
    sessionController: PlatformDataScannerSessionController? = nil,
    onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
    onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onBecameUnavailable: ((Error) -> Void)? = nil
) -> some View {
    PlatformPhotoComponentsLayer4.platformDataScannerContent_L4(
        configuration: configuration,
        bannerMessage: bannerMessage,
        sessionController: sessionController,
        onItemTap: onItemTap,
        onItemsAdded: onItemsAdded,
        onItemsUpdated: onItemsUpdated,
        onItemsRemoved: onItemsRemoved,
        onBecameUnavailable: onBecameUnavailable
    )
}

/// Presents the live scanner per `configuration.presentationStyle` (convenience wrapper).
@ViewBuilder
@MainActor
public func platformDataScannerInterface_L4(
    isPresented: Binding<Bool>,
    configuration: PlatformDataScannerConfiguration,
    bannerMessage: String,
    sessionController: PlatformDataScannerSessionController? = nil,
    showsDismissControl: Bool = true,
    onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
    onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onBecameUnavailable: ((Error) -> Void)? = nil
) -> some View {
    PlatformPhotoComponentsLayer4.platformDataScannerInterface_L4(
        isPresented: isPresented,
        configuration: configuration,
        bannerMessage: bannerMessage,
        sessionController: sessionController,
        showsDismissControl: showsDismissControl,
        onItemTap: onItemTap,
        onItemsAdded: onItemsAdded,
        onItemsUpdated: onItemsUpdated,
        onItemsRemoved: onItemsRemoved,
        onBecameUnavailable: onBecameUnavailable
    )
}

/// Presents the live scanner in a sheet (convenience wrapper).
@ViewBuilder
@MainActor
public func platformDataScannerInterface_L4AsSheet(
    isPresented: Binding<Bool>,
    configuration: PlatformDataScannerConfiguration,
    bannerMessage: String,
    sessionController: PlatformDataScannerSessionController? = nil,
    showsDismissControl: Bool = true,
    onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
    onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onBecameUnavailable: ((Error) -> Void)? = nil
) -> some View {
    PlatformPhotoComponentsLayer4.platformDataScannerInterface_L4AsSheet(
        isPresented: isPresented,
        configuration: configuration,
        bannerMessage: bannerMessage,
        sessionController: sessionController,
        showsDismissControl: showsDismissControl,
        onItemTap: onItemTap,
        onItemsAdded: onItemsAdded,
        onItemsUpdated: onItemsUpdated,
        onItemsRemoved: onItemsRemoved,
        onBecameUnavailable: onBecameUnavailable
    )
}

/// Presents the live scanner in a full-screen cover (convenience wrapper).
@ViewBuilder
@MainActor
public func platformDataScannerInterface_L4AsFullScreenCover(
    isPresented: Binding<Bool>,
    configuration: PlatformDataScannerConfiguration,
    bannerMessage: String,
    sessionController: PlatformDataScannerSessionController? = nil,
    showsDismissControl: Bool = true,
    onItemTap: @escaping (PlatformDataScannerRecognizedPayload) -> Void,
    onItemsAdded: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsUpdated: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onItemsRemoved: (([PlatformDataScannerTrackedItem]) -> Void)? = nil,
    onBecameUnavailable: ((Error) -> Void)? = nil
) -> some View {
    PlatformPhotoComponentsLayer4.platformDataScannerInterface_L4AsFullScreenCover(
        isPresented: isPresented,
        configuration: configuration,
        bannerMessage: bannerMessage,
        sessionController: sessionController,
        showsDismissControl: showsDismissControl,
        onItemTap: onItemTap,
        onItemsAdded: onItemsAdded,
        onItemsUpdated: onItemsUpdated,
        onItemsRemoved: onItemsRemoved,
        onBecameUnavailable: onBecameUnavailable
    )
}
#endif
