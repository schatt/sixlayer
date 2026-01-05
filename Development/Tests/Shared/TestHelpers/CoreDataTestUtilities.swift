//
//  CoreDataTestUtilities.swift
//  SixLayerFrameworkTests
//
//  BUSINESS PURPOSE:
//  Utilities for creating isolated CoreData test containers that don't attempt
//  to sync with CloudKit or access external services
//

import Foundation
import CoreData

#if canImport(CloudKit)
import CloudKit
#endif

/// CoreData test utilities for isolated test containers
public enum CoreDataTestUtilities {
    
    /// Create an isolated test container that doesn't sync with CloudKit
    /// - Parameters:
    ///   - name: The name of the data model
    ///   - managedObjectModel: The managed object model to use
    /// - Returns: An isolated NSPersistentContainer configured for testing
    public static func createIsolatedTestContainer(
        name: String,
        managedObjectModel: NSManagedObjectModel? = nil
    ) -> NSPersistentContainer {
        let model: NSManagedObjectModel
        if let providedModel = managedObjectModel {
            model = providedModel
        } else {
            // Try to load the model from the bundle
            if let modelURL = Bundle.main.url(forResource: name, withExtension: "momd"),
               let loadedModel = NSManagedObjectModel(contentsOf: modelURL) {
                model = loadedModel
            } else {
                // Create a minimal model if we can't find one
                model = NSManagedObjectModel()
            }
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        
        // Configure for in-memory storage (no disk I/O, no CloudKit sync)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Disable CloudKit sync
        #if canImport(CloudKit)
        description.cloudKitContainerOptions = nil
        #endif
        
        container.persistentStoreDescriptions = [description]
        
        // Load the store synchronously
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        return container
    }
    
    /// Create an isolated test container with a custom store type
    /// - Parameters:
    ///   - name: The name of the data model
    ///   - storeType: The store type (default: NSInMemoryStoreType)
    ///   - managedObjectModel: The managed object model to use
    /// - Returns: An isolated NSPersistentContainer configured for testing
    public static func createIsolatedTestContainer(
        name: String,
        storeType: String = NSInMemoryStoreType,
        managedObjectModel: NSManagedObjectModel? = nil
    ) -> NSPersistentContainer {
        let model: NSManagedObjectModel
        if let providedModel = managedObjectModel {
            model = providedModel
        } else {
            if let modelURL = Bundle.main.url(forResource: name, withExtension: "momd"),
               let loadedModel = NSManagedObjectModel(contentsOf: modelURL) {
                model = loadedModel
            } else {
                model = NSManagedObjectModel()
            }
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        
        let description = NSPersistentStoreDescription()
        description.type = storeType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Disable CloudKit sync
        #if canImport(CloudKit)
        description.cloudKitContainerOptions = nil
        #endif
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        return container
    }
}
