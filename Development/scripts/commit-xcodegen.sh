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

echo "Running xcodegen -c..."
xcodegen -c

git add project.yml SixLayerFramework.xcodeproj

if git diff --cached --quiet -- project.yml SixLayerFramework.xcodeproj; then
    echo "No project.yml or XcodeGen output changes to commit."
    exit 0
fi

echo "Committing project.yml and generated Xcode project files..."
git commit -m "$COMMIT_MESSAGE"
