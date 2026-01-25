# Localization Strings Inventory

## Current Status

**No localization files exist** - The framework currently has **zero `.strings` files** in its bundle.

All user-facing strings are currently **hardcoded in English** throughout the codebase.

## Accessibility Labels (Issue #154, #158)

The framework automatically generates accessibility labels for VoiceOver compliance. See `AccessibilityLabelsGuide.md` for complete documentation.

**Key Naming Convention:**
- **App keys (primary)**: `{AppName}.accessibility.{component}.{action}` - Developers use their own app keys
- Framework keys (internal): `SixLayerFramework.accessibility.{component}.{action}` - Framework-internal only
- Auto-extracted: `SixLayerFramework.accessibility.auto.{sanitizedText}` - For auto-extraction feature

**Discovery Methods:**
1. **Runtime logging** (debug mode) - Logs missing app keys to console with format:
   ```
   ⚠️ Accessibility Label: Missing localization key "MyApp.accessibility.button.save" for button "MyApp.accessibility.button.save"
   ```
2. **Build-time script** - `scripts/check_accessibility_labels_completeness.py` (✅ Created - Issue #158)
   - Scans codebase for `accessibilityLabel` parameters
   - Scans for `.automaticCompliance(accessibilityLabel:)` calls
   - Scans for `DynamicFormField.label` usage in Layer 1 functions
   - Generates report of missing keys per language
3. **Documentation** - `AccessibilityLabelsGuide.md` provides examples and guidance

**Accessibility Label Key Examples:**
- App keys: `MyApp.accessibility.button.save`, `MyApp.accessibility.field.email`
- Framework keys: `SixLayerFramework.accessibility.button.save` (internal only)
- Auto-extracted: `SixLayerFramework.accessibility.auto.save` (from `Button("Save")`)

**Note:** Developers should use their own app keys (e.g., `MyApp.accessibility.*`), not framework keys. The framework supports any key format you choose.

## Strings That Should Be Localized

### 1. Error Messages

#### Internationalization Errors (`InternationalizationTypes.swift`)
- `"Invalid locale provided"`
- `"Language not supported"`
- `"Invalid currency code"`
- `"Formatting operation failed"`
- `"Localization not found"`
- `"Pluralization operation failed"`

#### CloudKit Service Errors (`CloudKitService.swift`)
- `"iCloud account is not available"`
- `"Network is not available"`
- `"Write operations are not supported on this platform"`
- `"Required field '%@' is missing"` (with field parameter)
- `"Record not found"`
- `"Record conflict detected"`
- `"CloudKit quota exceeded"`
- `"Permission denied"`
- `"Invalid record"`
- `"Unknown error: %@"` (with error parameter)

#### Image Processing Errors (`ImageProcessingTypes.swift`)
- `"Invalid image provided for processing"`
- `"Image processing failed: %@"` (with error)
- `"Image enhancement failed: %@"` (with error)
- `"Image optimization failed: %@"` (with error)
- `"Image analysis failed: %@"` (with error)

#### Image Metadata Errors (`ImageMetadataTypes.swift`)
- `"Invalid image provided for metadata extraction"`
- `"Metadata extraction failed: %@"` (with error)
- `"Image analysis failed: %@"` (with error)
- `"Image categorization failed: %@"` (with error)

#### OCR Errors (`OCRService.swift`)
- Various OCR-specific error messages

#### Location Service Errors (`LocationService.swift`)
- Location service error messages

#### Field Action Errors (`FieldActions.swift`)
- Field action error messages

#### Barcode Errors (`PlatformOCRTypes.swift`)
- Barcode scanning error messages

### 2. UI Labels and Placeholders

#### Form Field Placeholders
- `"Select"` (default picker placeholder)
- `"Select an option"`
- `"Select date"`
- `"Select time"`
- `"Select date and time"`
- `"Select dates"` (multiple dates)
- `"Select file"`
- `"Select image"`
- `"Select color"`
- `"Select country"`
- `"Select start date"`
- `"Select start time"`
- `"Select end date"`
- `"Select end time"`
- `"Select creation date"`
- `"Select creation time"`
- `"Select birth date"`
- `"Select category"`
- `"Select type"`
- `"Select filters"`
- `"Select theme"`
- `"Select route type"`

#### Button Labels
- `"Choose Image"`
- `"Choose Photo"`
- `"Choose Option"`
- `"Select File"`
- `"Confirm"`
- `"Save"`
- `"Cancel"`

#### Navigation Labels
- `"Select an item"`
- `"Choose an item from the list to view its details"`

### 3. OCR Interface Strings

#### OCR Disambiguation View (`OCRDisambiguationView.swift`)
- `"Multiple interpretations found"`
- `"Please select the correct interpretation:"`
- `"Confidence: %d%%"` (with percentage)
- `"Type: %@"` (with type)
- `"Best match: %@"` (with text)
- `"Confirm"`

#### OCR Overlay (`OCROverlaySheetModifier.swift`)
- `"OCR Data Unavailable"`
- `"Both OCR result and image are required to display the overlay."`
- `"OCR result is missing. Please process the image first."`
- `"Image is missing. Please provide the image that was processed."`

#### OCR Overlay View (`OCROverlayView.swift`)
- `"Extracted Text:"`
- `"Confidence: %d%%"` (with percentage)

### 4. Form Validation Messages

#### Validation Rules (`FormUsageExample.swift`)
- `"Please enter a valid email address"`
- `"Please enter a valid phone number"`

#### Field Labels
- `"Selected: %@"` (with filename)
- `"Selected dates:"`
- `"Drag & drop files here"`
- `"or"`
- `"Supported types: %@"` (with types)
- `"Max file size: %@"` (with size)

### 5. Status Messages

#### Loading States
- `"Loading"`
- `"Loading location..."`

#### Status Labels
- `"Status: %@"` (with status)
- `"ID: %@"` (with ID)

### 6. Error Display Labels

#### Error UI
- `"Error"`
- `"Error: %@"` (with error description)
- `"Warning"`
- `"Failed"`
- `"Success"`

#### Invalid Data Labels
- `"Invalid Date"`
- `"Invalid URL"`

### 7. File System Messages

#### File Operations (`PlatformFileSystemUtilities.swift`)
- `"Invalid path - the path contains invalid characters or is malformed"`
- `"File system error: %@"` (with error)
- `"Directory creation failed: %@"` (with error)
- `"Unknown error: %@"` (with error)

### 8. Color/Encoding Errors

#### Color Encoding (`PlatformColorEncodeExtensions.swift`)
- `"Failed to encode color: %@"` (with error)
- `"Failed to decode color: %@"` (with error)
- `"Invalid color data provided"`

### 9. Entity Creation Messages

#### Entity Utilities (`EntityCreationUtilities.swift`)
- `"Failed to decode entity from form values: %@"` (with error)

#### Form Storage (`FormStateStorage.swift`)
- `"Failed to encode form draft: %@"` (with error)
- `"Failed to decode form draft: %@"` (with error)

### 10. CloudKit Components

#### CloudKit UI (`PlatformCloudKitComponentsLayer4.swift`)
- `"Error: %@"` (with error description)

## Recommended Localization File Structure

### Framework Bundle Structure

```
Framework/
└── Resources/
    ├── en.lproj/
    │   └── Localizable.strings
    ├── es.lproj/
    │   └── Localizable.strings
    ├── fr.lproj/
    │   └── Localizable.strings
    └── [other languages]/
        └── Localizable.strings
```

### Key Naming Convention

Recommended prefix: `"SixLayerFramework."` to avoid conflicts with app strings.

Example keys:
- `"SixLayerFramework.error.invalidLocale"`
- `"SixLayerFramework.form.placeholder.select"`
- `"SixLayerFramework.ocr.disambiguation.title"`
- `"SixLayerFramework.button.confirm"`

## Priority for Localization

### High Priority (User-Facing)
1. Error messages (all error types)
2. Form field placeholders
3. Button labels
4. OCR interface strings
5. Validation messages

### Medium Priority
1. Status messages
2. File operation messages
3. Navigation labels

### Low Priority
1. Debug/console messages
2. Internal status strings
3. Developer-facing messages

## Next Steps

1. **Create base English strings file** (`en.lproj/Localizable.strings`)
2. **Extract all hardcoded strings** to use `localizedString(for:)` with keys
3. **Add translations** for supported languages
4. **Update code** to use localization keys instead of hardcoded strings
5. **Test** app override functionality

## Example Localizable.strings File

```strings
/* Error Messages */
"SixLayerFramework.error.invalidLocale" = "Invalid locale provided";
"SixLayerFramework.error.languageNotSupported" = "Language not supported";
"SixLayerFramework.error.invalidCurrencyCode" = "Invalid currency code";
"SixLayerFramework.error.formattingFailed" = "Formatting operation failed";
"SixLayerFramework.error.localizationNotFound" = "Localization not found";
"SixLayerFramework.error.pluralizationFailed" = "Pluralization operation failed";

/* CloudKit Errors */
"SixLayerFramework.cloudkit.accountUnavailable" = "iCloud account is not available";
"SixLayerFramework.cloudkit.networkUnavailable" = "Network is not available";
"SixLayerFramework.cloudkit.writeNotSupported" = "Write operations are not supported on this platform";
"SixLayerFramework.cloudkit.missingField" = "Required field '%@' is missing";
"SixLayerFramework.cloudkit.recordNotFound" = "Record not found";
"SixLayerFramework.cloudkit.conflictDetected" = "Record conflict detected";
"SixLayerFramework.cloudkit.quotaExceeded" = "CloudKit quota exceeded";
"SixLayerFramework.cloudkit.permissionDenied" = "Permission denied";
"SixLayerFramework.cloudkit.invalidRecord" = "Invalid record";
"SixLayerFramework.cloudkit.unknownError" = "Unknown error: %@";

/* Form Placeholders */
"SixLayerFramework.form.placeholder.select" = "Select";
"SixLayerFramework.form.placeholder.selectOption" = "Select an option";
"SixLayerFramework.form.placeholder.selectDate" = "Select date";
"SixLayerFramework.form.placeholder.selectTime" = "Select time";
"SixLayerFramework.form.placeholder.selectDateTime" = "Select date and time";
"SixLayerFramework.form.placeholder.selectDates" = "Select dates";
"SixLayerFramework.form.placeholder.selectFile" = "Select file";
"SixLayerFramework.form.placeholder.selectImage" = "Select image";
"SixLayerFramework.form.placeholder.selectColor" = "Select color";
"SixLayerFramework.form.placeholder.selectCountry" = "Select country";

/* Buttons */
"SixLayerFramework.button.chooseImage" = "Choose Image";
"SixLayerFramework.button.choosePhoto" = "Choose Photo";
"SixLayerFramework.button.selectFile" = "Select File";
"SixLayerFramework.button.confirm" = "Confirm";
"SixLayerFramework.button.save" = "Save";
"SixLayerFramework.button.cancel" = "Cancel";

/* OCR Interface */
"SixLayerFramework.ocr.disambiguation.title" = "Multiple interpretations found";
"SixLayerFramework.ocr.disambiguation.prompt" = "Please select the correct interpretation:";
"SixLayerFramework.ocr.disambiguation.confidence" = "Confidence: %d%%";
"SixLayerFramework.ocr.disambiguation.type" = "Type: %@";
"SixLayerFramework.ocr.disambiguation.bestMatch" = "Best match: %@";
"SixLayerFramework.ocr.overlay.unavailable" = "OCR Data Unavailable";
"SixLayerFramework.ocr.overlay.bothRequired" = "Both OCR result and image are required to display the overlay.";
"SixLayerFramework.ocr.overlay.resultMissing" = "OCR result is missing. Please process the image first.";
"SixLayerFramework.ocr.overlay.imageMissing" = "Image is missing. Please provide the image that was processed.";
"SixLayerFramework.ocr.overlay.extractedText" = "Extracted Text:";

/* Validation */
"SixLayerFramework.validation.email" = "Please enter a valid email address";
"SixLayerFramework.validation.phone" = "Please enter a valid phone number";

/* Status */
"SixLayerFramework.status.loading" = "Loading";
"SixLayerFramework.status.loadingLocation" = "Loading location...";

/* Navigation */
"SixLayerFramework.navigation.selectItem" = "Select an item";
"SixLayerFramework.navigation.chooseItem" = "Choose an item from the list to view its details";

/* File Operations */
"SixLayerFramework.file.invalidPath" = "Invalid path - the path contains invalid characters or is malformed";
"SixLayerFramework.file.systemError" = "File system error: %@";
"SixLayerFramework.file.directoryCreationFailed" = "Directory creation failed: %@";
"SixLayerFramework.file.unknownError" = "Unknown error: %@";
```
