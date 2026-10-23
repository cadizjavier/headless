# Keep noninteractive SSH shells quiet and give tools explicit search paths.
typeset -U path PATH
path=(
  "$HOME/.local/share/mise/shims"
  "$HOME/.local/bin"
  "$HOME/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
export PATH
export VISUAL=vim
export EDITOR="$VISUAL"
export LANG=en_US.UTF-8
export FZF_DEFAULT_OPTS="--layout=reverse --border=rounded --height=40% --info=inline"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
