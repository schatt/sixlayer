//
//  CloudKitServiceQueueStatusTests.swift
//  SixLayerFrameworkTests
//
//  Tests for CloudKitService queue status reporting
//

import Testing
import CloudKit
@testable import SixLayerFramework

// MARK: - Queue Status Tests

@Suite("CloudKit Service Queue Status")
@MainActor
final class CloudKitServiceQueueStatusTests {
    
    // MARK: - QueueStatus Struct Tests
    
    @Test func testQueueStatusInitialization() {
        let status = QueueStatus(
            totalCount: 10,
            pendingCount: 5,
            failedCount: 2,
            oldestPendingDate: Date(),
            retryableCount: 1
        )
        
        #expect(status.totalCount == 10)
        #expect(status.pendingCount == 5)
        #expect(status.failedCount == 2)
        #expect(status.oldestPendingDate != nil)
        #expect(status.retryableCount == 1)
    }
    
    @Test func testQueueStatusWithNilOldestPendingDate() {
        let status = QueueStatus(
            totalCount: 0,
            pendingCount: 0,
            failedCount: 0,
            oldestPendingDate: nil,
            retryableCount: 0
        )
        
        #expect(status.oldestPendingDate == nil)
    }
    
    // MARK: - queueStatus Property Tests
    
    @Test func testQueueStatusWithEmptyQueue() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_status_empty")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let status = try service.queueStatus
        
        #expect(status.totalCount == 0)
        #expect(status.pendingCount == 0)
        #expect(status.failedCount == 0)
        #expect(status.oldestPendingDate == nil)
        #expect(status.retryableCount == 0)
    }
    
    @Test func testQueueStatusWithPendingOperations() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_status_pending")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let date1 = Date().addingTimeInterval(-100)
        let date2 = Date().addingTimeInterval(-50)
        
        let op1 = QueuedCloudKitOperation(
            operationType: "save",
            timestamp: date1,
            status: "pending"
        )
        let op2 = QueuedCloudKitOperation(
            operationType: "delete",
            timestamp: date2,
            status: "pending"
        )
        
        try storage.enqueue(op1)
        try storage.enqueue(op2)
        
        let status = try service.queueStatus
        
        #expect(status.totalCount == 2)
        #expect(status.pendingCount == 2)
        #expect(status.failedCount == 0)
        #expect(status.oldestPendingDate != nil)
        #expect(status.retryableCount == 0)
    }
    
    @Test func testQueueStatusWithFailedOperations() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_status_failed")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let op1 = QueuedCloudKitOperation(
            operationType: "save",
            retryCount: 1,
            maxRetries: 3,
            status: "failed"
        )
        let op2 = QueuedCloudKitOperation(
            operationType: "delete",
            retryCount: 3,
            maxRetries: 3,
            status: "failed"
        )
        
        try storage.enqueue(op1)
        try storage.enqueue(op2)
        
        let status = try service.queueStatus
        
        #expect(status.totalCount == 2)
        #expect(status.pendingCount == 0)
        #expect(status.failedCount == 2)
        #expect(status.retryableCount == 1) // Only op1 is retryable (retryCount < maxRetries)
    }
    
    @Test func testQueueStatusWithMixedStatusOperations() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_status_mixed")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let pendingDate = Date().addingTimeInterval(-200)
        
        let op1 = QueuedCloudKitOperation(
            operationType: "save",
            timestamp: pendingDate,
            status: "pending"
        )
        let op2 = QueuedCloudKitOperation(
            operationType: "delete",
            retryCount: 1,
            maxRetries: 3,
            status: "failed"
        )
        let op3 = QueuedCloudKitOperation(
            operationType: "sync",
            status: "completed"
        )
        
        try storage.enqueue(op1)
        try storage.enqueue(op2)
        try storage.enqueue(op3)
        
        let status = try service.queueStatus
        
        #expect(status.totalCount == 3)
        #expect(status.pendingCount == 1)
        #expect(status.failedCount == 1)
        #expect(status.oldestPendingDate != nil)
        #expect(status.retryableCount == 1)
    }
    
    @Test func testQueueStatusRetryableCountCalculation() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_queue_status_retryable")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        // Retryable: failed status AND retryCount < maxRetries
        let retryable1 = QueuedCloudKitOperation(
            operationType: "save",
            retryCount: 0,
            maxRetries: 3,
            status: "failed"
        )
        let retryable2 = QueuedCloudKitOperation(
            operationType: "delete",
            retryCount: 2,
            maxRetries: 3,
            status: "failed"
        )
        
        // Not retryable: exceeded maxRetries
        let notRetryable1 = QueuedCloudKitOperation(
            operationType: "sync",
            retryCount: 3,
            maxRetries: 3,
            status: "failed"
        )
        
        // Not retryable: not failed status
        let notRetryable2 = QueuedCloudKitOperation(
            operationType: "save",
            retryCount: 1,
            maxRetries: 3,
            status: "pending"
        )
        
        try storage.enqueue(retryable1)
        try storage.enqueue(retryable2)
        try storage.enqueue(notRetryable1)
        try storage.enqueue(notRetryable2)
        
        let status = try service.queueStatus
        
        #expect(status.failedCount == 3) // retryable1, retryable2, notRetryable1
        #expect(status.retryableCount == 2) // Only retryable1 and retryable2
    }
    
    // MARK: - retryFailedOperations Tests
    
    @Test func testRetryFailedOperationsWithRetryableOperations() async throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_retry_retryable")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let op1 = QueuedCloudKitOperation(
            operationType: "save",
            retryCount: 1,
            maxRetries: 3,
            status: "failed"
        )
        let op2 = QueuedCloudKitOperation(
            operationType: "delete",
            retryCount: 0,
            maxRetries: 3,
            status: "failed"
        )
        
        try storage.enqueue(op1)
        try storage.enqueue(op2)
        
        try await service.retryFailedOperations()
        
        let allOps = try storage.getAllOperations()
        let retriedOps = allOps.filter { $0.status == "pending" && $0.retryCount == 0 }
        
        #expect(retriedOps.count == 2)
    }
    
    @Test func testRetryFailedOperationsSkipsExceededMaxRetries() async throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_retry_exceeded")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let retryable = QueuedCloudKitOperation(
            operationType: "save",
            retryCount: 2,
            maxRetries: 3,
            status: "failed"
        )
        let exceeded = QueuedCloudKitOperation(
            operationType: "delete",
            retryCount: 3,
            maxRetries: 3,
            status: "failed"
        )
        
        try storage.enqueue(retryable)
        try storage.enqueue(exceeded)
        
        try await service.retryFailedOperations()
        
        let allOps = try storage.getAllOperations()
        let pendingOps = allOps.filter { $0.status == "pending" }
        let failedOps = allOps.filter { $0.status == "failed" }
        
        #expect(pendingOps.count == 1) // Only retryable was retried
        #expect(failedOps.count == 1) // exceeded remains failed
    }
    
    @Test func testRetryFailedOperationsWithEmptyQueue() async throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_retry_empty")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        // Should not throw with empty queue
        try await service.retryFailedOperations()
        
        let status = try service.queueStatus
        #expect(status.totalCount == 0)
    }
    
    // MARK: - clearFailedOperations Tests
    
    @Test func testClearFailedOperationsRemovesOnlyFailed() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_clear_failed")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let pending = QueuedCloudKitOperation(
            operationType: "save",
            status: "pending"
        )
        let failed1 = QueuedCloudKitOperation(
            operationType: "delete",
            status: "failed"
        )
        let failed2 = QueuedCloudKitOperation(
            operationType: "sync",
            status: "failed"
        )
        let completed = QueuedCloudKitOperation(
            operationType: "save",
            status: "completed"
        )
        
        try storage.enqueue(pending)
        try storage.enqueue(failed1)
        try storage.enqueue(failed2)
        try storage.enqueue(completed)
        
        try service.clearFailedOperations()
        
        let allOps = try storage.getAllOperations()
        let failedOps = allOps.filter { $0.status == "failed" }
        
        #expect(failedOps.isEmpty)
        #expect(allOps.count == 2) // pending and completed remain
    }
    
    @Test func testClearFailedOperationsWithEmptyQueue() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_clear_empty")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        // Should not throw with empty queue
        try service.clearFailedOperations()
        
        let status = try service.queueStatus
        #expect(status.totalCount == 0)
    }
    
    @Test func testClearFailedOperationsPreservesPendingOperations() throws {
        let delegate = TestCloudKitDelegate()
        let storage = UserDefaultsCloudKitQueueStorage(key: "test_clear_pending")
        try storage.clear()
        let service = CloudKitService(
            delegate: delegate,
            usePublicDatabase: false,
            queueStorage: storage
        )
        
        let pending1 = QueuedCloudKitOperation(
            operationType: "save",
            status: "pending"
        )
        let pending2 = QueuedCloudKitOperation(
            operationType: "delete",
            status: "pending"
        )
        let failed = QueuedCloudKitOperation(
            operationType: "sync",
            status: "failed"
        )
        
        try storage.enqueue(pending1)
        try storage.enqueue(pending2)
        try storage.enqueue(failed)
        
        try service.clearFailedOperations()
        
        let allOps = try storage.getAllOperations()
        let pendingOps = allOps.filter { $0.status == "pending" }
        
        #expect(pendingOps.count == 2)
        #expect(allOps.count == 2) // Only pending operations remain
    }
}
