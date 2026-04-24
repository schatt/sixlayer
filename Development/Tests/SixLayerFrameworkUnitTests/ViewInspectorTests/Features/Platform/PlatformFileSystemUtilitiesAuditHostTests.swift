import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

#if canImport(ViewInspector)
import ViewInspector
#endif

/// RealUI audit host + API probes for `PlatformFileSystemUtilities` (Issue #170). Keep <=10 tests.
@Suite("Platform File System Utilities Audit Host")
open class PlatformFileSystemUtilitiesAuditHostTests: BaseTestClass {

    /// Concatenated `Text` strings from the audit host (ViewInspector); empty if inspection fails.
    @MainActor
    private func auditHostTextJoined() -> String {
        #if canImport(ViewInspector)
        do {
            let root = PlatformFileSystemUtilitiesAuditHost()
            let inspected = try AnyView(root).inspect()
            let texts = inspected.findAll(ViewType.Text.self)
            let parts = try texts.map { try $0.string() }
            return parts.joined(separator: "\n")
        } catch {
            return ""
        }
        #else
        return ""
        #endif
    }

    @Test @MainActor func testPlatformFileSystemAuditHostRenders() async {
        let root = PlatformFileSystemUtilitiesAuditHost()
        let hosted = Self.hostRootPlatformView(root)
        #expect(hosted != nil)
    }

    @Test @MainActor func testPlatformFileSystemAuditHostViewInspectorSurfacesStandardDirectoryRows() async {
        #if canImport(ViewInspector)
        let blob = auditHostTextJoined()
        #expect(!blob.isEmpty, "ViewInspector should read at least one Text row from the audit host")
        #expect(blob.contains("home:"))
        #expect(blob.contains("appSupport:"))
        #expect(blob.contains("documents:"))
        #expect(blob.contains("caches:"))
        #expect(blob.contains("temporary:"))
        #else
        #expect(Bool(true), "ViewInspector not linked for this run")
        #endif
    }

    @Test @MainActor func testPlatformFileSystemAuditHostViewInspectorSurfacesContainerAndParityRows() async {
        #if canImport(ViewInspector)
        let blob = auditHostTextJoined()
        #expect(blob.contains("sharedContainer"))
        #expect(blob.contains("iCloudContainer"))
        let parityOk =
            blob.contains("documents optional path matches throwing")
            || blob.contains("documents optional and throwing both nil")
            || blob.contains("documents optional/throwing availability differs")
            || blob.contains("PATH MISMATCH")
        #expect(parityOk)
        #else
        #expect(Bool(true), "ViewInspector not linked for this run")
        #endif
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
