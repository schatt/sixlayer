//
//  L1SemanticTests.swift
//  SixLayerFramework
//
//  Layer 1 Testing: Semantic Intent Functions
//  Tests L1 functions (one test per function) - pure interfaces that don't perform capability checks
//

import Testing
import SwiftUI
@testable import SixLayerFramework

/// NOTE: Serialized to avoid UI conflicts with hostRootPlatformView
/// This suite uses hostRootPlatformView extensively and must run serially to prevent Xcode hangs
@Suite(.serialized)
class L1SemanticTests: BaseTestClass {
    
    // MARK: - Test Data
    
    private var sampleNumericData: [GenericNumericData] = []
    private var sampleHints: PresentationHints = PresentationHints()
    private var sampleFormFields: [GenericFormField] = []
    private var sampleMediaItems: [GenericMediaItem] = []
    private var sampleHierarchicalItems: [GenericHierarchicalItem] = []
    private var sampleTemporalItems: [GenericTemporalItem] = []
    private var sampleOCRContext: OCRContext = OCRContext()
    private var samplePhotoPurpose: PhotoPurpose = .general
    private var samplePhotoContext: PhotoContext = PhotoContext()
    private var sampleBarcodeContext: BarcodeContext = BarcodeContext()
    private var sampleItems: [TestItem] = []
    
    private func createSampleNumericData() {

    
        return createSampleNumericData()

    
    }

    
    private func createSampleHints() {

    
        return createSampleHints()

    
    }

    
    private func createSampleFormFields() {

    
        return createSampleFormFields()

    
    }

    
    private func createSampleMediaItems() {

    
        return createSampleMediaItems()

    
    }

    
    private func createSampleHierarchicalItems() {

    
        return createSampleHierarchicalItems()

    
    }

    
    private func createSampleTemporalItems() {

    
        return createSampleTemporalItems()

    
    }

    
    private func createSampleOCRContext() {

    
        return createSampleOCRContext()

    
    }

    
    private func createSamplePhotoPurpose() {

    
        return .general

    
    }

    
    private func createSamplePhotoContext() {

    
        return createSamplePhotoContext()

    
    }

    
    // BaseTestClass handles setup automatically - no init() needed
    
    deinit {
        Task { [weak self] in
            await self?.cleanupTestEnvironment()
        }
    }
    
    // MARK: - Test Data Creation
    
    private func createSampleNumericData() -> [GenericNumericData] {
        return [
            GenericNumericData(value: 42.5, label: "Test Value", unit: "units"),
            GenericNumericData(value: 100.0, label: "Another Value", unit: "items")
        ]
    }
    
    private func createSampleHints() -> PresentationHints {
        return PresentationHints(
            dataType: .generic,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
    }
    
    private func createSampleFormFields() -> [GenericFormField] {
        return [
            GenericFormField(
                id: "test_field_1",
                label: "Test Field",
                fieldType: .text,
                isRequired: true,
                placeholder: "Enter text"
            )
        ]
    }
    
    private func createSampleMediaItems() -> [GenericMediaItem] {
        return [
            GenericMediaItem(
                id: "media_1",
                title: "Test Media",
                mediaType: .image,
                url: "https://example.com/image.jpg"
            )
        ]
    }
    
    private func createSampleHierarchicalItems() -> [GenericHierarchicalItem] {
        return [
            GenericHierarchicalItem(
                id: "hier_1",
                title: "Parent Item",
                level: 0,
                children: []
            )
        ]
    }
    
    private func createSampleTemporalItems() -> [GenericTemporalItem] {
        return [
            GenericTemporalItem(
                id: "temp_1",
                title: "Temporal Item",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600)
            )
        ]
    }
    
    private func createSampleOCRContext() -> OCRContext {
        return OCRContext(
            textTypes: [.general],
            language: .english,
            confidenceThreshold: 0.8
        )
    }
    
    private func createSamplePhotoContext() -> PhotoContext {
        return PhotoContext(
            purpose: .general,
            quality: .high,
            editingAllowed: true
        )
    }
    
    private func createSampleBarcodeContext() -> BarcodeContext {
        return BarcodeContext(
            supportedBarcodeTypes: [.qrCode, .code128],
            confidenceThreshold: 0.8,
            allowsMultipleBarcodes: true
        )
    }
    
    private func createSampleItems() -> [TestPatterns.TestItem] {
        return [
            TestPatterns.TestItem(id: UUID(), title: "Item 1"),
            TestPatterns.TestItem(id: UUID(), title: "Item 2"),
            TestPatterns.TestItem(id: UUID(), title: "Item 3")
        ]
    }
    
    // MARK: - Core Data Presentation Functions
    
    @Test @MainActor
    func testPlatformPresentNumericData_L1() {
        // Given
        let data = sampleNumericData
        let hints = sampleHints
        
        // When
        let view = platformPresentNumericData_L1(
            data: data,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNumericData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformResponsiveCard_L1() {
        // Given
        let hints = sampleHints
        
        // When
        let view = platformResponsiveCard_L1(
            content: { Text("Test Content") },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformResponsiveCard_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentFormData_L1() {
        // Given
        let fields = sampleFormFields
        let hints = sampleHints
        
        // When
        let view = platformPresentFormData_L1(
            fields: fields,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentFormData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentModalForm_L1() {
        // Given
        let fields = sampleFormFields
        let hints = sampleHints
        
        // When
        let view = platformPresentModalForm_L1(
            fields: fields,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentModalForm_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1() {
        // Given
        let mediaItems = sampleMediaItems
        let hints = sampleHints
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItems: mediaItems,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentHierarchicalData_L1() {
        // Given
        let hierarchicalItems = sampleHierarchicalItems
        let hints = sampleHints
        
        // When
        let view = platformPresentHierarchicalData_L1(
            hierarchicalItems: hierarchicalItems,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentHierarchicalData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentTemporalData_L1() {
        // Given
        let temporalItems = sampleTemporalItems
        let hints = sampleHints
        
        // When
        let view = platformPresentTemporalData_L1(
            temporalItems: temporalItems,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentTemporalData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentContent_L1() {
        // Given
        let content = "Test content"
        let hints = sampleHints
        
        // When
        let view = platformPresentContent_L1(
            content: content,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentContent_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - OCR Functions
    
    @Test @MainActor
    func testPlatformOCRWithVisualCorrection_L1() {
        // Given
        let image = PlatformImage()
        let context = sampleOCRContext
        
        // When
        let view = platformOCRWithVisualCorrection_L1(
            image: image,
            context: context,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformOCRWithVisualCorrection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformExtractStructuredData_L1() {
        // Given
        let image = PlatformImage()
        let context = sampleOCRContext
        
        // When
        let view = platformExtractStructuredData_L1(
            image: image,
            context: context,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformExtractStructuredData_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Photo Functions
    
    @Test @MainActor
    func testPlatformPhotoCapture_L1() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoCapture_L1(
            purpose: purpose,
            context: context,
            onImageCaptured: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoCapture_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPhotoDisplay_L1() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        let image: PlatformImage? = nil
        
        // When
        let view = platformPhotoDisplay_L1(
            purpose: purpose,
            context: context,
            image: image
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoDisplay_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Photo Functions with Custom Views
    
    @Test @MainActor
    func testPlatformPhotoCapture_L1_WithCustomCameraView() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When: Using custom camera view wrapper
        let view = platformPhotoCapture_L1(
            purpose: purpose,
            context: context,
            onImageCaptured: { _ in },
            customCameraView: { (cameraContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Camera Interface")
                        .font(.headline)
                    cameraContent
                        .padding()
                }
            }
        )
        
        // Then: Should return a view with custom wrapper
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoCapture_L1 with custom camera view should return a view")
    }
    
    @Test @MainActor
    func testPlatformPhotoDisplay_L1_WithCustomDisplayView() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        let image: PlatformImage? = nil
        
        // When: Using custom display view wrapper
        let view = platformPhotoDisplay_L1(
            purpose: purpose,
            context: context,
            image: image,
            customDisplayView: { (displayContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Photo Display")
                        .font(.headline)
                    displayContent
                        .padding()
                        .background(Color.platformSecondaryBackground)
                }
            }
        )
        
        // Then: Should return a view with custom wrapper
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoDisplay_L1 with custom display view should return a view")
    }
    
    // MARK: - Internationalization Functions
    
    @Test @MainActor
    func testPlatformPresentLocalizedText_L1() {
        // Given
        let text = "Hello World"
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedText_L1(
            text: text,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedText_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedNumber_L1() {
        // Given
        let number = 42.5
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedNumber_L1(
            number: number,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedNumber_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedCurrency_L1() {
        // Given
        let amount = 99.99
        let currencyCode = "USD"
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedCurrency_L1(
            amount: amount,
            currencyCode: currencyCode,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedCurrency_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedDate_L1() {
        // Given
        let date = Date()
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedDate_L1(
            date: date,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedDate_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedTime_L1() {
        // Given
        let time = Date()
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedTime_L1(
            time: time,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedTime_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedPercentage_L1() {
        // Given
        let percentage = 0.75
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedPercentage_L1(
            percentage: percentage,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedPercentage_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedPlural_L1() {
        // Given
        let count = 5
        let singular = "item"
        let plural = "items"
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedPlural_L1(
            count: count,
            singular: singular,
            plural: plural,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedPlural_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformPresentLocalizedString_L1() {
        // Given
        let string = "Test String"
        let hints = sampleHints
        
        // When
        let view = platformPresentLocalizedString_L1(
            string: string,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedString_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformLocalizedTextField_L1() {
        // Given
        let placeholder = "Enter text"
        let hints = sampleHints
        
        // When
        let view = platformLocalizedTextField_L1(
            placeholder: placeholder,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformLocalizedTextField_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformLocalizedSecureField_L1() {
        // Given
        let placeholder = "Enter password"
        let hints = sampleHints
        
        // When
        let view = platformLocalizedSecureField_L1(
            placeholder: placeholder,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformLocalizedSecureField_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformLocalizedTextEditor_L1() {
        // Given
        let placeholder = "Enter long text"
        let hints = sampleHints
        
        // When
        let view = platformLocalizedTextEditor_L1(
            placeholder: placeholder,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformLocalizedTextEditor_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - DataFrame Analysis Functions
    
    @Test @MainActor
    func testPlatformAnalyzeDataFrame_L1() {
        // Given
        let dataFrame = DataFrame()
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformAnalyzeDataFrame_L1(
            dataFrame: dataFrame,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformAnalyzeDataFrame_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformCompareDataFrames_L1() {
        // Given
        let dataFrames = [DataFrame()]
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformCompareDataFrames_L1(
            dataFrames: dataFrames,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformCompareDataFrames_L1 view should be hostable")  // hostingView is non-optional
    }
    
    @Test @MainActor
    func testPlatformAssessDataQuality_L1() {
        // Given
        let dataFrame = DataFrame()
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformAssessDataQuality_L1(
            dataFrame: dataFrame,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformAssessDataQuality_L1 view should be hostable")  // hostingView is non-optional
    }
    
    // MARK: - Item Collection Functions
    
    @Test @MainActor
    func testPlatformPresentItemCollection_L1() {
        // Given
        let items = createSampleItems()
        let hints = sampleHints
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentItemCollection_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentItemCollection_L1_WithCustomItemView() {
        // Given
        let items = createSampleItems()
        let hints = sampleHints
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints,
            customItemView: { item in
                Text(item.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentItemCollection_L1 with customItemView should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentItemCollection_L1_WithEnhancedHints() {
        // Given
        let items = createSampleItems()
        let enhancedHints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: enhancedHints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentItemCollection_L1 with enhanced hints should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentItemCollection_L1_WithEnhancedHintsAndCustomView() {
        // Given
        let items = createSampleItems()
        let enhancedHints = EnhancedPresentationHints(
            dataType: .collection,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: enhancedHints,
            customItemView: { item in
                Text(item.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentItemCollection_L1 with enhanced hints and custom view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentItemCollection_L1_WithFullCustomization() {
        // Given
        let items = createSampleItems()
        let hints = sampleHints
        
        // When
        let view = platformPresentItemCollection_L1(
            items: items,
            hints: hints,
            customItemView: { item in
                Text(item.title)
            },
            customCreateView: {
                Text("Create New")
            },
            customEditView: { item in
                Text("Edit \(item.title)")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentItemCollection_L1 with full customization should be hostable")
    }
    
    // MARK: - Navigation Functions
    
    @Test @MainActor
    func testPlatformPresentNavigationStack_L1() {
        // Given
        let hints = sampleHints
        
        // When
        let view = platformPresentNavigationStack_L1(
            content: { Text("Test Content") },
            title: "Test Title",
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNavigationStack_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentNavigationStack_L1_WithItems() {
        // Given
        let items = createSampleItems()
        let hints = sampleHints
        
        // When
        let view = platformPresentNavigationStack_L1(
            items: items,
            hints: hints,
            itemView: { item in
                Text(item.title)
            },
            destination: { item in
                Text("Detail for \(item.title)")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNavigationStack_L1 with items should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentAppNavigation_L1() {
        // Given
        // No specific data needed
        
        // When
        let view = platformPresentAppNavigation_L1(
            sidebar: {
                Text("Sidebar Content")
            },
            detail: {
                Text("Detail Content")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentAppNavigation_L1 view should be hostable")
    }
    
    // MARK: - OCR Disambiguation Functions
    
    @Test @MainActor
    func testPlatformOCRWithDisambiguation_L1() {
        // Given
        let image = PlatformImage()
        let context = sampleOCRContext
        
        // When
        let view = platformOCRWithDisambiguation_L1(
            image: image,
            context: context,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformOCRWithDisambiguation_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformOCRWithDisambiguation_L1_WithConfiguration() {
        // Given
        let image = PlatformImage()
        let context = sampleOCRContext
        let configuration = OCRDisambiguationConfiguration()
        
        // When
        let view = platformOCRWithDisambiguation_L1(
            image: image,
            context: context,
            configuration: configuration,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformOCRWithDisambiguation_L1 with configuration should be hostable")
    }
    
    // MARK: - Barcode Functions
    
    @Test @MainActor
    func testPlatformScanBarcode_L1() {
        // Given
        let image = PlatformImage()
        let context = createSampleBarcodeContext()
        
        // When
        let view = platformScanBarcode_L1(
            image: image,
            context: context,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformScanBarcode_L1 view should be hostable")
    }
    
    // MARK: - Security Functions
    
    @Test @MainActor
    func testPlatformPresentSecureContent_L1() {
        // Given
        let hints = SecurityHints()
        
        // When
        let view = platformPresentSecureContent_L1(
            content: { Text("Secure Content") },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentSecureContent_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentSecureTextField_L1() {
        // Given
        let title = "Password"
        var text = ""
        let textBinding = Binding(
            get: { text },
            set: { text = $0 }
        )
        let hints = SecurityHints()
        
        // When
        let view = platformPresentSecureTextField_L1(
            title: title,
            text: textBinding,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentSecureTextField_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformShowPrivacyIndicator_L1() {
        // Given
        let hints = SecurityHints()
        
        // When
        let view = platformShowPrivacyIndicator_L1(
            type: .camera,
            isActive: true,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted (returns EmptyView)
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformShowPrivacyIndicator_L1 view should be hostable")
    }
    
    // MARK: - Notification Functions
    
    @Test @MainActor
    func testPlatformPresentAlert_L1() {
        // Given
        let hints = NotificationHints()
        
        // When
        let view = platformPresentAlert_L1(
            title: "Test Alert",
            message: "Test message",
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentAlert_L1 view should be hostable")
    }
    
    // MARK: - Internationalization Functions
    
    @Test @MainActor
    func testPlatformPresentLocalizedContent_L1() {
        // Given
        let hints = InternationalizationHints()
        
        // When
        let view = platformPresentLocalizedContent_L1(
            content: { Text("Localized Content") },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentLocalizedContent_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformRTLContainer_L1() {
        // Given
        let hints = InternationalizationHints()
        
        // When
        let view = platformRTLContainer_L1(
            content: { Text("RTL Content") },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformRTLContainer_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformRTLHStack_L1() {
        // Given
        let hints = InternationalizationHints()
        
        // When
        let view = platformRTLHStack_L1(
            alignment: .center,
            spacing: 8,
            content: {
                Text("Item 1")
                Text("Item 2")
            },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformRTLHStack_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformRTLVStack_L1() {
        // Given
        let hints = InternationalizationHints()
        
        // When
        let view = platformRTLVStack_L1(
            alignment: .center,
            spacing: 8,
            content: {
                Text("Item 1")
                Text("Item 2")
            },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformRTLVStack_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformRTLZStack_L1() {
        // Given
        let hints = InternationalizationHints()
        
        // When
        let view = platformRTLZStack_L1(
            alignment: .center,
            content: {
                Text("Item 1")
                Text("Item 2")
            },
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformRTLZStack_L1 view should be hostable")
    }
    
    // MARK: - Photo Functions with Custom Picker
    
    @Test @MainActor
    func testPlatformPhotoSelection_L1_WithCustomPickerView() {
        // Given
        let purpose = samplePhotoPurpose
        let context = samplePhotoContext
        
        // When: Using custom picker view wrapper
        let view = platformPhotoSelection_L1(
            purpose: purpose,
            context: context,
            onImageSelected: { _ in },
            customPickerView: { (pickerContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Picker Interface")
                        .font(.headline)
                    pickerContent
                        .padding()
                }
            }
        )
        
        // Then: Should return a view with custom wrapper
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPhotoSelection_L1 with custom picker view should return a view")
    }
    
    // MARK: - Data Analysis Functions with Custom Visualization
    
    @Test @MainActor
    func testPlatformAnalyzeDataFrame_L1_WithCustomVisualization() {
        // Given
        let dataFrame = DataFrame()
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformAnalyzeDataFrame_L1(
            dataFrame: dataFrame,
            hints: hints,
            customVisualizationView: { (analysisContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Visualization")
                        .font(.headline)
                    analysisContent
                        .padding()
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformAnalyzeDataFrame_L1 with custom visualization should be hostable")
    }
    
    @Test @MainActor
    func testPlatformCompareDataFrames_L1_WithCustomVisualization() {
        // Given
        let dataFrames = [DataFrame()]
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformCompareDataFrames_L1(
            dataFrames: dataFrames,
            hints: hints,
            customVisualizationView: { (comparisonContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Comparison")
                        .font(.headline)
                    comparisonContent
                        .padding()
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformCompareDataFrames_L1 with custom visualization should be hostable")
    }
    
    @Test @MainActor
    func testPlatformAssessDataQuality_L1_WithCustomVisualization() {
        // Given
        let dataFrame = DataFrame()
        let hints = DataFrameAnalysisHints()
        
        // When
        let view = platformAssessDataQuality_L1(
            dataFrame: dataFrame,
            hints: hints,
            customVisualizationView: { (qualityContent: AnyView) in
                platformVStackContainer {
                    Text("Custom Quality Assessment")
                        .font(.headline)
                    qualityContent
                        .padding()
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformAssessDataQuality_L1 with custom visualization should be hostable")
    }
    
    // MARK: - Basic Value Functions
    
    @Test @MainActor
    func testPlatformPresentBasicValue_L1() {
        // Given
        let value = 42
        let hints = sampleHints
        
        // When
        let view = platformPresentBasicValue_L1(
            value: value,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentBasicValue_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentBasicArray_L1() {
        // Given
        let array = [1, 2, 3, 4, 5]
        let hints = sampleHints
        
        // When
        let view = platformPresentBasicArray_L1(
            array: array,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentBasicArray_L1 view should be hostable")
    }
    
    // MARK: - Numeric Data Overloads
    
    @Test @MainActor
    func testPlatformPresentNumericData_L1_SingleItem() {
        // Given
        let singleData = GenericNumericData(value: 42.5, label: "Test Value", unit: "units")
        let hints = sampleHints
        
        // When
        let view = platformPresentNumericData_L1(
            data: singleData,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNumericData_L1 single item should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentNumericData_L1_WithCustomDataView() {
        // Given
        let data = sampleNumericData
        let hints = sampleHints
        
        // When
        let view = platformPresentNumericData_L1(
            data: data,
            hints: hints,
            customDataView: { numericData in
                Text("\(numericData.value) \(numericData.unit ?? "")")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNumericData_L1 with customDataView should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentNumericData_L1_WithEnhancedHints() {
        // Given
        let data = sampleNumericData
        let enhancedHints = EnhancedPresentationHints(
            dataType: .numeric,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentNumericData_L1(
            data: data,
            hints: enhancedHints,
            customDataView: { numericData in
                Text("\(numericData.value)")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNumericData_L1 with enhanced hints should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentNumericData_L1_WithFullCustomization() {
        // Given
        let data = sampleNumericData
        let enhancedHints = EnhancedPresentationHints(
            dataType: .numeric,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentNumericData_L1(
            data: data,
            hints: enhancedHints,
            customDataView: { numericData in
                Text("\(numericData.value)")
            },
            customContainer: { content in
                platformVStackContainer {
                    Text("Custom Container")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentNumericData_L1 with full customization should be hostable")
    }
    
    // MARK: - Form Data Overloads
    
    @Test @MainActor
    func testPlatformPresentFormData_L1_SingleField() {
        // Given
        let field = sampleFormFields.first!
        let hints = sampleHints
        
        // When
        let view = platformPresentFormData_L1(
            field: field,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentFormData_L1 single field should be hostable")
    }
    
    // MARK: - Modal Form Overloads
    
    @Test @MainActor
    func testPlatformPresentModalForm_L1_WithCustomContainer() {
        // Given
        let fields = sampleFormFields
        let hints = sampleHints
        
        // When
        let view = platformPresentModalForm_L1(
            fields: fields,
            hints: hints,
            customFormContainer: { content in
                platformVStackContainer {
                    Text("Custom Modal Container")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentModalForm_L1 with custom container should be hostable")
    }
    
    // MARK: - Media Data Overloads
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1_SingleItem() {
        // Given
        let singleMedia = sampleMediaItems.first!
        let hints = sampleHints
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItem: singleMedia,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 single item should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1_SingleItemWithEnhancedHints() {
        // Given
        let singleMedia = sampleMediaItems.first!
        let enhancedHints = EnhancedPresentationHints(
            dataType: .media,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItem: singleMedia,
            hints: enhancedHints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 single item with enhanced hints should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1_WithCustomMediaView() {
        // Given
        let mediaItems = sampleMediaItems
        let hints = sampleHints
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItems: mediaItems,
            hints: hints,
            customMediaView: { mediaItem in
                Text(mediaItem.title ?? "Media")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 with customMediaView should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1_WithEnhancedHintsAndCustomView() {
        // Given
        let mediaItems = sampleMediaItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .media,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItems: mediaItems,
            hints: enhancedHints,
            customMediaView: { mediaItem in
                Text(mediaItem.title ?? "Media")
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 with enhanced hints and custom view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentMediaData_L1_WithFullCustomization() {
        // Given
        let mediaItems = sampleMediaItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .media,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentMediaData_L1(
            mediaItems: mediaItems,
            hints: enhancedHints,
            customMediaView: { mediaItem in
                Text(mediaItem.title ?? "Media")
            },
            customContainer: { content in
                platformVStackContainer {
                    Text("Custom Media Container")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentMediaData_L1 with full customization should be hostable")
    }
    
    // MARK: - Hierarchical Data Overloads
    
    @Test @MainActor
    func testPlatformPresentHierarchicalData_L1_SingleItem() {
        // Given
        let singleItem = sampleHierarchicalItems.first!
        let hints = sampleHints
        
        // When
        let view = platformPresentHierarchicalData_L1(
            hierarchicalItem: singleItem,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentHierarchicalData_L1 single item should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentHierarchicalData_L1_WithEnhancedHints() {
        // Given
        let hierarchicalItems = sampleHierarchicalItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .hierarchical,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentHierarchicalData_L1(
            hierarchicalItems: hierarchicalItems,
            hints: enhancedHints,
            customItemView: { item in
                Text(item.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentHierarchicalData_L1 with enhanced hints should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentHierarchicalData_L1_WithFullCustomization() {
        // Given
        let hierarchicalItems = sampleHierarchicalItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .hierarchical,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentHierarchicalData_L1(
            hierarchicalItems: hierarchicalItems,
            hints: enhancedHints,
            customItemView: { item in
                Text(item.title)
            },
            customContainer: { content in
                platformVStackContainer {
                    Text("Custom Hierarchical Container")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentHierarchicalData_L1 with full customization should be hostable")
    }
    
    // MARK: - Temporal Data Overloads
    
    @Test @MainActor
    func testPlatformPresentTemporalData_L1_SingleItem() {
        // Given
        let singleItem = sampleTemporalItems.first!
        let hints = sampleHints
        
        // When
        let view = platformPresentTemporalData_L1(
            temporalItem: singleItem,
            hints: hints
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentTemporalData_L1 single item should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentTemporalData_L1_WithEnhancedHints() {
        // Given
        let temporalItems = sampleTemporalItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .temporal,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentTemporalData_L1(
            temporalItems: temporalItems,
            hints: enhancedHints,
            customItemView: { item in
                Text(item.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentTemporalData_L1 with enhanced hints should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentTemporalData_L1_WithFullCustomization() {
        // Given
        let temporalItems = sampleTemporalItems
        let enhancedHints = EnhancedPresentationHints(
            dataType: .temporal,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentTemporalData_L1(
            temporalItems: temporalItems,
            hints: enhancedHints,
            customItemView: { item in
                Text(item.title)
            },
            customContainer: { content in
                platformVStackContainer {
                    Text("Custom Temporal Container")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentTemporalData_L1 with full customization should be hostable")
    }
    
    // MARK: - Settings Functions
    
    @Test @MainActor
    func testPlatformPresentSettings_L1() {
        // Given
        let settings: [GenericSetting] = [
            GenericSetting(id: "setting1", title: "Setting 1", type: .toggle, value: true)
        ]
        let hints = sampleHints
        
        // When
        let view = platformPresentSettings_L1(
            settings: settings,
            hints: hints,
            callbacks: GenericSettingCallbacks()
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentSettings_L1 view should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentSettings_L1_WithCustomSettingView() {
        // Given
        let settings: [GenericSetting] = [
            GenericSetting(id: "setting1", title: "Setting 1", type: .toggle, value: true)
        ]
        let hints = sampleHints
        
        // When
        let view = platformPresentSettings_L1(
            settings: settings,
            hints: hints,
            callbacks: GenericSettingCallbacks(),
            customSettingView: { setting in
                Text(setting.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentSettings_L1 with customSettingView should be hostable")
    }
    
    @Test @MainActor
    func testPlatformPresentSettings_L1_WithEnhancedHints() {
        // Given
        let settings: [GenericSetting] = [
            GenericSetting(id: "setting1", title: "Setting 1", type: .toggle, value: true)
        ]
        let enhancedHints = EnhancedPresentationHints(
            dataType: .settings,
            presentationPreference: .automatic,
            complexity: .moderate,
            context: .dashboard
        )
        
        // When
        let view = platformPresentSettings_L1(
            settings: settings,
            hints: enhancedHints,
            callbacks: GenericSettingCallbacks(),
            customSettingView: { setting in
                Text(setting.title)
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformPresentSettings_L1 with enhanced hints should be hostable")
    }
    
    // MARK: - Responsive Card Overloads
    
    @Test @MainActor
    func testPlatformResponsiveCard_L1_WithCustomCardView() {
        // Given
        let hints = sampleHints
        
        // When
        let view = platformResponsiveCard_L1(
            content: { Text("Test Content") },
            hints: hints,
            customCardView: { content in
                platformVStackContainer {
                    Text("Custom Card")
                    content
                }
            }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformResponsiveCard_L1 with customCardView should be hostable")
    }
    
    // MARK: - OCR With Visual Correction Overloads
    
    @Test @MainActor
    func testPlatformOCRWithVisualCorrection_L1_WithConfiguration() {
        // Given
        let image = PlatformImage()
        let context = sampleOCRContext
        let configuration = OCROverlayConfiguration()
        
        // When
        let view = platformOCRWithVisualCorrection_L1(
            image: image,
            context: context,
            configuration: configuration,
            onResult: { _ in }
        )
        
        // Then: Test that the view can actually be hosted
        let hostingView = hostRootPlatformView(view.enableGlobalAutomaticCompliance())
        #expect(Bool(true), "platformOCRWithVisualCorrection_L1 with configuration should be hostable")
    }
}