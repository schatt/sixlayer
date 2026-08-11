# 🔍 **OCR Field Hints Guide - Enhanced Recognition Accuracy**

*Keyword-based field identification to improve OCR text-to-field mapping accuracy.*

## 🎯 **Overview**

OCR Field Hints enable **precise mapping** of OCR-extracted text to specific form fields by providing keyword arrays that help the OCR system identify which text regions correspond to which form fields.

This is especially valuable for:
- **Complex documents** with multiple similar numeric values
- **Varied terminology** (e.g., "gallons" vs "liters", "price" vs "cost")
- **Ambiguous layouts** where position alone isn't sufficient
- **Multi-language documents** with different terms for the same concept

## 📋 **Key Concepts**

### **OCR Hints Array**
Each field can specify an array of keywords that help identify it in OCR text.

**`ocrHints` ≠ Scan accessory (Issue #404).** Keywords are for extraction only. Batch fill eligibility is ``supportsOCR``; the per-field Scan button is ``displayOCR`` (defaults to the same value as `supportsOCR` when omitted). `applying(hints:)` never flips those flags just because `ocrHints` is present. Optional hints-file keys `"supportsOCR"` / `"displayOCR"` override when set.

### **Keyword Matching**
The OCR system uses these hints to:
- **Prioritize** text regions that match field keywords
- **Disambiguate** between similar numeric values
- **Improve accuracy** in complex document layouts

### **Multiple Variations**
Support common variations and synonyms:
```swift
ocrHints: ["gallons", "gal", "fuel quantity", "liters", "litres", "volume"]
```

## 🚀 **Quick Start**

### **Basic Usage**
```swift
let fuelField = DynamicFormField(
    id: "fuel_quantity",
    contentType: .number,
    label: "Fuel Quantity",
    supportsOCR: true, // batch / receipt fill target
    // displayOCR defaults to true when supportsOCR is true
    ocrHints: ["gallons", "gal", "fuel quantity", "liters", "litres"]
)
```

### **Batch fill without Scan button**
```swift
let stationField = DynamicFormField(
    id: "station",
    contentType: .text,
    label: "Station",
    supportsOCR: true,
    displayOCR: false, // map / custom trailingView only
    ocrHints: ["station", "fuel stop"]
)
```

### **Advanced Field Configuration**
```swift
let priceField = DynamicFormField(
    id: "unit_price",
    contentType: .number,
    label: "Unit Price",
    supportsOCR: true,
    ocrHints: [
        "price", "cost", "rate", "per unit", "each",
        "$", "USD", "dollars", "amount"
    ]
)
```

## 📖 **Detailed API Reference**

### **DynamicFormField Properties**
```swift
public struct DynamicFormField {
    // ... existing properties ...

    // NEW: OCR keyword hints for field identification
    public let ocrHints: [String]?
}
```

### **Usage in Field Initialization**
```swift
let field = DynamicFormField(
    id: "field_id",
    contentType: .number,
    label: "Field Label",
    supportsOCR: true,
    ocrHints: ["keyword1", "keyword2", "keyword3"]
)
```

## 🎯 **Usage Patterns**

### **Pattern 1: Fuel Receipt Fields**
```swift
// Fuel quantity field with volume-related keywords
let gallonsField = DynamicFormField(
    id: "gallons",
    contentType: .number,
    label: "Gallons",
    supportsOCR: true,
    ocrHints: [
        "gallons", "gal", "fuel quantity", "liters", "litres",
        "volume", "amount", "quantity", "qty"
    ]
)

// Price per gallon field
let pricePerGallonField = DynamicFormField(
    id: "price_per_gallon",
    contentType: .number,
    label: "Price per Gallon",
    supportsOCR: true,
    ocrHints: [
        "price", "per gallon", "per gal", "rate", "cost",
        "$/gal", "dollars per gallon", "price/gallon"
    ]
)

// Total price field
let totalPriceField = DynamicFormField(
    id: "total_price",
    contentType: .number,
    label: "Total Price",
    supportsOCR: true,
    ocrHints: [
        "total", "amount due", "grand total", "final price",
        "total price", "total cost", "amount", "sum"
    ]
)
```

### **Pattern 2: Invoice Fields**
```swift
let subtotalField = DynamicFormField(
    id: "subtotal",
    contentType: .number,
    label: "Subtotal",
    supportsOCR: true,
    ocrHints: [
        "subtotal", "sub-total", "net amount", "before tax",
        "pre-tax", "base amount", "line total"
    ]
)

let taxField = DynamicFormField(
    id: "tax_amount",
    contentType: .number,
    label: "Tax Amount",
    supportsOCR: true,
    ocrHints: [
        "tax", "taxes", "sales tax", "VAT", "GST",
        "tax amount", "tax total", "tax due"
    ]
)

let discountField = DynamicFormField(
    id: "discount",
    contentType: .number,
    label: "Discount",
    supportsOCR: true,
    ocrHints: [
        "discount", "reduction", "saving", "saving amount",
        "discount amount", "rebate", "adjustment", "less"
    ]
)
```

### **Pattern 3: Contact Information**
```swift
let phoneField = DynamicFormField(
    id: "phone_number",
    contentType: .phone,
    label: "Phone Number",
    supportsOCR: true,
    ocrHints: [
        "phone", "telephone", "tel", "mobile", "cell",
        "contact", "number", "call", "reach"
    ]
)

let emailField = DynamicFormField(
    id: "email_address",
    contentType: .email,
    label: "Email Address",
    supportsOCR: true,
    ocrHints: [
        "email", "e-mail", "mail", "address", "@",
        "contact", "reach", "electronic mail"
    ]
)
```

### **Pattern 4: Address Fields**
```swift
let streetAddressField = DynamicFormField(
    id: "street_address",
    contentType: .text,
    label: "Street Address",
    supportsOCR: true,
    ocrHints: [
        "street", "address", "avenue", "ave", "road", "rd",
        "boulevard", "blvd", "lane", "ln", "drive", "dr",
        "way", "place", "pl", "court", "ct"
    ]
)

let cityField = DynamicFormField(
    id: "city",
    contentType: .text,
    label: "City",
    supportsOCR: true,
    ocrHints: [
        "city", "town", "municipality", "urban area"
    ]
)

let zipField = DynamicFormField(
    id: "zip_code",
    contentType: .text,
    label: "ZIP Code",
    supportsOCR: true,
    ocrHints: [
        "zip", "postal", "zip code", "postal code",
        "zipcode", "postcode", "area code"
    ]
)
```

## 🔧 **Best Practices for OCR Hints**

### **Keyword Selection**
1. **Common Terms**: Include the most common ways people describe the field
2. **Abbreviations**: Add common abbreviations and acronyms
3. **Synonyms**: Include synonyms and related terms
4. **Context Words**: Add words that appear near the field value

### **Document Type Considerations**
1. **Business Documents**: Use formal business terminology
2. **Receipts**: Include brand-specific terms and common abbreviations
3. **Forms**: Use official form field labels and common variations

### **Language Support**
1. **Multi-language**: Include terms in multiple languages if applicable
2. **Regional Variations**: Consider regional spelling differences (e.g., "colour" vs "color")

### **Performance Optimization**
1. **Relevance**: Focus on highly relevant keywords to avoid false matches
2. **Uniqueness**: Choose keywords that distinguish this field from others
3. **Frequency**: Prioritize commonly used terms over obscure ones

## 🧪 **Testing OCR Hints**

### **Unit Testing Pattern**
```swift
@Test func testOCRFieldHintsConfiguration() {
    let field = DynamicFormField(
        id: "test_field",
        contentType: .number,
        label: "Test Field",
        supportsOCR: true,
        ocrHints: ["test", "example", "sample"]
    )

    #expect(field.ocrHints?.count == 3)
    #expect(field.ocrHints?.contains("test") ?? false)
    #expect(field.ocrHints?.contains("example") ?? false)
    #expect(field.ocrHints?.contains("sample") ?? false)
}
```

### **Default Behavior Testing**
```swift
@Test func testOCRFieldHintsDefaultToNil() {
    let field = DynamicFormField(
        id: "regular_field",
        contentType: .text,
        label: "Regular Field"
    )

    #expect(field.ocrHints == nil)
}
```

## 🔄 **Integration with OCR Processing**

### **OCR Processing Flow**
1. **Text Extraction**: OCR extracts all text and numeric values from document
2. **Field Mapping**: Use `ocrHints` to map text regions to specific form fields
3. **Value Assignment**: Populate form state with recognized values
4. **Calculation Groups**: Run calculation groups to fill missing fields
5. **Confidence Scoring**: Apply confidence levels based on hint matching strength

### **Hint Matching Algorithm**
```
For each OCR text region:
  Calculate relevance score based on:
  - Proximity to hint keywords
  - Keyword frequency in region
  - Context word matches
  - Layout position hints

  Assign to field with highest relevance score
```

## 📚 **Advanced Usage**

### **Context-Aware Hints**
```swift
// Different hints for different document types
let amountField = DynamicFormField(
    id: "amount",
    contentType: .number,
    label: "Amount",
    supportsOCR: true,
    ocrHints: [
        // Receipt context
        "total", "amount due", "balance",

        // Invoice context
        "invoice total", "amount payable", "net amount",

        // Statement context
        "ending balance", "current balance", "statement balance"
    ]
)
```

### **Numeric Pattern Hints**
```swift
// Fields that expect specific number formats
let priceField = DynamicFormField(
    id: "price",
    contentType: .number,
    label: "Price",
    supportsOCR: true,
    ocrHints: [
        "$", "USD", "dollars", "price", "cost", "fee",
        "amount", "value", "rate", "charge"
    ]
)
```

### **Compound Hints**
```swift
// Fields that benefit from multi-word hints
let shippingField = DynamicFormField(
    id: "shipping_cost",
    contentType: .number,
    label: "Shipping Cost",
    supportsOCR: true,
    ocrHints: [
        "shipping", "shipping cost", "shipping fee",
        "delivery", "delivery cost", "freight",
        "postage", "handling", "handling fee"
    ]
)
```

## ⚠️ **Common Pitfalls**

### **Overly Broad Hints**
```swift
// ❌ Too broad - matches too many things
ocrHints: ["the", "and", "or", "amount"]

// ✅ Specific and relevant
ocrHints: ["total amount", "final total", "grand total"]
```

### **Missing Common Variations**
```swift
// ❌ Missing common abbreviations
ocrHints: ["telephone number"]

// ✅ Include common abbreviations
ocrHints: ["telephone", "telephone number", "tel", "phone", "phone number"]
```

### **Context-Ignoring Hints**
```swift
// ❌ Same hints for all contexts
ocrHints: ["amount"]  // Too generic

// ✅ Context-specific hints
ocrHints: ["invoice amount", "total due", "amount payable"]
```

## 🔄 **Backward Compatibility**

### **Existing Fields**
Fields created without `ocrHints` continue to work normally - the parameter defaults to `nil`.

### **Migration Path**
```swift
// Before (still works)
let field = DynamicFormField(
    id: "price",
    contentType: .number,
    label: "Price",
    supportsOCR: true
)

// After (enhanced)
let field = DynamicFormField(
    id: "price",
    contentType: .number,
    label: "Price",
    supportsOCR: true,
    ocrHints: ["price", "cost", "amount", "$"]
)
```

## 📚 **Related Documentation**

- **[Calculation Groups Guide](CalculationGroupsGuide.md)** - Intelligent form calculations with OCR
- **[Dynamic Forms Guide](DynamicFormsGuide.md)** - Complete form configuration
- **[AI Agent Guide](AI_AGENT_GUIDE.md)** - Framework usage for AI assistants

## 🎯 **Performance Impact**

### **Minimal Overhead**
- Hints are stored as simple string arrays
- No runtime performance impact if hints are empty/nil
- Keyword matching is efficient string operations

### **Benefits Outweigh Costs**
- **Accuracy Improvement**: Significantly reduces OCR mapping errors
- **User Experience**: Fewer manual corrections needed
- **Processing Efficiency**: Better first-pass accuracy reduces retry cycles

---

*This guide covers OCR Field Hints introduced in SixLayer v5.0.0 for enhanced OCR recognition accuracy through keyword-based field identification.*
