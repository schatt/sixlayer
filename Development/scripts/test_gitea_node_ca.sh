#!/usr/bin/env bash
# Unit tests for Gitea Node CA export (#432).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib/gitea_node_ca.sh"
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

assert_true() {
    local label="$1"
    shift
    if "$@"; then
        echo "✅ $label"
        PASS=$((PASS + 1))
    else
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    fi
}

assert_false() {
    local label="$1"
    shift
    if "$@"; then
        echo "❌ $label"
        FAIL=$((FAIL + 1))
    else
        echo "✅ $label"
        PASS=$((PASS + 1))
    fi
}

if [[ ! -f "$LIB" ]]; then
    echo "❌ missing lib: $LIB"
    exit 1
fi

# shellcheck source=lib/gitea_node_ca.sh
source "$LIB"

assert_eq "$(gitea_node_ca_hostport_from_server_url 'https://192.168.185.4:3000')" \
    "192.168.185.4:3000" "parses host:port from GITHUB_SERVER_URL"
assert_eq "$(gitea_node_ca_hostport_from_server_url 'https://gitea.example.com')" \
    "gitea.example.com:443" "defaults https to port 443"
assert_eq "$(gitea_node_ca_hostport_from_server_url 'https://gitea.example.com/Ds5/sixlayer')" \
    "gitea.example.com:443" "strips path from server URL"
assert_eq "$(gitea_node_ca_hostport_from_server_url 'http://localhost:3000')" \
    "localhost:3000" "parses http localhost with port"
assert_eq "$(gitea_node_ca_hostport_from_server_url '')" \
    "" "empty server URL yields empty hostport"

assert_true "skips github.com" gitea_node_ca_should_skip_host "github.com"
assert_true "skips api.github.com" gitea_node_ca_should_skip_host "api.github.com"
assert_false "does not skip LAN Gitea host" gitea_node_ca_should_skip_host "192.168.185.4"
assert_false "does not skip localhost" gitea_node_ca_should_skip_host "localhost"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/gitea-node-ca-test.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

EXISTING="$WORKDIR/existing.pem"
printf '%s\n' "-----BEGIN CERTIFICATE-----" "EXISTING" "-----END CERTIFICATE-----" > "$EXISTING"
ENV_OUT="$WORKDIR/github.env"
NODE_EXTRA_CA_CERTS="$EXISTING" gitea_node_ca_write_github_env "$ENV_OUT" "https://192.168.185.4:3000" "$WORKDIR/fetched.pem"
assert_eq "$(grep '^NODE_EXTRA_CA_CERTS=' "$ENV_OUT")" \
    "NODE_EXTRA_CA_CERTS=$EXISTING" "reuses existing NODE_EXTRA_CA_CERTS file"
assert_false "does not fetch when NODE_EXTRA_CA_CERTS already set" test -e "$WORKDIR/fetched.pem"

gitea_node_ca_fetch_pem() {
    local hostport="$1"
    local dest="$2"
    printf '%s\n' "-----BEGIN CERTIFICATE-----" "FETCHED-FROM-$hostport" "-----END CERTIFICATE-----" > "$dest"
}

ENV_OUT2="$WORKDIR/github2.env"
unset NODE_EXTRA_CA_CERTS || true
gitea_node_ca_write_github_env "$ENV_OUT2" "https://192.168.185.4:3000" "$WORKDIR/fetched.pem"
assert_eq "$(grep '^NODE_EXTRA_CA_CERTS=' "$ENV_OUT2")" \
    "NODE_EXTRA_CA_CERTS=$WORKDIR/fetched.pem" "writes fetched PEM path to GITHUB_ENV"
assert_true "writes fetched PEM file" grep -Fq "FETCHED-FROM-192.168.185.4:3000" "$WORKDIR/fetched.pem"

ENV_OUT3="$WORKDIR/github3.env"
gitea_node_ca_write_github_env "$ENV_OUT3" "https://github.com" "$WORKDIR/github.pem"
assert_false "does not write env for github.com" test -s "$ENV_OUT3"
assert_false "does not fetch for github.com" test -e "$WORKDIR/github.pem"

echo
echo "Passed: $PASS  Failed: $FAIL"
if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi
