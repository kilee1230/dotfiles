# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/bashrc.pre.bash"
PATH=~/.console-ninja/.bin:$PATH

. "$HOME/.cargo/env"


[[ -f "$HOME/fig-export/dotfiles/dotfile.bash" ]] && source "$HOME/fig-export/dotfiles/dotfile.bash"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/bashrc.post.bash" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/bashrc.post.bash"

if [[ -n "$CURSOR_AGENT" ]]; then
  PS1='\u@\h \W \$ '
fi