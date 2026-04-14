#!/usr/bin/env bash
# One-time setup: Tart + sshpass on host, clone SixLayer dev VM from Cirrus macOS/Xcode
# image, provision guest, baseline snapshot.
#
# If you already have a CarManager dev VM, you can clone it instead of re-pulling the OCI image:
#   ./Development/scripts/vm/vm_setup_clone.sh
#
# Usage:
#   ./Development/scripts/vm/vm_setup.sh
#
# Environment overrides (see vm_config.sh):
#   SIXLAYER_VM_NAME       VM name       (default: sixlayer-dev)
#   SIXLAYER_VM_IMAGE      OCI image     (default: ghcr.io/cirruslabs/macos-tahoe-xcode:latest)
#   SIXLAYER_VM_MEMORY     RAM MB        (default: 8192)
#   SIXLAYER_VM_CPUS       CPUs          (default: 4)
#   SIXLAYER_VM_DISK_SIZE  Disk GB       (default: 150)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=vm_config.sh
source "${SCRIPT_DIR}/vm_config.sh"

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      echo "Usage: $0"
      exit 0
      ;;
  esac
done

require_macos

log_info "Step 1/6: Checking host prerequisites..."

if ! command -v brew &>/dev/null; then
  log_error "Homebrew is required. Install from https://brew.sh"
  exit 1
fi

if ! command -v tart &>/dev/null; then
  log_info "Installing Tart..."
  if ! brew tap cirruslabs/cli 2>/dev/null; then
    log_warn "Could not add cirruslabs/cli tap (may already be added)"
  fi
  if ! brew install cirruslabs/cli/tart; then
    log_warn "Homebrew install failed. Trying manual install from GitHub release..."
    TART_HOME="${HOME}/.local/opt/tart"
    TART_BIN="${HOME}/.local/bin"
    mkdir -p "${TART_HOME}" "${TART_BIN}"
    TART_TGZ="$(mktemp -t tart.XXXXXX.tar.gz)"
    if curl -fsSL -o "${TART_TGZ}" "https://github.com/cirruslabs/tart/releases/latest/download/tart.tar.gz"; then
      tar -xzf "${TART_TGZ}" -C "${TART_HOME}"
      if [[ -x "${TART_HOME}/tart.app/Contents/MacOS/tart" ]]; then
        ln -sf "${TART_HOME}/tart.app/Contents/MacOS/tart" "${TART_BIN}/tart"
        export PATH="${TART_BIN}:${PATH}"
        if ! command -v tart &>/dev/null; then
          echo "export PATH=\"${TART_BIN}:\${PATH}\"" >> "${HOME}/.zshrc" 2>/dev/null || true
          echo "export PATH=\"${TART_BIN}:\${PATH}\"" >> "${HOME}/.bashrc" 2>/dev/null || true
          log_ok "Tart installed to ${TART_BIN}. Restart the shell or run: export PATH=\"${TART_BIN}:\$PATH\""
        fi
      else
        log_error "Tart binary not found in archive"
        rm -f "${TART_TGZ}"
        exit 1
      fi
      rm -f "${TART_TGZ}"
    else
      log_error "Could not download Tart. Install manually: https://github.com/cirruslabs/tart/releases"
      exit 1
    fi
  fi
fi
if ! command -v tart &>/dev/null; then
  log_error "Tart is not in PATH after install. Add the Tart bin directory to PATH and re-run."
  exit 1
fi
log_ok "Tart is installed ($(tart --version 2>/dev/null || echo 'unknown version'))"

if ! command -v sshpass &>/dev/null; then
  log_info "Installing sshpass..."
  if ! brew install cirruslabs/cli/sshpass 2>/dev/null; then
    log_warn "Cirrus Labs sshpass failed. Trying homebrew-core..."
    brew install sshpass
  fi
fi
if ! command -v sshpass &>/dev/null; then
  log_error "Could not install sshpass. Install manually: brew install sshpass"
  exit 1
fi
log_ok "sshpass is installed"

log_info "Step 2/6: Creating VM '${VM_NAME}' from ${VM_IMAGE} (pulls image if needed)..."

if vm_exists; then
  log_warn "VM '${VM_NAME}' already exists. Deleting and recreating..."
  if vm_is_running; then
    tart stop "${VM_NAME}" 2>/dev/null || true
    sleep 3
  fi
  tart delete "${VM_NAME}"
fi

tart clone "${VM_IMAGE}" "${VM_NAME}"
log_ok "VM '${VM_NAME}' created."

log_info "Step 3/6: Configuring VM (${VM_CPUS} CPUs, ${VM_MEMORY} MB RAM, ${VM_DISK_SIZE} GB disk)..."
tart set "${VM_NAME}" --cpu "${VM_CPUS}" --memory "${VM_MEMORY}" --disk-size "${VM_DISK_SIZE}"
log_ok "VM configured."

log_info "Step 4/6: Booting VM in headless mode..."
tart run --no-graphics "${VM_NAME}" &
VM_PID=$!

trap 'log_warn "Cleaning up..."; kill $VM_PID 2>/dev/null || true' EXIT

require_sshpass
wait_for_ssh 90

log_info "Step 5/6: Provisioning guest environment..."
vm_provision_guest

log_info "Step 6/6: Verifying installation..."

vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)" && echo "  Xcode: $(xcodebuild -version 2>/dev/null | head -1)"'
vm_ssh 'echo "  iOS Simulator: $(xcrun simctl list runtimes 2>/dev/null | grep -c "iOS" || echo "0") runtime(s)"'
vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)" && echo "  XcodeGen: $(xcodegen --version 2>/dev/null)"'
vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)" && echo "  SwiftLint: $(swiftlint version 2>/dev/null)"'

log_info "Stopping VM to create baseline clone..."
tart stop "${VM_NAME}" 2>/dev/null || true
sleep 5

wait $VM_PID 2>/dev/null || true
trap - EXIT

log_info "Creating baseline clone '${VM_NAME}-baseline'..."
tart delete "${VM_NAME}-baseline" 2>/dev/null || true
tart clone "${VM_NAME}" "${VM_NAME}-baseline"
log_ok "Baseline clone created. Use vm_manage.sh reset to restore."

REL_MANAGE="./Development/scripts/vm/vm_manage.sh"
REL_TEST="./Development/scripts/vm/vm_test.sh"

cat <<EOF

════════════════════════════════════════════════════════════
  SixLayer development VM setup complete
════════════════════════════════════════════════════════════

  VM name:     ${VM_NAME}
  Baseline:    ${VM_NAME}-baseline
  Credentials: ${VM_USER} / ${VM_PASS}
  Project dir: ${VM_PROJECT_DIR}

  Quick start (from repo root):
    ${REL_MANAGE} start          # boot the VM
    ${REL_MANAGE} ssh            # shell in guest
    ${REL_TEST} sync             # rsync repo into VM
    ${REL_TEST} test             # default: SLF-macOS-UITests
    ${REL_MANAGE} stop           # shut down VM

EOF
