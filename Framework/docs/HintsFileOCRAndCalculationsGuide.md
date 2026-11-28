# Hints File OCR and Calculations Guide - v5.4.0

## Overview

**NEW in v5.4.0**: You can now define **OCR hints** and **calculation groups** directly in your `.hints` files! This extends the hints system to support intelligent OCR form-filling and automatic field calculations, all configured declaratively in JSON.

**Key Benefits:**
- **DRY**: Define OCR hints and calculations once in hints files, use everywhere
- **Internationalization**: Language-specific OCR hints with automatic fallback
- **Declarative**: All configuration in JSON, no code changes needed
- **Backward Compatible**: Existing hints files continue to work

## Quick Start

### Basic OCR Hints

Add `ocrHints` to any field in your hints file:

```json
{
  "gallons": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["gallons", "gal", "fuel quantity", "liters", "litres"]
  }
}
```

### Basic Calculation Groups

Add `calculationGroups` to fields that can be calculated:

```json
{
  "total": {
    "expectedLength": 10,
    "calculationGroups": [
      {
        "id": "multiply",
        "formula": "total = price * quantity",
        "dependentFields": ["price", "quantity"],
        "priority": 1
      }
    ]
  }
}
```

### Combined OCR + Calculations

Combine both for intelligent form-filling:

```json
{
  "gallons": {
    "expectedLength": 10,
    "ocrHints": ["gallons", "gal", "fuel quantity"],
    "calculationGroups": [
      {
        "id": "from_price_total",
        "formula": "gallons = total_price / price_per_gallon",
        "dependentFields": ["total_price", "price_per_gallon"],
        "priority": 1
      }
    ]
  }
}
```

## OCR Hints

### Purpose

OCR hints are **keywords** that help the OCR system identify which text regions in a scanned document belong to which form fields. This dramatically improves OCR accuracy, especially for complex documents with multiple numeric values.

### Format

OCR hints can be specified as:
- **Array of strings** (recommended): `["gallons", "gal", "fuel quantity"]`
- **Comma-separated string**: `"gallons,gal,fuel quantity"`

### Example: Fuel Receipt Form

**FuelReceipt.hints**:
```json
{
  "gallons": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["gallons", "gal", "fuel quantity", "liters", "litres"]
  },
  "pricePerGallon": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["price per gallon", "price/gal", "ppg", "per gallon"]
  },
  "totalPrice": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["total", "total price", "amount", "sum"]
  }
}
```

### How It Works

1. **OCR extracts text** from scanned document
2. **Framework searches** for OCR hint keywords in the text
3. **Maps text regions** to form fields based on keyword matches
4. **Populates form** with recognized values

### Best Practices

1. **Include variations**: Add common abbreviations, plurals, and synonyms
   ```json
   "ocrHints": ["gallons", "gal", "gals", "fuel quantity", "liters", "litres"]
   ```

2. **Use descriptive phrases**: Include multi-word phrases that appear in documents
   ```json
   "ocrHints": ["price per gallon", "price/gal", "ppg", "cost per gallon"]
   ```

3. **Order by frequency**: Put most common terms first
   ```json
   "ocrHints": ["total", "total price", "grand total", "amount due"]
   ```

## Calculation Groups

### Purpose

Calculation groups define **mathematical relationships** between form fields. When OCR extracts partial data, the framework can automatically calculate missing field values using these relationships.

### Format

Each calculation group requires:
- **`id`** (string): Unique identifier for this calculation
- **`formula`** (string): Mathematical formula (e.g., `"total = price * quantity"`)
- **`dependentFields`** (array): Field IDs this calculation depends on
- **`priority`** (number): Lower numbers = higher priority (used for conflict resolution)

### Example: Invoice Form

**Invoice.hints**:
```json
{
  "price": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["price", "unit price", "cost"]
  },
  "quantity": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["quantity", "qty", "amount"]
  },
  "subtotal": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["subtotal", "sub-total", "before tax"]
  },
  "tax": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["tax", "sales tax", "VAT"]
  },
  "total": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["total", "grand total", "amount due"],
    "calculationGroups": [
      {
        "id": "multiply",
        "formula": "total = price * quantity",
        "dependentFields": ["price", "quantity"],
        "priority": 1
      },
      {
        "id": "add_tax",
        "formula": "total = subtotal + tax",
        "dependentFields": ["subtotal", "tax"],
        "priority": 2
      }
    ]
  }
}
```

### How It Works

1. **OCR extracts available values** from document
2. **Framework identifies missing fields** that have calculation groups
3. **Runs calculations** using available dependent fields
4. **Resolves conflicts** if multiple calculations produce different results (uses priority)
5. **Provides confidence scores** for calculated values

### Priority System

- **Lower priority = Higher precedence**
- Priority 1 > Priority 2 > Priority 3
- Used when multiple calculation groups produce different results

**Example**:
```json
{
  "total": {
    "calculationGroups": [
      {
        "id": "primary_method",
        "formula": "total = price * quantity",
        "dependentFields": ["price", "quantity"],
        "priority": 1  // Highest priority
      },
      {
        "id": "fallback_method",
        "formula": "total = subtotal + tax",
        "dependentFields": ["subtotal", "tax"],
        "priority": 2  // Lower priority (fallback)
      }
    ]
  }
}
```

### Best Practices

1. **Use descriptive IDs**: Make calculation group IDs meaningful
   ```json
   "id": "from_price_total"  // ✅ Good
   "id": "calc1"            // ❌ Avoid
   ```

2. **Order by priority**: List higher priority calculations first
3. **Validate formulas**: Ensure formulas use valid field IDs
4. **Handle edge cases**: Consider division by zero, negative values, etc.

## Internationalization

### Language-Specific OCR Hints

**NEW in v5.4.0**: Support for language-specific OCR hints with automatic fallback!

### Format

Use language-specific keys: `ocrHints.{languageCode}`

```json
{
  "gallons": {
    "expectedLength": 10,
    "ocrHints": ["gallons", "gal"],  // Default/fallback (English)
    "ocrHints.es": ["galones", "gal"],  // Spanish
    "ocrHints.fr": ["gallons", "litres"],  // French
    "ocrHints.de": ["gallonen", "liter"]  // German
  }
}
```

### Fallback Chain

The framework uses this fallback order:
1. **`ocrHints.{currentLanguage}`** (e.g., `ocrHints.es` for Spanish)
2. **`ocrHints`** (default/fallback)
3. **`nil`** (no OCR hints)

### Example: Multi-Language Receipt Form

**Receipt.hints**:
```json
{
  "total": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["total", "amount due", "grand total"],
    "ocrHints.es": ["total", "importe debido", "total general"],
    "ocrHints.fr": ["total", "montant dû", "total général"],
    "ocrHints.de": ["gesamt", "fälliger Betrag", "Gesamtsumme"]
  },
  "tax": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["tax", "sales tax", "VAT"],
    "ocrHints.es": ["impuesto", "IVA", "impuesto sobre ventas"],
    "ocrHints.fr": ["taxe", "TVA", "taxe sur les ventes"],
    "ocrHints.de": ["Steuer", "MwSt", "Umsatzsteuer"]
  }
}
```

### Usage

The framework automatically uses the correct language based on the current locale:

```swift
// Spanish locale - uses ocrHints.es
let loader = FileBasedDataHintsLoader()
let result = loader.loadHintsResult(for: "Receipt", locale: Locale(identifier: "es"))
// result.fieldHints["total"]?.ocrHints == ["total", "importe debido", "total general"]

// French locale - uses ocrHints.fr
let result = loader.loadHintsResult(for: "Receipt", locale: Locale(identifier: "fr"))
// result.fieldHints["total"]?.ocrHints == ["total", "montant dû", "total général"]

// English locale (or no language-specific hints) - uses ocrHints
let result = loader.loadHintsResult(for: "Receipt", locale: Locale(identifier: "en"))
// result.fieldHints["total"]?.ocrHints == ["total", "amount due", "grand total"]
```

### Backward Compatibility

**Existing hints files continue to work!** If you only have `ocrHints` (no language-specific keys), the framework uses that for all locales.

```json
{
  "total": {
    "ocrHints": ["total", "amount due"]  // Works for all languages
  }
}
```

## Complete Example: Fuel Receipt Form

**FuelReceipt.hints**:
```json
{
  "gallons": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "maxLength": 20,
    "ocrHints": ["gallons", "gal", "fuel quantity", "liters", "litres"],
    "ocrHints.es": ["galones", "gal", "cantidad de combustible", "litros"],
    "ocrHints.fr": ["gallons", "litres", "quantité de carburant"],
    "calculationGroups": [
      {
        "id": "from_price_total",
        "formula": "gallons = total_price / price_per_gallon",
        "dependentFields": ["total_price", "price_per_gallon"],
        "priority": 1
      }
    ]
  },
  "pricePerGallon": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["price per gallon", "price/gal", "ppg", "per gallon"],
    "ocrHints.es": ["precio por galón", "precio/gal", "ppg"],
    "ocrHints.fr": ["prix par gallon", "prix/gal", "ppg"]
  },
  "totalPrice": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["total", "total price", "amount", "sum"],
    "ocrHints.es": ["total", "precio total", "importe", "suma"],
    "ocrHints.fr": ["total", "prix total", "montant", "somme"],
    "calculationGroups": [
      {
        "id": "multiply",
        "formula": "total_price = gallons * price_per_gallon",
        "dependentFields": ["gallons", "price_per_gallon"],
        "priority": 1
      }
    ]
  },
  "_sections": [
    {
      "id": "fuel_data",
      "title": "Fuel Information",
      "fields": ["gallons", "pricePerGallon", "totalPrice"],
      "layoutStyle": "vertical"
    }
  ]
}
```

## Integration with Code

### Applying Hints to Fields

The framework automatically applies hints when you use `modelName`:

```swift
let fields = [
    DynamicFormField(
        id: "gallons",
        contentType: .number,
        label: "Gallons"
    ),
    DynamicFormField(
        id: "totalPrice",
        contentType: .number,
        label: "Total Price"
    )
]

// Hints are automatically loaded and applied!
platformPresentFormData_L1(
    fields: fields,
    hints: EnhancedPresentationHints(
        dataType: .form,
        context: .create
    ),
    modelName: "FuelReceipt"  // Loads FuelReceipt.hints automatically
)
```

### Manual Application

You can also apply hints manually:

```swift
let loader = FileBasedDataHintsLoader()
let result = loader.loadHintsResult(for: "FuelReceipt", locale: Locale.current)

// Apply hints to fields
let fieldsWithHints = fields.map { field in
    if let hints = result.fieldHints[field.id] {
        return field.applying(hints: hints)
    }
    return field
}
```

## Migration Guide

### From Code-Based OCR Hints

**Before (v5.2.0)**:
```swift
let field = DynamicFormField(
    id: "gallons",
    contentType: .number,
    label: "Gallons",
    supportsOCR: true,
    ocrHints: ["gallons", "gal", "fuel quantity"]
)
```

**After (v5.4.0)**:
```json
// FuelReceipt.hints
{
  "gallons": {
    "ocrHints": ["gallons", "gal", "fuel quantity"]
  }
}
```

```swift
// Code - hints applied automatically!
let field = DynamicFormField(
    id: "gallons",
    contentType: .number,
    label: "Gallons"
)
// Use modelName to load hints
```

### From Code-Based Calculation Groups

**Before (v5.2.0)**:
```swift
let field = DynamicFormField(
    id: "total",
    contentType: .number,
    label: "Total",
    calculationGroups: [
        CalculationGroup(
            id: "multiply",
            formula: "total = price * quantity",
            dependentFields: ["price", "quantity"],
            priority: 1
        )
    ]
)
```

**After (v5.4.0)**:
```json
// Invoice.hints
{
  "total": {
    "calculationGroups": [
      {
        "id": "multiply",
        "formula": "total = price * quantity",
        "dependentFields": ["price", "quantity"],
        "priority": 1
      }
    ]
  }
}
```

## Best Practices

### 1. Organize by Model

Create separate hints files for each data model:
- `FuelReceipt.hints` - Fuel receipt forms
- `Invoice.hints` - Invoice forms
- `ExpenseReport.hints` - Expense reports

### 2. Use Descriptive IDs

Make calculation group IDs meaningful:
```json
"id": "from_price_total"  // ✅ Good - describes the calculation
"id": "calc1"            // ❌ Avoid - not descriptive
```

### 3. Include Common Variations

Add common abbreviations and synonyms to OCR hints:
```json
"ocrHints": ["total", "total price", "grand total", "amount due", "sum", "total amount"]
```

### 4. Test Language-Specific Hints

Verify OCR hints work for all supported languages:
```json
"ocrHints": ["total"],  // Default
"ocrHints.es": ["total", "importe"],  // Spanish
"ocrHints.fr": ["total", "montant"]   // French
```

### 5. Validate Calculation Formulas

Ensure formulas reference valid field IDs:
```json
{
  "total": {
    "calculationGroups": [
      {
        "formula": "total = price * quantity",  // ✅ price and quantity must exist
        "dependentFields": ["price", "quantity"]
      }
    ]
  }
}
```

## Value Ranges (NEW in v5.7.1)

### Purpose

Value ranges define **acceptable numeric ranges** for OCR-extracted field values. This helps filter out obviously incorrect OCR readings (e.g., "150 gallons" when the expected range is 5-30 gallons).

### Format

Value ranges are specified using `expectedRange` with `min` and `max` values:

```json
{
  "gallons": {
    "expectedLength": 10,
    "ocrHints": ["gallons", "gal"],
    "expectedRange": {
      "min": 5.0,
      "max": 30.0
    }
  }
}
```

### How It Works

1. **OCR extracts values** from scanned document
2. **Framework validates** numeric values against `expectedRange`
3. **Out-of-range values are kept but flagged** as questionable in `OCRResult.adjustedFields`
4. **Calculation groups can confirm** out-of-range values (if they agree, value is likely correct)
5. **User can verify** flagged values before accepting them

**Important**: Expected ranges are **guidelines**, not hard requirements. Real-world scenarios may legitimately fall outside typical ranges (e.g., expensive gas in remote locations).

### Example: Fuel Receipt with Ranges

**FuelPurchase.hints**:
```json
{
  "gallons": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["gallons", "gal", "fuel quantity"],
    "expectedRange": {
      "min": 5.0,
      "max": 30.0
    }
  },
  "pricePerGallon": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["price per gallon", "price/gal", "ppg"],
    "expectedRange": {
      "min": 2.0,
      "max": 10.0
    }
  },
  "totalPrice": {
    "expectedLength": 10,
    "displayWidth": "medium",
    "ocrHints": ["total", "total price", "amount"],
    "expectedRange": {
      "min": 10.0,
      "max": 300.0
    }
  }
}
```

### Runtime Overrides

Apps can override hints file ranges at runtime using `OCRContext.fieldRanges`. This is useful when acceptable ranges depend on dynamic context (e.g., vehicle type, user preferences).

### Field Averages (NEW in v5.7.2)

Apps can provide typical/average values for fields to identify values that are within expected range but unusual compared to typical usage.

**Example**:
```swift
let context = OCRContext(
    entityName: "FuelPurchase",
    fieldRanges: ["pricePerGallon": ValueRange(min: 2.0, max: 10.0)],
    fieldAverages: ["pricePerGallon": 4.34]  // Typical gas price user pays
)
```

**How It Works**:
- If a value is within expected range but farther from the average than the configured **percent deviation gate**, it's flagged
- Default gate is **50%** when `fieldAverageMaxPercentDeviation` is nil (`OCRContext.defaultFieldAverageMaxPercentDeviation`) — same legacy behavior (#679)
- Apps (and later OCR lab `label.json` fixtures, #677) can pass a custom percent; this is **not** the average magnitude itself, and not an absolute `fieldRanges` / `expectedRange` bound
- Distinct from regional **fraction-digit / format** priors (#678)

**Use Case**:
- Expected range: 2.0-10.0 (covers all possible gas prices)
- Typical value: 4.34 (regional magnitude prior at that time)
- Extracted value: 9.99 (within range, but ~130% deviation from average)
- Result with default 50% gate: flagged for verification even though it's within range

```swift
let context = OCRContext(
    textTypes: [.number],
    language: .english,
    extractionMode: .automatic,
    entityName: "FuelPurchase",
    fieldRanges: [
        "gallons": ValueRange(min: 20.0, max: 100.0)  // Override for trucks
    ],
    fieldAverages: ["pricePerGallon": 4.34],
    fieldAverageMaxPercentDeviation: 50  // optional; nil keeps the 50% default
)
```

**Priority**: Runtime override > Hints file range

### Fraction Digits / Numeric Format (#678)

Regional **display shape** for a field — how many digits after the decimal are normal — is separate from `fieldAverages` (regional **magnitude** at that time).

**Hints file**:
```json
"gallons": {
  "expectedRange": { "min": 0.0, "max": 100.0 },
  "fractionDigits": 2,
  "fractionDigits.US": 3,
  "fractionDigits.DE": 2
}
```

Resolution order when loading hints for a locale: `fractionDigits.{region}` → `fractionDigits.{language}` → `fractionDigits`.

**Runtime override** (apps / OCR lab fixtures via #677): `OCRContext.fieldFractionDigits` wins over the hints file for those field ids.

**How It Works**:
- During decimal-placement correction, candidates that match the preferred fraction-digit count score higher
- Absent format priors leave existing range/average/calculation scoring unchanged
- Do not overload `fieldAverages` to mean fraction digits

```swift
let context = OCRContext(
    entityName: "FuelPurchase",
    fieldRanges: ["gallons": ValueRange(min: 0, max: 100)],
    fieldFractionDigits: ["gallons": 3],  // e.g. US volume display
    decimalLocale: Locale(identifier: "en_US")
)
```

### Validation Behavior

- **Numeric values only**: Non-numeric values skip range validation
- **Inclusive boundaries**: `min <= value <= max`
- **Out-of-range handling**: Values outside range are **kept but flagged** in `OCRResult.adjustedFields`
- **Calculation confirmation**: If calculation groups confirm an out-of-range value, it's flagged as "confirmed by calculation"
- **Guidelines, not requirements**: Expected ranges are typical values, not absolute limits
- **User verification**: Flagged values should be verified by the user before accepting

### Best Practices

1. **Set realistic ranges**: Use ranges that cover 95% of expected values
   ```json
   "expectedRange": {"min": 5, "max": 30}  // ✅ Good - covers most cars
   "expectedRange": {"min": 0, "max": 1000}  // ❌ Too broad - not useful
   ```

2. **Combine with calculation groups**: If extraction fails, let calculations fill in
   ```json
   {
     "gallons": {
       "expectedRange": {"min": 5, "max": 30},
       "calculationGroups": [
         {
           "id": "from_price_total",
           "formula": "gallons = total_price / price_per_gallon",
           "dependentFields": ["total_price", "price_per_gallon"],
           "priority": 1
         }
       ]
     }
   }
   ```

3. **Use runtime overrides for dynamic contexts**: Different vehicle types, user preferences, etc.
   ```swift
   func createContext(for vehicle: VehicleType) -> OCRContext {
       let ranges: [String: ValueRange]
       switch vehicle {
       case .motorcycle:
           ranges = ["gallons": ValueRange(min: 2.0, max: 5.0)]
       case .truck:
           ranges = ["gallons": ValueRange(min: 20.0, max: 100.0)]
       default:
           ranges = [:]  // Use hints file ranges
       }
       
       return OCRContext(
           entityName: "FuelPurchase",
           fieldRanges: ranges
       )
   }
   ```

4. **Test edge cases**: Verify boundary values (min, max) work correctly
   ```json
   "expectedRange": {"min": 5.0, "max": 30.0}
   // Values 5.0 and 30.0 are accepted (inclusive)
   // Values 4.9 and 30.1 are rejected
   ```

## Decimal Correction & Range Inference (NEW in v5.7.2)

### Purpose

When Vision framework fails to detect decimal points (e.g., extracts "3288" instead of "32.88"), the framework can automatically correct them using expected ranges and calculation groups as heuristics.

### How It Works

1. **Detection**: If an extracted integer value is outside its expected range, the framework tries inserting decimal points
2. **Correction**: Tries various decimal positions (most common: 2 decimal places from right)
3. **Validation**: Checks if corrected value is within range and validates using calculation groups
4. **Tracking**: Records adjustments in `OCRResult.adjustedFields` for user verification

### Example: Decimal Correction

**FuelPurchase.hints**:
```json
{
  "totalCost": {
    "ocrHints": ["total", "amount", "$"],
    "expectedRange": {"min": 10.0, "max": 300.0}
  }
}
```

If Vision extracts "3288" (outside range), the framework:
1. Tries "32.88" → ✅ Within range (10.0 - 300.0)
2. Validates using calculation groups (if available)
3. Applies correction: `totalCost = "32.88"`
4. Records: `adjustedFields["totalCost"] = "Decimal point corrected: '3288' → '32.88' (inferred from expected range)"`

### Range Inference from Calculation Groups

Fields without explicit ranges can have their ranges inferred from calculation groups and related field ranges.

**Example**:
```json
{
  "gallons": {
    "expectedRange": {"min": 5.0, "max": 30.0},
    "ocrHints": ["gallons", "gal"]
  },
  "pricePerGallon": {
    "expectedRange": {"min": 2.0, "max": 10.0},
    "ocrHints": ["price per gallon"]
  },
  "totalCost": {
    "ocrHints": ["total", "$"],
    "calculationGroups": [
      {
        "id": "fuel_purchase",
        "formula": "totalCost = pricePerGallon * gallons",
        "dependentFields": ["pricePerGallon", "gallons"],
        "priority": 1
      }
    ]
    // No explicit range, but inferred: 2.0*5.0 to 10.0*30.0 = 10.0 - 300.0
  }
}
```

The framework automatically infers `totalCost` range as **10.0 - 300.0** based on:
- `pricePerGallon` range: 2.0 - 10.0
- `gallons` range: 5.0 - 30.0
- Formula: `totalCost = pricePerGallon * gallons`
- Calculation: min = 2.0 * 5.0 = 10.0, max = 10.0 * 30.0 = 300.0

### Supported Operations for Range Inference

- **Multiplication**: `total = price * quantity` → range = (min1*min2 to max1*max2)
- **Addition**: `total = subtotal + tax` → range = (min1+min2 to max1+max2)
- **Subtraction**: `net = gross - tax` → range = (min1-max2 to max1-min2)
- **Division**: `rate = total / quantity` → range = (min1/max2 to max1/min2)

### Checking Adjusted Fields

```swift
let result = try await service.processStructuredExtraction(image, context: context)

// Check if any fields were adjusted
if !result.adjustedFields.isEmpty {
    print("⚠️ Some fields were adjusted:")
    for (fieldId, description) in result.adjustedFields {
        print("  • \(fieldId): \(description)")
    }
}

// Example output:
// ⚠️ Some fields were adjusted:
//   • totalCost: Decimal point corrected: '3288' → '32.88' (inferred from expected range)
//   • pricePerGallon: Calculated from formula: pricePerGallon = totalCost / gallons = 3.64
```

### Best Practices

1. **Define explicit ranges** for better decimal correction accuracy
2. **Use range inference** when calculation groups are available (reduces duplication)
3. **Check `adjustedFields`** in your UI to show warnings for user verification
4. **Combine with calculation groups** for maximum accuracy

## Related Documentation

- **[Field Hints Guide](FieldHintsGuide.md)** - Complete field hints reference
- **[Calculation Groups Guide](CalculationGroupsGuide.md)** - Advanced calculation features
- **[OCR Field Hints Guide](OCRFieldHintsGuide.md)** - OCR recognition patterns
- **[Hints DRY Architecture](HintsDRYArchitecture.md)** - Hints system architecture

## Summary

**v5.4.0** brings OCR hints and calculation groups to hints files:
✅ **OCR Hints**: Define keywords for better OCR field identification  
✅ **Calculation Groups**: Define mathematical relationships between fields  
✅ **Internationalization**: Language-specific OCR hints with automatic fallback  

**v5.7.1** adds value range validation:
✅ **Value Ranges**: Define acceptable numeric ranges for OCR validation  
✅ **Runtime Overrides**: Override hints file ranges based on dynamic context  
✅ **Automatic Filtering**: Out-of-range values automatically removed  

**v5.7.2** adds intelligent decimal correction:
✅ **Decimal Correction**: Automatically corrects missing decimal points using expected ranges  
✅ **Range Inference**: Infers ranges from calculation groups and related field ranges  
✅ **Adjustment Tracking**: `OCRResult.adjustedFields` tracks which fields were adjusted  
✅ **Bidirectional Matching**: Handles "Gallons 9.022" and "9.022 Gallons" patterns  
✅ **Position Sorting**: Vision observations sorted for proper reading order  

✅ **Backward Compatible**: Existing hints files continue to work  
✅ **DRY**: Define once in hints files, use everywhere  

All configuration is declarative in JSON - no code changes needed!

