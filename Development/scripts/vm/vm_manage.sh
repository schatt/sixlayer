#!/usr/bin/env bash
# Manage the SixLayer development VM lifecycle (Tart + Cirrus macOS/Xcode image).
#
# Usage:
#   ./Development/scripts/vm/vm_manage.sh start
#   ./Development/scripts/vm/vm_manage.sh stop
#   ./Development/scripts/vm/vm_manage.sh restart
#   ./Development/scripts/vm/vm_manage.sh status
#   ./Development/scripts/vm/vm_manage.sh ssh
#   ./Development/scripts/vm/vm_manage.sh reset
#   ./Development/scripts/vm/vm_manage.sh set-baseline
#   ./Development/scripts/vm/vm_manage.sh fix
#   ./Development/scripts/vm/vm_manage.sh gui
#   ./Development/scripts/vm/vm_manage.sh ip
#   ./Development/scripts/vm/vm_manage.sh destroy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=vm_config.sh
source "${SCRIPT_DIR}/vm_config.sh"

require_macos
require_tart

cmd_start() {
  if vm_is_running; then
    log_ok "VM '${VM_NAME}' is already running."
    return 0
  fi
  if ! vm_exists; then
    log_error "VM '${VM_NAME}' does not exist. Run vm_setup.sh first."
    exit 1
  fi
  log_info "Starting VM '${VM_NAME}' (headless)..."
  tart run --no-graphics "${VM_NAME}" &
  disown
  require_sshpass
  wait_for_ssh 90
}

cmd_stop() {
  if ! vm_is_running; then
    log_ok "VM '${VM_NAME}' is not running."
    return 0
  fi
  log_info "Stopping VM '${VM_NAME}'..."
  tart stop "${VM_NAME}"
  sleep 3
  log_ok "VM stopped."
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_status() {
  if ! vm_exists; then
    echo "VM '${VM_NAME}': does not exist"
    echo "Baseline '${VM_NAME}-baseline': $(tart list 2>/dev/null | grep -q "${VM_NAME}-baseline" && echo "exists" || echo "does not exist")"
    return
  fi

  local state="stopped"
  if vm_is_running; then
    state="running"
  fi

  echo "VM '${VM_NAME}': ${state}"
  if [[ "$state" == "running" ]]; then
    local ip
    ip="$(get_vm_ip 2>/dev/null || echo 'unknown')"
    echo "  IP: ${ip}"
    echo "  SSH: ssh ${VM_USER}@${ip}"
  fi
  echo "Baseline '${VM_NAME}-baseline': $(tart list 2>/dev/null | grep -q "${VM_NAME}-baseline" && echo "exists" || echo "does not exist")"
}

cmd_ssh() {
  require_sshpass
  if ! vm_is_running; then
    log_error "VM '${VM_NAME}' is not running. Start it first with: $0 start"
    exit 1
  fi
  local ip
  ip="$(get_vm_ip)"
  log_info "Connecting to ${VM_USER}@${ip}..."
  sshpass -p "${VM_PASS}" ssh "${SSH_OPTS[@]}" -t "${VM_USER}@${ip}"
}

cmd_reset() {
  if ! tart list 2>/dev/null | grep -q "${VM_NAME}-baseline"; then
    log_error "No baseline clone found. Run vm_setup.sh first."
    exit 1
  fi

  log_info "Resetting VM '${VM_NAME}' to baseline..."

  if vm_is_running; then
    log_info "Stopping running VM..."
    tart stop "${VM_NAME}" 2>/dev/null || true
    sleep 3
  fi

  tart delete "${VM_NAME}" 2>/dev/null || true
  tart clone "${VM_NAME}-baseline" "${VM_NAME}"
  log_ok "VM reset to baseline. Start with: $0 start"
}

cmd_set_baseline() {
  if ! vm_exists; then
    log_error "VM '${VM_NAME}' does not exist. Run vm_setup.sh first."
    exit 1
  fi

  log_info "Saving current VM state as new baseline..."

  if vm_is_running; then
    log_info "Stopping VM..."
    tart stop "${VM_NAME}" 2>/dev/null || true
    sleep 3
  fi

  tart delete "${VM_NAME}-baseline" 2>/dev/null || true
  tart clone "${VM_NAME}" "${VM_NAME}-baseline"
  log_ok "Baseline updated. Future 'reset' will restore to this state."
}

cmd_fix() {
  if ! vm_exists; then
    log_error "VM '${VM_NAME}' does not exist. Run vm_setup.sh first."
    exit 1
  fi
  require_sshpass
  if ! vm_is_running; then
    log_info "VM not running. Starting it..."
    tart run --no-graphics "${VM_NAME}" &
    disown
    wait_for_ssh 90
  fi
  log_info "Running provisioning steps on existing VM..."
  vm_provision_guest
  log_ok "Fix complete. Run set-baseline to save this state (optional)."
}

cmd_gui() {
  if ! vm_exists; then
    log_error "VM '${VM_NAME}' does not exist. Run vm_setup.sh first."
    exit 1
  fi
  if vm_is_running; then
    log_warn "VM is already running (possibly headless). Stop it first to switch to GUI mode."
    exit 1
  fi
  log_info "Starting VM '${VM_NAME}' with display..."
  tart run "${VM_NAME}" &
  disown
  log_ok "VM started with GUI. Use Cmd+Q in the Tart window to stop."
}

cmd_ip() {
  if ! vm_is_running; then
    log_error "VM is not running."
    exit 1
  fi
  get_vm_ip
}

cmd_destroy() {
  read -rp "This will permanently delete '${VM_NAME}' and '${VM_NAME}-baseline'. Continue? [y/N] " confirm
  if [[ "$confirm" != [yY] ]]; then
    log_info "Cancelled."
    exit 0
  fi

  if vm_is_running; then
    tart stop "${VM_NAME}" 2>/dev/null || true
    sleep 3
  fi

  tart delete "${VM_NAME}" 2>/dev/null && log_ok "Deleted '${VM_NAME}'" || true
  tart delete "${VM_NAME}-baseline" 2>/dev/null && log_ok "Deleted '${VM_NAME}-baseline'" || true
}

usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  start          Boot VM headless (background)
  stop           Shut down VM
  restart        Stop + start
  status         VM state and IP
  ssh            Interactive SSH (password auth)
  reset          Restore VM to baseline clone
  set-baseline   Save current VM as new baseline
  fix            Re-run guest provisioning (xcodegen sync, etc.)
  gui            Boot with Tart window
  ip             Print VM IP
  destroy        Delete VM and baseline
EOF
}

case "${1:-}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) cmd_restart ;;
  status)  cmd_status ;;
  ssh)     cmd_ssh ;;
  reset)         cmd_reset ;;
  set-baseline)  cmd_set_baseline ;;
  fix)           cmd_fix ;;
  gui)           cmd_gui ;;
  ip)      cmd_ip ;;
  destroy) cmd_destroy ;;
  -h|--help) usage ;;
  *)
    if [[ -n "${1:-}" ]]; then
      log_error "Unknown command: $1"
    fi
    usage
    exit 1
    ;;
esac
