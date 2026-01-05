#!/bin/bash
# Run tests from command line to avoid Xcode timeout issues

# Build first
echo "Building project..."
xcodebuild build -project SixLayerFramework.xcodeproj \
  -scheme SixLayerFramework-AllTests-macOS \
  -destination "platform=macOS" \
  -quiet

# Run tests
echo "Running tests..."
xcodebuild test -project SixLayerFramework.xcodeproj \
  -scheme SixLayerFramework-AllTests-macOS \
  -destination "platform=macOS" \
  -only-testing:SixLayerFrameworkUnitTests_macOS \
  -parallel-testing-enabled YES \
  -maximum-concurrent-test-simulator-destinations 2
