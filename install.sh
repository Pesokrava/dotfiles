#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Packages managed by stow. Note: zsh is NOT included here — ~/.zshrc is
# configured manually per machine (it contains oh-my-zsh setup, machine-specific
# paths, and secrets loaded via ~/.env.llm). See zsh/.zshrc.example for a
# reference template.
PACKAGES=(nvim kitty tmux git)

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
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
backup_needed=false

for pkg in "${PACKAGES[@]}"; do
  case "$pkg" in
    nvim)  target="$HOME/.config/nvim"  ;;
    kitty) target="$HOME/.config/kitty" ;;
    tmux)  target="$HOME/.config/tmux"  ;;
    git)   target="$HOME/.gitconfig"    ;;
    *)     continue ;;
  esac

  # Skip if it's already a symlink (probably from a previous stow run)
  if [ -L "$target" ]; then
    continue
  fi

  if [ -e "$target" ]; then
    backup_needed=true
    mkdir -p "$BACKUP_DIR"
    echo "Backing up $target -> $BACKUP_DIR/"
    mv "$target" "$BACKUP_DIR/"
  fi
done

# Also back up ~/.tmux.conf if it exists (we now use ~/.config/tmux/tmux.conf)
if [ -e "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
  backup_needed=true
  mkdir -p "$BACKUP_DIR"
  echo "Backing up ~/.tmux.conf -> $BACKUP_DIR/"
  mv "$HOME/.tmux.conf" "$BACKUP_DIR/"
fi

if [ "$backup_needed" = true ]; then
  echo "Existing configs backed up to: $BACKUP_DIR"
fi

# ---------------------------------------------------------------------------
# 3. Stow all packages
# ---------------------------------------------------------------------------
echo "Stowing packages: ${PACKAGES[*]}"
cd "$DOTFILES_DIR"

stow -t "$HOME" "${PACKAGES[@]}"

echo ""
echo "Done! Symlinks created:"
for pkg in "${PACKAGES[@]}"; do
  case "$pkg" in
    nvim)  echo "  ~/.config/nvim  -> $DOTFILES_DIR/nvim/.config/nvim"  ;;
    kitty) echo "  ~/.config/kitty -> $DOTFILES_DIR/kitty/.config/kitty" ;;
    tmux)  echo "  ~/.config/tmux  -> $DOTFILES_DIR/tmux/.config/tmux"  ;;
    git)   echo "  ~/.gitconfig    -> $DOTFILES_DIR/git/.gitconfig"     ;;
  esac
done
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

