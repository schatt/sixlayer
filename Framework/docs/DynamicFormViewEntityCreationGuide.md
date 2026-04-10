# DynamicFormView Entity Creation Guide

## Overview

`DynamicFormView` can automatically create Core Data or SwiftData entities from form values when `modelName` is provided. This makes it easy to build forms that create new objects without manual entity creation code.

**Key Principle**: The distinction between `IntelligentFormView` and `DynamicFormView` is about **layout control**, not entity creation. Both can create entities automatically.

## Quick Start

### Core Data Example

```swift
struct CreateUserView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        DynamicFormView(
            configuration: DynamicFormConfiguration(
                id: "create-user",
                title: "Create User",
                sections: [
                    DynamicFormSection(
                        id: "info",
                        title: "User Information",
                        fields: [
                            DynamicFormField(id: "name", contentType: .text, label: "Name"),
                            DynamicFormField(id: "email", contentType: .email, label: "Email")
                        ]
                    )
                ],
                modelName: "User"  // Entity name for Core Data
            ),
            onSubmit: { values in
                // Dictionary of form values (always called)
                print("Form values: \(values)")
            },
            onEntityCreated: { entity in
                // Created Core Data entity (optional)
                if let user = entity as? NSManagedObject {
                    print("Created user: \(user)")
                }
            }
        )
    }
}
```

### SwiftData Example

```swift
import SwiftData

@Model
class User: Codable {
    var name: String
    var email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

struct CreateUserView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        DynamicFormView(
            configuration: DynamicFormConfiguration(
                id: "create-user",
                title: "Create User",
                sections: [
                    DynamicFormSection(
                        id: "info",
                        title: "User Information",
                        fields: [
                            DynamicFormField(id: "name", contentType: .text, label: "Name"),
                            DynamicFormField(id: "email", contentType: .email, label: "Email")
                        ]
                    )
                ],
                modelName: "User"
            ),
            onSubmit: { values in
                // Dictionary of form values (always called)
                print("Form values: \(values)")
            },
            onEntityCreated: { entity in
                // Created SwiftData entity (optional)
                if let user = entity as? User {
                    print("Created user: \(user)")
                }
            },
            entityType: User.self  // Required for SwiftData
        )
    }
}
```

## How It Works

1. **Form Collection**: User fills out the form (existing behavior)
2. **On Submit**: 
   - Always calls `onSubmit` with dictionary of values (backward compatible)
   - If `modelName` is provided, attempts to create entity
   - If entity created successfully, calls `onEntityCreated` callback
3. **Entity Creation**:
   - **Core Data**: Uses `NSEntityDescription.insertNewObject` and KVC
   - **SwiftData**: Uses Codable JSON encoding/decoding (requires `T: Codable`)

## Requirements

### Core Data

- **Automatic**: Works automatically when `modelName` is provided
- **No Codable Required**: Uses Key-Value Coding (KVC)
- **Context**: Requires `@Environment(\.managedObjectContext)`

### SwiftData

- **Requires `entityType`**: Must provide `entityType: User.self` parameter
- **Requires Codable**: Your SwiftData model must conform to `Codable`
- **Context**: Requires `@Environment(\.modelContext)`

**Why Codable?**: Swift doesn't support dynamic memberwise initialization at runtime. Codable allows us to encode form values to JSON, then decode to your entity type.

## Error Handling

**NEW in v6.1.0**: Error handling callback for entity creation failures:

```swift
DynamicFormView(
    configuration: config,
    onSubmit: { values in
        // Always called
    },
    onEntityCreated: { entity in
        // Called if entity created successfully
    },
    onError: { error in
        // Called if validation, entity creation, or save fails
        print("Error: \(error.localizedDescription)")
        
        // Check error type
        if let nsError = error as NSError? {
            if nsError.domain == "DynamicFormView" && nsError.code == 1 {
                // Validation error
                if let fieldErrors = nsError.userInfo["fieldErrors"] as? [String: [String]] {
                    // Display field-specific errors to user
                }
            }
        }
    }
)
```

### Error Scenarios

- **Validation Fails**: Form has validation errors (fieldErrors in userInfo)
- **Entity Creation Fails**: Invalid entity name, missing context, Codable decode failure
- **Save Fails**: Core Data/SwiftData save errors, constraint violations
- **Automatic Rollback**: Entity is automatically deleted if save fails

### Error Handling Flow

1. **Validation Check**: Form state is validated first
   - If validation fails → `onError` called with validation error
   - Entity is NOT created
   
2. **Entity Creation**: If validation passes, entity is created
   - If creation fails → `onError` called, no entity created
   
3. **Save**: Entity is saved to context
   - If save fails → Entity is deleted (rollback), `onError` called

## Validation

**NEW in v6.1.0**: Form validation before entity creation:

```swift
// Form state validation is checked before entity creation
// If validation fails, entity is not created and onError is called
```

The framework:
1. Validates form values using `DynamicFormState.isValid` property
2. Only creates entity if validation passes (`formState.isValid == true`)
3. Calls `onError` with validation error if validation fails
4. Includes `fieldErrors` in error userInfo for field-specific error display

## Backward Compatibility

**Always Maintained**: The `onSubmit` callback is **always** called with a dictionary of form values, even when entity creation is enabled. This ensures existing code continues to work:

```swift
// This code continues to work - onSubmit always called
DynamicFormView(
    configuration: config,
    onSubmit: { values in
        // Manual entity creation (existing pattern)
        let user = createUser(from: values)
    }
)
```

## Complete Example

### Core Data with Error Handling

```swift
struct CreateUserView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
            
            DynamicFormView(
                configuration: DynamicFormConfiguration(
                    id: "create-user",
                    title: "Create User",
                    sections: [
                        DynamicFormSection(
                            id: "info",
                            title: "User Information",
                            fields: [
                                DynamicFormField(
                                    id: "name",
                                    contentType: .text,
                                    label: "Name",
                                    isRequired: true
                                ),
                                DynamicFormField(
                                    id: "email",
                                    contentType: .email,
                                    label: "Email",
                                    isRequired: true
                                )
                            ]
                        )
                    ],
                    modelName: "User"
                ),
                onSubmit: { values in
                    // Always called - backward compatible
                    print("Form submitted with values: \(values)")
                },
                onEntityCreated: { entity in
                    // Success - entity created
                    errorMessage = nil
                    print("User created successfully")
                },
                onError: { error in
                    // Error handling
                    errorMessage = error.localizedDescription
                }
            )
        }
    }
}
```

## Best Practices

1. **Always Provide `modelName`**: Enables automatic entity creation
2. **Use Hints Files**: Create `.hints` files for your models to get type information
3. **Handle Errors**: Provide `onError` callback for user feedback
4. **Validate**: Use form field validation to prevent invalid data
5. **Backward Compatible**: Keep using `onSubmit` for manual entity creation if preferred

## Comparison: IntelligentFormView vs DynamicFormView

| Feature | IntelligentFormView | DynamicFormView |
|---------|-------------------|----------------|
| **Layout Control** | Automatic (framework decides) | Manual (you control sections/fields) |
| **Entity Creation** | ✅ Supported | ✅ Supported |
| **Type-Only Forms** | ✅ Supported | ⚠️ Requires hints |
| **Hints-First** | ✅ Supported | ✅ Supported |
| **Use Case** | Quick forms from types | Custom layouts, complex forms |

**Key Insight**: Both views support entity creation. Choose based on how much control you want over layout, not based on entity creation capabilities.

## Core Data Edit Sessions with Child Contexts

Sometimes you want more control than automatic entity creation provides—especially for **edit flows** where you:

- Need to pre‑populate a form from an existing entity
- Want to isolate edits in a **child context** until the user taps Save
- Prefer to keep **all Core Data specifics out of SixLayer** and in your own helpers

This section shows a recommended pattern:

- A small **edit‑session helper** that prepares a child context and entity
- A SwiftUI **host view** that wires `Core Data ⇄ DynamicFormState ⇄ DynamicFormView`
- Two identity variants:
  - **Core Data–centric**: `NSManagedObjectID` only (shortest reopen code)
  - **App‑level identity**: `UUID` property you can use outside Core Data

### Variant A: NSManagedObjectID-Only Identity (Shortest Reopen Code)

Use this when your feature is mostly Core Data–centric and you are happy to pass `NSManagedObjectID` around inside your app.

**Edit-session helper**

```swift
import CoreData

final class Expense: NSManagedObject {
    @NSManaged var date: Date?
    @NSManaged var amount: NSNumber?
    @NSManaged var notes: String?
}

struct EditExpenseSession {
    let context: NSManagedObjectContext
    let expense: Expense
}

enum EditExpenseError: Error {
    case notFound
}

@MainActor
func makeEditExpenseSession(
    parentContext: NSManagedObjectContext,
    existingID: NSManagedObjectID?
) throws -> EditExpenseSession {
    let child = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    child.parent = parentContext
    child.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

    if let existingID {
        // Edit flow: fetch into child context
        guard let existing = try child.existingObject(with: existingID) as? Expense else {
            throw EditExpenseError.notFound
        }
        return EditExpenseSession(context: child, expense: existing)
    } else {
        // Add flow: create new entity in child context
        let newExpense = Expense(context: child)
        newExpense.date = Date()
        return EditExpenseSession(context: child, expense: newExpense)
    }
}
```

**SwiftUI host view wiring Core Data ⇄ DynamicForm**

```swift
import SwiftUI
import CoreData
import SixLayerFramework

struct EditExpenseHostView: View {
    let parentContext: NSManagedObjectContext
    let existingID: NSManagedObjectID?
    let onFinished: () -> Void

    @State private var session: EditExpenseSession?
    @State private var errorMessage: String?
    @State private var saveErrorMessage: String?

    @StateObject private var formState: DynamicFormState

    init(
        parentContext: NSManagedObjectContext,
        existingID: NSManagedObjectID?,
        onFinished: @escaping () -> Void
    ) {
        self.parentContext = parentContext
        self.existingID = existingID
        self.onFinished = onFinished

        let config = DynamicFormConfiguration(
            id: "editExpense",
            title: "Edit Expense",
            sections: [
                DynamicFormSection(
                    id: "main",
                    title: "",
                    fields: [
                        DynamicFormField(
                            id: "date",
                            contentType: .date,
                            label: "Date",
                            isRequired: true,
                            supportsOCR: false
                        ),
                        DynamicFormField(
                            id: "amount",
                            contentType: .decimal,
                            label: "Amount",
                            isRequired: true,
                            supportsOCR: true
                        ),
                        DynamicFormField(
                            id: "notes",
                            contentType: .text,
                            label: "Notes",
                            isRequired: false,
                            supportsOCR: true
                        )
                    ]
                )
            ]
        )
        _formState = StateObject(wrappedValue: DynamicFormState(configuration: config))
    }

    var body: some View {
        Group {
            if let session {
                DynamicFormView(formState: formState)
                    .environment(\.managedObjectContext, session.context)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                session.context.reset()
                                onFinished()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task { await save() }
                            }
                        }
                    }
                    .onAppear { populateForm(from: session.expense) }
                    .alert("Error Saving", isPresented: .constant(saveErrorMessage != nil)) {
                        Button("OK") { saveErrorMessage = nil }
                    } message: {
                        Text(saveErrorMessage ?? "")
                    }
            } else if let errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ProgressView()
                    .onAppear { startSession() }
            }
        }
    }

    @MainActor
    private func startSession() {
        do {
            let newSession = try makeEditExpenseSession(
                parentContext: parentContext,
                existingID: existingID
            )
            session = newSession
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension EditExpenseHostView {
    private func populateForm(from expense: Expense) {
        formState.setValue(expense.date ?? Date(), forFieldID: "date")

        if let amount = expense.amount?.decimalValue {
            formState.setValue(amount, forFieldID: "amount")
        }

        formState.setValue(expense.notes ?? "", forFieldID: "notes")
    }

    @MainActor
    private func save() async {
        guard let session else { return }
        let context = session.context
        let expense = session.expense

        // Validate form using SixLayer’s validation API.
        guard formState.validateAllFields() else {
            return
        }

        // Read values from form.
        let date = (formState.value(forFieldID: "date") as? Date) ?? Date()
        let amount = formState.decimalValue(forFieldID: "amount") ?? 0
        let notes = (formState.value(forFieldID: "notes") as? String) ?? ""

        expense.date = date
        expense.amount = NSDecimalNumber(decimal: amount)
        expense.notes = notes

        do {
            // Save child, then parent so changes are visible to the rest of the app.
            try context.save()
            try parentContext.save()
            onFinished()
        } catch {
            context.rollback()
            saveErrorMessage = "We couldn’t save your changes. Please try again."
        }
    }
}
```

### Variant B: UUID App-Level Identity (Lookup via Fetch)

Use this when you want an **app‑level identifier** you can pass around outside Core Data (e.g. in URLs, deep links, syncing). The pattern is the same; only the identity changes.

**Edit-session helper using UUID**

```swift
import CoreData

final class Expense: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var amount: NSNumber?
    @NSManaged var notes: String?
}

struct EditExpenseSession {
    let context: NSManagedObjectContext
    let expense: Expense
}

enum EditExpenseError: Error {
    case notFound
}

@MainActor
func makeEditExpenseSession(
    parentContext: NSManagedObjectContext,
    existingID: UUID?
) throws -> EditExpenseSession {
    let child = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    child.parent = parentContext
    child.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

    if let existingID {
        // Edit flow: fetch by UUID into child context
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", existingID as CVarArg)

        guard let existing = try child.fetch(request).first else {
            throw EditExpenseError.notFound
        }

        return EditExpenseSession(context: child, expense: existing)
    } else {
        // Add flow: create new entity in child context
        let newExpense = Expense(context: child)
        newExpense.id = UUID()
        newExpense.date = Date()
        return EditExpenseSession(context: child, expense: newExpense)
    }
}
```

**Host view (same pattern, UUID identity)**

```swift
import SwiftUI
import CoreData
import SixLayerFramework

struct EditExpenseHostView: View {
    let parentContext: NSManagedObjectContext
    let existingID: UUID?
    let onFinished: () -> Void

    @State private var session: EditExpenseSession?
    @State private var errorMessage: String?
    @State private var saveErrorMessage: String?

    @StateObject private var formState: DynamicFormState

    init(
        parentContext: NSManagedObjectContext,
        existingID: UUID?,
        onFinished: @escaping () -> Void
    ) {
        self.parentContext = parentContext
        self.existingID = existingID
        self.onFinished = onFinished

        let config = DynamicFormConfiguration(
            id: "editExpense",
            title: "Edit Expense",
            sections: [
                DynamicFormSection(
                    id: "main",
                    title: "",
                    fields: [
                        DynamicFormField(
                            id: "date",
                            contentType: .date,
                            label: "Date",
                            isRequired: true,
                            supportsOCR: false
                        ),
                        DynamicFormField(
                            id: "amount",
                            contentType: .decimal,
                            label: "Amount",
                            isRequired: true,
                            supportsOCR: true
                        ),
                        DynamicFormField(
                            id: "notes",
                            contentType: .text,
                            label: "Notes",
                            isRequired: false,
                            supportsOCR: true
                        )
                    ]
                )
            ]
        )
        _formState = StateObject(wrappedValue: DynamicFormState(configuration: config))
    }

    var body: some View {
        Group {
            if let session {
                DynamicFormView(formState: formState)
                    .environment(\.managedObjectContext, session.context)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                session.context.reset()
                                onFinished()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task { await save() }
                            }
                        }
                    }
                    .onAppear { populateForm(from: session.expense) }
                    .alert("Error Saving", isPresented: .constant(saveErrorMessage != nil)) {
                        Button("OK") { saveErrorMessage = nil }
                    } message: {
                        Text(saveErrorMessage ?? "")
                    }
            } else if let errorMessage {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ProgressView()
                    .onAppear { startSession() }
            }
        }
    }

    @MainActor
    private func startSession() {
        do {
            let newSession = try makeEditExpenseSession(
                parentContext: parentContext,
                existingID: existingID
            )
            session = newSession
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension EditExpenseHostView {
    private func populateForm(from expense: Expense) {
        formState.setValue(expense.date ?? Date(), forFieldID: "date")

        if let amount = expense.amount?.decimalValue {
            formState.setValue(amount, forFieldID: "amount")
        }

        formState.setValue(expense.notes ?? "", forFieldID: "notes")
    }

    @MainActor
    private func save() async {
        guard let session else { return }
        let context = session.context
        let expense = session.expense

        guard formState.validateAllFields() else {
            return
        }

        let date = (formState.value(forFieldID: "date") as? Date) ?? Date()
        let amount = formState.decimalValue(forFieldID: "amount") ?? 0
        let notes = (formState.value(forFieldID: "notes") as? String) ?? ""

        expense.date = date
        expense.amount = NSDecimalNumber(decimal: amount)
        expense.notes = notes

        do {
            try context.save()
            try parentContext.save()
            onFinished()
        } catch {
            context.rollback()
            saveErrorMessage = "We couldn’t save your changes. Please try again."
        }
    }
}
```

### Choosing an Identity Style

- **Core Data–centric identity (NSManagedObjectID only)**:
  - Shortest possible “reopen this object in a child context” code
  - Great for features that live entirely inside Core Data and SwiftUI
- **App‑level identity (UUID)**:
  - Stable identifier you can pass through URLs, deep links, sync payloads, etc.
  - One extra fetch to resolve `UUID → Expense` inside the child context

The SixLayer pattern is the same in both cases: keep **Core Data helpers** like `makeEditExpenseSession` on your side of the app boundary, and use `DynamicFormState` + `DynamicFormView` purely for form layout, validation, and interaction.

## Related Documentation

- [Field Hints Guide](FieldHintsGuide.md) - Creating hints files
- [Fully Declarative Hints](FieldHintsGuide.md#fully-declarative-hints-type-only-form-generation) - Type-only form generation
- [IntelligentFormView Guide](IntelligentFormViewAutoBindingGuide.md) - Automatic form generation
