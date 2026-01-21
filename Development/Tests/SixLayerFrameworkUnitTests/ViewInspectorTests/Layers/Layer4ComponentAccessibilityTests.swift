import Testing
import Foundation
import SwiftUI
@testable import SixLayerFramework

//
//  Layer4ComponentAccessibilityTests.swift
//  SixLayerFrameworkTests
//
//  Tests Layer 4 components for accessibility - these are View extensions that add platform-specific styling
//

@Suite("Layer Component Accessibility")
/// NOTE: Not marked @MainActor on class to allow parallel execution
open class Layer4ComponentAccessibilityTests: BaseTestClass {
    
    // MARK: - Layer 4 Component Tests
    
    @Test @MainActor func testPlatformPrimaryButtonStyleGeneratesAccessibilityIdentifiers() async {
        // Given: A test button
        let testButton = Button("Test Button") { }
        
        // When: Applying platform primary button style
        let styledButton = testButton.platformPrimaryButtonStyle()
        
        // Then: Should generate accessibility identifiers
            // TODO: ViewInspector Detection Issue - VERIFIED: PlatformPrimaryButtonStyle DOES have .automaticCompliance() 
            // modifier applied in Framework/Sources/Layers/Layer4-Component/PlatformButtonsLayer4.swift:28.
            // The test needs to be updated to handle ViewInspector's inability to detect these modifiers reliably.
            // This is a ViewInspector limitation, not a missing modifier issue.
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            styledButton,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformPrimaryButtonStyle"
        )
        #expect(hasAccessibilityID, "Platform primary button style should generate accessibility identifiers")
    }
    
    @Test @MainActor func testPlatformSecondaryButtonStyleGeneratesAccessibilityIdentifiers() async {
        // Given: A test button
        let testButton = Button("Test Button") { }
        
        // When: Applying platform secondary button style
        let styledButton = testButton.platformSecondaryButtonStyle()
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            styledButton,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformSecondaryButtonStyle"
        )
        #expect(hasAccessibilityID, "Platform secondary button style should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformFormFieldGeneratesAccessibilityIdentifiers() async {
        // Given: A test text field
        let testTextField = TextField("Placeholder", text: .constant(""))
        
        // When: Applying platform form field wrapper
        let formField = testTextField.platformFormField(label: "Test Field") {
            testTextField
        }
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            formField,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformFormField"
        )
        #expect(hasAccessibilityID, "Platform form field should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformListRowGeneratesAccessibilityIdentifiers() async {
        // Given: A test list row title
        let title = "Test Item"
        
        // When: Applying platform list row wrapper
        let listRow = EmptyView().platformListRow(title: title) {
            Spacer()
        }
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            listRow,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformListRow"
        )
        #expect(hasAccessibilityID, "Platform list row should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformCardStyleGeneratesAccessibilityIdentifiers() async {
        // Given: A test card content
        let testCard = platformVStackContainer {
            Text("Test Card Title")
            Text("Test Card Content")
        }
        
        // When: Applying platform card style
        let styledCard = testCard.platformCardStyle()
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            styledCard,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformCardStyle"
        )
        #expect(hasAccessibilityID, "Platform card style should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformSheetGeneratesAccessibilityIdentifiers() async {
        // Given: A test sheet content
        let testSheetContent = platformVStackContainer {
            Text("Test Sheet Title")
            Text("Test Sheet Content")
        }
        
        // When: Applying platform sheet wrapper (without onDismiss - current signature)
        let sheet = testSheetContent.platformSheet(
            isPresented: .constant(true)
        ) {
            testSheetContent
        }
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            sheet,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformSheet"
        )
        #expect(hasAccessibilityID, "Platform sheet should generate accessibility identifiers ")
    }
    
    // MARK: - platformSheet onDismiss Parameter Tests (TDD - RED Phase)
    
    @Test @MainActor func testPlatformSheetWithOnDismiss() async {
        initializeTestConfig()
        // Given: Sheet with onDismiss callback
        var dismissCalled = false
        let onDismiss = {
            dismissCalled = true
        }
        
        // When: Applying platformSheet with onDismiss parameter
        // NOTE: This test will fail until onDismiss parameter is added
        let sheet = Text("Content")
            .platformSheet(
                isPresented: .constant(true),
                onDismiss: onDismiss
            ) {
                Text("Sheet Content")
            }
        
        // Then: Sheet should be created successfully
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with onDismiss should render")
        // Note: Testing dismiss callback would require actual sheet presentation, which is complex in unit tests
    }
    
    @Test @MainActor func testPlatformSheetWithOnDismissNil() async {
        initializeTestConfig()
        // Given: Sheet with nil onDismiss (should still work)
        
        // When: Applying platformSheet with nil onDismiss
        let sheet = Text("Content")
            .platformSheet(
                isPresented: .constant(true),
                onDismiss: nil
            ) {
                Text("Sheet Content")
            }
        
        // Then: Sheet should be created successfully
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with nil onDismiss should render")
    }
    
    @Test @MainActor func testPlatformSheetWithOnDismissAndDetents() async {
        initializeTestConfig()
        // Given: Sheet with both onDismiss and detents
        var dismissCalled = false
        let onDismiss = {
            dismissCalled = true
        }
        
        // When: Applying platformSheet with both parameters
        let sheet = Text("Content")
            .platformSheet(
                isPresented: .constant(true),
                detents: [.medium, .large],
                onDismiss: onDismiss
            ) {
                Text("Sheet Content")
            }
        
        // Then: Sheet should be created successfully
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with onDismiss and detents should render")
    }
    
    // MARK: - platformSheet Item-Based Overload Tests (TDD - RED Phase)
    
    @Test @MainActor func testPlatformSheetWithItemBinding() async {
        initializeTestConfig()
        // Given: Item-based sheet presentation
        struct TestItem: Identifiable {
            let id: Int
            let name: String
        }
        
        @State var selectedItem: TestItem? = TestItem(id: 1, name: "Test")
        
        // When: Applying platformSheet with item binding
        // NOTE: This test will fail until item-based overload is added
        let sheet = Text("Content")
            .platformSheet(item: $selectedItem) { item in
                Text("Sheet for: \(item.name)")
            }
        
        // Then: Sheet should be created successfully
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with item binding should render")
    }
    
    @Test @MainActor func testPlatformSheetWithItemBindingAndOnDismiss() async {
        initializeTestConfig()
        // Given: Item-based sheet with onDismiss
        struct TestItem: Identifiable {
            let id: Int
            let name: String
        }
        
        @State var selectedItem: TestItem? = TestItem(id: 1, name: "Test")
        var dismissCalled = false
        let onDismiss = {
            dismissCalled = true
        }
        
        // When: Applying platformSheet with item binding and onDismiss
        let sheet = Text("Content")
            .platformSheet(
                item: $selectedItem,
                onDismiss: onDismiss
            ) { item in
                Text("Sheet for: \(item.name)")
            }
        
        // Then: Sheet should be created successfully
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with item binding and onDismiss should render")
    }
    
    @Test @MainActor func testPlatformSheetItemBindingNil() async {
        initializeTestConfig()
        // Given: Item binding set to nil (sheet should not be presented)
        struct TestItem: Identifiable {
            let id: Int
        }
        
        @State var selectedItem: TestItem? = nil
        
        // When: Applying platformSheet with nil item
        let sheet = Text("Content")
            .platformSheet(item: $selectedItem) { item in
                Text("Sheet for: \(item.id)")
            }
        
        // Then: Sheet should still be created (binding controls presentation)
        let hostedView = hostRootPlatformView(sheet)
        #expect(hostedView != nil, "platformSheet with nil item binding should still create view")
    }
    
    // NOTE: testPlatformNavigationGeneratesAccessibilityIdentifiers moved to UI tests
    // NavigationStack/NavigationView cannot be reliably tested in unit tests because:
    // 1. ViewInspector's inspect() hangs indefinitely on NavigationStack/NavigationView
    // 2. hostRootPlatformView()'s layoutIfNeeded() hangs when hosting NavigationStack/NavigationView
    // 3. Navigation views require a proper window/view hierarchy to initialize correctly
    // See: Development/Tests/SixLayerFrameworkUITests/Features/Navigation/NavigationLayer4Tests.swift
    
    @Test @MainActor func testPlatformCardGridGeneratesAccessibilityIdentifiers() async {
        // Given: Test card items
        let testItems = ["Item 1", "Item 2", "Item 3"]
        
        // When: Creating platform card grid
        let cardGrid = EmptyView().platformCardGrid(
            columns: 2,
            spacing: 16,
            content: {
                ForEach(testItems, id: \.self) { item in
                    Text(item)
                }
            }
        )
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            cardGrid,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformCardGrid"
        )
        #expect(hasAccessibilityID, "Platform card grid should generate accessibility identifiers ")
    }
    
    @Test @MainActor func testPlatformBackgroundGeneratesAccessibilityIdentifiers() async {
        // Given: A test text view
        let testText = Text("Test Text")
        
        // When: Applying platform background
        let backgroundText = testText.platformBackground()
        
        // Then: Should generate accessibility identifiers
        let hasAccessibilityID = testComponentComplianceSinglePlatform(
            backgroundText,
            expectedPattern: "*.main.ui.element.*",
            platform: SixLayerPlatform.iOS,
            componentName: "PlatformBackground"
        )
        #expect(hasAccessibilityID, "Platform background should generate accessibility identifiers ")
    }
}