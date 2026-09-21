# SixLayerTestKit

A testing utility library for consumers of the SixLayer Framework.

## Overview

SixLayerTestKit provides testing utilities to help app teams test code that uses SixLayer components and services. It includes:

- **Service Test Doubles**: Mocks and stubs for SixLayer services (CloudKit, Notifications, Security, etc.)
- **Form & Navigation Helpers**: Utilities for testing DynamicForm and navigation flows
- **Layer Flow Utilities**: Tools to drive Layer 1→6 flows deterministically in tests
- **XCUI helpers**: Cross-platform `XCUIElement.platformTap` for multi-tap (iOS API / macOS repeated taps; #510)

## Usage

```swift
import SixLayerTestKit

class MyAppTests: XCTestCase {
    var testKit: SixLayerTestKit!

    override func setUp() {
        testKit = SixLayerTestKit()
    }

    func testFormSubmission() {
        // Create a form with test data
        let form = testKit.formHelper.createForm(with: TestModel.self)
        let viewModel = testKit.formHelper.createViewModel(for: form)

        // Simulate user interaction
        testKit.formHelper.simulateFieldInput(
            fieldId: "name",
            value: "Test User",
            in: viewModel
        )

        // Verify form state
        XCTAssertEqual(viewModel.getFieldValue("name") as? String, "Test User")
    }

    func testCloudKitOperations() {
        // Mock CloudKit service
        let cloudKitMock = testKit.serviceMocks.cloudKitService
        cloudKitMock.configureSuccessResponse()

        // Test your code that uses CloudKitService
        let service = CloudKitService(delegate: cloudKitMock)

        // Verify interactions
        XCTAssertTrue(cloudKitMock.saveWasCalled)
    }
}
```

## Components

### Service Mocks

- `CloudKitServiceMock`: Mock implementation of CloudKitService
- `NotificationServiceMock`: Mock implementation of NotificationService
- `SecurityServiceMock`: Mock implementation of SecurityService
- `InternationalizationServiceMock`: Mock implementation of InternationalizationService

### Form Helpers

- `FormTestHelper`: Utilities for creating and manipulating DynamicForm state
- `FieldInteractionSimulator`: Tools to simulate user interactions with form fields

### Navigation Helpers

- `NavigationTestHelper`: Utilities for testing navigation flows
- `LayerFlowDriver`: Tools to drive Layer 1→6 flows deterministically

## Configuration

Mocks can be configured for different test scenarios:

```swift
// Success scenario
cloudKitMock.configureSuccessResponse()

// Failure scenario
cloudKitMock.configureFailureResponse(error: .networkError)

// Custom behavior
cloudKitMock.configureCustomResponse { request in
    // Custom logic here
}
```

## Testing Best Practices

1. Use SixLayerTestKit for testing app code that consumes SixLayer
2. Configure mocks before exercising your code
3. Verify both the results and the interactions with mocks
4. Use deterministic test data and scenarios
5. Test error conditions as well as success paths

See the full documentation in `Framework/docs/SixLayerTestKitGuide.md` for detailed examples.