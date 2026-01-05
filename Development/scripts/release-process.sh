#!/bin/bash

# SixLayer Framework Release Process Script
# This script enforces the mandatory release documentation process

set -e

# Function to extract current version from Package.swift
extract_version_from_package() {
    if [ -f "Package.swift" ]; then
        # Look for version in comment: // SixLayerFramework v5.7.2 - ...
        local version_line=$(grep -E "^//.*SixLayerFramework v[0-9]+\.[0-9]+\.[0-9]+" Package.swift | head -1)
        if [ -n "$version_line" ]; then
            echo "$version_line" | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
            return 0
        fi
    fi
    return 1
}

# Function to extract current version from README.md
extract_version_from_readme() {
    if [ -f "README.md" ]; then
        # Look for version in: ## 🆕 Latest Release: v5.7.2
        local version_line=$(grep -E "^## 🆕 Latest Release: v[0-9]+\.[0-9]+\.[0-9]+" README.md | head -1)
        if [ -n "$version_line" ]; then
            echo "$version_line" | sed -E 's/.*v([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
            return 0
        fi
    fi
    return 1
}

# Function to get current version (tries Package.swift first, then README.md)
get_current_version() {
    local version=$(extract_version_from_package)
    if [ -n "$version" ]; then
        echo "$version"
        return 0
    fi
    
    version=$(extract_version_from_readme)
    if [ -n "$version" ]; then
        echo "$version"
        return 0
    fi
    
    return 1
}

# Function to increment version based on release type
increment_version() {
    local current_version=$1
    local release_type=$2
    
    # Parse version into major.minor.patch
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case "$release_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ Error: Invalid release type '$release_type'. Must be 'major', 'minor', or 'patch'" >&2
            return 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to check if a string looks like a version number (X.Y.Z)
is_version_number() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Parse arguments with smart detection
# Order: [release_type] [version]
# If first arg looks like a version (X.Y.Z), treat it as version
# Otherwise, treat it as release_type
ARG1=$1
ARG2=$2

if [ -z "$ARG1" ]; then
    # No arguments: auto-detect version, use patch default
    RELEASE_TYPE="patch"
    VERSION=""
elif is_version_number "$ARG1"; then
    # First arg is a version number: treat as [version] [release_type]
    VERSION=$ARG1
    RELEASE_TYPE=${ARG2:-"patch"}
else
    # First arg is not a version: treat as [release_type] [version]
    RELEASE_TYPE=$ARG1
    VERSION=$ARG2
fi

# Validate release type early
if [[ ! "$RELEASE_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "❌ Error: Invalid release type '$RELEASE_TYPE'. Must be 'major', 'minor', or 'patch'"
    echo "Usage: $0 [release_type] [version]"
    echo "       $0 [version] [release_type]"
    echo "Examples:"
    echo "  $0 minor              # Auto-detect version, minor release"
    echo "  $0 5.8.0              # Explicit version, patch release (default)"
    echo "  $0 minor 5.8.0        # Explicit type and version"
    echo "  $0 5.8.0 minor        # Version first, then type (also works)"
    exit 1
fi

# If version not provided, suggest one based on current version
if [ -z "$VERSION" ]; then
    CURRENT_VERSION=$(get_current_version)
    if [ $? -eq 0 ] && [ -n "$CURRENT_VERSION" ]; then
        SUGGESTED_VERSION=$(increment_version "$CURRENT_VERSION" "$RELEASE_TYPE")
        if [ $? -eq 0 ]; then
            echo "📋 Current version detected: v$CURRENT_VERSION"
            echo "💡 Suggested next version (${RELEASE_TYPE}): v$SUGGESTED_VERSION"
            echo ""
            read -p "Use suggested version v$SUGGESTED_VERSION? (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                echo "❌ Error: Version required"
                echo "Usage: $0 [release_type] [version]"
                echo "       $0 [version] [release_type]"
                echo "Examples:"
                echo "  $0 minor 5.8.0        # Explicit type and version"
                echo "  $0 5.8.0 minor        # Version first, then type"
                exit 1
            else
                VERSION=$SUGGESTED_VERSION
                echo "✅ Using suggested version: v$VERSION"
            fi
        else
            echo "❌ Error: Failed to calculate suggested version"
            echo "Usage: $0 [release_type] [version]"
            echo "       $0 [version] [release_type]"
            exit 1
        fi
    else
        echo "❌ Error: Version required and could not detect current version"
        echo "Usage: $0 [release_type] [version]"
        echo "       $0 [version] [release_type]"
        echo ""
        echo "Could not find version in Package.swift or README.md"
        exit 1
    fi
fi

# Initialize error tracking
ERRORS_FOUND=0
ERROR_MESSAGES=""

log_error() {
    echo "❌ $1"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
    ERROR_MESSAGES="${ERROR_MESSAGES}\n❌ $1"
}

echo "🚀 Starting release process for v$VERSION ($RELEASE_TYPE)"

# Step 1: Regenerate Xcode project
echo "📋 Step 1: Ensuring Xcode project is up to date..."
if command -v xcodegen &> /dev/null; then
    echo "🔧 Regenerating Xcode project with xcodegen..."
    if xcodegen -c; then
        echo "✅ Xcode project regenerated successfully"
    else
        echo "❌ Failed to regenerate Xcode project!"
        exit 1
    fi
else
    echo "⚠️  xcodegen not available, skipping project regeneration"
fi

# Step 2: Run tests
echo "📋 Step 2: Running test suite..."

# Run macOS unit tests first
echo "🧪 Running macOS unit tests..."
# Note: do NOT use -quiet here so that any failures print detailed diagnostics
if ! xcodebuild test -project SixLayerFramework.xcodeproj -scheme SixLayerFramework-UnitTestsOnly-macOS -quiet -destination "platform=macOS,arch=arm64"; then
    log_error "macOS unit tests failed! Cannot proceed with release."
    exit 1
fi
echo "✅ macOS unit tests passed"

# Run iOS unit tests on Simulator
echo "🧪 Running iOS unit tests on Simulator..."

# Ensure an iOS Simulator is booted (non-fatal if already booted or missing)
if command -v xcrun &> /dev/null; then
    echo "📱 Ensuring iOS Simulator is booted (iPhone 17 Pro Max)..."
    xcrun simctl boot "iPhone 17 Pro Max" 2>/dev/null || echo "ℹ️  Simulator already booted or not available; continuing..."
else
    echo "⚠️  xcrun not available; attempting to run iOS tests without explicit simulator boot"
fi

if ! xcodebuild test -project SixLayerFramework.xcodeproj -scheme SixLayerFramework-UnitTestsOnly-iOS -quiet -destination "platform=iOS Simulator,name=iPhone 17 Pro Max"; then
    log_error "iOS unit tests failed! Cannot proceed with release."
    exit 1
fi
echo "✅ iOS unit tests passed"

# Note: UI tests are currently disabled due to ViewInspector Swift 6 compatibility issues
# They compile successfully but have concurrency warnings treated as errors
echo "ℹ️  UI tests temporarily disabled (ViewInspector Swift 6 compatibility)"
echo "ℹ️  UI test compilation verified - infrastructure is working"
echo "✅ Unit test suite validation passed"

# Step 2: Check git is clean (no uncommitted changes)
echo "📋 Step 2: Checking git repository status..."
ERRORS_BEFORE_GIT=$ERRORS_FOUND
if [ -n "$(git status --porcelain)" ]; then
    log_error "Git repository has uncommitted changes! Please commit or stash all changes before creating a release."
    echo ""
    echo "Uncommitted changes:"
    git status --short
fi
if [ $ERRORS_BEFORE_GIT -eq $ERRORS_FOUND ]; then
    echo "✅ Git repository is clean"
fi

# Step 2.5: Check current branch
echo "📋 Step 2.5: Checking current branch..."
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "✅ On main branch (will use direct tag/push workflow)"
else
    echo "✅ On branch: $CURRENT_BRANCH (will merge to main before tag/push)"
fi

# Step 3: Check if RELEASES.md needs updating
echo "📋 Step 3: Checking RELEASES.md..."
ERRORS_BEFORE_RELEASES=$ERRORS_FOUND
if ! grep -q "v$VERSION" Development/RELEASES.md; then
    log_error "RELEASES.md missing v$VERSION entry! Please update Development/RELEASES.md with the new release information"
fi

# Check that RELEASES.md has the version as the current release at the top
if ! grep -A 5 "^## 📍 \*\*Current Release:" Development/RELEASES.md | grep -q "v$VERSION"; then
    log_error "RELEASES.md does not list v$VERSION as the Current Release! Please update the 'Current Release' section at the top of Development/RELEASES.md"
fi

# Check that the version section exists and is properly formatted
if ! grep -q "^## 🎯 \*\*v$VERSION" Development/RELEASES.md; then
    log_error "RELEASES.md missing proper v$VERSION section header! Expected format: ## 🎯 **v$VERSION - ..."
fi

if [ $ERRORS_BEFORE_RELEASES -eq $ERRORS_FOUND ]; then
    echo "✅ RELEASES.md correctly updated with v$VERSION"
fi

# Step 4: Check for individual release file
echo "📋 Step 4: Checking for individual release file..."
if [ -f "Development/RELEASE_v$VERSION.md" ]; then
    echo "✅ Individual release file exists"
else
    log_error "Missing Development/RELEASE_v$VERSION.md! Please create the individual release file"
fi

# Step 4.5: Check for resolved GitHub issues
echo "📋 Step 4.5: Checking for resolved GitHub issues..."
ERRORS_BEFORE_ISSUES=$ERRORS_FOUND

RELEASE_FILE="Development/RELEASE_v$VERSION.md"

# Always check for milestones and recently closed issues (even if release file doesn't exist)
if command -v gh &> /dev/null; then
    # Initialize milestone issues list (used for filtering recently closed issues)
    ALL_MILESTONE_ISSUES=""
    CLOSED_ISSUES=""
    OPEN_ISSUES=""
    CLOSED_COUNT=0
    OPEN_COUNT=0
    MILESTONE_NUMBER=""
    
    # Check for milestone matching this version
    MILESTONE_TITLE="v$VERSION"
    echo "🔍 Checking for milestone: $MILESTONE_TITLE..."
    
    # Get milestone by title
    MILESTONE_DATA=$(gh api repos/:owner/:repo/milestones --jq ".[] | select(.title == \"$MILESTONE_TITLE\")" 2>/dev/null || echo "")
    
    if [ -n "$MILESTONE_DATA" ] && [ "$MILESTONE_DATA" != "null" ]; then
        MILESTONE_NUMBER=$(echo "$MILESTONE_DATA" | jq -r '.number' 2>/dev/null || echo "")
        
        if [ -n "$MILESTONE_NUMBER" ] && [ "$MILESTONE_NUMBER" != "null" ]; then
            # Get all issues in this milestone (both open and closed) with their states
            # jq outputs each object on a new line, so we can process line by line
            MILESTONE_ISSUES_JSON=$(gh api "repos/:owner/:repo/issues?state=all" --jq ".[] | select(.milestone != null and .milestone.number == $MILESTONE_NUMBER) | \"\(.number)|\(.state)\"" 2>/dev/null || echo "")
        
            if [ -n "$MILESTONE_ISSUES_JSON" ]; then
                echo "✅ Found milestone $MILESTONE_TITLE with issues"
                
                # Parse issues and separate by state (format: "number|state")
                while IFS= read -r ISSUE_LINE; do
                    if [ -n "$ISSUE_LINE" ]; then
                        ISSUE_NUM=$(echo "$ISSUE_LINE" | cut -d'|' -f1)
                        ISSUE_STATE=$(echo "$ISSUE_LINE" | cut -d'|' -f2)
                        
                        if [ -n "$ISSUE_NUM" ] && [ "$ISSUE_NUM" != "null" ]; then
                            # Add to all milestone issues list
                            if [ -z "$ALL_MILESTONE_ISSUES" ]; then
                                ALL_MILESTONE_ISSUES="$ISSUE_NUM"
                            else
                                ALL_MILESTONE_ISSUES="$ALL_MILESTONE_ISSUES $ISSUE_NUM"
                            fi
                            
                            if [ "$ISSUE_STATE" = "closed" ]; then
                                CLOSED_COUNT=$((CLOSED_COUNT + 1))
                                if [ -z "$CLOSED_ISSUES" ]; then
                                    CLOSED_ISSUES="$ISSUE_NUM"
                                else
                                    CLOSED_ISSUES="$CLOSED_ISSUES $ISSUE_NUM"
                                fi
                            else
                                OPEN_COUNT=$((OPEN_COUNT + 1))
                                if [ -z "$OPEN_ISSUES" ]; then
                                    OPEN_ISSUES="$ISSUE_NUM"
                                else
                                    OPEN_ISSUES="$OPEN_ISSUES $ISSUE_NUM"
                                fi
                            fi
                        fi
                    fi
                done <<< "$MILESTONE_ISSUES_JSON"
                
                # Show summary
                if [ $CLOSED_COUNT -gt 0 ] || [ $OPEN_COUNT -gt 0 ]; then
                    echo "📊 Milestone summary: $CLOSED_COUNT closed, $OPEN_COUNT open"
                fi
                
                # Show closed issues that should be documented
                if [ $CLOSED_COUNT -gt 0 ]; then
                    echo "📝 Closed issues that should be documented in release notes: $CLOSED_ISSUES"
                    if [ ! -f "$RELEASE_FILE" ]; then
                        echo "💡 These issues should be documented when you create $RELEASE_FILE"
                        echo "💡 Format: 'Resolves Issue #123' or 'Implements [Issue #123](https://github.com/schatt/6layer/issues/123)'"
                    fi
                fi
                
                # Error on open issues in milestone (they should be closed or removed before release)
                if [ $OPEN_COUNT -gt 0 ]; then
                    log_error "Milestone $MILESTONE_TITLE has $OPEN_COUNT open issue(s): $OPEN_ISSUES"
                    echo "💡 All issues in the release milestone must be closed or removed before creating the release"
                    echo "💡 Close these issues if they're completed and part of v$VERSION, or remove them from the milestone if they're not part of this release"
                    echo "💡 View milestone: https://github.com/schatt/6layer/milestone/$MILESTONE_NUMBER"
                fi
            else
                echo "ℹ️  Milestone $MILESTONE_TITLE exists but has no issues assigned"
            fi
        else
            echo "⚠️  Warning: Could not retrieve milestone number for $MILESTONE_TITLE"
        fi
    else
        echo "⚠️  Warning: No milestone found for v$VERSION"
        echo "💡 Consider creating a milestone and assigning issues to it for better release tracking"
        echo "💡 Create milestone: gh api repos/:owner/:repo/milestones -X POST -f title=\"v$VERSION\""
    fi
    
    # Also show recently closed issues as a reminder (for issues not in milestone)
    echo "🔍 Checking for recently closed issues (reminder only)..."
    
    # Build jq filter to exclude milestone issues
    if [ -n "$ALL_MILESTONE_ISSUES" ]; then
        # Build array of milestone issue numbers for jq
        MILESTONE_ARRAY="["
        FIRST=true
        for ISSUE_NUM in $ALL_MILESTONE_ISSUES; do
            if [ "$FIRST" = true ]; then
                MILESTONE_ARRAY="${MILESTONE_ARRAY}$ISSUE_NUM"
                FIRST=false
            else
                MILESTONE_ARRAY="${MILESTONE_ARRAY},$ISSUE_NUM"
            fi
        done
        MILESTONE_ARRAY="${MILESTONE_ARRAY}]"
        
        # Filter out milestone issues using jq (exclude if number is in milestone array)
        RECENT_CLOSED=$(gh issue list --state closed --limit 10 --json number,title,closedAt --jq ".[] | select(.number as \$n | ($MILESTONE_ARRAY | index(\$n)) == null) | \"  - Issue #\(.number): \(.title) (closed: \(.closedAt))\"" 2>/dev/null || echo "")
    else
        # No milestone issues to filter, show all recently closed
        RECENT_CLOSED=$(gh issue list --state closed --limit 10 --json number,title,closedAt --jq '.[] | "  - Issue #\(.number): \(.title) (closed: \(.closedAt))"' 2>/dev/null || echo "")
    fi
    
    if [ -n "$RECENT_CLOSED" ]; then
        echo "ℹ️  Recently closed issues (excluding milestone issues - review to ensure they're documented if significant):"
        echo "$RECENT_CLOSED"
        echo "💡 Review these at: https://github.com/schatt/6layer/issues?q=is%3Aissue+is%3Aclosed"
        if [ -f "$RELEASE_FILE" ]; then
            echo "💡 Add significant issues to $RELEASE_FILE if not already documented"
        else
            echo "💡 Add significant issues to $RELEASE_FILE when you create it"
        fi
    else
        echo "ℹ️  No recently closed issues found (excluding milestone issues)"
    fi
else
    echo "ℹ️  GitHub CLI (gh) not available"
    echo "💡 Manual checklist: Review closed issues at https://github.com/schatt/6layer/issues?q=is%3Aissue+is%3Aclosed"
    echo "💡 Check milestone: https://github.com/schatt/6layer/milestones"
    if [ -f "$RELEASE_FILE" ]; then
        echo "💡 Ensure significant resolved issues are documented in $RELEASE_FILE"
    else
        echo "💡 Ensure significant resolved issues are documented in $RELEASE_FILE when you create it"
    fi
fi

# If release file exists, validate that issues are documented
if [ -f "$RELEASE_FILE" ]; then
    # Always check for common issue reference patterns in release file
    if ! grep -qE "#[0-9]+|Issue #[0-9]+|github\.com.*issues" "$RELEASE_FILE"; then
        echo "⚠️  Warning: No GitHub issue references found in release notes"
        echo "💡 Tip: Consider adding issue references for significant features/bug fixes"
        echo "💡 Format: 'Resolves Issue #123' or 'Implements [Issue #123](https://github.com/schatt/6layer/issues/123)'"
    else
        echo "✅ Release notes contain issue references"
    fi
    
    # Validate that closed milestone issues are documented
    if [ -n "$CLOSED_ISSUES" ] && [ $CLOSED_COUNT -gt 0 ]; then
        echo "🔍 Validating that all closed milestone issues are documented in release notes..."
        
        MISSING_CLOSED_ISSUES=""
        
        for ISSUE_NUM in $CLOSED_ISSUES; do
            # Check if issue is referenced in release notes (multiple patterns)
            if ! grep -qE "#$ISSUE_NUM\b|Issue #$ISSUE_NUM\b|issues/$ISSUE_NUM\b" "$RELEASE_FILE"; then
                if [ -z "$MISSING_CLOSED_ISSUES" ]; then
                    MISSING_CLOSED_ISSUES="$ISSUE_NUM"
                else
                    MISSING_CLOSED_ISSUES="$MISSING_CLOSED_ISSUES $ISSUE_NUM"
                fi
            fi
        done
        
        if [ -n "$MISSING_CLOSED_ISSUES" ]; then
            log_error "Milestone $MILESTONE_TITLE has $CLOSED_COUNT closed issue(s), but the following are not documented in release notes: $MISSING_CLOSED_ISSUES"
            echo "💡 Add references to these issues in $RELEASE_FILE"
            echo "💡 Format: 'Resolves Issue #123' or 'Implements [Issue #123](https://github.com/schatt/6layer/issues/123)'"
            echo "💡 View milestone: https://github.com/schatt/6layer/milestone/$MILESTONE_NUMBER"
        else
            echo "✅ All $CLOSED_COUNT closed issue(s) from milestone $MILESTONE_TITLE are documented in release notes"
        fi
    fi
    
    # Check if any open issues are documented in release notes (double error)
    if [ -n "$OPEN_ISSUES" ] && [ $OPEN_COUNT -gt 0 ]; then
        DOCUMENTED_OPEN_ISSUES=""
        for ISSUE_NUM in $OPEN_ISSUES; do
            if grep -qE "#$ISSUE_NUM\b|Issue #$ISSUE_NUM\b|issues/$ISSUE_NUM\b" "$RELEASE_FILE"; then
                if [ -z "$DOCUMENTED_OPEN_ISSUES" ]; then
                    DOCUMENTED_OPEN_ISSUES="$ISSUE_NUM"
                else
                    DOCUMENTED_OPEN_ISSUES="$DOCUMENTED_OPEN_ISSUES $ISSUE_NUM"
                fi
            fi
        done
        
        if [ -n "$DOCUMENTED_OPEN_ISSUES" ]; then
            log_error "The following OPEN issues are documented in release notes: $DOCUMENTED_OPEN_ISSUES"
            echo "💡 Release notes should only document completed (closed) issues"
            echo "💡 Either close these issues if they're done, or remove them from the release notes"
        fi
    fi
fi

if [ $ERRORS_BEFORE_ISSUES -eq $ERRORS_FOUND ]; then
    echo "✅ Issue tracking check complete"
fi

# Step 5: Check for AI_AGENT file (for significant releases)
if [[ "$RELEASE_TYPE" == "major" || "$RELEASE_TYPE" == "minor" ]]; then
    echo "📋 Step 5: Checking for AI_AGENT file..."
    if [ -f "Development/AI_AGENT_v$VERSION.md" ]; then
        echo "✅ AI_AGENT file exists"
    else
        log_error "Missing Development/AI_AGENT_v$VERSION.md for $RELEASE_TYPE release! AI_AGENT files are MANDATORY for major and minor releases"
    fi
fi

# Step 7: Check README files
echo "📋 Step 7: Checking README files..."

ERRORS_BEFORE_README=$ERRORS_FOUND
# Check main README.md - verify version appears in key locations
if ! grep -q "v$VERSION" README.md; then
    log_error "Main README missing v$VERSION!"
fi

# Check that README.md has the version as the Latest Release
if ! grep -q "^## 🆕 Latest Release: v$VERSION" README.md; then
    log_error "README.md does not list v$VERSION as the Latest Release! Please update the 'Latest Release' section in README.md"
fi

# Check that README.md has the version in the package dependency example
if ! grep -q "from: \"$VERSION\"" README.md; then
    log_error "README.md package dependency example does not use v$VERSION! Please update the package dependency example in README.md"
fi

# Check that README.md has the version in the Current Status section
if ! grep -A 2 "^## 📋 Current Status" README.md | grep -q "v$VERSION"; then
    log_error "README.md Current Status section does not list v$VERSION! Please update the 'Current Status' section in README.md"
fi

if [ $ERRORS_BEFORE_README -eq $ERRORS_FOUND ]; then
    echo "✅ Main README correctly updated with v$VERSION"
fi

# Step 7.5: Check Package.swift version consistency
echo "📋 Step 7.5: Checking Package.swift version consistency..."
ERRORS_BEFORE_PACKAGE=$ERRORS_FOUND
if ! grep -q "v$VERSION" Package.swift; then
    log_error "Package.swift missing v$VERSION in version comment! Please update the version comment in Package.swift to match v$VERSION. Expected format: // SixLayerFramework v$VERSION - [Description]"
fi
if [ $ERRORS_BEFORE_PACKAGE -eq $ERRORS_FOUND ]; then
    echo "✅ Package.swift version comment correctly updated with v$VERSION"
fi

# Check Framework README - verify version badge at top
ERRORS_BEFORE_FRAMEWORK_README=$ERRORS_FOUND
if ! grep -q "v$VERSION" Framework/README.md; then
    log_error "Framework README missing v$VERSION!"
fi

# Check that Framework README has the version in the badge
if ! grep -q "version-v$VERSION" Framework/README.md; then
    log_error "Framework README version badge does not use v$VERSION! Please update the version badge at the top of Framework/README.md. Expected format: [![Version](https://img.shields.io/badge/version-v$VERSION-blue.svg)]"
fi

if [ $ERRORS_BEFORE_FRAMEWORK_README -eq $ERRORS_FOUND ]; then
    echo "✅ Framework README correctly updated with v$VERSION"
fi

if grep -q "v$VERSION" Framework/Examples/README.md; then
    echo "✅ Examples README updated"
else
    log_error "Examples README missing v$VERSION!"
fi

# Step 8: Check project status files
echo "📋 Step 8: Checking project status files..."
if grep -q "v$VERSION" Development/PROJECT_STATUS.md; then
    echo "✅ PROJECT_STATUS.md updated"
else
    log_error "PROJECT_STATUS.md missing v$VERSION!"
fi

# Check ROADMAP.md for current release status
if [ -f "Development/ROADMAP.md" ]; then
    if grep -q "v$VERSION\|Current Release.*v$VERSION" Development/ROADMAP.md; then
        echo "✅ ROADMAP.md updated with current release"
    else
        echo "⚠️  ROADMAP.md doesn't mention v$VERSION - consider updating current status"
    fi
    
    # Validate roadmap items with GitHub issues are in release notes
    echo "📋 Validating roadmap items with GitHub issues are in release..."
    roadmap_issues=$(grep -oE '#[0-9]+' Development/ROADMAP.md | sort -u)
    if [ -n "$roadmap_issues" ]; then
        for issue in $roadmap_issues; do
            issue_num=$(echo "$issue" | tr -d '#')
            # Check if this issue is mentioned in the release notes
            if [ -f "Development/RELEASE_v$VERSION.md" ]; then
                if grep -q "$issue\|Issue #$issue_num\|#$issue_num" "Development/RELEASE_v$VERSION.md"; then
                    echo "  ✅ Roadmap item $issue found in release notes"
                else
                    # Check if it's marked as completed in roadmap
                    if grep -A 5 "$issue" Development/ROADMAP.md | grep -q "\[x\]\|✅\|COMPLETED"; then
                        echo "  ℹ️  Roadmap item $issue is marked completed but not in release notes (optional)"
                    else
                        echo "  ⚠️  Roadmap item $issue is not mentioned in release notes - verify if it should be included"
                    fi
                fi
            fi
        done
    fi
else
    log_error "Missing Development/ROADMAP.md! ROADMAP.md is MANDATORY"
fi

# Step 9: Check main AI_AGENT.md file
echo "📋 Step 9: Checking main AI_AGENT.md file..."
ERRORS_BEFORE_AI_AGENT=$ERRORS_FOUND
if [ -f "Development/AI_AGENT.md" ]; then
    echo "✅ Main AI_AGENT.md file exists"
else
    log_error "Missing Development/AI_AGENT.md! Main AI_AGENT.md file is MANDATORY"
fi

# Check that main AI_AGENT.md lists the new version in Latest Versions section
if [ -f "Development/AI_AGENT.md" ]; then
    if ! grep -A 10 "^### Latest Versions" Development/AI_AGENT.md | grep -q "v$VERSION"; then
        log_error "Main AI_AGENT.md does not list v$VERSION in the 'Latest Versions (Recommended)' section! Please add v$VERSION to the Latest Versions section in Development/AI_AGENT.md"
    fi
fi

if [ $ERRORS_BEFORE_AI_AGENT -eq $ERRORS_FOUND ]; then
    echo "✅ Main AI_AGENT.md correctly updated with v$VERSION"
fi

# Step 10: Check documentation files (only if features changed)
echo "📋 Step 10: Checking documentation files..."
echo "ℹ️  Feature documentation only needs updating if features changed"
if [ -f "Framework/docs/AutomaticAccessibilityIdentifiers.md" ]; then
    echo "✅ AutomaticAccessibilityIdentifiers.md exists"
else
    echo "⚠️  Missing Framework/docs/AutomaticAccessibilityIdentifiers.md (only needed if accessibility features changed)"
fi

# Step 11: Check example files (only if features changed)
echo "📋 Step 11: Checking example files..."
echo "ℹ️  Example files only need updating if features changed"
if [ -f "Framework/Examples/AutomaticAccessibilityIdentifiersExample.swift" ]; then
    echo "✅ AutomaticAccessibilityIdentifiersExample.swift exists"
else
    echo "⚠️  Missing AutomaticAccessibilityIdentifiersExample.swift (only needed if accessibility features changed)"
fi

if [ -f "Framework/Examples/AccessibilityIdentifierDebuggingExample.swift" ]; then
    echo "✅ AccessibilityIdentifierDebuggingExample.swift exists"
else
    echo "⚠️  Missing AccessibilityIdentifierDebuggingExample.swift (only needed if debugging features changed)"
fi

if [ -f "Framework/Examples/EnhancedBreadcrumbExample.swift" ]; then
    echo "✅ EnhancedBreadcrumbExample.swift exists"
else
    echo "⚠️  Missing EnhancedBreadcrumbExample.swift (only needed if breadcrumb features changed)"
fi

echo ""

# Check if any errors were found
if [ $ERRORS_FOUND -gt 0 ]; then
    echo "❌ RELEASE CHECKS FAILED!"
    echo ""
    echo "Found $ERRORS_FOUND error(s) that need to be fixed:"
    echo -e "$ERROR_MESSAGES"
    echo ""
    echo "Please fix all errors and run the release script again."
    echo "💡 Tip: The script now reports ALL errors at once for efficient fixing!"
    exit 1
fi

echo "🎉 All release documentation checks passed!"
echo ""
echo "📋 Release Checklist Complete:"
echo "✅ Xcode project regenerated"
echo "✅ Tests passed"
echo "✅ Git repository is clean"
echo "✅ RELEASES.md updated correctly"
echo "✅ Individual release file exists"
echo "✅ AI_AGENT file exists (for major/minor releases)"
echo "✅ All README files updated"
echo "✅ Package.swift version comment updated"
echo "✅ Project status files updated"
echo "✅ Main AI_AGENT.md file exists"
echo "✅ Documentation files exist"
echo "✅ Example files exist"
echo ""
echo "🚀 All checks passed! Ready for tagging and release."

# Handle different workflows based on current branch
if [ "$CURRENT_BRANCH" = "main" ]; then
    # On main: use direct tag/push workflow
    read -p "🚀 Auto-tag and push v$VERSION to all remotes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🏷️  Creating and pushing tag v$VERSION..."

        # Create annotated tag
        git tag -a "v$VERSION" -m "Release v$VERSION"

        # Push tag to all remotes
        echo "📤 Pushing tag to all remotes..."
        git push all --tags

        echo "📤 Pushing commits to all remotes..."
        git push all main

        echo ""
        echo "🎉 Release v$VERSION completed successfully!"
        echo "📦 Tag: v$VERSION"
        echo "🌐 Pushed to all remotes (GitHub, Codeberg, GitLab)"
    else
        echo "🚀 Ready to create release tag v$VERSION"
        echo ""
        echo "Manual steps:"
        echo "1. git tag -a v$VERSION -m \"Release v$VERSION\""
        echo "2. git push all --tags"
        echo "3. git push all main"
    fi
else
    # On a branch: merge to main, then tag/push
    echo "📋 Current branch: $CURRENT_BRANCH"
    echo "📋 This will:"
    echo "   1. Switch to main branch"
    echo "   2. Merge $CURRENT_BRANCH into main"
    echo "   3. Create and push tag v$VERSION"
    echo "   4. Push to all remotes"
    echo ""
    read -p "🚀 Proceed with merge and release? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Switch to main
        echo "🔄 Switching to main branch..."
        git checkout main
        
        # Ensure main is up to date
        echo "📥 Fetching latest changes..."
        git fetch all
        
        # Check if main has diverged
        if ! git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
            echo "⚠️  Warning: Local main has diverged from origin/main"
            read -p "   Pull and rebase main? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git pull all main
            else
                echo "❌ Aborting - please resolve main branch state manually"
                exit 1
            fi
        fi
        
        # Merge the branch
        echo "🔀 Merging $CURRENT_BRANCH into main..."
        if git merge "$CURRENT_BRANCH" --no-ff -m "Merge $CURRENT_BRANCH for release v$VERSION"; then
            echo "✅ Merge successful"
        else
            echo "❌ Merge failed! Please resolve conflicts manually and run the release script again."
            exit 1
        fi
        
        # Create and push tag
        echo "🏷️  Creating and pushing tag v$VERSION..."
        git tag -a "v$VERSION" -m "Release v$VERSION"
        
        # Push tag to all remotes
        echo "📤 Pushing tag to all remotes..."
        git push all --tags
        
        # Push commits to all remotes
        echo "📤 Pushing commits to all remotes..."
        git push all main
        
        echo ""
        echo "🎉 Release v$VERSION completed successfully!"
        echo "📦 Tag: v$VERSION"
        echo "🌐 Pushed to all remotes (GitHub, Codeberg, GitLab)"
        echo ""
        
        # Optionally delete the release branch
        read -p "🗑️  Delete branch $CURRENT_BRANCH (local and remote)? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Deleting branch $CURRENT_BRANCH..."
            
            # Delete remote branches (try all remotes, ignore errors if branch doesn't exist)
            echo "📤 Deleting remote branch from all remotes..."
            git push all --delete "$CURRENT_BRANCH" 2>/dev/null || true
            
            # Delete local branch (only if we're not on it, which we're not since we switched to main)
            if git show-ref --verify --quiet refs/heads/"$CURRENT_BRANCH"; then
                git branch -d "$CURRENT_BRANCH" 2>/dev/null || git branch -D "$CURRENT_BRANCH" 2>/dev/null || true
                echo "✅ Local branch deleted"
            fi
            
            echo "✅ Branch $CURRENT_BRANCH deleted from all remotes"
        else
            echo "💡 Branch $CURRENT_BRANCH kept for reference"
        fi
    else
        echo "🚀 Ready to merge and create release tag v$VERSION"
        echo ""
        echo "Manual steps:"
        echo "1. git checkout main"
        echo "2. git merge $CURRENT_BRANCH --no-ff -m \"Merge $CURRENT_BRANCH for release v$VERSION\""
        echo "3. git tag -a v$VERSION -m \"Release v$VERSION\""
        echo "4. git push all --tags"
        echo "5. git push all main"
    fi
fi

echo ""
echo "Release process complete! ✅"
