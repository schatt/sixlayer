#!/usr/bin/env bash
# Release-process unit-test stamp helpers (#342, #343).
# Sourced by release-process.sh and unit tests.
#
# After a green macOS+iOS unit-test gate, record HEAD in a single /tmp file.
# Later runs may skip tests when every change since that commit is docs-only.
#
# Release runs are manual, one at a time, from one checkout — so one fixed
# stamp path is enough (override via RELEASE_TEST_STAMP_FILE for tests).

# Absolute path to the stamp file (single shared file).
release_test_stamp_path() {
    echo "${RELEASE_TEST_STAMP_FILE:-/tmp/sixlayer-release-tests-passed}"
}

# True (0) when path is documentation/metadata-only for release re-runs.
release_is_docs_only_path() {
    local p="$1"
    case "$p" in
        README.md|\
        Framework/README.md|\
        Framework/Examples/README.md|\
        Framework/docs/*|\
        Development/RELEASES.md|\
        Development/RELEASE_*.md|\
        Development/AI_AGENT.md|\
        Development/AI_AGENT_*.md|\
        Development/PROJECT_STATUS.md|\
        Development/ROADMAP.md|\
        Development/scripts/ISSUE_TRACKING_GUIDE.md|\
        PROJECT_RULES.md|\
        MANDATORY_TESTING_RULES.md|\
        .cursor/*|\
        .cursorrules)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Write bare commit hash to the stamp file.
release_test_stamp_write() {
    local commit="$1"
    local path
    path=$(release_test_stamp_path)
    printf '%s\n' "$commit" > "$path"
}

# Read bare commit hash from the stamp file.
release_test_stamp_read_commit() {
    local path commit
    path=$(release_test_stamp_path)
    [ -f "$path" ] || return 1
    commit=$(tr -d '[:space:]' < "$path")
    [ -n "$commit" ] || return 1
    printf '%s\n' "$commit"
}

# Paths changed since commit (working tree + untracked), relative to repo root.
release_changed_paths_since() {
    local commit="$1"
    local root="${2:-.}"
    (
        cd "$root" || exit 1
        {
            git diff --name-only "$commit" 2>/dev/null || true
            git ls-files --others --exclude-standard 2>/dev/null || true
        } | awk 'NF' | sort -u
    )
}

# Return 0 if unit tests may be skipped; 1 if they must run.
# force_tests: 1 → always run.
release_should_skip_unit_tests() {
    local root="$1"
    local force_tests="${2:-0}"
    local path commit p

    if [ "$force_tests" -eq 1 ]; then
        return 1
    fi

    path=$(release_test_stamp_path)
    if [ ! -f "$path" ]; then
        return 1
    fi

    commit=$(release_test_stamp_read_commit || true)
    if [ -z "$commit" ]; then
        return 1
    fi

    if ! git -C "$root" cat-file -e "${commit}^{commit}" 2>/dev/null; then
        return 1
    fi

    while IFS= read -r p; do
        [ -z "$p" ] && continue
        if ! release_is_docs_only_path "$p"; then
            return 1
        fi
    done < <(release_changed_paths_since "$commit" "$root")

    return 0
}
