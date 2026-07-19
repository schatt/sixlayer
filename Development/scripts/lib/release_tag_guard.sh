#!/usr/bin/env bash
# Release-process tag existence guard (#356).
# Sourced by release-process.sh and unit tests.
#
# STUB: always reports tags as absent — replaced in green phase.

release_tag_name_for_version() {
    local ver="$1"
    ver="${ver#v}"
    echo "v${ver}"
}

release_tag_exists_local() {
    return 1
}

release_tag_exists_on_remotes() {
    return 1
}

release_tag_exists() {
    return 1
}

release_abort_if_tag_exists() {
    return 0
}
