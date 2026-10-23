#!/bin/bash
set -euo pipefail

# Resolve symlinks so the script also works when linked onto PATH.
_self="$(command -v -- "$0" 2>/dev/null || true)"
[ -n "$_self" ] || _self="$0"
while [ -L "$_self" ]; do
  _target="$(readlink "$_self")"
  case "$_target" in
    /*) _self="$_target" ;;
    *) _self="$(dirname -- "$_self")/$_target" ;;
  esac
done
ROOT="$(cd -- "$(dirname -- "$_self")" && pwd -P)"
DOTFILES=(.zshrc .zshenv .gitconfig .config/git/ignore)

log() { printf '[headless] %s\n' "$*"; }
die() {
  printf '[headless] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing $1. Run ./bootstrap.sh first."
}

require_macos() {
  [ "$(uname -s)" = Darwin ] || die 'This setup supports macOS only.'
  [ "$(uname -m)" = arm64 ] || die 'Run this setup natively on Apple Silicon (not through Rosetta).'
}

require_user() {
  [ "$(id -u)" -ne 0 ] || die 'Run as your normal build user, not root. Individual tools may request sudo.'
}

require_clt() {
  xcode-select -p >/dev/null 2>&1 ||
    die 'Install Command Line Tools first: xcode-select --install. Without a GUI session, install the CLT package from Apple or enable Screen Sharing first.'
}

init_brew_path() {
  if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  fi
}

install_brew() {
  if command -v brew >/dev/null 2>&1; then
    log 'Homebrew is already installed.'
    return
  fi
  log 'Downloading the official Homebrew installer; it may prompt for sudo.'
  (
    installer="$(mktemp -t headless-homebrew)"
    trap 'rm -f "$installer"' EXIT
    curl --fail --silent --show-error --location \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer" ||
      die 'Could not download the Homebrew installer.'
    /bin/bash "$installer"
  )
  init_brew_path
  require_command brew
}

apply_dotfiles() {
  local file
  log 'Linking configuration into the home directory; existing files are replaced.'
  for file in "${DOTFILES[@]}"; do
    [ -f "$ROOT/dotfiles/$file" ] || die "Missing dotfiles/$file; restore it before continuing."
    mkdir -p "$HOME/$(dirname "$file")"
    ln -sfn "$ROOT/dotfiles/$file" "$HOME/$file"
  done
}

install_tools() {
  local mode="$1"
  require_command brew
  if [ "$mode" = update ]; then
    log 'Updating Homebrew metadata and Brewfile entries. Xcode and runtimes stay unchanged.'
    brew update
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle upgrade --file="$ROOT/install/Brewfile"
  else
    log 'Installing declared tools without requesting upgrades.'
    HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file="$ROOT/install/Brewfile"
  fi
  "$ROOT/install/agents.sh"
  apply_dotfiles
  log 'Setup complete. Run ./bootstrap.sh doctor. Manage Xcode and runtimes manually with xcodes.'
}

doctor() {
  local failures=0 link_failures=0 file tool

  log "Host: $(hostname -s)"
  log "macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  log "Architecture: $(uname -m)"
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew: $(HOMEBREW_NO_AUTO_UPDATE=1 brew --version | head -n 1)"
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$ROOT/install/Brewfile" >/dev/null 2>&1; then
      log 'OK: Brewfile tools'
    else
      log 'MISSING: Brewfile tools; run ./bootstrap.sh.'
      HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file="$ROOT/install/Brewfile" 2>&1 |
        sed 's/^/[headless]   /' || true
      failures=$((failures + 1))
    fi
  else
    log 'MISSING: Homebrew; run ./bootstrap.sh.'
    failures=$((failures + 1))
  fi

  # Agent CLIs come from their vendor installers, so Brewfile cannot account for them.
  for tool in claude codex; do
    if command -v "$tool" >/dev/null 2>&1 || [ -x "$HOME/.local/bin/$tool" ]; then
      log "OK: $tool"
    else
      log "MISSING: $tool; run ./bootstrap.sh."
      failures=$((failures + 1))
    fi
  done

  for file in "${DOTFILES[@]}"; do
    if [ ! -e "$HOME/$file" ] || [ "$(readlink "$HOME/$file")" != "$ROOT/dotfiles/$file" ]; then
      log "DRIFT: ~/$file does not link into this checkout; run ./bootstrap.sh."
      link_failures=$((link_failures + 1))
    fi
  done
  if [ "$link_failures" -eq 0 ]; then
    log 'OK: configuration links'
  else
    failures=$((failures + link_failures))
  fi

  # .zshenv is read by every zsh invocation, so a break there affects non-interactive SSH too.
  # zsh exits 0 despite startup parse errors, so syntax-check the files explicitly.
  if zsh -n "$HOME/.zshenv" && zsh -n "$HOME/.zshrc" && zsh -lic 'exit 0' >/dev/null 2>&1; then
    log 'OK: zsh configuration loads'
  else
    log 'BROKEN: zsh configuration; shells may fail to start.'
    failures=$((failures + 1))
  fi

  log 'Manage Xcode/runtimes manually. Verify SSH access, reboot recovery, builds, and signing separately.'
  [ "$failures" -eq 0 ] || die "$failures readiness check(s) failed."
  log 'Base setup checks passed.'
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [COMMAND]

  bootstrap  Install Homebrew if missing, install tools, link configuration (default)
  update     Upgrade tools and link configuration
  doctor     Check tools, links, and shell configuration
  help       Show this help

Xcode and simulator runtimes are managed manually using the installed xcodes CLI.
EOF
}

main() {
  local command="${1:-bootstrap}"
  [ "$#" -le 1 ] || die 'Commands do not accept extra arguments.'
  case "$command" in
    help | --help | -h)
      usage
      return
      ;;
    bootstrap | update | doctor) ;;
    *)
      usage >&2
      die "Unknown command: $command"
      ;;
  esac

  require_macos
  init_brew_path
  case "$command" in
    bootstrap)
      require_user
      require_clt
      install_brew
      install_tools install
      ;;
    update)
      require_user
      install_tools update
      ;;
    doctor)
      doctor
      ;;
  esac
}

main "$@"
