# Form Auto-Save and Draft Functionality Guide

## Overview

The SixLayer Framework provides comprehensive auto-save and draft functionality for both `DynamicFormView` and `IntelligentFormView`. This ensures users never lose their work when navigating away or closing the app.

**Implements**: Issue #80

## Features

### DynamicFormView Auto-Save
- **Periodic Auto-Save**: Form state is automatically saved every 30 seconds (configurable)
- **Change-Based Auto-Save**: Form state is saved when field values change (debounced, 2 seconds default)
- **Draft Restoration**: Drafts are automatically loaded when forms appear
- **Draft Management**: Save, load, and clear drafts programmatically

### IntelligentFormView Entity Auto-Save
- **Entity Auto-Save**: Core Data and SwiftData entities are saved periodically
- **Draft Entity Tracking**: New entities are marked as drafts until submitted
- **Draft Entity Cleanup**: Draft entities are deleted on cancel if never submitted

## Quick Start

### DynamicFormView Auto-Save

Auto-save is enabled by default. No additional configuration is required:

```swift
struct MyFormView: View {
    var body: some View {
        DynamicFormView(
            configuration: DynamicFormConfiguration(
                id: "my-form",
                title: "My Form",
                sections: [
                    DynamicFormSection(
                        id: "info",
                        title: "Information",
                        fields: [
                            DynamicFormField(id: "name", contentType: .text, label: "Name"),
                            DynamicFormField(id: "email", contentType: .email, label: "Email")
                        ]
                    )
                ]
            ),
            onSubmit: { values in
                // Form submitted - draft is automatically cleared
                print("Submitted: \(values)")
            }
        )
        // Auto-save happens automatically:
        // - Loads draft on appear
        // - Saves periodically (every 30 seconds)
        // - Saves on field changes (debounced)
        // - Saves on disappear
        // - Clears draft on submit
    }
}
```

### IntelligentFormView Entity Auto-Save

Entity auto-save is enabled by default for Core Data and SwiftData entities:

```swift
struct CreateTaskView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        IntelligentFormView.generateForm(
            for: Task.self,
            initialData: nil, // Creates new entity
            onSubmit: { task in
                // Entity is auto-saved before this callback
                // Draft flag is cleared on submit
                print("Task created: \(task)")
            },
            onCancel: {
                // Draft entity is deleted if never submitted
            }
        )
        // Entity auto-save happens automatically:
        // - Entity is saved periodically (every 30 seconds)
        // - Entity is marked as draft if new
        // - Draft flag is cleared on submit
        // - Draft entity is deleted on cancel
    }
}
```

## Configuration

### Customize Auto-Save Interval

```swift
let formState = DynamicFormState(configuration: config)
formState.autoSaveInterval = 60.0 // Save every 60 seconds instead of 30
formState.debounceDelay = 3.0 // Wait 3 seconds after last change instead of 2
```

### Disable Auto-Save

```swift
let formState = DynamicFormState(configuration: config)
formState.autoSaveEnabled = false // Disable auto-save
```

### Custom Storage

```swift
let customStorage = UserDefaultsFormStateStorage(
    userDefaults: UserDefaults(suiteName: "my-app-group")!,
    keyPrefix: "custom_draft_"
)
let formState = DynamicFormState(configuration: config, storage: customStorage)
```

### IntelligentFormView Auto-Save Configuration

```swift
IntelligentFormView.generateForm(
    for: entity,
    autoSaveInterval: 60.0, // Save every 60 seconds (default: 30.0)
    isDraft: true, // Mark entity as draft
    onUpdate: { entity in
        // Entity is auto-saved periodically
    }
)

// Disable auto-save
IntelligentFormView.generateForm(
    for: entity,
    autoSaveInterval: 0, // Disable auto-save
    onUpdate: { entity in
        // No automatic saves
    }
)
```

## Advanced Usage

### Manual Draft Management

```swift
let formState = DynamicFormState(configuration: config)

// Save draft manually
formState.saveDraft()

// Load draft manually
if formState.loadDraft() {
    print("Draft loaded")
}

// Check if draft exists
if formState.hasDraft() {
    print("Draft exists")
}

// Clear draft manually
formState.clearDraft()
```

### Multiple Forms with Separate Drafts

Each form maintains its own draft based on the form `id`:

```swift
let form1 = DynamicFormConfiguration(id: "form-1", title: "Form 1", sections: [])
let form2 = DynamicFormConfiguration(id: "form-2", title: "Form 2", sections: [])

// Each form has its own draft
let state1 = DynamicFormState(configuration: form1)
let state2 = DynamicFormState(configuration: form2)

// Drafts are stored separately
state1.setValue("value1", for: "field1")
state1.saveDraft()

state2.setValue("value2", for: "field1")
state2.saveDraft()

// Each draft is independent
```

### Optional draft storage key (Issue #273)

Draft persistence is keyed separately from **field values** and from **form definition identity**.

| Concept | Role |
|--------|------|
| `DynamicFormConfiguration.id` | Stable form definition identity (schema, labels, sections). |
| `draftStorageKey` | Optional UserDefaults draft **bucket** for `saveDraft`, `loadDraft`, `clearDraft`, and `hasDraft`. |
| Resolved persistence id | Non-empty `draftStorageKey` if provided; otherwise `configuration.id`. |

`draftStorageKey` is fixed for the lifetime of the `DynamicFormState` instance (v1 does not support changing it after init). Passing `nil` or `""` uses `configuration.id`, same as omitting the parameter.

Use this when multiple screens share one configuration but must not share drafts—for example add vs edit using the same form JSON:

```swift
let sharedConfig = DynamicFormConfiguration(id: "fuel-entry", title: "Fuel", sections: [...])

let addState = DynamicFormState(
    configuration: sharedConfig,
    draftStorageKey: "fuel-entry-add"
)
let editState = DynamicFormState(
    configuration: sharedConfig,
    draftStorageKey: "fuel-entry-edit"
)
// addState and editState persist under different keys despite the same configuration.id
```

**Not covered here:** how individual field values are typed in `fieldValues` (e.g. `Double` vs `String` for number fields). See [Number and integer field values](#number-and-integer-field-values-issue-289) below.

### Number and integer field values (Issue #289)

`DynamicNumberField` and `DynamicIntegerField` bind to a `TextField` and **store `String` on edit**. On read, they also accept `Int`, `Double`, or `NSNumber` in `fieldValues` (common when hosts prefill from Core Data or DTOs) and format them for display.

Prefer `String` when you control the host mapping; numeric types are tolerated on read so prefilled forms do not render blank.

### Draft Entity Management

For IntelligentFormView, draft entities are automatically handled:

```swift
// Creating a new entity (marked as draft)
IntelligentFormView.generateForm(
    for: Task.self,
    initialData: nil,
    isDraft: true, // Explicitly mark as draft
    onSubmit: { task in
        // Draft flag is cleared on submit
        // Entity is now "saved" (not a draft)
    },
    onCancel: {
        // Draft entity is deleted if never submitted
    }
)
```

## Storage Details

### Default Storage

By default, drafts are stored in `UserDefaults` with the key prefix `"form_draft_"`. The storage key is `"form_draft_{formId}"` where `{formId}` is the resolved persistence id (`draftStorageKey` when non-empty, otherwise `configuration.id`).

### Storage Protocol

You can implement custom storage by conforming to `FormStateStorage`:

```swift
protocol FormStateStorage {
    func saveDraft(_ draft: FormDraft) throws
    func loadDraft(formId: String) -> FormDraft?
    func clearDraft(formId: String) throws
    func hasDraft(formId: String) -> Bool
}
```

### Draft Model

Drafts are stored as `FormDraft` objects:

```swift
struct FormDraft: Codable {
    let formId: String
    let fieldValues: [String: AnyCodable]
    let timestamp: Date
    let metadata: [String: String]?
}
```

## Best Practices

### 1. Use Appropriate Form IDs

Form IDs should be unique and stable:

```swift
// Good: Stable, unique ID
DynamicFormConfiguration(id: "user-profile-edit", ...)

// Bad: Unstable ID
DynamicFormConfiguration(id: UUID().uuidString, ...)
```

### 2. Clear Drafts After Successful Submit

Drafts are automatically cleared on submit, but you can also clear manually:

```swift
onSubmit: { values in
    // Process submission
    saveToDatabase(values)
    
    // Draft is automatically cleared, but you can also clear manually
    formState.clearDraft()
}
```

### 3. Handle Storage Errors Gracefully

Storage errors are logged but don't crash the app. You can add custom error handling:

```swift
do {
    try formState.saveDraft()
} catch {
    // Handle error (e.g., show user notification)
    print("Failed to save draft: \(error)")
}
```

### 4. Consider Privacy for Sensitive Data

For sensitive fields (passwords, etc.), consider excluding them from auto-save or using encrypted storage:

```swift
// Exclude sensitive fields from draft
let draft = FormDraft(
    formId: formId,
    fieldValues: fieldValues.filter { key, _ in
        !sensitiveFields.contains(key)
    }
)
```

## Troubleshooting

### Draft Not Loading

- Verify the form `id` matches between save and load
- Check that storage is accessible (UserDefaults permissions)
- Verify draft exists: `formState.hasDraft()`

### Auto-Save Not Working

- Check `autoSaveEnabled` is `true` (default)
- Verify `autoSaveInterval > 0` (default: 30.0)
- Check that form appears/disappears correctly (onAppear/onDisappear)

### Entity Not Auto-Saving

- Verify entity is Core Data or SwiftData (auto-save only works for these)
- Check that `autoSaveInterval > 0`
- Verify context is accessible

## Related Documentation

- [DynamicFormView Entity Creation Guide](DynamicFormViewEntityCreationGuide.md)
- [IntelligentFormView Auto Binding Guide](IntelligentFormViewAutoBindingGuide.md)
- [Form UI Patterns Analysis](../../Development/FORM_UI_PATTERNS_ANALYSIS.md)

## API Reference

### DynamicFormState

- `init(configuration:draftStorageKey:storage:)` - Optional `draftStorageKey` for draft bucket (Issue #273)
- `startAutoSave(interval:)` - Start periodic auto-save
- `stopAutoSave()` - Stop auto-save timer
- `saveDraft()` - Save current state as draft
- `loadDraft() -> Bool` - Load draft if it exists
- `clearDraft()` - Clear draft
- `hasDraft() -> Bool` - Check if draft exists
- `triggerDebouncedSave()` - Trigger debounced save on field change

### IntelligentFormView

- `generateForm(for:autoSaveInterval:isDraft:...)` - Generate form with auto-save
- `handleSubmit(initialData:isDraft:...)` - Handle submit with draft flag clearing

### FormStateStorage

- `saveDraft(_:)` - Save draft
- `loadDraft(formId:)` - Load draft
- `clearDraft(formId:)` - Clear draft
- `hasDraft(formId:)` - Check if draft exists
