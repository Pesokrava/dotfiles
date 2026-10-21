# Coder workspace ~/.zshrc. The org config (/etc/zsh/zshrc) runs first and
# sets history, completion, the prompt, fzf, and sources
# ~/.zsh/zsh-autosuggestions when present; this file only adds to it.

export EDITOR=nvim
alias vi=nvim

bindkey -v

# oh-my-zsh robbyrussell prompt, without oh-my-zsh: the theme's own lines plus
# the one helper it calls.
autoload -U colors && colors
setopt prompt_subst
git_prompt_info() {
  local ref
  ref=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return 0
  local state=$ZSH_THEME_GIT_PROMPT_CLEAN
  [[ -n $(git status --porcelain --ignore-submodules=dirty 2>/dev/null | tail -n 1) ]] && state=$ZSH_THEME_GIT_PROMPT_DIRTY
  print -rn -- "$ZSH_THEME_GIT_PROMPT_PREFIX$ref$state$ZSH_THEME_GIT_PROMPT_SUFFIX"
}
PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' $(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

alias glogin='gcloud auth login && gcloud auth application-default login'

[[ -d ~/.zsh/zsh-autosuggestions ]] ||
  git clone -q --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions 2>/dev/null &!
