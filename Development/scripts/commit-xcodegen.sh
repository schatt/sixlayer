#!/bin/bash

# Regenerate the Xcode project from project.yml and commit the declarative
# source plus generated project files together.

set -euo pipefail

COMMIT_MESSAGE="${1:-Regenerate Xcode project}"

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required." >&2
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Error: xcodegen is required." >&2
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ ! -f "project.yml" ]; then
    echo "Error: project.yml not found at repository root: $REPO_ROOT" >&2
    exit 1
fi

# Top-level `name:` in the XcodeGen spec is the generated project basename
# (see ProjectSpec "name" — output is "{name}.xcodeproj" next to the spec).
read_spec_project_name() {
    local spec="$1"
    local raw
    raw="$(
        awk '
            /^name:/ {
                sub(/^name:[[:space:]]*/, "")
                sub(/[[:space:]]+#.*/, "")
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
                sub(/^"/, "")
                sub(/"$/, "")
                sub(/^'"'"'/, "")
                sub(/'"'"'$/, "", $0)
                print
                exit
            }
        ' "$spec"
    )"
    if [ -z "$raw" ]; then
        echo "Error: could not find top-level name: in $spec" >&2
        exit 1
    fi
    printf '%s' "$raw"
}

PROJECT_NAME="$(read_spec_project_name project.yml)"
XCODEPROJ="${PROJECT_NAME}.xcodeproj"

echo "Running xcodegen -c..."
xcodegen -c

if [ ! -d "$XCODEPROJ" ]; then
    echo "Error: expected Xcode project directory not found: $XCODEPROJ" >&2
    exit 1
fi

git add -- project.yml "$XCODEPROJ"

if git diff --cached --quiet -- project.yml "$XCODEPROJ"; then
    echo "No project.yml or XcodeGen output changes to commit."
    exit 0
fi

echo "Committing project.yml and generated Xcode project files..."
git commit -m "$COMMIT_MESSAGE"
