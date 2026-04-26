import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

/// Host rendering + `platform*Directory` API probes (Issue #170). RealUI coverage lives in
/// `PlatformFileSystemUtilitiesAuditHost` / TestApp; ViewInspector does not reliably enumerate
/// `Text` rows under `platformNavigationTitleDisplayMode_L4`, so this suite asserts the same
/// filesystem helpers directly. Keep <=10 tests.
@Suite("Platform File System Utilities Audit Host")
open class PlatformFileSystemUtilitiesAuditHostTests: BaseTestClass {

    @Test @MainActor func testPlatformFileSystemAuditHostRenders() async {
        let root = PlatformFileSystemUtilitiesAuditHost()
        let hosted = Self.hostRootPlatformView(root)
        #expect(hosted != nil)
    }

    @Test func testPlatformHomeDirectoryIsNonemptyFileURL() {
        let home = platformHomeDirectory()
        #expect(home.isFileURL)
        #expect(!home.path.isEmpty)
    }

    @Test func testPlatformTemporaryDirectoryMatchesFileManagerDefault() {
        guard let resolved = platformTemporaryDirectory(createIfNeeded: false) else {
            Issue.record("Temporary directory should resolve")
            return
        }
        #expect(resolved.path == FileManager.default.temporaryDirectory.path)
    }

    @Test func testPlatformDocumentsOptionalPathMatchesThrowing() throws {
        let opt = platformDocumentsDirectory(createIfNeeded: true)
        let thrown = try platformDocumentsDirectoryThrowing(createIfNeeded: true)
        #expect(opt?.path == thrown.path)
    }

    @Test func testPlatformApplicationSupportDirectoryOptionalResolves() {
        guard let url = platformApplicationSupportDirectory(createIfNeeded: true) else {
            Issue.record("Application Support directory should resolve in test host")
            return
        }
        #expect(url.isFileURL)
    }

    @Test func testPlatformCachesDirectoryOptionalResolvesToFileURL() {
        guard let caches = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should resolve in test host")
            return
        }
        #expect(caches.isFileURL)
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: caches.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test func testInvalidICloudContainerURLIsNil() {
        let url = platformiCloudContainerDirectory(
            containerIdentifier: "iCloud.sixlayer.audit.invalid.placeholder",
            createIfNeeded: false
        )
        #expect(url == nil)
    }
}
