# SixLayerTestKit Guide

SixLayerTestKit provides testing utilities for consumers of the SixLayer Framework. It includes service mocks, form testing helpers, navigation testing utilities, and tools to drive Layer 1→6 flows deterministically in tests.

## Overview

Testing code that uses SixLayer can be challenging because of its layered architecture and service dependencies. SixLayerTestKit addresses this by providing:

- **Service Mocks**: Test doubles for all SixLayer services
- **Form Helpers**: Utilities for testing DynamicForm and form interactions
- **Navigation Helpers**: Tools for testing navigation flows and Layer 1 functions
- **Layer Flow Driver**: Deterministic testing of complete Layer 1→6 flows
- **Test Data Generators**: Utilities for generating realistic test data
- **Host-identifier XCUI query**: `waitForAccessibilityIdentifier` / `elementMatchingAccessibilityIdentifier` for `accessibilityHostIdentifier` (#473)

## Installation

SixLayerTestKit is distributed as a separate Swift package product. Add it to your test targets:

```swift
dependencies: [
    .package(url: "https://github.com/schatt/sixlayer", from: "6.4.0"),
],
targets: [
    .testTarget(
        name: "MyAppTests",
        dependencies: [
            "MyApp",  // Your app
            .product(name: "SixLayerTestKit", package: "SixLayerFramework")
        ]
    )
]
```

## Quick Start

```swift
import SixLayerTestKit

class MyAppTests: XCTestCase {
    var testKit: SixLayerTestKit!

    override func setUp() {
        testKit = SixLayerTestKit()
    }

    func testUserRegistration() {
        // Mock services
        testKit.serviceMocks.cloudKitService.configureSuccessResponse()

        // Create form
        let form = testKit.formHelper.createTestForm()
        let state = testKit.formHelper.createFormState(from: form)

        // Simulate user input
        testKit.formHelper.simulateFieldInput(
            fieldId: "email",
            value: "user@example.com",
            in: state
        )

        // Test your registration logic
        // ...
    }
}
```

## Service Mocks

### CloudKit Service Mock

```swift
func testCloudKitOperations() {
    let mock = testKit.serviceMocks.cloudKitService

    // Configure success response
    mock.configureSuccessResponse()

    // Or configure failure
    mock.configureFailureResponse(error: .networkError)

    // Or configure custom behavior
    mock.configureCustomResponse { operation in
        // Custom logic here
        return mockRecord
    }

    // Test your CloudKit-dependent code
    let service = CloudKitService(delegate: mock)
    // ... use service ...

    // Verify interactions
    XCTAssertTrue(mock.saveWasCalled)
    XCTAssertEqual(mock.saveRecords.count, 1)
}
```

### Notification Service Mock

```swift
func testNotificationScheduling() {
    let mock = testKit.serviceMocks.notificationService

    mock.configureSuccessResponse()
    mock.configurePermissionResponse(granted: true)

    // Test notification code
    let service = NotificationService()
    let granted = try await service.requestNotificationPermission()
    XCTAssertTrue(granted)

    try await service.scheduleLocalNotification(
        identifier: "reminder",
        title: "Reminder",
        body: "Don't forget!",
        date: Date().addingTimeInterval(3600)
    )

    // Verify
    XCTAssertTrue(mock.requestPermissionWasCalled)
    XCTAssertTrue(mock.scheduleLocalNotificationWasCalled)
    XCTAssertEqual(mock.scheduledNotifications.first?.title, "Reminder")
}
```

### Security Service Mock

```swift
func testBiometricAuthentication() {
    let mock = testKit.serviceMocks.securityService

    mock.configureSuccessResponse()
    mock.configureBiometricAvailability(available: true, type: .faceID)

    // Test authentication code
    let service = SecurityService()
    XCTAssertTrue(service.isBiometricAvailable)

    let success = try await service.authenticateWithBiometrics(
        reason: "Access secure content"
    )
    XCTAssertTrue(success)

    // Verify
    XCTAssertTrue(mock.authenticateWithBiometricsWasCalled)
    XCTAssertEqual(mock.authenticationReason, "Access secure content")
}
```

### Internationalization Service Mock

```swift
func testLocalization() {
    let mock = testKit.serviceMocks.internationalizationService

    // Set up translations
    mock.addTranslation(key: "greeting", value: "Hello", locale: "en")
    mock.addTranslation(key: "greeting", value: "Hola", locale: "es")

    // Test localization code
    let service = InternationalizationService()
    let english = service.localizedString(for: "greeting", locale: "en", defaultValue: "Hi")
    let spanish = service.localizedString(for: "greeting", locale: "es", defaultValue: "Hi")

    XCTAssertEqual(english, "Hello")
    XCTAssertEqual(spanish, "Hola")

    // Verify
    XCTAssertTrue(mock.wasKeyRequested("greeting"))
}
```

## Form Testing

### Creating Test Forms

```swift
func testFormCreation() {
    let formHelper = testKit.formHelper

    // Create individual fields
    let nameField = formHelper.createTextField(
        id: "name",
        label: "Full Name",
        placeholder: "Enter your name",
        value: "John Doe"
    )

    let emailField = formHelper.createEmailField(
        id: "email",
        value: "john@example.com"
    )

    let ageField = formHelper.createNumberField(
        id: "age",
        value: 30
    )

    // Create complete form
    let fields = formHelper.createTestForm() // Pre-built test form
    let state = formHelper.createFormState(from: fields)

    // Populate with test data
    formHelper.populateFormWithTestData(state, fields: fields)
}
```

### Simulating User Interactions

```swift
func testFormInteractions() {
    let formHelper = testKit.formHelper
    let fields = formHelper.createTestForm()
    let state = formHelper.createFormState(from: fields)

    // Simulate field input
    formHelper.simulateFieldInput(fieldId: "name", value: "Jane Smith", in: state)
    formHelper.simulateFieldInput(fieldId: "email", value: "jane@example.com", in: state)

    // Verify values
    XCTAssertEqual(
        formHelper.getFieldValue(from: state, fieldId: "name") as? String,
        "Jane Smith"
    )

    // Test validation
    let errors = formHelper.validateForm(state, requiredFields: ["name", "email"])
    XCTAssertTrue(errors.isEmpty)
}
```

### Form Submission Testing

```swift
func testFormSubmission() {
    let formHelper = testKit.formHelper
    let fields = formHelper.createTestForm()
    let state = formHelper.createFormState(from: fields)

    // Fill out form
    formHelper.simulateFieldInput(fieldId: "name", value: "Test User", in: state)
    formHelper.simulateFieldInput(fieldId: "email", value: "test@example.com", in: state)

    // Capture submission
    var submittedData: [String: Any]?
    let result = formHelper.simulateFormSubmission(
        state: state,
        fields: fields,
        onSubmit: { data in
            submittedData = data
        }
    )

    // Verify submission
    XCTAssertNotNil(submittedData)
    XCTAssertEqual(submittedData?["name"] as? String, "Test User")
    XCTAssertEqual(result["name"] as? String, "Test User")
}
```

## Navigation Testing

### Basic Navigation Flows

```swift
func testNavigationFlow() {
    let navHelper = testKit.navigationHelper

    // Simulate navigation
    navHelper.simulatePush(viewId: "home")
    navHelper.simulatePush(viewId: "settings")
    navHelper.simulatePresentSheet(sheetId: "options")

    // Verify state
    XCTAssertEqual(navHelper.navigationStack, ["home", "settings"])
    XCTAssertEqual(navHelper.presentedSheets, ["options"])

    // Simulate back navigation
    let popped = navHelper.simulatePop()
    XCTAssertEqual(popped, "settings")
    XCTAssertEqual(navHelper.navigationStack, ["home"])
}
```

### Deep Link Testing

```swift
func testDeepLinks() {
    let navHelper = testKit.navigationHelper

    // Test various deep links
    let urls = [
        URL(string: "myapp://settings")!,
        URL(string: "myapp://profile")!,
        URL(string: "myapp://item/123")!
    ]

    let results = navHelper.testDeepLinkHandling(urls: urls)

    XCTAssertEqual(results[0], ["settings"])  // /settings -> settings view
    XCTAssertEqual(results[1], ["profile"])   // /profile -> profile view
    XCTAssertEqual(results[2], ["item-123"])  // /item/123 -> item view
}
```

### Layer 1 Function Testing

```swift
func testLayer1Functions() {
    let navHelper = testKit.navigationHelper

    let results = navHelper.testSemanticFunctions()

    // Verify all Layer 1 functions return expected types
    XCTAssertTrue(results["buttonTapped"] is Bool)
    XCTAssertTrue(results["textFieldChanged"] is String)
    XCTAssertTrue(results["toggleSwitched"] is Bool)
    XCTAssertTrue(results["pickerSelected"] is String)
    XCTAssertTrue(results["sliderMoved"] is Double)
}
```

## Layer Flow Testing

### Complete Flow Simulation

```swift
func testCompleteLayerFlow() async throws {
    let flowDriver = testKit.layerFlowDriver

    // Configure input and behavior
    let input = LayerFlowDriver.LayerInput(
        buttonCount: 3,
        textFieldCount: 2,
        toggleCount: 1,
        sliderCount: 1
    )

    let config = LayerFlowDriver.LayerConfiguration(
        buttonCount: 3,
        textFieldCount: 2,
        listItemCount: 5,
        cardCount: 3,
        navigationDepth: 4
    )

    // Run complete flow simulation
    let result = try await flowDriver.simulateLayerFlow(
        input: input,
        configuration: config
    )

    // Verify all layers executed
    XCTAssertGreaterThan(result.duration, 0)
    XCTAssertEqual(result.layer1Result.buttonActions.count, 3)
    XCTAssertEqual(result.layer2Result.listSelections.count, 5)
    XCTAssertEqual(result.layer3Result.gridLayouts.count, 2) // default rows
    XCTAssertEqual(result.layer4Result.navigationPushes.count, 4)
    XCTAssertFalse(result.layer5Result.voiceOverAnnouncements.isEmpty)
    XCTAssertFalse(result.layer6Result.ocrResults.isEmpty)
}
```

### Custom Flow Configuration

```swift
func testCustomFlowConfiguration() async throws {
    let flowDriver = testKit.layerFlowDriver

    var config = LayerFlowDriver.LayerConfiguration()
    config.buttonCount = 5
    config.tabCount = 3
    config.accessibilityElements = 10
    config.ocrImageCount = 3

    let result = try await flowDriver.simulateLayerFlow(
        input: LayerFlowDriver.LayerInput(),
        configuration: config
    )

    // Verify custom configuration was used
    XCTAssertEqual(result.layer1Result.buttonActions.count, 5)
    XCTAssertEqual(result.layer4Result.tabSwitches.count, 3)
    XCTAssertEqual(result.layer5Result.voiceOverAnnouncements.count, 10)
    XCTAssertEqual(result.layer6Result.ocrResults.count, 3)
}
```

## Integration Testing

### End-to-End User Flows

```swift
func testCompleteUserFlow() {
    // Combine all testing utilities
    let formHelper = testKit.formHelper
    let navHelper = testKit.navigationHelper
    let cloudKitMock = testKit.serviceMocks.cloudKitService

    cloudKitMock.configureSuccessResponse()

    // 1. Simulate user registration
    let registrationForm = formHelper.createTestForm()
    let formState = formHelper.createFormState(from: registrationForm)

    formHelper.simulateFieldInput(fieldId: "email", value: "user@example.com", in: formState)
    formHelper.simulateFieldInput(fieldId: "name", value: "Test User", in: formState)

    // 2. Submit registration
    formHelper.simulateFormSubmission(
        state: formState,
        fields: registrationForm,
        onSubmit: { data in
            // Simulate saving to CloudKit
            let record = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: "user123"))
            record.setValuesForKeys(data)
            // In real code: cloudKitService.save(record)
        }
    )

    // 3. Navigate to profile
    navHelper.simulatePush(viewId: "profile")

    // 4. Verify flow
    XCTAssertTrue(cloudKitMock.saveWasCalled)
    XCTAssertEqual(navHelper.navigationStack, ["profile"])
}
```

### Error Scenario Testing

```swift
func testErrorHandling() {
    // Configure mocks for failure
    testKit.serviceMocks.cloudKitService.configureFailureResponse(error: .networkError)
    testKit.serviceMocks.notificationService.configureFailureResponse()

    // Test your error handling code
    // ... exercise code that uses these services ...

    // Verify error handling
    XCTAssertTrue(testKit.serviceMocks.cloudKitService.saveWasCalled)
    // Verify your app shows appropriate error messages
}
```

## Test Data Generation

### Realistic Test Data

```swift
func testDataGeneration() {
    let formHelper = testKit.formHelper

    // Generate complete user profiles
    let user1 = formHelper.generateTestUserData()
    let user2 = formHelper.generateTestUserData()

    // Verify structure
    XCTAssertNotNil(user1["name"])
    XCTAssertNotNil(user1["email"])
    XCTAssertNotNil(user1["age"])

    // Verify uniqueness
    XCTAssertNotEqual(user1["email"], user2["email"])
}
```

### Custom Test Data

```swift
func testCustomTestData() {
    // Use TestDataGenerator directly
    let name = TestDataGenerator.randomString(length: 10)
    let email = TestDataGenerator.randomEmail()
    let phone = TestDataGenerator.randomPhoneNumber()
    let date = TestDataGenerator.randomDate(in: Date.distantPast...Date())

    XCTAssertFalse(name.isEmpty)
    XCTAssertTrue(email.contains("@"))
    XCTAssertTrue(phone.hasPrefix("+1"))
    XCTAssertNotNil(date)
}
```

## Best Practices

### 1. Configure Mocks First

```swift
func testFeatureWithDependencies() {
    // ✅ Configure mocks before exercising code
    testKit.serviceMocks.cloudKitService.configureSuccessResponse()
    testKit.serviceMocks.notificationService.configureSuccessResponse()

    // Then exercise your code
    // ...
}
```

### 2. Verify Interactions

```swift
func testServiceIntegration() {
    // Exercise code that uses services
    // ...

    // ✅ Verify both results AND interactions
    XCTAssertTrue(testKit.serviceMocks.cloudKitService.saveWasCalled)
    XCTAssertEqual(testKit.serviceMocks.cloudKitService.saveRecords.count, 1)
}
```

### 3. Test Error Conditions

```swift
func testErrorConditions() {
    // ✅ Test success AND failure scenarios
    testKit.serviceMocks.cloudKitService.configureFailureResponse()

    // Verify error handling
    // ...
}
```

### 4. Use Realistic Test Data

```swift
func testWithRealisticData() {
    let formHelper = testKit.formHelper

    // ✅ Use generated test data for realistic scenarios
    let state = formHelper.createFormState(from: formHelper.createTestForm())
    formHelper.populateFormWithTestData(state, fields: formHelper.createTestForm())

    // Test with populated form
    // ...
}
```

### 5. Combine Testing Utilities

```swift
func testComplexFlow() {
    // ✅ Combine form, navigation, and service testing
    let formHelper = testKit.formHelper
    let navHelper = testKit.navigationHelper
    let cloudKitMock = testKit.serviceMocks.cloudKitService

    // Set up all mocks
    cloudKitMock.configureSuccessResponse()

    // Create and fill form
    let fields = formHelper.createTestForm()
    let state = formHelper.createFormState(from: fields)
    formHelper.populateFormWithTestData(state, fields: fields)

    // Simulate navigation and submission
    navHelper.simulatePush(viewId: "registration")
    formHelper.simulateFormSubmission(state: state, fields: fields) { data in
        // Submit to service
    }

    // Verify everything worked
    XCTAssertEqual(navHelper.navigationStack, ["registration"])
    XCTAssertTrue(cloudKitMock.saveWasCalled)
}
```

## Mock Configuration Reference

### CloudKitServiceMock

```swift
let mock = testKit.serviceMocks.cloudKitService

// Success responses
mock.configureSuccessResponse()

// Failure responses
mock.configureFailureResponse(error: .networkError)

// Custom responses
mock.configureCustomResponse { operation in
    switch operation {
    case .save(let record):
        return record // Return saved record
    case .fetch:
        return CKRecord(recordType: "Test") // Return mock record
    default:
        throw CloudKitServiceError.unknownError
    }
}

// Inspection
XCTAssertTrue(mock.saveWasCalled)
XCTAssertEqual(mock.saveRecords.count, 1)
```

### NotificationServiceMock

```swift
let mock = testKit.serviceMocks.notificationService

// Configure responses
mock.configureSuccessResponse()
mock.configurePermissionResponse(granted: true)

// Simulate notifications
mock.simulateNotificationReceived(identifier: "test", title: "Title", body: "Body")

// Inspection
XCTAssertTrue(mock.scheduleLocalNotificationWasCalled)
XCTAssertEqual(mock.scheduledNotifications.first?.title, "Title")
```

### SecurityServiceMock

```swift
let mock = testKit.serviceMocks.securityService

// Configure responses
mock.configureSuccessResponse()
mock.configureBiometricAvailability(available: true, type: .faceID)

// Inspection
XCTAssertTrue(mock.authenticateWithBiometricsWasCalled)
XCTAssertTrue(mock.isBiometricAvailable)
```

### InternationalizationServiceMock

```swift
let mock = testKit.serviceMocks.internationalizationService

// Add translations
mock.addTranslation(key: "hello", value: "Hello", locale: "en")
mock.setupCommonTranslations() // Adds common test translations

// Inspection
XCTAssertTrue(mock.wasKeyRequested("hello"))
XCTAssertEqual(mock.lastRequestedLocale, "en")
```

## Troubleshooting

### Mocks Not Working

1. **Ensure mocks are configured before use**
   ```swift
   // ✅ Configure first
   mock.configureSuccessResponse()
   // Then use service
   ```

2. **Check that you're using the mock in your service**
   ```swift
   // ✅ Pass mock to service
   let service = CloudKitService(delegate: mock)
   ```

### Form Testing Issues

1. **Field IDs must match**
   ```swift
   // ✅ Use same field ID
   let field = formHelper.createTextField(id: "name")
   formHelper.simulateFieldInput(fieldId: "name", value: "Test", in: state)
   ```

2. **Field values are stored in DynamicFormState**
   ```swift
   // ✅ Get values from state, not field
   let value = formHelper.getFieldValue(from: state, fieldId: "name")
   ```

### Navigation Testing Issues

1. **Navigation state is tracked per helper instance**
   ```swift
   // ✅ Use same helper instance
   let navHelper = testKit.navigationHelper
   navHelper.simulatePush(viewId: "home")
   XCTAssertEqual(navHelper.navigationStack, ["home"])
   ```

2. **Deep links require URL format**
   ```swift
   // ✅ Use proper URL format
   let url = URL(string: "myapp://settings")!
   let result = navHelper.simulateDeepLink(url)
   ```

## Host identifiers in XCUITest (#473)

`accessibilityHostIdentifier` (and `.named` / `.exactNamed` hosts) are **not** typed containers. On macOS the stamp is a `StaticText` leaf. Use:

```swift
import SixLayerTestKit

XCTAssertTrue(app.waitForAccessibilityIdentifier("MyApp.Expenses.scrollHost"))
let host = app.elementMatchingAccessibilityIdentifier("MyApp.Expenses.scrollHost")
```

Do not use `otherElements` / `scrollViews` or `UITestContractElementResolver.findFirstExisting` for these ids. Do not query nested ids as descendants of `host`. See `AutomaticAccessibilityIdentifiers.md` and `UITestContractElementResolver.md`.

## Examples Repository

See the complete examples in:
- `Framework/TestKit/Tests/SixLayerTestKitExamples.swift` - Comprehensive test examples
- `Framework/Examples/DesignSystemBridgeExample.swift` - Shows Design System integration testing
- `Framework/Examples/ExternalDesignTokensExample.swift` - External token mapping examples

## Migration from Manual Mocks

If you're currently using manual mocks:

```swift
// Before: Manual mock
class MyCloudKitMock: CloudKitServiceDelegate { /* ... */ }

// After: SixLayerTestKit
let mock = testKit.serviceMocks.cloudKitService
mock.configureSuccessResponse()
```

The benefits of SixLayerTestKit:
- **Consistency**: Standardized mock interfaces
- **Completeness**: All services mocked consistently
- **Maintenance**: Updated with framework changes
- **Features**: Built-in configuration and inspection
- **Integration**: Works seamlessly with other testing utilities