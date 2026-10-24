#!/bin/bash
# Installs Claude Code and Codex from their vendor scripts into ~/.local/bin.
# Run directly or via bootstrap.sh; both are safe to repeat.
set -euo pipefail

log() { printf '[headless] %s\n' "$*"; }
die() {
  printf '[headless] ERROR: %s\n' "$*" >&2
  exit 1
}

# Downloads from the first URL that responds, then runs that script.
run_installer() {
  local name="$1" interpreter="$2" url
  shift 2
  log "Installing $name."
  (
    installer="$(mktemp -t headless-installer)"
    trap 'rm -f "$installer"' EXIT
    for url in "$@"; do
      # Download fully before executing so a truncated transfer cannot run half a script.
      if curl --fail --silent --show-error --location --retry 2 "$url" -o "$installer"; then
        # Keep ~/.local/bin on PATH so the installer skips editing shell profiles.
        PATH="$HOME/.local/bin:$PATH"
        # Never prompt or launch the agent in a provisioning run.
        export CODEX_NON_INTERACTIVE=1
        # The subshell's || handler disables errexit, so check the installer explicitly.
        "$interpreter" "$installer" || exit $?
        exit 0
      fi
      log "No installer at $url; trying the next source."
    done
    die "Could not download the $name installer."
  ) || die "$name installer failed."
}

# Both agents self-update, so an existing binary is left alone. This also makes
# a rerun after a partial failure cheap.
install_agent() {
  local name="$1" tool="$2" interpreter="$3"
  shift 3
  if [ -x "$HOME/.local/bin/$tool" ]; then
    log "$name is already installed; skipping."
    return
  fi
  run_installer "$name" "$interpreter" "$@"
  [ -x "$HOME/.local/bin/$tool" ] || die "$tool is missing from ~/.local/bin after installation."
}

main() {
  if HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask claude-code >/dev/null 2>&1 ||
    HOMEBREW_NO_AUTO_UPDATE=1 brew list --cask codex >/dev/null 2>&1; then
    die 'Remove the old Homebrew casks first: brew uninstall --cask claude-code codex'
  fi
  install_agent 'Claude Code' claude bash https://claude.ai/install.sh
  install_agent 'Codex' codex sh \
    https://releases.openai.com/codex/install.sh \
    https://chatgpt.com/codex/install.sh
}

main "$@"
