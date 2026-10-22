#!/usr/bin/env bash
# Create or reuse scripts/venv for the translation scripts.
#
# Idempotent: exits 0 when deep-translator is importable from scripts/venv.
#
# Worktrees do not copy untracked files from the primary clone. When run from a
# linked worktree, this script symlinks to the primary clone's venv when that
# environment already exists; otherwise it creates a local venv here.
#
# Usage:
#   scripts/bootstrap_venv.sh [--force] [--no-link]
#
# Options:
#   --force    Recreate the venv (or re-link after removing a broken link).
#   --no-link  Always create scripts/venv in this checkout (no primary symlink).
#
# See scripts/requirements.txt. Adapted from CarManager's bootstrap for #582.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT/scripts/venv"
REQ="$ROOT/scripts/requirements.txt"
FORCE=0
NO_LINK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --no-link) NO_LINK=1 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

venv_python() {
  [[ -x "$VENV/bin/python3" ]] || return 1
  echo "$VENV/bin/python3"
}

venv_ok() {
  local py
  py="$(venv_python)" || return 1
  "$py" -c "import deep_translator" 2>/dev/null
}

primary_repo_root() {
  local common
  common="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null)" || return 1
  [[ "$common" != /* ]] && common="$ROOT/$common"
  dirname "$common"
}

link_primary_venv() {
  local primary primary_venv
  primary="$(primary_repo_root)" || return 1
  [[ "$primary" != "$ROOT" ]] || return 1
  primary_venv="$primary/scripts/venv"
  [[ -x "$primary_venv/bin/python3" ]] || return 1
  "$primary_venv/bin/python3" -c "import deep_translator" 2>/dev/null || return 1
  mkdir -p "$ROOT/scripts"
  rm -rf "$VENV"
  ln -s "$primary_venv" "$VENV"
  echo "Linked scripts/venv -> $primary_venv"
}

create_venv() {
  command -v python3 >/dev/null || {
    echo "python3 is required to create scripts/venv" >&2
    exit 1
  }
  [[ -f "$REQ" ]] || {
    echo "Missing $REQ" >&2
    exit 1
  }
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q --upgrade pip
  "$VENV/bin/pip" install -q -r "$REQ"
  echo "Created scripts/venv and installed scripts/requirements.txt"
}

if [[ "$FORCE" -eq 1 ]]; then
  rm -rf "$VENV"
fi

if venv_ok; then
  echo "scripts/venv ok (deep-translator available)"
  exit 0
fi

if [[ "$NO_LINK" -eq 0 ]] && link_primary_venv && venv_ok; then
  exit 0
fi

if [[ -L "$VENV" ]]; then
  echo "scripts/venv symlink exists but deep-translator is not importable" >&2
  exit 1
fi

create_venv
venv_ok || {
  echo "scripts/venv setup failed: deep-translator not importable" >&2
  exit 1
}
