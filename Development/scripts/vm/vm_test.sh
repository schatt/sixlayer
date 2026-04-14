#!/usr/bin/env bash
# Run build, test, and optional lint inside the SixLayer Tart VM (keeps disruptive
# macOS UI tests off the host). Adapted from CarManager.
#
# Usage (from repo root):
#   ./Development/scripts/vm/vm_test.sh sync
#   ./Development/scripts/vm/vm_test.sh xcodegen
#   ./Development/scripts/vm/vm_test.sh build [macos|ios|all]
#   ./Development/scripts/vm/vm_test.sh test [scheme]   # default: SLF-macOS-UITests
#   ./Development/scripts/vm/vm_test.sh lint
#   ./Development/scripts/vm/vm_test.sh test-ui-macos    # shortcut → SLF-macOS-UITests
#   ./Development/scripts/vm/vm_test.sh test-ui-ios      # shortcut → SLF-iOS-UITests
#   ./Development/scripts/vm/vm_test.sh run-testapp      # build + open macOS TestApp
#   ./Development/scripts/vm/vm_test.sh all              # sync + xcodegen + default test
#   ./Development/scripts/vm/vm_test.sh results
#   ./Development/scripts/vm/vm_test.sh clean
#   ./Development/scripts/vm/vm_test.sh shell [cmd]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=vm_config.sh
source "${SCRIPT_DIR}/vm_config.sh"

require_macos
require_tart
require_sshpass

trap 'vm_ssh_close_master' EXIT

BREW_ENV='eval "$(/opt/homebrew/bin/brew shellenv)"'

ensure_vm_running() {
  if ! vm_is_running; then
    log_info "VM '${VM_NAME}' is not running. Starting it..."
    tart run --no-graphics "${VM_NAME}" &
    wait_for_ssh 90
  fi
}

cmd_sync() {
  ensure_vm_running
  log_info "Syncing project code to VM..."
  vm_ssh "mkdir -p '${VM_PROJECT_DIR}'"
  vm_rsync_to "${REPO_ROOT}/" "${VM_PROJECT_DIR}/"
  log_ok "Code synced to ${VM_PROJECT_DIR}"
}

cmd_xcodegen() {
  ensure_vm_running
  log_info "Regenerating Xcode project in VM..."
  vm_ssh "test -x /opt/homebrew/bin/xcodegen || (${BREW_ENV} && brew install xcodegen); cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && /opt/homebrew/bin/xcodegen generate"
  log_ok "Xcode project regenerated."
}

cmd_build() {
  local target="${1:-macos}"
  ensure_vm_running

  local scheme destination
  case "$target" in
    macos|mac)
      scheme="${SCHEME_MACOS_BUILD}"
      destination="platform=macOS"
      ;;
    ios)
      scheme="${SCHEME_IOS_BUILD}"
      destination="platform=iOS Simulator,name=iPhone 16"
      ;;
    all)
      cmd_build macos
      cmd_build ios
      return
      ;;
    *)
      log_error "Unknown build target: $target (use macos, ios, or all)"
      exit 1
      ;;
  esac

  log_info "Building ${target} (scheme: ${scheme})..."
  local xcode_extra=""
  if [[ "${SIXLAYER_VM_ADHOC_SIGN:-0}" == "1" ]]; then
    xcode_extra='CODE_SIGN_IDENTITY="-" '
    log_info "Using ad-hoc signing (SIXLAYER_VM_ADHOC_SIGN=1)."
  fi
  vm_ssh "security unlock-keychain -p '${VM_PASS}' \"\$HOME/Library/Keychains/login.keychain-db\" 2>&1 || security unlock-keychain -p '${VM_PASS}' login 2>&1 || true; security set-keychain-settings -t 3600 -u \"\$HOME/Library/Keychains/login.keychain-db\" 2>/dev/null || security set-keychain-settings -t 3600 -u login 2>/dev/null || true; cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && bash -c 'set -o pipefail; xcodebuild \
    -project ${XCODE_PROJECT} \
    -scheme '\''${scheme}'\'' \
    -destination '\''${destination}'\'' \
    -configuration Debug \
    -allowProvisioningUpdates \
    ${xcode_extra}build 2>&1 | tail -40'"
  log_ok "Build (${target}) succeeded."
}

test_destination_for_scheme() {
  local scheme="$1"
  if [[ "$scheme" == *iOS* ]]; then
    printf '%s' "platform=iOS Simulator,name=iPhone 16"
  else
    printf '%s' "platform=macOS"
  fi
}

cmd_test() {
  local scheme="${1:-${DEFAULT_TEST_SCHEME}}"
  ensure_vm_running

  local destination
  destination="$(test_destination_for_scheme "$scheme")"

  local safe_name="${scheme//[^A-Za-z0-9._-]/_}"
  local result_name="${safe_name}-$(date +%Y%m%d-%H%M%S)"

  log_info "Running tests (scheme: ${scheme}, destination: ${destination})..."
  local xcode_extra=""
  if [[ "${SIXLAYER_VM_ADHOC_SIGN:-0}" == "1" ]]; then
    xcode_extra='CODE_SIGN_IDENTITY="-" '
  fi
  set +e
  vm_ssh "security unlock-keychain -p '${VM_PASS}' \"\$HOME/Library/Keychains/login.keychain-db\" 2>&1 || security unlock-keychain -p '${VM_PASS}' login 2>&1 || true; security set-keychain-settings -t 3600 -u \"\$HOME/Library/Keychains/login.keychain-db\" 2>/dev/null || security set-keychain-settings -t 3600 -u login 2>/dev/null || true; cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && mkdir -p build && bash -c 'set -o pipefail; xcodebuild \
    -project ${XCODE_PROJECT} \
    -scheme '\''${scheme}'\'' \
    -destination '\''${destination}'\'' \
    -configuration Debug \
    -resultBundlePath '\''build/${result_name}.xcresult'\'' \
    -allowProvisioningUpdates \
    ${xcode_extra}test 2>&1'"
  local test_exit_code=$?
  set -e

  log_info "Test run finished (exit code: ${test_exit_code})"
  if [[ $test_exit_code -eq 0 ]]; then
    log_ok "Tests (${scheme}) completed. Result bundle: build/${result_name}.xcresult"
  else
    log_warn "Tests (${scheme}) failed (exit ${test_exit_code}). Result bundle: build/${result_name}.xcresult"
  fi

  local dest="${REPO_ROOT}/artifacts"
  mkdir -p "$dest"
  log_info "Pulling result bundle to ${dest}/..."
  if vm_rsync_from "${VM_PROJECT_DIR}/build/${result_name}.xcresult" "${dest}/" 2>/dev/null; then
    log_ok "Result bundle saved to ${dest}/${result_name}.xcresult"
  else
    log_warn "Could not pull result bundle (run '$0 results' to retry)."
  fi

  return $test_exit_code
}

cmd_lint() {
  ensure_vm_running
  log_info "Running SwiftLint in VM (if config present)..."
  vm_ssh "cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && \
    if compgen -G '.swiftlint*.yml' > /dev/null || compgen -G '.swiftlint*.yaml' > /dev/null; then \
      swiftlint lint --strict 2>&1 | tail -50; \
    else \
      echo 'No .swiftlint.yml / .swiftlint.yaml in repo root; skipping.'; \
    fi"
  log_ok "Lint step finished."
}

cmd_run_testapp() {
  ensure_vm_running
  log_info "Building macOS TestApp (${SCHEME_MACOS_TESTAPP})..."
  local xcode_extra=""
  if [[ "${SIXLAYER_VM_ADHOC_SIGN:-0}" == "1" ]]; then
    xcode_extra='CODE_SIGN_IDENTITY="-" '
  fi
  vm_ssh "security unlock-keychain -p '${VM_PASS}' \"\$HOME/Library/Keychains/login.keychain-db\" 2>&1 || security unlock-keychain -p '${VM_PASS}' login 2>&1 || true; security set-keychain-settings -t 3600 -u \"\$HOME/Library/Keychains/login.keychain-db\" 2>/dev/null || security set-keychain-settings -t 3600 -u login 2>/dev/null || true; cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && bash -c 'set -o pipefail; xcodebuild \
    -project ${XCODE_PROJECT} \
    -scheme '\''${SCHEME_MACOS_TESTAPP}'\'' \
    -destination '\''platform=macOS'\'' \
    -configuration Debug \
    -allowProvisioningUpdates \
    ${xcode_extra}build 2>&1 | tail -20'"

  vm_ssh "cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && \
    PRODUCTS=\"\$(xcodebuild -project ${XCODE_PROJECT} -scheme '${SCHEME_MACOS_TESTAPP}' -destination 'platform=macOS' -configuration Debug -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | head -1 | sed 's/.*=[[:space:]]*//')\" && \
    APP=\"\$(ls -d \"\${PRODUCTS}\"/*.app 2>/dev/null | head -1)\" && \
    if [[ -n \"\${APP}\" ]]; then open \"\${APP}\"; else echo 'Could not find .app in BUILT_PRODUCTS_DIR'; fi"
  log_ok "TestApp launch attempted."
}

cmd_results() {
  ensure_vm_running
  local dest="${REPO_ROOT}/artifacts"
  mkdir -p "$dest"
  log_info "Pulling test results from VM to ${dest}/..."
  vm_rsync_from "${VM_PROJECT_DIR}/build/*.xcresult" "${dest}/" 2>/dev/null || \
    log_warn "No .xcresult bundles found in VM build directory."
  log_ok "Results pulled to ${dest}/"
}

cmd_clean() {
  ensure_vm_running
  log_info "Cleaning build artifacts in VM..."
  vm_ssh "cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && xcodebuild -project ${XCODE_PROJECT} -scheme '${SCHEME_MACOS_BUILD}' -configuration Debug clean 2>&1 | tail -8"
  vm_ssh "cd '${VM_PROJECT_DIR}' && rm -rf build/*.xcresult 2>/dev/null; mkdir -p build"
  log_ok "Clean complete."
}

cmd_shell() {
  ensure_vm_running
  if [[ $# -gt 0 ]]; then
    vm_ssh "cd '${VM_PROJECT_DIR}' && ${BREW_ENV} && $*"
  else
    log_info "Opening interactive shell in VM..."
    vm_ssh_open_master
    local ip
    ip="$(get_vm_ip)"
    if [[ -S "${VM_SSH_CTRL_SOCK}" ]]; then
      ssh -S "${VM_SSH_CTRL_SOCK}" "${SSH_OPTS[@]}" -t "${VM_USER}@${ip}"
    else
      sshpass -p "${VM_PASS}" ssh "${SSH_OPTS[@]}" -t "${VM_USER}@${ip}"
    fi
  fi
}

cmd_all() {
  cmd_sync
  cmd_xcodegen
  cmd_test "${DEFAULT_TEST_SCHEME}"
  log_ok "All steps completed."
}

usage() {
  cat <<EOF
Usage: $0 <command> [args...]

Commands:
  sync              Rsync repo host → VM (${VM_PROJECT_DIR})
  xcodegen          xcodegen generate in VM
  build [target]    macos | ios | all (default: macos)
  test [scheme]     xcodebuild test (default: ${DEFAULT_TEST_SCHEME})
  test-ui-macos     Same as: test SLF-macOS-UITests
  test-ui-ios       Same as: test SLF-iOS-UITests
  lint              swiftlint --strict if .swiftlint* exists
  run-testapp       Build SLF-macOS-TestApp and open .app
  all               sync + xcodegen + test (default scheme)
  results           Pull build/*.xcresult → ./artifacts
  clean             xcodebuild clean + remove .xcresult in VM
  shell [cmd]       Remote shell or one command

Environment:
  SIXLAYER_VM_DEFAULT_TEST_SCHEME Override default test scheme
  SIXLAYER_VM_ADHOC_SIGN=1          Ad-hoc codesign in VM

Common schemes:
  SLF-macOS-UITests macOS XCUITest (TestApp)
  SLF-iOS-UITests         iOS XCUITest (Simulator)
  SLF-macOS-ViewInspectorTests / SLF-iOS-ViewInspectorTests
  SLF-macOS-UnitTests / SLF-iOS-UnitTests
EOF
}

case "${1:-}" in
  sync)      shift; cmd_sync "$@" ;;
  xcodegen)  shift; cmd_xcodegen "$@" ;;
  build)     shift; cmd_build "$@" ;;
  test)      shift; cmd_test "$@"; exit $? ;;
  test-ui-macos) shift; cmd_test "SLF-macOS-UITests"; exit $? ;;
  test-ui-ios)   shift; cmd_test "SLF-iOS-UITests"; exit $? ;;
  lint)      shift; cmd_lint "$@" ;;
  run-testapp) shift; cmd_run_testapp "$@" ;;
  all)       shift; cmd_all "$@" ;;
  results)   shift; cmd_results "$@" ;;
  clean)     shift; cmd_clean "$@" ;;
  shell)     shift; cmd_shell "$@" ;;
  -h|--help) usage ;;
  *)
    if [[ -n "${1:-}" ]]; then
      log_error "Unknown command: $1"
    fi
    usage
    exit 1
    ;;
esac
