# CoreData/SwiftData Testing Guide

## Overview

This guide explains how to set up isolated CoreData and SwiftData stores for testing that don't attempt to sync with CloudKit or access external services (like Account Services, Address Book, etc.).

## The Problem

By default, CoreData and SwiftData may attempt to:
- Sync with CloudKit (if configured)
- Access account services via XPC
- Contact Apple services for remote change notifications
- Access address book or other system services

This causes test failures and XPC communication errors like:
```
Unable to open XPC store: Error Domain=NSCocoaErrorDomain Code=134060
ACMonitoredAccountStore: Failed to fetch accounts
```

Additionally, you may see macOS sandbox warnings in the console like:
```
Couldn't write values for keys (ABMetadataLastOilChange) in CFPrefsPlistSource...
setting these preferences requires user-preference-write or file-write-data sandbox access
```

**These sandbox warnings are benign and can be safely ignored.** They occur when macOS tries to access Contacts/AddressBook preferences, which is expected system behavior and doesn't affect test functionality.

## Solution: Isolated Test Stores

Use `CoreDataTestUtilities` to create isolated test containers that:
- Use in-memory storage (no disk I/O)
- Disable all CloudKit sync features
- Disable remote change notifications
- Prevent access to external services
- Provide clean isolation between tests

## CoreData Testing

### Basic Usage

```swift
import CoreData
import Testing

@Test func testMyCoreDataFeature() throws {
    // Create isolated test container
    let container = CoreDataTestUtilities.createIsolatedTestContainer(
        name: "TestModel",
        managedObjectModel: myModel
    )
    
    let context = container.viewContext
    
    // Use context for testing...
    let entity = NSEntityDescription.insertNewObject(
        forEntityName: "MyEntity",
        into: context
    )
    
    // Test your code...
}
```

### With Custom Model

```swift
let model = NSManagedObjectModel()
// ... configure model entities ...

let container = CoreDataTestUtilities.createIsolatedTestContainer(
    name: "TestModel",
    managedObjectModel: model
)
```

## SwiftData Testing (iOS 17+)

### Basic Usage

```swift
import SwiftData
import Testing

@available(macOS 14.0, iOS 17.0, *)
@Test func testMySwiftDataFeature() throws {
    // Define your schema
    let schema = Schema([MyModel.self])
    
    // Create isolated test container (in-memory, no CloudKit)
    let container = try CoreDataTestUtilities.createIsolatedTestContainer(
        for: schema,
        isStoredInMemoryOnly: true
    )
    
    let context = container.mainContext
    
    // Use context for testing...
    let item = MyModel(...)
    context.insert(item)
    
    // Test your code...
}
```

## Key Configuration Details

### CoreData Isolation Settings

The `CoreDataTestUtilities.createIsolatedTestContainer()` method configures:

1. **In-Memory Store Type**
   ```swift
   desc.type = NSInMemoryStoreType
   desc.url = URL(fileURLWithPath: "/dev/null")
   ```

2. **Disable Automatic Behaviors**
   ```swift
   desc.shouldAddStoreAsynchronously = false
   desc.shouldMigrateStoreAutomatically = false
   desc.shouldInferMappingModelAutomatically = false
   ```

3. **Disable CloudKit & Remote Services**
   ```swift
   desc.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
   desc.setOption(false as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
   desc.cloudKitContainerOptions = nil
   ```

### SwiftData Isolation Settings

For SwiftData, the key is **not specifying** `cloudKitContainerIdentifier`:

```swift
// ✅ CORRECT - No CloudKit sync
let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: schema, configurations: [configuration])

// ❌ WRONG - Will attempt CloudKit sync
let configuration = ModelConfiguration(
    cloudKitContainerIdentifier: "iCloud.com.example.app"
)
```

## Best Practices

1. **Always use in-memory stores for tests**
   - Faster execution
   - No disk I/O
   - Complete isolation

2. **Create a new container per test**
   - Don't share containers between tests
   - Clean up in tearDown if needed

3. **Disable all sync features**
   - CloudKit
   - Remote change notifications
   - History tracking

4. **Handle errors gracefully**
   - In-memory stores may have benign errors
   - Log but don't fail tests unless critical

5. **Use the utility functions**
   - `CoreDataTestUtilities.createIsolatedTestContainer()` handles all configuration
   - Don't manually configure stores in tests

## Common Mistakes

### ❌ Don't use NSPersistentCloudKitContainer in tests
```swift
// WRONG - Will attempt CloudKit sync
let container = NSPersistentCloudKitContainer(name: "TestModel")
```

### ❌ Don't specify CloudKit container identifier
```swift
// WRONG - Will attempt CloudKit sync
let config = ModelConfiguration(cloudKitContainerIdentifier: "iCloud.com.example")
```

### ❌ Don't enable iCloud capabilities in test targets
- Keep test targets isolated from production entitlements

### ❌ Don't forget to disable history tracking
```swift
// WRONG - May trigger remote change notifications
desc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
```

## Example: Complete Test

```swift
import Testing
import CoreData
@testable import MyApp

@Suite("My CoreData Tests")
struct MyCoreDataTests {
    
    @Test func testEntityCreation() throws {
        // Create isolated test container
        let container = CoreDataTestUtilities.createIsolatedTestContainer(
            name: "TestModel"
        )
        
        let context = container.viewContext
        
        // Create test entity
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "Task",
            into: context
        )
        entity.setValue("Test Task", forKey: "title")
        
        // Save context
        try context.save()
        
        // Verify
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        let results = try context.fetch(fetchRequest)
        
        #expect(results.count == 1)
        #expect(results.first?.value(forKey: "title") as? String == "Test Task")
    }
}
```

## Troubleshooting

### Still getting XPC errors?

1. Verify you're using `CoreDataTestUtilities.createIsolatedTestContainer()`
2. Check that `cloudKitContainerOptions` is `nil`
3. Ensure `NSPersistentHistoryTrackingKey` is disabled
4. Verify test target doesn't have iCloud entitlements

### Tests are slow?

1. Make sure you're using `NSInMemoryStoreType` (not SQLite)
2. Don't create unnecessary containers
3. Clean up containers in tearDown

### Data persisting between tests?

1. Create a new container for each test
2. Don't share contexts between tests
3. Use in-memory stores (they're automatically cleared)

## References

- [Apple WWDC 2018: Core Data Best Practices](https://developer.apple.com/videos/play/wwdc2018/224/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Core Data Programming Guide](https://developer.apple.com/documentation/coredata)

