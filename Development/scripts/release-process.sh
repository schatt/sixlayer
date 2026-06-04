#!/bin/bash

# SixLayer Framework Release Process Script
# This script enforces the mandatory release documentation process
#
# Branch and Tag Naming Convention:
# - Branches: b<major>/bX.Y.Z (e.g., b7/b7.7.1) — release-prep / integration lines; major folder matches semver major
# - Legacy flat bX.Y.Z (e.g., b7.7.1) is still recognized until fully migrated
# - Tags: v7.0.0 format (e.g., v7.0.0, v7.0.1) - used for releases on main
# - After a successful merge+tag from a release-prep branch, the script creates the next patch line:
#   b<major>/b<X.Y.(Z+1)> where vX.Y.Z is the version you just released (e.g. v7.7.1 -> b7/b7.7.2).
#
# Flags:
#   --release  Non-interactive release: auto-accept suggested version (when prompted),
#              proceed with tag/push or merge+release, skip branch delete (keeps branch,
#              switches back when not on main). Does not auto-resolve a diverged main.
#
# Version suggestion (when VERSION is omitted): latest local semver tag vX.Y.Z, then
# Package.swift, then README.md. Removed tags are not visible; pass an explicit version
# for non-linear cases (e.g. emergency re-release).

set -e

# -----------------------------------------------------------------------------
# Per-run logging: capture the entire release process output in /tmp
# -----------------------------------------------------------------------------
LOG_STAMP="$(date +"%Y%m%d_%H%M%S")"
RELEASE_LOG_FILE="/tmp/release_process_${LOG_STAMP}.txt"

# Duplicate all stdout/stderr to the timestamped log file.
# This must run before any other output to ensure a complete trace.
exec > >(tee -a "${RELEASE_LOG_FILE}") 2>&1

echo "📄 Release process log: ${RELEASE_LOG_FILE}"

AUTO_RELEASE=0
POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        --release)
            AUTO_RELEASE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--release] [release_type|version] [version|release_type]"
            echo ""
            echo "  --release  Run without prompts: confirm tag/push or merge+release, keep release branch."
            echo "             Auto-accepts suggested version when version is inferred from the repo."
            echo ""
            echo "  Omitted version: bump is suggested from latest local vX.Y.Z tag, else Package.swift, else README."
            echo ""
            echo "Examples:"
            echo "  $0 minor"
            echo "  $0 --release patch"
            echo "  $0 --release 7.2.0 minor"
            exit 0
            ;;
        -*)
            echo "❌ Unknown option: $1" >&2
            echo "Usage: $0 [--release] [release_type] [version]  (see --help)" >&2
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

ARG1=${POSITIONAL[0]:-}
ARG2=${POSITIONAL[1]:-}

# Latest released version from local git tags (strict vMAJOR.MINOR.PATCH only).
# Best-effort baseline for semver bump; use explicit VERSION if tags were deleted or skewed.
extract_version_from_git_tags() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi
    local latest
    latest=$(
        git tag 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
    ) || true
    if [ -z "$latest" ]; then
        return 1
    fi
    echo "${latest#v}"
    return 0
}

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

# Prints "SOURCE|X.Y.Z" where SOURCE is tags|package|readme for messaging; fails if none found.
resolve_baseline_version() {
    local version
    version=$(extract_version_from_git_tags)
    if [ -n "$version" ]; then
        echo "tags|$version"
        return 0
    fi
    version=$(extract_version_from_package)
    if [ -n "$version" ]; then
        echo "package|$version"
        return 0
    fi
    version=$(extract_version_from_readme)
    if [ -n "$version" ]; then
        echo "readme|$version"
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

# Released SemVer X.Y.Z -> next patch only (7.6.2 -> 7.6.3; 7.7.0 -> 7.7.1) for the next release-prep branch leaf.
next_patch_semver() {
    local current_version=$1
    IFS='.' read -r major minor patch <<< "$current_version"
    patch=$((patch + 1))
    echo "$major.$minor.$patch"
}

# Released SemVer X.Y.Z -> next standard release-prep branch b<major>/b<X.Y.(Z+1)>.
next_release_prep_branch_name() {
    local released_version=$1
    local next_semver
    next_semver=$(next_patch_semver "$released_version")
    IFS='.' read -r major _ _ <<< "$next_semver"
    echo "b${major}/b${next_semver}"
}

# git push all does not set branch.*.merge; track origin so status/hooks see ahead/behind.
set_branch_upstream_to_origin() {
    local branch="${1:-$(git branch --show-current)}"
    if [ -z "$branch" ]; then
        return 0
    fi
    git fetch origin "$branch" 2>/dev/null || true
    if git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null 2>&1; then
        git branch --set-upstream-to="origin/$branch" "$branch"
        echo "✅ Tracking origin/$branch"
    else
        echo "⚠️  Could not set upstream: origin/$branch not found after push"
    fi
}

# Function to check if a string looks like a version number (X.Y.Z)
is_version_number() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Parse positional arguments with smart detection
# Order: [release_type] [version]
# If first positional looks like a version (X.Y.Z), treat it as version
# Otherwise, treat it as release_type

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
    echo "Usage: $0 [--release] [release_type] [version]"
    echo "       $0 [--release] [version] [release_type]"
    echo "Examples:"
    echo "  $0 minor              # Auto-detect version, minor release"
    echo "  $0 5.8.0              # Explicit version, patch release (default)"
    echo "  $0 minor 5.8.0        # Explicit type and version"
    echo "  $0 5.8.0 minor        # Version first, then type (also works)"
    echo "  $0 --release patch    # Non-interactive patch release (see header comment)"
    exit 1
fi

# If version not provided, suggest one based on current version
if [ -z "$VERSION" ]; then
    BASELINE_RESOLVED=$(resolve_baseline_version) || true
    if [ -n "$BASELINE_RESOLVED" ]; then
        BASELINE_SOURCE=${BASELINE_RESOLVED%%|*}
        CURRENT_VERSION=${BASELINE_RESOLVED#*|}
    else
        BASELINE_SOURCE=""
        CURRENT_VERSION=""
    fi
    if [ -n "$CURRENT_VERSION" ]; then
        SUGGESTED_VERSION=$(increment_version "$CURRENT_VERSION" "$RELEASE_TYPE")
        if [ $? -eq 0 ]; then
            case "$BASELINE_SOURCE" in
                tags)    echo "📋 Baseline for bump (latest semver tag): v$CURRENT_VERSION" ;;
                package) echo "📋 Baseline for bump (Package.swift): v$CURRENT_VERSION" ;;
                readme)  echo "📋 Baseline for bump (README.md): v$CURRENT_VERSION" ;;
                *)       echo "📋 Baseline for bump: v$CURRENT_VERSION" ;;
            esac
            echo "💡 Suggested next version (${RELEASE_TYPE}): v$SUGGESTED_VERSION"
            echo ""
            if [ "$AUTO_RELEASE" -eq 1 ]; then
                VERSION=$SUGGESTED_VERSION
                echo "✅ Using suggested version: v$VERSION (--release)"
            else
                read -p "Use suggested version v$SUGGESTED_VERSION? (Y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Nn]$ ]]; then
                    echo "❌ Error: Version required"
                    echo "Usage: $0 [--release] [release_type] [version]"
                    echo "       $0 [--release] [version] [release_type]"
                    echo "Examples:"
                    echo "  $0 minor 5.8.0        # Explicit type and version"
                    echo "  $0 5.8.0 minor        # Version first, then type"
                    exit 1
                else
                    VERSION=$SUGGESTED_VERSION
                    echo "✅ Using suggested version: v$VERSION"
                fi
            fi
        else
            echo "❌ Error: Failed to calculate suggested version"
            echo "Usage: $0 [--release] [release_type] [version]"
            echo "       $0 [--release] [version] [release_type]"
            exit 1
        fi
    else
        echo "❌ Error: Version required and could not detect current version"
        echo "Usage: $0 [--release] [release_type] [version]"
        echo "       $0 [--release] [version] [release_type]"
        echo ""
        echo "Could not determine baseline: no semver tag vX.Y.Z, and no version in Package.swift or README.md"
        exit 1
    fi
fi

# Allow explicit version with or without a leading "v" (e.g. 7.5.12 or v7.5.12)
if [[ -n "$VERSION" ]] && [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VERSION="${VERSION#v}"
fi

# Initialize error tracking
ERRORS_FOUND=0
ERROR_MESSAGES=""

log_error() {
    echo "❌ $1"
    ERRORS_FOUND=$((ERRORS_FOUND + 1))
    ERROR_MESSAGES="${ERROR_MESSAGES}\n❌ $1"
}

# Open an .xcresult in Xcode after a failed test gate (local workflow).
# Skip when CI is set (typical macOS runners) or when RELEASE_SKIP_OPEN_XCRESULT=1 (SSH / automation).
maybe_open_xcresult() {
    local bundle="$1"
    if [[ -n "${RELEASE_SKIP_OPEN_XCRESULT:-}" ]]; then
        return 0
    fi
    if [[ -n "${CI:-}" ]]; then
        return 0
    fi
    command -v open >/dev/null 2>&1 || return 0
    if [[ -d "$bundle" ]]; then
        echo "📂 Opening result bundle: $bundle" >&2
        open "$bundle" 2>/dev/null || true
    fi
}

# Optional: create GitHub Release (requires gh CLI, auth, and remote tag v$VERSION)
create_github_release_for_version() {
    local ver=$1
    local tag="v${ver}"
    local notes_file="Development/RELEASE_${tag}.md"

    if ! command -v gh &> /dev/null; then
        echo "ℹ️  gh (GitHub CLI) not installed; skipping GitHub Release"
        echo "💡 https://cli.github.com/manual/installation"
        echo "💡 Manual: gh release create $tag --title \"SixLayer Framework $tag\" --notes-file $notes_file"
        return 0
    fi

    if ! gh auth status &> /dev/null; then
        echo "⚠️  gh not authenticated; skipping GitHub Release"
        echo "💡 Run: gh auth login"
        return 0
    fi

    if [ ! -f "$notes_file" ]; then
        echo "⚠️  $notes_file not found; skipping GitHub Release"
        return 0
    fi

    if gh release view "$tag" &> /dev/null; then
        echo "ℹ️  GitHub Release $tag already exists; skipping"
        return 0
    fi

    echo "📦 Creating GitHub Release $tag..."
    if gh release create "$tag" --title "SixLayer Framework $tag" --notes-file "$notes_file"; then
        local owner_repo
        owner_repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
        if [ -n "$owner_repo" ]; then
            echo "✅ GitHub Release: https://github.com/$owner_repo/releases/tag/$tag"
        else
            echo "✅ GitHub Release created"
        fi
    else
        echo "⚠️  GitHub Release creation failed (tag was pushed). Create manually:"
        echo "   gh release create $tag --title \"SixLayer Framework $tag\" --notes-file $notes_file"
    fi
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

# Step 2: Run tests (unit tests only per platform — no UI tests, no ViewInspector, no AllTests)
echo "📋 Step 2: Running unit test suite (macOS + iOS unit tests only)..."

# Write structured test bundles for triage when the release gate fails (ignored via build/)
RELEASE_TEST_STAMP=$(date -u +"%Y%m%dT%H%M%SZ")
XCRESULT_BASE="build/release-process/${RELEASE_TEST_STAMP}-v${VERSION}"
mkdir -p "$XCRESULT_BASE"
MACOS_XCRESULT="${XCRESULT_BASE}/SLF-macOS-UnitTests.xcresult"
IOS_XCRESULT="${XCRESULT_BASE}/SLF-iOS-UnitTests.xcresult"
echo "📎 xcresult bundles for this run: $MACOS_XCRESULT and $IOS_XCRESULT"

# Run both platform unit tests even if one fails (cross-platform signal). Do not exit here:
# remaining release checks still run so test + documentation failures appear together at the end.
MACOS_TESTS_FAILED=0
IOS_TESTS_FAILED=0

echo "🧪 Running macOS unit tests (SLF-macOS-UnitTests)..."
# Note: do NOT use -quiet here so that any failures print detailed diagnostics
if ! xcodebuild test \
    -project SixLayerFramework.xcodeproj \
    -scheme SLF-macOS-UnitTests \
    -destination "platform=macOS,arch=arm64" \
    -resultBundlePath "$MACOS_XCRESULT" \
    -quiet; then
    MACOS_TESTS_FAILED=1
    log_error "macOS unit tests failed."
else
    echo "✅ macOS unit tests passed"
fi

echo "🧪 Running iOS unit tests on Simulator (SLF-iOS-UnitTests)..."
echo "🧹 Pruning unavailable iOS Simulators..."
xcrun simctl delete unavailable 2>/dev/null || true
IOS_SIM_NAME="${SLF_IOS_TEST_SIMULATOR:-iPhone 16 Pro}"
if ! xcrun simctl list devices available | grep -q "${IOS_SIM_NAME} ("; then
    IOS_RUNTIME=$(xcrun simctl list runtimes available -j | python3 -c "import json,sys; rs=[r for r in json.load(sys.stdin).get('runtimes',[]) if r.get('isAvailable') and 'iOS' in r.get('name','')]; print(sorted(rs,key=lambda r:r.get('version',''))[-1]['identifier'] if rs else '')")
    if [ -n "$IOS_RUNTIME" ]; then
        echo "📱 Creating iOS Simulator: ${IOS_SIM_NAME} (${IOS_RUNTIME})"
        xcrun simctl create "$IOS_SIM_NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro "$IOS_RUNTIME" >/dev/null 2>&1 || true
    fi
fi
if ! xcodebuild test \
    -project SixLayerFramework.xcodeproj \
    -scheme SLF-iOS-UnitTests \
    -destination "platform=iOS Simulator,name=${IOS_SIM_NAME}" \
    -resultBundlePath "$IOS_XCRESULT" \
    -quiet; then
    IOS_TESTS_FAILED=1
    log_error "iOS unit tests failed."
else
    echo "✅ iOS unit tests passed"
fi

# Release gate runs unit tests only (SLF-*-UnitTests). UI/ViewInspector/AllTests are not run here.
if [ "$MACOS_TESTS_FAILED" -eq 1 ] || [ "$IOS_TESTS_FAILED" -eq 1 ]; then
    echo "⚠️  Unit test gate failed on one or more platforms; continuing with remaining release checks." >&2
    echo "📎 macOS xcresult: $MACOS_XCRESULT" >&2
    echo "📎 iOS xcresult:   $IOS_XCRESULT" >&2
    echo "💡 Inspect: xcrun xcresulttool get test-results summary --path <path>" >&2
else
    echo "✅ Unit test suite validation passed (macOS + iOS unit tests only)"
fi

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
    # Note: Release-prep branches use b<major>/bX.Y.Z (e.g., b7/b7.7.1); tags use vX.Y.Z on main
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
NO_RELEASE_MILESTONE=0
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
        NO_RELEASE_MILESTONE=1
        echo "⚠️  Warning: No milestone found for v$VERSION (common for patch releases; optional)"
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
        ISSUES_WITH_INSUFFICIENT_DETAIL=""
        
        for ISSUE_NUM in $CLOSED_ISSUES; do
            # Check if issue is referenced in release notes (multiple patterns)
            if ! grep -qE "#$ISSUE_NUM\b|Issue #$ISSUE_NUM\b|issues/$ISSUE_NUM\b" "$RELEASE_FILE"; then
                if [ -z "$MISSING_CLOSED_ISSUES" ]; then
                    MISSING_CLOSED_ISSUES="$ISSUE_NUM"
                else
                    MISSING_CLOSED_ISSUES="$MISSING_CLOSED_ISSUES $ISSUE_NUM"
                fi
            else
                # Issue is referenced - check if it has sufficient detail based on issue type
                # Extract the section containing this issue reference
                ISSUE_SECTION=$(grep -A 10 -B 2 "#$ISSUE_NUM\b\|Issue #$ISSUE_NUM\b\|issues/$ISSUE_NUM\b" "$RELEASE_FILE" | head -15)
                
                # Determine if this issue requires detailed documentation
                REQUIRES_DETAIL=false
                ISSUE_LABELS=""
                
                if command -v gh &> /dev/null; then
                    ISSUE_LABELS=$(gh issue view "$ISSUE_NUM" --json labels --jq '.labels[].name' 2>/dev/null | tr '\n' ' ' || echo "")
                    
                    # Issues that require detailed documentation:
                    # - Breaking changes
                    # - Major features
                    # - Security fixes
                    # - Performance improvements
                    # - API changes
                    if echo "$ISSUE_LABELS" | grep -qiE "breaking|major|feature|enhancement|security|performance|api"; then
                        REQUIRES_DETAIL=true
                    fi
                fi
                
                # Check if the section is just a one-liner with issue number and title
                # Count lines in the issue section (excluding blank lines and headers)
                NON_BLANK_LINES=$(echo "$ISSUE_SECTION" | grep -v '^[[:space:]]*$' | grep -v '^#' | grep -v '^⚠️' | wc -l | tr -d ' ')
                
                # Count words in the issue section (excluding headers)
                ISSUE_WORDS=$(echo "$ISSUE_SECTION" | grep -v '^#' | grep -v '^⚠️' | wc -w | tr -d ' ')
                
                # Check if it looks like just "Issue #123 - Title" (one-liner)
                # Pattern: Issue #123 followed by dash and title, with minimal other content
                IS_ONE_LINER=false
                if echo "$ISSUE_SECTION" | grep -qE "#$ISSUE_NUM\b.*[-–—].*[A-Z]" && [ "$NON_BLANK_LINES" -le 2 ] && [ "$ISSUE_WORDS" -lt 20 ]; then
                    IS_ONE_LINER=true
                fi
                
                # Flag issues that need detail but don't have it
                if [ "$REQUIRES_DETAIL" = true ] && [ "$IS_ONE_LINER" = true ]; then
                    if [ -z "$ISSUES_WITH_INSUFFICIENT_DETAIL" ]; then
                        ISSUES_WITH_INSUFFICIENT_DETAIL="$ISSUE_NUM"
                    else
                        ISSUES_WITH_INSUFFICIENT_DETAIL="$ISSUES_WITH_INSUFFICIENT_DETAIL $ISSUE_NUM"
                    fi
                elif [ "$IS_ONE_LINER" = true ] && [ "$NON_BLANK_LINES" -lt 2 ]; then
                    # Even minor issues should have at least a brief explanation, not just "Issue #123 - Title"
                    # But we'll only warn, not error, for non-significant issues
                    if [ -z "$ISSUES_WITH_INSUFFICIENT_DETAIL" ]; then
                        ISSUES_WITH_INSUFFICIENT_DETAIL="$ISSUE_NUM"
                    else
                        ISSUES_WITH_INSUFFICIENT_DETAIL="$ISSUES_WITH_INSUFFICIENT_DETAIL $ISSUE_NUM"
                    fi
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
        
        # Check for issues with insufficient detail
        if [ -n "$ISSUES_WITH_INSUFFICIENT_DETAIL" ]; then
            echo ""
            echo "⚠️  Warning: The following issues are referenced but may lack sufficient detail:"
            for ISSUE_NUM in $ISSUES_WITH_INSUFFICIENT_DETAIL; do
                echo "  - Issue #$ISSUE_NUM"
                if command -v gh &> /dev/null; then
                    ISSUE_TITLE=$(gh issue view "$ISSUE_NUM" --json title --jq '.title' 2>/dev/null || echo "")
                    ISSUE_BODY=$(gh issue view "$ISSUE_NUM" --json body --jq '.body' 2>/dev/null | head -c 200 || echo "")
                    ISSUE_LABELS=$(gh issue view "$ISSUE_NUM" --json labels --jq '.labels[].name' 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")
                    echo "    Title: $ISSUE_TITLE"
                    if [ -n "$ISSUE_LABELS" ] && [ "$ISSUE_LABELS" != "null" ]; then
                        echo "    Labels: $ISSUE_LABELS"
                    fi
                    if [ -n "$ISSUE_BODY" ] && [ "$ISSUE_BODY" != "null" ]; then
                        echo "    Description: ${ISSUE_BODY}..."
                    fi
                    echo "    View: https://github.com/schatt/6layer/issues/$ISSUE_NUM"
                    
                    # Check if this is a significant issue that requires more detail
                    if echo "$ISSUE_LABELS" | grep -qiE "breaking|major|feature|enhancement|security|performance|api"; then
                        echo "    ⚠️  This is a significant issue and requires detailed documentation"
                    fi
                fi
            done
            echo ""
            echo "💡 Release notes should include:"
            echo "   - Summary of what was changed/improved (not just issue number and title)"
            echo "   - For significant issues (features, breaking changes, major bugs):"
            echo "     * Technical details about the implementation"
            echo "     * Migration guide if there are breaking changes"
            echo "     * Context about what the change means for users"
            echo "   - For minor issues: Brief explanation is sufficient"
            echo ""
            echo "💡 Example of good release note entry (significant feature):"
            echo "   ## 🆕 New Feature"
            echo "   "
            echo "   ### Configurable Photo Sources (Issue #145)"
            echo "   "
            echo "   Added configurable photo source options to FieldActionOCRScanner, allowing"
            echo "   developers to choose whether to offer camera, photo library, or both options."
            echo "   The implementation includes automatic device capability detection and graceful"
            echo "   fallbacks when camera hardware is unavailable."
            echo ""
            echo "💡 Example of acceptable release note entry (minor fix):"
            echo "   ## 🐛 Bug Fixes"
            echo "   "
            echo "   - **Fixed typo in error message** (Issue #123): Corrected spelling error in"
            echo "     validation error message displayed to users."
            echo ""
        fi
        
        # Extract and display issue details to help write better release notes
        if command -v gh &> /dev/null && [ $CLOSED_COUNT -gt 0 ]; then
            echo "📋 Issue details to help write comprehensive release notes:"
            echo ""
            for ISSUE_NUM in $CLOSED_ISSUES; do
                ISSUE_DATA=$(gh issue view "$ISSUE_NUM" --json number,title,body,labels,state 2>/dev/null || echo "")
                if [ -n "$ISSUE_DATA" ] && [ "$ISSUE_DATA" != "null" ]; then
                    ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r '.title' 2>/dev/null || echo "")
                    ISSUE_BODY=$(echo "$ISSUE_DATA" | jq -r '.body' 2>/dev/null | head -c 300 || echo "")
                    ISSUE_LABELS=$(echo "$ISSUE_DATA" | jq -r '.labels[].name' 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")
                    
                    echo "  Issue #$ISSUE_NUM: $ISSUE_TITLE"
                    if [ -n "$ISSUE_LABELS" ] && [ "$ISSUE_LABELS" != "null" ]; then
                        echo "    Labels: $ISSUE_LABELS"
                    fi
                    if [ -n "$ISSUE_BODY" ] && [ "$ISSUE_BODY" != "null" ] && [ "$ISSUE_BODY" != "" ]; then
                        echo "    Description: ${ISSUE_BODY}..."
                    fi
                    echo "    URL: https://github.com/schatt/6layer/issues/$ISSUE_NUM"
                    echo ""
                fi
            done
            echo "💡 Use these details to write comprehensive release notes with summaries, not just issue numbers and titles"
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
    
    # Validate breaking changes are clearly marked
    echo "🔍 Checking for breaking changes documentation..."
    if grep -qiE "breaking|BREAKING" "$RELEASE_FILE"; then
        # Check if breaking changes section exists and has content
        if grep -qiE "##.*[Bb]reaking|###.*[Bb]reaking|⚠️.*[Bb]reaking" "$RELEASE_FILE"; then
            # Check if breaking changes section has more than just a header
            BREAKING_SECTION=$(grep -A 20 -iE "##.*[Bb]reaking|###.*[Bb]reaking|⚠️.*[Bb]reaking" "$RELEASE_FILE" | head -25)
            BREAKING_CONTENT_LINES=$(echo "$BREAKING_SECTION" | grep -v '^[[:space:]]*$' | grep -v '^#' | grep -v '^⚠️' | wc -l | tr -d ' ')
            
            if [ "$BREAKING_CONTENT_LINES" -lt 3 ]; then
                echo "⚠️  Warning: Breaking changes section found but may lack sufficient detail"
                echo "💡 Breaking changes should include:"
                echo "   - Clear explanation of what changed"
                echo "   - Before/after code examples"
                echo "   - Migration guide"
                echo "   - Impact on users"
            else
                echo "✅ Breaking changes are documented with sufficient detail"
            fi
        else
            echo "⚠️  Warning: Breaking changes mentioned but no dedicated section found"
            echo "💡 Consider adding a '## ⚠️ Breaking Changes' section with detailed migration guide"
        fi
    else
        # Check if any issues are labeled as breaking changes
        if command -v gh &> /dev/null && [ -n "$CLOSED_ISSUES" ] && [ $CLOSED_COUNT -gt 0 ]; then
            BREAKING_ISSUES=""
            for ISSUE_NUM in $CLOSED_ISSUES; do
                ISSUE_LABELS=$(gh issue view "$ISSUE_NUM" --json labels --jq '.labels[].name' 2>/dev/null | tr '\n' ' ' || echo "")
                if echo "$ISSUE_LABELS" | grep -qiE "breaking|major"; then
                    if [ -z "$BREAKING_ISSUES" ]; then
                        BREAKING_ISSUES="$ISSUE_NUM"
                    else
                        BREAKING_ISSUES="$BREAKING_ISSUES $ISSUE_NUM"
                    fi
                fi
            done
            
            if [ -n "$BREAKING_ISSUES" ]; then
                log_error "Issues labeled as breaking changes are not clearly marked in release notes: $BREAKING_ISSUES"
                echo "💡 Add a '## ⚠️ Breaking Changes' section with detailed migration guide"
            fi
        fi
    fi
    
    # Validate release notes have sufficient content (not just issue numbers and titles)
    # This is a softer check - we account for that some issues need less detail
    echo "🔍 Validating release notes have sufficient content..."
    RELEASE_FILE_LINES=$(wc -l < "$RELEASE_FILE" | tr -d ' ')
    RELEASE_FILE_WORDS=$(wc -w < "$RELEASE_FILE" | tr -d ' ')
    
    # Count issue references
    ISSUE_REF_COUNT=$(grep -oE "#[0-9]+|Issue #[0-9]+" "$RELEASE_FILE" | wc -l | tr -d ' ')
    
    # Calculate expected word count based on issue types
    # Significant issues (features, breaking changes) need ~100 words
    # Minor issues (bug fixes, patches) need ~20 words
    # We'll use a conservative average of ~30 words per issue as minimum
    MIN_EXPECTED_WORDS=$((ISSUE_REF_COUNT * 30))
    
    # If there are many issue references but few words, it might be just issue numbers and titles
    # But we're more lenient - this is just a warning, not an error
    if [ "$ISSUE_REF_COUNT" -gt 0 ] && [ "$RELEASE_FILE_WORDS" -lt "$MIN_EXPECTED_WORDS" ]; then
        echo "⚠️  Warning: Release notes may lack sufficient detail"
        echo "   Found $ISSUE_REF_COUNT issue reference(s) but only $RELEASE_FILE_WORDS words"
        echo "   Expected at least ~$MIN_EXPECTED_WORDS words (average ~30 words per issue)"
        echo "💡 Note: Significant issues (features, breaking changes) need more detail"
        echo "💡 Minor issues (bug fixes) can be shorter, but should still explain what was fixed"
    else
        echo "✅ Release notes appear to have sufficient content"
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
    if [ "${MACOS_TESTS_FAILED:-0}" -eq 1 ]; then
        echo "💡 macOS test failures — result bundle: $MACOS_XCRESULT" >&2
        maybe_open_xcresult "$MACOS_XCRESULT"
    fi
    if [ "${IOS_TESTS_FAILED:-0}" -eq 1 ]; then
        echo "💡 iOS test failures — result bundle: $IOS_XCRESULT" >&2
        maybe_open_xcresult "$IOS_XCRESULT"
    fi
    if [ "${NO_RELEASE_MILESTONE:-0}" -eq 1 ]; then
        echo ""
        echo "⚠️  No GitHub milestone v$VERSION found (optional; not a blocker — patch releases often skip milestones). Creating one can help track release work:"
        echo "   gh api repos/:owner/:repo/milestones -X POST -f title=\"v$VERSION\""
    fi
    echo ""
    echo "Please fix all errors and run the release script again."
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
# After tag + main push, create_github_release_for_version runs when gh is installed and authenticated.
if [ "$CURRENT_BRANCH" = "main" ]; then
    # On main: use direct tag/push workflow
    if [ "$AUTO_RELEASE" -eq 1 ]; then
        echo "🚀 Auto-tag and push v$VERSION (--release)"
        REPLY=y
    else
        read -p "🚀 Auto-tag and push v$VERSION to all remotes? (y/N): " -n 1 -r
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🏷️  Creating and pushing tag v$VERSION..."

        # Create annotated tag
        git tag -a "v$VERSION" -m "Release v$VERSION"

        # Push tag to all remotes
        echo "📤 Pushing tag to all remotes..."
        git push all --tags

        echo "📤 Pushing commits to all remotes..."
        git push all main

        create_github_release_for_version "$VERSION"

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
        echo "4. gh release create v$VERSION --title \"SixLayer Framework v$VERSION\" --notes-file Development/RELEASE_v$VERSION.md"
    fi
else
    # On a branch: merge to main, then tag/push
    # Release-prep branches: b<major>/bX.Y.Z (legacy flat bX.Y.Z still recognized)
    echo "📋 Current branch: $CURRENT_BRANCH"
    echo "📋 This will:"
    echo "   1. Push $CURRENT_BRANCH to all remotes"
    echo "   2. Switch to main branch"
    echo "   3. Merge $CURRENT_BRANCH into main"
    echo "   4. Create and push tag v$VERSION (tags use v$VERSION format)"
    echo "   5. Push main to all remotes"
    echo "   6. Create GitHub Release from Development/RELEASE_v$VERSION.md (if gh is installed and authenticated)"
    echo "   7. If $CURRENT_BRANCH is release-prep (b<major>/bM.m.p or legacy bM.m.p): create b<major>/b + next patch after v$VERSION from main and switch (else: switch back to $CURRENT_BRANCH)"
    echo ""
    if [ "$AUTO_RELEASE" -eq 1 ]; then
        echo "🚀 Proceed with merge and release (--release)"
        REPLY=y
    else
        read -p "🚀 Proceed with merge and release? (y/N): " -n 1 -r
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Publish release branch first so remotes match what we merge into main
        echo "📤 Pushing branch $CURRENT_BRANCH to all remotes..."
        if ! git push all "$CURRENT_BRANCH"; then
            echo "❌ Failed to push $CURRENT_BRANCH. Fix the error and run the release script again."
            exit 1
        fi
        echo "✅ Branch $CURRENT_BRANCH pushed to all remotes"
        set_branch_upstream_to_origin "$CURRENT_BRANCH"

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
        
        # Push main to all remotes
        echo "📤 Pushing main to all remotes..."
        git push all main

        create_github_release_for_version "$VERSION"
        
        echo ""
        echo "🎉 Release v$VERSION completed successfully!"
        echo "📦 Tag: v$VERSION"
        echo "🌐 Pushed to all remotes (GitHub, Codeberg, GitLab)"
        echo ""

        # After merge we are on main. If the source branch is release-prep (namespaced or legacy flat), create b<major>/b<next patch>.
        RELEASE_PREP_MATCH=0
        if [[ "$CURRENT_BRANCH" =~ ^b([0-9]+)/b([0-9]+)\.[0-9]+\.[0-9]+$ ]]; then
            if [[ "${BASH_REMATCH[1]}" == "${BASH_REMATCH[2]}" ]]; then
                RELEASE_PREP_MATCH=1
            fi
        elif [[ "$CURRENT_BRANCH" =~ ^b[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            RELEASE_PREP_MATCH=1
        fi
        if [ "$RELEASE_PREP_MATCH" -eq 1 ]; then
            NEXT_SEMVER=$(next_patch_semver "$VERSION")
            NEXT_RELEASE_BRANCH=$(next_release_prep_branch_name "$VERSION")
            echo "📋 Release-prep branch $CURRENT_BRANCH detected; creating $NEXT_RELEASE_BRANCH from main (patch after released v$VERSION → $NEXT_SEMVER)."
            if git show-ref --verify --quiet refs/heads/"$NEXT_RELEASE_BRANCH"; then
                echo "⚠️  Local branch $NEXT_RELEASE_BRANCH already exists; checking out and merging main..."
                git checkout "$NEXT_RELEASE_BRANCH"
                if ! git merge main --no-edit -m "Merge main after v$VERSION release"; then
                    echo "❌ Merge main into $NEXT_RELEASE_BRANCH failed. Resolve conflicts, then: git push all $NEXT_RELEASE_BRANCH"
                    exit 1
                fi
            else
                git checkout -b "$NEXT_RELEASE_BRANCH"
            fi
            if ! git push all "$NEXT_RELEASE_BRANCH"; then
                echo "⚠️  Could not push $NEXT_RELEASE_BRANCH to all remotes; push manually: git push all $NEXT_RELEASE_BRANCH"
            else
                echo "✅ Pushed $NEXT_RELEASE_BRANCH to all remotes"
                set_branch_upstream_to_origin "$NEXT_RELEASE_BRANCH"
            fi
            echo "✅ Now on $NEXT_RELEASE_BRANCH for work after v$VERSION"
            if [ "$AUTO_RELEASE" -ne 1 ]; then
                read -p "🗑️  Delete prior release branch $CURRENT_BRANCH (local and remote)? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "🗑️  Deleting branch $CURRENT_BRANCH..."
                    git push all --delete "$CURRENT_BRANCH" 2>/dev/null || true
                    if git show-ref --verify --quiet refs/heads/"$CURRENT_BRANCH"; then
                        git branch -d "$CURRENT_BRANCH" 2>/dev/null || git branch -D "$CURRENT_BRANCH" 2>/dev/null || true
                        echo "✅ Local branch $CURRENT_BRANCH deleted"
                    fi
                    echo "✅ Remote branch $CURRENT_BRANCH removed where present"
                fi
            fi
        else
            # Not release-prep shape: switch back to the working branch (or stay on main if deleted)
            if [ "$AUTO_RELEASE" -eq 1 ]; then
                echo "💡 Branch $CURRENT_BRANCH is not a release-prep branch (--release); switching back to it if it still exists locally."
                if git show-ref --verify --quiet refs/heads/"$CURRENT_BRANCH"; then
                    echo "🔄 Switching back to $CURRENT_BRANCH..."
                    git checkout "$CURRENT_BRANCH"
                    echo "✅ Now on branch $CURRENT_BRANCH"
                else
                    echo "⚠️  Local branch $CURRENT_BRANCH not found; staying on main"
                fi
            else
                read -p "🗑️  Delete branch $CURRENT_BRANCH (local and remote)? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo "🗑️  Deleting branch $CURRENT_BRANCH..."
                    git push all --delete "$CURRENT_BRANCH" 2>/dev/null || true
                    if git show-ref --verify --quiet refs/heads/"$CURRENT_BRANCH"; then
                        git branch -d "$CURRENT_BRANCH" 2>/dev/null || git branch -D "$CURRENT_BRANCH" 2>/dev/null || true
                        echo "✅ Local branch deleted"
                    fi
                    echo "✅ Branch $CURRENT_BRANCH deleted from all remotes"
                else
                    echo "💡 Branch $CURRENT_BRANCH kept for reference"
                    if git show-ref --verify --quiet refs/heads/"$CURRENT_BRANCH"; then
                        echo "🔄 Switching back to $CURRENT_BRANCH..."
                        git checkout "$CURRENT_BRANCH"
                        echo "✅ Now on branch $CURRENT_BRANCH"
                    else
                        echo "⚠️  Local branch $CURRENT_BRANCH not found; staying on main"
                    fi
                fi
            fi
        fi
    else
        echo "🚀 Ready to merge and create release tag v$VERSION"
        echo ""
        echo "Manual steps:"
        echo "1. git push all $CURRENT_BRANCH"
        echo "2. git checkout main"
        echo "3. git merge $CURRENT_BRANCH --no-ff -m \"Merge $CURRENT_BRANCH for release v$VERSION\""
        echo "4. git tag -a v$VERSION -m \"Release v$VERSION\"  # Tags use v$VERSION format"
        echo "5. git push all --tags"
        echo "6. git push all main"
        echo "7. gh release create v$VERSION --title \"SixLayer Framework v$VERSION\" --notes-file Development/RELEASE_v$VERSION.md"
        echo "8. If on release-prep branch: from main, create b<major>/b<next patch>, push to remotes, checkout"
    fi
fi

echo ""
echo "Release process complete! ✅"
