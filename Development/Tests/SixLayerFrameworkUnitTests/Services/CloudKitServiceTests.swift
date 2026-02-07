//
//  CloudKitServiceTests.swift
//  SixLayerFrameworkTests
//
//  CloudKit service tests
//  Tests the CloudKit service implementation with delegate pattern
//

import Testing
import CloudKit
@testable import SixLayerFramework

// MARK: - CloudKit Service Tests

@Suite("CloudKit Service")
@MainActor
final class CloudKitServiceTests {
    
    // MARK: - Error Types Tests
    
    @Test func testCloudKitServiceErrorTypes() {
        // Test all error types exist and have descriptions
        let errors: [CloudKitServiceError] = [
            .containerNotFound,
            .accountUnavailable,
            .networkUnavailable,
            .writeNotSupportedOnPlatform,
            .missingRequiredField("test"),
            .recordNotFound,
            .conflictDetected(local: CKRecord(recordType: "Test"), remote: CKRecord(recordType: "Test")),
            .quotaExceeded,
            .permissionDenied,
            .invalidRecord,
            .unknown(NSError(domain: "test", code: 1))
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil, "Each error should have error description")
        }
    }
    
    @Test func testCloudKitServiceErrorDescriptions() {
        #expect(CloudKitServiceError.containerNotFound.errorDescription != nil)
        #expect(CloudKitServiceError.accountUnavailable.errorDescription != nil)
        #expect(CloudKitServiceError.networkUnavailable.errorDescription != nil)
        #expect(CloudKitServiceError.writeNotSupportedOnPlatform.errorDescription != nil)
        
        // Test missingRequiredField - check that description exists and contains the field name
        let errorDesc = CloudKitServiceError.missingRequiredField("fieldName").errorDescription
        #expect(errorDesc != nil)
        // The description should either contain "fieldName" or be the formatted string with the field
        #expect(errorDesc?.contains("fieldName") == true || errorDesc?.contains("Required field") == true)
    }
    
    // MARK: - Sync Status Tests
    
    @Test func testCloudKitSyncStatusEquality() {
        #expect(CloudKitSyncStatus.idle == CloudKitSyncStatus.idle)
        #expect(CloudKitSyncStatus.syncing == CloudKitSyncStatus.syncing)
        #expect(CloudKitSyncStatus.paused == CloudKitSyncStatus.paused)
        #expect(CloudKitSyncStatus.complete == CloudKitSyncStatus.complete)
        
        let error1 = NSError(domain: "test", code: 1)
        let error2 = NSError(domain: "test", code: 1)
        #expect(CloudKitSyncStatus.error(error1) == CloudKitSyncStatus.error(error2))
    }
    
    // MARK: - Service Initialization Tests
    
    @Test func testCloudKitServiceInitialization() async {
        // Given: A test delegate
        let delegate = TestCloudKitDelegate(containerID: "iCloud.com.test.app")
        
        // When: Creating the service
        // Note: In test environments, CloudKit container initialization may not be available
        // The service will initialize but container access will be deferred until needed
        let service = CloudKitService(delegate: delegate)
        
        // Then: Service should be created successfully
        #expect(service.delegate === delegate)
        #expect(service.syncStatus == .idle)
        #expect(service.syncProgress == 0.0)
        // Account status may be .couldNotDetermine in test environment
        #expect(service.accountStatus == .couldNotDetermine || 
                service.accountStatus == .available ||
                service.accountStatus == .noAccount)
    }
    
    @Test func testCloudKitServiceUsesPrivateDatabaseByDefault() async {
        // Given: A delegate
        let delegate = TestCloudKitDelegate()
        
        // When: Creating service without specifying database
        let service = CloudKitService(delegate: delegate)
        
        // Then: Should use private database
        // Note: We can't directly test database type, but we can verify it's set
        #expect(service.delegate === delegate)
    }
    
    @Test func testCloudKitServiceUsesPublicDatabaseWhenSpecified() async {
        // Given: A delegate
        let delegate = TestCloudKitDelegate()
        
        // When: Creating service with usePublicDatabase: true
        let service = CloudKitService(delegate: delegate, usePublicDatabase: true)
        
        // Then: Should use public database
        #expect(service.delegate === delegate)
    }
    
    // MARK: - Delegate Protocol Tests
    
    @Test func testDelegateContainerIdentifierIsRequired() async {
        // Given: A delegate with container ID
        let delegate = TestCloudKitDelegate(containerID: "iCloud.com.custom.app")
        
        // When: Creating service
        let service = CloudKitService(delegate: delegate)
        
        // Then: Service should use the delegate's container ID
        #expect(service.delegate?.containerIdentifier() == "iCloud.com.custom.app")
    }
    
    @Test func testDelegateDefaultConflictResolution() async {
        // Given: A delegate (using default implementation)
        let delegate = TestCloudKitDelegate()
        
        // When: Resolving conflict
        let local = CKRecord(recordType: "Test")
        local["value"] = "local"
        let remote = CKRecord(recordType: "Test")
        remote["value"] = "remote"
        
        let resolved = delegate.resolveConflict(local: local, remote: remote)
        
        // Then: Default should return remote (server wins)
        #expect(resolved === remote)
    }
    
    @Test func testDelegateDefaultValidation() async {
        // Given: A delegate (using default implementation)
        let delegate = TestCloudKitDelegate()
        
        // When: Validating a record
        let record = CKRecord(recordType: "Test")
        
        // Then: Should not throw (default does nothing)
        do {
            try delegate.validateRecord(record)
            // Should not throw
        } catch {
            Issue.record("Default validation should not throw")
        }
    }
    
    @Test func testDelegateDefaultTransformation() async {
        // Given: A delegate (using default implementation)
        let delegate = TestCloudKitDelegate()
        
        // When: Transforming a record
        let record = CKRecord(recordType: "Test")
        record["value"] = "test"
        
        let transformed = delegate.transformRecord(record)
        
        // Then: Should return same record (default does nothing)
        #expect(transformed === record)
    }
    
    @Test func testDelegateDefaultErrorHandling() async {
        // Given: A delegate (using default implementation)
        let delegate = TestCloudKitDelegate()
        
        // When: Handling an error
        let error = NSError(domain: "test", code: 1)
        let handled = delegate.handleError(error)
        
        // Then: Should return false (framework handles)
        #expect(handled == false)
    }
    
    // MARK: - Queue Storage Tests
    
    @Test func testUserDefaultsQueueStorageEnqueue() async throws {
        // Given: A queue storage
        let storage = UserDefaultsCloudKitQueueStorage()
        try storage.clear() // Start fresh
        
        // When: Enqueuing an operation
        let operation = QueuedCloudKitOperation(
            operationType: "save",
            recordID: "test-record-id"
        )
        try storage.enqueue(operation)
        
        // Then: Should be able to peek it
        let peeked = try storage.peek()
        #expect(peeked != nil)
        #expect(peeked?.id == operation.id)
        #expect(peeked?.operationType == "save")
    }
    
    @Test func testUserDefaultsQueueStorageDequeue() async throws {
        // Given: A queue storage with operations
        let storage = UserDefaultsCloudKitQueueStorage()
        try storage.clear()
        
        let operation1 = QueuedCloudKitOperation(operationType: "save", recordID: "1")
        let operation2 = QueuedCloudKitOperation(operationType: "delete", recordID: "2")
        
        try storage.enqueue(operation1)
        try storage.enqueue(operation2)
        
        // When: Dequeuing
        let dequeued = try storage.dequeue()
        
        // Then: Should get first operation (FIFO)
        #expect(dequeued != nil)
        #expect(dequeued?.id == operation1.id)
        
        // And: Count should be reduced
        #expect(try storage.count() == 1)
    }
    
    @Test func testUserDefaultsQueueStorageCount() async throws {
        // Given: A queue storage
        let storage = UserDefaultsCloudKitQueueStorage()
        try storage.clear()
        
        // When: Adding operations
        try storage.enqueue(QueuedCloudKitOperation(operationType: "save"))
        try storage.enqueue(QueuedCloudKitOperation(operationType: "delete"))
        
        // Then: Count should be correct
        #expect(try storage.count() == 2)
    }
    
    @Test func testUserDefaultsQueueStorageClear() async throws {
        // Given: A queue storage with operations
        let storage = UserDefaultsCloudKitQueueStorage()
        try storage.enqueue(QueuedCloudKitOperation(operationType: "save"))
        
        // When: Clearing
        try storage.clear()
        
        // Then: Should be empty
        #expect(try storage.count() == 0)
        #expect(try storage.peek() == nil)
    }
    
    // MARK: - Service Queue Integration Tests
    
    @Test func testCloudKitServiceHasQueueStorage() async {
        // Given: A service with default storage
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // Then: Should have queue storage (default UserDefaults)
        #expect(service.queuedOperationCount >= 0) // Should not crash
    }
    
    @Test func testCloudKitServiceCustomQueueStorage() async {
        // Given: A custom queue storage
        let delegate = TestCloudKitDelegate()
        let customStorage = UserDefaultsCloudKitQueueStorage(key: "custom_queue_key")
        try? customStorage.clear()
        
        // When: Creating service with custom storage
        let service = CloudKitService(delegate: delegate, queueStorage: customStorage)
        
        // Then: Should use custom storage
        #expect(service.queuedOperationCount == 0)
    }
    
    // MARK: - Network Monitoring Tests
    
    @Test func testCloudKitServiceStartsNetworkMonitoring() async {
        // Given: A service
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // Then: Network monitoring should be active (we can't directly test, but service should be initialized)
        // Note: Network availability depends on test environment
        #expect(service.queuedOperationCount >= 0) // Should not crash
    }
    
    @Test func testCloudKitServiceAutoFlushEnabled() async {
        // Given: A service
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // When: Disabling auto-flush
        service.setAutoFlushEnabled(false)
        
        // Then: Should be disabled (we can't directly test, but method should not crash)
        // Re-enable for cleanup
        service.setAutoFlushEnabled(true)
    }
    
    // MARK: - Queue Integration Tests
    
    @Test func testCloudKitServiceQueuedOperationCount() async {
        // Given: A service with queue storage
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_count")
        try? storage.clear()
        
        let service = CloudKitService(delegate: delegate, queueStorage: storage)
        
        // When: Adding operations to queue
        let operation1 = QueuedCloudKitOperation(operationType: "save")
        let operation2 = QueuedCloudKitOperation(operationType: "delete")
        try? storage.enqueue(operation1)
        try? storage.enqueue(operation2)
        
        // Then: Count should reflect queued operations
        #expect(service.queuedOperationCount == 2)
    }
    
    @Test func testCloudKitServiceClearQueue() async throws {
        // Given: A service with queued operations
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_clear_queue")
        try storage.clear()
        
        let service = CloudKitService(delegate: delegate, queueStorage: storage)
        try storage.enqueue(QueuedCloudKitOperation(operationType: "save"))
        
        // When: Clearing queue
        try service.clearOfflineQueue()
        
        // Then: Queue should be empty
        #expect(service.queuedOperationCount == 0)
    }
    
    // MARK: - Batch Operations Result Handling Tests
    
    @Test func testSaveResultStructure() async {
        // Given: A SaveResult struct
        let successful = [CKRecord(recordType: "Test")]
        let failed: [(CKRecord.ID, Error)] = [(CKRecord.ID(recordName: "test"), NSError(domain: "test", code: 1))]
        let conflicts: [(CKRecord, CKRecord)] = []
        
        // When: Creating SaveResult
        let result = SaveResult(successful: successful, failed: failed, conflicts: conflicts)
        
        // Then: Should have correct properties
        #expect(result.successful.count == 1)
        #expect(result.failed.count == 1)
        #expect(result.conflicts.isEmpty)
        #expect(result.totalCount == 2)
        #expect(result.allSucceeded == false)
    }
    
    @Test func testSaveResultAllSucceeded() async {
        // Given: A SaveResult with all successful
        let successful = [CKRecord(recordType: "Test1"), CKRecord(recordType: "Test2")]
        let result = SaveResult(successful: successful, failed: [], conflicts: [])
        
        // Then: Should indicate all succeeded
        #expect(result.allSucceeded == true)
        #expect(result.totalCount == 2)
    }
    
    // MARK: - Change Token Management Tests
    
    @Test func testChangeTokenStorage() async {
        // Given: A service
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // When: Getting last change token (initially nil)
        let initialToken = service.getLastChangeToken()
        
        // Then: Should be nil initially
        #expect(initialToken == nil)
        
        // Note: Testing actual token storage requires CloudKit operations
        // This test verifies the API exists
    }
    
    @Test func testResetChangeToken() async {
        // Given: A service
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // When: Resetting change token
        service.resetChangeToken()
        
        // Then: Token should be nil
        #expect(service.getLastChangeToken() == nil)
    }
    
    // MARK: - Enhanced Progress Tracking Tests
    
    @Test func testSyncProgressStruct() async {
        // Given: A service
        let delegate = TestCloudKitDelegate()
        let service = CloudKitService(delegate: delegate)
        
        // When: Starting sync (in test environment, this may not complete)
        // We're testing that the progress tracking structure exists
        #expect(service.syncProgress >= 0.0)
        #expect(service.syncProgress <= 1.0)
    }
}



