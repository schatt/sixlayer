#!/usr/bin/env bash
# Release-process tag existence guard (#356).
# Sourced by release-process.sh and unit tests.
#
# Abort before tagging when vX.Y.Z already exists locally or on any remote.

release_tag_name_for_version() {
    local ver="$1"
    ver="${ver#v}"
    echo "v${ver}"
}

# 0 when refs/tags/<tag> exists in the current repository.
release_tag_exists_local() {
    local tag="$1"
    git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1
}

# 0 when any configured remote advertises refs/tags/<tag> (via ls-remote).
release_tag_exists_on_remotes() {
    local tag="$1"
    local remote
    local remotes
    remotes=$(git remote 2>/dev/null) || return 1
    [ -n "$remotes" ] || return 1
    while IFS= read -r remote; do
        [ -n "$remote" ] || continue
        if git ls-remote --exit-code --tags "$remote" "refs/tags/${tag}" >/dev/null 2>&1; then
            return 0
        fi
    done <<< "$remotes"
    return 1
}

# 0 when the tag exists locally or on any remote.
release_tag_exists() {
    local tag="$1"
    if release_tag_exists_local "$tag"; then
        return 0
    fi
    release_tag_exists_on_remotes "$tag"
}

# Print a clear error and return 1 when v$version (or version) already exists.
# Args: version with or without leading v.
release_abort_if_tag_exists() {
    local version="$1"
    local tag
    local where=""
    tag=$(release_tag_name_for_version "$version")

    if release_tag_exists_local "$tag"; then
        where="locally"
    elif release_tag_exists_on_remotes "$tag"; then
        where="on a remote"
    else
        return 0
    fi

    echo "❌ Release tag ${tag} already exists ${where}."
    echo "   Choose a new version, or delete/move the existing tag intentionally before re-releasing."
    return 1
}
