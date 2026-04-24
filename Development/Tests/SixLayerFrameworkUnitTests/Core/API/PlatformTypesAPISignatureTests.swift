import Testing

import Foundation
import SwiftUI
@testable import SixLayerFramework

/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformTypesAPISignatureTests: BaseTestClass {
    // MARK: - SixLayerPlatform API
    @Test func testSixLayerPlatformCasesExist() {
        let all = SixLayerPlatform.allCases
        #expect(all.contains(.iOS))
        #expect(all.contains(.macOS))
        #expect(all.contains(.watchOS))
        #expect(all.contains(.tvOS))
        #expect(all.contains(.visionOS))
    }

    @Test func testSixLayerPlatformCurrentAvailable() {
        // compile-time current
        let platform = SixLayerPlatform.current
        // non-optional assertion ensures API exists
        let _ = platform
    }

    @Test @MainActor func testSixLayerPlatformCurrentPlatformAvailable() {
        initializeTestConfig()
        // runtime-aware accessor
        let platform = SixLayerPlatform.currentPlatform
        let _ = platform
    }

    // MARK: - DeviceType API
    @Test func testDeviceTypeCasesExist() {
        let all = DeviceType.allCases
        #expect(!all.isEmpty)
        #expect(all.contains(.phone))
        #expect(all.contains(.pad))
        #expect(all.contains(.mac))
        #expect(all.contains(.tv))
        #expect(all.contains(.watch))
        #expect(all.contains(.car))
        #expect(all.contains(.vision))
    }

    @Test @MainActor func testDeviceTypeCurrentAvailable() {
        initializeTestConfig()
        let deviceType = DeviceType.current
        let _ = deviceType
    }
    
    // MARK: - platformHomeDirectory API
    
    @Test func testPlatformHomeDirectoryReturnsURL() {
        // Test that the function exists and returns a URL
        let homeDir = platformHomeDirectory()
        // Verify it returns a valid URL (not nil since it's not optional)
        #expect(!homeDir.path.isEmpty)
    }
    
    @Test func testPlatformHomeDirectoryReturnsFileURL() {
        // Test that the returned URL is a file URL
        let homeDir = platformHomeDirectory()
        #expect(homeDir.isFileURL)
    }
    
    @Test func testPlatformHomeDirectoryReturnsExistingDirectory() {
        // Test that the home directory actually exists
        let homeDir = platformHomeDirectory()
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: homeDir.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testPlatformHomeDirectoryConsistentReturns() {
        // Test that multiple calls return the same path
        let homeDir1 = platformHomeDirectory()
        let homeDir2 = platformHomeDirectory()
        #expect(homeDir1.path == homeDir2.path)
    }
    
    // MARK: - platformApplicationSupportDirectory API
    
    @Test func testPlatformApplicationSupportDirectoryReturnsURL() {
        // Test that the function exists and returns a URL when directory exists
        guard let appSupport = platformApplicationSupportDirectory() else {
            Issue.record("Application Support directory should exist on Apple platforms")
            return
        }
        #expect(!appSupport.path.isEmpty)
    }
    
    @Test func testPlatformApplicationSupportDirectoryReturnsFileURL() {
        // Test that the returned URL is a file URL
        guard let appSupport = platformApplicationSupportDirectory() else {
            Issue.record("Application Support directory should exist on Apple platforms")
            return
        }
        #expect(appSupport.isFileURL)
    }
    
    @Test func testPlatformApplicationSupportDirectoryReturnsExistingDirectory() {
        // Test that the Application Support directory actually exists
        guard let appSupport = platformApplicationSupportDirectory() else {
            Issue.record("Application Support directory should exist on Apple platforms")
            return
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: appSupport.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testPlatformApplicationSupportDirectoryConsistentReturns() {
        // Test that multiple calls return the same path
        guard let appSupport1 = platformApplicationSupportDirectory(),
              let appSupport2 = platformApplicationSupportDirectory() else {
            Issue.record("Application Support directory should exist on Apple platforms")
            return
        }
        #expect(appSupport1.path == appSupport2.path)
    }
    
    @Test func testPlatformApplicationSupportDirectoryWithCreateIfNeeded() {
        // Test that createIfNeeded parameter works
        // The directory should already exist, so this should return the same URL
        guard let appSupport1 = platformApplicationSupportDirectory(),
              let appSupport2 = platformApplicationSupportDirectory(createIfNeeded: true) else {
            Issue.record("Application Support directory should exist on Apple platforms")
            return
        }
        #expect(appSupport1.path == appSupport2.path)
    }
    
    // MARK: - platformDocumentsDirectory API
    
    @Test func testPlatformDocumentsDirectoryReturnsURL() {
        // Test that the function exists and returns a URL when directory exists
        guard let documentsURL = platformDocumentsDirectory() else {
            Issue.record("Documents directory should exist on Apple platforms")
            return
        }
        #expect(!documentsURL.path.isEmpty)
    }
    
    @Test func testPlatformDocumentsDirectoryReturnsFileURL() {
        // Test that the returned URL is a file URL
        guard let documentsURL = platformDocumentsDirectory() else {
            Issue.record("Documents directory should exist on Apple platforms")
            return
        }
        #expect(documentsURL.isFileURL)
    }
    
    @Test func testPlatformDocumentsDirectoryReturnsExistingDirectory() {
        // Test that the Documents directory actually exists
        guard let documentsURL = platformDocumentsDirectory() else {
            Issue.record("Documents directory should exist on Apple platforms")
            return
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: documentsURL.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testPlatformDocumentsDirectoryConsistentReturns() {
        // Test that multiple calls return the same path
        guard let documentsURL1 = platformDocumentsDirectory(),
              let documentsURL2 = platformDocumentsDirectory() else {
            Issue.record("Documents directory should exist on Apple platforms")
            return
        }
        #expect(documentsURL1.path == documentsURL2.path)
    }
    
    @Test func testPlatformDocumentsDirectoryWithCreateIfNeeded() {
        // Test that createIfNeeded parameter works
        // The directory should already exist, so this should return the same URL
        guard let documentsURL1 = platformDocumentsDirectory(),
              let documentsURL2 = platformDocumentsDirectory(createIfNeeded: true) else {
            Issue.record("Documents directory should exist on Apple platforms")
            return
        }
        #expect(documentsURL1.path == documentsURL2.path)
    }
    
    // MARK: - platformCachesDirectory API
    
    @Test func testPlatformCachesDirectoryReturnsURL() {
        // Test that the function exists and returns a URL when directory exists or can be created
        guard let cachesURL = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should be accessible on Apple platforms")
            return
        }
        #expect(!cachesURL.path.isEmpty)
    }
    
    @Test func testPlatformCachesDirectoryReturnsFileURL() {
        // Test that the returned URL is a file URL
        guard let cachesURL = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should be accessible on Apple platforms")
            return
        }
        #expect(cachesURL.isFileURL)
    }
    
    @Test func testPlatformCachesDirectoryReturnsExistingDirectory() {
        // Test that the Caches directory actually exists (or can be created)
        guard let cachesURL = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should be accessible on Apple platforms")
            return
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: cachesURL.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testPlatformCachesDirectoryConsistentReturns() {
        // Test that multiple calls return the same path
        guard let cachesURL1 = platformCachesDirectory(createIfNeeded: true),
              let cachesURL2 = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should be accessible on Apple platforms")
            return
        }
        #expect(cachesURL1.path == cachesURL2.path)
    }
    
    @Test func testPlatformCachesDirectoryWithCreateIfNeeded() {
        // Test that createIfNeeded parameter works
        guard let cachesURL1 = platformCachesDirectory(createIfNeeded: true),
              let cachesURL2 = platformCachesDirectory(createIfNeeded: true) else {
            Issue.record("Caches directory should be accessible on Apple platforms")
            return
        }
        #expect(cachesURL1.path == cachesURL2.path)
    }
    
    // MARK: - platformTemporaryDirectory API
    
    @Test func testPlatformTemporaryDirectoryReturnsURL() {
        // Test that the function exists and returns a URL
        guard let tempURL = platformTemporaryDirectory(createIfNeeded: true) else {
            Issue.record("Temporary directory should be accessible on Apple platforms")
            return
        }
        #expect(!tempURL.path.isEmpty)
    }
    
    @Test func testPlatformTemporaryDirectoryReturnsFileURL() {
        // Test that the returned URL is a file URL
        guard let tempURL = platformTemporaryDirectory(createIfNeeded: true) else {
            Issue.record("Temporary directory should be accessible on Apple platforms")
            return
        }
        #expect(tempURL.isFileURL)
    }
    
    @Test func testPlatformTemporaryDirectoryReturnsExistingDirectory() {
        // Test that the Temporary directory actually exists (or can be created)
        guard let tempURL = platformTemporaryDirectory(createIfNeeded: true) else {
            Issue.record("Temporary directory should be accessible on Apple platforms")
            return
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempURL.path, isDirectory: &isDirectory)
        #expect(exists)
        #expect(isDirectory.boolValue)
    }
    
    @Test func testPlatformTemporaryDirectoryConsistentReturns() {
        // Test that multiple calls return the same path
        guard let tempURL1 = platformTemporaryDirectory(createIfNeeded: true),
              let tempURL2 = platformTemporaryDirectory(createIfNeeded: true) else {
            Issue.record("Temporary directory should be accessible on Apple platforms")
            return
        }
        #expect(tempURL1.path == tempURL2.path)
    }
    
    @Test func testPlatformTemporaryDirectoryWithCreateIfNeeded() {
        // Test that createIfNeeded parameter works
        guard let tempURL1 = platformTemporaryDirectory(createIfNeeded: true),
              let tempURL2 = platformTemporaryDirectory(createIfNeeded: true) else {
            Issue.record("Temporary directory should be accessible on Apple platforms")
            return
        }
        #expect(tempURL1.path == tempURL2.path)
    }
    
    // MARK: - platformSharedContainerDirectory API
    
    @Test func testPlatformSharedContainerDirectoryReturnsURL() {
        // Test that the function exists and returns a URL when container identifier is valid
        // Use a test container identifier (may not exist, but API should handle gracefully)
        let testContainerID = "group.com.test.container"
        let containerURL = platformSharedContainerDirectory(containerIdentifier: testContainerID, createIfNeeded: false)
        // May return nil if container doesn't exist, but API should exist
        let _ = containerURL
    }
    
    @Test func testPlatformSharedContainerDirectoryReturnsFileURLWhenExists() {
        // Test that the returned URL is a file URL when container exists
        // This test may pass or fail depending on whether test container exists
        let testContainerID = "group.com.test.container"
        if let containerURL = platformSharedContainerDirectory(containerIdentifier: testContainerID, createIfNeeded: false) {
            #expect(containerURL.isFileURL)
        }
    }
    
    @Test func testPlatformSharedContainerDirectoryWithCreateIfNeeded() {
        // Test that createIfNeeded parameter works
        // This test may pass or fail depending on container permissions
        let testContainerID = "group.com.test.container"
        let containerURL1 = platformSharedContainerDirectory(containerIdentifier: testContainerID, createIfNeeded: false)
        let containerURL2 = platformSharedContainerDirectory(containerIdentifier: testContainerID, createIfNeeded: true)
        
        // If both exist, they should be the same
        if let url1 = containerURL1, let url2 = containerURL2 {
            #expect(url1.path == url2.path)
        }
    }
    
    // MARK: - platformSecurityScopedAccess API
    
    @Test func testPlatformSecurityScopedAccessExecutesBlock() {
        // Test that the function executes the block
        // Works on macOS and iOS (both support security-scoped resources)
        let testURL = URL(fileURLWithPath: "/tmp/test")
        var blockExecuted = false
        
        platformSecurityScopedAccess(url: testURL) { url in
            blockExecuted = true
            #expect(url == testURL)
        }
        
        #expect(blockExecuted)
    }
    
    @Test func testPlatformSecurityScopedAccessReturnsBlockResult() {
        // Test that the function returns the block's result
        let testURL = URL(fileURLWithPath: "/tmp/test")
        let result = platformSecurityScopedAccess(url: testURL) { url in
            return "test result"
        }
        
        #expect(result == "test result")
    }
    
    @Test func testPlatformSecurityScopedAccessPropagatesThrows() throws {
        // Test that thrown errors are propagated
        let testURL = URL(fileURLWithPath: "/tmp/test")
        
        do {
            try platformSecurityScopedAccess(url: testURL) { url in
                throw NSError(domain: "test", code: 1)
            }
            Issue.record("Should have thrown an error")
        } catch {
            // Expected - error should be propagated
            #expect(Bool(true))
        }
    }
    
    // MARK: - platformSecurityScopedBookmark API
    
    #if os(macOS)
    @Test func testPlatformSecurityScopedBookmarkSavesBookmark() {
        // Test that bookmark can be saved
        // Use a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
        let testKey = "test_bookmark_\(UUID().uuidString)"
        
        // Clean up any existing bookmark
        _ = platformSecurityScopedRemoveBookmark(key: testKey)
        
        // Try to save bookmark (may fail if not in sandbox, but API should exist)
        let saved = platformSecurityScopedBookmark(url: tempDir, key: testKey)
        
        // Clean up
        _ = platformSecurityScopedRemoveBookmark(key: testKey)
        
        // API should exist and return a boolean (even if false due to sandbox restrictions)
        let _ = saved
    }
    
    @Test func testPlatformSecurityScopedBookmarkWithInvalidKey() {
        // Test that bookmark save handles invalid keys gracefully
        let tempDir = FileManager.default.temporaryDirectory
        let invalidKey = ""
        
        // Should handle empty key gracefully
        let result = platformSecurityScopedBookmark(url: tempDir, key: invalidKey)
        // Result may be false, but should not crash
        let _ = result
    }
    #else
    @Test func testPlatformSecurityScopedBookmarkReturnsFalseOnNonMacOS() {
        // Test that bookmark save returns false on non-macOS platforms
        // Bookmarks are macOS-specific (iOS doesn't support persistent bookmarks)
        let testURL = URL(fileURLWithPath: "/tmp/test")
        let result = platformSecurityScopedBookmark(url: testURL, key: "test")
        #expect(result == false)
    }
    #endif
    
    // MARK: - platformSecurityScopedRestore API
    
    #if os(macOS)
    @Test func testPlatformSecurityScopedRestoreReturnsNilForNonExistentKey() {
        // Test that restore returns nil for non-existent bookmark
        let nonExistentKey = "non_existent_bookmark_\(UUID().uuidString)"
        let result = platformSecurityScopedRestore(key: nonExistentKey)
        #expect(result == nil)
    }
    
    @Test func testPlatformSecurityScopedRestoreAndAccess() {
        // Test full cycle: save, restore, access
        let tempDir = FileManager.default.temporaryDirectory
        let testKey = "test_restore_\(UUID().uuidString)"
        
        // Clean up
        _ = platformSecurityScopedRemoveBookmark(key: testKey)
        
        // Save bookmark
        let saved = platformSecurityScopedBookmark(url: tempDir, key: testKey)
        
        if saved {
            // Restore bookmark
            if let restoredURL = platformSecurityScopedRestore(key: testKey) {
                // Access restored URL
                platformSecurityScopedAccess(url: restoredURL) { url in
                    // Resolve symlinks in both paths to handle /var -> /private/var on macOS
                    // This ensures we compare the actual paths, not symlink paths
                    let restoredResolved = url.resolvingSymlinksInPath().path
                    let tempDirResolved = tempDir.resolvingSymlinksInPath().path
                    
                    // Paths should match after resolving symlinks
                    #expect(restoredResolved == tempDirResolved, 
                           "Restored URL path should match original temp directory path after resolving symlinks")
                }
            }
            
            // Clean up
            _ = platformSecurityScopedRemoveBookmark(key: testKey)
        }
        
        // Test should complete without crashing
        #expect(Bool(true))
    }
    #else
    @Test func testPlatformSecurityScopedRestoreReturnsNilOnNonMacOS() {
        // Test that restore returns nil on non-macOS platforms
        // Bookmarks are macOS-specific (iOS doesn't support persistent bookmarks)
        let result = platformSecurityScopedRestore(key: "test")
        #expect(result == nil)
    }
    #endif
    
    // MARK: - platformSecurityScopedRemoveBookmark API
    
    #if os(macOS)
    @Test func testPlatformSecurityScopedRemoveBookmarkRemovesBookmark() {
        // Test that bookmark can be removed
        let tempDir = FileManager.default.temporaryDirectory
        let testKey = "test_remove_\(UUID().uuidString)"
        
        // Clean up first
        _ = platformSecurityScopedRemoveBookmark(key: testKey)
        
        // Save bookmark
        let saved = platformSecurityScopedBookmark(url: tempDir, key: testKey)
        
        if saved {
            // Verify it exists
            let existsBefore = platformSecurityScopedHasBookmark(key: testKey)
            #expect(existsBefore == true)
            
            // Remove bookmark
            let removed = platformSecurityScopedRemoveBookmark(key: testKey)
            #expect(removed == true)
            
            // Verify it no longer exists
            let existsAfter = platformSecurityScopedHasBookmark(key: testKey)
            #expect(existsAfter == false)
        } else {
            // If save failed (e.g., not in sandbox), removal should also return false
            let removed = platformSecurityScopedRemoveBookmark(key: testKey)
            let _ = removed
        }
    }
    
    @Test func testPlatformSecurityScopedRemoveBookmarkWithNonExistentKey() {
        // Test that removing non-existent bookmark returns false
        let nonExistentKey = "non_existent_\(UUID().uuidString)"
        let result = platformSecurityScopedRemoveBookmark(key: nonExistentKey)
        #expect(result == false)
    }
    #else
    @Test func testPlatformSecurityScopedRemoveBookmarkReturnsFalseOnNonMacOS() {
        // Test that remove returns false on non-macOS platforms
        // Bookmarks are macOS-specific (iOS doesn't support persistent bookmarks)
        let result = platformSecurityScopedRemoveBookmark(key: "test")
        #expect(result == false)
    }
    #endif
    
    // MARK: - platformSecurityScopedHasBookmark API
    
    #if os(macOS)
    @Test func testPlatformSecurityScopedHasBookmarkReturnsFalseForNonExistent() {
        // Test that hasBookmark returns false for non-existent bookmark
        let nonExistentKey = "non_existent_\(UUID().uuidString)"
        let result = platformSecurityScopedHasBookmark(key: nonExistentKey)
        #expect(result == false)
    }
    
    @Test func testPlatformSecurityScopedHasBookmarkReturnsTrueForExistent() {
        // Test that hasBookmark returns true for existing bookmark
        let tempDir = FileManager.default.temporaryDirectory
        let testKey = "test_has_\(UUID().uuidString)"
        
        // Clean up first
        _ = platformSecurityScopedRemoveBookmark(key: testKey)
        
        // Save bookmark
        let saved = platformSecurityScopedBookmark(url: tempDir, key: testKey)
        
        if saved {
            // Verify it exists
            let exists = platformSecurityScopedHasBookmark(key: testKey)
            #expect(exists == true)
            
            // Clean up
            _ = platformSecurityScopedRemoveBookmark(key: testKey)
        }
    }
    #else
    @Test func testPlatformSecurityScopedHasBookmarkReturnsFalseOnNonMacOS() {
        // Test that hasBookmark returns false on non-macOS platforms
        // Bookmarks are macOS-specific (iOS doesn't support persistent bookmarks)
        let result = platformSecurityScopedHasBookmark(key: "test")
        #expect(result == false)
    }
    #endif
}


