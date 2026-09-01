#!/usr/bin/env bash
# Write NODE_EXTRA_CA_CERTS to GITHUB_ENV for Gitea artifact upload (#432).
#
# Usage: export-gitea-node-ca.sh
# Prefers an existing NODE_EXTRA_CA_CERTS file; otherwise fetches the peer
# certificate of GITHUB_SERVER_URL. Skips github.com. Never disables TLS verify.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/gitea_node_ca.sh
source "${SCRIPT_DIR}/lib/gitea_node_ca.sh"

DEST="${GITEA_NODE_CA_PEM:-${RUNNER_TEMP:-/tmp}/gitea-node-ca/gitea.pem}"
URL="${GITHUB_SERVER_URL:-}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
    gitea_node_ca_write_github_env "$GITHUB_ENV" "$URL" "$DEST"
    exit 0
fi

TMP_ENV="$(mktemp "${TMPDIR:-/tmp}/gitea-node-ca-env.XXXXXX")"
trap 'rm -f "$TMP_ENV"' EXIT
gitea_node_ca_write_github_env "$TMP_ENV" "$URL" "$DEST"
if [[ -s "$TMP_ENV" ]]; then
    cat "$TMP_ENV"
fi
