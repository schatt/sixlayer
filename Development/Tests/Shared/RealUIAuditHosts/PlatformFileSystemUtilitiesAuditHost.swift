//
//  PlatformFileSystemUtilitiesAuditHost.swift
//  SixLayerFramework
//
//  Shared RealUI (TestApp) + ViewInspector host for cross-platform directory helpers (Issue #170).
//

import Foundation
import SwiftUI
import SixLayerFramework

/// Surfaces `platform*Directory` utilities in a scrollable audit layout with stable accessibility ids.
struct PlatformFileSystemUtilitiesAuditHost: View {
    var onBackToMain: (() -> Void)?

    var body: some View {
        // Flat `VStack` (no scroll wrapper) so ViewInspector and UIKit a11y traversal reliably
        // reach row `Text` nodes in test hosts (Issue #170).
        VStack(alignment: .leading, spacing: 14) {
            platformText("Platform file system directory utilities")
                .font(.headline)
                .accessibilityIdentifier("platform-fs-audit-title")

            platformText(PlatformFileSystemAuditCopy.homeLine)
                .accessibilityIdentifier("platform-fs-audit-home")

            platformText(PlatformFileSystemAuditCopy.applicationSupportLine)
                .accessibilityIdentifier("platform-fs-audit-app-support")

            platformText(PlatformFileSystemAuditCopy.documentsLine)
                .accessibilityIdentifier("platform-fs-audit-documents")

            platformText(PlatformFileSystemAuditCopy.cachesLine)
                .accessibilityIdentifier("platform-fs-audit-caches")

            platformText(PlatformFileSystemAuditCopy.temporaryLine)
                .accessibilityIdentifier("platform-fs-audit-temporary")

            platformText(PlatformFileSystemAuditCopy.sharedContainerLine)
                .accessibilityIdentifier("platform-fs-audit-shared-container")

            platformText(PlatformFileSystemAuditCopy.iCloudContainerLine)
                .accessibilityIdentifier("platform-fs-audit-icloud-container")

            platformText(PlatformFileSystemAuditCopy.documentsOptionalThrowingParityLine)
                .accessibilityIdentifier("platform-fs-audit-documents-parity")

            platformText(PlatformFileSystemAuditCopy.securityScopedAccessLine)
                .accessibilityIdentifier("platform-fs-audit-security-access")

            platformText(PlatformFileSystemAuditCopy.securityScopedBookmarkSaveLine)
                .accessibilityIdentifier("platform-fs-audit-security-bookmark-save")

            platformText(PlatformFileSystemAuditCopy.securityScopedBookmarkHasLine)
                .accessibilityIdentifier("platform-fs-audit-security-bookmark-has")

            platformText(PlatformFileSystemAuditCopy.securityScopedBookmarkRestoreLine)
                .accessibilityIdentifier("platform-fs-audit-security-bookmark-restore")

            platformText(PlatformFileSystemAuditCopy.securityScopedBookmarkRemoveLine)
                .accessibilityIdentifier("platform-fs-audit-security-bookmark-remove")

            if let onBackToMain {
                platformButton(label: "Back to Main", id: "platform-fs-audit-back-to-main") {
                    onBackToMain()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("File System Utilities")
        .platformNavigationTitleDisplayMode_L4(.inline)
    }
}

private enum PlatformFileSystemAuditCopy {
    private static func existsLine(label: String, url: URL?) -> String {
        guard let url else { return "\(label): nil" }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return "\(label): last=\(url.lastPathComponent) exists=\(exists) dir=\(isDir.boolValue)"
    }

    static var homeLine: String {
        existsLine(label: "home", url: platformHomeDirectory())
    }

    static var applicationSupportLine: String {
        existsLine(label: "appSupport", url: platformApplicationSupportDirectory(createIfNeeded: true))
    }

    static var documentsLine: String {
        existsLine(label: "documents", url: platformDocumentsDirectory(createIfNeeded: true))
    }

    static var cachesLine: String {
        existsLine(label: "caches", url: platformCachesDirectory(createIfNeeded: true))
    }

    static var temporaryLine: String {
        existsLine(label: "temporary", url: platformTemporaryDirectory(createIfNeeded: false))
    }

    /// Deliberately invalid app group — expect nil in TestApp / unit host without that entitlement.
    static var sharedContainerLine: String {
        let id = "group.sixlayer.audit.invalid.placeholder"
        let url = platformSharedContainerDirectory(containerIdentifier: id, createIfNeeded: false)
        if url == nil {
            return "sharedContainer(invalid id): nil"
        }
        return existsLine(label: "sharedContainer", url: url)
    }

    /// Deliberately invalid iCloud container id — expect nil when not configured.
    static var iCloudContainerLine: String {
        let id = "iCloud.sixlayer.audit.invalid.placeholder"
        let url = platformiCloudContainerDirectory(containerIdentifier: id, createIfNeeded: false)
        if url == nil {
            return "iCloudContainer(invalid id): nil"
        }
        return existsLine(label: "iCloudContainer", url: url)
    }

    static var documentsOptionalThrowingParityLine: String {
        let opt = platformDocumentsDirectory(createIfNeeded: true)
        let thrown = try? platformDocumentsDirectoryThrowing(createIfNeeded: true)
        switch (opt, thrown) {
        case let (o?, t?):
            return o.path == t.path
                ? "documents optional path matches throwing"
                : "documents optional vs throwing PATH MISMATCH"
        case (nil, nil):
            return "documents optional and throwing both nil"
        default:
            return "documents optional/throwing availability differs"
        }
    }

    static var securityScopedAccessLine: String {
        guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true) else {
            return "securityScopedAccess: documents unavailable"
        }
        let lastPath = platformSecurityScopedAccess(url: documentsURL) { accessibleURL in
            accessibleURL.lastPathComponent
        }
        return "securityScopedAccess: last=\(lastPath)"
    }

    static var securityScopedBookmarkSaveLine: String {
        guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true) else {
            return "securityBookmark(save): documents unavailable"
        }
        let key = "sixlayer.issue170.audit.securitybookmark"
        let saved = platformSecurityScopedBookmark(url: documentsURL, key: key)
        return "securityBookmark(save): \(saved)"
    }

    static var securityScopedBookmarkHasLine: String {
        let key = "sixlayer.issue170.audit.securitybookmark"
        let has = platformSecurityScopedHasBookmark(key: key)
        return "securityBookmark(has): \(has)"
    }

    static var securityScopedBookmarkRestoreLine: String {
        let key = "sixlayer.issue170.audit.securitybookmark"
        let restored = platformSecurityScopedRestore(key: key)
        return restored != nil
            ? "securityBookmark(restore): restored"
            : "securityBookmark(restore): nil"
    }

    static var securityScopedBookmarkRemoveLine: String {
        let key = "sixlayer.issue170.audit.securitybookmark"
        let removed = platformSecurityScopedRemoveBookmark(key: key)
        return "securityBookmark(remove): \(removed)"
    }
}
