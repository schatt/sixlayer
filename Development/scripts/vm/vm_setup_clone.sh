#!/usr/bin/env bash
# Create the SixLayer Tart VM by cloning an existing CarManager (or other) VM instead of
# pulling the OCI image from scratch. Reuses Xcode/Homebrew/simulator setup from the source.
#
# Default source is the CarManager *baseline* clone so your running `carmanager-dev` VM can
# stay booted. Override with the first argument or SIXLAYER_VM_CLONE_SOURCE.
#
# Usage:
#   ./Development/scripts/vm/vm_setup_clone.sh
#   ./Development/scripts/vm/vm_setup_clone.sh carmanager-dev-baseline
#   SIXLAYER_VM_CLONE_SOURCE=carmanager-dev ./Development/scripts/vm/vm_setup_clone.sh
#
# Prerequisites: same as vm_setup.sh on the host (Homebrew, tart, sshpass). Source VM must exist
# in `tart list`. If you clone from a live VM name (not *-baseline), that VM must be stopped first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=vm_config.sh
source "${SCRIPT_DIR}/vm_config.sh"

SOURCE_VM="${1:-${SIXLAYER_VM_CLONE_SOURCE:-carmanager-dev-baseline}}"

usage() {
  cat <<EOF
Usage: $0 [source_vm_name]

Clone an existing Tart VM into SixLayer's VM_NAME (${VM_NAME}), tune resources, boot,
run SixLayer provisioning (rsync + xcodegen), and create ${VM_NAME}-baseline.

Arguments:
  source_vm_name   Tart VM to clone (default: carmanager-dev-baseline)

Environment:
  SIXLAYER_VM_CLONE_SOURCE   Default source when no argument is passed
  SIXLAYER_VM_NAME           Target VM name (default: sixlayer-dev)

Tip: Prefer *-baseline as the source so you do not need to stop the running dev VM.
     If you use carmanager-dev, run: tart stop carmanager-dev  first.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

require_macos
require_tart

if ! command -v brew &>/dev/null; then
  log_error "Homebrew is required on the host."
  exit 1
fi

if ! command -v sshpass &>/dev/null; then
  log_info "Installing sshpass on host..."
  brew tap cirruslabs/cli 2>/dev/null || true
  brew install cirruslabs/cli/sshpass 2>/dev/null || brew install sshpass
fi
require_sshpass

tart_vm_named_exists() {
  tart list 2>/dev/null | grep -wq "$1"
}

vm_named_is_running() {
  tart list 2>/dev/null | grep -w "$1" | grep -q "running"
}

if ! tart_vm_named_exists "${SOURCE_VM}"; then
  log_error "Source VM '${SOURCE_VM}' not found. tart list:"
  tart list 2>/dev/null || true
  log_error "Create the CarManager VM first, or pass an existing VM name."
  exit 1
fi

if [[ "${SOURCE_VM}" != *-baseline ]] && vm_named_is_running "${SOURCE_VM}"; then
  log_error "Source '${SOURCE_VM}' is running. Stop it first:"
  log_error "  tart stop ${SOURCE_VM}"
  log_error "Or clone from '${SOURCE_VM%-baseline}-baseline' if it exists."
  exit 1
fi

if tart_vm_named_exists "${VM_NAME}"; then
  log_error "Target VM '${VM_NAME}' already exists. Remove it first, e.g.:"
  log_error "  ${SCRIPT_DIR}/vm_manage.sh destroy"
  log_error "  # or: tart stop ${VM_NAME}; tart delete ${VM_NAME}"
  exit 1
fi

log_info "Cloning '${SOURCE_VM}' -> '${VM_NAME}'..."
tart clone "${SOURCE_VM}" "${VM_NAME}"

log_info "Applying resource limits (${VM_CPUS} CPUs, ${VM_MEMORY} MB RAM, ${VM_DISK_SIZE} GB disk)..."
tart set "${VM_NAME}" --cpu "${VM_CPUS}" --memory "${VM_MEMORY}" --disk-size "${VM_DISK_SIZE}"

log_info "Booting '${VM_NAME}' (headless)..."
tart run --no-graphics "${VM_NAME}" &
VM_PID=$!
trap 'log_warn "Cleaning up..."; kill $VM_PID 2>/dev/null || true' EXIT

wait_for_ssh 90

log_info "Provisioning SixLayer workspace in guest (rsync + xcodegen)..."
vm_provision_guest

log_info "Stopping VM to create baseline clone..."
tart stop "${VM_NAME}" 2>/dev/null || true
sleep 5
wait $VM_PID 2>/dev/null || true
trap - EXIT

log_info "Creating baseline '${VM_NAME}-baseline'..."
tart delete "${VM_NAME}-baseline" 2>/dev/null || true
tart clone "${VM_NAME}" "${VM_NAME}-baseline"
log_ok "Baseline '${VM_NAME}-baseline' ready."

REL_MANAGE="./Development/scripts/vm/vm_manage.sh"
REL_TEST="./Development/scripts/vm/vm_test.sh"

cat <<EOF

════════════════════════════════════════════════════════════
  SixLayer VM created from clone: ${SOURCE_VM}
════════════════════════════════════════════════════════════

  VM name:     ${VM_NAME}
  Baseline:    ${VM_NAME}-baseline
  Project dir: ${VM_PROJECT_DIR} (SixLayer sources synced on provision)

  Next:
    ${REL_MANAGE} start
    ${REL_TEST} sync
    ${REL_TEST} test-ui-macos

EOF
