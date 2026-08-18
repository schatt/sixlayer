#!/usr/bin/env bash
# Helpers to export NODE_EXTRA_CA_CERTS for Gitea artifact upload (#432).
# Stub: no parsing or fetch yet.

gitea_node_ca_hostport_from_server_url() {
    printf '%s\n' ""
}

gitea_node_ca_should_skip_host() {
    return 0
}

gitea_node_ca_fetch_pem() {
    return 1
}

gitea_node_ca_write_github_env() {
    return 0
}
