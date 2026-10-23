#!/bin/bash
# Installs Claude Code and Codex from their vendor scripts into ~/.local/bin.
# Run directly or via bootstrap.sh; both are safe to repeat.
set -euo pipefail

log() { printf '[headless] %s\n' "$*"; }
die() {
  printf '[headless] ERROR: %s\n' "$*" >&2
  exit 1
}

run_installer() {
  local name="$1" url="$2" interpreter="$3"
  log "Installing or updating $name with the vendor script."
  (
    installer="$(mktemp -t headless-installer)"
    trap 'rm -f "$installer"' EXIT
    # Download fully before executing so a truncated transfer cannot run half a script.
    curl --fail --silent --show-error --location --retry 2 "$url" -o "$installer"
    # Keep ~/.local/bin on PATH so the installer skips editing shell profiles.
    PATH="$HOME/.local/bin:$PATH"
    # Never prompt or launch the agent in a provisioning run.
    export CODEX_NON_INTERACTIVE=1
    "$interpreter" "$installer"
  ) || die "$name installer failed."
}

main() {
  local tool
  if HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask claude-code >/dev/null 2>&1 ||
    HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask codex >/dev/null 2>&1; then
    die 'Remove the old Homebrew casks first: brew uninstall --cask claude-code codex'
  fi
  run_installer 'Claude Code' 'https://claude.ai/install.sh' bash
  run_installer 'Codex' 'https://chatgpt.com/codex/install.sh' sh
  for tool in claude codex; do
    [ -x "$HOME/.local/bin/$tool" ] || die "$tool is missing from ~/.local/bin after installation."
  done
}

main "$@"
