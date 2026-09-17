# IntelligentFormView Automatic Data Binding Guide

**Version**: 5.8.0+  
**Last Updated**: December 2, 2025

## Overview

`IntelligentFormView` now automatically creates a `DataBinder` instance when generating forms, reducing boilerplate and providing real-time model updates by default. This guide explains how automatic binding works, when to use it, and when to opt out.

## Table of Contents

1. [Quick Start](#quick-start)
2. [How Automatic Binding Works](#how-automatic-binding-works)
3. [When to Use Automatic Binding](#when-to-use-automatic-binding)
4. [When to Opt Out](#when-to-opt-out)
5. [Manual Field Binding](#manual-field-binding)
6. [Examples](#examples)
7. [Limitations and Edge Cases](#limitations-and-edge-cases)
8. [Migration Guide](#migration-guide)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Basic Usage (Automatic Binding Enabled)

```swift
struct Task {
    var title: String
    var status: String
    var priority: Int
}

let task = Task(title: "Fix bug", status: "In Progress", priority: 2)

// DataBinder is automatically created
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    onSubmit: { updatedTask in
        // Task is automatically updated as fields change
        print("Updated: \(updatedTask)")
    }
)
```

`selectAllOnBeginEditing` is a form-level opt-in (default `false`, caret at end). It is **not** a `FieldDisplayHints` / `.hints` file key.

### Opt-Out (Disable Automatic Binding)

```swift
// Disable automatic binding
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    onSubmit: { updatedTask in
        // Handle updates manually
    }
)
```

### Explicit DataBinder (Override Automatic)

```swift
// Provide your own DataBinder (autoBind is ignored)
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)
dataBinder.bind("status", to: \Task.status)

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder,  // Your binder takes precedence
    onSubmit: { updatedTask in
        // Your binder is used
    }
)
```

---

## How Automatic Binding Works

### What Gets Created Automatically

When `autoBind: true` (the default) and no explicit `dataBinder` is provided:

1. **DataBinder Instance**: A `DataBinder<T>` instance is automatically created
2. **Model Reference**: The binder holds a reference to your model
3. **Change Tracking**: The binder is ready to track changes
4. **Field Updates**: When fields change, `dataBinder.updateField()` is called automatically

### What Does NOT Happen Automatically

**Important Limitation**: Swift's type system requires compile-time `WritableKeyPath` values. The framework **cannot** automatically bind fields to key paths at runtime. This means:

- ✅ **DataBinder instance is created automatically**
- ❌ **Field-to-key-path binding is NOT automatic** (requires manual binding)

### Why Manual Binding is Still Needed

Swift's reflection (Mirror) can discover:
- Property names
- Property values
- Property types

But it **cannot** create `WritableKeyPath<T, Value>` at runtime because:
- Key paths are compile-time constructs
- They require type information that's erased at runtime
- They provide type safety that runtime reflection cannot guarantee

### The Solution: Hybrid Approach

The framework provides a **hybrid approach**:

1. **Automatic**: Creates the `DataBinder` instance (reduces boilerplate)
2. **Manual**: You bind fields using key paths (ensures type safety)

This gives you:
- ✅ Less boilerplate (no need to create DataBinder manually)
- ✅ Type safety (key paths are compile-time checked)
- ✅ Flexibility (bind only the fields you need)

---

## When to Use Automatic Binding

Automatic binding (default behavior) is ideal when:

### ✅ Real-Time Model Updates

You want form field changes to immediately update your model:

```swift
struct User {
    var name: String
    var email: String
}

let user = User(name: "John", email: "john@example.com")

// Automatic binding - model updates in real-time
IntelligentFormView.generateForm(
    for: User.self,
    initialData: user
    // DataBinder created automatically
    // Fields update model as user types
)
```

### ✅ Mutable Models

Your model has `var` properties (not `let`):

```swift
struct Task {
    var title: String      // ✅ Mutable - can bind
    var status: String     // ✅ Mutable - can bind
    let id: UUID          // ❌ Immutable - cannot bind
}
```

### ✅ Standard Form Editing

You're building a typical edit form where users modify existing data:

```swift
// Edit existing task
IntelligentFormView.generateForm(
    for: task,
    onUpdate: { updatedTask in
        // Task is automatically updated as fields change
        saveTask(updatedTask)
    }
)
```

### ✅ Change Tracking Needed

You want to track what fields changed:

```swift
// The automatically created DataBinder tracks changes
// You can check which fields were modified
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task
)

// Later, check for changes (requires accessing the binder)
// Note: Full change tracking requires manual binding
```

---

## When to Opt Out

Set `autoBind: false` when:

### ❌ Read-Only Forms

Displaying data without editing:

```swift
// Read-only form - no binding needed
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // No updates needed
    onSubmit: { _ in }  // Not used for read-only
)
```

### ❌ Immutable Models

All properties are `let` (cannot be mutated):

```swift
struct ImmutableTask {
    let id: UUID
    let title: String
    let createdAt: Date
}

// Cannot bind immutable properties
IntelligentFormView.generateForm(
    for: ImmutableTask.self,
    initialData: task,
    autoBind: false  // Model is immutable
)
```

### ❌ External State Management

Using Redux, Combine, or other state management:

```swift
@StateObject private var store = AppStore()

// Use external state management
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Updates go through store
    customFieldView: { fieldName, value, type in
        // Update store.dispatch() instead
    }
)
```

### ❌ Batch Updates

Collect all changes and apply at once:

```swift
@State private var pendingChanges: [String: Any] = [:]

IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Collect changes manually
    customFieldView: { fieldName, value, type in
        // Collect in pendingChanges
        pendingChanges[fieldName] = value
    },
    onSubmit: { _ in
        // Apply all changes at once
        applyBatchUpdates(pendingChanges)
    }
)
```

### ❌ Validation Before Updates

Need to validate before updating model:

```swift
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Validate first
    customFieldView: { fieldName, value, type in
        if isValid(value) {
            // Update model manually
        } else {
            // Show validation error
        }
    }
)
```

### ❌ Performance Concerns

Too many real-time updates causing performance issues:

```swift
// Defer updates until user finishes editing
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Update on blur/submit only
    customFieldView: { fieldName, value, type in
        // Update on .onChange or .onSubmit only
    }
)
```

### ❌ Undo/Redo Support

Need to batch changes for undo functionality:

```swift
var undoStack: [TaskState] = []

IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Batch for undo
    onSubmit: { updatedTask in
        undoStack.append(currentState)
        applyChanges(updatedTask)
    }
)
```

### ❌ Complex Field Mappings

Fields don't map 1:1 to model properties:

```swift
// Form field "fullName" maps to firstName + lastName
IntelligentFormView.generateForm(
    for: User.self,
    initialData: user,
    autoBind: false,  // Custom mapping needed
    customFieldView: { fieldName, value, type in
        if fieldName == "fullName" {
            // Split into firstName + lastName
            // Update multiple properties
        }
    }
)
```

---

## Manual Field Binding

Even with automatic `DataBinder` creation, you still need to manually bind fields to key paths for full functionality.

### Why Manual Binding is Required

Swift requires compile-time `WritableKeyPath` values. The framework cannot automatically discover key paths at runtime, so you must provide them explicitly.

### How to Bind Fields

```swift
struct Task {
    var title: String
    var status: String
    var priority: Int
}

let task = Task(title: "Fix bug", status: "In Progress", priority: 2)

// Option 1: Access the auto-created binder (requires storing it)
var autoBinder: DataBinder<Task>?

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    customFieldView: { fieldName, value, type in
        // Access binder here if needed
        // Note: This is a limitation - the auto-created binder
        // is not easily accessible from outside
    }
)

// Option 2: Create your own binder and bind fields
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)
dataBinder.bind("status", to: \Task.status)
dataBinder.bind("priority", to: \Task.priority)

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder  // Your binder with bound fields
)
```

### Binding Helper Pattern

For convenience, you can create a helper extension:

```swift
extension DataBinder where T == Task {
    func bindAllFields() {
        self.bind("title", to: \Task.title)
        self.bind("status", to: \Task.status)
        self.bind("priority", to: \Task.priority)
    }
}

// Usage
let dataBinder = DataBinder(task)
dataBinder.bindAllFields()

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder
)
```

### What Happens Without Manual Binding

If you use automatic binding but don't manually bind fields:

- ✅ **DataBinder instance exists** - The binder is created
- ✅ **Field updates call `updateField()`** - The method is called
- ❌ **Model is NOT updated** - No key paths are bound, so updates don't reach the model
- ✅ **Change tracking works** - Changes are tracked in the binder
- ✅ **Dirty state works** - Fields are marked as dirty

**Result**: The binder tracks changes, but the model itself is not updated until you manually bind fields or handle updates in `onSubmit`.

---

## Examples

### Example 1: Basic Automatic Binding

```swift
struct User {
    var name: String
    var email: String
    var age: Int
}

let user = User(name: "Alice", email: "alice@example.com", age: 30)

// Automatic binding - DataBinder created automatically
let form = IntelligentFormView.generateForm(
    for: User.self,
    initialData: user,
    onSubmit: { updatedUser in
        // User model is updated as fields change
        // (if fields are manually bound, otherwise only on submit)
        print("Updated user: \(updatedUser)")
    }
)
```

### Example 2: Automatic Binding with Manual Field Binding

```swift
struct Task {
    var title: String
    var status: String
    var priority: Int
}

let task = Task(title: "Fix bug", status: "In Progress", priority: 2)

// Create binder and bind fields manually
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)
dataBinder.bind("status", to: \Task.status)
dataBinder.bind("priority", to: \Task.priority)

// Use the binder (autoBind is ignored when dataBinder is provided)
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder,
    onSubmit: { updatedTask in
        // Model is updated in real-time as fields change
        print("Title: \(updatedTask.title)")
        print("Status: \(updatedTask.status)")
    }
)
```

### Example 3: Opt-Out for Read-Only Form

```swift
struct Task {
    let id: UUID
    let title: String
    let createdAt: Date
}

let task = Task(id: UUID(), title: "View task", createdAt: Date())

// Read-only form - no binding needed
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    onSubmit: { _ in }  // Not used
)
```

### Example 4: Opt-Out for External State Management

```swift
@StateObject private var store = AppStore()

struct Task {
    var title: String
    var status: String
}

let task = Task(title: "Fix bug", status: "In Progress")

// Use external state management
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    customFieldView: { fieldName, value, type in
        // Update through store instead
        TextField(fieldName, text: Binding(
            get: { value as? String ?? "" },
            set: { newValue in
                store.dispatch(.updateField(fieldName, value: newValue))
            }
        ))
    }
)
```

### Example 5: Opt-Out for Batch Updates

```swift
struct Task {
    var title: String
    var status: String
    var priority: Int
}

@State private var task = Task(title: "Fix bug", status: "In Progress", priority: 2)
@State private var pendingChanges: [String: Any] = [:]

// Collect changes, apply on submit
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    customFieldView: { fieldName, value, type in
        TextField(fieldName, text: Binding(
            get: { value as? String ?? "" },
            set: { newValue in
                // Collect in pending changes
                pendingChanges[fieldName] = newValue
            }
        ))
    },
    onSubmit: { _ in
        // Apply all changes at once
        if let title = pendingChanges["title"] as? String {
            task.title = title
        }
        if let status = pendingChanges["status"] as? String {
            task.status = status
        }
        // ... apply other changes
        pendingChanges.removeAll()
    }
)
```

### Example 6: Core Data with Automatic Binding

**Important**: CoreData `@NSManaged` properties don't support `WritableKeyPath` assignment. Use KVC-based binding instead.

```swift
#if canImport(CoreData)
import CoreData

// Core Data entity
@objc(Task)
class Task: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var status: String
    @NSManaged var priority: Int
}

let task: Task = // ... get from context

// Option 1: Use bindKVC for CoreData entities
let dataBinder = DataBinder(task)
dataBinder.bindKVC("title")
dataBinder.bindKVC("status")
dataBinder.bindKVC("priority")

let form = IntelligentFormView.generateForm(
    for: task,
    dataBinder: dataBinder,
    onSubmit: { updatedTask in
        // Core Data auto-save happens (see Issue #9)
        // Model is updated as fields change via KVC binding
    }
)

// Option 2: Use bindAuto for automatic detection
let dataBinder2 = DataBinder(task)
dataBinder2.bindAuto("title")  // Auto-detects CoreData and uses KVC
dataBinder2.bindAuto("status")
dataBinder2.bindAuto("priority")

let form2 = IntelligentFormView.generateForm(
    for: task,
    dataBinder: dataBinder2,
    onSubmit: { updatedTask in
        // Core Data auto-save happens
    }
)
#endif
```

**Note**: The `bindKVC()` and `bindAuto()` methods are only available when `CoreData` is imported. For regular Swift types, continue using `bind(_:to:)` with key paths.

---

## Limitations and Edge Cases

### Limitation 1: Key Path Binding is Manual

**Issue**: Swift requires compile-time `WritableKeyPath` values, so automatic field-to-key-path binding is not possible.

**Impact**: You must manually bind fields using `dataBinder.bind(_:to:)` for full functionality.

**Workaround**: Create a helper extension to bind all fields at once:

```swift
extension DataBinder where T == YourModel {
    func bindAllFields() {
        // Bind all fields here
    }
}
```

### Limitation 2: Immutable Properties Cannot Be Bound

**Issue**: Properties declared with `let` cannot be mutated, so they cannot be bound.

**Impact**: Fields for immutable properties will not update the model, even if bound.

**Workaround**: Use `var` for properties that need to be editable, or opt out of automatic binding.

### Limitation 3: CoreData @NSManaged Properties Require KVC Binding

**Issue**: CoreData `@NSManaged` properties don't support `WritableKeyPath` assignment.

**Impact**: Using `bind(_:to:)` with key paths won't work for CoreData entities.

**Solution**: Use `bindKVC(_:)` or `bindAuto(_:)` for CoreData entities:

```swift
#if canImport(CoreData)
let dataBinder = DataBinder(coreDataEntity)
dataBinder.bindKVC("title")  // Use KVC instead of key path
dataBinder.bindAuto("status") // Auto-detects CoreData and uses KVC
#endif
```

**Note**: This limitation was addressed in Issue #72. The framework now provides KVC-based binding specifically for CoreData entities.

### Limitation 3: Auto-Created Binder Not Easily Accessible

**Issue**: The automatically created `DataBinder` is not easily accessible from outside the form generation.

**Impact**: You cannot easily check `hasUnsavedChanges` or `dirtyFields` for the auto-created binder.

**Workaround**: Create your own `DataBinder` and pass it explicitly if you need to access it:

```swift
let dataBinder = DataBinder(task)
// ... bind fields ...

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder  // Now you can access it
)

// Later...
if dataBinder.hasUnsavedChanges {
    // Show unsaved changes warning
}
```

### Limitation 4: Complex Types May Not Bind Correctly

**Issue**: Complex types (nested structs, enums, optionals) may require special handling.

**Impact**: Binding may fail or behave unexpectedly for complex types.

**Workaround**: Use `customFieldView` to handle complex types manually, or opt out of automatic binding.

### Edge Case 1: Structs vs Classes

**Structs**: Value types - binding updates a copy. Changes are tracked but may not persist if the struct is copied.

**Classes**: Reference types - binding updates the original instance. Changes persist automatically.

**Recommendation**: For automatic binding, prefer classes or ensure you're working with the same struct instance.

### Edge Case 2: Optional Properties

**Issue**: Optional properties require special handling when binding.

**Impact**: Binding may need to handle `nil` values.

**Workaround**: Ensure your binding logic handles optionals correctly:

```swift
// For optional String
dataBinder.bind("optionalField", to: \Model.optionalField)
// The binder handles optionals automatically
```

### Edge Case 3: Computed Properties

**Issue**: Computed properties (properties with only a getter) cannot be bound.

**Impact**: Fields for computed properties will not update the model.

**Workaround**: Use stored properties (`var`) for bindable fields, or handle computed properties in `customFieldView`.

---

## Migration Guide

### From Manual DataBinder Creation

**Before** (v5.7.x and earlier):
```swift
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder
)
```

**After** (v5.8.0+):
```swift
// Option 1: Let framework create binder automatically
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task
    // DataBinder created automatically
    // Still need to bind fields manually for full functionality
)

// Option 2: Keep your existing code (still works)
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder  // Your binder takes precedence
)
```

### From No DataBinder

**Before**:
```swift
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task
    // No dataBinder - fields don't update model
)
```

**After**:
```swift
// Automatic binding enabled by default
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task
    // DataBinder created automatically
    // Fields update model (if manually bound)
)

// Or opt out if you don't want it
let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false  // Opt out
)
```

### Breaking Changes

**None**: Existing code continues to work. The `autoBind` parameter defaults to `true`, but:
- If you provide a `dataBinder`, it's used (same as before)
- If you don't provide a `dataBinder`, one is created automatically (new behavior)
- You can opt out with `autoBind: false` if needed

---

## Troubleshooting

### Problem: Model Not Updating

**Symptoms**: Form fields change, but the model doesn't update.

**Cause**: Fields are not manually bound to key paths.

**Solution**: Manually bind fields:

```swift
let dataBinder = DataBinder(task)
dataBinder.bind("title", to: \Task.title)
dataBinder.bind("status", to: \Task.status)

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder
)
```

### Problem: Binding Fails for Immutable Properties

**Symptoms**: Binding fails or model doesn't update for certain fields.

**Cause**: Property is declared with `let` instead of `var`.

**Solution**: Change property to `var`, or opt out of automatic binding:

```swift
struct Task {
    var title: String  // ✅ Mutable
    let id: UUID      // ❌ Immutable - cannot bind
}
```

### Problem: Too Many Updates (Performance)

**Symptoms**: Form is slow or unresponsive.

**Cause**: Automatic binding updates model on every keystroke.

**Solution**: Opt out and handle updates manually:

```swift
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    customFieldView: { fieldName, value, type in
        // Update on .onChange or .onSubmit only
    }
)
```

### Problem: Need to Access DataBinder

**Symptoms**: Need to check `hasUnsavedChanges` or `dirtyFields`.

**Cause**: Auto-created binder is not easily accessible.

**Solution**: Create your own binder:

```swift
let dataBinder = DataBinder(task)
// ... bind fields ...

let form = IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    dataBinder: dataBinder  // Now accessible
)

// Later...
if dataBinder.hasUnsavedChanges {
    // Show warning
}
```

### Problem: External State Management Conflict

**Symptoms**: Updates go to both DataBinder and external store.

**Cause**: Automatic binding conflicts with external state management.

**Solution**: Opt out of automatic binding:

```swift
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: task,
    autoBind: false,  // Opt out
    customFieldView: { fieldName, value, type in
        // Update external store only
    }
)
```

---

## Summary

### Key Points

1. **Automatic by Default**: `DataBinder` is automatically created when `autoBind: true` (default)
2. **Manual Binding Required**: Fields must be manually bound to key paths for full functionality
3. **Opt-Out Available**: Set `autoBind: false` to disable automatic binding
4. **Explicit Override**: Providing your own `dataBinder` overrides automatic creation
5. **Backward Compatible**: Existing code continues to work without changes

### Best Practices

- ✅ **Use automatic binding** for standard edit forms with mutable models
- ✅ **Manually bind fields** using key paths for full functionality
- ✅ **Opt out** for read-only forms, immutable models, or external state management
- ✅ **Create your own binder** if you need to access it (check changes, dirty state, etc.)
- ✅ **Test thoroughly** to ensure binding works for your specific use case

### When in Doubt

If you're unsure whether to use automatic binding:

1. **Try it first**: Use default behavior (`autoBind: true`)
2. **Test thoroughly**: Verify model updates work correctly
3. **Opt out if needed**: Set `autoBind: false` if you encounter issues
4. **Provide explicit binder**: Create your own if you need more control

---

**Related Documentation**:
- [DataBinder API Reference](../Sources/Core/Models/DataBinding.swift)
- [IntelligentFormView Guide](./IntelligentFormViewGuide.md)
- [Field Hints Guide](./FieldHintsGuide.md)

