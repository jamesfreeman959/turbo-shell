#!/usr/bin/env bash
# bootstrap_macos.sh — macOS terminal environment setup
# Run from the repo directory: bash bootstrap.sh
#
# What this does:
#   1. Installs Homebrew packages and casks
#   2. Sets up oh-my-tmux + TPM
#   3. Installs LazyVim (Neovim config framework)
#   4. Deploys all config files (with backups)
#   5. Configures git to use delta (diffs) + difftastic (semantic diffs)
#   6. Appends shell additions to ~/.zshrc

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_DIR/configs"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}▶${NC} $1"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $1"; }
info()   { echo -e "${BLUE}ℹ${NC}  $1"; }
header() { echo -e "\n${BOLD}── $1 ──${NC}"; }

backup_if_exists() {
  if [[ -e "$1" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$1" "$BACKUP_DIR/"
    warn "Backed up: $1 → $BACKUP_DIR/"
  fi
}

# ── 1. Homebrew packages ──────────────────────────────────────────────────────
header "Homebrew packages"
log "Updating Homebrew..."
brew update --quiet

BREW_PACKAGES=(
  mosh           # mobile shell — the whole point
  tmux           # multiplexer
  neovim         # editor
  fzf            # fuzzy finder (you already have this)
  zoxide         # smarter cd
  atuin          # better shell history with cross-machine sync
  yazi           # TUI file manager
  lsd            # better ls (drop-in: ls -ltr and traditional flags work)
  glow           # terminal markdown viewer (used by helpme)
  bat            # better cat
  ripgrep        # better grep (used by nvim telescope)
  fd             # better find (used by FZF)
  git-delta      # better git diffs (unified, syntax highlighted)
  difftastic     # semantic side-by-side diffs
  lazygit        # TUI git client
  btop           # better top
  tmuxinator     # session templates
  mc             # Midnight Commander TUI file manager
)

log "Installing packages..."
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    info "$pkg already installed — skipping"
  else
    brew install "$pkg"
    log "Installed $pkg"
  fi
done

# sesh (FZF session manager) — lives in its own tap
if ! brew list sesh &>/dev/null 2>&1; then
  log "Installing sesh..."
  brew tap joshmedeski/sesh 2>/dev/null || true
  brew install sesh
fi

header "Homebrew casks"
if ! brew list --cask ghostty &>/dev/null 2>&1; then
  log "Installing Ghostty..."
  brew install --cask ghostty
else
  info "Ghostty already installed — skipping"
fi

if ! brew list --cask font-monaspace-nerd-font &>/dev/null 2>&1; then
  log "Installing MonaspiceNe Nerd Font..."
  brew tap homebrew/cask-fonts 2>/dev/null || true
  brew install --cask font-monaspace-nerd-font
else
  info "MonaspiceNe Nerd Font already installed — skipping"
fi

# ── 2. oh-my-tmux ─────────────────────────────────────────────────────────────
header "oh-my-tmux"
if [[ ! -d "$HOME/.oh-my-tmux" ]]; then
  log "Cloning oh-my-tmux..."
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.oh-my-tmux"
  ln -sf "$HOME/.oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
  log "Symlinked ~/.tmux.conf → ~/.oh-my-tmux/.tmux.conf"
else
  info "oh-my-tmux already at ~/.oh-my-tmux"
  # Ensure symlink exists
  if [[ ! -L "$HOME/.tmux.conf" ]]; then
    ln -sf "$HOME/.oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
    warn "Re-created ~/.tmux.conf symlink"
  fi
fi

# ── 3. TPM (Tmux Plugin Manager) ─────────────────────────────────────────────
header "TPM"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  log "Installing TPM..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  info "TPM already installed at ~/.tmux/plugins/tpm"
fi

# ── 4. tmux.conf.local ────────────────────────────────────────────────────────
header "tmux config"
backup_if_exists "$HOME/.tmux.conf.local"
cp "$CONFIGS/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
log "Deployed ~/.tmux.conf.local"

# If a tmux server is already running, reload the config into it now.
# Without this, any existing server keeps the stale config until restarted.
if tmux info &>/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null && log "Reloaded tmux config into running server" \
    || warn "Could not reload tmux config — start a new session to pick it up"
fi

# ── 5. LazyVim ────────────────────────────────────────────────────────────────
header "LazyVim (Neovim)"
if [[ -d "$HOME/.config/nvim" ]]; then
  backup_if_exists "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim"
  warn "Removed existing ~/.config/nvim (backed up above)"
fi

# Also clear old lazy.nvim data to avoid conflicts with new config
if [[ -d "$HOME/.local/share/nvim" ]]; then
  backup_if_exists "$HOME/.local/share/nvim"
  rm -rf "$HOME/.local/share/nvim"
fi

log "Cloning LazyVim starter..."
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"   # detach from starter repo so you can init your own

# Overlay our custom config files onto the starter boilerplate
log "Deploying Neovim customisations..."
cp "$CONFIGS/nvim/lua/config/options.lua"  "$HOME/.config/nvim/lua/config/options.lua"
cp "$CONFIGS/nvim/lua/config/keymaps.lua"  "$HOME/.config/nvim/lua/config/keymaps.lua"

mkdir -p "$HOME/.config/nvim/lua/plugins"
cp "$CONFIGS/nvim/lua/plugins/extras.lua"  "$HOME/.config/nvim/lua/plugins/extras.lua"
cp "$CONFIGS/nvim/lua/plugins/lang.lua"    "$HOME/.config/nvim/lua/plugins/lang.lua"
# Remove the LazyVim starter example plugin file (it's just template content)
rm -f "$HOME/.config/nvim/lua/plugins/example.lua"

log "LazyVim configured. Plugins will install on first 'nvim' launch."

# ── 6. Ghostty ────────────────────────────────────────────────────────────────
header "Ghostty"
mkdir -p "$HOME/.config/ghostty"
backup_if_exists "$HOME/.config/ghostty/config"
cp "$CONFIGS/ghostty/config" "$HOME/.config/ghostty/config"
log "Deployed ~/.config/ghostty/config"

# ── 7. Starship ───────────────────────────────────────────────────────────────
header "Starship"
backup_if_exists "$HOME/.config/starship.toml"
cp "$CONFIGS/starship/starship.toml" "$HOME/.config/starship.toml"
log "Deployed ~/.config/starship.toml"

# ── 8. atuin ──────────────────────────────────────────────────────────────────
header "atuin"
mkdir -p "$HOME/.config/atuin"
backup_if_exists "$HOME/.config/atuin/config.toml"
cp "$CONFIGS/atuin/config.toml" "$HOME/.config/atuin/config.toml"
log "Deployed ~/.config/atuin/config.toml"
warn "Remember to set ATUIN_SERVER_URL in ~/.config/atuin/config.toml after launching your server"

# ── 9. tmuxinator ────────────────────────────────────────────────────────────
header "tmuxinator"
mkdir -p "$HOME/.config/tmuxinator"
cp "$CONFIGS/tmuxinator/main.yml" "$HOME/.config/tmuxinator/main.yml"
cp "$CONFIGS/tmuxinator/llm.yml"  "$HOME/.config/tmuxinator/llm.yml"
log "Deployed tmuxinator templates: main, llm"

# Cheatsheets — available via 'helpme' command
mkdir -p "$HOME/.local/share/cheatsheets"
cp "$REPO_DIR/TMUX_CHEATSHEET.md"      "$HOME/.local/share/cheatsheets/tmux.md"
cp "$REPO_DIR/NEOVIM_CHEATSHEET.md"    "$HOME/.local/share/cheatsheets/nvim.md"
cp "$REPO_DIR/NEW_TOOLS_CHEATSHEET.md" "$HOME/.local/share/cheatsheets/tools.md"
cp "$REPO_DIR/MC_CHEATSHEET.md"        "$HOME/.local/share/cheatsheets/mc.md"
cp "$REPO_DIR/GETTING_STARTED.md"      "$HOME/.local/share/cheatsheets/start.md"
log "Deployed cheatsheets to ~/.local/share/cheatsheets/ (use 'helpme' to browse)"

# Midnight Commander
mkdir -p "$HOME/.config/mc" "$HOME/.local/share/mc/skins"
backup_if_exists "$HOME/.config/mc/ini"
cp "$CONFIGS/mc/ini" "$HOME/.config/mc/ini"
cp "$CONFIGS/mc/skins/nc-classic.ini" "$HOME/.local/share/mc/skins/nc-classic.ini"
log "Deployed ~/.config/mc/ini and nc-classic skin"

# tmux-ip helper — used by status bar to show primary IPv4
mkdir -p "$HOME/.local/bin"
install -m 755 "$REPO_DIR/scripts/tmux-ip" "$HOME/.local/bin/tmux-ip"
log "Deployed tmux-ip → ~/.local/bin/tmux-ip"

# ── 10. bat theme ────────────────────────────────────────────────────────────
header "bat theme"
BAT_THEMES_DIR="$(bat --config-dir)/themes"
TOKYO_THEME="$BAT_THEMES_DIR/tokyonight_night.tmTheme"
if [[ ! -f "$TOKYO_THEME" ]]; then
  mkdir -p "$BAT_THEMES_DIR"
  log "Downloading Tokyo Night theme for bat..."
  curl -fsSL "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme" \
    -o "$TOKYO_THEME"
  bat cache --build
  log "bat theme installed and cache rebuilt"
else
  info "bat Tokyo Night theme already installed"
fi

# ── 12. git config — delta + difftastic ─────────────────────────────────────
header "git config"
log "Configuring delta as git pager..."
git config --global core.pager             delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate         true
git config --global delta.side-by-side     true
git config --global delta.line-numbers     true
git config --global delta.light            false
git config --global delta.syntax-theme     "tokyonight_night"
git config --global merge.conflictstyle    diff3
git config --global diff.colorMoved        default

log "Configuring difftastic as git difftool..."
git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
git config --global difftool.prompt          false
git config --global alias.dft               'difftool --tool difftastic'

log "git: use 'git diff' for line diffs (delta), 'git dft' for semantic diffs (difftastic)"

# ── 13. zshrc plugin ─────────────────────────────────────────────────────────
header "~/.zshrc plugin"
ZSHRC="$HOME/.zshrc"
PLUGIN_DIR="$HOME/.zsh/plugins"
MARKER="# >>> turbo-shell additions <<<"

# Symlink zshrc_additions.zsh as a .plugin.zsh file
mkdir -p "$PLUGIN_DIR"
ln -sf "$REPO_DIR/zshrc_additions.zsh" "$PLUGIN_DIR/turbo-shell.plugin.zsh"
log "Symlinked zshrc_additions.zsh → ~/.zsh/plugins/turbo-shell.plugin.zsh"

# Add a single source line to ~/.zshrc (idempotent)
[[ ! -f "$ZSHRC" ]] && touch "$ZSHRC"
if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  info "Plugin source line already in ~/.zshrc"
else
  printf '\n%s\n%s\n%s\n' \
    "$MARKER" \
    '[[ -f "$HOME/.zsh/plugins/turbo-shell.plugin.zsh" ]] && source "$HOME/.zsh/plugins/turbo-shell.plugin.zsh"' \
    "# <<< turbo-shell additions >>>" >> "$ZSHRC"
  log "Added plugin source line to ~/.zshrc"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Bootstrap complete!${NC}"
echo ""
echo -e "${BOLD}Manual steps required:${NC}"
echo ""
echo -e "  ${YELLOW}1. Remove the old ssh() function from ~/.zshrc${NC}"
echo "     It lives around lines 16–32. The new version is in the additions block."
echo ""
echo -e "  ${YELLOW}2. Install tmux plugins${NC}"
echo "     oh-my-tmux changes the prefix from Ctrl+b to Ctrl+a."
echo "     Start a FRESH tmux session (kill any existing ones first):"
echo "       tmux kill-server && tmux new -s main"
echo "     Then press:  Ctrl+a  then  capital I  to install plugins."
echo "     Wait for all plugins to install, then press Enter."
echo ""
echo -e "  ${YELLOW}3. Open Neovim${NC}"
echo "     Run: nvim"
echo "     LazyVim will auto-install all plugins (takes ~2 min on first launch)."
echo "     When it finishes, run: :Mason  then press U to install language servers."
echo ""
echo -e "  ${YELLOW}4. Configure atuin sync (when ready)${NC}"
echo "     a. Set your server URL in: ~/.config/atuin/config.toml"
echo "     b. atuin import auto          # import your existing zsh history"
echo "     c. atuin register -u USER -e EMAIL  # register on your self-hosted server"
echo "        or if registered: atuin login -u <username> -p <password> -k <encryption-key>"
echo "     d. atuin sync                 # initial sync"
echo ""
echo -e "  ${YELLOW}5. Reload your shell${NC}"
echo "     exec zsh"
echo ""
echo -e "  ${YELLOW}6. Switch to Ghostty${NC}"
echo "     Open Ghostty.app — your config is already in place."
echo "     Verify the Tokyo Night theme loads correctly."
echo "     If the theme name is wrong, run: ghostty +list-themes | grep -i tokyo"
echo ""

if [[ -d "$BACKUP_DIR" ]]; then
  echo -e "${BLUE}Backups saved to: $BACKUP_DIR${NC}"
  echo ""
fi
