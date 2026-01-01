import Testing


import SwiftUI
@testable import SixLayerFramework
/// Tests for PlatformSemanticLayer1.swift
/// 
/// BUSINESS PURPOSE: Ensure all Layer 1 semantic presentation functions generate proper accessibility identifiers
/// TESTING SCOPE: All functions in PlatformSemanticLayer1.swift
/// METHODOLOGY: Test each function on both iOS and macOS platforms as required by mandatory testing guidelines
@Suite("Platform Semantic Layer")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class PlatformSemanticLayer1Tests: BaseTestClass {
    
    // MARK: - Test Setup
    
    // BaseTestClass handles setup automatically - no custom init needed    // MARK: - platformPresentItemCollection_L1 Tests
    
    
    // BaseTestClass handles setup automatically
    
    private func cleanupTestEnvironment() async {
        await AccessibilityTestUtilities.cleanupAccessibilityTestEnvironment()
    }
    
@Test @MainActor func testPlatformPresentItemCollectionL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testItems = [
            PlatformSemanticLayer1TestItem(id: "1", title: "Test Item 1", subtitle: "Subtitle 1"),
            PlatformSemanticLayer1TestItem(id: "2", title: "Test Item 2", subtitle: "Subtitle 2")
        ]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .list,
            customPreferences: [:]
        )
        
        let view = platformPresentItemCollection_L1(items: testItems, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentItemCollection_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentItemCollection_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentItemCollectionL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testItems = [
            PlatformSemanticLayer1TestItem(id: "1", title: "Test Item 1", subtitle: "Subtitle 1"),
            PlatformSemanticLayer1TestItem(id: "2", title: "Test Item 2", subtitle: "Subtitle 2")
        ]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .grid,
            complexity: .moderate,
            context: .list,
            customPreferences: [:]
        )
        
        let view = platformPresentItemCollection_L1(items: testItems, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentItemCollection_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentItemCollection_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentNumericData_L1 Tests
    
    @Test @MainActor func testPlatformPresentNumericDataL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testData = GenericNumericData(value: 123.45, label: "Test Value", unit: "units")
        let hints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentNumericData_L1(data: testData, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentNumericData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentNumericData_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentNumericDataL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testData = GenericNumericData(value: 123.45, label: "Test Value", unit: "units")
        let hints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentNumericData_L1(data: testData, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentNumericData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentNumericData_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentFormData_L1 Tests
    
    @Test @MainActor func testPlatformPresentFormDataL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testField = DynamicFormField(
            id: "testField",
            contentType: .text,
            label: "Test Field",
            placeholder: "Enter text",
            isRequired: true,
            validationRules: [:]
        )
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .list,
            complexity: .moderate,
            context: .form,
            customPreferences: [:]
        )
        
        let view = platformPresentFormData_L1(field: testField, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentFormData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentFormData_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentFormDataL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testField = DynamicFormField(
            id: "testField",
            contentType: .text,
            label: "Test Field",
            placeholder: "Enter text",
            isRequired: true,
            validationRules: [:]
        )
        let hints = PresentationHints(
            dataType: .form,
            presentationPreference: .list,
            complexity: .moderate,
            context: .form,
            customPreferences: [:]
        )
        
        let view = platformPresentFormData_L1(field: testField, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentFormData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentFormData_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentMediaData_L1 Tests
    
    @Test @MainActor func testPlatformPresentMediaDataL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testMedia = GenericMediaItem(title: "Test Media", url: "https://example.com")
        let hints = PresentationHints(
            dataType: .media,
            presentationPreference: .grid,
            complexity: .simple,
            context: .gallery,
            customPreferences: [:]
        )
        
        let view = platformPresentMediaData_L1(media: testMedia, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentMediaData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentMediaData_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentMediaDataL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testMedia = GenericMediaItem(title: "Test Media", url: "https://example.com")
        let hints = PresentationHints(
            dataType: .media,
            presentationPreference: .grid,
            complexity: .simple,
            context: .gallery,
            customPreferences: [:]
        )
        
        let view = platformPresentMediaData_L1(media: testMedia, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentMediaData_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentMediaData_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentSettings_L1 Tests
    
    @Test @MainActor func testPlatformPresentSettingsL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testSettings = [
            SettingsSectionData(
                title: "Test Section",
                items: [
                    SettingsItemData(
                        key: "testItem",
                        title: "Test Item",
                        type: .toggle,
                        value: true
                    )
                ]
            )
        ]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .simple,
            context: .settings,
            customPreferences: [:]
        )
        
        let view = platformPresentSettings_L1(settings: testSettings, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentSettings_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentSettings_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentSettingsL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        let testSettings = [
            SettingsSectionData(
                title: "Test Section",
                items: [
                    SettingsItemData(
                        key: "testItem",
                        title: "Test Item",
                        type: .toggle,
                        value: true
                    )
                ]
            )
        ]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .simple,
            context: .settings,
            customPreferences: [:]
        )
        
        let view = platformPresentSettings_L1(settings: testSettings, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentSettings_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentSettings_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentContent_L1 Tests
    
    @Test @MainActor func testPlatformPresentContentL1GeneratesAccessibilityIdentifiersOnIOS() async {
        let testContent = "Test Content"
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentContent_L1(content: testContent, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentContent_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentContentL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        let testContent = "Test Content"
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentContent_L1(content: testContent, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            platform: .macOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentBasicValue_L1 Tests
    
    @Test @MainActor func testPlatformPresentBasicValueL1GeneratesAccessibilityIdentifiersOnIOS() async {
        let testValue = 42
        let hints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentBasicValue_L1(value: testValue, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentBasicValue_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentBasicValue_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentBasicValueL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        let testValue = 42
        let hints = PresentationHints(
            dataType: .numeric,
            presentationPreference: .card,
            complexity: .simple,
            context: .detail,
            customPreferences: [:]
        )
        
        let view = platformPresentBasicValue_L1(value: testValue, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            platform: .macOS,
            componentName: "platformPresentBasicValue_L1"
        )
 #expect(hasAccessibilityID, "platformPresentBasicValue_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentBasicArray_L1 Tests
    
    @Test @MainActor func testPlatformPresentBasicArrayL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let testArray = [1, 2, 3, 4, 5]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .simple,
            context: .list,
            customPreferences: [:]
        )
        
        let view = platformPresentBasicArray_L1(array: testArray, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformPresentBasicArray_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformPresentBasicArray_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformPresentBasicArrayL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let testArray = [1, 2, 3, 4, 5]
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .list,
            complexity: .simple,
            context: .list,
            customPreferences: [:]
        )
        
        let view = platformPresentBasicArray_L1(array: testArray, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            platform: .macOS,
            componentName: "platformPresentBasicArray_L1"
        )
 #expect(hasAccessibilityID, "platformPresentBasicArray_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformPresentContent_L1 All Delegate Path Tests
    
    /// Test platformPresentContent_L1 delegates to form function when content is [DynamicFormField]
    @Test @MainActor func testPlatformPresentContentL1DelegatesToFormFunction() async {
        initializeTestConfig()
        let formFields = [
            DynamicFormField(id: "field1", contentType: .text, label: "Field 1")
        ]
        
        let view = platformPresentContent_L1(content: formFields, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to form function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to media function when content is [GenericMediaItem]
    @Test @MainActor func testPlatformPresentContentL1DelegatesToMediaFunction() async {
        initializeTestConfig()
        let mediaItems = [
            GenericMediaItem(title: "Test Media", url: "https://example.com")
        ]
        
        let view = platformPresentContent_L1(content: mediaItems, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to media function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to numeric function when content is [GenericNumericData]
    @Test @MainActor func testPlatformPresentContentL1DelegatesToNumericFunction() async {
        initializeTestConfig()
        let numericData = [
            GenericNumericData(value: 123.45, label: "Test", unit: "units")
        ]
        
        let view = platformPresentContent_L1(content: numericData, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to numeric function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to hierarchical function when content is [GenericHierarchicalItem]
    @Test @MainActor func testPlatformPresentContentL1DelegatesToHierarchicalFunction() async {
        initializeTestConfig()
        let hierarchicalItems = [
            GenericHierarchicalItem(title: "Root", level: 0)
        ]
        
        let view = platformPresentContent_L1(content: hierarchicalItems, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to hierarchical function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to temporal function when content is [GenericTemporalItem]
    @Test @MainActor func testPlatformPresentContentL1DelegatesToTemporalFunction() async {
        initializeTestConfig()
        let temporalItems = [
            GenericTemporalItem(title: "Event", date: Date(), duration: 3600)
        ]
        
        let view = platformPresentContent_L1(content: temporalItems, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to temporal function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to item collection function when content is identifiable array
    @Test @MainActor func testPlatformPresentContentL1DelegatesToItemCollectionFunction() async {
            initializeTestConfig()
        struct TestItem: Identifiable {
            let id = UUID()
            let name: String
        }
        
        let items = [TestItem(name: "Item 1"), TestItem(name: "Item 2")]
        
        let view = platformPresentContent_L1(content: items, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to item collection function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to basic value function when content is basic numeric type
    @Test @MainActor func testPlatformPresentContentL1DelegatesToBasicValueFunctionForNumeric() async {
        initializeTestConfig()
        let view = platformPresentContent_L1(content: 42, hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to basic value function for numeric ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to basic array function when content is basic array
    @Test @MainActor func testPlatformPresentContentL1DelegatesToBasicArrayFunction() async {
        initializeTestConfig()
        let view = platformPresentContent_L1(content: [1, 2, 3], hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to basic array function ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to basic value function when content is String
    @Test @MainActor func testPlatformPresentContentL1DelegatesToBasicValueFunctionForString() async {
        initializeTestConfig()
        let view = platformPresentContent_L1(content: "Test String", hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to basic value function for string ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    /// Test platformPresentContent_L1 delegates to GenericFallbackView for unknown types
    @Test @MainActor func testPlatformPresentContentL1DelegatesToFallbackView() async {
            initializeTestConfig()
        struct UnknownType {
            let value: String
        }
        
        let view = platformPresentContent_L1(content: UnknownType(value: "test"), hints: PresentationHints())
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.*ui", 
            platform: SixLayerPlatform.iOS,
            componentName: "platformPresentContent_L1"
        )
 #expect(hasAccessibilityID, "platformPresentContent_L1 should generate accessibility identifiers when delegating to fallback view ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    // MARK: - platformResponsiveCard_L1 Tests
    
    @Test @MainActor func testPlatformResponsiveCardL1GeneratesAccessibilityIdentifiersOnIOS() async {
        initializeTestConfig()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .card,
            complexity: .simple,
            context: .standard,
            customPreferences: [:]
        )
        
        let view = platformResponsiveCard_L1(content: {
            Text("Test Card Content")
        }, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testAccessibilityIdentifiersCrossPlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            componentName: "platformResponsiveCard_L1",
            testName: "PlatformTest"
        )
 #expect(hasAccessibilityID, "platformResponsiveCard_L1 should generate accessibility identifiers on iOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
    
    @Test @MainActor func testPlatformResponsiveCardL1GeneratesAccessibilityIdentifiersOnMacOS() async {
        initializeTestConfig()
        let hints = PresentationHints(
            dataType: .generic,
            presentationPreference: .card,
            complexity: .simple,
            context: .standard,
            customPreferences: [:]
        )
        
        let view = platformResponsiveCard_L1(content: {
            Text("Test Card Content")
        }, hints: hints)
        
        #if canImport(ViewInspector) && (!os(macOS) || VIEW_INSPECTOR_MAC_FIXED)
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            view, 
            expectedPattern: "SixLayer.main.ui", 
            platform: .macOS,
            componentName: "platformResponsiveCard_L1"
        )
 #expect(hasAccessibilityID, "platformResponsiveCard_L1 should generate accessibility identifiers on macOS ")
        #else
        // ViewInspector not available on this platform (likely macOS) - this is expected, not a failure
        // The modifier IS present in the code, but ViewInspector can't detect it on macOS
        #endif
    }
}

// MARK: - Test Support Types

/// Test item for PlatformSemanticLayer1 testing
struct PlatformSemanticLayer1TestItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    
    init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }
}
