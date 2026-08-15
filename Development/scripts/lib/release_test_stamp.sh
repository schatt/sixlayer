#!/usr/bin/env bash
# Release-process unit-test stamp helpers (#342, #343, #346, #390).
# Sourced by release-process.sh and unit tests.
#
# After each platform's unit tests pass, record that platform for HEAD in a
# single /tmp file. Full Step-3 skip (docs-only) requires both platforms green.
# Per-platform skip lets a retry avoid re-running a platform that already passed
# at the stamped commit (docs-only delta since then still counts as valid).
# The stamp means unit tests passed — not a completed release.

# Absolute path to the stamp file (single shared file).
release_test_stamp_path() {
    echo "${RELEASE_TEST_STAMP_FILE:-/tmp/sixlayer-release-tests-passed}"
}

# True (0) when path is documentation/metadata-only for release re-runs.
# All markdown and LICENSE count as docs. Also release-prep metadata
# (Package.swift, xcodegen output, release scripts, Cursor rules).
release_is_docs_only_path() {
    local p="$1"
    case "$p" in
        *.md|\
        LICENSE|\
        Package.swift|\
        Development/scripts/release-process.sh|\
        Development/scripts/lib/release_test_stamp.sh|\
        Development/scripts/lib/release_tag_guard.sh|\
        Development/scripts/test_release_*.sh|\
        SixLayerFramework.xcodeproj/project.pbxproj|\
        SixLayerFramework.xcodeproj/xcshareddata/xcschemes/*|\
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

# True when stamp has no macos_passed/ios_passed keys (legacy formats).
release_test_stamp_is_legacy_platforms() {
    local path
    path=$(release_test_stamp_path)
    [ -f "$path" ] || return 1
    if grep -qE '^(macos_passed|ios_passed)=' "$path" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Echo 1 if platform passed at stamp, 0 otherwise.
# platform: macos | ios
# Legacy stamps (bare hash or commit= without platform keys) count as both passed.
release_test_stamp_read_platform_passed() {
    local platform="$1"
    local field value path
    case "$platform" in
        macos) field="macos_passed" ;;
        ios) field="ios_passed" ;;
        *) return 1 ;;
    esac
    path=$(release_test_stamp_path)
    [ -f "$path" ] || { echo "0"; return 0; }
    if release_test_stamp_is_legacy_platforms; then
        echo "1"
        return 0
    fi
    value=$(release_test_stamp_read_field "$field" 2>/dev/null || true)
    if [ "$value" = "1" ]; then
        echo "1"
    else
        echo "0"
    fi
}

release_test_stamp_both_platforms_passed() {
    local macos ios
    macos=$(release_test_stamp_read_platform_passed macos)
    ios=$(release_test_stamp_read_platform_passed ios)
    [ "$macos" = "1" ] && [ "$ios" = "1" ]
}

# Rewrite stamp file preserving known fields.
release_test_stamp_write_fields() {
    local commit="$1"
    local recorded_at="$2"
    local macos_passed="$3"
    local ios_passed="$4"
    local release_completed="$5"
    local path
    path=$(release_test_stamp_path)
    cat > "$path" <<EOF
commit=${commit}
recorded_at=${recorded_at}
macos_passed=${macos_passed}
ios_passed=${ios_passed}
release_completed=${release_completed}
EOF
}

# Write stamp after macOS+iOS unit tests pass (release may still fail afterward).
release_test_stamp_write() {
    local commit="$1"
    release_test_stamp_write_fields "$commit" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "1" "1" "0"
}

# Record one platform passing at commit. Different commit resets the other platform.
# platform: macos | ios
release_test_stamp_record_platform_pass() {
    local commit="$1"
    local platform="$2"
    local existing_commit macos_passed ios_passed release_completed recorded_at
    existing_commit=$(release_test_stamp_read_commit 2>/dev/null || true)
    macos_passed=0
    ios_passed=0
    release_completed=0
    if [ -n "$existing_commit" ] && [ "$existing_commit" = "$commit" ]; then
        macos_passed=$(release_test_stamp_read_platform_passed macos)
        ios_passed=$(release_test_stamp_read_platform_passed ios)
        release_completed=$(release_test_stamp_read_release_completed)
        [ -n "$release_completed" ] || release_completed=0
    fi
    case "$platform" in
        macos) macos_passed=1 ;;
        ios) ios_passed=1 ;;
        *)
            echo "release_test_stamp_record_platform_pass: unknown platform: $platform" >&2
            return 1
            ;;
    esac
    recorded_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    release_test_stamp_write_fields "$commit" "$recorded_at" "$macos_passed" "$ios_passed" "$release_completed"
}

# Call when tag/merge/push release finishes successfully.
release_test_stamp_mark_release_complete() {
    local path commit recorded_at macos_passed ios_passed
    path=$(release_test_stamp_path)
    commit=$(release_test_stamp_read_commit || return 1)
    recorded_at=$(release_test_stamp_read_recorded_at)
    if [ -z "$recorded_at" ]; then
        recorded_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    fi
    macos_passed=$(release_test_stamp_read_platform_passed macos)
    ios_passed=$(release_test_stamp_read_platform_passed ios)
    release_test_stamp_write_fields "$commit" "$recorded_at" "$macos_passed" "$ios_passed" "1"
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

# Return 0 if stamp commit is valid and every change since it is docs-only.
release_test_stamp_docs_only_since() {
    local root="$1"
    local commit p

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

# Return 0 if full unit-test Step 3 may be skipped; 1 if some/all tests must run.
# Requires both platforms green (legacy stamps count as both).
release_should_skip_unit_tests() {
    local root="$1"
    local force_tests="${2:-0}"
    local path

    if [ "$force_tests" -eq 1 ]; then
        return 1
    fi

    path=$(release_test_stamp_path)
    if [ ! -f "$path" ]; then
        return 1
    fi

    if ! release_test_stamp_both_platforms_passed; then
        return 1
    fi

    release_test_stamp_docs_only_since "$root"
}

# Return 0 if this platform's unit tests may be skipped on a partial retry.
# platform: macos | ios
release_should_skip_platform_unit_tests() {
    local root="$1"
    local force_tests="${2:-0}"
    local platform="$3"
    local path

    if [ "$force_tests" -eq 1 ]; then
        return 1
    fi

    path=$(release_test_stamp_path)
    if [ ! -f "$path" ]; then
        return 1
    fi

    if [ "$(release_test_stamp_read_platform_passed "$platform")" != "1" ]; then
        return 1
    fi

    release_test_stamp_docs_only_since "$root"
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

release_test_stamp_platform_status_line() {
    local macos ios
    if release_test_stamp_is_legacy_platforms 2>/dev/null; then
        echo "   Platforms: macos=pass ios=pass (legacy stamp)"
        return 0
    fi
    macos=$(release_test_stamp_read_platform_passed macos)
    ios=$(release_test_stamp_read_platform_passed ios)
    echo "   Platforms: macos=$([ "$macos" = "1" ] && echo pass || echo pending) ios=$([ "$ios" = "1" ] && echo pass || echo pending)"
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
        release_test_stamp_platform_status_line
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

    if ! release_test_stamp_both_platforms_passed; then
        echo "📎 Unit test gate (non-docs): would run (partial platform gate; missing platform(s))"
        if release_should_skip_platform_unit_tests "$root" 0 macos; then
            echo "   macOS: would skip (already passed)"
        else
            echo "   macOS: would run"
        fi
        if release_should_skip_platform_unit_tests "$root" 0 ios; then
            echo "   iOS: would skip (already passed)"
        else
            echo "   iOS: would run"
        fi
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
