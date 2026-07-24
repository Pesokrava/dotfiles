#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Packages managed by stow. Note: zsh is NOT included here — ~/.zshrc is
# configured manually per machine (it contains oh-my-zsh setup, machine-specific
# paths, and secrets loaded via ~/.env.llm). See zsh/.zshrc.example for a
# reference template.
PACKAGES=(nvim kitty tmux git herdr)

# Stowed with --no-folding so ~/.claude and ~/.config/opencode stay REAL dirs
# and only our leaf files get symlinked. Folding would turn the whole dir into
# one symlink, dragging live state (sessions, credentials, node_modules) into
# the repo. ponytail: --no-folding, revisit only if a tool needs a folded dir.
NOFOLD_PACKAGES=(claude opencode)

# ---------------------------------------------------------------------------
# 1. Install GNU Stow if missing
# ---------------------------------------------------------------------------
if ! command -v stow &>/dev/null; then
  echo "GNU Stow not found. Installing..."
  if command -v brew &>/dev/null; then
    brew install stow
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update && sudo apt-get install -y stow
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm stow
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y stow
  else
    echo "Error: Could not detect a package manager. Please install GNU Stow manually."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# 2. Back up any existing configs that would conflict with stow
# ---------------------------------------------------------------------------
# Whole dirs (not leaf files): stow errors "existing target is not owned by
# stow: .config/herdr" if the dir exists as a real tree — backing up only a
# leaf leaves the parent and stow still fails (Coder/dev images often precreate
# these).
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backup_needed=false

backup_if_real() {
  local target="$1"
  # Already a symlink → prior stow (or manual); leave it for restow/adopt.
  if [ -L "$target" ] || [ ! -e "$target" ]; then
    return 0
  fi
  backup_needed=true
  mkdir -p "$BACKUP_DIR"
  echo "Backing up $target -> $BACKUP_DIR/"
  mv "$target" "$BACKUP_DIR/"
}

for pkg in "${PACKAGES[@]}"; do
  case "$pkg" in
    nvim)  backup_if_real "$HOME/.config/nvim"  ;;
    kitty) backup_if_real "$HOME/.config/kitty" ;;
    tmux)  backup_if_real "$HOME/.config/tmux"  ;;
    herdr) backup_if_real "$HOME/.config/herdr" ;; # whole dir, not just config.toml
    git)   backup_if_real "$HOME/.gitconfig"    ;;
  esac
done

# Also back up ~/.tmux.conf if it exists (we now use ~/.config/tmux/tmux.conf)
backup_if_real "$HOME/.tmux.conf"

if [ "$backup_needed" = true ]; then
  echo "Existing configs backed up to: $BACKUP_DIR"
fi

# ---------------------------------------------------------------------------
# 3. Stow all packages
# ---------------------------------------------------------------------------
echo "Stowing packages: ${PACKAGES[*]} ${NOFOLD_PACKAGES[*]}"
cd "$DOTFILES_DIR"

# --adopt: if anything still blocks (race / unexpected path), pull it into the
# package tree and replace with a symlink. Dirty git clone is fine on ephemeral
# workspaces; local machines rarely hit this after the backup pass.
if ! stow -t "$HOME" "${PACKAGES[@]}"; then
  echo "stow conflict — retrying with --adopt"
  stow --adopt -t "$HOME" "${PACKAGES[@]}"
fi
if ! stow --no-folding -t "$HOME" "${NOFOLD_PACKAGES[@]}"; then
  echo "stow --no-folding conflict — retrying with --adopt"
  stow --adopt --no-folding -t "$HOME" "${NOFOLD_PACKAGES[@]}"
fi
echo ""
echo "Done! Symlinks created:"
for pkg in "${PACKAGES[@]}"; do
  case "$pkg" in
    nvim)  echo "  ~/.config/nvim  -> $DOTFILES_DIR/nvim/.config/nvim"  ;;
    kitty) echo "  ~/.config/kitty -> $DOTFILES_DIR/kitty/.config/kitty" ;;
    tmux)  echo "  ~/.config/tmux  -> $DOTFILES_DIR/tmux/.config/tmux"  ;;
    herdr) echo "  ~/.config/herdr/config.toml -> $DOTFILES_DIR/herdr/.config/herdr/config.toml" ;;
    git)   echo "  ~/.gitconfig    -> $DOTFILES_DIR/git/.gitconfig"     ;;
  esac
done
echo "  ~/.claude/{settings.json,commands,hooks,skills/linus-review,skills/review-fleet} -> $DOTFILES_DIR/claude/.claude/*"
echo "  ~/.config/opencode/{opencode.json,tui.json,command,skill,plugins} -> $DOTFILES_DIR/opencode/.config/opencode/*"
echo ""
echo "Note: ~/.zshrc is NOT managed by stow. Configure it manually per machine."
echo "      See $DOTFILES_DIR/zsh/.zshrc.example for a reference template."

# ---------------------------------------------------------------------------
# 4. Append vi mode keybinding to ~/.zshrc if not already present
# ---------------------------------------------------------------------------
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ] && grep -qF 'bindkey -v' "$ZSHRC"; then
  echo "bindkey -v already present in ~/.zshrc, skipping."
else
  cat >> "$ZSHRC" << 'EOF'

# Vi mode
bindkey -v
EOF
  echo "Appended 'bindkey -v' to ~/.zshrc"
fi

if [ -f "$ZSHRC" ] && grep -qF 'alias vi=' "$ZSHRC"; then
  echo "alias vi already present in ~/.zshrc, skipping."
else
  cat >> "$ZSHRC" << 'EOF'

# Aliases
alias vi="nvim"
EOF
  echo "Appended 'alias vi=\"nvim\"' to ~/.zshrc"
fi

if [ -f "$ZSHRC" ] && grep -qF 'plugins=' "$ZSHRC"; then
  sed -i.bak 's/^plugins=(.*)/plugins=(brew git docker golang rust)/' "$ZSHRC"
  echo "Replaced plugins in ~/.zshrc"
else
  cat >> "$ZSHRC" << 'EOF'

# Oh-my-zsh plugins
plugins=(brew git docker golang rust)
EOF
  echo "Appended plugins to ~/.zshrc"
fi

if [ -f "$ZSHRC" ] && grep -qF 'EDITOR=' "$ZSHRC"; then
  echo "EDITOR already present in ~/.zshrc, skipping."
else
  cat >> "$ZSHRC" << 'EOF'

# Default editor
export EDITOR="nvim"
EOF
  echo "Appended 'export EDITOR=\"nvim\"' to ~/.zshrc"
fi

# ---------------------------------------------------------------------------
# Bash customizations (append; idempotent). For shells whose login shell is
# bash — e.g. the Coder devcontainer default — mirror the key zsh tweaks.
# ---------------------------------------------------------------------------
BASHRC="$HOME/.bashrc"
if grep -qF '# dotfiles: bash customizations' "$BASHRC" 2>/dev/null; then
  echo "bash customizations already present in ~/.bashrc, skipping."
else
  cat >> "$BASHRC" << 'EOF'

# dotfiles: bash customizations
export LANG=C.UTF-8
set -o vi
alias vi="nvim"
# Prompt: show just the current path.
PS1='\[\e[1;36m\]\w\[\e[0m\] \$ '
EOF
  echo "Appended bash customizations to ~/.bashrc"
fi

