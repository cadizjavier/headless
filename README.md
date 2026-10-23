# headless

Provision an Apple Silicon Mac mini: Homebrew tools, symlinked dotfiles, coding
agents, and a health check. Idempotent and safe to rerun.

## Setup

```sh
xcode-select --install   # first; wait for it to finish
```

```sh
git clone https://github.com/cadizjavier/headless.git ~/.headless
cd ~/.headless
./bootstrap.sh
./bootstrap.sh doctor
```

## Commands

```sh
./bootstrap.sh         # install tools and link config
./bootstrap.sh update  # upgrade tools and link config
./bootstrap.sh doctor  # check tools, links, and shell config
```

## Sign in

```sh
gh auth login
claude auth login
codex login
```

## Manual

- Xcode and simulator runtimes (`xcodes`)
- Ghostty (config is linked), T3 Code, and other GUI apps
- SSH keys, Screen Sharing, power settings
- Apple ID and code signing
