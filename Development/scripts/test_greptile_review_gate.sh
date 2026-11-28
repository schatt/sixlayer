#!/usr/bin/env bash
# Tests for greptile_review_gate.sh (#723). Uses a stub `gh` on PATH that serves
# JSON fixtures, so no network or GitHub state is needed.
#
# Gate contract (exit codes):
#   0  Greptile review complete on current head SHA, no unresolved Greptile threads
#   1  unresolved Greptile review threads remain
#   2  review absent/pending (timeout), failed, stale head SHA, or thread list truncated
#   3  usage error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="${SCRIPT_DIR}/greptile_review_gate.sh"
PASS=0
FAIL=0

assert_eq() {
    local got="$1" want="$2" label="$3"
    if [ "$got" = "$want" ]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   got:  $got"
        echo "   want: $want"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        echo "   missing: $needle"
        echo "   in: $haystack"
        FAIL=$((FAIL + 1))
    fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"

# Stub gh: dispatches on subcommand, reads fixtures from $FIX.
cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
    "repo view") echo "schatt/sixlayer" ;;
    "pr view")   cat "$FIX/head_sha" ;;
    "api graphql") cat "$FIX/threads.json" ;;
    "api repos/"*) cat "$FIX/check_runs.json" ;;
    *) echo "stub gh: unexpected: $*" >&2; exit 64 ;;
esac
STUB
chmod +x "$WORK/bin/gh"

SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
OLD="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

check_runs() { # status conclusion head_sha [slug] [name]
    local status="$1" conclusion="$2" sha="$3" slug="${4:-greptile-apps}" name="${5:-Greptile Review}"
    jq -n --arg s "$status" --arg c "$conclusion" --arg h "$sha" --arg slug "$slug" --arg n "$name" '
        {check_runs: [
            {name: "CodeQL", status: "completed", conclusion: "success", head_sha: $h, app: {slug: "github-advanced-security"}},
            {name: $n, status: $s, conclusion: (if $c == "" then null else $c end), head_sha: $h, app: {slug: $slug}}
        ]}'
}

thread() { # resolved author path
    jq -n --argjson r "$1" --arg a "$2" --arg p "$3" '
        {isResolved: $r, isOutdated: false, comments: {nodes: [{author: {login: $a}, path: $p, body: "**finding** body text"}]}}'
}

threads() { # hasNextPage [thread...]
    local next="$1"; shift
    local nodes="[]"
    if [ "$#" -gt 0 ]; then
        nodes="$(printf '%s\n' "$@" | jq -s '.')"
    fi
    jq -n --argjson n "$next" --argjson nodes "$nodes" '
        {data: {repository: {pullRequest: {reviewThreads: {pageInfo: {hasNextPage: $n}, nodes: $nodes}}}}}'
}

run_gate() { # uses $FIX; sets OUT and RC
    set +e
    OUT="$(FIX="$FIX" PATH="$WORK/bin:$PATH" bash "$GATE" --timeout 1 --interval 1 42 2>&1)"
    RC=$?
    set -e
}

new_case() {
    FIX="$WORK/$1"
    mkdir -p "$FIX"
    echo "$SHA" > "$FIX/head_sha"
}

# 1. Clean: check complete on head SHA, no threads.
new_case clean
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads false > "$FIX/threads.json"
run_gate
assert_eq "$RC" "0" "clean review passes"

# 2. Unresolved Greptile thread blocks.
new_case unresolved
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads false "$(thread false greptile-apps Framework/A.swift)" > "$FIX/threads.json"
run_gate
assert_eq "$RC" "1" "unresolved Greptile thread blocks"
assert_contains "$OUT" "Framework/A.swift" "unresolved thread output names the file"

# 3. Resolved Greptile threads pass.
new_case resolved
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads false "$(thread true greptile-apps Framework/A.swift)" > "$FIX/threads.json"
run_gate
assert_eq "$RC" "0" "resolved Greptile thread passes"

# 4. Unresolved human thread does not trip the Greptile gate.
new_case human
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads false "$(thread false schatt Framework/A.swift)" > "$FIX/threads.json"
run_gate
assert_eq "$RC" "0" "unresolved human thread is not a Greptile finding"

# 5. [bot] login suffix is recognised.
new_case botsuffix
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads false "$(thread false 'greptile-apps[bot]' Framework/B.swift)" > "$FIX/threads.json"
run_gate
assert_eq "$RC" "1" "greptile-apps[bot] login counts as Greptile"

# 6. Check run still in progress → timeout.
new_case pending
check_runs in_progress "" "$SHA" > "$FIX/check_runs.json"
threads false > "$FIX/threads.json"
run_gate
assert_eq "$RC" "2" "in-progress Greptile check times out"

# 7. No Greptile check run for this SHA → timeout (never silently pass).
new_case absent
check_runs completed success "$SHA" other-app "Other Check" > "$FIX/check_runs.json"
threads false > "$FIX/threads.json"
run_gate
assert_eq "$RC" "2" "missing Greptile check run is not a pass"

# 8. Check run is for an older SHA (stale review).
new_case stale
check_runs completed success "$OLD" > "$FIX/check_runs.json"
threads false > "$FIX/threads.json"
run_gate
assert_eq "$RC" "2" "review of a stale head SHA is not accepted"

# 9. Greptile check failed.
new_case failed
check_runs completed failure "$SHA" > "$FIX/check_runs.json"
threads false > "$FIX/threads.json"
run_gate
assert_eq "$RC" "2" "failed Greptile check is not a pass"

# 10. Thread list truncated → cannot prove no findings.
new_case truncated
check_runs completed success "$SHA" > "$FIX/check_runs.json"
threads true > "$FIX/threads.json"
run_gate
assert_eq "$RC" "2" "paginated thread list is rejected, not assumed clean"

# 11. Usage error.
set +e
PATH="$WORK/bin:$PATH" bash "$GATE" >/dev/null 2>&1
USAGE_RC=$?
set -e
assert_eq "$USAGE_RC" "3" "missing PR number is a usage error"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
