#!/usr/bin/env bash
# Shared configuration for SixLayer VM scripts (adapted from CarManager).
# Source this file; do not execute it directly.
# To reuse a CarManager VM disk instead of vm_setup.sh + OCI image, use vm_setup_clone.sh.

VM_NAME="${SIXLAYER_VM_NAME:-sixlayer-dev}"
VM_IMAGE="${SIXLAYER_VM_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-xcode:latest}"
VM_USER="${SIXLAYER_VM_USER:-admin}"
VM_PASS="${SIXLAYER_VM_PASS:-admin}"
VM_MEMORY="${SIXLAYER_VM_MEMORY:-8192}"
VM_CPUS="${SIXLAYER_VM_CPUS:-4}"
# Cirrus macos-tahoe-xcode image uses ~140 GB disk; Tart cannot shrink, so default must be >= 140
VM_DISK_SIZE="${SIXLAYER_VM_DISK_SIZE:-150}"

# Repository root (parent of Development/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VM_PROJECT_DIR="/Users/${VM_USER}/sixlayer"

XCODE_PROJECT="SixLayerFramework.xcodeproj"
# Default test run: macOS UI tests (disruptive locally; run in VM)
DEFAULT_TEST_SCHEME="${SIXLAYER_VM_DEFAULT_TEST_SCHEME:-SLF-macOS-UITests}"
SCHEME_MACOS_BUILD="${SIXLAYER_VM_SCHEME_MACOS_BUILD:-SLF-macOS-Framework}"
SCHEME_IOS_BUILD="${SIXLAYER_VM_SCHEME_IOS_BUILD:-SLF-iOS-Framework}"
SCHEME_MACOS_TESTAPP="${SIXLAYER_VM_SCHEME_MACOS_TESTAPP:-SLF-macOS-TestApp}"

# Password-only auth: avoid "Too many authentication failures" when ssh-agent has many keys.
SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10 -o PubkeyAuthentication=no -o PreferredAuthentications=password)

VM_SSH_CTRL_SOCK="/tmp/sixlayer-vm-$$.sock"
VM_SSH_MASTER_OPENED=

log_info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
log_warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$*"; }
log_error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }
log_ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*"; }

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script requires macOS."
    exit 1
  fi
}

require_tart() {
  if ! command -v tart &>/dev/null; then
    log_error "Tart is not installed. Install with: brew install cirruslabs/cli/tart"
    exit 1
  fi
}

require_sshpass() {
  if ! command -v sshpass &>/dev/null; then
    log_error "sshpass is not installed. Install with: brew install sshpass (or brew install cirruslabs/cli/sshpass)"
    exit 1
  fi
}

vm_is_running() {
  tart list 2>/dev/null | grep -w "${VM_NAME}" | grep -q "running"
}

vm_exists() {
  tart list 2>/dev/null | grep -wq "${VM_NAME}"
}

get_vm_ip() {
  tart ip "${VM_NAME}" 2>/dev/null
}

wait_for_ssh() {
  local max_attempts="${1:-60}"
  local attempt=0
  log_info "Waiting for SSH to become available..."
  while [[ $attempt -lt $max_attempts ]]; do
    local ip
    ip="$(get_vm_ip 2>/dev/null)" || ip=""
    if [[ -n "$ip" ]] && sshpass -p "${VM_PASS}" ssh "${SSH_OPTS[@]}" "${VM_USER}@${ip}" "echo ok" &>/dev/null; then
      log_ok "SSH is ready at ${ip}"
      return 0
    fi
    attempt=$((attempt + 1))
    printf "."
    sleep 2
  done
  echo
  log_error "SSH did not become available after $((max_attempts * 2)) seconds."
  return 1
}

vm_ssh_open_master() {
  local ip
  ip="$(get_vm_ip)"
  if [[ -z "$ip" ]]; then
    log_error "Cannot determine VM IP. Is '${VM_NAME}' running?"
    return 1
  fi
  if [[ -S "${VM_SSH_CTRL_SOCK}" ]] && ssh -S "${VM_SSH_CTRL_SOCK}" -O check "${VM_USER}@${ip}" 2>/dev/null; then
    return 0
  fi
  sshpass -p "${VM_PASS}" ssh -M -S "${VM_SSH_CTRL_SOCK}" -f -N -o ControlPersist=300 "${SSH_OPTS[@]}" "${VM_USER}@${ip}"
  VM_SSH_MASTER_OPENED=1
}

vm_ssh_close_master() {
  if [[ -z "${VM_SSH_MASTER_OPENED}" ]] || [[ ! -S "${VM_SSH_CTRL_SOCK}" ]]; then
    return 0
  fi
  local ip
  ip="$(get_vm_ip 2>/dev/null)" || true
  if [[ -n "$ip" ]]; then
    ssh -S "${VM_SSH_CTRL_SOCK}" -O exit "${VM_USER}@${ip}" 2>/dev/null || true
  fi
  VM_SSH_MASTER_OPENED=
}

vm_ssh() {
  local ip
  ip="$(get_vm_ip)"
  if [[ -z "$ip" ]]; then
    log_error "Cannot determine VM IP. Is '${VM_NAME}' running?"
    return 1
  fi
  vm_ssh_open_master
  if [[ -S "${VM_SSH_CTRL_SOCK}" ]]; then
    ssh -S "${VM_SSH_CTRL_SOCK}" "${SSH_OPTS[@]}" "${VM_USER}@${ip}" "$@"
  else
    sshpass -p "${VM_PASS}" ssh "${SSH_OPTS[@]}" "${VM_USER}@${ip}" "$@"
  fi
}

vm_rsync_to() {
  local src="$1" dst="$2"
  local ip
  ip="$(get_vm_ip)"
  if [[ -z "$ip" ]]; then
    log_error "Cannot determine VM IP."
    return 1
  fi
  vm_ssh_open_master
  if [[ -S "${VM_SSH_CTRL_SOCK}" ]]; then
    rsync -az --delete \
      -e "ssh -S ${VM_SSH_CTRL_SOCK} ${SSH_OPTS[*]}" \
      --exclude 'node_modules' \
      --exclude '.build' \
      --exclude 'DerivedData' \
      --exclude 'build' \
      --exclude 'artifacts' \
      --exclude '.tart' \
      "$src" "${VM_USER}@${ip}:${dst}"
  else
    sshpass -p "${VM_PASS}" rsync -az --delete \
      -e "ssh ${SSH_OPTS[*]}" \
      --exclude 'node_modules' \
      --exclude '.build' \
      --exclude 'DerivedData' \
      --exclude 'build' \
      --exclude 'artifacts' \
      --exclude '.tart' \
      "$src" "${VM_USER}@${ip}:${dst}"
  fi
}

vm_rsync_from() {
  local src="$1" dst="$2"
  local ip
  ip="$(get_vm_ip)"
  if [[ -z "$ip" ]]; then
    log_error "Cannot determine VM IP."
    return 1
  fi
  vm_ssh_open_master
  if [[ -S "${VM_SSH_CTRL_SOCK}" ]]; then
    rsync -az -e "ssh -S ${VM_SSH_CTRL_SOCK} ${SSH_OPTS[*]}" \
      "${VM_USER}@${ip}:${src}" "$dst"
  else
    sshpass -p "${VM_PASS}" rsync -az -e "ssh ${SSH_OPTS[*]}" "${VM_USER}@${ip}:${src}" "$dst"
  fi
}

# Guest provisioning (vm_setup.sh Step 5 / vm_manage.sh fix).
vm_provision_guest() {
  log_info "Creating ssh-askpass stub (fixes broken /usr/X11R6 in image)..."
  vm_ssh 'sudo mkdir -p /private/var/select/X11/bin && printf "%s\n" "#!/bin/sh" "exit 0" | sudo tee /private/var/select/X11/bin/ssh-askpass >/dev/null && sudo chmod +x /private/var/select/X11/bin/ssh-askpass'

  log_info "Disabling natural scrolling for guest user (${VM_USER})..."
  vm_ssh 'defaults write -g com.apple.swipescrolldirection -bool false'

  log_info "Installing Homebrew in guest..."
  vm_ssh 'command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  log_info "Installing XcodeGen..."
  vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)" && brew install xcodegen 2>/dev/null || true'

  log_info "Installing SwiftLint..."
  vm_ssh 'eval "$(/opt/homebrew/bin/brew shellenv)" && brew install swiftlint 2>/dev/null || true'

  log_info "Accepting Xcode license..."
  vm_ssh 'sudo xcodebuild -license accept 2>/dev/null || true'

  log_info "Downloading iOS Simulator runtime (optional; may take 10+ min)..."
  vm_ssh 'xcodebuild -downloadPlatform iOS 2>&1 || true'

  log_info "Syncing project code..."
  vm_ssh "mkdir -p '${VM_PROJECT_DIR}'"
  vm_rsync_to "${REPO_ROOT}/" "${VM_PROJECT_DIR}/"

  log_info "Generating Xcode project..."
  vm_ssh "cd '${VM_PROJECT_DIR}' && eval \"\$(/opt/homebrew/bin/brew shellenv)\" && xcodegen generate 2>&1 || true"

  log_ok "Guest provisioning complete."
}
