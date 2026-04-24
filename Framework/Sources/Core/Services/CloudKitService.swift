//
//  CloudKitService.swift
//  SixLayerFramework
//
//  CloudKit service implementation with delegate pattern
//  Eliminates boilerplate while allowing app-specific configuration
//

import Foundation
import CloudKit
@preconcurrency import Combine
import Network

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - CloudKit Batch Operation Results

/// Result of a batch save operation with detailed success/failure information
public struct SaveResult {
    /// Records that were successfully saved
    public let successful: [CKRecord]
    
    /// Records that failed to save, with their IDs and errors
    public let failed: [(CKRecord.ID, Error)]
    
    /// Conflicts detected (local record, remote record)
    public let conflicts: [(CKRecord, CKRecord)]
    
    /// Total number of records processed
    public var totalCount: Int {
        successful.count + failed.count + conflicts.count
    }
    
    /// Whether all records succeeded
    public var allSucceeded: Bool {
        failed.isEmpty && conflicts.isEmpty
    }
    
    public init(successful: [CKRecord] = [], failed: [(CKRecord.ID, Error)] = [], conflicts: [(CKRecord, CKRecord)] = []) {
        self.successful = successful
        self.failed = failed
        self.conflicts = conflicts
    }
}

// MARK: - CloudKit Queue Status

/// Status information about the CloudKit operation queue
public struct QueueStatus {
    /// Total number of operations in the queue
    public let totalCount: Int
    
    /// Number of operations with pending status
    public let pendingCount: Int
    
    /// Number of operations with failed status
    public let failedCount: Int
    
    /// Date of the oldest pending operation, if any
    public let oldestPendingDate: Date?
    
    /// Number of failed operations that can be retried (status == "failed" AND retryCount < maxRetries)
    public let retryableCount: Int
    
    public init(
        totalCount: Int,
        pendingCount: Int,
        failedCount: Int,
        oldestPendingDate: Date?,
        retryableCount: Int
    ) {
        self.totalCount = totalCount
        self.pendingCount = pendingCount
        self.failedCount = failedCount
        self.oldestPendingDate = oldestPendingDate
        self.retryableCount = retryableCount
    }
}

// MARK: - CloudKit Service Error Types

/// Errors that can occur during CloudKit service operations
public enum CloudKitServiceError: LocalizedError {
    case containerNotFound
    case accountUnavailable
    case networkUnavailable
    case writeNotSupportedOnPlatform
    case missingRequiredField(String)
    case recordNotFound
    case conflictDetected(local: CKRecord, remote: CKRecord)
    case quotaExceeded
    case permissionDenied
    case invalidRecord
    case unknown(Error)
    
    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .containerNotFound:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.containerNotFound")
        case .accountUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.accountUnavailable")
        case .networkUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.networkUnavailable")
        case .writeNotSupportedOnPlatform:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.writeNotSupported")
        case .missingRequiredField(let field):
            let format = i18n.localizedString(for: "SixLayerFramework.cloudkit.missingField")
            // If format is still the key (not found), provide fallback
            if format == "SixLayerFramework.cloudkit.missingField" {
                return "Required field '\(field)' is missing"
            }
            return String(format: format, field)
        case .recordNotFound:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.recordNotFound")
        case .conflictDetected:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.conflictDetected")
        case .quotaExceeded:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.quotaExceeded")
        case .permissionDenied:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.permissionDenied")
        case .invalidRecord:
            return i18n.localizedString(for: "SixLayerFramework.cloudkit.invalidRecord")
        case .unknown(let error):
            let format = i18n.localizedString(for: "SixLayerFramework.cloudkit.unknownError")
            // If format is still the key (not found), provide fallback
            if format == "SixLayerFramework.cloudkit.unknownError" {
                return "Unknown error: \(error.localizedDescription)"
            }
            return String(format: format, error.localizedDescription)
        }
    }
}

// MARK: - CloudKit Sync Progress

/// Detailed progress information for sync operations
public struct SyncProgress {
    /// Overall progress (0.0 to 1.0)
    public let overallProgress: Double
    
    /// Current entity/record type being processed
    public let currentEntity: String?
    
    /// Current item number being processed
    public let currentItem: Int
    
    /// Total number of items to process
    public let totalItems: Int
    
    /// Items processed per second (if available)
    public let itemsPerSecond: Double?
    
    /// Estimated time remaining in seconds (if available)
    public let estimatedTimeRemaining: TimeInterval?
    
    /// Number of items uploaded
    public let itemsUploaded: Int
    
    /// Number of items downloaded
    public let itemsDownloaded: Int
    
    /// Number of conflicts found
    public let conflictsFound: Int
    
    public init(
        overallProgress: Double,
        currentEntity: String? = nil,
        currentItem: Int = 0,
        totalItems: Int = 0,
        itemsPerSecond: Double? = nil,
        estimatedTimeRemaining: TimeInterval? = nil,
        itemsUploaded: Int = 0,
        itemsDownloaded: Int = 0,
        conflictsFound: Int = 0
    ) {
        self.overallProgress = overallProgress
        self.currentEntity = currentEntity
        self.currentItem = currentItem
        self.totalItems = totalItems
        self.itemsPerSecond = itemsPerSecond
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.itemsUploaded = itemsUploaded
        self.itemsDownloaded = itemsDownloaded
        self.conflictsFound = conflictsFound
    }
}

// MARK: - CloudKit Sync Status

/// Status of CloudKit sync operations
public enum CloudKitSyncStatus: Equatable {
    case idle
    case syncing
    case paused
    case error(Error)
    case complete
    
    public static func == (lhs: CloudKitSyncStatus, rhs: CloudKitSyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.paused, .paused), (.complete, .complete):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - CloudKit Service Delegate Protocol

/// Protocol for app-specific CloudKit configuration and business logic
@MainActor
public protocol CloudKitServiceDelegate: AnyObject {
    /// Required: Container identifier
    func containerIdentifier() -> String
    
    /// Optional: Conflict resolution
    func resolveConflict(local: CKRecord, remote: CKRecord) -> CKRecord?
    
    /// Optional: Record validation
    func validateRecord(_ record: CKRecord) throws
    
    /// Optional: Record transformation
    func transformRecord(_ record: CKRecord) -> CKRecord
    
    /// Optional: Custom error handling
    func handleError(_ error: Error) -> Bool // returns true if handled
    
    /// Optional: Sync completion notification
    func syncDidComplete(success: Bool, recordsChanged: Int)
}

// MARK: - Default Implementation (Framework Provides)

extension CloudKitServiceDelegate {
    /// Default: Use remote (server wins)
    public func resolveConflict(local: CKRecord, remote: CKRecord) -> CKRecord? {
        return remote
    }
    
    /// Default: No validation
    public func validateRecord(_ record: CKRecord) throws {
        // No validation by default
    }
    
    /// Default: No transformation
    public func transformRecord(_ record: CKRecord) -> CKRecord {
        return record
    }
    
    /// Default: Framework handles errors
    public func handleError(_ error: Error) -> Bool {
        return false
    }
    
    /// Default: No action
    public func syncDidComplete(success: Bool, recordsChanged: Int) {
        // No action by default
    }
}

// MARK: - CloudKit Service

/// CloudKit service that eliminates boilerplate while allowing app-specific configuration
@MainActor
public class CloudKitService: ObservableObject {
    // MARK: - Published Properties
    
    @Published public var syncStatus: CloudKitSyncStatus = .idle
    @Published public var syncProgress: Double = 0.0
    @Published public var detailedSyncProgress: SyncProgress?
    @Published public var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published public var lastError: Error?
    
    // MARK: - Public Properties
    
    /// Delegate for app-specific logic
    public weak var delegate: CloudKitServiceDelegate?
    
    /// Database selection (default: private)
    /// Note: Accessing this property will initialize the container if not already initialized
    /// In test environments without CloudKit, this will throw an error
    public var database: CKDatabase {
        guard let container = container else {
            // In test environment without CloudKit - throw error
            // Tests should avoid accessing database directly
            fatalError("CloudKit container not available. This may occur in test environments without CloudKit entitlements. Use a mock service or ensure CloudKit is properly configured.")
        }
        return usePublicDatabase ? container.publicCloudDatabase : container.privateCloudDatabase
    }
    
    // MARK: - Private Properties
    
    private var _container: CKContainer?
    private var container: CKContainer? {
        if let existing = _container {
            return existing
        }
        // Lazy initialization - only create when actually needed
        // In test environments, this may not be available
        guard canInitializeContainer() else {
            return nil
        }
        let newContainer = CKContainer(identifier: containerIdentifier)
        _container = newContainer
        return newContainer
    }
    private let usePublicDatabase: Bool
    private let queueStorage: CloudKitQueueStorage?
    private var isNetworkAvailable: Bool = true
    private var autoFlushEnabled: Bool = true
    private var lastSyncToken: CKServerChangeToken?
    private let syncTokenKey: String
    private let containerIdentifier: String
    private var networkStatusCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Initialize CloudKit service with delegate
    /// - Parameters:
    ///   - delegate: Delegate providing container identifier and optional custom logic
    ///   - usePublicDatabase: Whether to use public database (default: false for private)
    ///   - queueStorage: Optional queue storage (default: UserDefaultsCloudKitQueueStorage)
    public init(
        delegate: CloudKitServiceDelegate,
        usePublicDatabase: Bool = false,
        queueStorage: CloudKitQueueStorage? = nil
    ) {
        self.delegate = delegate
        self.usePublicDatabase = usePublicDatabase
        self.queueStorage = queueStorage ?? UserDefaultsCloudKitQueueStorage()
        
        // Store container identifier (don't initialize container yet - lazy init)
        self.containerIdentifier = delegate.containerIdentifier()
        
        // Load last sync token
        self.syncTokenKey = "cloudkit_sync_token_\(containerIdentifier)"
        self.lastSyncToken = loadSyncToken()
        
        // Check account status (non-blocking, errors are handled internally)
        Task {
            do {
                _ = try await checkAccountStatus()
            } catch {
                // Account status check failed - will be set to .couldNotDetermine
                // This is non-critical for initialization
            }
        }
        
        // Start network monitoring using shared manager
        startNetworkMonitoring()
    }
    
    deinit {
        // Clean up network monitoring subscription
        // AnyCancellable.cancel() is thread-safe
        networkStatusCancellable?.cancel()
        Task { @MainActor in
            SharedNetworkStatusManager.shared.stopMonitoring()
        }
    }
    
    // MARK: - Account Management
    
    /// Check current account status
    public func checkAccountStatus() async throws -> CKAccountStatus {
        // Only check if container can be initialized (avoids crashes in test environments)
        guard let ckContainer = container else {
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
            }
            return .couldNotDetermine
        }
        
        let status = try await ckContainer.accountStatus()
        await MainActor.run {
            self.accountStatus = status
        }
        return status
    }
    
    /// Check if container can be safely initialized (not in test environment without entitlements)
    private func canInitializeContainer() -> Bool {
        // XCUITest host: XCTest runs out-of-process; `XCTestConfigurationFilePath` is unset, but the driver
        // passes `-UITesting` / `XCUI_TESTING`. Creating `CKContainer` can trap without entitlements (#169).
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            return false
        }
        if ProcessInfo.processInfo.environment["XCUI_TESTING"] == "1" {
            return false
        }
        // In-process XCTest: skip CloudKit container (same rationale as UI test host).
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return false
        }
        #endif
        return true
    }
    
    /// Request account status update
    public func requestAccountStatus() async throws {
        _ = try await checkAccountStatus()
    }
    
    // MARK: - Basic CRUD Operations
    
    /// Save a record to CloudKit
    /// Automatically queues operation if network is unavailable
    public func save(_ record: CKRecord) async throws -> CKRecord {
        // Platform check for write operations
        #if os(tvOS) || os(watchOS)
        throw CloudKitServiceError.writeNotSupportedOnPlatform
        #endif
        
        // Validate record via delegate
        try delegate?.validateRecord(record)
        
        // Transform record via delegate
        let transformedRecord = delegate?.transformRecord(record) ?? record
        
        // Check network availability
        if !isNetworkAvailable {
            // Queue operation for later
            try await queueOperation(type: "save", record: transformedRecord)
            throw CloudKitServiceError.networkUnavailable
        }
        
        // Ensure container is available
        guard let ckContainer = container else {
            // In test environment - queue operation instead
            try await queueOperation(type: "save", record: transformedRecord)
            throw CloudKitServiceError.accountUnavailable
        }
        
        // Save to CloudKit
        do {
            let savedRecord = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).save(transformedRecord)
            return savedRecord
        } catch let error as CKError {
            // Handle conflicts
            if error.code == .serverRecordChanged {
                if let serverRecord = error.serverRecord {
                    // Try to resolve conflict via delegate
                    if let resolved = delegate?.resolveConflict(local: transformedRecord, remote: serverRecord) {
                        // Retry with resolved record
                        guard let ckContainer = container else {
                            throw CloudKitServiceError.accountUnavailable
                        }
                        return try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).save(resolved)
                    } else {
                        throw CloudKitServiceError.conflictDetected(local: transformedRecord, remote: serverRecord)
                    }
                }
            }
            
            // If network error, queue the operation
            if error.code == .networkUnavailable || error.code == .networkFailure {
                try await queueOperation(type: "save", record: transformedRecord)
            }
            
            // Check if delegate handles this error
            if delegate?.handleError(error) == true {
                // Delegate handled it, but we still need to throw something
                throw CloudKitServiceError.unknown(error)
            }
            
            // Map CKError to CloudKitServiceError
            throw mapCKError(error)
        } catch {
            // Check if delegate handles this error
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            // If it's a network error and we haven't queued it yet, try to queue
            if let nsError = error as NSError?,
               nsError.domain == NSURLErrorDomain,
               (nsError.code == NSURLErrorNotConnectedToInternet || nsError.code == NSURLErrorNetworkConnectionLost) {
                try await queueOperation(type: "save", record: transformedRecord)
            }
            throw error
        }
    }
    
    /// Fetch a record by ID
    public func fetch(recordID: CKRecord.ID) async throws -> CKRecord? {
        guard let ckContainer = container else {
            throw CloudKitServiceError.accountUnavailable
        }
        
        do {
            let record = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).record(for: recordID)
            
            // Transform record via delegate
            if let transformed = delegate?.transformRecord(record) {
                return transformed
            }
            return record
        } catch let error as CKError {
            if error.code == .unknownItem {
                return nil
            }
            
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw mapCKError(error)
        } catch {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw error
        }
    }
    
    /// Delete a record by ID
    /// Automatically queues operation if network is unavailable
    public func delete(recordID: CKRecord.ID) async throws {
        // Platform check for write operations
        #if os(tvOS) || os(watchOS)
        throw CloudKitServiceError.writeNotSupportedOnPlatform
        #endif
        
        // Check network availability
        if !isNetworkAvailable {
            // Queue operation for later
            try await queueOperation(type: "delete", recordID: recordID)
            throw CloudKitServiceError.networkUnavailable
        }
        
        guard let ckContainer = container else {
            try await queueOperation(type: "delete", recordID: recordID)
            throw CloudKitServiceError.accountUnavailable
        }
        
        do {
            _ = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).deleteRecord(withID: recordID)
        } catch let error as CKError {
            // If network error, queue the operation
            if error.code == .networkUnavailable || error.code == .networkFailure {
                try await queueOperation(type: "delete", recordID: recordID)
            }
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw mapCKError(error)
        } catch {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw error
        }
    }
    
    /// Query records
    public func query(_ query: CKQuery) async throws -> [CKRecord] {
        guard let ckContainer = container else {
            throw CloudKitServiceError.accountUnavailable
        }
        
        do {
            let (results, _) = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).records(matching: query)
            var records: [CKRecord] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    // Transform record via delegate
                    if let transformed = delegate?.transformRecord(record) {
                        records.append(transformed)
                    } else {
                        records.append(record)
                    }
                case .failure(let error):
                    // Log but continue with other records
                    if delegate?.handleError(error) != true {
                        // If delegate doesn't handle it, we might want to throw
                        // For now, continue with other records
                    }
                }
            }
            
            return records
        } catch let error as CKError {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw mapCKError(error)
        } catch {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw error
        }
    }
    
    // MARK: - Batch Operations
    
    /// Save multiple records with detailed result information
    /// Returns partial success - processes all records even if some fail
    public func saveWithResult(_ records: [CKRecord]) async throws -> SaveResult {
        // Platform check for write operations
        #if os(tvOS) || os(watchOS)
        throw CloudKitServiceError.writeNotSupportedOnPlatform
        #endif
        
        // Validate and transform all records
        var transformedRecords: [CKRecord] = []
        var recordMapping: [CKRecord.ID: CKRecord] = [:]
        for record in records {
            try delegate?.validateRecord(record)
            let transformed = delegate?.transformRecord(record) ?? record
            transformedRecords.append(transformed)
            recordMapping[transformed.recordID] = record // Map back to original
        }
        
        guard let ckContainer = container else {
            throw CloudKitServiceError.accountUnavailable
        }
        
        do {
            let (results, _) = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).modifyRecords(saving: transformedRecords, deleting: [])
            var successful: [CKRecord] = []
            var failed: [(CKRecord.ID, Error)] = []
            var conflicts: [(CKRecord, CKRecord)] = []
            
            for (recordID, result) in results {
                switch result {
                case .success(let record):
                    successful.append(record)
                case .failure(let error):
                    if let ckError = error as? CKError {
                        if ckError.code == .serverRecordChanged {
                            // Conflict detected
                            if let serverRecord = ckError.serverRecord,
                               let localRecord = recordMapping[recordID] {
                                conflicts.append((localRecord, serverRecord))
                                
                                // Try to resolve via delegate
                                if let resolved = delegate?.resolveConflict(local: localRecord, remote: serverRecord) {
                                    // Retry with resolved record
                                    do {
                                        let saved = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).save(resolved)
                                        successful.append(saved)
                                    } catch {
                                        // Retry failed, add to conflicts
                                        conflicts.append((localRecord, serverRecord))
                                    }
                                }
                            } else {
                                // Conflict but can't resolve - add to failed
                                failed.append((recordID, ckError))
                            }
                        } else {
                            // Other error
                            if delegate?.handleError(error) != true {
                                failed.append((recordID, error))
                            }
                        }
                    } else {
                        // Non-CKError
                        if delegate?.handleError(error) != true {
                            failed.append((recordID, error))
                        }
                    }
                }
            }
            
            return SaveResult(successful: successful, failed: failed, conflicts: conflicts)
        } catch let error as CKError {
            // Top-level error from modifyRecords itself
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw mapCKError(error)
        } catch {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw error
        }
    }
    
    /// Save multiple records (more efficient than individual saves)
    /// Returns only successfully saved records - does not throw on partial failure
    public func save(_ records: [CKRecord]) async throws -> [CKRecord] {
        let result = try await saveWithResult(records)
        
        // If there are failures or conflicts and delegate doesn't handle them, we might want to log
        // But we don't throw - we return partial success
        if !result.failed.isEmpty || !result.conflicts.isEmpty {
            // Log failures but don't throw
            for (_, error) in result.failed {
                _ = delegate?.handleError(error)
            }
        }
        
        return result.successful
    }
    
    /// Delete multiple records
    public func delete(_ recordIDs: [CKRecord.ID]) async throws {
        // Platform check for write operations
        #if os(tvOS) || os(watchOS)
        throw CloudKitServiceError.writeNotSupportedOnPlatform
        #endif
        
        guard let ckContainer = container else {
            throw CloudKitServiceError.accountUnavailable
        }
        
        do {
            let (_, _) = try await (usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase).modifyRecords(saving: [], deleting: recordIDs)
        } catch let error as CKError {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw mapCKError(error)
        } catch {
            if delegate?.handleError(error) == true {
                throw CloudKitServiceError.unknown(error)
            }
            throw error
        }
    }
    
    // MARK: - Sync Operations
    
    /// Perform manual sync
    /// Uploads queued operations and fetches remote changes using change tokens
    public func sync() async throws {
        guard !isReadOnlyPlatform else {
            throw CloudKitServiceError.writeNotSupportedOnPlatform
        }
        
        guard isNetworkAvailable else {
            throw CloudKitServiceError.networkUnavailable
        }
        
        guard let ckContainer = container else {
            throw CloudKitServiceError.accountUnavailable
        }
        
        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
            detailedSyncProgress = SyncProgress(overallProgress: 0.0)
        }
        
        var recordsChanged = 0
        var itemsUploaded = 0
        var itemsDownloaded = 0
        
        do {
            // Step 1: Flush offline queue (upload local changes)
            await MainActor.run {
                syncProgress = 0.1
                detailedSyncProgress = SyncProgress(
                    overallProgress: 0.1,
                    itemsUploaded: itemsUploaded
                )
            }
            
            let queueCountBefore = queuedOperationCount
            try await flushOfflineQueue()
            itemsUploaded = queueCountBefore - queuedOperationCount
            
            // Step 2: Fetch remote changes using change token
            await MainActor.run {
                syncProgress = 0.5
                detailedSyncProgress = SyncProgress(
                    overallProgress: 0.5,
                    itemsUploaded: itemsUploaded,
                    itemsDownloaded: itemsDownloaded
                )
            }
            
            // Use default zone for private database
            let database = usePublicDatabase ? ckContainer.publicCloudDatabase : ckContainer.privateCloudDatabase
            let defaultZoneID = CKRecordZone.default().zoneID
            
            // Fetch changes since last sync token using operation-based API
            // Note: CloudKit's change token API is operation-based, so we wrap it in async/await
            let newChangeToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKServerChangeToken?, Error>) in
                let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
                configuration.previousServerChangeToken = lastSyncToken
                
                var downloadedRecords: [CKRecord] = []
                var finalToken: CKServerChangeToken?
                var hasResumed = false
                
                let operation = CKFetchRecordZoneChangesOperation()
                operation.recordZoneIDs = [defaultZoneID]
                operation.configurationsByRecordZoneID = [defaultZoneID: configuration]
                
                operation.recordWasChangedBlock = { [weak self] (recordID: CKRecord.ID, result: Result<CKRecord, Error>) in
                    switch result {
                    case .success(let record):
                        downloadedRecords.append(record)
                        itemsDownloaded += 1
                        // Transform record via delegate
                        _ = self?.delegate?.transformRecord(record)
                    case .failure(let error):
                        // Log error but continue
                        _ = self?.delegate?.handleError(error)
                    }
                }
                
                operation.recordWithIDWasDeletedBlock = { recordID, recordType in
                    // Handle deleted records
                    recordsChanged += 1
                }
                
                operation.recordZoneChangeTokensUpdatedBlock = { zoneID, token, data in
                    finalToken = token
                }
                
                operation.recordZoneFetchResultBlock = { zoneID, result in
                    guard !hasResumed else { return } // Prevent double resume
                    hasResumed = true
                    
                    switch result {
                    case .success(let zoneResult):
                        // Use token from zone result
                        finalToken = zoneResult.serverChangeToken
                        // Process all downloaded records
                        for _ in downloadedRecords {
                            recordsChanged += 1
                        }
                        continuation.resume(returning: finalToken)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                operation.fetchRecordZoneChangesResultBlock = { result in
                    guard !hasResumed else { return } // Prevent double resume
                    hasResumed = true
                    
                    switch result {
                    case .success:
                        // Operation completed successfully
                        // Process all downloaded records
                        for _ in downloadedRecords {
                            recordsChanged += 1
                        }
                        // Use finalToken if we got one, otherwise nil (no changes)
                        continuation.resume(returning: finalToken)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                database.add(operation)
            }
            
            // Update change token if we got a new one
            if let token = newChangeToken {
                saveChangeToken(token)
            }
            
            // Step 3: Complete sync
            await MainActor.run {
                syncProgress = 1.0
                detailedSyncProgress = SyncProgress(
                    overallProgress: 1.0,
                    itemsUploaded: itemsUploaded,
                    itemsDownloaded: itemsDownloaded,
                    conflictsFound: 0
                )
                syncStatus = .complete
                delegate?.syncDidComplete(success: true, recordsChanged: recordsChanged)
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error)
                syncProgress = 0.0
                detailedSyncProgress = nil
                lastError = error
                delegate?.syncDidComplete(success: false, recordsChanged: recordsChanged)
            }
            throw error
        }
    }
    
    /// Sync specific record types
    /// - Parameter recordTypes: Array of record type names to sync
    public func sync(recordTypes: [String]) async throws {
        guard !isReadOnlyPlatform else {
            throw CloudKitServiceError.writeNotSupportedOnPlatform
        }
        
        guard isNetworkAvailable else {
            throw CloudKitServiceError.networkUnavailable
        }
        
        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
        }
        
        var recordsChanged = 0
        
        do {
            // Fetch records of specified types
            for (index, recordType) in recordTypes.enumerated() {
                let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                let records = try await self.query(query)
                
                // Transform records via delegate
                for record in records {
                    _ = delegate?.transformRecord(record)
                }
                
                recordsChanged += records.count
                
                await MainActor.run {
                    syncProgress = Double(index + 1) / Double(recordTypes.count)
                }
            }
            
            await MainActor.run {
                syncProgress = 1.0
                syncStatus = .complete
                delegate?.syncDidComplete(success: true, recordsChanged: recordsChanged)
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error)
                syncProgress = 0.0
                lastError = error
                delegate?.syncDidComplete(success: false, recordsChanged: recordsChanged)
            }
            throw error
        }
    }
    
    /// Start periodic sync
    public func startPeriodicSync(interval: TimeInterval) {
        // TODO: Implement periodic sync with timer
    }
    
    /// Stop periodic sync
    public func stopPeriodicSync() {
        // TODO: Implement periodic sync stop
    }
    
    // MARK: - Offline Queue Management
    
    /// Get count of queued operations
    public var queuedOperationCount: Int {
        guard let storage = queueStorage else { return 0 }
        do {
            return try storage.count()
        } catch {
            return 0
        }
    }
    
    /// Flush offline queue (process all queued operations)
    public func flushOfflineQueue() async throws {
        guard let storage = queueStorage else { return }
        guard isNetworkAvailable else {
            throw CloudKitServiceError.networkUnavailable
        }
        
        var processedCount = 0
        var failedOperations: [QueuedCloudKitOperation] = []
        
        while let operation = try storage.dequeue() {
            // Skip operations that have exceeded max retries
            if operation.retryCount >= operation.maxRetries {
                // Operation failed too many times, skip it
                continue
            }
            
            // Check if operation should be retried now
            if let nextRetryAt = operation.nextRetryAt, nextRetryAt > Date() {
                // Not time to retry yet, re-queue it
                var delayedOperation = operation
                delayedOperation.nextRetryAt = nextRetryAt
                try storage.enqueue(delayedOperation)
                continue
            }
            
            do {
                // Process operation based on type
                switch operation.operationType {
                case "save":
                    // For save operations, we need the app to provide the record
                    // Since CKRecord doesn't encode easily, we'll need delegate help
                    // For now, we'll skip saves that require record reconstruction
                    // Apps should handle this via delegate or custom queue storage
                    if let recordIDString = operation.recordID {
                        // Try to fetch the record first, then save
                        // This is a simplified approach - apps may need custom handling
                        let recordID = CKRecord.ID(recordName: recordIDString)
                        if let existingRecord = try? await fetch(recordID: recordID) {
                            // Record exists, try to save it (app should have updated it)
                            _ = try await save(existingRecord)
                        }
                    }
                    processedCount += 1
                    
                case "delete":
                    if let recordIDString = operation.recordID {
                        let recordID = CKRecord.ID(recordName: recordIDString)
                        try await delete(recordID: recordID)
                        processedCount += 1
                    }
                    
                case "sync":
                    try await sync()
                    processedCount += 1
                    
                default:
                    // Unknown operation type, skip it
                    break
                }
            } catch {
                // Operation failed, increment retry count
                var failedOperation = operation
                failedOperation.retryCount += 1
                failedOperation.status = "failed"
                failedOperation.errorMessage = error.localizedDescription
                
                // Calculate next retry time (exponential backoff)
                let delay = pow(2.0, Double(failedOperation.retryCount)) // 2, 4, 8 seconds
                failedOperation.nextRetryAt = Date().addingTimeInterval(delay)
                
                if failedOperation.retryCount < failedOperation.maxRetries {
                    // Re-queue for retry
                    failedOperation.status = "pending"
                    try storage.enqueue(failedOperation)
                } else {
                    // Max retries exceeded, keep in failed list
                    failedOperations.append(failedOperation)
                }
            }
        }
        
        // Notify delegate of flush completion
        if processedCount > 0 {
            delegate?.syncDidComplete(success: failedOperations.isEmpty, recordsChanged: processedCount)
        }
    }
    
    /// Clear offline queue
    public func clearOfflineQueue() throws {
        try queueStorage?.clear()
    }
    
    /// Enable/disable automatic queue flushing when network returns
    public func setAutoFlushEnabled(_ enabled: Bool) {
        autoFlushEnabled = enabled
    }
    
    // MARK: - Network Monitoring
    
    /// Start monitoring network connectivity using shared network status manager
    /// This prevents multiple NWPathMonitor instances from stressing configd
    private func startNetworkMonitoring() {
        Task { @MainActor in
            // Use shared network status manager to prevent multiple monitors
            let statusPublisher = SharedNetworkStatusManager.shared.startMonitoring()
            
            // Subscribe to network status changes
            networkStatusCancellable = statusPublisher
                .sink { [weak self] (isAvailable: Bool) in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        let wasAvailable = self.isNetworkAvailable
                        self.isNetworkAvailable = isAvailable
                        
                        // If network just became available and we have queued operations, flush them
                        if !wasAvailable && self.isNetworkAvailable && self.autoFlushEnabled {
                            do {
                                try await self.flushOfflineQueue()
                            } catch {
                                // Log error but don't crash
                                self.lastError = error
                            }
                        }
                    }
                }
            
            // Set initial network status
            isNetworkAvailable = SharedNetworkStatusManager.shared.currentStatus()
        }
    }
    
    // MARK: - Queue Operations
    
    /// Queue an operation for later execution
    private func queueOperation(
        type: String,
        record: CKRecord? = nil,
        recordID: CKRecord.ID? = nil
    ) async throws {
        guard let storage = queueStorage else {
            throw CloudKitServiceError.unknown(NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Queue storage not available"]))
        }
        
        var recordIDString: String?
        var recordType: String?
        
        if let record = record {
            // Store record ID and type for later reconstruction
            // Note: CKRecord doesn't conform to Codable, so we store minimal info
            // Apps using custom queue storage can implement full record encoding
            recordIDString = record.recordID.recordName
            recordType = record.recordType
        } else if let recordID = recordID {
            recordIDString = recordID.recordName
        }
        
        let operation = QueuedCloudKitOperation(
            operationType: type,
            recordData: nil, // CKRecord encoding handled by custom storage if needed
            recordID: recordIDString,
            recordType: recordType,
            timestamp: Date(),
            retryCount: 0,
            maxRetries: 3,
            nextRetryAt: nil,
            status: "pending"
        )
        
        try storage.enqueue(operation)
    }
    
    // MARK: - Sync Token Management
    
    /// Get the last change token used for syncing
    public func getLastChangeToken() -> CKServerChangeToken? {
        return lastSyncToken
    }
    
    /// Save a change token for future incremental syncs
    public func saveChangeToken(_ token: CKServerChangeToken) {
        lastSyncToken = token
        saveSyncToken(token)
    }
    
    /// Reset the change token to force a full sync on next sync operation
    public func resetChangeToken() {
        lastSyncToken = nil
        UserDefaults.standard.removeObject(forKey: syncTokenKey)
    }
    
    /// Load last sync token from UserDefaults
    private func loadSyncToken() -> CKServerChangeToken? {
        guard let data = UserDefaults.standard.data(forKey: syncTokenKey) else {
            return nil
        }
        
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = true
            return try unarchiver.decodeTopLevelObject(of: CKServerChangeToken.self, forKey: NSKeyedArchiveRootObjectKey)
        } catch {
            return nil
        }
    }
    
    /// Save sync token to UserDefaults
    private func saveSyncToken(_ token: CKServerChangeToken) {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(token, forKey: NSKeyedArchiveRootObjectKey)
        archiver.finishEncoding()
        let data = archiver.encodedData
        UserDefaults.standard.set(data, forKey: syncTokenKey)
    }
    
    // MARK: - Queue Status Reporting
    
    /// Get current status of the operation queue
    /// - Returns: QueueStatus with statistics about pending, failed, and retryable operations
    /// - Note: May be slow for large queues. Consider caching if called frequently.
    public var queueStatus: QueueStatus {
        get throws {
            guard let storage = queueStorage else {
                return QueueStatus(
                    totalCount: 0,
                    pendingCount: 0,
                    failedCount: 0,
                    oldestPendingDate: nil,
                    retryableCount: 0
                )
            }
            
            let allOperations = try storage.getAllOperations()
            
            let pendingOperations = allOperations.filter { $0.status == "pending" }
            let failedOperations = allOperations.filter { $0.status == "failed" }
            
            let oldestPendingDate = pendingOperations
                .map { $0.timestamp }
                .min()
            
            let retryableCount = failedOperations.filter { operation in
                operation.retryCount < operation.maxRetries
            }.count
            
            return QueueStatus(
                totalCount: allOperations.count,
                pendingCount: pendingOperations.count,
                failedCount: failedOperations.count,
                oldestPendingDate: oldestPendingDate,
                retryableCount: retryableCount
            )
        }
    }
    
    /// Retry failed operations that haven't exceeded their maximum retry count
    /// - Note: Operations with `status == "failed"` AND `retryCount < maxRetries` will be reset to pending status
    public func retryFailedOperations() async throws {
        guard let storage = queueStorage else {
            throw CloudKitServiceError.unknown(NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Queue storage not available"]))
        }
        
        let allOperations = try storage.getAllOperations()
        let retryableOperations = allOperations.filter { operation in
            operation.status == "failed" && operation.retryCount < operation.maxRetries
        }
        
        // Remove retryable operations from storage
        for operation in retryableOperations {
            try storage.remove(operation)
        }
        
        // Re-enqueue with reset status (preserve original timestamp)
        for operation in retryableOperations {
            var retriedOperation = operation
            retriedOperation.status = "pending"
            retriedOperation.retryCount = 0
            retriedOperation.nextRetryAt = nil
            retriedOperation.errorMessage = nil
            // Preserve original timestamp
            try storage.enqueue(retriedOperation)
        }
    }
    
    /// Clear all failed operations from the queue
    /// - Note: Only removes operations with `status == "failed"`. Pending and other operations are preserved.
    public func clearFailedOperations() throws {
        guard let storage = queueStorage else {
            throw CloudKitServiceError.unknown(NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Queue storage not available"]))
        }
        
        let allOperations = try storage.getAllOperations()
        let failedOperations = allOperations.filter { $0.status == "failed" }
        
        for operation in failedOperations {
            try storage.remove(operation)
        }
    }
    
    // MARK: - Private Helpers
    
    private var isReadOnlyPlatform: Bool {
        #if os(tvOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }
    
    private func mapCKError(_ error: CKError) -> CloudKitServiceError {
        switch error.code {
        case .notAuthenticated, .accountTemporarilyUnavailable:
            return .accountUnavailable
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .permissionFailure:
            return .permissionDenied
        case .unknownItem:
            return .recordNotFound
        case .serverRecordChanged:
            // Should be handled above, but just in case
            return .conflictDetected(local: CKRecord(recordType: "Unknown"), remote: CKRecord(recordType: "Unknown"))
        default:
            return .unknown(error)
        }
    }
}



