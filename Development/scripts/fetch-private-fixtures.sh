#!/bin/bash
# Clone or update the private real-photo fixtures that some OCR tests read.
#
#   Development/scripts/fetch-private-fixtures.sh
#
# The fixtures live in schatt/sixlayer-test-fixtures (private) and land in
# Development/TestFixtures/private, which .gitignore keeps out of this repo.
# It is deliberately not a submodule: SwiftPM checks out a dependency's
# submodules, so a private one would break package resolution for consumers.
#
# Auth: locally uses your normal git credentials. CI must set
# SIXLAYER_FIXTURES_TOKEN (read-only for that repo). Without access the script
# warns and exits 0; tests that need a missing photo skip themselves.
#
# In CI without a token, credential helpers are disabled so the missing secret
# fails fast instead of hanging on osxkeychain (#685).
set -euo pipefail
export GIT_TERMINAL_PROMPT=0

root="$(cd "$(dirname "$0")/../.." && pwd)"
dest="$root/Development/TestFixtures/private"
repo="github.com/schatt/sixlayer-test-fixtures.git"

auth=()
if [[ -n "${SIXLAYER_FIXTURES_TOKEN:-}" ]]; then
  # Pass the token as a header so it is not stored in the clone's remote URL.
  # Do not clear credential.helper here: on current Git that drops the header
  # and forces a username prompt instead of sending basic auth.
  auth=(-c "http.https://github.com/.extraheader=AUTHORIZATION: basic $(printf 'x-access-token:%s' "$SIXLAYER_FIXTURES_TOKEN" | base64 | tr -d '\n')")
elif [[ "${CI:-}" == "true" ]]; then
  # No secret configured: do not consult osxkeychain (hangs on self-hosted).
  auth=(-c credential.helper=)
fi

if [[ -d "$dest/.git" ]]; then
  if ! git ${auth[@]+"${auth[@]}"} -C "$dest" pull --ff-only --quiet; then
    echo "warning: could not update private fixtures in $dest; using what is there" >&2
  fi
else
  mkdir -p "$(dirname "$dest")"
  if ! git ${auth[@]+"${auth[@]}"} clone --quiet --depth 1 "https://$repo" "$dest"; then
    echo "warning: no access to $repo; tests that need private photos will skip" >&2
    exit 0
  fi
fi
echo "private fixtures: $dest ($(git -C "$dest" rev-parse --short HEAD))"
