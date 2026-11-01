//
//  IntelligentFormView+EntityAutoSave.swift
//  SixLayerFramework
//
//  Entity auto-save functionality for IntelligentFormView
//  Implements Issue #80: Form auto-save and draft functionality
//

import Foundation
import SwiftUI
#if canImport(CoreData)
import CoreData
#endif
#if canImport(SwiftData)
import SwiftData
#endif

extension IntelligentFormView {
    
    /// Wrapper view that adds entity auto-save functionality to a form
    /// - Parameters:
    ///   - content: The form content view
    ///   - entity: The entity being edited
    ///   - autoSaveInterval: Interval for periodic auto-save (default: 30 seconds)
    ///   - isDraft: Whether this entity is a draft (created but not yet submitted)
    ///   - onEntitySaved: Optional callback when entity is auto-saved
    @MainActor
    static func withEntityAutoSave<T>(
        content: some View,
        entity: T,
        autoSaveInterval: TimeInterval = 30.0,
        isDraft: Bool = false,
        onEntitySaved: ((T) -> Void)? = nil
    ) -> some View {
        EntityAutoSaveWrapper(
            content: content,
            entity: entity,
            autoSaveInterval: autoSaveInterval,
            isDraft: isDraft,
            onEntitySaved: onEntitySaved
        )
    }
}

// MARK: - Entity Auto-Save Wrapper

/// Wrapper view that manages periodic entity auto-save
@MainActor
private struct EntityAutoSaveWrapper<T>: View {
    let content: AnyView
    let entity: T
    let autoSaveInterval: TimeInterval
    let isDraft: Bool
    let onEntitySaved: ((T) -> Void)?
    
    @State private var autoSaveTask: Task<Void, Never>?
    
    #if canImport(CoreData)
    @Environment(\.managedObjectContext) private var managedObjectContext
    #endif
    
    #if canImport(SwiftData)
    @available(macOS 14.0, iOS 17.0, *)
    @Environment(\.self) private var environment
    #endif
    
    init(
        content: some View,
        entity: T,
        autoSaveInterval: TimeInterval,
        isDraft: Bool,
        onEntitySaved: ((T) -> Void)?
    ) {
        self.content = AnyView(content)
        self.entity = entity
        self.autoSaveInterval = autoSaveInterval
        self.isDraft = isDraft
        self.onEntitySaved = onEntitySaved
    }
    
    var body: some View {
        content
            .onAppear {
                startAutoSave()
            }
            .onDisappear {
                stopAutoSave()
                // Final save when view disappears
                saveEntity()
            }
    }
    
    /// Start periodic auto-save timer
    private func startAutoSave() {
        stopAutoSave()
        
        // Use Task-based timer for SwiftUI compatibility
        let interval = autoSaveInterval
        let entityToSave = entity
        let isDraftFlag = isDraft
        let onSaved = onEntitySaved
        
        autoSaveTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                saveEntity(entity: entityToSave, isDraft: isDraftFlag, onEntitySaved: onSaved)
            }
        }
    }
    
    /// Stop auto-save timer
    private func stopAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = nil
    }
    
    /// Save entity to persistent storage
    private func saveEntity() {
        saveEntity(entity: entity, isDraft: isDraft, onEntitySaved: onEntitySaved)
    }
    
    /// Save entity to persistent storage (internal helper)
    @MainActor
    private func saveEntity(
        entity: T,
        isDraft: Bool,
        onEntitySaved: ((T) -> Void)?
    ) {
        // Save Core Data entity
        #if canImport(CoreData)
        if let managedObject = entity as? NSManagedObject,
           let context = managedObject.managedObjectContext {
            do {
                // Update timestamp if property exists
                if managedObject.entity.attributesByName["updatedAt"] != nil {
                    managedObject.setValue(Date(), forKey: "updatedAt")
                } else if managedObject.entity.attributesByName["modifiedAt"] != nil {
                    managedObject.setValue(Date(), forKey: "modifiedAt")
                } else if managedObject.entity.attributesByName["lastModified"] != nil {
                    managedObject.setValue(Date(), forKey: "lastModified")
                }
                
                // Mark as draft if applicable
                if isDraft {
                    if managedObject.entity.attributesByName["isDraft"] != nil {
                        managedObject.setValue(true, forKey: "isDraft")
                    }
                }
                
                // Save the context
                if context.hasChanges {
                    try context.save()
                    onEntitySaved?(entity)
                }
            } catch {
                // Log error but don't crash
                print("Error auto-saving Core Data entity: \(error.localizedDescription)")
            }
        }
        #endif
        
        // Save SwiftData entity
        #if canImport(SwiftData)
        if #available(macOS 14.0, iOS 17.0, *) {
            if entity is any PersistentModel {
                guard let modelContext = SwiftDataContextAccess.installedContext(in: environment) else {
                    print("SwiftData model auto-save: No ModelContainer is installed. Refusing to open the empty default store.")
                    return
                }
                do {
                    // Note: SwiftData timestamp updates would need to be done via the model itself
                    // or in the onSubmit callback, as we can't directly set properties via reflection
                    
                    // Save the context if it has changes
                    if modelContext.hasChanges {
                        try modelContext.save()
                        onEntitySaved?(entity)
                    }
                } catch {
                    // Log error but don't crash
                    print("Error auto-saving SwiftData entity: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }
}
