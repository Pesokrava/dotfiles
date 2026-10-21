# Coder workspace ~/.zshrc. The org config (/etc/zsh/zshrc) runs first and
# sets history, completion, the prompt, fzf, and sources
# ~/.zsh/zsh-autosuggestions when present; this file only adds to it.

export EDITOR=nvim
alias vi=nvim

bindkey -v

alias glogin='gcloud auth login && gcloud auth application-default login'

[[ -d ~/.zsh/zsh-autosuggestions ]] ||
  git clone -q --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions 2>/dev/null &!
