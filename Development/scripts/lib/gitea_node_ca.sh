#!/usr/bin/env bash
# Helpers to export NODE_EXTRA_CA_CERTS for Gitea artifact upload (#432).
# Source from export-gitea-node-ca.sh or tests.
#
# --use-system-ca is not enough when the Gitea cert is not in the OS trust
# store. Prefer an existing NODE_EXTRA_CA_CERTS file; otherwise fetch the
# peer PEM from GITHUB_SERVER_URL. Skip github.com.

gitea_node_ca_hostport_from_server_url() {
    local url="${1:-}"
    [[ -n "$url" ]] || return 0
    python3 - "$url" <<'PY'
from urllib.parse import urlparse
import sys

raw = sys.argv[1]
parsed = urlparse(raw)
if not parsed.hostname:
    sys.exit(0)
scheme = (parsed.scheme or "https").lower()
port = parsed.port
if port is None:
    port = 443 if scheme == "https" else 80
print(f"{parsed.hostname}:{port}")
PY
}

gitea_node_ca_should_skip_host() {
    local host="${1:-}"
    host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"
    case "$host" in
        github.com|api.github.com) return 0 ;;
        *) return 1 ;;
    esac
}

gitea_node_ca_fetch_pem() {
    local hostport="${1:?hostport required}"
    local dest="${2:?dest required}"
    local host="${hostport%%:*}"
    mkdir -p "$(dirname "$dest")"
    openssl s_client -connect "$hostport" -servername "$host" </dev/null 2>/dev/null \
        | openssl x509 -outform PEM -out "$dest"
}

gitea_node_ca_write_github_env() {
    local env_file="${1:?env file required}"
    local server_url="${2:-}"
    local dest_pem="${3:?dest pem required}"

    if [[ -n "${NODE_EXTRA_CA_CERTS:-}" && -f "${NODE_EXTRA_CA_CERTS}" ]]; then
        printf 'NODE_EXTRA_CA_CERTS=%s\n' "$NODE_EXTRA_CA_CERTS" >> "$env_file"
        return 0
    fi

    local hostport=""
    hostport="$(gitea_node_ca_hostport_from_server_url "$server_url")"
    [[ -n "$hostport" ]] || return 0

    local host="${hostport%%:*}"
    if gitea_node_ca_should_skip_host "$host"; then
        return 0
    fi

    if ! gitea_node_ca_fetch_pem "$hostport" "$dest_pem"; then
        return 0
    fi
    [[ -s "$dest_pem" ]] || return 0
    printf 'NODE_EXTRA_CA_CERTS=%s\n' "$dest_pem" >> "$env_file"
}
