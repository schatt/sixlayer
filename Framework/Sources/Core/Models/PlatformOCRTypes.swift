//
//  PlatformOCRTypes.swift
//  SixLayerFramework
//
//  OCR-related types and enums for cross-platform text recognition functionality
//

import Foundation
import SwiftUI

#if canImport(Vision)
import Vision
#endif

// MARK: - Text Types

/// Types of text that can be recognized by OCR
public enum TextType: String, CaseIterable, Sendable {
    case price = "price"
    case number = "number"
    case date = "date"
    case address = "address"
    case email = "email"
    case phone = "phone"
    case url = "url"
    case general = "general"
    
    // New structured text types for enhanced extraction
    case name = "name"
    case idNumber = "id_number"
    case stationName = "station_name"
    case total = "total"
    case vendor = "vendor"
    case expiryDate = "expiry_date"
    case quantity = "quantity"
    case unit = "unit"
    case currency = "currency"
    case percentage = "percentage"
    case postalCode = "postal_code"
    case state = "state"
    case country = "country"
    
    public var displayName: String {
        switch self {
        case .price: return "Price"
        case .number: return "Number"
        case .date: return "Date"
        case .address: return "Address"
        case .email: return "Email"
        case .phone: return "Phone"
        case .url: return "URL"
        case .general: return "General Text"
        case .name: return "Name"
        case .idNumber: return "ID Number"
        case .stationName: return "Station Name"
        case .total: return "Total"
        case .vendor: return "Vendor"
        case .expiryDate: return "Expiry Date"
        case .quantity: return "Quantity"
        case .unit: return "Unit"
        case .currency: return "Currency"
        case .percentage: return "Percentage"
        case .postalCode: return "Postal Code"
        case .state: return "State"
        case .country: return "Country"
        }
    }
}

// MARK: - Document Types

/// Types of documents that can be analyzed
public enum DocumentType: String, CaseIterable, Sendable {
    case receipt = "receipt"
    case invoice = "invoice"
    case businessCard = "business_card"
    case form = "form"
    case license = "license"
    case passport = "passport"
    case general = "general"
    
    // New document types for structured extraction
    case fuelReceipt = "fuel_receipt"
    case idDocument = "id_document"
    case medicalRecord = "medical_record"
    case legalDocument = "legal_document"
    
    public var displayName: String {
        switch self {
        case .receipt: return "Receipt"
        case .invoice: return "Invoice"
        case .businessCard: return "Business Card"
        case .form: return "Form"
        case .license: return "License"
        case .passport: return "Passport"
        case .general: return "General Document"
        case .fuelReceipt: return "Fuel Receipt"
        case .idDocument: return "ID Document"
        case .medicalRecord: return "Medical Record"
        case .legalDocument: return "Legal Document"
        }
    }
}

// MARK: - Extraction Mode

/// Modes for structured data extraction
public enum ExtractionMode: String, CaseIterable, Sendable {
    case automatic = "automatic"    // Use built-in patterns
    case custom = "custom"         // Use provided hints
    case hybrid = "hybrid"         // Combine automatic + custom
    
    public var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .custom: return "Custom"
        case .hybrid: return "Hybrid"
        }
    }
}

// MARK: - OCR text inference & uncategorized extractions

/// A typed text fragment recognized by Vision that was **not** promoted into ``OCRResult/structuredData``
/// (e.g. pump readouts without a matching hint field). Ordered in reading order; labels are stable per run.
public struct UncategorizedOCRExtraction: Sendable, Equatable {
    public let label: String
    public let inferredTextType: TextType
    public let value: String
    
    public init(label: String, inferredTextType: TextType, value: String) {
        self.label = label
        self.inferredTextType = inferredTextType
        self.value = value
    }
}

/// Coarse classification for a single OCR text fragment (Vision line or substring).
public enum OCRTextTypeInference: Sendable {
    public static func inferredType(for text: String) -> TextType {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return .general }
        if t.contains("$") || t.contains("€") || t.contains("£") || t.contains("¥") {
            return .price
        }
        if t.allSatisfy({ $0.isNumber || $0 == "." || $0 == "," }) {
            return .number
        }
        if t.contains("@") {
            return .email
        }
        if t.hasPrefix("http") || t.hasPrefix("www") {
            return .url
        }
        if t.range(of: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#, options: .regularExpression) != nil {
            return .date
        }
        return .general
    }
}

public enum OCRUncategorizedExtractionBuilder: Sendable {
    /// Builds ordered ``UncategorizedOCRExtraction`` values from Vision lines (reading order).
    /// Skips trimmed lines that exactly match a structured field value.
    /// By default only includes ``TextType/number``, ``TextType/date``, and ``TextType/price`` clusters.
    public static func build(
        recognizedLines: [String],
        structuredValues: Set<String>,
        includeEmailAndURL: Bool = false
    ) -> [UncategorizedOCRExtraction] {
        var out: [UncategorizedOCRExtraction] = []
        var counts: [TextType: Int] = [:]
        for line in recognizedLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let inferred = OCRTextTypeInference.inferredType(for: trimmed)
            guard isUncategorizedCandidate(inferred, includeEmailAndURL: includeEmailAndURL) else { continue }
            if structuredValues.contains(trimmed) { continue }
            let nextIndex = (counts[inferred] ?? 0) + 1
            counts[inferred] = nextIndex
            let label = "\(inferred.rawValue)[\(nextIndex)]"
            out.append(UncategorizedOCRExtraction(label: label, inferredTextType: inferred, value: trimmed))
        }
        return out
    }
    
    private static func isUncategorizedCandidate(_ t: TextType, includeEmailAndURL: Bool) -> Bool {
        switch t {
        case .number, .date, .price:
            return true
        case .email, .url:
            return includeEmailAndURL
        default:
            return false
        }
    }
}

// MARK: - Vision OCR defaults

/// Shared defaults for Vision text recognition requests.
public enum OCRVisionDefaults: Sendable {
    /// Minimum text height as a fraction of image height.
    /// `0.01` drops pump LCD digits on full-resolution photos; `0.003` retains them (#288).
    public static let minimumTextHeight: Float = 0.003
}

// MARK: - OCR Context

/// Context information for OCR operations
public struct OCRContext: Sendable {
    public let textTypes: [TextType]
    public let language: OCRLanguage
    public let confidenceThreshold: Float
    public let allowsEditing: Bool
    public let maxImageSize: CGSize?
    
    // New structured extraction properties
    public let extractionHints: [String: String] // field name -> regex pattern
    public let requiredFields: [String]
    public let extractionMode: ExtractionMode
    
    /// Entity/model name for hints file loading
    /// Specifies which .hints file to load (e.g., "FuelPurchase", "Expense", "Address", etc.)
    /// The framework will automatically load "{entityName}.hints" from the Hints/ folder
    /// This is the primary way to specify which data model's hints to use for OCR extraction
    /// 
    /// If nil, no hints file will be loaded automatically. The framework will:
    /// - Use custom extractionHints (if provided)
    /// - Skip automatic ocrHints conversion and calculation groups
    /// 
    /// This allows developers to opt out of hints-based extraction if they don't need it.
    public let entityName: String?
    
    /// Runtime override for field value ranges
    /// Maps field names to value ranges that override hints file values
    /// This allows app-level logic to dynamically adjust expected ranges based on context
    /// (e.g., different ranges for trucks vs motorcycles, even though hints file is static)
    /// 
    /// Example: ["gallons": ValueRange(min: 20, max: 100)] to override hints file range
    /// If a field is not in this dictionary, the hints file range (if any) will be used
    public let fieldRanges: [String: ValueRange]?
    
    /// Typical/average values for fields (provided by application)
    /// Used to identify values that are within expected range but unusual compared to typical usage
    /// Helps flag values for verification even when they're technically within range
    /// 
    /// Example: If average gas price is 4.34, a value of 9.99 (within range 2.0-10.0) is unusual
    /// and should be flagged for verification, even though it's within the expected range
    /// 
    /// This is particularly useful when expected ranges are broad but typical values are narrower
    public let fieldAverages: [String: Double]?
    
    /// When `true`, Vision observations are filtered by ``textTypes`` using coarse ``OCRTextTypeInference``.
    /// When `false` (default), no per-line type filtering is applied so numeric and label text is not dropped
    /// solely because the app requested semantic types like ``TextType/quantity`` (GitHub #279).
    public let strictVisionTextTypeFiltering: Bool
    
    /// Vision `VNRecognizeTextRequest.minimumTextHeight` (fraction of image height).
    /// Lower values retain small pump LCD digits on full-resolution photos (#288).
    public let visionMinimumTextHeight: Float
    
    public init(
        textTypes: [TextType] = [.general],
        language: OCRLanguage = .english,
        confidenceThreshold: Float = 0.35,
        allowsEditing: Bool = true,
        maxImageSize: CGSize? = nil,
        extractionHints: [String: String] = [:],
        requiredFields: [String] = [],
        extractionMode: ExtractionMode = .automatic,
        entityName: String? = nil,
        fieldRanges: [String: ValueRange]? = nil,
        fieldAverages: [String: Double]? = nil,
        strictVisionTextTypeFiltering: Bool = false,
        visionMinimumTextHeight: Float = OCRVisionDefaults.minimumTextHeight
    ) {
        self.textTypes = textTypes
        self.language = language
        self.confidenceThreshold = confidenceThreshold
        self.allowsEditing = allowsEditing
        self.maxImageSize = maxImageSize
        self.extractionHints = extractionHints
        self.requiredFields = requiredFields
        self.extractionMode = extractionMode
        self.entityName = entityName
        self.fieldRanges = fieldRanges
        self.fieldAverages = fieldAverages
        self.strictVisionTextTypeFiltering = strictVisionTextTypeFiltering
        self.visionMinimumTextHeight = visionMinimumTextHeight
    }
    
    /// Text types supplied to Vision for observation filtering. Empty means **no** per-line type filter.
    public var visionStrategySupportedTextTypes: [TextType] {
        strictVisionTextTypeFiltering ? textTypes : []
    }
}

// MARK: - OCR Language

/// Supported languages for OCR
public enum OCRLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case arabic = "ar"
    case russian = "ru"
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .arabic: return "Arabic"
        case .russian: return "Russian"
        }
    }
}

// MARK: - OCR Result

/// Result of OCR text recognition
public struct OCRResult: Sendable {
    public let extractedText: String
    public let confidence: Float
    public let boundingBoxes: [CGRect]
    public let textTypes: [TextType: String]
    public let processingTime: TimeInterval
    public let language: OCRLanguage?
    
    // New structured extraction properties
    public let structuredData: [String: String]
    public let extractionConfidence: Float
    public let missingRequiredFields: [String]
    
    // Field adjustment tracking
    /// Fields that were adjusted during extraction (e.g., decimal correction, range inference)
    /// Maps field ID to a description of what was adjusted
    public let adjustedFields: [String: String]
    
    // Validation properties
    public let isValid: Bool
    public let validationReason: String?
    
    /// Typed fragments that did not become ``structuredData`` entries (reading order; GitHub #279).
    public let uncategorizedExtractions: [UncategorizedOCRExtraction]
    
    public init(
        extractedText: String,
        confidence: Float,
        boundingBoxes: [CGRect] = [],
        textTypes: [TextType: String] = [:],
        processingTime: TimeInterval = 0.0,
        language: OCRLanguage? = nil,
        structuredData: [String: String] = [:],
        extractionConfidence: Float = 0.0,
        missingRequiredFields: [String] = [],
        adjustedFields: [String: String] = [:],
        uncategorizedExtractions: [UncategorizedOCRExtraction] = [],
        isValid: Bool? = nil,
        validationReason: String? = nil
    ) {
        self.extractedText = extractedText
        self.confidence = confidence
        self.boundingBoxes = boundingBoxes
        self.textTypes = textTypes
        self.processingTime = processingTime
        self.language = language
        self.structuredData = structuredData
        self.extractionConfidence = extractionConfidence
        self.missingRequiredFields = missingRequiredFields
        self.adjustedFields = adjustedFields
        self.uncategorizedExtractions = uncategorizedExtractions
        
        // Set validation properties - use provided value or compute from confidence
        self.isValid = isValid ?? (confidence >= 0.5)
        self.validationReason = validationReason
    }
    
    /// Filter the result by confidence threshold
    public func filtered(by threshold: Float) -> OCRResult {
        if confidence >= threshold {
            return self
        } else {
            return OCRResult(
                extractedText: "",
                confidence: confidence,
                boundingBoxes: [],
                textTypes: [:],
                processingTime: processingTime,
                language: language,
                structuredData: [:],
                extractionConfidence: extractionConfidence,
                missingRequiredFields: missingRequiredFields,
                adjustedFields: adjustedFields,
                uncategorizedExtractions: [],
                isValid: false,
                validationReason: "Confidence below threshold (\(threshold))"
            )
        }
    }
    
    /// Get text for a specific type
    public func text(for type: TextType) -> String? {
        return textTypes[type]
    }
    
    /// Get all recognized text types
    public var recognizedTextTypes: [TextType] {
        return Array(textTypes.keys)
    }
    
    /// Whether the structured extraction is complete (no missing required fields)
    public var isStructuredExtractionComplete: Bool {
        return missingRequiredFields.isEmpty
    }
    
    /// Get the structured extraction confidence
    public var structuredExtractionConfidence: Float {
        return extractionConfidence
    }
}

// MARK: - OCR Configuration

/// Configuration for OCR operations
public struct OCRConfiguration {
    public let textTypes: [TextType]
    public let language: OCRLanguage
    public let confidenceThreshold: Float
    public let allowsEditing: Bool
    public let maxImageSize: CGSize?
    public let processingOptions: OCRProcessingOptions
    
    public init(
        textTypes: [TextType] = [.general],
        language: OCRLanguage = .english,
        confidenceThreshold: Float = 0.35,
        allowsEditing: Bool = true,
        maxImageSize: CGSize? = nil,
        processingOptions: OCRProcessingOptions = OCRProcessingOptions()
    ) {
        self.textTypes = textTypes
        self.language = language
        self.confidenceThreshold = confidenceThreshold
        self.allowsEditing = allowsEditing
        self.maxImageSize = maxImageSize
        self.processingOptions = processingOptions
    }
}

// MARK: - OCR Processing Options

/// Options for OCR processing
public struct OCRProcessingOptions {
    public let enableLanguageDetection: Bool
    public let enableTextCorrection: Bool
    public let enableBoundingBoxDetection: Bool
    public let enableTextTypeClassification: Bool
    public let maxProcessingTime: TimeInterval
    
    public init(
        enableLanguageDetection: Bool = true,
        enableTextCorrection: Bool = true,
        enableBoundingBoxDetection: Bool = true,
        enableTextTypeClassification: Bool = true,
        maxProcessingTime: TimeInterval = 30.0
    ) {
        self.enableLanguageDetection = enableLanguageDetection
        self.enableTextCorrection = enableTextCorrection
        self.enableBoundingBoxDetection = enableBoundingBoxDetection
        self.enableTextTypeClassification = enableTextTypeClassification
        self.maxProcessingTime = maxProcessingTime
    }
}

// MARK: - Text Recognition Options

/// Options for text recognition
public struct TextRecognitionOptions {
    public let textTypes: [TextType]
    public let language: OCRLanguage
    public let confidenceThreshold: Float
    public let enableBoundingBoxes: Bool
    public let enableTextCorrection: Bool
    
    public init(
        textTypes: [TextType] = [.general],
        language: OCRLanguage = .english,
        confidenceThreshold: Float = 0.8,
        enableBoundingBoxes: Bool = true,
        enableTextCorrection: Bool = true
    ) {
        self.textTypes = textTypes
        self.language = language
        self.confidenceThreshold = confidenceThreshold
        self.enableBoundingBoxes = enableBoundingBoxes
        self.enableTextCorrection = enableTextCorrection
    }
}

// MARK: - OCR Device Capabilities

/// Device capabilities for OCR operations
public struct OCRDeviceCapabilities {
    public let hasVisionFramework: Bool
    public let hasNeuralEngine: Bool
    public let maxImageSize: CGSize
    public let supportedLanguages: [OCRLanguage]
    public let processingPower: OCRProcessingPower
    
    public init(
        hasVisionFramework: Bool = true,
        hasNeuralEngine: Bool = false,
        maxImageSize: CGSize = CGSize(width: 4000, height: 4000),
        supportedLanguages: [OCRLanguage] = [.english],
        processingPower: OCRProcessingPower = .standard
    ) {
        self.hasVisionFramework = hasVisionFramework
        self.hasNeuralEngine = hasNeuralEngine
        self.maxImageSize = maxImageSize
        self.supportedLanguages = supportedLanguages
        self.processingPower = processingPower
    }
}

// MARK: - OCR Processing Power

/// Processing power levels for OCR
public enum OCRProcessingPower: String, CaseIterable {
    case low = "low"
    case standard = "standard"
    case high = "high"
    case neural = "neural"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Power"
        case .standard: return "Standard"
        case .high: return "High Performance"
        case .neural: return "Neural Engine"
        }
    }
}

// MARK: - OCR Layout

/// Layout information for OCR operations
public struct OCRLayout {
    public let maxImageSize: CGSize
    public let recommendedImageSize: CGSize
    public let processingMode: OCRProcessingMode
    public let uiConfiguration: OCRUIConfiguration
    
    public init(
        maxImageSize: CGSize,
        recommendedImageSize: CGSize,
        processingMode: OCRProcessingMode = .standard,
        uiConfiguration: OCRUIConfiguration = OCRUIConfiguration()
    ) {
        self.maxImageSize = maxImageSize
        self.recommendedImageSize = recommendedImageSize
        self.processingMode = processingMode
        self.uiConfiguration = uiConfiguration
    }
}

// MARK: - OCR Processing Mode

/// Processing modes for OCR
public enum OCRProcessingMode: String, CaseIterable, Sendable {
    case fast = "fast"
    case standard = "standard"
    case accurate = "accurate"
    case neural = "neural"
    
    public var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .standard: return "Standard"
        case .accurate: return "Accurate"
        case .neural: return "Neural Engine"
        }
    }
}

// MARK: - OCR UI Configuration

/// UI configuration for OCR operations
public struct OCRUIConfiguration {
    public let showProgress: Bool
    public let showConfidence: Bool
    public let showBoundingBoxes: Bool
    public let allowEditing: Bool
    public let theme: OCRTheme
    
    public init(
        showProgress: Bool = true,
        showConfidence: Bool = false,
        showBoundingBoxes: Bool = true,
        allowEditing: Bool = true,
        theme: OCRTheme = .system
    ) {
        self.showProgress = showProgress
        self.showConfidence = showConfidence
        self.showBoundingBoxes = showBoundingBoxes
        self.allowEditing = allowEditing
        self.theme = theme
    }
}

// MARK: - OCR Theme

/// Themes for OCR UI
public enum OCRTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case highContrast = "high_contrast"
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .highContrast: return "High Contrast"
        }
    }
}

// MARK: - OCR Strategy

/// Strategy for OCR operations
public struct OCRStrategy: Sendable {
    public let supportedTextTypes: [TextType]
    public let supportedLanguages: [OCRLanguage]
    public let processingMode: OCRProcessingMode
    public let requiresNeuralEngine: Bool
    public let estimatedProcessingTime: TimeInterval
    
    public init(
        supportedTextTypes: [TextType],
        supportedLanguages: [OCRLanguage],
        processingMode: OCRProcessingMode,
        requiresNeuralEngine: Bool = false,
        estimatedProcessingTime: TimeInterval = 1.0
    ) {
        self.supportedTextTypes = supportedTextTypes
        self.supportedLanguages = supportedLanguages
        self.processingMode = processingMode
        self.requiresNeuralEngine = requiresNeuralEngine
        self.estimatedProcessingTime = estimatedProcessingTime
    }
}

// MARK: - Built-in Patterns

/// Library of built-in regex patterns for common document types
public struct BuiltInPatterns {
    public static let patterns: [DocumentType: [String: String]] = [
        .fuelReceipt: [
            "price": #"\$(\d+\.\d{2})"#,
            "gallons": #"(\d+\.\d{2})\s*gal"#,
            "station": #"Station:\s*([A-Za-z\s]+)"#
        ],
        .invoice: [
            "total": #"Total:\s*\$(\d+\.\d{2})"#,
            "date": #"Date:\s*(\d{2}/\d{2}/\d{4})"#,
            "vendor": #"From:\s*([A-Za-z\s]+)"#
        ],
        .businessCard: [
            "name": #"Name:\s*([A-Za-z\s]+)"#,
            "phone": #"(\d{3}-\d{3}-\d{4})"#,
            "email": #"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})"#
        ],
        .idDocument: [
            "name": #"Name:\s*([A-Za-z\s]+)"#,
            "idNumber": #"ID#:\s*([A-Z0-9]+)"#,
            "expiry": #"Exp:\s*(\d{2}/\d{2}/\d{4})"#
        ]
    ]
}

// MARK: - Barcode Types

/// Types of barcodes that can be detected
public enum BarcodeType: String, CaseIterable, Sendable {
    // 1D Barcodes
    case ean8 = "ean8"
    case ean13 = "ean13"
    case upcA = "upcA"
    case upcE = "upcE"
    case code128 = "code128"
    case code39 = "code39"
    case code93 = "code93"
    case codabar = "codabar"
    case interleaved2of5 = "interleaved2of5"
    case itf14 = "itf14"
    case msiPlessey = "msiPlessey"
    
    // 2D Barcodes
    case qrCode = "qrCode"
    case dataMatrix = "dataMatrix"
    case pdf417 = "pdf417"
    case aztec = "aztec"
    
    public var displayName: String {
        switch self {
        case .ean8: return "EAN-8"
        case .ean13: return "EAN-13"
        case .upcA: return "UPC-A"
        case .upcE: return "UPC-E"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .codabar: return "Codabar"
        case .interleaved2of5: return "Interleaved 2 of 5"
        case .itf14: return "ITF-14"
        case .msiPlessey: return "MSI Plessey"
        case .qrCode: return "QR Code"
        case .dataMatrix: return "Data Matrix"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        }
    }
    
    /// Whether this is a 1D barcode type
    public var is1D: Bool {
        switch self {
        case .ean8, .ean13, .upcA, .upcE, .code128, .code39, .code93, .codabar, .interleaved2of5, .itf14, .msiPlessey:
            return true
        case .qrCode, .dataMatrix, .pdf417, .aztec:
            return false
        }
    }
    
    /// Whether this is a 2D barcode type
    public var is2D: Bool {
        return !is1D
    }
    
    /// Convert to VNBarcodeSymbology (for Vision framework)
    #if canImport(Vision)
    @available(iOS 11.0, macOS 10.15, visionOS 1.0, *)
    public var vnSymbology: VNBarcodeSymbology? {
        switch self {
        case .ean8: return .ean8
        case .ean13: return .ean13
        case .upcE: return .upce
        case .code128: return .code128
        case .code39: return .code39
        case .code93: return .code93
        case .interleaved2of5: return .i2of5
        case .itf14: return .itf14
        case .qrCode: return .qr
        case .dataMatrix: return .dataMatrix
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        // Note: UPC-A, Codabar, and MSI Plessey are not directly supported by Vision framework
        // UPC-A can be detected via EAN-13, but we'll return nil for unsupported types
        case .upcA, .codabar, .msiPlessey:
            return nil
        }
    }
    #endif
}

// MARK: - Barcode Context

/// Context information for barcode scanning operations
public struct BarcodeContext: Sendable {
    public let supportedBarcodeTypes: [BarcodeType]
    public let confidenceThreshold: Float
    public let allowsMultipleBarcodes: Bool
    public let maxImageSize: CGSize?
    
    public init(
        supportedBarcodeTypes: [BarcodeType] = BarcodeType.allCases,
        confidenceThreshold: Float = 0.8,
        allowsMultipleBarcodes: Bool = true,
        maxImageSize: CGSize? = nil
    ) {
        self.supportedBarcodeTypes = supportedBarcodeTypes
        self.confidenceThreshold = confidenceThreshold
        self.allowsMultipleBarcodes = allowsMultipleBarcodes
        self.maxImageSize = maxImageSize
    }
}

// MARK: - Barcode

/// Represents a detected barcode
public struct Barcode: Sendable {
    public let payload: String
    public let barcodeType: BarcodeType
    public let boundingBox: CGRect
    public let confidence: Float
    
    public init(
        payload: String,
        barcodeType: BarcodeType,
        boundingBox: CGRect,
        confidence: Float
    ) {
        self.payload = payload
        self.barcodeType = barcodeType
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

// MARK: - Barcode Result

/// Result of barcode scanning operation
public struct BarcodeResult: Sendable {
    public let barcodes: [Barcode]
    public let confidence: Float
    public let processingTime: TimeInterval
    
    public init(
        barcodes: [Barcode],
        confidence: Float,
        processingTime: TimeInterval
    ) {
        self.barcodes = barcodes
        self.confidence = confidence
        self.processingTime = processingTime
    }
    
    /// Whether any barcodes were detected
    public var hasBarcodes: Bool {
        return !barcodes.isEmpty
    }
    
    /// Filter barcodes by type
    public func filtered(by type: BarcodeType) -> [Barcode] {
        return barcodes.filter { $0.barcodeType == type }
    }
    
    /// Filter barcodes by confidence threshold
    public func filtered(by threshold: Float) -> BarcodeResult {
        let filtered = barcodes.filter { $0.confidence >= threshold }
        let avgConfidence = filtered.isEmpty ? 0.0 : filtered.map { $0.confidence }.reduce(0, +) / Float(filtered.count)
        return BarcodeResult(
            barcodes: filtered,
            confidence: avgConfidence,
            processingTime: processingTime
        )
    }
}

// MARK: - Barcode Error Types

/// Barcode-specific error types
public enum BarcodeError: Error, LocalizedError {
    case visionUnavailable
    case invalidImage
    case noBarcodeFound
    case processingFailed
    case unsupportedPlatform
    
    public var errorDescription: String? {
        let i18n = InternationalizationService()
        switch self {
        case .visionUnavailable:
            return i18n.localizedString(for: "SixLayerFramework.barcode.visionUnavailable")
        case .invalidImage:
            return i18n.localizedString(for: "SixLayerFramework.barcode.invalidImage")
        case .noBarcodeFound:
            return i18n.localizedString(for: "SixLayerFramework.barcode.noBarcodeFound")
        case .processingFailed:
            return i18n.localizedString(for: "SixLayerFramework.barcode.processingFailed")
        case .unsupportedPlatform:
            return i18n.localizedString(for: "SixLayerFramework.barcode.unsupportedPlatform")
        }
    }
}

// MARK: - Barcode Capabilities

/// Platform-specific barcode scanning capabilities
public struct BarcodeCapabilities {
    public let supportsVision: Bool
    public let supportedBarcodeTypes: [BarcodeType]
    public let maxImageSize: CGSize
    public let processingTimeEstimate: TimeInterval
    
    public init(
        supportsVision: Bool,
        supportedBarcodeTypes: [BarcodeType],
        maxImageSize: CGSize,
        processingTimeEstimate: TimeInterval
    ) {
        self.supportsVision = supportsVision
        self.supportedBarcodeTypes = supportedBarcodeTypes
        self.maxImageSize = maxImageSize
        self.processingTimeEstimate = processingTimeEstimate
    }
}



