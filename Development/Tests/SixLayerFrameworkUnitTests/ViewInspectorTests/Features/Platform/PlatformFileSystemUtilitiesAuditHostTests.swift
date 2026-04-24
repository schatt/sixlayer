import Foundation
import Testing
import SwiftUI
@testable import SixLayerFramework

/// RealUI audit host + direct API probes for `PlatformFileSystemUtilities` (Issue #170). Keep <=10 tests.
@Suite("Platform File System Utilities Audit Host")
open class PlatformFileSystemUtilitiesAuditHostTests: BaseTestClass {

    @MainActor
    private func hostedAuditIdentifierSnapshot() -> [String] {
        let hosted = Self.hostRootPlatformView(PlatformFileSystemUtilitiesAuditHost())
        return findAllAccessibilityIdentifiersFromPlatformView(hosted)
    }

    @MainActor
    private func snapshotContainsAny(of needles: [String], in ids: [String]) -> Bool {
        for needle in needles {
            if ids.contains(where: { $0 == needle || $0.hasSuffix(needle) || $0.contains(needle) }) {
                return true
            }
        }
        return false
    }

    @Test @MainActor func testPlatformFileSystemAuditHostRenders() async {
        let root = PlatformFileSystemUtilitiesAuditHost()
        let hosted = Self.hostRootPlatformView(root)
        #expect(hosted != nil)
    }

    @Test @MainActor func testPlatformFileSystemAuditHostSurfacesTitleIdentifier() async {
        let ids = hostedAuditIdentifierSnapshot()
        #expect(snapshotContainsAny(of: ["platform-fs-audit-title"], in: ids))
    }

    @Test @MainActor func testPlatformFileSystemAuditHostSurfacesHomeAndAppSupportIdentifiers() async {
        let ids = hostedAuditIdentifierSnapshot()
        #expect(snapshotContainsAny(of: ["platform-fs-audit-home"], in: ids))
        #expect(snapshotContainsAny(of: ["platform-fs-audit-app-support"], in: ids))
    }

    @Test @MainActor func testPlatformFileSystemAuditHostSurfacesDocumentsCachesTemporaryIdentifiers() async {
        let ids = hostedAuditIdentifierSnapshot()
        #expect(snapshotContainsAny(of: ["platform-fs-audit-documents"], in: ids))
        #expect(snapshotContainsAny(of: ["platform-fs-audit-caches"], in: ids))
        #expect(snapshotContainsAny(of: ["platform-fs-audit-temporary"], in: ids))
    }

    @Test @MainActor func testPlatformFileSystemAuditHostSurfacesContainerProbeIdentifiers() async {
        let ids = hostedAuditIdentifierSnapshot()
        #expect(snapshotContainsAny(of: ["platform-fs-audit-shared-container"], in: ids))
        #expect(snapshotContainsAny(of: ["platform-fs-audit-icloud-container"], in: ids))
    }

    @Test @MainActor func testPlatformFileSystemAuditHostSurfacesDocumentsParityRowIdentifier() async {
        let ids = hostedAuditIdentifierSnapshot()
        #expect(snapshotContainsAny(of: ["platform-fs-audit-documents-parity"], in: ids))
    }

    @Test func testInvalidAppGroupSharedContainerURLIsNil() {
        let url = platformSharedContainerDirectory(
            containerIdentifier: "group.sixlayer.audit.invalid.placeholder",
            createIfNeeded: false
        )
        #expect(url == nil)
    }

    @Test func testInvalidICloudContainerURLIsNil() {
        let url = platformiCloudContainerDirectory(
            containerIdentifier: "iCloud.sixlayer.audit.invalid.placeholder",
            createIfNeeded: false
        )
        #expect(url == nil)
    }
}
