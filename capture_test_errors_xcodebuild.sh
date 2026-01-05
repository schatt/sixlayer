#!/bin/bash
# Capture all test errors using xcodebuild with detailed output
# This should match what Xcode shows in the Test Navigator

set -e

SCHEME="${1:-SixLayerFramework-AllTests-macOS}"
OUTPUT_FILE="${2:-test_errors_xcodebuild.txt}"

echo "Running tests with xcodebuild to capture all errors..."
echo "Scheme: $SCHEME"
echo "Output file: $OUTPUT_FILE"
echo ""

# Run tests with xcodebuild and capture all output
xcodebuild test \
  -project SixLayerFramework.xcodeproj \
  -scheme "$SCHEME" \
  -destination "platform=macOS" \
  -resultBundlePath ./TestResults.xcresult \
  2>&1 | tee "$OUTPUT_FILE.tmp"

# Extract test failures and errors from the output
echo "Extracting test failures..."
grep -E "(Test Case|Test Suite|failed|error:|Expectation failed|Issue recorded)" "$OUTPUT_FILE.tmp" > "$OUTPUT_FILE" || true

# Also extract from xcresult bundle if available
if [ -d "./TestResults.xcresult" ]; then
    echo "Extracting from xcresult bundle..."
    xcrun xcresulttool get --path ./TestResults.xcresult --format json > "$OUTPUT_FILE.json" 2>/dev/null || true
fi

echo ""
echo "Test errors captured to: $OUTPUT_FILE"
echo "Full output saved to: $OUTPUT_FILE.tmp"
echo "JSON results saved to: $OUTPUT_FILE.json (if available)"

# Clean up temp file
rm -f "$OUTPUT_FILE.tmp"
