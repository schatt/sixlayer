#!/usr/bin/env bash
# Release-process unit-test stamp helpers (#342).
# Sourced by release-process.sh and unit tests.
#
# After a green macOS+iOS unit-test gate, record HEAD under /tmp (repo-scoped).
# Later runs may skip tests when every change since that commit is docs-only.

# Absolute path to the stamp file for a given repo root.
release_test_stamp_path() {
    local root="$1"
    local key
    key=$(printf '%s' "$root" | shasum -a 256 | awk '{print $1}')
    echo "/tmp/sixlayer-release-tests-passed-${key}"
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

release_test_stamp_write() {
    local root="$1"
    local commit="$2"
    local path
    path=$(release_test_stamp_path "$root")
    cat > "$path" <<EOF
commit=${commit}
repo=${root}
passed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
}

release_test_stamp_read_commit() {
    local root="$1"
    local path line
    path=$(release_test_stamp_path "$root")
    [ -f "$path" ] || return 1
    line=$(grep -E '^commit=' "$path" | head -1 || true)
    [ -n "$line" ] || return 1
    echo "${line#commit=}"
}

release_test_stamp_read_repo() {
    local root="$1"
    local path line
    path=$(release_test_stamp_path "$root")
    [ -f "$path" ] || return 1
    line=$(grep -E '^repo=' "$path" | head -1 || true)
    [ -n "$line" ] || return 1
    echo "${line#repo=}"
}

# Paths changed since commit (working tree + untracked), relative to repo root.
# Runs in the current directory (caller should cd to repo root) unless REPO_ROOT set.
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
    local path commit stamped_repo changed p

    if [ "$force_tests" -eq 1 ]; then
        return 1
    fi

    path=$(release_test_stamp_path "$root")
    if [ ! -f "$path" ]; then
        return 1
    fi

    stamped_repo=$(release_test_stamp_read_repo "$root" || true)
    if [ "$stamped_repo" != "$root" ]; then
        return 1
    fi

    commit=$(release_test_stamp_read_commit "$root" || true)
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
