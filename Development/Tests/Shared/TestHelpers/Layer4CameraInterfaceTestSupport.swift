/// Expected `platformCameraInterface_L4` subject-type token on **this host**.
/// Mirrors the compile-time branches in `platformCameraInterface_L4`:
/// iOS/`CameraView`, macOS/`MacCameraView`, else `Text` + `automaticCompliance`.
enum Layer4CameraInterfaceTestSupport {
    static var expectedRootViewName: String {
        #if os(iOS)
        return "CameraView"
        #elseif os(macOS)
        return "MacCameraView"
        #else
        return "Text"
        #endif
    }
}
