#!/bin/bash
# Run tests using Swift Package Manager - faster discovery, no Xcode UI timeout

echo "Running tests with Swift Package Manager..."
swift test --filter SixLayerFrameworkUnitTests

# Or run specific test suite:
# swift test --filter AccessibilityIdentifierEdgeCaseTests

# Or run all tests:
# swift test
