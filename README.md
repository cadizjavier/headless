# headless

Provision an Apple Silicon Mac mini: Homebrew tools, symlinked dotfiles, coding
agents, and a health check. Idempotent and safe to rerun.

## Steps

1. **Install Ghostty** — [ghostty.org](https://ghostty.org)

2. **Install Command Line Tools** (skip if Xcode is installed)

   ```sh
   xcode-select --install
   ```

3. **Set up an SSH key**

   ```sh
   mkdir -p ~/.ssh
   ssh-keygen -t ed25519 -C "you@example.com"
   cat >> ~/.ssh/config <<'EOF'
   Host github.com
     AddKeysToAgent yes
     UseKeychain yes
     IdentityFile ~/.ssh/id_ed25519
   EOF
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519
   cat ~/.ssh/id_ed25519.pub   # add at github.com/settings/keys
   ssh -T git@github.com
   ```

4. **Clone the repo**

   ```sh
   git clone git@github.com:cadizjavier/headless.git ~/.headless
   ```

5. **Run bootstrap**

   ```sh
   cd ~/.headless
   ./bootstrap.sh
   ```

6. **Check the setup**

   ```sh
   ./bootstrap.sh doctor
   ```

7. **Sign in to the CLIs**

   ```sh
   gh auth login
   claude auth login
   codex login
   ```

8. **By hand** — Xcode and simulator runtimes, T3 Code, Screen Sharing, power
   settings, Apple ID, code signing.
