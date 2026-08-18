@testable import SixLayerFramework

/// Expected `platformCameraInterface_L4` subject-type token on **this host**.
/// iOS/macOS wrap `CameraView` / `MacCameraView`; other platforms return
/// `Text` + `automaticCompliance` (no camera).
enum Layer4CameraInterfaceTestSupport {
    static var expectedRootViewName: String {
        switch SixLayerPlatform.current {
        case .iOS:
            return "CameraView"
        case .macOS:
            return "MacCameraView"
        case .tvOS, .watchOS, .visionOS:
            return "Text"
        }
    }
}
