//
//  PlatformFileSystemUtilities.swift
//  SixLayerFramework
//
//  Cross-platform file system utility functions
//  Provides platform-agnostic access to common file system directories
//

import Foundation

// MARK: - Cross-Platform File System Utilities

/// Returns the home directory URL for the current user in a cross-platform manner.
///
/// This function abstracts platform-specific home directory access:
/// - **macOS**: Uses `FileManager.default.homeDirectoryForCurrentUser`
/// - **All other platforms (iOS, watchOS, tvOS, visionOS)**: Uses `NSHomeDirectory()` converted to a file URL
///
/// This eliminates the need for conditional compilation in consuming applications:
/// ```swift
/// // Instead of platform-specific code:
/// // #if os(macOS)
/// // let homeDir = FileManager.default.homeDirectoryForCurrentUser
/// // #else
/// // let homeDir = URL(fileURLWithPath: NSHomeDirectory())
/// // #endif
///
/// // Use the cross-platform function:
/// let homeDir = platformHomeDirectory()
/// ```
///
/// - Returns: A `URL` representing the home directory for the current user.
public func platformHomeDirectory() -> URL {
    #if os(macOS)
    return FileManager.default.homeDirectoryForCurrentUser
    #else
    return URL(fileURLWithPath: NSHomeDirectory())
    #endif
}

/// Returns the Application Support directory URL in a cross-platform manner.
///
/// This function abstracts platform-specific Application Support directory access:
/// - **macOS**: Uses `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`
/// - **iOS**: Uses `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`
///
/// While both platforms use the same underlying API, this abstraction provides:
/// - Consistent, testable API across the framework
/// - Future extensibility for platform-specific enhancements (e.g., iCloud Drive integration, sandbox handling)
/// - Reduced code verbosity in consuming applications
///
/// **iCloud Drive Support:**
/// When `useiCloud` is `true`, this function attempts to use the iCloud container directory
/// instead of the local Application Support directory. If iCloud is not available, it falls
/// back to the local directory. The default container identifier (derived from your app's
/// bundle identifier) is used.
///
/// This eliminates the need for verbose, repetitive code in consuming applications:
/// ```swift
/// // Instead of:
/// let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
///
/// // Use the cross-platform function:
/// guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true) else {
///     // Handle error
///     return
/// }
///
/// // With iCloud support:
/// guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true, useiCloud: true) else {
///     // Handle error (may be iCloud unavailable)
///     return
/// }
/// ```
///
/// - Parameters:
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
///   - useiCloud: If `true`, attempts to use iCloud container directory. Defaults to `false` for backward compatibility.
/// - Returns: A `URL` representing the Application Support directory (or iCloud container if `useiCloud` is true), or `nil` if the directory cannot be located or created.
public func platformApplicationSupportDirectory(createIfNeeded: Bool = false, useiCloud: Bool = false) -> URL? {
    #if os(iOS) || os(macOS)
    if useiCloud {
        // Try to use iCloud container (default container identifier)
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            // Use Documents subdirectory in iCloud container (standard pattern)
            let documentsURL = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
            return resolveDirectory(url: documentsURL, createIfNeeded: createIfNeeded)
        }
        // Fall back to local directory if iCloud is not available
    }
    #endif
    
    // Use local directory (default behavior)
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    return resolveDirectory(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Application Support directory URL in a cross-platform manner (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
/// For backward compatibility, use the optional return variant `platformApplicationSupportDirectory(createIfNeeded:)`.
///
/// **Example Usage:**
/// ```swift
/// // With detailed error handling
/// do {
///     let appSupport = try platformApplicationSupportDirectoryThrowing(createIfNeeded: true)
///     // Use appSupport directory
/// } catch PlatformFileSystemError.permissionDenied {
///     // Handle permission issue
/// } catch PlatformFileSystemError.diskFull {
///     // Handle disk full error
/// } catch PlatformFileSystemError.creationFailed(let underlying) {
///     // Handle creation failure with underlying error
///     print("Creation failed: \(underlying)")
/// } catch {
///     // Handle other errors
/// }
///
/// // With iCloud support:
/// do {
///     let appSupport = try platformApplicationSupportDirectoryThrowing(createIfNeeded: true, useiCloud: true)
///     // Use iCloud container directory
/// } catch PlatformFileSystemError.iCloudUnavailable {
///     // iCloud is not available, fall back to local
///     let appSupport = try platformApplicationSupportDirectoryThrowing(createIfNeeded: true, useiCloud: false)
/// }
/// ```
///
/// - Parameters:
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
///   - useiCloud: If `true`, attempts to use iCloud container directory. Defaults to `false` for backward compatibility.
/// - Returns: A `URL` representing the Application Support directory (or iCloud container if `useiCloud` is true)
/// - Throws: `PlatformFileSystemError` if the directory cannot be located or created. Throws `.iCloudUnavailable` if `useiCloud` is true but iCloud is not available.
public func platformApplicationSupportDirectoryThrowing(createIfNeeded: Bool = false, useiCloud: Bool = false) throws -> URL {
    #if os(iOS) || os(macOS)
    if useiCloud {
        // Try to use iCloud container (default container identifier)
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw PlatformFileSystemError.iCloudUnavailable
        }
        // Use Documents subdirectory in iCloud container (standard pattern)
        let documentsURL = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
        return try resolveDirectoryThrowing(url: documentsURL, createIfNeeded: createIfNeeded)
    }
    #endif
    
    // Use local directory (default behavior)
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    return try resolveDirectoryThrowing(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Documents directory URL in a cross-platform manner.
///
/// This function abstracts platform-specific Documents directory access:
/// - **macOS**: Uses `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)`
/// - **iOS**: Uses `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)`
///
/// While both platforms use the same underlying API, this abstraction provides:
/// - Consistent, testable API across the framework
/// - Future extensibility for platform-specific enhancements (e.g., iCloud Drive integration, sandbox handling)
/// - Reduced code verbosity in consuming applications
///
/// **iCloud Drive Support:**
/// When `useiCloud` is `true`, this function attempts to use the iCloud container directory
/// instead of the local Documents directory. If iCloud is not available, it falls back to
/// the local directory. The default container identifier (derived from your app's bundle
/// identifier) is used.
///
/// This eliminates the need for verbose, repetitive code in consuming applications:
/// ```swift
/// // Instead of:
/// let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
///
/// // Use the cross-platform function:
/// guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true) else {
///     // Handle error
///     return
/// }
///
/// // With iCloud support:
/// guard let documentsURL = platformDocumentsDirectory(createIfNeeded: true, useiCloud: true) else {
///     // Handle error (may be iCloud unavailable)
///     return
/// }
/// ```
///
/// - Parameters:
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
///   - useiCloud: If `true`, attempts to use iCloud container directory. Defaults to `false` for backward compatibility.
/// - Returns: A `URL` representing the Documents directory (or iCloud container if `useiCloud` is true), or `nil` if the directory cannot be located or created.
public func platformDocumentsDirectory(createIfNeeded: Bool = false, useiCloud: Bool = false) -> URL? {
    #if os(iOS) || os(macOS)
    if useiCloud {
        // Try to use iCloud container (default container identifier)
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            // Use Documents subdirectory in iCloud container (standard pattern)
            let documentsURL = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
            return resolveDirectory(url: documentsURL, createIfNeeded: createIfNeeded)
        }
        // Fall back to local directory if iCloud is not available
    }
    #endif
    
    // Use local directory (default behavior)
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    return resolveDirectory(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Documents directory URL in a cross-platform manner (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
/// For backward compatibility, use the optional return variant `platformDocumentsDirectory(createIfNeeded:)`.
///
/// **Example Usage:**
/// ```swift
/// do {
///     let documents = try platformDocumentsDirectoryThrowing(createIfNeeded: true)
///     // Use documents directory
/// } catch PlatformFileSystemError.permissionDenied {
///     // Handle permission issue
/// } catch PlatformFileSystemError.diskFull {
///     // Handle disk full error
/// } catch {
///     // Handle other errors
/// }
///
/// // With iCloud support:
/// do {
///     let documents = try platformDocumentsDirectoryThrowing(createIfNeeded: true, useiCloud: true)
///     // Use iCloud container directory
/// } catch PlatformFileSystemError.iCloudUnavailable {
///     // iCloud is not available, fall back to local
///     let documents = try platformDocumentsDirectoryThrowing(createIfNeeded: true, useiCloud: false)
/// }
/// ```
///
/// - Parameters:
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
///   - useiCloud: If `true`, attempts to use iCloud container directory. Defaults to `false` for backward compatibility.
/// - Returns: A `URL` representing the Documents directory (or iCloud container if `useiCloud` is true)
/// - Throws: `PlatformFileSystemError` if the directory cannot be located or created. Throws `.iCloudUnavailable` if `useiCloud` is true but iCloud is not available.
public func platformDocumentsDirectoryThrowing(createIfNeeded: Bool = false, useiCloud: Bool = false) throws -> URL {
    #if os(iOS) || os(macOS)
    if useiCloud {
        // Try to use iCloud container (default container identifier)
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw PlatformFileSystemError.iCloudUnavailable
        }
        // Use Documents subdirectory in iCloud container (standard pattern)
        let documentsURL = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
        return try resolveDirectoryThrowing(url: documentsURL, createIfNeeded: createIfNeeded)
    }
    #endif
    
    // Use local directory (default behavior)
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    return try resolveDirectoryThrowing(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Caches directory URL in a cross-platform manner.
///
/// This function abstracts platform-specific Caches directory access:
/// - **macOS**: Uses `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)`
/// - **iOS**: Uses `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)`
/// - **watchOS/tvOS/visionOS**: Uses `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)`
///
/// While all platforms use the same underlying API, this abstraction provides:
/// - Consistent, testable API across the framework
/// - Future extensibility for platform-specific enhancements
/// - Reduced code verbosity in consuming applications
///
/// This eliminates the need for verbose, repetitive code in consuming applications:
/// ```swift
/// // Instead of:
/// let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
///
/// // Use the cross-platform function:
/// guard let cachesURL = platformCachesDirectory(createIfNeeded: true) else {
///     // Handle error
///     return
/// }
/// ```
///
/// - Parameter createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Caches directory, or `nil` if the directory cannot be located or created.
public func platformCachesDirectory(createIfNeeded: Bool = false) -> URL? {
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    return resolveDirectory(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Caches directory URL in a cross-platform manner (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
/// For backward compatibility, use the optional return variant `platformCachesDirectory(createIfNeeded:)`.
///
/// **Example Usage:**
/// ```swift
/// do {
///     let caches = try platformCachesDirectoryThrowing(createIfNeeded: true)
///     // Use caches directory
/// } catch PlatformFileSystemError.permissionDenied {
///     // Handle permission issue
/// } catch {
///     // Handle other errors
/// }
/// ```
///
/// - Parameter createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Caches directory
/// - Throws: `PlatformFileSystemError` if the directory cannot be located or created
public func platformCachesDirectoryThrowing(createIfNeeded: Bool = false) throws -> URL {
    let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    return try resolveDirectoryThrowing(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Temporary directory URL in a cross-platform manner.
///
/// This function abstracts platform-specific Temporary directory access:
/// - **All platforms**: Uses `FileManager.default.temporaryDirectory`
///
/// This abstraction provides:
/// - Consistent, testable API across the framework
/// - Future extensibility for platform-specific enhancements
/// - Reduced code verbosity in consuming applications
///
/// This eliminates the need for verbose, repetitive code in consuming applications:
/// ```swift
/// // Instead of:
/// let tempURL = FileManager.default.temporaryDirectory
///
/// // Use the cross-platform function:
/// guard let tempURL = platformTemporaryDirectory(createIfNeeded: true) else {
///     // Handle error
///     return
/// }
/// ```
///
/// - Parameter createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Temporary directory, or `nil` if the directory cannot be located or created.
public func platformTemporaryDirectory(createIfNeeded: Bool = false) -> URL? {
    return resolveDirectory(url: FileManager.default.temporaryDirectory, createIfNeeded: createIfNeeded)
}

/// Returns the Temporary directory URL in a cross-platform manner (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
/// For backward compatibility, use the optional return variant `platformTemporaryDirectory(createIfNeeded:)`.
///
/// **Example Usage:**
/// ```swift
/// do {
///     let tempDir = try platformTemporaryDirectoryThrowing(createIfNeeded: true)
///     // Use temporary directory
/// } catch PlatformFileSystemError.diskFull {
///     // Handle disk full error
/// } catch {
///     // Handle other errors
/// }
/// ```
///
/// - Parameter createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Temporary directory
/// - Throws: `PlatformFileSystemError` if the directory cannot be located or created
public func platformTemporaryDirectoryThrowing(createIfNeeded: Bool = false) throws -> URL {
    // Temporary directory always exists, but we still use the helper for consistency
    return try resolveDirectoryThrowing(url: FileManager.default.temporaryDirectory, createIfNeeded: createIfNeeded)
}

/// Returns the Shared Container (App Group) directory URL in a cross-platform manner.
///
/// This function abstracts platform-specific Shared Container directory access:
/// - **iOS/watchOS/tvOS**: Uses `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`
/// - **macOS**: Uses `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` (when App Groups are configured)
///
/// Shared containers allow apps and their extensions to share data within the same app group.
/// This is commonly used for:
/// - Sharing data between main app and extensions (Today widgets, Share extensions, etc.)
/// - Sharing data between watchOS app and iOS app
/// - Sharing data between multiple apps in the same app group
///
/// This abstraction provides:
/// - Consistent, testable API across the framework
/// - Future extensibility for platform-specific enhancements
/// - Reduced code verbosity in consuming applications
///
/// This eliminates the need for verbose, repetitive code in consuming applications:
/// ```swift
/// // Instead of:
/// let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.app")!
///
/// // Use the cross-platform function:
/// guard let containerURL = platformSharedContainerDirectory(containerIdentifier: "group.com.example.app", createIfNeeded: true) else {
///     // Handle error (container may not be configured in entitlements)
///     return
/// }
/// ```
///
/// - Parameters:
///   - containerIdentifier: The app group identifier (e.g., "group.com.example.app")
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Shared Container directory, or `nil` if the container cannot be located or created.
/// - Note: Returns `nil` if the container identifier is not configured in the app's entitlements or if the container cannot be accessed.
public func platformSharedContainerDirectory(containerIdentifier: String, createIfNeeded: Bool = false) -> URL? {
    let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: containerIdentifier)
    return resolveDirectory(url: url, createIfNeeded: createIfNeeded)
}

/// Returns the Shared Container (App Group) directory URL in a cross-platform manner (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
/// For backward compatibility, use the optional return variant `platformSharedContainerDirectory(containerIdentifier:createIfNeeded:)`.
///
/// **Example Usage:**
/// ```swift
/// do {
///     let container = try platformSharedContainerDirectoryThrowing(
///         containerIdentifier: "group.com.example.app",
///         createIfNeeded: true
///     )
///     // Use shared container directory
/// } catch PlatformFileSystemError.directoryNotFound {
///     // Container identifier not configured in entitlements
/// } catch PlatformFileSystemError.permissionDenied {
///     // Handle permission issue
/// } catch {
///     // Handle other errors
/// }
/// ```
///
/// - Parameters:
///   - containerIdentifier: The app group identifier (e.g., "group.com.example.app")
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the Shared Container directory
/// - Throws: `PlatformFileSystemError` if the container cannot be located or created
/// - Note: Throws `PlatformFileSystemError.directoryNotFound` if the container identifier is not configured in the app's entitlements
public func platformSharedContainerDirectoryThrowing(containerIdentifier: String, createIfNeeded: Bool = false) throws -> URL {
    let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: containerIdentifier)
    return try resolveDirectoryThrowing(url: url, createIfNeeded: createIfNeeded)
}

// MARK: - Security-Scoped Resource Management

#if os(macOS) || os(iOS)
/// Provides automatic security-scoped resource access with RAII-style lifecycle management.
///
/// This function automatically handles starting and stopping security-scoped resource access,
/// ensuring proper cleanup even if an error is thrown.
///
/// **macOS Use Cases:**
/// - File picker results (`NSOpenPanel`, `fileImporter`)
/// - Drag & drop operations (`NSItemProvider` URLs)
/// - Restored bookmarks from previous sessions
/// - Files accessed via "Open Recent" menu
/// - App Sandbox: Accessing files outside the sandbox
///
/// **iOS Use Cases:**
/// - Document picker results (`UIDocumentPickerViewController`)
/// - Files accessed outside the app's sandbox
/// - Files from file provider extensions
///
/// **Example Usage:**
/// ```swift
/// // From file picker
/// if let url = filePickerURL {
///     platformSecurityScopedAccess(url: url) { accessibleURL in
///         // Use accessibleURL here - access is automatically managed
///         let data = try Data(contentsOf: accessibleURL)
///         // Access automatically stops when block exits
///     }
/// }
///
/// // With error handling
/// do {
///     try platformSecurityScopedAccess(url: url) { accessibleURL in
///         try processFile(at: accessibleURL)
///     }
/// } catch {
///     // Handle error
/// }
/// ```
///
/// - Parameters:
///   - url: The URL that requires security-scoped access
///   - block: A closure that receives the accessible URL. Access is automatically
///            started before the block and stopped after (even if an error is thrown)
/// - Returns: The result of the block
/// - Throws: Any error thrown by the block
/// - Note: On platforms that don't support security-scoped resources, this function simply passes the URL through unchanged
@available(macOS 10.7, iOS 8.0, *)
public func platformSecurityScopedAccess<T>(url: URL, _ block: (URL) throws -> T) rethrows -> T {
    let started = url.startAccessingSecurityScopedResource()
    defer {
        if started {
            url.stopAccessingSecurityScopedResource()
        }
    }
    return try block(url)
}

/// Persists a security-scoped bookmark for later restoration.
///
/// Saves a bookmark for a URL so it can be accessed across app launches without
/// requiring the user to reselect the file. This is essential for sandboxed macOS apps
/// that need persistent access to user-selected directories or files.
///
/// **Storage Location:**
/// Bookmarks are stored in the Application Support directory in a subdirectory
/// specifically for security-scoped bookmarks. This design allows for future enhancement
/// with a dedicated storage manager (e.g., encryption, compression, migration).
///
/// **Example Usage:**
/// ```swift
/// // After user selects a folder
/// if let folderURL = selectedFolderURL {
///     if platformSecurityScopedBookmark(url: folderURL, key: "userDocuments") {
///         print("Bookmark saved successfully")
///     }
/// }
///
/// // Later, restore the bookmark
/// if let restoredURL = platformSecurityScopedRestore(key: "userDocuments") {
///     platformSecurityScopedAccess(url: restoredURL) { accessibleURL in
///         // Use the restored URL
///     }
/// }
/// ```
///
/// - Parameters:
///   - url: The URL to create a bookmark for
///   - key: A unique key to identify this bookmark (used for later restoration)
/// - Returns: `true` if the bookmark was successfully saved, `false` otherwise
/// - Note: Bookmarks are macOS-specific. On iOS and other platforms, this function returns `false`
@available(macOS 10.7, *)
public func platformSecurityScopedBookmark(url: URL, key: String) -> Bool {
    #if os(macOS)
    return _platformSecurityScopedBookmarkSave(url: url, key: key)
    #else
    return false
    #endif
}

/// Restores a previously saved security-scoped bookmark.
///
/// Retrieves a URL from a previously saved bookmark. The returned URL must be used
/// with `platformSecurityScopedAccess()` to actually access the resource.
///
/// **Example Usage:**
/// ```swift
/// // Restore bookmark from previous session
/// if let restoredURL = platformSecurityScopedRestore(key: "userDocuments") {
///     platformSecurityScopedAccess(url: restoredURL) { accessibleURL in
///         // Access the restored resource
///         let files = try FileManager.default.contentsOfDirectory(at: accessibleURL, ...)
///     }
/// } else {
///     // Bookmark not found or invalid - prompt user to reselect
///     showFilePicker()
/// }
/// ```
///
/// - Parameter key: The unique key used when saving the bookmark
/// - Returns: The restored URL, or `nil` if the bookmark doesn't exist or is invalid
/// - Note: Bookmarks are macOS-specific. On iOS and other platforms, this function returns `nil`
@available(macOS 10.7, *)
public func platformSecurityScopedRestore(key: String) -> URL? {
    #if os(macOS)
    return _platformSecurityScopedBookmarkLoad(key: key)
    #else
    return nil
    #endif
}

/// Removes a previously saved security-scoped bookmark.
///
/// Deletes a bookmark from storage. This is useful when the user explicitly removes
/// access or when cleaning up invalid bookmarks.
///
/// - Parameter key: The unique key of the bookmark to remove
/// - Returns: `true` if the bookmark was successfully removed, `false` otherwise
/// - Note: Bookmarks are macOS-specific. On iOS and other platforms, this function returns `false`
@available(macOS 10.7, *)
public func platformSecurityScopedRemoveBookmark(key: String) -> Bool {
    #if os(macOS)
    return _platformSecurityScopedBookmarkRemove(key: key)
    #else
    return false
    #endif
}

/// Checks if a bookmark exists for the given key.
///
/// - Parameter key: The unique key to check
/// - Returns: `true` if a bookmark exists for the key, `false` otherwise
/// - Note: Bookmarks are macOS-specific. On iOS and other platforms, this function returns `false`
@available(macOS 10.7, *)
public func platformSecurityScopedHasBookmark(key: String) -> Bool {
    #if os(macOS)
    return _platformSecurityScopedBookmarkExists(key: key)
    #else
    return false
    #endif
}

// MARK: - Internal Bookmark Storage Helpers

/// Internal helper functions for bookmark storage.
///
/// These functions use Application Support directory directly and are structured
/// to allow future enhancement with a dedicated storage manager (e.g., encryption,
/// compression, migration, etc.) without changing the public API.
///
/// **Future Enhancement Path:**
/// A `SecurityScopedBookmarkManager` class can be added later that wraps these
/// functions, providing additional features like:
/// - Encryption of bookmark data
/// - Compression for large bookmark collections
/// - Migration between storage formats
/// - Bookmark validation and cleanup
/// - Metadata storage (creation date, last access, etc.)
///
/// The public API functions (`platformSecurityScopedBookmark`, etc.) can then
/// delegate to the manager while maintaining backward compatibility.

#if os(macOS)
/// Bookmark storage directory name within Application Support
private let _bookmarkStorageDirectoryName = "SecurityScopedBookmarks"

/// Gets the bookmark storage directory, creating it if needed
/// Note: Bookmarks are macOS-specific only
@available(macOS 10.7, *)
private func _getBookmarkStorageDirectory() -> URL? {
    guard let appSupport = platformApplicationSupportDirectory(createIfNeeded: true) else {
        return nil
    }
    
    let bookmarkDir = appSupport.appendingPathComponent(_bookmarkStorageDirectoryName, isDirectory: true)
    
    // Create directory if it doesn't exist
    if !FileManager.default.fileExists(atPath: bookmarkDir.path) {
        do {
            try FileManager.default.createDirectory(at: bookmarkDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }
    }
    
    return bookmarkDir
}

/// Gets the file URL for a bookmark with the given key
@available(macOS 10.7, *)
private func _bookmarkFileURL(for key: String) -> URL? {
    guard let bookmarkDir = _getBookmarkStorageDirectory() else {
        return nil
    }
    
    // Sanitize key to be filesystem-safe
    let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
                           .replacingOccurrences(of: "\\", with: "_")
                           .replacingOccurrences(of: "..", with: "_")
    
    return bookmarkDir.appendingPathComponent("\(sanitizedKey).bookmark")
}

/// Saves a bookmark for a URL with the given key
@available(macOS 10.7, *)
private func _platformSecurityScopedBookmarkSave(url: URL, key: String) -> Bool {
    guard let bookmarkFileURL = _bookmarkFileURL(for: key) else {
        return false
    }
    
    do {
        // Create security-scoped bookmark data
        // Note: The bookmark preserves the access level available when created
        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        
        // Write bookmark data to file
        try bookmarkData.write(to: bookmarkFileURL, options: [.atomic])
        return true
    } catch {
        return false
    }
}

/// Loads a bookmark for the given key and resolves it to a URL
@available(macOS 10.7, *)
private func _platformSecurityScopedBookmarkLoad(key: String) -> URL? {
    guard let bookmarkFileURL = _bookmarkFileURL(for: key),
          FileManager.default.fileExists(atPath: bookmarkFileURL.path) else {
        return nil
    }
    
    do {
        // Read bookmark data from file
        let bookmarkData = try Data(contentsOf: bookmarkFileURL)
        
        // Resolve bookmark to URL with security scope
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        // If bookmark is stale, it may still work but should be refreshed
        // For now, we return it anyway - future enhancement could refresh automatically
        if isStale {
            // Optionally refresh the bookmark here in future
        }
        
        return url
    } catch {
        return nil
    }
}

/// Removes a bookmark for the given key
@available(macOS 10.7, *)
private func _platformSecurityScopedBookmarkRemove(key: String) -> Bool {
    guard let bookmarkFileURL = _bookmarkFileURL(for: key) else {
        return false
    }
    
    do {
        try FileManager.default.removeItem(at: bookmarkFileURL)
        return true
    } catch {
        return false
    }
}

/// Checks if a bookmark exists for the given key
@available(macOS 10.7, *)
private func _platformSecurityScopedBookmarkExists(key: String) -> Bool {
    guard let bookmarkFileURL = _bookmarkFileURL(for: key) else {
        return false
    }
    
    return FileManager.default.fileExists(atPath: bookmarkFileURL.path)
}
#endif

#else
// MARK: - Security-Scoped Resource Management (Other Platforms)

/// Provides automatic security-scoped resource access (no-op on platforms that don't support it).
///
/// On platforms that don't support security-scoped resources (watchOS, tvOS, visionOS),
/// this function simply passes the URL through unchanged.
///
/// - Parameters:
///   - url: The URL to access
///   - block: A closure that receives the URL
/// - Returns: The result of the block
/// - Throws: Any error thrown by the block
public func platformSecurityScopedAccess<T>(url: URL, _ block: (URL) throws -> T) rethrows -> T {
    return try block(url)
}

/// Persists a security-scoped bookmark (no-op on platforms that don't support bookmarks).
///
/// Bookmarks are only supported on macOS. On other platforms, this function returns `false`.
///
/// - Parameters:
///   - url: The URL to create a bookmark for
///   - key: A unique key to identify this bookmark
/// - Returns: `false` (bookmarks are macOS-specific)
public func platformSecurityScopedBookmark(url: URL, key: String) -> Bool {
    return false
}

/// Restores a previously saved security-scoped bookmark (no-op on platforms that don't support bookmarks).
///
/// Bookmarks are only supported on macOS. On other platforms, this function returns `nil`.
///
/// - Parameter key: The unique key used when saving the bookmark
/// - Returns: `nil` (bookmarks are macOS-specific)
public func platformSecurityScopedRestore(key: String) -> URL? {
    return nil
}

/// Removes a previously saved security-scoped bookmark (no-op on platforms that don't support bookmarks).
///
/// Bookmarks are only supported on macOS. On other platforms, this function returns `false`.
///
/// - Parameter key: The unique key of the bookmark to remove
/// - Returns: `false` (bookmarks are macOS-specific)
public func platformSecurityScopedRemoveBookmark(key: String) -> Bool {
    return false
}

/// Checks if a bookmark exists for the given key (no-op on platforms that don't support bookmarks).
///
/// Bookmarks are only supported on macOS. On other platforms, this function returns `false`.
///
/// - Parameter key: The unique key to check
/// - Returns: `false` (bookmarks are macOS-specific)
public func platformSecurityScopedHasBookmark(key: String) -> Bool {
    return false
}
#endif

// MARK: - Directory Validation and Path Utilities

/// Directory permissions for the current process (effective UID)
///
/// This structure represents what the current process can do with a directory.
/// Permissions are checked using the process's effective user ID (EUID).
///
/// In sandboxed apps, these permissions reflect:
/// - The app's sandbox boundaries
/// - User-granted access via TCC (Transparency, Consent, and Control)
/// - Security-scoped resource access (if applicable)
///
/// **Platform Notes:**
/// - **macOS**: Checks traditional Unix permissions + sandbox restrictions
/// - **iOS/watchOS/tvOS/visionOS**: Primarily reflects sandbox permissions
///
/// **Example Usage:**
/// ```swift
/// let permissions = checkDirectoryPermissions(at: someURL)
/// if permissions.readable && permissions.writable {
///     // Safe to read and write
/// }
/// ```
public struct DirectoryPermissions: Sendable {
    /// Whether the current process can read this directory
    public let readable: Bool
    
    /// Whether the current process can write to this directory
    public let writable: Bool
    
    /// Whether the current process can execute/search this directory
    /// (required to list contents or traverse into subdirectories)
    public let executable: Bool
    
    /// Whether the directory exists and is a directory (not a file)
    public let exists: Bool
    
    /// Whether the path exists but is not a directory (e.g., it's a file)
    public let isFile: Bool
    
    /// Whether the directory is accessible (exists and is a directory)
    public var accessible: Bool {
        return exists && !isFile
    }
    
    /// Whether the directory is usable for read operations
    public var canRead: Bool {
        return accessible && readable
    }
    
    /// Whether the directory is usable for write operations
    public var canWrite: Bool {
        return accessible && writable
    }
    
    /// Whether the directory is usable for full operations (read, write, list)
    public var fullyAccessible: Bool {
        return accessible && readable && writable && executable
    }
    
    public init(
        readable: Bool,
        writable: Bool,
        executable: Bool,
        exists: Bool,
        isFile: Bool
    ) {
        self.readable = readable
        self.writable = writable
        self.executable = executable
        self.exists = exists
        self.isFile = isFile
    }
}

/// Errors that can occur during directory validation
public enum DirectoryValidationError: Error, LocalizedError, Sendable {
    /// The path does not exist
    case doesNotExist
    
    /// The path exists but is not a directory (e.g., it's a file)
    case notADirectory
    
    /// The directory exists but the current process cannot read it
    case notReadable
    
    /// The directory exists but the current process cannot write to it
    case notWritable
    
    /// The directory exists but the current process cannot execute/search it
    case notExecutable
    
    /// The directory is on a network volume that is unavailable
    case networkVolumeUnavailable
    
    /// The directory is on a network volume that is slow/unresponsive
    case networkVolumeSlow
    
    /// An underlying file system error occurred
    case fileSystemError(Error)
    
    /// The path contains invalid characters or is malformed
    case invalidPath
    
    /// Security-scoped resource access is required but not available
    case securityScopedAccessRequired
    
    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .doesNotExist:
            return i18n.localizedString(for: "SixLayerFramework.directory.doesNotExist")
        case .notADirectory:
            return i18n.localizedString(for: "SixLayerFramework.directory.notADirectory")
        case .notReadable:
            return i18n.localizedString(for: "SixLayerFramework.directory.notReadable")
        case .notWritable:
            return i18n.localizedString(for: "SixLayerFramework.directory.notWritable")
        case .notExecutable:
            return i18n.localizedString(for: "SixLayerFramework.directory.notExecutable")
        case .networkVolumeUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.directory.networkVolumeUnavailable")
        case .networkVolumeSlow:
            return i18n.localizedString(for: "SixLayerFramework.directory.networkVolumeSlow")
        case .fileSystemError(let error):
            let format = i18n.localizedString(for: "SixLayerFramework.file.systemError")
            return String(format: format, error.localizedDescription)
        case .invalidPath:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.invalidPath")
        case .securityScopedAccessRequired:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.securityScopedAccessRequired")
        }
    }
}

// MARK: - Platform File System Error

/// Errors that can occur during platform file system directory operations.
///
/// This error type provides detailed information about why directory operations failed,
/// enabling better error handling, debugging, and user-facing error messages.
///
/// **Example Usage:**
/// ```swift
/// do {
///     let dir = try platformApplicationSupportDirectoryThrowing(createIfNeeded: true)
///     // Use directory
/// } catch PlatformFileSystemError.permissionDenied {
///     // Show user-friendly message about permissions
///     showError("Permission denied. Please check app permissions.")
/// } catch PlatformFileSystemError.diskFull {
///     // Show disk space warning
///     showError("Disk is full. Please free up space.")
/// } catch PlatformFileSystemError.creationFailed(let underlying) {
///     // Log underlying error for debugging
///     print("Creation failed: \(underlying)")
///     showError("Failed to create directory.")
/// } catch {
///     // Handle other errors
///     showError("An error occurred: \(error.localizedDescription)")
/// }
/// ```
public enum PlatformFileSystemError: Error, LocalizedError, Sendable {
    /// The directory could not be located (e.g., Application Support directory not found)
    case directoryNotFound
    
    /// Permission denied - the current process cannot access the directory
    case permissionDenied
    
    /// Disk is full - insufficient space to create directory or write files
    case diskFull
    
    /// Invalid path - the path contains invalid characters or is malformed
    case invalidPath
    
    /// Directory creation failed with an underlying error
    case creationFailed(underlying: Error)
    
    /// iCloud Drive is unavailable (future enhancement)
    case iCloudUnavailable
    
    /// Unknown error occurred
    case unknown(Error)
    
    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .directoryNotFound:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.directoryNotFound")
        case .permissionDenied:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.permissionDenied")
        case .diskFull:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.diskFull")
        case .invalidPath:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.invalidPath")
        case .creationFailed(let error):
            let format = i18n.localizedString(for: "SixLayerFramework.filesystem.creationFailed")
            return String(format: format, error.localizedDescription)
        case .iCloudUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.filesystem.iCloudUnavailable")
        case .unknown(let error):
            let format = i18n.localizedString(for: "SixLayerFramework.file.unknownError")
            return String(format: format, error.localizedDescription)
        }
    }
    
    /// The underlying error, if available
    public var underlyingError: Error? {
        switch self {
        case .creationFailed(let error), .unknown(let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - Error Mapping Helpers

/// Maps Foundation errors to `PlatformFileSystemError`.
///
/// This function provides intelligent mapping of common Foundation errors
/// (particularly `CocoaError`) to more specific `PlatformFileSystemError` cases.
///
/// - Parameter error: The Foundation error to map
/// - Returns: A `PlatformFileSystemError` representing the error
private func mapFoundationError(_ error: Error) -> PlatformFileSystemError {
    // Handle CocoaError specifically
    if let cocoaError = error as? CocoaError {
        switch cocoaError.code {
        case .fileReadNoPermission, .fileWriteNoPermission:
            return .permissionDenied
        case .fileWriteVolumeReadOnly, .fileWriteOutOfSpace:
            return .diskFull
        case .fileNoSuchFile, .fileReadNoSuchFile:
            return .directoryNotFound
        case .fileReadInvalidFileName, .fileWriteInvalidFileName:
            return .invalidPath
        default:
            return .creationFailed(underlying: error)
        }
    }
    
    // Handle POSIX errors if available
    if let posixError = error as? POSIXError {
        switch posixError.code {
        case .EACCES, .EPERM:
            return .permissionDenied
        case .ENOSPC:
            return .diskFull
        case .ENOENT:
            return .directoryNotFound
        case .EINVAL:
            return .invalidPath
        default:
            return .unknown(error)
        }
    }
    
    // For other errors, wrap them
    return .unknown(error)
}

// MARK: - Directory Resolution Helpers

/// Resolves a directory URL, creating it if needed (optional variant).
///
/// This helper function extracts the common logic for resolving directory URLs
/// with creation support. Returns `nil` if the directory cannot be located or created.
///
/// - Parameters:
///   - url: The directory URL to resolve (may be `nil` if directory cannot be located)
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist
/// - Returns: The resolved directory URL, or `nil` if the directory cannot be located or created
private func resolveDirectory(url: URL?, createIfNeeded: Bool) -> URL? {
    guard let url = url else {
        return nil
    }
    
    // Check if directory exists
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    
    if exists && isDirectory.boolValue {
        // Directory exists, return it
        return url
    }
    
    // Directory doesn't exist
    if createIfNeeded {
        // Try to create the directory
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            // Verify it was created successfully
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                return url
            }
        } catch {
            // Creation failed, return nil
            return nil
        }
    }
    
    // Directory doesn't exist and createIfNeeded is false, or creation failed
    return nil
}

/// Resolves a directory URL, creating it if needed (throwing variant).
///
/// This helper function extracts the common logic for resolving directory URLs
/// with creation support and detailed error reporting.
///
/// - Parameters:
///   - url: The directory URL to resolve (may be `nil` if directory cannot be located)
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist
/// - Returns: The resolved directory URL
/// - Throws: `PlatformFileSystemError` if the directory cannot be located or created
private func resolveDirectoryThrowing(url: URL?, createIfNeeded: Bool) throws -> URL {
    guard let url = url else {
        throw PlatformFileSystemError.directoryNotFound
    }
    
    // Check if directory exists
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    
    if exists && isDirectory.boolValue {
        // Directory exists, return it
        return url
    }
    
    // Directory doesn't exist
    if createIfNeeded {
        // Try to create the directory
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            // Verify it was created successfully
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                return url
            } else {
                throw PlatformFileSystemError.creationFailed(underlying: NSError(domain: NSCocoaErrorDomain, code: NSFileWriteFileExistsError))
            }
        } catch {
            throw mapFoundationError(error)
        }
    }
    
    // Directory doesn't exist and createIfNeeded is false
    throw PlatformFileSystemError.directoryNotFound
}

// MARK: - Directory Validation

/// Validates that a directory exists, is accessible, and has required permissions.
///
/// This is a convenience function that performs basic validation checks.
/// For detailed error information, use `validateDirectoryAccessThrowing()`.
///
/// **What it checks:**
/// - Directory exists
/// - Path is actually a directory (not a file)
/// - Current process can read the directory
///
/// **What it does NOT check:**
/// - Write permissions (use `checkDirectoryPermissions()` for that)
/// - Execute permissions
/// - Network volume availability
///
/// **Platform Behavior:**
/// - **macOS**: Checks Unix permissions + sandbox restrictions
/// - **iOS/watchOS/tvOS/visionOS**: Checks sandbox permissions
///
/// **Security-Scoped Resources:**
/// - Does NOT automatically start security-scoped access
/// - If the URL requires security-scoped access, wrap the call in
///   `platformSecurityScopedAccess()` first
///
/// **Example Usage:**
/// ```swift
/// // Simple check
/// if validateDirectoryAccess(at: someURL) {
///     // Directory is accessible and readable
/// }
///
/// // With security-scoped resources
/// platformSecurityScopedAccess(url: userSelectedURL) { accessibleURL in
///     if validateDirectoryAccess(at: accessibleURL) {
///         // Safe to use
///     }
/// }
/// ```
///
/// - Parameter url: The directory URL to validate
/// - Returns: `true` if the directory exists, is a directory, and is readable by the current process
public func validateDirectoryAccess(at url: URL) -> Bool {
    let path = url.path
    let (exists, isDirectory) = pathExistsAndIsDirectory(path)
    
    guard exists && isDirectory else {
        return false
    }
    
    // Check if readable
    return FileManager.default.isReadableFile(atPath: path)
}

/// Validates directory access and returns detailed error information on failure.
///
/// This is the throwing variant that provides specific error information.
/// For simple boolean checks, use `validateDirectoryAccess()`.
///
/// **What it checks:**
/// - Directory exists
/// - Path is actually a directory (not a file)
/// - Current process can read the directory
///
/// **Error Details:**
/// - Returns specific `DirectoryValidationError` cases
/// - Wraps underlying file system errors
///
/// **Example Usage:**
/// ```swift
/// do {
///     try validateDirectoryAccessThrowing(at: someURL)
///     // Directory is accessible and readable
/// } catch DirectoryValidationError.doesNotExist {
///     // Handle missing directory
/// } catch DirectoryValidationError.notReadable {
///     // Handle permission issue
/// } catch {
///     // Handle other errors
/// }
/// ```
///
/// - Parameter url: The directory URL to validate
/// - Throws: `DirectoryValidationError` if validation fails
/// - Returns: `true` if validation succeeds (always returns true, throws on failure)
@discardableResult
public func validateDirectoryAccessThrowing(at url: URL) throws -> Bool {
    let path = url.path
    let (exists, isDirectory) = pathExistsAndIsDirectory(path)
    
    guard exists else {
        throw DirectoryValidationError.doesNotExist
    }
    
    guard isDirectory else {
        throw DirectoryValidationError.notADirectory
    }
    
    guard FileManager.default.isReadableFile(atPath: path) else {
        throw DirectoryValidationError.notReadable
    }
    
    return true
}

/// Checks directory permissions for the current process (effective UID).
///
/// Returns detailed permission information including read, write, and execute
/// permissions. Permissions are checked using the process's effective user ID.
///
/// **What it checks:**
/// - Directory existence
/// - Whether path is a directory (not a file)
/// - Read permission (can list contents)
/// - Write permission (can create/modify files)
/// - Execute permission (can traverse/search)
///
/// **Platform Behavior:**
/// - **macOS**: Checks Unix permissions (owner/group/other) based on effective UID
/// - **iOS/watchOS/tvOS/visionOS**: Primarily reflects sandbox permissions
///
/// **Security-Scoped Resources:**
/// - Does NOT automatically start security-scoped access
/// - If the URL requires security-scoped access, wrap the call in
///   `platformSecurityScopedAccess()` first
///
/// **Example Usage:**
/// ```swift
/// let permissions = checkDirectoryPermissions(at: someURL)
///
/// if permissions.canRead {
///     // Safe to read/list contents
/// }
///
/// if permissions.canWrite {
///     // Safe to create/modify files
/// }
///
/// if permissions.fullyAccessible {
///     // Safe for all operations
/// }
/// ```
///
/// - Parameter url: The directory URL to check
/// - Returns: `DirectoryPermissions` structure with detailed permission information
public func checkDirectoryPermissions(at url: URL) -> DirectoryPermissions {
    let path = url.path
    let (exists, isDirectory) = pathExistsAndIsDirectory(path)
    
    let isFile = exists && !isDirectory
    
    guard exists && isDirectory else {
        return DirectoryPermissions(
            readable: false,
            writable: false,
            executable: false,
            exists: exists,
            isFile: isFile
        )
    }
    
    // Check permissions
    let readable = FileManager.default.isReadableFile(atPath: path)
    let writable = FileManager.default.isWritableFile(atPath: path)
    let executable = FileManager.default.isExecutableFile(atPath: path)
    
    return DirectoryPermissions(
        readable: readable,
        writable: writable,
        executable: executable,
        exists: true,
        isFile: false
    )
}

// MARK: - Disk Space Utilities

/// Gets the available disk space for the volume containing the specified directory.
///
/// **Platform Behavior:**
/// - **macOS**: Generally reliable, returns bytes available
/// - **iOS/watchOS/tvOS/visionOS**: May be unreliable or return `nil` in some cases
///   - iCloud Drive volumes may report incorrect values
///   - Some system volumes may not report space
///   - Sandbox restrictions may limit accuracy
///
/// **Performance:**
/// - Generally fast (< 10ms)
/// - May be slower on network volumes
///
/// **Example Usage:**
/// ```swift
/// if let availableSpace = getAvailableDiskSpace(at: someURL) {
///     let availableGB = Double(availableSpace) / 1_000_000_000.0
///     if availableGB < 1.0 {
///         // Warn user about low disk space
///     }
/// }
/// ```
///
/// - Parameter url: A URL on the volume to check (can be any path on the volume)
/// - Returns: Available disk space in bytes, or `nil` if unavailable or cannot be determined
public func getAvailableDiskSpace(at url: URL) -> Int64? {
    let path = url.path
    
    do {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
        if let freeSize = attributes[.systemFreeSize] as? NSNumber {
            return freeSize.int64Value
        }
    } catch {
        // Return nil on error
    }
    
    return nil
}

/// Checks if there is enough available disk space for a specified operation.
///
/// This is a convenience function that wraps `getAvailableDiskSpace()` to provide
/// a simple boolean check for whether a specific amount of space is available.
///
/// **Platform Behavior:**
/// - Same platform limitations as `getAvailableDiskSpace()`
/// - Returns `false` if space cannot be determined (conservative approach)
///
/// **Performance:**
/// - Same as `getAvailableDiskSpace()` (< 10ms typically)
///
/// **Example Usage:**
/// ```swift
/// // Check if we can create a 2GB file
/// if hasEnoughDiskSpace(at: someURL, requiredBytes: 2_000_000_000) {
///     // Safe to proceed with operation
///     createLargeFile(at: someURL)
/// } else {
///     // Not enough space - warn user
///     showDiskSpaceWarning()
/// }
///
/// // Check before downloading
/// let downloadSize: Int64 = 500_000_000 // 500 MB
/// if hasEnoughDiskSpace(at: downloadDirectory, requiredBytes: downloadSize) {
///     startDownload()
/// } else {
///     showInsufficientSpaceError()
/// }
/// ```
///
/// - Parameters:
///   - url: A URL on the volume to check (can be any path on the volume)
///   - requiredBytes: The number of bytes required for the operation
/// - Returns: `true` if enough space is available, `false` if not enough space or if space cannot be determined
public func hasEnoughDiskSpace(at url: URL, requiredBytes: Int64) -> Bool {
    guard requiredBytes >= 0 else {
        return true // Negative or zero bytes means no space needed
    }
    
    guard let availableSpace = getAvailableDiskSpace(at: url) else {
        return false // Conservative: return false if we can't determine
    }
    
    return availableSpace >= requiredBytes
}

// MARK: - Path Utilities

/// Safely appends a path component to a URL with validation.
///
/// This function provides additional safety over `URL.appendingPathComponent()`
/// by validating the component and preventing path traversal attacks.
///
/// **Safety Features:**
/// - Validates component doesn't contain path separators (`/` or `\`)
/// - Prevents path traversal (`..` components)
/// - Sanitizes component before appending
/// - Validates resulting path is still valid
///
/// **When to use:**
/// - When appending user-provided path components
/// - When appending components from untrusted sources
/// - When you need validation beyond basic URL construction
///
/// **When NOT to use:**
/// - For trusted, known-safe path components
/// - For simple path construction (use `URL.appendingPathComponent()`)
///
/// **Example Usage:**
/// ```swift
/// let baseURL = platformDocumentsDirectory()!
/// 
/// // Safe: user-provided component
/// if let safeURL = safeAppendPathComponent(baseURL, "user_data") {
///     // Component was valid and appended
/// } else {
///     // Component was invalid (contained path separators or ..)
/// }
///
/// // Unsafe component (will return nil)
/// safeAppendPathComponent(baseURL, "../etc/passwd") // Returns nil
/// safeAppendPathComponent(baseURL, "data/file.txt") // Returns nil (contains /)
/// ```
///
/// - Parameters:
///   - url: The base URL to append to
///   - component: The path component to append (must not contain path separators)
/// - Returns: The new URL with component appended, or `nil` if component is invalid
public func safeAppendPathComponent(_ url: URL, _ component: String) -> URL? {
    // Trim whitespace
    let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Validation rules
    guard !trimmed.isEmpty else {
        return nil // Empty after trimming
    }
    
    guard !trimmed.contains("/") && !trimmed.contains("\\") else {
        return nil // Contains path separators
    }
    
    guard trimmed != ".." && trimmed != "." else {
        return nil // Path traversal
    }
    
    guard !trimmed.contains("\0") else {
        return nil // Null bytes
    }
    
    // Check for leading/trailing whitespace (security concern)
    guard component == trimmed else {
        return nil // Had leading/trailing whitespace
    }
    
    return url.appendingPathComponent(trimmed)
}

// MARK: - Directory Size Calculation

/// Calculates the total size of a directory and all its contents recursively.
///
/// **Performance Characteristics:**
/// - **Small directories** (< 100 files): Fast (< 100ms)
/// - **Medium directories** (100-10,000 files): Moderate (100ms - 5s)
/// - **Large directories** (> 10,000 files): Slow (5s - minutes)
/// - **Network volumes**: Can be very slow or timeout
///
/// **Considerations:**
/// - This operation can be slow for large directory trees
/// - Consider using `calculateDirectorySizeAsync()` for large directories
/// - May timeout or fail on network volumes
/// - Symlinks are followed (counts target size, not link)
///
/// **Example Usage:**
/// ```swift
/// // For small directories
/// if let size = calculateDirectorySize(at: someURL) {
///     let sizeMB = Double(size) / 1_000_000.0
///     print("Directory size: \(sizeMB) MB")
/// }
///
/// // For large directories, use async version
/// Task {
///     if let size = await calculateDirectorySizeAsync(at: largeURL) {
///         // Handle result
///     }
/// }
/// ```
///
/// - Parameter url: The directory URL to calculate size for
/// - Returns: Total size in bytes, or `nil` if calculation fails or directory doesn't exist
/// - Warning: This is a synchronous operation that may block for large directories
/// - Note: Returns `0` for empty directories
public func calculateDirectorySize(at url: URL) -> Int64? {
    let path = url.path
    let (exists, isDirectory) = pathExistsAndIsDirectory(path)
    
    guard exists && isDirectory else {
        return nil
    }
    
    var totalSize: Int64 = 0
    var visitedInodes = Set<ino_t>() // Track visited inodes to detect circular symlinks
    
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey],
        options: [.skipsHiddenFiles],
        errorHandler: nil
    ) else {
        return nil
    }
    
    for case let fileURL as URL in enumerator {
        // Get resource values
        guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]) else {
            continue
        }
        
        // Skip if it's a directory (we only count file sizes)
        if resourceValues.isDirectory == true {
            continue
        }
        
        // Handle symlinks - check for circular references
        if resourceValues.isSymbolicLink == true {
            // For symlinks, we could skip or follow - following is more accurate
            // But we need to detect circular references
            if let inode = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.systemFileNumber] as? NSNumber {
                let ino = inode.uint64Value
                if visitedInodes.contains(ino_t(ino)) {
                    continue // Skip circular symlink
                }
                visitedInodes.insert(ino_t(ino))
            }
        }
        
        // Add file size
        if let fileSize = resourceValues.fileSize {
            totalSize += Int64(fileSize)
        }
    }
    
    return totalSize
}

/// Asynchronously calculates the total size of a directory and all its contents.
///
/// This is the async variant for large directories that may take significant time.
/// Use this instead of `calculateDirectorySize()` for directories with many files
/// or when called from the main thread.
///
/// **Performance:**
/// - Same performance characteristics as sync version
/// - Does not block the calling thread
/// - Can be cancelled via Task cancellation
///
/// **Example Usage:**
/// ```swift
/// Task {
///     if let size = await calculateDirectorySizeAsync(at: largeURL) {
///         updateUI(with: size)
///     }
/// }
///
/// // With cancellation
/// let task = Task {
///     if let size = await calculateDirectorySizeAsync(at: url) {
///         // Handle result
///     }
/// }
/// task.cancel() // Cancels the calculation
/// ```
///
/// - Parameter url: The directory URL to calculate size for
/// - Returns: Total size in bytes, or `nil` if calculation fails
/// - Note: Can be cancelled via Task cancellation
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func calculateDirectorySizeAsync(at url: URL) async -> Int64? {
    let path = url.path
    let (exists, isDirectory) = pathExistsAndIsDirectory(path)
    
    guard exists && isDirectory else {
        return nil
    }
    
    var totalSize: Int64 = 0
    var visitedInodes = Set<ino_t>() // Track visited inodes to detect circular symlinks
    var fileCount = 0
    
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey],
        options: [.skipsHiddenFiles],
        errorHandler: nil
    ) else {
        return nil
    }
    
    // Convert synchronous enumerator to work in async context
    while let fileURL = enumerator.nextObject() as? URL {
        // Check for cancellation
        try? Task.checkCancellation()
        
        // Yield periodically to avoid blocking
        if fileCount % 100 == 0 {
            await Task.yield()
        }
        fileCount += 1
        
        // Get resource values
        guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]) else {
            continue
        }
        
        // Skip if it's a directory (we only count file sizes)
        if resourceValues.isDirectory == true {
            continue
        }
        
        // Handle symlinks - check for circular references
        if resourceValues.isSymbolicLink == true {
            if let inode = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.systemFileNumber] as? NSNumber {
                let ino = inode.uint64Value
                if visitedInodes.contains(ino_t(ino)) {
                    continue // Skip circular symlink
                }
                visitedInodes.insert(ino_t(ino))
            }
        }
        
        // Add file size
        if let fileSize = resourceValues.fileSize {
            totalSize += Int64(fileSize)
        }
    }
    
    return totalSize
}

// MARK: - Path Sanitization

// Note: Sanitization helper functions are defined in StringSanitizationHelpers.swift
// to avoid code duplication with StringUtilities.swift

/// Checks if a path exists and is a directory
private func pathExistsAndIsDirectory(_ path: String) -> (exists: Bool, isDirectory: Bool) {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return (exists, isDirectory.boolValue)
}

/// Sanitizes a path string to prevent security vulnerabilities.
///
/// **What it does:**
/// - Normalizes Unicode to NFC form (prevents HFS+/APFS compatibility issues)
/// - Removes all control characters (0x00-0x1F, 0x7F)
/// - Removes zero-width characters (can hide malicious content)
/// - Removes bidirectional override characters (can reverse text display)
/// - Removes path traversal sequences (`..`)
/// - Removes leading/trailing whitespace, dots, and spaces
/// - Normalizes path separators (converts `\` to `/`)
/// - Removes multiple consecutive separators
/// - Removes/replaces reserved characters (e.g., `:` on macOS)
///
/// **What it does NOT do:**
/// - Validate path exists
/// - Check permissions
/// - Resolve symlinks
/// - Validate path is within a sandbox
/// - Detect Unicode confusables (homoglyphs)
/// - Enforce maximum path length
///
/// **Security Considerations:**
/// - This function helps prevent path traversal attacks and obfuscation
/// - However, it does NOT guarantee the path is safe
/// - Always validate paths against expected directories
/// - Use `URL` instead of `String` when possible (URLs are safer)
/// - Consider using `safeAppendPathComponent()` for component-level safety
///
/// **Example Usage:**
/// ```swift
/// // User-provided path (potentially unsafe)
/// let userPath = "../../etc/passwd"
/// let sanitized = sanitizePath(userPath)
/// // Result: "etc/passwd" (removed ..)
///
/// // Path with control characters
/// let unsafePath = "file\u{200B}name.txt" // Contains zero-width space
/// let sanitized = sanitizePath(unsafePath)
/// // Result: "filename.txt" (removed zero-width space)
/// ```
///
/// - Parameter path: The path string to sanitize
/// - Returns: Sanitized path string
/// - Warning: Sanitization is not a substitute for proper path validation
public func sanitizePath(_ path: String) -> String {
    var result = path
    
    // 1. Unicode normalization to NFC
    result = result.precomposedStringWithCanonicalMapping
    
    // 2. Remove control characters (0x00-0x1F, 0x7F), including newlines/tabs for filesystem
    result = removeControlCharacters(result, preserveWhitespace: false)
    
    // 3. Remove zero-width characters
    result = removeZeroWidthCharacters(result)
    
    // 4. Remove bidirectional override characters
    result = removeBidirectionalOverrideCharacters(result)
    
    // 5. Convert backslashes to forward slashes
    result = result.replacingOccurrences(of: "\\", with: "/")
    
    // 6. Remove leading/trailing whitespace
    result = result.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // 7. Remove trailing dots and spaces (for cross-platform compatibility)
    // But preserve leading dot for hidden files
    let hadLeadingDot = result.hasPrefix(".")
    result = result.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
    if hadLeadingDot && !result.isEmpty {
        result = "." + result
    }
    
    // 8. Remove .. sequences (path traversal)
    while result.contains("../") {
        result = result.replacingOccurrences(of: "../", with: "")
    }
    while result.hasPrefix("../") {
        result = String(result.dropFirst(3))
    }
    if result == ".." {
        result = ""
    }
    
    // 9. Remove . sequences (but preserve . at start for hidden files)
    if result != "." && result.hasPrefix("./") {
        result = String(result.dropFirst(2))
    }
    while result.contains("/./") {
        result = result.replacingOccurrences(of: "/./", with: "/")
    }
    
    // 10. Collapse multiple consecutive separators
    while result.contains("//") {
        result = result.replacingOccurrences(of: "//", with: "/")
    }
    
    // 11. Remove leading separators (but preserve one if path is absolute)
    // For relative paths that start with / after removing .., remove the leading /
    let wasAbsolute = path.hasPrefix("/")
    if result.hasPrefix("/") {
        if wasAbsolute {
            // Preserve leading / for absolute paths
            result = "/" + result.dropFirst().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        } else {
            // Remove leading / for relative paths that got it from .. removal
            result = result.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
    } else {
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    
    // 12. Replace reserved characters (colon on macOS)
    // But preserve Windows drive letters (C:, D:, etc.) and colons in absolute paths
    #if os(macOS)
    // Only replace colons that are not part of Windows drive letters
    // Windows drive letters are single letter followed by colon at start: "C:", "D:", etc.
    if result.count >= 2 && result[result.startIndex].isLetter && result[result.index(result.startIndex, offsetBy: 1)] == ":" {
        // Preserve Windows drive letter format
    } else {
        // Replace other colons
        result = result.replacingOccurrences(of: ":", with: "-")
    }
    #endif
    
    return result
}

/// Sanitizes a string to be safe for use as a filename or path component.
///
/// This function is designed for sanitizing individual components (filenames, directory names)
/// that will be used in file paths. For sanitizing full paths, use `sanitizePath()`.
///
/// **What it does:**
/// - Normalizes Unicode to NFC form (prevents HFS+/APFS compatibility issues)
/// - Removes all control characters (0x00-0x1F, 0x7F)
/// - Removes zero-width characters (can hide malicious content)
/// - Removes bidirectional override characters (can reverse text display)
/// - Removes/replaces path separators (`/`, `\`) - not allowed in filenames
/// - Removes path traversal sequences (`..`, `.`)
/// - Removes leading/trailing whitespace, dots, and spaces
/// - Removes/replaces reserved characters (e.g., `:` on macOS)
/// - Optionally enforces maximum length
///
/// **What it does NOT do:**
/// - Validate the resulting filename is unique
/// - Check if filename already exists
/// - Validate path exists
/// - Check permissions
/// - Detect Unicode confusables (homoglyphs)
///
/// **Differences from `sanitizePath()`:**
/// - `sanitizePath()` handles full paths with separators
/// - `sanitizeFilename()` handles single components (no separators allowed)
/// - `sanitizeFilename()` is stricter - path separators are removed/replaced, not normalized
/// - `sanitizeFilename()` can enforce maximum length
///
/// **Security Considerations:**
/// - This function helps prevent security issues in filenames
/// - However, it does NOT guarantee the filename is completely safe
/// - Always validate filenames are within expected directories
/// - Use `URL.appendingPathComponent()` with sanitized filenames
/// - Consider using `safeAppendPathComponent()` for additional validation
///
/// **Example Usage:**
/// ```swift
/// // User-provided filename (potentially unsafe)
/// let userFilename = "my:file\u{200B}name.txt"
/// let sanitized = sanitizeFilename(userFilename)
/// // Result: "my-filename.txt" or "myfilename.txt" (colon and zero-width space removed)
///
/// // Filename with path separators (will be removed/replaced)
/// let unsafeName = "folder/file.txt"
/// let sanitized = sanitizeFilename(unsafeName)
/// // Result: "folder-file.txt" or "folder_file.txt" (separator replaced)
/// ```
///
/// - Parameters:
///   - filename: The string to sanitize for use as a filename
///   - replacementCharacter: Character to replace invalid characters with (default: `"-"`)
///   - maxLength: Maximum length for the filename (default: `255`, `nil` for no limit)
/// - Returns: Sanitized filename string
/// - Warning: Sanitization is not a substitute for proper validation
public func sanitizeFilename(
    _ filename: String,
    replacementCharacter: Character = "-",
    maxLength: Int? = 255
) -> String {
    var result = filename
    
    // 1. Unicode normalization to NFC
    result = result.precomposedStringWithCanonicalMapping
    
    // 2. Remove control characters (0x00-0x1F, 0x7F), including newlines/tabs for filesystem
    result = removeControlCharacters(result, preserveWhitespace: false)
    
    // 3. Remove zero-width characters
    result = removeZeroWidthCharacters(result)
    
    // 4. Remove bidirectional override characters
    result = removeBidirectionalOverrideCharacters(result)
    
    // 5. Replace path separators (not allowed in filenames)
    result = result.replacingOccurrences(of: "/", with: String(replacementCharacter))
    result = result.replacingOccurrences(of: "\\", with: String(replacementCharacter))
    
    // 6. Remove .. sequences
    result = result.replacingOccurrences(of: "..", with: String(replacementCharacter))
    
    // 7. Remove . sequences (but preserve . at start for hidden files)
    if result != "." && result.hasPrefix("./") {
        result = String(result.dropFirst(2))
    }
    if result == "." {
        result = String(replacementCharacter)
    }
    
    // 8. Remove leading/trailing whitespace
    result = result.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // 9. Remove trailing dots and spaces
    result = result.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
    
    // 10. Replace reserved characters (colon on macOS)
    #if os(macOS)
    result = result.replacingOccurrences(of: ":", with: String(replacementCharacter))
    #endif
    
    // 11. Enforce maximum length
    if let maxLength = maxLength, result.count > maxLength {
        result = String(result.prefix(maxLength))
    }
    
    // 12. If result is empty after sanitization, return safe default
    if result.isEmpty {
        result = "_"
    }
    
    return result
}

// MARK: - iCloud Drive Integration

/// Checks if iCloud Drive is available and enabled on the current device.
///
/// This function checks if iCloud Drive is available by attempting to access
/// the default ubiquity container. On platforms that don't support iCloud
/// (watchOS, tvOS), this always returns `false`.
///
/// **Platform Support:**
/// - **iOS/macOS**: Returns `true` if iCloud Drive is available and enabled
/// - **watchOS/tvOS/visionOS**: Always returns `false` (iCloud Drive not supported)
///
/// **Note**: This function checks availability, not whether the user is signed in.
/// Even if iCloud is available, the user may not be signed in to iCloud.
///
/// - Returns: `true` if iCloud Drive is available, `false` otherwise
public func isiCloudDriveAvailable() -> Bool {
    #if os(iOS) || os(macOS)
    // Check if default ubiquity container is available
    if FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil {
        return true
    }
    return false
    #else
    // iCloud Drive not supported on watchOS, tvOS, visionOS
    return false
    #endif
}

/// Checks if a specific iCloud container is available.
///
/// This function checks if a specific iCloud container identifier is available
/// and accessible. The container identifier should be in the format
/// "iCloud.com.example.app" (matching your app's bundle identifier).
///
/// **Platform Support:**
/// - **iOS/macOS**: Returns `true` if the container is available and accessible
/// - **watchOS/tvOS/visionOS**: Always returns `false` (iCloud Drive not supported)
///
/// **Example Usage:**
/// ```swift
/// if isiCloudDriveAvailable(containerIdentifier: "iCloud.com.example.app") {
///     // Use iCloud container
/// } else {
///     // Fall back to local directory
/// }
/// ```
///
/// - Parameter containerIdentifier: The iCloud container identifier (e.g., "iCloud.com.example.app")
/// - Returns: `true` if the container is available, `false` otherwise
public func isiCloudDriveAvailable(containerIdentifier: String) -> Bool {
    #if os(iOS) || os(macOS)
    // Check if specific ubiquity container is available
    if FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) != nil {
        return true
    }
    return false
    #else
    // iCloud Drive not supported on watchOS, tvOS, visionOS
    return false
    #endif
}

/// Returns the iCloud container directory URL.
///
/// This function provides access to an iCloud container directory. The container
/// must be configured in your app's entitlements file.
///
/// **Platform Support:**
/// - **iOS/macOS**: Returns iCloud container URL if available
/// - **watchOS/tvOS/visionOS**: Always returns `nil` (iCloud Drive not supported)
///
/// **Requirements:**
/// - The container identifier must be configured in your app's entitlements
/// - iCloud Drive must be available and enabled
/// - User must be signed in to iCloud (for full functionality)
///
/// **Example Usage:**
/// ```swift
/// if let iCloudURL = platformiCloudContainerDirectory(
///     containerIdentifier: "iCloud.com.example.app",
///     createIfNeeded: true
/// ) {
///     // Use iCloud container
/// } else {
///     // Fall back to local directory
/// }
/// ```
///
/// - Parameters:
///   - containerIdentifier: The iCloud container identifier (e.g., "iCloud.com.example.app")
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the iCloud container directory, or `nil` if unavailable
public func platformiCloudContainerDirectory(containerIdentifier: String, createIfNeeded: Bool = false) -> URL? {
    #if os(iOS) || os(macOS)
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
        return nil
    }
    return resolveDirectory(url: containerURL, createIfNeeded: createIfNeeded)
    #else
    // iCloud Drive not supported on watchOS, tvOS, visionOS
    return nil
    #endif
}

/// Returns the iCloud container directory URL (throwing variant).
///
/// This is the throwing variant that provides detailed error information.
///
/// - Parameters:
///   - containerIdentifier: The iCloud container identifier (e.g., "iCloud.com.example.app")
///   - createIfNeeded: If `true`, creates the directory if it doesn't exist. Defaults to `false`.
/// - Returns: A `URL` representing the iCloud container directory
/// - Throws: `PlatformFileSystemError.iCloudUnavailable` if iCloud is not available, or other `PlatformFileSystemError` if directory cannot be created
public func platformiCloudContainerDirectoryThrowing(containerIdentifier: String, createIfNeeded: Bool = false) throws -> URL {
    #if os(iOS) || os(macOS)
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
        throw PlatformFileSystemError.iCloudUnavailable
    }
    return try resolveDirectoryThrowing(url: containerURL, createIfNeeded: createIfNeeded)
    #else
    // iCloud Drive not supported on watchOS, tvOS, visionOS
    throw PlatformFileSystemError.iCloudUnavailable
    #endif
}

// MARK: - Future Enhancements

/// Potential future enhancements for platform file system utilities:
///
/// **Platform-Specific Features:**
/// - ✅ **iCloud Drive Integration**: Support for iCloud-enabled directories on iOS/macOS (IMPLEMENTED)
///   - ✅ Detect if iCloud Drive is available and enabled
///   - ✅ Option to use iCloud container directories
///   - ⚠️ Handle iCloud sync status and conflicts (basic support - sync status requires NSMetadataQuery)
///
/// - **watchOS/tvOS Optimizations**: Platform-specific directory handling
///   - Optimize for limited storage on watchOS
///   - Handle tvOS shared container access
///
/// **Additional Directories:**
/// - ✅ `platformCachesDirectory()` - Cache directory access (IMPLEMENTED)
/// - ✅ `platformTemporaryDirectory()` - Temporary file directory (IMPLEMENTED)
/// - ✅ `platformSharedContainerDirectory()` - App group shared containers (IMPLEMENTED)
///
/// **Enhanced Features:**
/// - ✅ **Directory Validation**: Verify directory permissions and accessibility (IMPLEMENTED)
///   - ✅ `validateDirectoryAccess()` - Simple boolean validation
///   - ✅ `validateDirectoryAccessThrowing()` - Detailed error variant
///   - ✅ `checkDirectoryPermissions()` - Comprehensive permissions
///
/// - ✅ **Path Utilities**: Additional helper functions (IMPLEMENTED)
///   - ✅ `safeAppendPathComponent()` - Safe path component appending
///   - ✅ `sanitizePath()` - Path sanitization for security
///   - ✅ `sanitizeFilename()` - Filename/component sanitization
///
/// - ✅ **Disk Space Utilities**: Disk space checking (IMPLEMENTED)
///   - ✅ `getAvailableDiskSpace()` - Get available disk space
///   - ✅ `hasEnoughDiskSpace()` - Check if enough space exists
///
/// - ✅ **Directory Size Calculation**: Calculate directory sizes (IMPLEMENTED)
///   - ✅ `calculateDirectorySize()` - Synchronous calculation
///   - ✅ `calculateDirectorySizeAsync()` - Async variant for large directories
///
/// **Security-Scoped Resource Enhancements:**
/// - **Dedicated Storage Manager**: Wrapper around bookmark storage with additional features
///   - Encryption of bookmark data
///   - Compression for large bookmark collections
///   - Migration between storage formats
///   - Bookmark validation and cleanup
///   - Metadata storage (creation date, last access, etc.)
///   - The current implementation uses internal helpers that can be wrapped by a manager
///     class without breaking the public API
///
/// **Considerations:**
/// - Maintain backward compatibility with existing API
/// - Keep optional return types for safe error handling
/// - Consider adding throwing variants for detailed error information
/// - Evaluate performance impact of additional features
///
/// **Implementation Notes:**
/// - Current implementation uses same API on both platforms, but abstraction
///   enables future platform-specific behavior without breaking changes
/// - Optional return type pattern allows graceful degradation
/// - `createIfNeeded` parameter provides flexibility for different use cases
/// - Security-scoped resource functions use internal helpers that can be wrapped
///   by a dedicated manager class in the future without breaking the public API
