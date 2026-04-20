# Field-Level Display Hints Guide

## Overview

The SixLayer Framework supports field-level display hints that **describe your data**. You create `.hints` files that describe how to present your data models, and 6Layer automatically reads and uses them.

**Key insight**: Hints describe the DATA, so they're stored in `.hints` files that correspond to your data models, not passed in manually.

## How Field Hints Work

### Storage Architecture

Field hints are stored in `.hints` files in a `Hints/` subfolder. The name matches your data model:

```
YourApp/
  Models/
    User.swift                 # Your User data model
    
  Hints/                      # Hints subfolder (created by you)
    User.hints                 # How to present User data
    Product.hints             # How to present Product data
```

### Hints File Format

Create a file named `{YourModelName}.hints` in your project:

**User.hints**:
```json
{
  "username": {
    "expectedLength": 20,
    "displayWidth": "medium",
    "maxLength": 50,
    "minLength": 3,
    "showCharacterCounter": "false"
  },
  "email": {
    "expectedLength": 30,
    "displayWidth": "wide",
    "maxLength": 255
  },
  "bio": {
    "expectedLength": 500,
    "displayWidth": "wide",
    "maxLength": 1000,
    "showCharacterCounter": "true"
  },
  "postalCode": {
    "expectedLength": 10,
    "displayWidth": "narrow",
    "maxLength": 10
  },
  "sizeUnit": {
    "displayWidth": "medium",
    "expectedLength": 15,
    "inputType": "picker",
    "options": [
      {"value": "story_points", "label": "Story Points"},
      {"value": "hours", "label": "Hours"},
      {"value": "days", "label": "Days"},
      {"value": "weeks", "label": "Weeks"},
      {"value": "t_shirt", "label": "T-Shirt Size"}
    ]
  }
}
```

**NEW in v5.4.0**: You can also include OCR hints and calculation groups in hints files!  
**NEW in v5.7.1**: Value range validation for OCR-extracted numeric fields!  
**NEW in v5.8.0**: Picker options for enum fields with human-readable labels!  
**NEW in v5.8.0**: Automatic DataBinder creation for real-time model updates!  

See the [Hints File OCR and Calculations Guide](HintsFileOCRAndCalculationsGuide.md) for complete documentation.  
See the [IntelligentFormView Auto-Binding Guide](IntelligentFormViewAutoBindingGuide.md) for automatic data binding documentation.

### Using Field Hints

#### 1. Create Your Data Model

```swift
// User.swift
struct User {
    let username: String
    let email: String
    let bio: String?
    let postalCode: String
}
```

#### 2. Create the Hints File in Hints/ Folder

Create a `Hints/` folder in your project and add `User.hints`:

```
YourApp/
  Models/
    User.swift
  Hints/
    User.hints      <- 6Layer reads this automatically
```

**Note**: Add the `Hints/` folder to your Xcode project and include the `.hints` files in your target.

#### 3. Use 6Layer with Model Name

6Layer automatically reads the .hints file:

```swift
struct CreateUserView: View {
    let fields = createUserFields()
    
    var body: some View {
        // Pass modelName to tell 6Layer which .hints file to read
        platformPresentFormData_L1(
            fields: fields,
            hints: EnhancedPresentationHints(
                dataType: .form,
                presentationPreference: .form,
                context: .create
            ),
            modelName: "User"  // 6Layer reads User.hints automatically!
        )
    }
}
```

#### 4. That's It!

6Layer automatically:
- Reads the `User.hints` file
- Applies display widths to each field
- Uses expected lengths for sizing
- Shows character counters when configured
- Creates a `DataBinder` for real-time model updates (v5.8.0+)

**No manual hint passing needed!** The hints describe your data model.

**📚 Data Binding**: For information about automatic `DataBinder` creation and real-time model updates, see the [IntelligentFormView Auto-Binding Guide](IntelligentFormViewAutoBindingGuide.md).

## Field Hints Properties

### `FieldDisplayHints` Structure

```swift
public struct FieldDisplayHints: Sendable {
    /// Expected maximum length (for display sizing)
    public let expectedLength: Int?
    
    /// Display width: "narrow", "medium", "wide", or numeric value
    public let displayWidth: String?
    
    /// Whether to show a character counter
    public let showCharacterCounter: Bool
    
    /// Maximum allowed length (for validation)
    public let maxLength: Int?
    
    /// Minimum allowed length (for validation)
    public let minLength: Int?
    
    /// Expected value range for numeric fields (for OCR validation) (NEW in v5.7.1)
    /// When specified, OCR-extracted numeric values outside this range will be filtered out
    /// Format: {"min": 5.0, "max": 30.0} in hints files
    public let expectedRange: ValueRange?
    
    /// Additional metadata
    public let metadata: [String: String]
    
    /// OCR hints for field identification (NEW in v5.4.0)
    public let ocrHints: [String]?
    
    /// Calculation groups for computing field values (NEW in v5.4.0)
    public let calculationGroups: [CalculationGroup]?
}
```

**📚 For complete OCR hints, calculation groups, and value ranges documentation, see:**
- **[Hints File OCR and Calculations Guide](HintsFileOCRAndCalculationsGuide.md)** - Complete guide to OCR hints, calculations, and value ranges in hints files

## Fully Declarative Hints (Type-Only Form Generation)

**NEW in v6.1.0**: You can now make hints fully declarative by adding type information. This enables **type-only form generation** - creating forms without requiring instance data.

### What Are Fully Declarative Hints?

Fully declarative hints include type information (`fieldType`, `isOptional`, `isArray`, `defaultValue`) that allows the framework to generate forms from hints alone, without needing to examine actual data instances using Mirror reflection.

### Benefits

- **Type-Only Forms**: Generate forms without creating instance data
- **Self-Documenting**: Hints become complete data schemas
- **Better Control**: Explicitly define what fields exist and their types
- **Code Generation**: Use hints as source of truth for documentation/tools
- **Performance**: Skip Mirror reflection when hints are complete

### Making Hints Fully Declarative

Add type information to your hints:

```json
{
  "username": {
    "fieldType": "string",        // NEW: Field type
    "isOptional": false,           // NEW: Whether field can be nil
    "isArray": false,              // NEW: Whether field is an array
    "defaultValue": null,          // NEW: Default value (optional)
    "expectedLength": 20,
    "displayWidth": "medium",
    "maxLength": 50
  },
  "email": {
    "fieldType": "string",
    "isOptional": true,
    "displayWidth": "wide"
  },
  "age": {
    "fieldType": "number",
    "isOptional": false,
    "expectedRange": {"min": 0, "max": 120},
    "displayWidth": "narrow"
  },
  "isActive": {
    "fieldType": "boolean",
    "isOptional": false,
    "defaultValue": true
  },
  "tags": {
    "fieldType": "string",
    "isArray": true,
    "displayWidth": "wide"
  }
}
```

### Field Type Values

The `fieldType` property supports:
- `"string"` - Text fields
- `"number"` - Numeric fields (Int, Double, Float)
- `"boolean"` - Boolean/toggle fields
- `"date"` - Date fields
- `"url"` - URL fields
- `"uuid"` - UUID fields
- `"document"` - Document/file fields
- `"image"` - Image fields
- `"custom"` - Custom types

### When Hints Are Fully Declarative

A hint is **fully declarative** when it has both `fieldType` and `isOptional` specified:

```json
{
  "username": {
    "fieldType": "string",    // ✅ Has fieldType
    "isOptional": false        // ✅ Has isOptional
    // This hint is fully declarative!
  }
}
```

### Hybrid Approach (Mirror Fallback)

The framework uses a **hybrid approach**:
1. **Hints-First**: If hints are fully declarative, use them
2. **Mirror Fallback**: If hints are incomplete or missing, use Mirror reflection
3. **Best of Both**: Automatic by default (Mirror), explicit when needed (hints)

**Example - Partial Hints (Mirror Fallback)**:
```json
{
  "email": {
    "displayWidth": "wide",
    "maxLength": 255
    // No fieldType/isOptional - Mirror will discover it
  }
}
```

### Type-Only Form Generation

With fully declarative hints, you can generate forms without instance data:

```swift
// Generate form from type + hints only (no instance needed)
IntelligentFormView.generateForm(
    for: User.self,        // Type only
    initialData: nil,      // No instance data
    onSubmit: { user in
        // Handle created user
    },
    onCancel: {
        // Handle cancel
    }
)
```

The framework will:
1. Load hints for `User`
2. Verify hints are fully declarative
3. Create a blank entity (Core Data or SwiftData) with defaults from hints
4. Generate form for the new entity

### The `__example` Field

The hints generator (`scripts/generate_hints_from_models.swift`) **rewrites** the top-level `__example` object on every run so it always reflects the **current** set of documented keys and patterns (nested field template, sample `_sections`, sample `_defaults`, and related options). It is not a hand-maintained fragment inside an otherwise frozen file.

Structurally, `__example` mirrors what a hints file can contain: for example a template field entry (under a key such as `__examplefield`) plus illustrative `_sections` and `_defaults`. The exact keys evolve with the script; treat the generated block as the source of truth when adding or editing real field entries.

This field serves as **self-documentation** alongside your real model keys (`username`, `amount`, …).

**Note**: The `__example` key is **ignored during form loading**—it is documentation only.

### Migration Guide

To migrate existing hints to fully declarative:

1. **Add `fieldType`**: Determine the type for each field
2. **Add `isOptional`**: Mark optional fields as `true`, required as `false`
3. **Add `isArray`** (if needed): Mark array/collection fields as `true`
4. **Add `defaultValue`** (optional): Specify default values where appropriate

**Example Migration**:

**Before** (display hints only):
```json
{
  "username": {
    "displayWidth": "medium",
    "maxLength": 50
  }
}
```

**After** (fully declarative):
```json
{
  "username": {
    "fieldType": "string",
    "isOptional": false,
    "displayWidth": "medium",
    "maxLength": 50
  }
}
```

**Backward Compatibility**: Existing hints without type information continue to work - Mirror reflection is used as fallback.

### Using the Hints Generator Tool

The script `scripts/generate_hints_from_models.swift` builds or updates `{ModelName}.hints` from a **Swift** source file (`-model`) or a **Core Data** model (`-modeld`). Run it with the Swift toolchain, for example:

```bash
swift scripts/generate_hints_from_models.swift \
  -model Models/User.swift \
  -extensionsdir Models \
  -outputdir Hints
```

**Arguments** (see `-h` in the script for the canonical list):

| Flag | Purpose |
|------|---------|
| `-model <path>` | Single `.swift` file that defines (or extends) the model; exactly one of `-model` or `-modeld` is required. |
| `-modeld <path>` | `.xcdatamodel` directory or `.xcdatamodeld` bundle. |
| `-extensionsdir <path>` | Extra directories to search for `extension TypeName` files (Swift only); may be repeated. |
| `-outputdir <path>` | Where to write `.hints` files (default: `Hints` under the current working directory). |

#### Regeneration and merge behavior

When a `.hints` file **already exists**, regeneration is designed around two ideas: **keep author-edited presentation hints**, and **keep type/default alignment with the model** where the script can infer it.

1. **Structural keys (per field)** — If a field object is missing any of these, they are filled from the model: `fieldType`, `isOptional`, `isArray`, `isHidden`, `isEditable`. If the file already sets them, they are **not** overwritten (so you can override generator defaults such as hiding UUIDs).

2. **`defaultValue` (Swift models only)** — If the parser finds a **simple** property initializer (`= literal`) on a stored property, the script **writes `defaultValue` in hints to match that literal** on every run—including when you change the literal in Swift (so hints stay in sync). Supported shapes match the script’s parser (e.g. string, numeric, boolean literals). **If the model has no parseable initializer**, any existing `defaultValue` in the hints file is **left unchanged** (the script does not delete hints-only defaults).

3. **`defaultValue` (Core Data)** — Attributes are emitted with structural fields only; the script does **not** currently map Core Data default strings into `defaultValue` in `.hints`. Set `defaultValue` in JSON by hand if you need it.

4. **Never from the model script** — Keys such as `placeholder`, `expectedLength`, `displayWidth`, picker options, etc. are **only** what you put in JSON (or copy from `__example`). The generator does not infer UX copy or presentation from Swift beyond the structural list above and Swift literal `defaultValue`.

5. **`_sections`** — If the file already defines `_sections`, they are **preserved**. If there are no sections, the script may add a minimal default section listing known fields.

6. **`_defaults`** — If you already have presentation defaults under `_defaults`, they are **preserved**. If the file has no color-related defaults, the script may inject a small **example** block so the feature is discoverable (you can edit or remove it).

7. **`__example`** — **Always replaced** with the script’s current full template so documentation stays up to date.

8. **Field order** — Existing top-level field key order is preserved when possible; **new** properties discovered from the model are appended.

**New files**: If no `.hints` file exists yet, the script creates one with structural entries for each model field, Swift-sourced `defaultValue` when applicable, optional default `_sections` / `_defaults` as above, and `__example`.

#### Swift parser: when something cannot be parsed

The Swift side uses a **regex-based** extractor (not SwiftSyntax). Behavior when the model does not match what the script understands:

| Situation | What the parser does | Effect on `.hints` |
|-----------|----------------------|-------------------|
| **Line does not match** the property pattern (e.g. complex generic type with `<…>`, wrappers/attributes that break the line, `var`/`let` forms outside the supported grammar) | Property is **skipped**—no `FieldInfo` for that name from this file. | That field is **not** updated or added by this parse pass. Any existing JSON entry for the same key is **left as-is** (stale hints are possible if you rename/remove a property and the line no longer matches). |
| **Computed property** (`{` immediately after the type) | Still listed with structural hints; `isEditable` follows ID/computed rules. | No `defaultValue` from Swift (no stored initializer). |
| **`=` present but literal not understood** (e.g. `= UUID()`, `= .red`, `= 1_000`, hex `0xFF`, expressions, multi-line values) | `parseDefaultValue` returns **no value** for that property. | **`defaultValue` in hints is not overwritten**—whatever you already had in JSON stays (including omission). The script does **not** write the raw expression text into hints. |
| **`fieldType` is `date`, `url`, `uuid`, `document`, `image`, or `custom`** | Initializers are **not** parsed into JSON defaults (only `string` / `number` / `boolean` literals are). | Same as row above: no model-driven `defaultValue` update from `= …`. |
| **Number** | Only decimal integer or floating text that `Int`/`Double` can parse. | Unparseable → no model `defaultValue` sync. |
| **Boolean** | Only the tokens `true` and `false`. | Anything else → no model `defaultValue` sync. |
| **String** | Quoted `"…"` content is unescaped into the value; other non-empty text is taken as a single token (limited). | Complex string literals or interpolation are not supported. |

**Practical takeaway**: If the generator ignores a default you care about, set **`defaultValue` (or `placeholder`) explicitly in the `.hints` file**—that remains the source of truth whenever the parser cannot map Swift to JSON.

## Picker Options for Enum Fields

**NEW in v5.8.0**: You can now specify enum fields as pickers with human-readable labels!

### When to Use Pickers

Use pickers when a field represents an enum or a fixed set of values. This provides better UX than requiring users to type raw enum values.

### Picker Configuration

Add `inputType: "picker"` and an `options` array to your field definition:

```json
{
  "sizeUnit": {
    "displayWidth": "medium",
    "expectedLength": 15,
    "inputType": "picker",
    "options": [
      {"value": "story_points", "label": "Story Points"},
      {"value": "hours", "label": "Hours"},
      {"value": "days", "label": "Days"},
      {"value": "weeks", "label": "Weeks"},
      {"value": "t_shirt", "label": "T-Shirt Size"}
    ]
  }
}
```

### How It Works

- **Display**: The picker shows human-readable `label` values (e.g., "Story Points", "Hours")
- **Storage**: The model stores the raw `value` (e.g., "story_points", "hours")
- **Platform Support**: Works on both macOS (menu style) and iOS (menu style)
- **Backward Compatible**: Fields without `inputType` continue to render as TextFields

### DynamicFormField Component Support

**NEW**: All `DynamicFormField` components now automatically understand and respect hints:

- **`DynamicTextField`**: Checks `inputType == "picker"` and renders a picker when `pickerOptions` are available
- **`DynamicSelectField`**: Prefers `pickerOptions` from hints (with labels) over `field.options` (simple strings)
- **`DynamicEnumField`**: Prefers `pickerOptions` from hints (with labels) over `field.options` (simple strings)

Components automatically:
1. Check `displayHints.inputType` and `displayHints.pickerOptions` first
2. Fall back to `field.options` if hints aren't available
3. Use labeled options (`PickerOption.label` for display, `PickerOption.value` for storage) when available

This means you can configure pickers entirely through hints files, and components will automatically use them!

### Example

```swift
struct Task {
    let sizeUnit: String  // Will use picker if hints specify inputType: "picker"
    let name: String      // Will use TextField (default)
}
```

With the hints file above, `sizeUnit` will render as a picker with labels, while `name` remains a text field.

## Display Width Guidelines

### Named Widths

- **`narrow`**: ~150 points (e.g., postal code, phone extension)
- **`medium`**: ~200 points (e.g., username, city)
- **`wide`**: ~400 points (e.g., full name, email, address)

### Numeric Widths

You can specify exact widths:

```json
{
  "customField": {
    "displayWidth": "250"
  }
}
```

## Complete Example

### 1. Create Your Data Model

```swift
// User.swift
struct User: Identifiable {
    let id: UUID
    let username: String
    let email: String
    let bio: String?
    let postalCode: String
}
```

### 2. Create the Hints File

**User.hints**:
```json
{
  "username": {
    "expectedLength": 20,
    "displayWidth": "medium",
    "maxLength": 50,
    "minLength": 3
  },
  "email": {
    "displayWidth": "wide"
  },
  "bio": {
    "displayWidth": "wide",
    "showCharacterCounter": "true"
  },
  "postalCode": {
    "displayWidth": "narrow"
  }
}
```

### 3. Create Your View

```swift
struct CreateUserView: View {
    var body: some View {
        platformPresentFormData_L1(
            fields: createUserFields(),
            hints: EnhancedPresentationHints(
                dataType: .form,
                presentationPreference: .form,
                context: .create
            ),
            modelName: "User"  // 6Layer reads User.hints automatically!
        )
    }
}

func createUserFields() -> [DynamicFormField] {
    [
        DynamicFormField(
            id: "username",
            contentType: .text,
            label: "Username",
            isRequired: true
        ),
        DynamicFormField(
            id: "email",
            contentType: .email,
            label: "Email",
            isRequired: true
        ),
        DynamicFormField(
            id: "bio",
            contentType: .textarea,
            label: "Biography"
        ),
        DynamicFormField(
            id: "postalCode",
            textContentType: .postalCode,
            label: "Postal Code"
        )
    ]
}
```

That's it! 6Layer automatically reads `User.hints` and applies the display properties.

## Integration with DynamicFormField

The framework automatically applies field hints when rendering forms. Simply include hints in your `PresentationHints` and the views will respect the display width and other properties.

### Automatic Hint Recognition

**NEW**: `DynamicFormField` components automatically understand and use hints:

```swift
// Create a field - no need to specify options manually
let field = DynamicFormField(
    id: "sizeUnit",
    contentType: .text,  // Can be .text, .select, or .enum
    label: "Size Unit"
)

// If User.hints contains:
// {
//   "sizeUnit": {
//     "inputType": "picker",
//     "options": [{"value": "story_points", "label": "Story Points"}, ...]
//   }
// }
// Then DynamicTextField will automatically render a picker!
```

**Component Behavior**:
- **`DynamicTextField`**: Automatically renders picker when `inputType == "picker"` in hints
- **`DynamicSelectField`**: Uses `pickerOptions` from hints (preferred) or `field.options` (fallback)
- **`DynamicEnumField`**: Uses `pickerOptions` from hints (preferred) or `field.options` (fallback)

**Hints Priority**: Components prefer hints over direct field configuration:
1. `displayHints.pickerOptions` (from hints file) - **Preferred** (has labels)
2. `field.options` (from code) - **Fallback** (simple strings)

### Using Picker Options in Metadata

You can also provide picker options via metadata (useful for runtime configuration):

```swift
let field = DynamicFormField(
    id: "status",
    contentType: .select,
    label: "Status",
    metadata: [
        "inputType": "picker",
        "pickerOptions": """
        [
            {"value": "draft", "label": "Draft"},
            {"value": "published", "label": "Published"},
            {"value": "archived", "label": "Archived"}
        ]
        """
    ]
)
```

The `displayHints` property automatically parses JSON strings from metadata to create `PickerOption` arrays.

## Benefits

1. **Configuration-Driven**: Hints stored in files, separate from code
2. **Type-Safe**: Strongly-typed FieldDisplayHints structure
3. **Cached**: Registry caches hints for performance
4. **File-Based**: Similar to CoreData models, hints are stored in JSON files
5. **Flexible**: Support for both file-based and runtime configuration

## Deterministic Field Ordering (Explicit Order, Groups, Traits)

You can control the display order of fields in IntelligentFormView.

### Quick Start: Runtime Provider

Install a provider once (e.g., at app launch):

```swift
IntelligentFormView.orderRulesProvider = { analysis in
    let names = Set(analysis.fields.map { $0.name })
    let isTask = ["title","status","priority","sizeUnit","estimatedHours","notes"].allSatisfy { names.contains($0) }
    if isTask {
        let base = FieldOrderRules(
            explicitOrder: ["title","status","priority","sizeUnit","estimatedHours","notes"]
        )
        let compact = FieldOrderRules(explicitOrder: ["title","priority","status"])
        return FieldOrderRules(
            explicitOrder: base.explicitOrder,
            perFieldWeights: base.perFieldWeights,
            groups: base.groups,
            traitOverrides: [.compact: compact]
        )
    }
    return nil // fallback to defaults (title/name first)
}
```

Rules are applied trait-aware (phones -> `.compact`, others -> `.regular`). When no provider returns rules, 6Layer defaults to a sensible order that prioritizes common primary fields like `title` or `name` first.

### API Reference

```swift
public struct FieldGroup: Equatable, Sendable {
    public let id: String
    public let title: String?
    public let fields: [String]
}

public enum FieldTrait: Hashable, Sendable { case compact, regular }

public struct FieldOrderRules: Equatable, Sendable {
    public let explicitOrder: [String]?          // Highest precedence
    public let perFieldWeights: [String: Int]    // Higher weight -> earlier
    public let groups: [FieldGroup]              // Declaration order respected
    public let traitOverrides: [FieldTrait: FieldOrderRules]
}
```

Resolver behavior:
- Sort by explicitOrder when provided; unknown keys are ignored.
- Then append remaining fields by weight (desc), then by name for deterministic tie-break.
- Groups render in declaration order; order within each group follows the same rules.
- Trait overrides replace the base rules for that trait.

Validation helper:

```swift
let (sorted, warnings) = IntelligentFormView.inspectEffectiveOrder(analysis: analysis)
// warnings contains any unknown keys detected in explicitOrder/weights/groups
```

### Using Hints

`EnhancedPresentationHints` includes an optional `fieldOrderRules` to carry deterministic ordering through hints if you prefer to keep ordering near your hint definitions:

```swift
let hints = EnhancedPresentationHints(
    dataType: .form,
    fieldOrderRules: FieldOrderRules(
        explicitOrder: ["title","status","priority"]
    )
)
```

If both hints and the runtime provider are present, your app-level provider can decide priority by merging or preferring one.

## Layout Hints and Section Grouping (NEW in v5.0.0+)

### Overview

Layout hints allow you to define **how groups of fields should be displayed together** and **what layout style to use** for each group. This extends the field-level hints system to include structural organization.

**Key principle**: Layout hints describe **data relationships** - which fields belong together and in what order. They're **hints, not commandments** - the framework adapts layouts responsively based on available space and platform capabilities.

### Hints File Format with Sections

Add a `_sections` array to your `.hints` file to define field groupings and layout styles:

**User.hints**:
```json
{
  "username": {
    "displayWidth": "medium",
    "expectedLength": 20
  },
  "email": {
    "displayWidth": "wide"
  },
  "bio": {
    "displayWidth": "wide",
    "showCharacterCounter": true
  },
  "postalCode": {
    "displayWidth": "narrow"
  },
  "_sections": [
    {
      "id": "basic-info",
      "title": "Basic Information",
      "description": "Enter your account details",
      "fields": ["username", "email"],
      "layoutStyle": "vertical"
    },
    {
      "id": "personal-info",
      "title": "Personal Details",
      "fields": ["bio", "postalCode"],
      "layoutStyle": "horizontal"
    }
  ]
}
```

### Section Properties

Each section in `_sections` supports:

- **`id`** (required): Unique identifier for the section
- **`title`** (required): Section title (used for accessibility)
- **`description`** (optional): Section description text
- **`fields`** (optional): Array of field IDs that belong to this section, in display order
- **`layoutStyle`** (optional): Layout strategy for fields in this section

### Layout Styles

The `layoutStyle` property supports the following values (all are **hints** - the framework adapts):

- **`vertical`** (default): Fields stacked vertically
- **`horizontal`**: Fields displayed side-by-side (2 columns)
- **`grid`**: Adaptive grid layout based on field count
- **`adaptive`**: Framework chooses layout based on field count (vertical for ≤4, horizontal for ≤8, grid for >8)
- **`standard`**, **`compact`**, **`spacious`**: Vertical layouts with different spacing

### Precedence Rules

1. **Explicit LayoutSpec** (highest priority): If you pass a `LayoutSpec` to `platformPresentFormData_L1`, it overrides hints
2. **Hints file `_sections`**: Sections defined in `.hints` file
3. **Framework defaults** (lowest priority): Single default section with all fields

### Complete Example

**User.hints**:
```json
{
  "username": {
    "displayWidth": "medium",
    "expectedLength": 20
  },
  "email": {
    "displayWidth": "wide"
  },
  "bio": {
    "displayWidth": "wide",
    "showCharacterCounter": true
  },
  "phone": {
    "displayWidth": "medium"
  },
  "address": {
    "displayWidth": "wide"
  },
  "postalCode": {
    "displayWidth": "narrow"
  },
  "_sections": [
    {
      "id": "account",
      "title": "Account Information",
      "description": "Your login credentials",
      "fields": ["username", "email"],
      "layoutStyle": "vertical"
    },
    {
      "id": "contact",
      "title": "Contact Information",
      "fields": ["phone", "address", "postalCode"],
      "layoutStyle": "horizontal"
    },
    {
      "id": "profile",
      "title": "Profile",
      "fields": ["bio"],
      "layoutStyle": "vertical"
    }
  ]
}
```

**Usage in Swift**:
```swift
let fields = [
    DynamicFormField(id: "username", contentType: .text, label: "Username"),
    DynamicFormField(id: "email", contentType: .email, label: "Email"),
    DynamicFormField(id: "phone", contentType: .telephoneNumber, label: "Phone"),
    DynamicFormField(id: "address", contentType: .text, label: "Address"),
    DynamicFormField(id: "postalCode", textContentType: .postalCode, label: "Postal Code"),
    DynamicFormField(id: "bio", contentType: .textarea, label: "Biography")
]

platformPresentFormData_L1(
    fields: fields,
    hints: EnhancedPresentationHints(
        dataType: .form,
        context: .create
    ),
    modelName: "User"  // Loads User.hints with _sections automatically!
)
```

### Programmatic Override with LayoutSpec

For special cases where you need to override hints programmatically:

```swift
let customLayout = LayoutSpec(sections: [
    DynamicFormSection(
        id: "custom-section",
        title: "Custom Layout",
        fields: [fields[0], fields[1]],
        layoutStyle: .grid
    )
])

platformPresentFormData_L1(
    fields: fields,
    hints: EnhancedPresentationHints(...),
    modelName: "User",
    layoutSpec: customLayout  // Overrides hints file sections
)
```

### Missing Fields Handling

If a section references a field ID that doesn't exist in your form fields:
- A warning is logged to the console
- The missing field is ignored
- The section is created with the remaining valid fields

This provides graceful degradation - your hints file can reference fields that aren't always present.

### Field Order Preservation

Fields within a section are displayed **in the order specified in the `fields` array** in your hints file. This gives you full control over field ordering within each section.

### Benefits

1. **Data-Driven Layout**: Layout structure defined with your data, not scattered in code
2. **DRY**: Define layout once in hints, use everywhere
3. **Responsive**: Framework adapts layouts based on available space
4. **Accessible**: Section titles used for accessibility identifiers
5. **Flexible**: Can override programmatically with `LayoutSpec` when needed
6. **Backward Compatible**: Existing hints files without `_sections` continue to work

