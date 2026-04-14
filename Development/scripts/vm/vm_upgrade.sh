#!/usr/bin/env bash
# Upgrade Tart, refresh the SixLayer dev VM OCI image, optionally recreate VMs.
# Adapted from CarManager.
#
# Usage:
#   ./Development/scripts/vm/vm_upgrade.sh status
#   ./Development/scripts/vm/vm_upgrade.sh cli
#   ./Development/scripts/vm/vm_upgrade.sh pull
#   ./Development/scripts/vm/vm_upgrade.sh recreate [-y]
#   ./Development/scripts/vm/vm_upgrade.sh all [-y]
#   ./Development/scripts/vm/vm_upgrade.sh prune [-- …]
#
# Env: SIXLAYER_VM_RECREATE_SHUTDOWN_WAIT_SEC (0 = wait until you shut down guest; default 0)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=vm_config.sh
source "${SCRIPT_DIR}/vm_config.sh"

usage() {
  cat <<EOF
Usage: $0 <command> [options]

Commands:
  status    Tart version, VM_IMAGE / VM_NAME, tart list
  cli       brew upgrade tart (Homebrew install only)
  pull      tart pull on SIXLAYER_VM_IMAGE
  recreate  Archive baseline, delete live VM, clone image; GUI boot, provision, wait for shutdown, new baseline
            -y / --yes  skip confirmation
            Env: SIXLAYER_VM_RECREATE_SHUTDOWN_WAIT_SEC (max wait seconds; 0 = unlimited)
  all       cli + pull + recreate
  prune     Pass-through: tart prune

See vm_config.sh for SIXLAYER_VM_* variables.
EOF
}

cmd_status() {
  require_macos
  echo "VM_NAME:     ${VM_NAME}"
  echo "VM_IMAGE:    ${VM_IMAGE}"
  if command -v tart &>/dev/null; then
    echo "Tart CLI:    $(tart --version 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Local VMs (tart list):"
    tart list 2>/dev/null || true
  else
    echo "Tart CLI:    (not in PATH — run vm_setup.sh or install Tart)"
  fi
}

cmd_cli() {
  require_macos
  if ! command -v brew &>/dev/null; then
    log_warn "Homebrew not found. Skipping CLI upgrade."
    return 0
  fi
  brew tap cirruslabs/cli 2>/dev/null || true
  if brew list --formula tart &>/dev/null; then
    log_info "Upgrading Tart via Homebrew..."
    brew upgrade tart
    require_tart
    log_ok "Tart is now: $(tart --version 2>/dev/null || echo 'unknown')"
  else
    log_warn "Tart is not installed as Homebrew formula 'tart'. Skipping brew upgrade."
  fi
}

cmd_pull() {
  require_macos
  require_tart
  log_info "Pulling registry image: ${VM_IMAGE}"
  tart pull "${VM_IMAGE}"
  log_ok "Pull complete."
}

consume_yes_flags() {
  local a
  YES_FLAG=0
  local -a rest=()
  for a in "$@"; do
    if [[ "$a" == "-y" || "$a" == "--yes" ]]; then
      YES_FLAG=1
    else
      rest+=("$a")
    fi
  done
  RECREATE_ARGS=("${rest[@]}")
}

BASELINE_NAME="${VM_NAME}-baseline"

tart_vm_exists() {
  tart list 2>/dev/null | grep -wq "$1"
}

vm_named_is_running() {
  tart list 2>/dev/null | grep -w "$1" | grep -q "running"
}

stop_named_vm() {
  local n="$1"
  if vm_named_is_running "$n"; then
    log_info "Stopping '${n}'..."
    tart stop "$n" 2>/dev/null || true
    sleep 3
  fi
}

pick_archived_baseline_name() {
  local ts candidate n
  ts="$(date +%Y%m%d-%H%M%S)"
  candidate="${VM_NAME}-baseline-archived-${ts}"
  n=0
  while tart_vm_exists "${candidate}"; do
    n=$((n + 1))
    candidate="${VM_NAME}-baseline-archived-${ts}-${n}"
  done
  printf '%s' "${candidate}"
}

wait_for_vm_stopped() {
  local max_sec="${SIXLAYER_VM_RECREATE_SHUTDOWN_WAIT_SEC:-0}"
  local elapsed=0
  log_info "Shut down the VM from the guest or close Tart (Cmd+Q)."
  log_info "Waiting until '${VM_NAME}' is stopped, then creating baseline."
  while vm_named_is_running "${VM_NAME}"; do
    if [[ "${max_sec}" -gt 0 ]] && [[ "${elapsed}" -ge "${max_sec}" ]]; then
      log_error "Timed out after ${max_sec}s. Stop the VM, then run:"
      log_error "  tart clone '${VM_NAME}' '${BASELINE_NAME}'"
      return 1
    fi
    sleep 3
    elapsed=$((elapsed + 3))
    if (( elapsed % 30 == 0 )); then
      log_info "Still waiting for '${VM_NAME}' to stop (${elapsed}s)..."
    fi
  done
  log_ok "VM '${VM_NAME}' is stopped."
}

cmd_recreate() {
  require_macos
  require_tart
  require_sshpass

  local archived

  consume_yes_flags "$@"
  set -- "${RECREATE_ARGS[@]}"

  if [[ $# -gt 0 ]]; then
    log_error "Unknown arguments: $*"
    exit 1
  fi

  if [[ "${YES_FLAG}" != 1 ]]; then
    read -rp "Recreate '${VM_NAME}' from ${VM_IMAGE}, provision, then save baseline after shutdown? [y/N] " confirm
    if [[ "${confirm}" != [yY] ]]; then
      log_info "Cancelled."
      exit 0
    fi
  fi

  log_info "Pulling latest ${VM_IMAGE}..."
  tart pull "${VM_IMAGE}"

  stop_named_vm "${VM_NAME}"

  if tart_vm_exists "${BASELINE_NAME}"; then
    stop_named_vm "${BASELINE_NAME}"
    archived="$(pick_archived_baseline_name)"
    log_info "Archiving baseline: '${BASELINE_NAME}' -> '${archived}'"
    tart rename "${BASELINE_NAME}" "${archived}"
    log_ok "Previous baseline kept as '${archived}'."
  else
    log_warn "No existing '${BASELINE_NAME}' to archive."
  fi

  if tart_vm_exists "${VM_NAME}"; then
    log_info "Removing live VM '${VM_NAME}'..."
    tart delete "${VM_NAME}" 2>/dev/null || true
  fi

  log_info "Cloning fresh VM from ${VM_IMAGE}..."
  tart clone "${VM_IMAGE}" "${VM_NAME}"

  log_info "Configuring VM (${VM_CPUS} CPUs, ${VM_MEMORY} MB RAM, ${VM_DISK_SIZE} GB disk)..."
  tart set "${VM_NAME}" --cpu "${VM_CPUS}" --memory "${VM_MEMORY}" --disk-size "${VM_DISK_SIZE}"

  log_info "Starting VM '${VM_NAME}' with display..."
  tart run "${VM_NAME}" &
  disown 2>/dev/null || true

  cleanup_recreate_interrupt() {
    log_warn "Interrupted; stopping VM if still running..."
    tart stop "${VM_NAME}" 2>/dev/null || true
  }
  trap cleanup_recreate_interrupt INT HUP

  wait_for_ssh 90

  log_info "Provisioning guest over SSH..."
  vm_provision_guest

  log_ok "Automated provisioning finished."
  if ! wait_for_vm_stopped; then
    trap - INT HUP
    exit 1
  fi
  sleep 2

  trap - INT HUP

  log_info "Creating baseline '${BASELINE_NAME}'..."
  tart delete "${BASELINE_NAME}" 2>/dev/null || true
  tart clone "${VM_NAME}" "${BASELINE_NAME}"

  log_ok "Upgrade complete. Start with: ${SCRIPT_DIR}/vm_manage.sh start"
}

cmd_all() {
  consume_yes_flags "$@"
  set -- "${RECREATE_ARGS[@]}"
  if [[ $# -gt 0 ]]; then
    log_error "Unknown arguments after flags: $*"
    exit 1
  fi
  cmd_cli
  cmd_pull
  if [[ "${YES_FLAG}" == 1 ]]; then
    cmd_recreate -y
  else
    cmd_recreate
  fi
}

cmd_prune() {
  require_macos
  require_tart
  log_info "Running: tart prune $*"
  tart prune "$@"
}

main() {
  case "${1:-}" in
    status)  cmd_status ;;
    cli)     cmd_cli ;;
    pull)    cmd_pull ;;
    recreate) shift; cmd_recreate "$@" ;;
    all)     shift; cmd_all "$@" ;;
    prune)   shift; cmd_prune "$@" ;;
    -h|--help) usage; exit 0 ;;
    "") usage; exit 1 ;;
    *)
      log_error "Unknown command: $1"
      usage
      exit 1
      ;;
  esac
}

main "$@"
