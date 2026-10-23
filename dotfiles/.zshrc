# Interactive conveniences only. Builds must not depend on this file.
# Make Homebrew's Pure prompt available to macOS's bundled zsh.
fpath+=(/opt/homebrew/share/zsh/site-functions)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

: "${HISTFILE:=$HOME/.zsh_history}"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY
unsetopt NOMATCH

alias ..='cd ..'
alias ...='cd ../..'
alias reload='exec zsh'
alias v='vim'

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

autoload -Uz promptinit
promptinit
prompt pure

if [[ -t 0 ]]; then
  stty start undef
  stty stop undef
fi

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Keep syntax highlighting last so it wraps the final shell widgets.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
