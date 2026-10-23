# headless

Provision an Apple Silicon Mac mini for development: Homebrew tools, symlinked
dotfiles, coding agents, and a readiness check. Idempotent and safe to rerun.

## Setup

Install Command Line Tools and wait for the installer to finish. Skip this if
Xcode is already installed.

```sh
xcode-select --install
```

Then clone and run:

```sh
git clone YOUR_REPOSITORY_URL ~/.headless
cd ~/.headless
./bootstrap.sh
./bootstrap.sh doctor
```

Bootstrap replaces files at the managed dotfile paths, so edit `dotfiles/`
rather than your home directory.

## Commands

```sh
./bootstrap.sh         # Install missing tools and link configuration
./bootstrap.sh update  # Upgrade tools and link configuration
./bootstrap.sh doctor  # Check tools, links, shell config, and disk space
```

After pulling changes: `git pull --ff-only && ./bootstrap.sh update`.

`doctor` exits non-zero on problems and requires 60 GiB free by default; override
with `MIN_FREE_GB=30 ./bootstrap.sh doctor`.

Tools are declared in `install/Brewfile`; Claude Code and Codex are installed by
their vendor scripts via `install/agents.sh`. Open a new shell after changes.

Sign in with `gh auth login`, `claude auth login`, and `codex login`.

Xcode, simulator runtimes (`xcodes`), T3 Code, SSH, Screen Sharing, power
settings, and code signing remain manual.
