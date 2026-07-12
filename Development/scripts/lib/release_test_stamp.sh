#!/usr/bin/env bash
# Release-process unit-test stamp helpers (#342, #343, #346).
# Sourced by release-process.sh and unit tests.
#
# After a green macOS+iOS unit-test gate, record HEAD in a single /tmp file.
# Later runs may skip tests when every change since that commit is docs-only.
# The stamp means unit tests passed at that commit — not a completed release.

# Absolute path to the stamp file (single shared file).
release_test_stamp_path() {
    echo "${RELEASE_TEST_STAMP_FILE:-/tmp/sixlayer-release-tests-passed}"
}

# True (0) when path is documentation/metadata-only for release re-runs.
# Includes release-prep metadata (version comments, xcodegen output, release scripts).
release_is_docs_only_path() {
    local p="$1"
    case "$p" in
        README.md|\
        Package.swift|\
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
        Development/scripts/release-process.sh|\
        Development/scripts/lib/release_test_stamp.sh|\
        Development/scripts/test_release_*.sh|\
        SixLayerFramework.xcodeproj/project.pbxproj|\
        SixLayerFramework.xcodeproj/xcshareddata/xcschemes/*|\
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

release_test_stamp_read_field() {
    local field="$1"
    local path line
    path=$(release_test_stamp_path)
    [ -f "$path" ] || return 1
    line=$(grep -E "^${field}=" "$path" | head -1 || true)
    [ -n "$line" ] || return 1
    echo "${line#${field}=}"
}

# Read commit hash from stamp (supports legacy bare-hash files).
release_test_stamp_read_commit() {
    local path commit
    path=$(release_test_stamp_path)
    [ -f "$path" ] || return 1
    if commit=$(release_test_stamp_read_field "commit" 2>/dev/null); then
        :
    else
        commit=$(head -1 "$path" | tr -d '[:space:]')
    fi
    [ -n "$commit" ] || return 1
    printf '%s\n' "$commit"
}

release_test_stamp_read_recorded_at() {
    release_test_stamp_read_field "recorded_at" 2>/dev/null || true
}

# 0 = tests only; 1 = a release completed after this gate. Legacy bare-hash → empty (unknown).
release_test_stamp_read_release_completed() {
    local value
    value=$(release_test_stamp_read_field "release_completed" 2>/dev/null || true)
    if [ "$value" = "1" ]; then
        echo "1"
    elif [ "$value" = "0" ]; then
        echo "0"
    fi
}

# Write stamp after macOS+iOS unit tests pass (release may still fail afterward).
release_test_stamp_write() {
    local commit="$1"
    local path
    path=$(release_test_stamp_path)
    cat > "$path" <<EOF
commit=${commit}
recorded_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
release_completed=0
EOF
}

# Call when tag/merge/push release finishes successfully.
release_test_stamp_mark_release_complete() {
    local path commit recorded_at
    path=$(release_test_stamp_path)
    commit=$(release_test_stamp_read_commit || return 1)
    recorded_at=$(release_test_stamp_read_recorded_at)
    if [ -z "$recorded_at" ]; then
        recorded_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    fi
    cat > "$path" <<EOF
commit=${commit}
recorded_at=${recorded_at}
release_completed=1
EOF
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

release_test_stamp_release_status_line() {
    local completed
    completed=$(release_test_stamp_read_release_completed)
    case "$completed" in
        1) echo "   Release from this gate: completed successfully" ;;
        0) echo "   Release from this gate: not completed (tests passed; doc checks or ship may have failed afterward)" ;;
        *) echo "   Release from this gate: unknown (legacy stamp — tests-only skip still applies)" ;;
    esac
}

# Print last-pass stamp and whether a non-docs run would skip or run unit tests.
release_print_unit_test_stamp_status() {
    local root="$1"
    local force_tests="${2:-0}"
    local commit stamp_path recorded_at non_docs_only

    stamp_path=$(release_test_stamp_path)
    if commit=$(release_test_stamp_read_commit 2>/dev/null); then
        recorded_at=$(release_test_stamp_read_recorded_at)
        if [ -n "$recorded_at" ]; then
            echo "📎 Last green unit-test gate: $commit (recorded $recorded_at)"
        else
            echo "📎 Last green unit-test gate: $commit"
        fi
        release_test_stamp_release_status_line
    else
        echo "📎 Last green unit-test gate: (none recorded)"
        echo "   Stamp file: $stamp_path"
    fi

    if [ "$force_tests" -eq 1 ]; then
        echo "📎 Unit test gate (non-docs): would run (--force-tests)"
        return 0
    fi

    if release_should_skip_unit_tests "$root" 0; then
        commit=$(release_test_stamp_read_commit)
        echo "📎 Unit test gate (non-docs): would skip (docs-only changes since $commit)"
        return 0
    fi

    if [ ! -f "$stamp_path" ]; then
        echo "📎 Unit test gate (non-docs): would run (no prior test-pass stamp)"
        return 0
    fi

    if ! commit=$(release_test_stamp_read_commit 2>/dev/null); then
        echo "📎 Unit test gate (non-docs): would run (invalid stamp file)"
        return 0
    fi

    if ! git -C "$root" cat-file -e "${commit}^{commit}" 2>/dev/null; then
        echo "📎 Unit test gate (non-docs): would run (stamp commit not in repo: $commit)"
        return 0
    fi

    non_docs_only=""
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        if ! release_is_docs_only_path "$p"; then
            non_docs_only="$p"
            break
        fi
    done < <(release_changed_paths_since "$commit" "$root")

    if [ -n "$non_docs_only" ]; then
        echo "📎 Unit test gate (non-docs): would run (non-docs-only changes since $commit; e.g. $non_docs_only)"
    else
        echo "📎 Unit test gate (non-docs): would run (non-docs-only changes since $commit)"
    fi
}
